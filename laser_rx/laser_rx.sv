module laser_rx(
	input logic clk50,
	input  logic [1:0] KEY, // onboard FPGA dev board buttons
	output logic [1:0] GPIO_0, // 0 used for transmitter
	input logic [1:0] GPIO_1 // 0 used for receiver
);

localparam DATA_TBS = 8'b01011001;

logic txstart, txdone, rxrecv, rxdone;
logic [7:0] data_received;

ccom_rx nios_system(
	.clk50_clk(clk50),
	.reset_n_reset_n(KEY[0]),
	.datarx_export(data_received)
);

ir_tx transmitter(
	.clk50(clk50),
	.reset(KEY[0]),
	.start(txstart),
	.done(txdone),
	.data(DATA_TBS),
	.ir_out(GPIO_0[0])
);


ir_rx receiver(
	.clk50(clk50),
	.ir_input(GPIO_1[0]),
	.recv(rxrecv),
	.done(rxdone),
	.data(data_received)
);


endmodule