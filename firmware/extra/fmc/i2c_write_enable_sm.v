// This state machine controls the I2C writes to enable all requested SFP devices

module i2c_write_enable_sm (
    // inputs
    input clk,                    // 125-MHz clock
    input reset,                  // synchronous, active-hi reset from 'rst_from_ipb'
    input [1:0] fmc_loc,          // 
    input [7:0] sfp_enable,       // 
    input i2c_en_start,           // 
    input i2c_wr_done,            // byte write request has finished
    // outputs
    output reg [7:0] i2c_dev_adr, // address of the device on the I2C bus
    output reg [7:0] i2c_reg_dat, // chip register value to write
    output reg i2c_start_write,   // start the sequence to write a byte
    output reg sm_busy            // 
);

// Create a counter used for writing the programming sequence
reg [2:0] byte_cntr;

// Select between device addresses
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_dev_adr[7:0] <= {5'b11101, fmc_loc[1:0], 1'b0};
    if (byte_cntr[2:0] == 3'd1) i2c_dev_adr[7:0] <=  8'b0111000_0;
    if (byte_cntr[2:0] == 3'd2) i2c_dev_adr[7:0] <= {5'b11101, fmc_loc[1:0], 1'b0};
end

// Select between control registers
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_reg_dat[7:0] <= 8'b0000_0100;
    if (byte_cntr[2:0] == 3'd1) i2c_reg_dat[7:0] <= sfp_enable[7:0];
    if (byte_cntr[2:0] == 3'd2) i2c_reg_dat[7:0] <= 8'b0000_0000;
end

// ----------------------------------------------
// Four states are used to write each byte:
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
    DONE      = 3'd6;
    
// Declare current state and next state variables
reg [6:0] CS;
reg [6:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 7'b0;       // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments) 
always @(CS or i2c_en_start or i2c_wr_done or byte_cntr[2:0]) begin
    NS = 7'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state as soon as 'reset' is negated
        CS[IDLE]: begin
            NS[INIT] = 1'b1;
        end

        // Wait for a configuration request
        CS[INIT]: begin
            if (i2c_en_start)
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
            if (i2c_wr_done)
                NS[CHECK_CNT] = 1'b1;
            else
                NS[WAIT_BYTE] = 1'b1;
        end

        // See if all registers have been written
        CS[CHECK_CNT]: begin
            if (byte_cntr[2:0] == 3'd2)
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
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    i2c_start_write <= 1'b0;
    sm_busy         <= 1'b0;

    // next states
    if (NS[IDLE]) begin
    end

    if (NS[INIT]) begin
        // initialize the address and register
        byte_cntr[2:0] <= 3'b0;
    end

    if (NS[REQ_BYTE]) begin
        // kick off an I2C write
        i2c_start_write <= 1'b1;
        sm_busy <= 1'b1;
    end

    if (NS[WAIT_BYTE]) begin
        // kick off an I2C write
        i2c_start_write <= 1'b1;
        sm_busy <= 1'b1;
    end

    if (NS[CHECK_CNT]) begin
        sm_busy <= 1'b1;
    end

    if (NS[INC_CNTR]) begin
        // increment the address and register
        byte_cntr[2:0] <= byte_cntr[2:0] + 1'b1;
        sm_busy <= 1'b1;
    end

    if (NS[DONE]) begin
    end
end

endmodule
