module rx_state (
	input logic clk50,
	input logic reset,
	input logic [11:0] q0, q1, q2, q3,
	
	output logic [23:0] dxdy,
	output logic [1:0] status,
	
	output logic ir_out
);
	//logic en_ir;
	logic on_target, micro;
	logic [4:0] move_com;
	
	qpd_state qpd0 (.*);
	 
	assign status = { on_target, micro };
	
	ir_tx ir0(
		.clk50(clk50),
		.reset(reset),
		.start(on_target),
		.data({ 3'b0, move_com }),
		.ir_out(ir_out)
	);

endmodule