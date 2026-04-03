module laser_rx(
	input logic clk50,
	input  logic [1:0] KEY, // onboard FPGA dev board buttons
	output logic [3:0] GPIO_0, // 0 used for transmitter
	input logic [1:0] GPIO_1, // 0 used for receiver
	output logic [7:0] LED
);

localparam DATA_TBS = 8'b0101_1001;

logic txstart, txdone, rxrecv, rxdone;
logic baseband_out;
logic [7:0] data_received;
logic [2:0] rxstate;

assign LED = data_received;

ccom_rx nios_system(
	.clk50_clk(clk50),
	.reset_n_reset_n(KEY[0]),
	.datarx_export(data_received),
	.sysout_export({ 1'b0, rxstate[2:0], txstart, txdone, rxrecv, rxdone}),
	.sysin_export({ 7'b0, txstart })
);

ir_tx transmitter(
	.clk50(clk50),
	.reset(!KEY[1]),
	.start(txstart | GPIO_1[1]),
	.done(txdone),
	.data(DATA_TBS),
	.ir_out(GPIO_0[0]),
);


ir_rx receiver(
	.clk50(clk50),
	.reset(!KEY[1]),
	.ir_input(GPIO_1[0]),
	.recv(rxrecv),
	.done(rxdone),
	.data(data_received)
);


endmodule