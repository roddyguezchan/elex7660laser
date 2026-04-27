// laser_rx.sv
// Rafael Banalan 2026-04-01
/*
	This is the top level module for the receiver. It
	ties the sub-modules together.
*/

module laser_rx(
	input logic clk50, clk38,
	input  logic [1:0] KEY, // onboard FPGA dev board buttons
	output logic [3:0] GPIO_1, // pin 0 used for transmitter
	
	 // onboard FPGA dev board ADC chip
	 input  logic ADC_SDO, 
    output logic ADC_CONVST, ADC_SDI, ADC_SCK
);

logic [1:0] rx_state_status;
logic [23:0] dxdy;
logic [11:0] q0, q1, q2, q3;

ccom_rx nios_system(
	.clk50_clk(clk50),
	.reset_n_reset_n(KEY[0]),
	.dxdy_export(dxdy),
	.qpdp1_export({ q3, q2 }),
	.qpdp2_export({ q1, q0 }),
	.status_export({ 6'b111111, rx_state_status})
);

adc_qpd_scanner qpdrd(
	.clk(clk50),
	.reset(!KEY[0]),
	.sdo(ADC_SDO),
	.convst(ADC_CONVST),
	.sck(ADC_SCK),
	.sdi(ADC_SDI),
	.q0(q0),
	.q1(q1),
	.q2(q2),
	.q3(q3)
);

rx_state r0 (
	.clk50(clk50),
	.reset(!KEY[0]),
	.dxdy(dxdy),
	.status(rx_state_status),
	.ir_out(GPIO_1[0]),
	.q0(q0),
	.q1(q1),
	.q2(q2),
	.q3(q3)
);

endmodule