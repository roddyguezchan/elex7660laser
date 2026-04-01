module laser_top
  ( input  logic clk50, // internal system 50MHz clock
    input  logic [1:0] KEY, // onboard FPGA dev board buttons
	 input logic [3:0] SW, // onboard FPGA dev board switches
    output logic [7:0] LED, // onboard FPGA dev board LED strip
	 output logic [3:0] GPIO_0, // motor driver output
    
	 // onboard FPGA dev board ADC chip
	 input  logic ADC_SDO, 
    output logic ADC_CONVST, ADC_SDI, ADC_SCK
	 ) ;
	
	// ADC samples
	logic [11:0] q0, q1, q2, q3;
	logic [5:0] status_sig;
	logic cyawstep, cyawdir, cpitchstep, cpitchdir;
   
	// ADC QPD scanner module
	adc_qpd_scanner qpd_inst(
		.clk(clk50),
		.reset(SW[0]), // the launchpad switches are active low
		.sdo(ADC_SDO),
		.convst(ADC_CONVST),
		.sck(ADC_SCK),
		.sdi(ADC_SDI),
		.q0(q0),
		.q1(q1),
		.q2(q2),
		.q3(q3)
	);
	
   ccom nios_system( 
		.clk50_clk(clk50), 
		.leds_export(LED),               
		.reset_n_reset_n(KEY[0]),
		.button_pio_export(KEY[1]),
		.q0_data_export(q0),
		.q1_data_export(q1),
		.q2_data_export(q2),
		.q3_data_export(q3),
		.status_export({ 8'b100000, GPIO_0[3:0] }),
		.stepper_export({4'b0, cpitchdir, cpitchstep, cyawdir, cyawstep})
	);
	
	driver simpledriver(
		.clk(clk50),
		.yaw_step_en(cyawstep),
		.pitch_step_en(cpitchstep),
		.yaw_step(GPIO_0[0]),
		.pitch_step(GPIO_0[2])
	);
	
	assign GPIO_0[1] = cyawdir;
	assign GPIO_0[3] = cpitchdir;
	
//	gimbal gimbal0(
//		.clk(clk),
//		.reset(KEY[1]),
//		.tr(q0),
//		.br(q1),
//		.bl(q1),
//		.tl(q3),
//		.yaw_step(GPIO_0[0]),
//		.yaw_dir(GPIO_0[1]),
//		.pitch_step(GPIO_0[2]),
//		.pitch_dir(GPIO_0[3]),
//		.max_disp(status_sig[0]),
//		.idle(status_sig[1]),
//		.left(status_sig[2]),
//		.right(status_sig[3]),
//		.up(status_sig[4]),
//		.down(status_sig[5]),
//	);
	
	
endmodule