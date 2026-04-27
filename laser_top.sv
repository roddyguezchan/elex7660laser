// laser_top.sv
// Rafael Banalan 2026-04-23
/*
	This module ties all the sub-modules of the transmitter module, and also
	provides the needed step_tick for the search_controller.
*/
module laser_top
  ( input  logic clk50, // internal system 50MHz clock
    input  logic [1:0] KEY, // onboard FPGA dev board buttons
	 input  logic [1:0] GPIO_1,
    output logic [7:0] LED, // onboard FPGA dev board LED strip
	 output logic [3:0] GPIO_0 // motor driver output
	 ) ;
	
	logic cyawstep, cyawdir, cpitchstep, cpitchdir;
	logic rx_done;
	logic [7:0] ir_data;
	logic step_tick;
   logic searching;
   logic on_target;
	
	assign on_target = ir_data[4];
	
	logic [19:0] clk_count;
	always_ff @(posedge clk50) begin
		if (clk_count >= 500_000) begin
			clk_count <= 0;
			step_tick <= 1;
		end else begin
			clk_count <= clk_count + 1;
			step_tick <= 0;
		end
	end

   ccom nios_system( 
		.clk50_clk(clk50),               
		.reset_n_reset_n(KEY[0]),
		.status_export({ 3'b0, searching, ir_data })
	);
	
	ir_rx r0(
		.clk50(clk50),
		.ir_input(GPIO_1[0]),
		.reset(!KEY[0]),
		.done(rx_done),
		.data(ir_data)
	);
	
	search_controller controller0 (
		.clk50(clk50),
		.reset(!KEY[0]),
		.return_home(!KEY[1]),
		.on_target(on_target),
		.step_tick(step_tick),
		.rx_done(rx_done),
		
		.ir_yaw_en(ir_data[0]),
		.ir_yaw_dir(!ir_data[1]),
		.ir_pitch_en(ir_data[2]),
		.ir_pitch_dir(!ir_data[3]),
		
		.out_yaw_en(cyawstep),
		.out_yaw_dir(cyawdir),
		.out_pitch_en(cpitchstep),
		.out_pitch_dir(cpitchdir),
		.is_searching(searching)
		);
	
	driver simpledriver (
		.clk50(clk50),
		.yaw_step_en(cyawstep),
		.pitch_step_en(cpitchstep),
		.yaw_step(GPIO_0[0]),
		.pitch_step(GPIO_0[2])
		);
	
	assign GPIO_0[1] = cyawdir;
	assign GPIO_0[3] = cpitchdir;
	assign LED = ir_data;
	
endmodule