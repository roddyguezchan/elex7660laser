module laser_top
  ( input  logic clk50,
    input  logic [1:0] KEY,
    output logic [7:0] LED,
    input  logic ADC_SDO,
    output logic ADC_CONVST, ADC_SDI, ADC_SCK
	 ) ;
   
   laser laser_0 
     ( .clk50_clk(clk50), 
       .leds_export(LED),               
       .reset_n_reset_n(KEY[0]),
		 .button_pio_export(KEY[1]),
       .ltc2308_0_adc0_sdo(ADC_SDO), .ltc2308_0_adc0_convst(ADC_CONVST), 
       .ltc2308_0_adc0_sdi(ADC_SDI), .ltc2308_0_adc0_sck(ADC_SCK) ) ;
   
endmodule
