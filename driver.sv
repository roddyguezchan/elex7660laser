module driver
(
	input logic clk50,
	input logic latch_en,
	input logic yaw_step_en, pitch_step_en,
	output logic yaw_dir, pitch_dir,
	output logic yaw_step, pitch_step
);
	logic clk0;
	logic latched;

	clkdiv #(50_000_000, 50000) c0 (clk50, clk0);

	always_ff @(posedge clk50) begin
		if (latch_en)
			latched <= 1'b1;
		else if (latched && (!yaw_step || !pitch_step))
			latched <= 1'b0;
	end

	always_ff @(posedge clk0) begin
		if (!latched) begin
			yaw_step   <= 1'b1;
			pitch_step <= 1'b1;
		end else begin
			yaw_step   <= yaw_step_en   ? !yaw_step   : 1'b1;
			pitch_step <= pitch_step_en ? !pitch_step : 1'b1;
		end
	end

endmodule