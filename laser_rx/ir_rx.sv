// ir_rx.sv
// Rafael Banalan 2026-04-01
/*
	This module uses a modified version of the NEC infrared transmission
	protocol. The main difference is that instead of an address+inv and
	data+inv state, we use one data+inv state of width 8 bits.
*/

// THE RECEIVER IS ACTIVE LOW
// THE RECEIVER IS ACTIVE LOW
// THE RECEIVER IS ACTIVE LOW
// THE RECEIVER IS ACTIVE LOW
// THE RECEIVER IS ACTIVE LOW
// THE RECEIVER IS ACTIVE LOW
// THE RECEIVER IS ACTIVE LOW

module ir_rx(
	input logic clk50,
	input logic ir_input,
	input logic reset,
	output logic recv, done,
	output logic [7:0] data
);

	// Timing constants for 50MHz clock (1 tick = 20ns)
	localparam TICK_1_1MS = 55_000; // average of 0 and 1 space time
	localparam TICK_TIMEOUT = 18'h3FFFF;
	// Define tolerances (approx +/- 10%)
	localparam BURST_MIN = 400_000; // 8ms
	localparam BURST_MAX = 500_000; // 10ms
	localparam SPACE_MIN = 200_000; // 4ms
	localparam SPACE_MAX = 250_000; // 5ms

	// Transmitter protocol state machine
	typedef enum { IDLE, HEADER_BURST, HEADER_SPACE, DATA_BURST, DATA_SPACE, VALIDATE} state_t;
	state_t state;

	
	// Edge detector
	logic ir_sync, ir_prev;
	always_ff @(posedge clk50) begin
		ir_sync <= ir_input;
		ir_prev <= ir_sync;
	end
	
	logic falling, rising;
	assign falling = ir_prev == 1 && ir_sync == 0;
	assign rising = ir_prev == 0 && ir_sync == 1;
	
	// State machine
	logic [19:0] tick_count;
	logic [3:0] bit_count; // Up to 16 bits
	logic [15:0] shift_reg; // 8 data + 8 data inv
	
	always_ff @(posedge clk50) begin
		if ( reset ) begin
			state <= IDLE;
		end else 		
		case ( state )
			IDLE : begin
				if ( falling ) begin
					tick_count <= 0;
					done <= 0;
					recv <= 1;
					state <= HEADER_BURST;
				end else recv <= 0;
			end
			
			HEADER_BURST: begin
            tick_count <= tick_count + 1'b1;
            if (rising) begin
                if (tick_count > BURST_MIN && tick_count < BURST_MAX) begin
                    tick_count <= 0;
                    state <= HEADER_SPACE;
                end else state <= IDLE;
            end else if (tick_count >= TICK_TIMEOUT) state <= IDLE;
        end

        HEADER_SPACE: begin
            tick_count <= tick_count + 1'b1;
            if (falling) begin
                if (tick_count > SPACE_MIN && tick_count < SPACE_MAX) begin
                    tick_count <= 0;
                    bit_count <= 0;
                    state <= DATA_BURST; // Valid header! Start receiving bits.
                end else state <= IDLE;
            end else if (tick_count >= TICK_TIMEOUT) state <= IDLE;
        end
			
			DATA_BURST : begin
				if ( rising ) begin
					tick_count <= 0;
					state <= DATA_SPACE;
				end else if (tick_count >= TICK_TIMEOUT) state <= IDLE;
			end
			
			DATA_SPACE : begin
				tick_count <= tick_count + 1'b1;
				if ( falling ) begin
					shift_reg <= { shift_reg[14:0], tick_count > TICK_1_1MS };
					
					if ( bit_count == 4'b1111 ) state <= VALIDATE;
					else begin
						bit_count <= bit_count + 1'b1;
						state <= DATA_BURST;
					end
				end else if (tick_count >= TICK_TIMEOUT) state <= IDLE;
			end
			
			VALIDATE : begin
				if ( shift_reg[15:8] == ~shift_reg[7:0]) begin
					data <= shift_reg[15:8];
					done <= 1;
				end
				
				state <= IDLE;
			end
		endcase
	end
endmodule