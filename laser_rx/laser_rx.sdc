create_clock -name clk50 -period 20.0 [get_ports clk50]
create_clock -name clk38 -period 26315.789 [get_ports clk38]
derive_pll_clocks
