// qpd_state.sv
// Rafael Banalan 2026-04-05
/*
    This module parses ADC values of QPD channels and calculates 
    laser displacement (dx, dy). Outputs are registered to ensure 
    timing closure and stable data for the Nios V PIO.
*/

module qpd_state(
    input  logic        clk,        // System Clock (e.g. 80MHz)
    input  logic        reset_n,    // Active-low reset
    input  logic [11:0] q0, q1, q2, q3,
    output logic        on_target,
    output logic        micro,
    output logic [23:0] dxdy,
    output logic [4:0]  move_com
);
    
    // Thresholds adjusted for Gain of 8 (<< 8)
    localparam CENTER_THRESH    = 38;  
    localparam MICROSTEP_THRESH = 50; 
    localparam SUM_GUARD_THRESH = 200; // Minimum light intensity to trust math

<<<<<<< Updated upstream
    // Quadrant Mapping:
    // q0 - TOP RIGHT
    // q1 - BOTTOM RIGHT
    // q2 - BOTTOM LEFT
    // q3 - TOP LEFT
    
    logic signed [15:0] sum;
    logic signed [24:0] dx_num, dy_num;
    logic signed [24:0] dx_full, dy_full;
    logic signed [11:0] dx_sat, dy_sat;
    
    // Combinational Math (Numerators and Sum)
    assign sum    = $signed({1'b0, (q0 + q1 + q2 + q3)});
    assign dx_num = (($signed({1'b0, q0}) + $signed({1'b0, q1})) - ($signed({1'b0, q3}) + $signed({1'b0, q2}))) << 8;
    assign dy_num = (($signed({1'b0, q0}) + $signed({1'b0, q3})) - ($signed({1'b0, q1}) + $signed({1'b0, q2}))) << 8;

    // Combinational Division and Clamping
    always_comb begin
        dx_full = 25'sd0;
        dy_full = 25'sd0;
        dx_sat  = 12'sd0;
        dy_sat  = 12'sd0;

        if (sum >= SUM_GUARD_THRESH) begin
            dx_full = dx_num / sum;
            dy_full = dy_num / sum;

            // Saturation Logic for dx (-2048 to 2047)
            if (dx_full > 25'sd2047)       dx_sat = 12'sd2047;
            else if (dx_full < -25'sd2048) dx_sat = 12'sd2048;
            else                            dx_sat = dx_full[11:0];

            // Saturation Logic for dy
            if (dy_full > 25'sd2047)       dy_sat = 12'sd2047;
            else if (dy_full < -25'sd2048) dy_sat = 12'sd2048;
            else                            dy_sat = dy_full[11:0];
        end
    end

    // REGISTERED OUTPUTS
    // This block runs at the speed of your hardware clock.
    // It "latches" the math once it is stable.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dxdy      <= 24'd0;
            on_target <= 1'b0;
            micro     <= 1'b0;
            move_com  <= 5'd0;
        end else begin
            dxdy      <= { dx_sat, dy_sat };
            on_target <= (sum > 4000);
            
            // Re-assigning micro locally for move_com bit
            micro     <= ( abs_12(dx_sat) < MICROSTEP_THRESH && abs_12(dy_sat) < MICROSTEP_THRESH );
            
            move_com  <= {
                ( abs_12(dx_sat) < MICROSTEP_THRESH && abs_12(dy_sat) < MICROSTEP_THRESH ), // bit 4: micro
                ( dy_sat > 0 ),                                                           // bit 3: dy direction
                ( abs_12(dy_sat) > CENTER_THRESH),                                        // bit 2: dy move req
                ( dx_sat > 0 ),                                                           // bit 1: dx direction
                ( abs_12(dx_sat) > CENTER_THRESH)                                         // bit 0: dx move req
            };
        end
    end

    // Internal Absolute Value Function
    function signed [12:0] abs_12(input signed [11:0] val);
        abs_12 = (val < 0) ? -val : val;
    endfunction
    
=======
	// THIS CODE ASSUMES THE FOLLOWING:
	//  q0 - TOP RIGHT
	//  q1 - BOTTOM RIGHT
	//  q2 - BOTTOM LEFT
	//  q3 - TOP LEFT
	
	logic [13:0] raw_sum;
	logic signed [15:0] sum;
	
	logic signed [25:0] dx_num, dy_num;
	logic signed [25:0] dx, dy;
	
	assign raw_sum = q0 + q1 + q2 +q3;
	assign sum = $signed({2'b0, raw_sum});
	
	assign dx_num = (($signed({1'b0, q0}) + $signed({1'b0, q1})) - ($signed({1'b0, q3}) + $signed({1'b0, q2}))) <<< 10;
	assign dy_num = (($signed({1'b0, q0}) + $signed({1'b0, q3})) - ($signed({1'b0, q1}) + $signed({1'b0, q2}))) <<< 10;
	
	assign dx = dx_num / sum;
	assign dy = dy_num / sum;
	
	assign dxdy = { dx[11:0], dy[11:0] };
	
	assign on_target = sum > 4000; // if the sum is greater than 4000, we can assume the laser is on the QPD
	
	assign move_com = {
		( abs(dx) < MICROSTEP_THRESH && abs(dy) < MICROSTEP_THRESH ),
		( dy > 0 ),
		( abs(dy) > CENTER_THRESH),
		( dx > 0 ),
		( abs(dx) > CENTER_THRESH) };
	
		
	// function for absolute value
	function signed [25:0] abs(input signed [25:0] val);
		return (val < 0) ? -val : val;
	endfunction
	
>>>>>>> Stashed changes
endmodule