module qpd_state(
    input  logic        clk50,
    input  logic [11:0] q0, q1, q2, q3,
    output logic        on_target, micro,
    output logic [23:0] dxdy,
    output logic [4:0]  move_com
);

    // --- Tuning Parameters for Stability ---
    localparam MOVE_START_THRESH = 180;  // Threshold to start moving
    localparam MOVE_STOP_THRESH  = 110;  // INCREASED: Wider deadzone to stop fluttering
    localparam TARGET_ON         = 200;  
    localparam TARGET_OFF        = 40;   
    localparam MICRO_ON          = 650;  // INCREASED: Switch to slow mode much earlier
    localparam MICRO_OFF         = 800;  

    logic signed [15:0] sum;
    logic signed [25:0] dx_num, dy_num;
    logic signed [25:0] dx_raw, dy_raw;

    // --- Fast 4-Sample Filter ---
    logic signed [12:0] dx_history [3:0];
    logic signed [12:0] dy_history [3:0];
    logic signed [15:0] dx_avg, dy_avg;

    assign sum = $signed({4'b0, q0}) + $signed({4'b0, q1})
               + $signed({4'b0, q2}) + $signed({4'b0, q3});

    // QPD Difference Math
    assign dx_num = ($signed({2'b0, q0 + q1}) - $signed({2'b0, q2 + q3})) <<< 10;
    assign dy_num = ($signed({2'b0, q0 + q3}) - $signed({2'b0, q1 + q2})) <<< 10;

    // Zero-guard using TARGET_OFF
    assign dx_raw = (sum > TARGET_OFF) ? (dx_num / sum) : 26'sd0;
    assign dy_raw = (sum > TARGET_OFF) ? (dy_num / sum) : 26'sd0;

    // --- Filtering Logic with "Flash Fill" ---
    integer i;
    always_ff @(posedge clk50) begin
        // If laser just appeared, fill buffer to prevent sluggish ramp-up
        if (!on_target && (sum > TARGET_ON)) begin
            for (i = 0; i < 4; i = i + 1) begin
                dx_history[i] <= dx_raw[12:0];
                dy_history[i] <= dy_raw[12:0];
            end
        end else begin
            // Shift register for 4-tap average
            dx_history[0] <= (dx_raw > 2047)  ?  13'd2047 :
                             (dx_raw < -2048) ? -13'sd2048 : dx_raw[12:0];
            dy_history[0] <= (dy_raw > 2047)  ?  13'd2047 :
                             (dy_raw < -2048) ? -13'sd2048 : dy_raw[12:0];
            
            for (i = 1; i < 4; i = i + 1) begin
                dx_history[i] <= dx_history[i-1];
                dy_history[i] <= dy_history[i-1];
            end
        end
    end

    // Resulting Average (Sum / 4)
    assign dx_avg = (dx_history[0] + dx_history[1] + dx_history[2] + dx_history[3]) >>> 2;
    assign dy_avg = (dy_history[0] + dy_history[1] + dy_history[2] + dy_history[3]) >>> 2;

    // Helper function for magnitude checks
    function automatic signed [15:0] abs16(input signed [15:0] val);
        return (val[15]) ? -val : val;
    endfunction

    // --- Control Logic Hysteresis ---
    logic move_x, move_y, dir_x, dir_y;

    always_ff @(posedge clk50) begin
        // Signal Presence
        if      (sum > TARGET_ON)  on_target <= 1'b1;
        else if (sum < TARGET_OFF) on_target <= 1'b0;

        // Move Decision: The wider MOVE_STOP_THRESH prevents hunting
        if      (abs16(dx_avg) > MOVE_START_THRESH) move_x <= 1'b1;
        else if (abs16(dx_avg) < MOVE_STOP_THRESH)  move_x <= 1'b0;

        if      (abs16(dy_avg) > MOVE_START_THRESH) move_y <= 1'b1;
        else if (abs16(dy_avg) < MOVE_STOP_THRESH)  move_y <= 1'b0;

        // Direction Locking: Prevents sign-flip jitter at the null point
        if (move_x) dir_x <= (dx_avg > 0);
        if (move_y) dir_y <= (dy_avg > 0);

        // Precision Mode: Switch to microstepping much earlier to damp the arrival
        if      (abs16(dx_avg) < MICRO_ON  && abs16(dy_avg) < MICRO_ON)  micro <= 1'b1;
        else if (abs16(dx_avg) > MICRO_OFF || abs16(dy_avg) > MICRO_OFF) micro <= 1'b0;
    end

    // Output Mapping
    assign dxdy     = { dx_avg[11:0], dy_avg[11:0] };
    assign move_com = { micro, dir_y, move_y, dir_x, move_x };

endmodule