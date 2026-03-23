module seg_display
(
	input logic clk,
	input logic [3:0][3:0] digs, // digits to show
	output logic [7:0] leds, // LED segment anodes
	output logic [3:0] ct // digit cathodes
);

// 7-segment decoder	
logic [7:0] decoder7 [0:15];
assign decoder7 = '{ 63, 6, 91, 79, 102, 109, 125, 7, 127, 111, 119, 124, 57, 94, 121, 113};

always_ff @ (posedge clk) begin
	ct <=
		(ct == 4'b1110) ? 4'b1101 :
		(ct == 4'b1101) ? 4'b1011 :
		(ct == 4'b1011) ? 4'b0111 : 4'b1110;
		
	leds <=
		(ct == 4'b1110) ? decoder7[digs[1]] :
		(ct == 4'b1101) ? decoder7[digs[2]] :
		(ct == 4'b1011) ? decoder7[digs[3]] : 
		(ct == 4'b0111) ? decoder7[digs[0]] : '0;
end

endmodule