// ir_rx.sv
// Rafael Banalan 2026-04-06
/*
	This module uses a modified version of the NEC infrared transmission
	protocol. The main difference is that instead of an address+inv and
	data+inv state, we use one data state of width 8 bits.
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
    output logic recv,
    output logic done,
    output logic [7:0] data
);

	// Timing constants (ticks using 50 MHz period = 20ns)

	localparam BURST_MIN = 80_000;   // 1.6ms
	localparam BURST_MAX = 120_000;  // 2.4ms
	
	localparam SPACE_MIN = 35_000;   // 0.7ms
	localparam SPACE_MAX = 65_000;   // 1.3ms

	localparam DATA_BURST_MIN = 5_000;   // 100us
	localparam DATA_BURST_MAX = 22_000;  // 440us

	localparam BIT_THRESHOLD = 25_000;   // 500us

	localparam TIMEOUT = 500_000; // 10ms total timeout for recovery

	// Edge detector (metastability protection)
	logic ir_sync0, ir_sync;
	always_ff @( posedge clk50 ) begin
		ir_sync0 <= ir_input;
		ir_sync  <= ir_sync0;
	end

	// Receiver state machine
	typedef enum logic [2:0] {
	  IDLE, HEADER_BURST, HEADER_SPACE, DATA_BURST, DATA_SPACE, VALIDATE
	} state_t;

	state_t state;
	logic [19:0] tick_count;
	logic prev_level;
	logic [3:0] bit_count;
	logic [7:0] shift_reg;

	always_ff @( posedge clk50 ) begin
		if ( reset ) begin
			state <= IDLE;
			tick_count <= 0;
			prev_level <= 1'b1;
			bit_count <= 0;
			shift_reg <= 0;
			done <= 0;
			recv <= 0;
			data <= 0;
		end else begin
			done <= 0;
			
			if ( ir_sync == prev_level ) begin
				// No edge keep counting
				if ( tick_count < 20'hFFFFF ) // saturate to avoid overflow
					tick_count <= tick_count + 1;
			end else begin
				// Edge detected
				case ( state )
					IDLE: begin
						// Wait for falling edge (start of header burst)
						if ( prev_level == 1'b1 ) begin
							recv <= 1;
							state <= HEADER_BURST;
						end
						tick_count <= 0;
					end

					HEADER_BURST: begin
						// Rising edge
							   
						if ( tick_count >= BURST_MIN && tick_count <= BURST_MAX ) begin
							state <= HEADER_SPACE;
						end else begin
							recv <= 0;
							state <= IDLE;
						end
						tick_count <= 0;
					end

					HEADER_SPACE: begin
						//Falling edge
						if ( tick_count >= SPACE_MIN && tick_count <= SPACE_MAX ) begin
							bit_count <= 0;
							shift_reg <= 0;
							state <= DATA_BURST;
						end else begin
							recv <= 0;
							state <= IDLE;
						end
						tick_count <= 0;
					end

					DATA_BURST: begin
						// Rising edge
						if ( tick_count >= DATA_BURST_MIN && tick_count <= DATA_BURST_MAX ) begin
							state <= DATA_SPACE;
						end else begin
							recv <= 0;
							state <= IDLE;
						end
						tick_count <= 0;
					end

					DATA_SPACE: begin
						// Falling edge: decode bit by HIGH duration
						shift_reg <= {shift_reg[6:0], (tick_count > BIT_THRESHOLD)};
						tick_count <= 0;

						if ( bit_count == 4'd7 ) begin
							state <= VALIDATE;
						end else begin
							bit_count <= bit_count + 1;
							state <= DATA_BURST;
						end
					end

					VALIDATE: begin
						state <= IDLE;
						recv <= 0;
					end
				endcase
				prev_level <= ir_sync;
	
			end

			// Validate by checking to see if the data matches the inverted data
			if ( state == VALIDATE ) begin
				data <= shift_reg;
				done <= 1;
				state <= IDLE;
				recv <= 0;
			end

			// Timeout if we get stuck in a state for too long
			if ( tick_count >= TIMEOUT && state != IDLE ) begin
				state <= IDLE;
				recv <= 0;
				bit_count <= 0;
				shift_reg <= 0;
				tick_count <= 0;
			end
		end
	end
endmodule