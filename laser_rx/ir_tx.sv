// ir_tx.sv
// Rafael Banalan 2026-04-01
/*
	This module uses a modified version of the NEC infrared transmission
	protocol. The main difference is that instead of an address+inv and
	data+inv state, we use one data+inv state of width 8 bits.
*/

module ir_tx(
	input logic clk50,
	
	input logic reset,
	input logic start,
	output logic done,
	
	input logic [7:0] data,
	
	output logic ir_out
);
	// Timing constants for 50MHz clock (1 tick = 20ns)
	localparam BIT_COUNT_RESET_VAL = 3'b111;
	localparam TICK_9MS = 450_000; // header burst time
	localparam TICK_4_5MS = 225_000; // header space time
	localparam TICK_562_5US = 28_125; // data burst / data zero / EOF burst
	localparam TICK_1_6875MS = 84_375; // data one
	
	// Generate carrier frequency
	logic carrier;
	clkdiv #(50_000_000, 38_000) c0 (clk50, carrier);
	
	// Transmitter protocol state machine
	typedef enum logic [3:0] { 
		IDLE = 4'd0,
		HEADER_BURST = 4'd1,
		HEADER_SPACE = 4'd2, 
		DATA_BURST = 4'd3, 
		DATA_SPACE = 4'd4, 
		DATA_BURST_INV = 4'd5, 
		DATA_SPACE_INV = 4'd6, 
		EOF  = 4'd7,
		WAIT  = 4'd8
		} state_t;
	state_t state;
	
	task next_bit_logic;
		tick_count <= 0;
		if (bit_count == 0) begin
			if (data_sent) begin
					state <= EOF;
			end else begin
					bit_count <= BIT_COUNT_RESET_VAL;
					data_sent <= 1'b1;
					state <= DATA_BURST_INV;
			end
		end else begin
			bit_count <= bit_count - 1'b1;
			state <= data_sent ? DATA_BURST_INV : DATA_BURST;
		end
	endtask
	
	logic [7:0] data_out; // A copy of the data to be written, set at start
	
	logic message; // The signal that will be modulated with the carrier
	
	logic [2:0] bit_count; // Stores the bit position
   logic data_sent;

	logic [19:0] tick_count;
	
	always_ff @(posedge clk50) begin
		if ( reset ) begin
			state <= IDLE;
			tick_count <= 0;
			done <= 0;
			data_sent <= 0;
		end else case (state)
		default : state <= IDLE;
		
		// IDLE STATE
			IDLE : begin
				message <= 0;
				bit_count <= BIT_COUNT_RESET_VAL;
				if ( start ) begin
					data_out <= data;
					data_sent <= 0;
					done <= 0;
					tick_count <= 0;
					state <= HEADER_BURST;
				end
			end
			
		// HEADER_BURST STATE
			HEADER_BURST : begin
				message <= 1;
				if ( tick_count >= TICK_9MS ) begin
					tick_count <= 0;
					state <= HEADER_SPACE;
				end else tick_count <= tick_count + 1'b1;
			end
		
		// HEADER_SPACE STATE
			HEADER_SPACE : begin
				message <= 0;
				if ( tick_count >= TICK_4_5MS ) begin
					tick_count <= 0;
					state <= DATA_BURST;
				end else tick_count <= tick_count + 1'b1;
			end
		
		// DATA BURST
			DATA_BURST : begin
				message <= 1;
				if ( tick_count >= TICK_562_5US ) begin
					tick_count <= 0;
					state <= DATA_SPACE;
				end else tick_count <= tick_count + 1'b1;
			end
			
		// DATA STATE
			DATA_SPACE : begin
				message <= 0;
				if( data_out[bit_count] == 1'b1 ) begin
					if (tick_count >= TICK_1_6875MS ) begin
						tick_count <= 0;
						next_bit_logic();
					end else tick_count <= tick_count + 1'b1;
				end else begin // if the current bit is a 0
					if ( tick_count >= TICK_562_5US ) begin
						tick_count <= 0;
						next_bit_logic();
					end else tick_count <= tick_count + 1'b1;
				end
			end
			
			// DATA BURST INVERTED
			DATA_BURST_INV : begin
				message <= 1;
				if ( tick_count >= TICK_562_5US ) begin
					tick_count <= 0;
					state <= DATA_SPACE_INV;
				end else tick_count <= tick_count + 1'b1;
			end
			
		// DATA SPACE INVERTED
			DATA_SPACE_INV : begin
				message <= 0;
				if( ~data_out[bit_count] == 1'b1 ) begin
					if (tick_count >= TICK_1_6875MS ) begin
						tick_count <= 0;
						next_bit_logic();
					end else tick_count <= tick_count + 1'b1;
				end else begin // if the inverse of the current bit is a 1
					if ( tick_count >= TICK_562_5US ) begin
						tick_count <= 0;
						next_bit_logic();
					end else tick_count <= tick_count + 1'b1;
				end
			end
			
		
			EOF : begin
				message <= 1;
				if ( tick_count >= TICK_562_5US ) begin
					tick_count <= 0;
					done <= 1;
					if ( start ) state <= WAIT;
					else state <= IDLE;
				end else tick_count <= tick_count + 1'b1;
			end

			WAIT : begin
				message <= 0;
				if ( tick_count >= '1 ) begin
					tick_count <= 0;
					state <= IDLE;
				end else tick_count <= tick_count + 1'b1;
			end
			
		endcase
	end
	
	assign ir_out = carrier & message;
	
	
	
endmodule