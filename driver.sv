module driver
(
	input  logic        clk,
	input  logic		  yaw_step_en, pitch_step_en,  
	output logic        yaw_step, pitch_step
);

	logic clk0;
	clkdiv #(50_000_000, 10) c0 (clk, clk0);

	always_ff @(posedge clk0) begin
		yaw_step <= yaw_step_en ? !yaw_step : 1'b1;
		pitch_step <= pitch_step_en ? !pitch_step : 1'b1;
	end

endmodule