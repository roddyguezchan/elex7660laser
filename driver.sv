module driver
(
	input logic clk50,
	input logic [3:0] ir_msg, // message from IR
	output logic yaw_dir, pitch_dir
	output logic yaw_step, pitch_step 
);

	logic clk0;
	clkdiv #(50_000_000, 10) c0 (clk, clk0);

	always_ff @(posedge clk0) begin
		yaw_step <= yaw_step_en ? !yaw_step : 1'b1;
		pitch_step <= pitch_step_en ? !pitch_step : 1'b1;
	end

endmodule