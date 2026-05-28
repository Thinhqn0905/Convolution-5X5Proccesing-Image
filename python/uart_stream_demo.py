import argparse
import time
import threading
import cv2
import numpy as np
import serial
import pyrealsense2 as rs # type: ignore

def rx_thread_func(ser: serial.Serial, expected_bytes: int, rx_buffer: bytearray, event: threading.Event):
    """Background thread to continuously read from serial to prevent OS buffer overflow."""
    bytes_read = 0
    while bytes_read < expected_bytes:
        if event.is_set():
            break
        chunk = ser.read(min(4096, expected_bytes - bytes_read))
        if chunk:
            rx_buffer.extend(chunk)
            bytes_read += len(chunk)
    
def send_kernel(ser: serial.Serial, kernel_name: str):
    # Standard 5x5 kernels
    kernels = {
        "identity": [
            0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,
            0,  0,  1,  0,  0,
            0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,
        ],
        "gaussian5": [
            1,  4,  6,  4, 1,
            4, 16, 24, 16, 4,
            6, 24, 36, 24, 6,
            4, 16, 24, 16, 4,
            1,  4,  6,  4, 1,
        ],
        "sharpen5": [
            -1, -1, -1, -1, -1,
            -1,  2,  2,  2, -1,
            -1,  2,  8,  2, -1,
            -1,  2,  2,  2, -1,
            -1, -1, -1, -1, -1,
        ],
        "laplacian5": [
            -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1,
            -1, -1, 24, -1, -1,
            -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1,
        ]
    }
    
    k = kernels.get(kernel_name, kernels["identity"])
    
    print(f"Programming kernel '{kernel_name}' to FPGA...")
    # Send 'K' command
    ser.write(b'K')
    time.sleep(0.1) # small delay
    
    # Send 25 bytes (each coeff is a signed 8-bit int)
    k_bytes = bytearray()
    for val in k:
        k_bytes.append(val & 0xFF)
        
    ser.write(k_bytes)
    time.sleep(0.5) # Wait for programming
    print("Kernel programmed!")


def main():
    parser = argparse.ArgumentParser(description="Live FPGA UART Streaming Demo")
    parser.add_argument("--com", type=str, required=True, help="COM port of the FPGA (e.g. COM3)")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate (must match arty_top.sv)")
    parser.add_argument("--width", type=int, default=160, help="Image width (must match IMAGE_WIDTH parameter in FPGA)")
    parser.add_argument("--height", type=int, default=120, help="Image height")
    parser.add_argument("--kernel", type=str, default="gaussian5", choices=["identity", "gaussian5", "sharpen5", "laplacian5"])
    args = parser.parse_args()

    # KSIZE = 5, padding = 4. Output dimensions:
    out_w = args.width - 4
    out_h = args.height - 4
    expected_rx_bytes = out_w * out_h * 3

    print(f"Connecting to FPGA on {args.com} at {args.baud} baud...")
    try:
        ser = serial.Serial(args.com, args.baud, timeout=0.1)
    except Exception as e:
        print(f"Failed to open {args.com}: {e}")
        return

    # Program kernel
    send_kernel(ser, args.kernel)

    print("Initializing Intel RealSense D455...")
    pipeline = rs.pipeline()
    config = rs.config()
    config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)
    
    try:
        pipeline.start(config)
    except Exception as e:
        print(f"Failed to start camera: {e}")
        ser.close()
        return

    print(f"Stream started. Expected to send {args.width}x{args.height} and receive {out_w}x{out_h}.")
    print("Press 'q' in the image window to exit.")

    try:
        while True:
            # 1. Capture frame
            frames = pipeline.wait_for_frames()
            color_frame = frames.get_color_frame()
            if not color_frame:
                continue
                
            bgr = np.asanyarray(color_frame.get_data())
            raw_rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
            
            # 2. Resize to required FPGA width
            feed_rgb = cv2.resize(raw_rgb, (args.width, args.height), interpolation=cv2.INTER_AREA)
            tx_data = feed_rgb.tobytes()
            
            # 3. Setup RX thread (we must read while writing to avoid deadlocks)
            rx_buffer = bytearray()
            stop_event = threading.Event()
            rx_thread = threading.Thread(target=rx_thread_func, args=(ser, expected_rx_bytes, rx_buffer, stop_event))
            
            start_t = time.time()
            rx_thread.start()
            
            # 4. Send over UART
            ser.write(b'D')
            
            # Write in chunks to allow RX thread to breathe
            chunk_size = 4096
            for i in range(0, len(tx_data), chunk_size):
                ser.write(tx_data[i:i+chunk_size])
                
            ser.write(b'S') # End of frame marker
            
            # 5. Wait for RX to finish
            # 54KB at 115200 takes ~5 seconds
            rx_thread.join(timeout=10.0) 
            stop_event.set()
            
            end_t = time.time()
            elapsed = end_t - start_t
            fps = 1.0 / elapsed if elapsed > 0 else 0
            
            print(f"Frame complete! Sent {len(tx_data)}b, Rcvd {len(rx_buffer)}b. Time: {elapsed:.2f}s ({fps:.2f} FPS)")
            
            if len(rx_buffer) == expected_rx_bytes:
                # Convert received bytes to numpy array
                rx_arr = np.frombuffer(rx_buffer, dtype=np.uint8)
                filtered_rgb = rx_arr.reshape((out_h, out_w, 3))
                
                # Convert back to BGR for OpenCV display
                filtered_bgr = cv2.cvtColor(filtered_rgb, cv2.COLOR_RGB2BGR)
                feed_bgr = cv2.cvtColor(feed_rgb, cv2.COLOR_RGB2BGR)
                
                # Show side by side (pad filtered to match feed height if we want side-by-side)
                padded_filtered = cv2.copyMakeBorder(filtered_bgr, 2, 2, 2, 2, cv2.BORDER_CONSTANT, value=[0,0,0])
                combined = np.hstack((feed_bgr, padded_filtered))
                
                # Resize for better viewing on screen
                combined_large = cv2.resize(combined, (combined.shape[1]*3, combined.shape[0]*3), interpolation=cv2.INTER_NEAREST)
                
                cv2.imshow("Original vs FPGA Filtered", combined_large)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
            else:
                print(f"Error: Expected {expected_rx_bytes} bytes, got {len(rx_buffer)}. Check UART connection.")
                # Clear buffer just in case
                ser.reset_input_buffer()

    except KeyboardInterrupt:
        print("Stopping...")
    finally:
        pipeline.stop()
        ser.close()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
