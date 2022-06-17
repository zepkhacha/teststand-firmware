// IPbus interface to Flash memory
// 
// Written for Flash memory chip: Micron N25Q256A
// 
// WBUF = block RAM to hold commands & data to be sent to Flash
//        write to this buffer using IPbus address FLASH.WBUF
//        (the MSB will be sent to Flash first)
//
// RBUF = block RAM to hold response from Flash
//        read from this buffer using IPbus address FLASH.RBUF
//        (the MSB is the first bit of the Flash response)
//
// To initiate a transaction with the Flash, write a command to IPbus address FLASH.CMD
//        The format of the 32-bit command is 0x0NNN0MMM
//        "NNN" is the number of bytes that will be sent from WBUF to the Flash
//        "MMM" is the number of response bytes to store in RBUF from the Flash
//        both NNN and MMM are limited to 9 bits

module spi_flash_intf (
    input  clk,
    input  reset,
    output spi_clk,
    output spi_mosi,
    input  spi_miso,
    output spi_ss,
    input  [ 8:0] flash_wr_nBytes,
    input  [ 8:0] flash_rd_nBytes,
    input  flash_cmd_strobe,
    input  rbuf_rd_en,
    input  [ 6:0] rbuf_rd_addr,
    output [31:0] rbuf_data_out,
    input  wbuf_wr_en,
    input  [ 6:0] wbuf_wr_addr,
    input  [31:0] wbuf_data_in
);

assign spi_clk = ~clk;

wire wbuf_rd_en;
wire [13:0] wbuf_rd_addr;
wire [15:0] wbuf_data_out;

wire rbuf_wr_en;
wire [13:0] rbuf_wr_addr;
wire rbuf_data_in;


// ====================================================
// Counter for addresses on Flash side of WBUF and RBUF
// ====================================================

reg  [11:0] bit_cnt = 12'b0;
wire bit_cnt_reset;
wire [11:0] bit_cnt_wr_max;
wire [11:0] bit_cnt_rd_max;

