
module ccom (
	button_pio_export,
	clk50_clk,
	leds_export,
	qpdp1_export,
	reset_n_reset_n,
	status_export,
	stepper_export,
	qpdp2_export);	

	input		button_pio_export;
	input		clk50_clk;
	output	[7:0]	leds_export;
	input	[11:0]	qpdp1_export;
	input		reset_n_reset_n;
	input	[11:0]	status_export;
	output	[7:0]	stepper_export;
	input	[11:0]	qpdp2_export;
endmodule
