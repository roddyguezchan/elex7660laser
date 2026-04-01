
module ccom (
	button_pio_export,
	clk50_clk,
	leds_export,
	q0_data_export,
	q1_data_export,
	q2_data_export,
	q3_data_export,
	reset_n_reset_n,
	status_export,
	stepper_export);	

	input		button_pio_export;
	input		clk50_clk;
	output	[7:0]	leds_export;
	input	[11:0]	q0_data_export;
	input	[11:0]	q1_data_export;
	input	[11:0]	q2_data_export;
	input	[11:0]	q3_data_export;
	input		reset_n_reset_n;
	input	[11:0]	status_export;
	output	[7:0]	stepper_export;
endmodule
