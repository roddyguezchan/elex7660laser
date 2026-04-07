module qpd_state(
    input  logic        clk50,
    input  logic [11:0] q0, q1, q2, q3,
    output logic        on_target, micro,
    output logic [23:0] dxdy,
    output logic [4:0]  move_com
);
    
    // --- Thresholds ---
    localparam MOVE_START_THRESH = 180; 
    localparam MOVE_STOP_THRESH  = 150; 
    localparam TARGET_ON         = 100;
    localparam TARGET_OFF        = 50;

    logic signed [15:0] sum;
    logic signed [25:0] dx_num, dy_num;
    logic signed [25:0] dx_raw, dy_raw;
    
    // Filter Registers
    logic signed [12:0] dx_history [3:0];
    logic signed [12:0] dy_history [3:0];
    logic signed [14:0] dx_avg, dy_avg; // Extra bits for sum of history

    assign sum = $signed({4'b0, q0}) + $signed({4'b0, q1}) + $signed({4'b0, q2}) + $signed({4'b0, q3});
    
    assign dx_num = ($signed({2'b0, q0 + q1}) - $signed({2'b0, q3 + q2})) <<< 10;
    assign dy_num = ($signed({2'b0, q0 + q3}) - $signed({2'b0, q1 + q2})) <<< 10;
    
    assign dx_raw = (sum > 50) ? (dx_num / sum) : 26'sd0;
    assign dy_raw = (sum > 50) ? (dy_num / sum) : 26'sd0;

    // --- Filtering Logic ---
    always_ff @(posedge clk50) begin
        // Shift history and add new sample (clamped to 13 bits to prevent overflow in filter)
        dx_history[3] <= dx_history[2];
        dx_history[2] <= dx_history[1];
        dx_history[1] <= dx_history[0];
        dx_history[0] <= (dx_raw > 2047) ? 13'd2047 : (dx_raw < -2048) ? -13'sd2048 : dx_raw[12:0];

        dy_history[3] <= dy_history[2];
        dy_history[2] <= dy_history[1];
        dy_history[1] <= dy_history[0];
        dy_history[0] <= (dy_raw > 2047) ? 13'd2047 : (dy_raw < -2048) ? -13'sd2048 : dy_raw[12:0];
    end

    // Calculate Average
    assign dx_avg = (dx_history[0] + dx_history[1] + dx_history[2] + dx_history[3]) >>> 2; // Divide by 4
    assign dy_avg = (dy_history[0] + dy_history[1] + dy_history[2] + dy_history[3]) >>> 2;

    // --- Decision Hysteresis ---
    logic move_x, move_y;
    always_ff @(posedge clk50) begin
        if (sum > TARGET_ON)       on_target <= 1'b1;
        else if (sum < TARGET_OFF) on_target <= 1'b0;

        if (abs(dx_avg) > MOVE_START_THRESH)     move_x <= 1'b1;
        else if (abs(dx_avg) < MOVE_STOP_THRESH) move_x <= 1'b0;

        if (abs(dy_avg) > MOVE_START_THRESH)     move_y <= 1'b1;
        else if (abs(dy_avg) < MOVE_STOP_THRESH) move_y <= 1'b0;
    end

    assign dxdy  = { dx_avg[11:0], dy_avg[11:0] };
    assign micro = (abs(dx_avg) < 300 && abs(dy_avg) < 300);

    assign move_com = {
        micro,
        (dy_avg > 0),
        move_y,
        (dx_avg > 0),
        move_x
    };
    
    function signed [25:0] abs(input signed [25:0] val);
        return (val < 0) ? -val : val;
    endfunction
endmodule