
module ccom_rx (
	clk50_clk,
	datarx_export,
	reset_n_reset_n,
	sysin_export,
	sysout_export);	

	input		clk50_clk;
	input	[7:0]	datarx_export;
	input		reset_n_reset_n;
	output	[7:0]	sysin_export;
	input	[7:0]	sysout_export;
endmodule
