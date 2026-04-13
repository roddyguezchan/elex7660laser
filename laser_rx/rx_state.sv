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
	
	logic [19:0] tx_timer;
	logic tx_pulse;

	always_ff @(posedge clk50) begin
	  if (tx_timer >= 1_000_000) begin // 50MHz / 1M = 50Hz
			tx_timer <= 0;
			tx_pulse <= 1'b1;
	  end else begin
			tx_timer <= tx_timer + 1;
			tx_pulse <= 1'b0;
	  end
	end
	
	qpd_state qpd0 (.*);
	 
	assign status = { on_target, micro };
	
	ir_tx ir0(
		.clk50(clk50),
		.reset(reset),
		.start(tx_pulse),
		.data({ 3'b0, move_com }),
		.ir_out(ir_out)
	);

endmodule