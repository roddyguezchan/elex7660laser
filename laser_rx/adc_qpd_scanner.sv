// adc_qpd_scanner.sv
// Derived from code by Ed Casas (ltc2308.sv)
// Modified for use by Rafael Banalan
/*
	This code adresses the onboard ADC to read the QPD ADC values. It 
	outputs each channel as a ready-to-use 12-bit logic value.
*/

module adc_qpd_scanner (
    input  logic clk, reset,       // 50 MHz clock
    input  logic sdo,              // serial data from ADC chip
    output logic convst, sck, sdi, // ADC control signals
    
    // Direct outputs for motor/logic modules (latest sampled value)
    output logic [11:0] q0, q1, q2, q3,
	 
	 // Additional logic signals
	 output logic available
	 
);

   // ADC states and state duration counter
    typedef enum { start, convert, transfer, acquire } state_t;
    state_t state, state_next;
    logic [6:0] count, count_next;

    `define set_next(s,c) begin state_next=(s); \
	 count_next=7'(c)-1'b1; end

    always_comb begin
        if (reset)
            `set_next(start, 2)
        else if (count)
            `set_next(state, count)

        else 
            case(state)
                start:    `set_next(convert, 126) 
                convert:  `set_next(transfer, 24) 
                transfer: `set_next(acquire, 8) 
                acquire:  `set_next(start, 2)
                default:  `set_next(start, 2)
            endcase
    end
    
    always_ff @(posedge clk) begin
        state <= state_next;
        count <= count_next;
    end
	 
   // ADC control signals
    always_ff @(posedge clk) begin 
        convst <= (state_next == start);
        sck <= (state_next == transfer && !count_next[0]);
    end

    // cycle through channels
    logic [2:0] ch, prevch;
    const logic [2:0] firstch = 3'd0;
    const logic [2:0] lastch  = 3'd3;

    always_ff @(posedge clk) begin
        if (reset) begin
            ch <= firstch;
            prevch <= firstch;
        end else if (state == convert && !count_next) begin
            // move to next quadrant channel
            ch <= (ch == lastch) ? firstch : ch + 1'b1;
            // remember which channel is currently being read
            prevch <= ch;
        end
    end

      // ADC configuration on SDI
    logic [11:0] adccfg;
    assign adccfg = { 1'b1, ch[0], ch[2:1], 2'b10, 6'b0 };

    always_ff @(posedge clk)
        sdi <= (state_next == transfer) ? adccfg[count_next >> 1] : 1'b0;

     // ADC data on SDO
    logic [11:0] sample;
    always_ff @(posedge clk) begin
        if (state == transfer && !sck)
            sample <= { sample[10:0], sdo };
    end

    // when a transfer finishes, save the sample to the specific quadrant register
    always_ff @(posedge clk) begin
        if (reset) begin
            q0 <= 12'h0; q1 <= 12'h0; q2 <= 12'h0; q3 <= 12'h0;
        end else if (state == transfer && state_next == acquire) begin
            case (prevch)
                3'd0: q0 <= sample;
                3'd1: q1 <= sample;
                3'd2: q2 <= sample;
                3'd3: q3 <= sample;
            endcase
        end
    end

endmodule