# ============================================================================
# Constraints for arty_top on Arty A7 100T Board
# All top-level ports are fully constrained - no DRC bypass needed.
# ============================================================================

# --- Clock ---
create_clock -period 10.000 [get_ports clk]   ;# 100 MHz target
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports clk]

# --- Reset (BTN0 active-high) ---
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports rst]

# --- USB-UART (via FT2232HQ on Arty A7) ---
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports uart_rx]
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports uart_tx]

# --- Debug LEDs ---
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

# --- Configuration voltage for Arty A7 100T ---
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
