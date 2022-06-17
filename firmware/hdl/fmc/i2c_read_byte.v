// This module will read one byte from the device chip

module i2c_read_byte (
    // inputs
    input clk,               // 125-MHz clock
    input reset,             // reset
    input [7:0] i2c_dev_adr, // selection of I2C device
    input i2c_start_read,    // initiate a byte read
    // outputs
    output reg i2c_byte_rdy, // the byte is ready
    output [7:0] i2c_rd_dat, // byte read from I2C device
    output reg error,        // error has occured
    // I2C signals
    input  scl_pad_i,        // 'clock' input from external pin
    output scl_pad_o,        // 'clock' output to tri-state driver
    output scl_padoen_o,     // 'clock' enable signal for tri-state driver
    input  sda_pad_i,        // 'data' input from external pin
    output sda_pad_o,        // 'data' output to tri-state driver
    output sda_padoen_o      // 'data' enable signal for tri-state driver
);

// Create registers for the state machine outputs
reg core_en;
reg i2c_start;
reg i2c_stop;
reg i2c_write;
reg i2c_read;
reg itxack;

wire irxack;
wire cmd_ack;

// Connect the I2C controller module
// This came from the 'opencores' website at http://opencores.org/project,i2c
// The 'wishbone' interface was eliminated, and direct connections made to the 'byte controller' block
i2c_master_byte_ctrl byte_controller (
    // inputs
    .clk(clk),              // master clock
    .rst(reset),            // synchronous active high reset
    .nReset(1'b1),          // asynchronous active low reset, NOT USED SO HELD HIGH
    .ena(core_en),          // core enable signal
    .clk_cnt(16'd499),      // = (clk/(5*SCL)) - 1, so for 125-MHz 'clk' and 50-kHz SCL, need 499
    .start(i2c_start),      // prepend an I2C 'start' cycle
    .stop(i2c_stop),        // post-pend an I2C 'stop' cycle
    .read(i2c_read),        // do an I2C 'read' operation
    .write(i2c_write),      // do an I2C 'write' operation
    .ack_in(itxack),        // ACK/NACK to send out on I2C bus after a READ
    .din(i2c_dev_adr[7:0]), // byte that we send out on the device
    // outputs
    .cmd_ack(cmd_ack),      // the command is complete
    .ack_out(irxack),       // status of the ACK bit from the I2C bus
    .dout(i2c_rd_dat[7:0]), // byte read from the device
    // I2C signals
    .scl_i(scl_pad_i),      // 'clock' input from external pin
    .scl_o(scl_pad_o),      // 'clock' output to tri-state driver
    .scl_oen(scl_padoen_o), // 'clock' enable signal for tri-state driver
    .sda_i(sda_pad_i),      // 'data' input from external pin
    .sda_o(sda_pad_o),      // 'data' output to tri-state driver
    .sda_oen(sda_padoen_o)  // 'data' enable signal for tri-state driver
);

// Connect a state machine that will drive the 'byte_controller' through the whole
// sequence required to write a byte to the chip. This is replacing the 'wishbone'
// interface of the original 'opencores' project.

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [3:0]
    IDLE      = 4'd0,
    ENABLE    = 4'd1,
    WAIT      = 4'd2,
    DEV_INIT1 = 4'd3,
    DEV_INIT2 = 4'd4,
    DEV_INIT3 = 4'd5,
    DEV_INIT4 = 4'd6,
    READ_INIT = 4'd7,
    READ_WAIT = 4'd8,
    ERROR     = 4'd9,
    DONE      = 4'd10;

// Declare current state and next state variables
reg [10:0] CS;
reg [10:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 11'b0;      // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or i2c_start_read or cmd_ack or irxack) begin
    NS = 11'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state as soon as 'reset' is negated
        CS[IDLE]: begin
            NS[ENABLE] = 1'b1;
        end

        // Enable the I2C controller; it will start up using the counter pre-scale value
        CS[ENABLE]: begin
            NS[WAIT] = 1'b1;
        end

        // Wait for a request to read a byte
        CS[WAIT]: begin
            if (i2c_start_read)
                NS[DEV_INIT1] = 1'b1;
            else
                NS[WAIT] = 1'b1;
        end

        // Initialize the device address and the R/W bit
        CS[DEV_INIT1]: begin
            NS[DEV_INIT2] = 1'b1;
        end

        // Send the device address and the R/W bit
        CS[DEV_INIT2]: begin
            NS[DEV_INIT3] = 1'b1;
        end

        // Wait for completion of the transfer
        CS[DEV_INIT3]: begin
            if (cmd_ack)
                NS[DEV_INIT4] = 1'b1;
            else
                NS[DEV_INIT3] = 1'b1;
        end

        // Check the state of the ACK bit on the I2C bus
        CS[DEV_INIT4]: begin
            if (irxack)
                NS[ERROR] = 1'b1;
            else
                NS[READ_INIT] = 1'b1; // no delay
        end
        
        // Start a read
        CS[READ_INIT]: begin
            NS[READ_WAIT] = 1'b1;
        end

        // Wait for completion of the transfer
        CS[READ_WAIT]: begin
            if (cmd_ack)
                NS[DONE] = 1'b1;
            else
                NS[READ_WAIT] = 1'b1;
        end

        // Do some type of error reporting
        CS[ERROR]: begin
            NS[DONE] = 1'b1;
        end

        // Done
        CS[DONE]: begin
            NS[IDLE] = 1'b1;
        end
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    core_en      <= 1'b1; // enabled except when explicitly disabled
    i2c_start    <= 1'b0;
    i2c_stop     <= 1'b0;
    i2c_write    <= 1'b0;
    i2c_read     <= 1'b0;
    i2c_byte_rdy <= 1'b0;
    itxack       <= 1'b0;
    error        <= 1'b0;

    // next states
    if (NS[IDLE]) begin
        // disable the core when idle
        core_en <= 1'b0;
    end

    if (NS[ENABLE]) begin
    end

    if (NS[WAIT]) begin
    end

    if (NS[DEV_INIT1]) begin
    end

    if (NS[DEV_INIT2]) begin
        // set the byte controller's STA and R/W bits
        i2c_start <= 1'b1;
        i2c_write <= 1'b1;
    end

    if (NS[DEV_INIT3]) begin
    end

    if (NS[DEV_INIT4]) begin
    end

    if (NS[READ_INIT]) begin
        i2c_read <= 1'b1;
    end

    if (NS[READ_WAIT]) begin
        // set ACK to '1' (NACK), set STO bit
        itxack   <= 1'b1;
        i2c_stop <= 1'b1;
    end

    if (NS[ERROR]) begin
        error <= 1'b1;
    end

    if (NS[DONE]) begin
        i2c_byte_rdy <= 1'b1;
    end
end

endmodule
