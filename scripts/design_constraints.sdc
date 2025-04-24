# Define Clock Constraints
create_clock -period 10 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]

# Define Input Constraints
set_input_delay -max 2.0 -clock clk [get_ports data_in]
set_input_delay -min 1.0 -clock clk [get_ports data_in]

# Define Output Constraints
set_output_delay -max 2.5 -clock clk [get_ports data_out]
set_output_delay -min 1.0 -clock clk [get_ports data_out]

# Define False Paths (Ignored Timing Paths)
set_false_path -from [get_ports debug_signal]

# Define Multi-Cycle Paths
set_multicycle_path 2 -setup -from [get_cells multicycle_reg]
set_multicycle_path 1 -hold -from [get_cells multicycle_reg]
