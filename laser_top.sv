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
	
   ccom nios_system( 
		.clk50_clk(clk50),               
		.reset_n_reset_n(KEY[0]),
		.status_export({ 4'b1111, ir_data })
	);
	
	ir_rx r0(
		.clk50(clk50),
		.ir_input(GPIO_1[0]),
		.reset(!KEY[0]),
		.done(rx_done),
		.data(ir_data)
	);
	
	driver simpledriver(
		.clk50(clk50),
		.yaw_step_en(cyawstep),
		.pitch_step_en(cpitchstep),
		.latch_en(rx_done),
		.yaw_step(GPIO_0[0]),
		.pitch_step(GPIO_0[2])
	);
	
	assign GPIO_0[1] = cyawdir;
	assign GPIO_0[3] = cpitchdir;
	
	assign {  cpitchdir, cpitchstep, cyawdir, cyawstep } = { !ir_data[3], ir_data[2], !ir_data[1], ir_data[0] };
	assign LED = ir_data;
	
	
endmodule