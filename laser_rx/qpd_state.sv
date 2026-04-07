// qpd_state.sv
// Rafael Banalan 2026-04-05
/*
	This module is responsible for parsing the ADC values of the QPD channels.
	After parsing the needed movement of direction to properly align the laser
	with the QPD, it creates the needed body for the IR alignment command for
	transmission.
*/

module qpd_state(
	input logic [11:0] q0, q1, q2, q3,
	output logic on_target, micro,
	output logic [23:0] dxdy,
	output logic [4:0] move_com
);
	
	localparam CENTER_THRESH = 150; // The laser is at the center if both dx and dy are here.
	localparam MICROSTEP_THRESH = 200; // The motors need to start moving step by step when dx and dy are here.

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
	
	assign on_target = sum > 200;
	
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
	
endmodule