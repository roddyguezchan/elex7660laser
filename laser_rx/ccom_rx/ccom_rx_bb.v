
module ccom_rx (
	clk50_clk,
	qpdp1_export,
	reset_n_reset_n,
	qpdp2_export,
	dxdy_export,
	status_export);	

	input		clk50_clk;
	input	[23:0]	qpdp1_export;
	input		reset_n_reset_n;
	input	[23:0]	qpdp2_export;
	input	[23:0]	dxdy_export;
	input	[7:0]	status_export;
endmodule