assign bit_cnt_wr_max[11:0] = {flash_wr_nBytes[8:0], 3'b000} - 1'b1;
assign bit_cnt_rd_max[11:0] = {flash_rd_nBytes[8:0], 3'b000} - 1'b1;

always @(posedge clk) begin
    if (bit_cnt_reset)
        bit_cnt[11:0] <= 12'b0;
    else
        bit_cnt[11:0] <= bit_cnt[11:0] + 1'b1;
end


// ==========================================
// State machine for communicating with Flash
// ==========================================

// declare symbolic name for each state
// simplified one-hot encoding (each constant is an index into an array of bits)
parameter [2:0]
    IDLE        = 3'd0,
    START_CMD   = 3'd1,
    SEND_CMD    = 3'd2,
    FINISH_CMD  = 3'd3,
    RECEIVE_RSP = 3'd4;

// declare current state and next state variables
reg [4:0] CS;
reg [4:0] NS;

// sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 5'b0;       // set all state bits to 0
        CS[IDLE] <= 1'b1; // enter IDLE state
    end
    else
        CS <= NS;         // go to the next state
end

// combinational always block to determine next state (use blocking [=] assignments)
always @* begin
    NS = 5'b0; // one bit will be set to 1 by case statement

    case (1'b1)

        CS[IDLE] : begin
            // stay in IDLE if flash_wr_nBytes = 0
            if (flash_cmd_strobe & (bit_cnt_wr_max != 12'hFFF))
                NS[START_CMD] = 1'b1;
            else
                NS[IDLE] = 1'b1;
        end

        CS[START_CMD] : begin
            NS[SEND_CMD] = 1'b1;
        end

        CS[SEND_CMD] : begin
            if (bit_cnt == bit_cnt_wr_max)
                NS[FINISH_CMD] = 1'b1;
            else
                NS[SEND_CMD] = 1'b1;
        end

        CS[FINISH_CMD] : begin
            if (bit_cnt_rd_max == 12'hFFF) // flash_rd_nBytes = 0
                NS[IDLE] = 1'b1;
            else
                NS[RECEIVE_RSP] = 1'b1;
        end

        CS[RECEIVE_RSP] : begin
            if (bit_cnt == bit_cnt_rd_max)
                NS[IDLE] = 1'b1;
            else
                NS[RECEIVE_RSP] = 1'b1;
        end

    endcase
end

// assign outputs based on states

assign bit_cnt_reset = (CS[IDLE]        == 1'b1) | (CS[FINISH_CMD] == 1'b1); // bit_cnt_reset is high when the bit counter does not need to increment
assign wbuf_rd_en    = (CS[START_CMD]   == 1'b1) | (CS[SEND_CMD]   == 1'b1); // wbuf_rd_en is high when commands are being read from the WBUF
assign rbuf_wr_en    = (CS[RECEIVE_RSP] == 1'b1);                            // rbuf_wr_en is high when Flash responses are being stored in the RBUF
assign spi_ss        = (CS[IDLE]        == 1'b1) | (CS[START_CMD]  == 1'b1); // spi_ss is high when there is no active Flash transaction


// ====================
// Dual port block RAMs
// ====================

// WBUF: for writing to Flash
//      32-bit port = input from IPbus
//       1-bit port = output to Flash
// RBUF: for reading from Flash
//       1-bit port = input from Flash
//      32-bit port = output to IPbus

assign wbuf_rd_addr[13:0] = {2'b00, bit_cnt[11:0]};
assign rbuf_wr_addr[13:0] = {2'b00, bit_cnt[11:0]};

assign spi_mosi     = wbuf_data_out[0];
assign rbuf_data_in = spi_miso;

// reverse the bit order of the IPbus data, so that the MSB will be stored in the lowest
// address of the block RAMs (i.e., the first bit written to or read from Flash)

wire [31:0] wbuf_data_in_r;
wire [31:0] rbuf_data_out_r;

genvar i;
for (i = 0; i < 32; i = i + 1)
begin
    assign wbuf_data_in_r[i] = wbuf_data_in[31-i];
    assign rbuf_data_out[i]  = rbuf_data_out_r[31-i];
end

RAMB18E1 #(
    .SIM_DEVICE("7SERIES"),
    .RAM_MODE("SDP"),
    .READ_WIDTH_A(1),
    .WRITE_WIDTH_B(36)             // 32 data bits, 4 (unused) parity bits
) wbuf (
    .CLKARDCLK(clk),               // 1-bit input: Read clk (port A)
    .CLKBWRCLK(clk),               // 1-bit input: Write clk (port B)

    .ENARDEN(wbuf_rd_en),          // 1-bit input: Read enable (port A)
    .ENBWREN(wbuf_wr_en),          // 1-bit input: Write enable (port B)
    .WEBWE(4'b1111),               // 4-bit input: byte-wide write enable

    .RSTREGARSTREG(1'b0),          // 1-bit input: A port register set/reset
    .RSTRAMARSTRAM(1'b0),          // 1-bit input: A port set/reset

    // addresses: 32-bit port has depth = 512, 9-bit address (bits [13:5] are used)
    //             1-bit port has depth = 16384 and uses the full 14-bit address
    //            unused bits are connected high
    .ADDRARDADDR(wbuf_rd_addr[13:0]),                   // 14-bit input: Read address
    .ADDRBWRADDR({2'b00, wbuf_wr_addr[6:0], 5'b11111}), // 14-bit input: Write address

    // data in
    .DIBDI(wbuf_data_in_r[31:16]), // 16-bit input: DI[31:16]
    .DIADI(wbuf_data_in_r[15:0]),  // 16-bit input: DI[15: 0]

    // data out
    .DOADO(wbuf_data_out[15:0])    // 16-bit output: we only use DO[0]
);

RAMB18E1 #(
    .SIM_DEVICE("7SERIES"),
    .RAM_MODE("SDP"),
    .READ_WIDTH_A(36),              // 32 data bits, 4 (unused) parity bits
    .WRITE_WIDTH_B(1)
) rbuf (
    .CLKARDCLK(clk),                // 1-bit input: Read clk (port A)
    .CLKBWRCLK(clk),                // 1-bit input: Write clk (port B)

    .ENARDEN(rbuf_rd_en),           // 1-bit input: Read enable (port A)
    .ENBWREN(rbuf_wr_en),           // 1-bit input: Write enable (port B)
    .WEBWE(4'b1111),                // 4-bit input: byte-wide write enable

    .RSTREGARSTREG(1'b0),           // 1-bit input: A port register set/reset
    .RSTRAMARSTRAM(1'b0),           // 1-bit input: A port set/reset

    // addresses: 32-bit port has depth = 512, 9-bit address (bits [13:5] are used)
    //             1-bit port has depth = 16384 and uses the full 14-bit address
    //            unused bits are connected high
    .ADDRARDADDR({2'b00, rbuf_rd_addr[6:0], 5'b11111}), // 14-bit input: Read address
    .ADDRBWRADDR(rbuf_wr_addr[13:0]),                   // 14-bit input: Write address

    // data in
    .DIBDI({15'b0, rbuf_data_in}),  // 16-bit input: we only use DI[0]

    // data out
    .DOBDO(rbuf_data_out_r[31:16]), // 16-bit output: DO[31:16]
    .DOADO(rbuf_data_out_r[15:0])   // 16-bit output: DO[15:0]
);

endmodule
