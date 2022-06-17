// This state machine reads from the PCA8574APW I2C-bus, 8-bit expander

module i2c_read_expander (
    // clock and reset
    input clk,                    // 125-MHz clock
    input reset,                  // synchronous, active-hi reset
    // controls
    input sm_start,               // initiate this state machine
    output reg sm_running,        // this state machine is running
    // read information
    input [1:0] fmc_loc,          // FMC LOC
    input [7:0] channel_sel,      // PCA9548APW channel select
    output reg [7:0] reg_out,     // register value returned
    output reg reg_out_valid,     // register value is valid
    output reg read_error,        // 
    // I2C interface
    input i2c_wr_byte_done,       // byte write request has finished
    input i2c_byte_error,         // byte read/write error thrown
    input i2c_byte_rdy,           // the byte is ready
    input [7:0] i2c_rd_dat,       // byte read from I2C device
    output reg i2c_rd_byte_ctrl,  // read = 1, write = 0
    output reg [7:0] i2c_dev_adr, // address of the device on the I2C bus
    output reg [7:0] i2c_reg_dat, // chip register value to write
    output reg i2c_start_write,   // start the sequence to write a byte
    output reg i2c_start_read     // start the sequence to read a byte
);

// Create a counter used for writing the programming sequence
reg [2:0] byte_cntr;

// Select between device addresses
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_dev_adr[7:0] <= {4'b1110, 1'b1, fmc_loc[1:0], 1'b0}; // PCA9548APW
    if (byte_cntr[2:0] == 3'd1) i2c_dev_adr[7:0] <= 8'b0111000_1;                        // PCA8574APW
    if (byte_cntr[2:0] == 3'd2) i2c_dev_adr[7:0] <= {4'b1110, 1'b1, fmc_loc[1:0], 1'b0}; // PCA9548APW
end

// Select between control registers
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_reg_dat[7:0] <= channel_sel[7:0]; // select switch channel
    // read requested register
    if (byte_cntr[2:0] == 3'd2) i2c_reg_dat[7:0] <= 8'b000_00000;     // deselect switch channel
end

// Select between read and write byte controller (0 = read, 1 = write)
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_rd_byte_ctrl <= 1'b0; // write
    if (byte_cntr[2:0] == 3'd1) i2c_rd_byte_ctrl <= 1'b1; // read
    if (byte_cntr[2:0] == 3'd2) i2c_rd_byte_ctrl <= 1'b0; // write
end

// ----------------------------------------------
// Four states are used to read each byte:
//   1. Initialize the transfer
//   2. Wait for the data to be ready
//   3. Store the data
//   4. Check if all of the data has been written
// ----------------------------------------------

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [2:0]
    IDLE      = 3'd0,
    INIT      = 3'd1,
    REQ_BYTE  = 3'd2,
    WAIT_BYTE = 3'd3,
    CHECK_CNT = 3'd4,
    INC_CNTR  = 3'd5,
    DONE      = 3'd6,
    ERROR     = 3'd7;

// Declare current state and next state variables
reg [7:0] CS;
reg [7:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 8'b0;       // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or sm_start or i2c_byte_rdy or i2c_wr_byte_done or i2c_byte_error or byte_cntr[2:0]) begin
    NS = 8'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state as soon as 'reset' is negated
        CS[IDLE]: begin
            NS[INIT] = 1'b1;
        end

        // Wait for a configuration request
        CS[INIT]: begin
            if (sm_start)
                NS[REQ_BYTE] = 1'b1;
            else
                NS[INIT] = 1'b1;
        end

        // Request a byte
        CS[REQ_BYTE]: begin
            NS[WAIT_BYTE] = 1'b1;
        end

        // Wait for the byte
        CS[WAIT_BYTE]: begin
            if (i2c_byte_error)
                NS[ERROR] = 1'b1;
            else if (i2c_wr_byte_done | i2c_byte_rdy)
                NS[CHECK_CNT] = 1'b1;
            else
                NS[WAIT_BYTE] = 1'b1;
        end

        // See if all registers have been written
        CS[CHECK_CNT]: begin
            if (byte_cntr[2:0] == 3'd2) // total bytes
                NS[DONE] = 1'b1;
            else
                NS[INC_CNTR] = 1'b1;
        end

        // Update the device address and control register
        CS[INC_CNTR]: begin
            NS[REQ_BYTE] = 1'b1; // no delay between bytes
        end

        // Done
        CS[DONE]: begin
            NS[INIT] = 1'b1;
        end

        // Error
        CS[ERROR]: begin
            NS[INIT] = 1'b1;
        end
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    i2c_start_write <= 1'b0;
    i2c_start_read  <= 1'b0;
    sm_running      <= 1'b1;
    reg_out_valid   <= 1'b0;
    read_error      <= 1'b0;
    
    // next states
    if (NS[IDLE]) begin
        sm_running <= 1'b0;
    end

    if (NS[INIT]) begin
        // initialize the address and register
        byte_cntr[2:0] <= 3'b0;
        sm_running <= 1'b0;
    end
   
    if (NS[REQ_BYTE]) begin
        // kick off an I2C read or write
        if (byte_cntr[2:0] == 3'd1) // read bytes
            i2c_start_read <= 1'b1;
        else
            i2c_start_write <= 1'b1;
    end

    if (NS[WAIT_BYTE]) begin
        // kick off an I2C read or write
        if (byte_cntr[2:0] == 3'd1) // read bytes
            i2c_start_read <= 1'b1;
        else
            i2c_start_write <= 1'b1;
    end

    if (NS[CHECK_CNT]) begin
        // store byte
        if (byte_cntr[2:0] == 3'd1)
            reg_out[7:0] <= i2c_rd_dat[7:0];
    end

    if (NS[INC_CNTR]) begin
        // increment the address and register
        byte_cntr[2:0] <= byte_cntr[2:0] + 1'b1;
    end

    if (NS[DONE]) begin
        reg_out_valid <= 1'b1;
    end

    if (NS[ERROR]) begin
        read_error <= 1'b1;
    end
end

endmodule
