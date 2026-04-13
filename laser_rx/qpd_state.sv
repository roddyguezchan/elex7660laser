module qpd_state(
    input  logic        clk50,
    input  logic        reset,
    input  logic [11:0] q0, q1, q2, q3,
    output logic        on_target, micro,
    output logic [23:0] dxdy,
    output logic [4:0]  move_com
);

    // Optimized Thresholds
    localparam int TARGET_CONFIDENCE_MAX = 500_000; 
    localparam int MOVE_THRESH           = 350;     
    localparam int MICRO_THRESH          = 150;

    logic signed [15:0] sum;
    logic signed [15:0] dx_num, dy_num;
    logic [23:0] confidence_counter;
    
    assign sum    = q0 + q1 + q2 + q3;
    assign dx_num = (q0 + q1) - (q2 + q3);
    assign dy_num = (q0 + q3) - (q1 + q2);

    // Confidence Logic
    always_ff @(posedge clk50 or posedge reset) begin
        if (reset) begin
            confidence_counter <= 0;
            on_target <= 1'b0;
        end else begin
            if (sum > 300) begin 
                if (confidence_counter < TARGET_CONFIDENCE_MAX)
                    confidence_counter <= confidence_counter + 1;
                
                // Hysteresis: Require 50k cycles to lock, but don't drop immediately
                if (confidence_counter > 50_000) on_target <= 1'b1;
            end else begin 
                if (confidence_counter > 0)
                    confidence_counter <= confidence_counter - 1;
                else
                    on_target <= 1'b0;
            end
        end
    end

    logic move_x, move_y, dir_x, dir_y;

    always_ff @(posedge clk50) begin
        // Horizontal Movement
        if (dx_num > MOVE_THRESH) begin
            move_x <= 1'b1; dir_x <= 1'b1;
        end else if (dx_num < -MOVE_THRESH) begin
            move_x <= 1'b1; dir_x <= 1'b0;
        end else begin
            move_x <= 1'b0;
        end

        // Vertical Movement
        if (dy_num > MOVE_THRESH) begin
            move_y <= 1'b1; dir_y <= 1'b1;
        end else if (dy_num < -MOVE_THRESH) begin
            move_y <= 1'b1; dir_y <= 1'b0;
        end else begin
            move_y <= 1'b0;
        end
        
        // Micro-adjustment
        micro <= (abs16(dx_num) < MICRO_THRESH && abs16(dy_num) < MICRO_THRESH);
    end

    function automatic signed [15:0] abs16(input signed [15:0] val);
        return (val[15]) ? -val : val;
    endfunction

    // Debugging output
    assign dxdy     = { 2'b0, dx_num[15], dx_num[8:0], 2'b0, dy_num[15], dy_num[8:0] }; 
    assign move_com = { on_target, dir_y, move_y, dir_x, move_x };

endmodule