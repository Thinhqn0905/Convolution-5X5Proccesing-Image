# Clock constraint template
# Update clock port name to match your integration wrapper when available.

# create_clock -period 6.667 [get_ports clk]  ;# 150 MHz target
create_clock -period 8.000 [get_ports clk]    ;# 125 MHz conservative baseline

# Add board-specific pin assignments after wrapper integration.
# Example:
# set_property PACKAGE_PIN W5 [get_ports clk]
# set_property IOSTANDARD LVCMOS33 [get_ports clk]
