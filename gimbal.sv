module gimbal #(
    parameter YAW_MAXDISP   = 800,
    parameter PITCH_MAXDISP = 800,
    parameter THRESHOLD     = 10     // Minimum error to trigger a step
) (
    input  logic        clk,
    input  logic [11:0] tr, tl, bl, br, 
    input  logic        reset,
    output logic        yaw_step, yaw_dir, pitch_step, pitch_dir,
    output logic        max_disp, idle
);
	logic [11:0] zero [4];
	signed [13:0] diff_q [4];
	signed [15:0] yaw_err, pitch_err;

	// step clock
	logic clk0;
	clkdiv #(50_000_000, 1_000) c0 (clk50, clk0);

	// displacement counters
	signed [15:0] yaw_count, pitch_count;

	// set zeros if reset is pressed
	always_ff @(posedge clk) begin
		if (reset) begin
			zero[0] <= tr;
			zero[1] <= tl;
			zero[2] <= bl;
			zero[3] <= br;
			yaw_count   <= 0;
			pitch_count <= 0;
		end
	end

	// calculate errors
	always_comb begin
		diff_q[0] = $signed({1'b0, tr}) - $signed({1'b0, zero[0]});
		diff_q[1] = $signed({1'b0, tl}) - $signed({1'b0, zero[1]});
		diff_q[2] = $signed({1'b0, bl}) - $signed({1'b0, zero[2]});
		diff_q[3] = $signed({1'b0, br}) - $signed({1'b0, zero[3]});

		// x and y axis error
		yaw_err   = (diff_q[1] + diff_q[2]) - (diff_q[0] + diff_q[3]);
		pitch_err = (diff_q[0] + diff_q[1]) - (diff_q[2] + diff_q[3]);

		// status signals
		idle = (yaw_err < THRESHOLD && yaw_err > -THRESHOLD) && (pitch_err < THRESHOLD && pitch_err > -THRESHOLD);

		max_disp = (abs(yaw_count) >= YAW_MAXDISP) || (abs(pitch_count) >= PITCH_MAXDISP);
	end

	// motor control
	always_ff @(posedge clk0) begin
		if (reset) begin
			yaw_step <= 0;
			pitch_step <= 0;
		end 
		else begin
			// yaw control
			if (yaw_err > THRESHOLD && yaw_count < YAW_MAXDISP) begin
				yaw_dir  <= 1;
				yaw_step <= !yaw_step; // toggle to create pulses
				yaw_count <= yaw_count + 1;
			end else if (yaw_err < -THRESHOLD && yaw_count > -YAW_MAXDISP) begin
				yaw_dir  <= 0;
				yaw_step <= !yaw_step;
				yaw_count <= yaw_count - 1;
			end else begin
				yaw_step <= 0;
			end

			// pitch control
			if (pitch_err > THRESHOLD && pitch_count < PITCH_MAXDISP) begin
				pitch_dir  <= 1;
				pitch_step <= !pitch_step; // toggle to create pulses
				pitch_count <= pitch_count + 1;
			end else if (pitch_err < -THRESHOLD && pitch_count > -PITCH_MAXDISP) begin
				pitch_dir  <= 0;
				pitch_step <= !pitch_step;
				pitch_count <= pitch_count - 1;
			end else begin
				pitch_step <= 0;
			end
		end
	end

	// function for absolute value
	function signed [15:0] abs(input signed [15:0] val);
		return (val < 0) ? -val : val;
	endfunction

endmodule