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
	
	logic signed [15:0] sum;
	
	logic signed [24:0] dx_num, dy_num;
	logic signed [23:0] dx, dy;
	
	assign sum = $signed({1'b0, (q0 + q1 + q2 + q3)});
	
	assign dx_num = (($signed({1'b0, q0}) + $signed({1'b0, q1})) - ($signed({1'b0, q3}) + $signed({1'b0, q2}))) << 10;
	assign dy_num = (($signed({1'b0, q0}) + $signed({1'b0, q3})) - ($signed({1'b0, q1}) + $signed({1'b0, q2}))) << 10;
	
	assign dx = dx_num / sum;
	assign dy = dy_num / sum;
	assign dxdy = { dx, dy };
	
	assign on_target = sum > 4000; // if the sum is greater than 4000, we can assume the laser is on the QPD
	
	assign move_com = {
		( abs(dx) < MICROSTEP_THRESH && abs(dy) < MICROSTEP_THRESH ),
		( dy > 0 ),
		( abs(dy) > CENTER_THRESH),
		( dx > 0 ),
		( abs(dx) > CENTER_THRESH) };
	
		
	// function for absolute value
	function signed [23:0] abs(input signed [23:0] val);
		return (val < 0) ? -val : val;
	endfunction
	
endmodule