module search_controller (
    input  logic clk50,
    input  logic reset,        // KEY[0]
    input  logic return_home,  // KEY[1]
    input  logic on_target,
    input  logic step_tick,
    input  logic rx_done,
    
    input  logic ir_yaw_en, ir_yaw_dir,
    input  logic ir_pitch_en, ir_pitch_dir,

    output logic out_yaw_en, out_yaw_dir,
    output logic out_pitch_en, out_pitch_dir,
    output logic is_searching
);

    // Constraints
    localparam signed [15:0] BOOT_LIMIT  = 266; 
    localparam signed [15:0] PITCH_LIMIT = 89;  
    localparam signed [15:0] YAW_LIMIT   = 177; 
    
    // Search Configuration
    localparam [15:0] SEARCH_MAX_SIDE = 200;     
    localparam [31:0] PULSE_WIDTH     = 50_000;  
    localparam [15:0] DENSITY_STEP    = 3;      

    typedef enum logic [2:0] {
        BOOT_UP       = 3'd0,
        IDLE_WAIT     = 3'd1,
        TRACKING      = 3'd2,
        SEARCHING     = 3'd3,
        RETURNING     = 3'd4,
        FORCED_RETURN = 3'd5
    } state_t;

    state_t state;
    logic signed [15:0] pos_x, pos_y;
    logic [15:0] side_limit, step_count;
    logic [1:0]  spiral_dir; 
    logic [31:0] pulse_timer;
    logic has_seen_target;

    assign is_searching = (state == SEARCHING || state == RETURNING || state == FORCED_RETURN);

    always_ff @(posedge clk50 or posedge reset) begin
        if (reset) begin
            state <= BOOT_UP;
            pos_x <= 0; pos_y <= -BOOT_LIMIT;
            has_seen_target <= 0;
            side_limit <= DENSITY_STEP;
            step_count <= 0;
            spiral_dir <= 0;
            pulse_timer <= 0;
        end else if (return_home) begin
            state <= FORCED_RETURN;
        end else begin
            
            if (pulse_timer > 0) pulse_timer <= pulse_timer - 1;

            case (state)
                BOOT_UP: begin
                    out_pitch_dir <= 1'b1; 
                    out_pitch_en  <= (pulse_timer > 0); 
                    if (step_tick) begin
                        if (pos_y < 0) begin
                            pos_y <= pos_y + 1;
                            pulse_timer <= PULSE_WIDTH;
                        end else state <= IDLE_WAIT;
                    end
                end

                IDLE_WAIT: begin
                    {out_yaw_en, out_pitch_en} <= 2'b00;
                    if (on_target) state <= TRACKING;
                end

                TRACKING: begin
                    if (on_target) begin
                        has_seen_target <= 1'b1;
                        if (rx_done) begin
                            pulse_timer <= PULSE_WIDTH; 
                            out_yaw_dir <= ir_yaw_dir;
                            out_pitch_dir <= ir_pitch_dir;
                            if (ir_yaw_en) begin
                                if (ir_yaw_dir && pos_x < YAW_LIMIT)      pos_x <= pos_x + 1;
                                else if (!ir_yaw_dir && pos_x > -YAW_LIMIT) pos_x <= pos_x - 1;
                            end
                            if (ir_pitch_en) begin
                                if (ir_pitch_dir && pos_y < PITCH_LIMIT)     pos_y <= pos_y + 1;
                                else if (!ir_pitch_dir && pos_y > -PITCH_LIMIT) pos_y <= pos_y - 1;
                            end
                        end
                        out_yaw_en   <= (pulse_timer > 0 && ir_yaw_en);
                        out_pitch_en <= (pulse_timer > 0 && ir_pitch_en);
                    end else if (has_seen_target) begin
                        state <= SEARCHING;
                        step_count <= 0; spiral_dir <= 0;
                        side_limit <= DENSITY_STEP;
                        pulse_timer <= 0; // Immediate reset for clean start
                    end
                end

                SEARCHING: begin
                    if (on_target) state <= TRACKING;
                    else if (side_limit > SEARCH_MAX_SIDE) state <= RETURNING;
                    else begin
                        case (spiral_dir)
                            0: begin out_yaw_dir <= 1; out_yaw_en <= (pulse_timer > 0); out_pitch_en <= 0; end
                            1: begin out_pitch_dir <= 1; out_pitch_en <= (pulse_timer > 0); out_yaw_en <= 0; end
                            2: begin out_yaw_dir <= 0; out_yaw_en <= (pulse_timer > 0); out_pitch_en <= 0; end
                            3: begin out_pitch_dir <= 0; out_pitch_en <= (pulse_timer > 0); out_yaw_en <= 0; end
                        endcase

                        if (step_tick) begin
                            pulse_timer <= PULSE_WIDTH;
                            case (spiral_dir)
                                0: pos_x <= pos_x + 1; 
                                1: pos_y <= pos_y + 1;
                                2: pos_x <= pos_x - 1; 
                                3: pos_y <= pos_y - 1;
                            endcase
                            
                            if (step_count >= side_limit - 1) begin
                                step_count <= 0;
                                spiral_dir <= spiral_dir + 1;
                                if (spiral_dir == 1 || spiral_dir == 3) 
                                    side_limit <= side_limit + DENSITY_STEP;
                            end else begin
                                step_count <= step_count + 1;
                            end
                        end
                    end
                end

                RETURNING: begin
                    if (on_target) state <= TRACKING;
                    else if (pos_x == 0 && pos_y == 0) begin
                        has_seen_target <= 0;
                        state <= IDLE_WAIT;
                    end else begin
                        out_yaw_dir   <= (pos_x < 0);
                        out_pitch_dir <= (pos_y < 0);
                        out_yaw_en    <= (pulse_timer > 0 && pos_x != 0);
                        out_pitch_en  <= (pulse_timer > 0 && pos_y != 0);

                        if (step_tick) begin
                            pulse_timer <= PULSE_WIDTH;
                            if (pos_x > 0) pos_x <= pos_x - 1; else if (pos_x < 0) pos_x <= pos_x + 1;
                            if (pos_y > 0) pos_y <= pos_y - 1; else if (pos_y < 0) pos_y <= pos_y + 1;
                        end
                    end
                end

                FORCED_RETURN: begin
                    if (pos_x == 0 && pos_y == -BOOT_LIMIT) begin
                        has_seen_target <= 0;
                        state <= IDLE_WAIT;
                    end else begin
                        out_yaw_dir   <= (pos_x < 0);
                        out_pitch_dir <= (pos_y > -BOOT_LIMIT) ? 1'b0 : 1'b1;
                        out_yaw_en    <= (pulse_timer > 0 && pos_x != 0);
                        out_pitch_en  <= (pulse_timer > 0 && pos_y != -BOOT_LIMIT);

                        if (step_tick) begin
                            pulse_timer <= PULSE_WIDTH;
                            if (pos_x > 0) pos_x <= pos_x - 1; else if (pos_x < 0) pos_x <= pos_x + 1;
                            if (pos_y > -BOOT_LIMIT) pos_y <= pos_y - 1; else if (pos_y < -BOOT_LIMIT) pos_y <= pos_y + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule