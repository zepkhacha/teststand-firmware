// This state machine reads from the installed SFP transceiver

module i2c_read_transceiver (
    // clock and reset
    input clk,                    // 125-MHz clock
    input reset,                  // synchronous, active-hi reset
    // controls
    input sm_start,               // initiate this state machine
    // read information
    input [1:0] fmc_loc,          // FMC LOC
    input [7:0] channel_sel,      // PCA9548APW channel select
    input eeprom_map_sel,         // SFP MSA = 0, digital diagnostic = 1
    input [7:0] eeprom_start_adr, // EEPROM register address to read
    input [5:0] eeprom_num_regs,  // number of registers to read sequentially
    output wire [127:0] reg_out,  // register value returned
    output reg reg_out_valid,     // register value is valid
    output reg read_error,        // 
    // I2C interface
    input i2c_wr_byte_done,       // byte write request has finished
    input i2c_byte_error,         // byte read/write error thrown
    input i2c_byte_rdy,           // the byte is ready
    input [7:0] i2c_rd_dat,       // byte read from I2C device
    output reg i2c_rd_byte_ctrl,  // SFP read = 1, PCA write = 0
    output reg [7:0] i2c_dev_adr, // address of the device on the I2C bus
    output reg [7:0] i2c_reg_dat, // chip register value to write
    output reg i2c_start_write,   // start the sequence to write a byte
    output reg i2c_start_read     // start the sequence to read a byte
);

// Internal registers
reg [2:0] byte_cntr;
reg [5:0] reg_cntr;
reg [7:0] eeprom_reg_adr;
reg [7:0] byte_from_device [15:0];

assign reg_out = {byte_from_device[15], byte_from_device[14], byte_from_device[13], byte_from_device[12], byte_from_device[11],
                  byte_from_device[10], byte_from_device[ 9], byte_from_device[ 8], byte_from_device[ 7], byte_from_device[ 6],
                  byte_from_device[ 5], byte_from_device[ 4], byte_from_device[ 3], byte_from_device[ 2], byte_from_device[ 1],
                  byte_from_device[ 0]};

// Select between device addresses
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_dev_adr[7:0] <= {4'b1110, 1'b0, fmc_loc[1:0], 1'b0}; // PCA9548APW
    if (byte_cntr[2:0] == 3'd1) i2c_dev_adr[7:0] <= {6'b101000, eeprom_map_sel, 1'b0};   // SFP transceiver, only [7:1] used
    if (byte_cntr[2:0] == 3'd2) i2c_dev_adr[7:0] <= {4'b1110, 1'b0, fmc_loc[1:0], 1'b0}; // PCA9548APW
end

// Select between control registers
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_reg_dat[7:0] <= channel_sel[7:0];    // select switch channel
    if (byte_cntr[2:0] == 3'd1) i2c_reg_dat[7:0] <= eeprom_reg_adr[7:0]; // EEPROM address
    if (byte_cntr[2:0] == 3'd2) i2c_reg_dat[7:0] <= 8'b000_00000;        // deselect switch channel
end

// Select between read and write byte controller (0 = SFP read, 1 = PCA write)
always @(posedge clk) begin
    if (byte_cntr[2:0] == 3'd0) i2c_rd_byte_ctrl <= 1'b0; // PCA write
    if (byte_cntr[2:0] == 3'd1) i2c_rd_byte_ctrl <= 1'b1; // SFP read
    if (byte_cntr[2:0] == 3'd2) i2c_rd_byte_ctrl <= 1'b0; // PCA write
end


// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [3:0]
    IDLE         = 4'd0,
    INIT         = 4'd1,
    REQ_BYTE     = 4'd2,
    WAIT_BYTE    = 4'd3,
    CHECK_CNT    = 4'd4,
    INC_REG_CNTR = 4'd5,
    INC_I2C_CNTR = 4'd6,
    DONE         = 4'd7,
    ERROR        = 4'd8;

// Declare current state and next state variables
reg [8:0] CS;
reg [8:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 9'b0;       // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or sm_start or i2c_byte_rdy or i2c_wr_byte_done or i2c_byte_error or byte_cntr[2:0] or reg_cntr[5:0] or eeprom_num_regs[5:0]) begin
    NS = 9'b0; // default all bits to zero; will override one bit

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
            else if ((byte_cntr[2:0] == 3'd1) & (reg_cntr[5:0]  < eeprom_num_regs[5:0]))
                NS[INC_REG_CNTR] = 1'b1;
            else
                NS[INC_I2C_CNTR] = 1'b1;
        end

        // Update the EEPROM address
        CS[INC_REG_CNTR]: begin
            NS[REQ_BYTE] = 1'b1; // no delay between bytes
        end

        // Update the device address and control register
        CS[INC_I2C_CNTR]: begin
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
    reg_out_valid   <= 1'b0;
    read_error      <= 1'b0;
    
    // next states
    if (NS[IDLE]) begin
    end

    if (NS[INIT]) begin
        // initialize the address and registers
        byte_cntr[2:0] <= 3'b0; // start index at zero
        reg_cntr[5:0]  <= 6'b1; // start index at one
        byte_from_device[ 0] <= 8'b0;
        byte_from_device[ 1] <= 8'b0;
        byte_from_device[ 2] <= 8'b0;
        byte_from_device[ 3] <= 8'b0;
        byte_from_device[ 4] <= 8'b0;
        byte_from_device[ 5] <= 8'b0;
        byte_from_device[ 6] <= 8'b0;
        byte_from_device[ 7] <= 8'b0;
        byte_from_device[ 8] <= 8'b0;
        byte_from_device[ 9] <= 8'b0;
        byte_from_device[10] <= 8'b0;
        byte_from_device[11] <= 8'b0;
        byte_from_device[12] <= 8'b0;
        byte_from_device[13] <= 8'b0;
        byte_from_device[14] <= 8'b0;
        byte_from_device[15] <= 8'b0;
    end
   
    if (NS[REQ_BYTE]) begin
        // kick off an I2C read or write
        if (byte_cntr[2:0] == 3'd1)
            i2c_start_read <= 1'b1;
        else begin
            i2c_start_write <= 1'b1;
            eeprom_reg_adr[7:0] <= eeprom_start_adr[7:0];
        end
    end

    if (NS[WAIT_BYTE]) begin
        // kick off an I2C read or write
        if (byte_cntr[2:0] == 3'd1)
            i2c_start_read <= 1'b1;
        else
            i2c_start_write <= 1'b1;
    end

    if (NS[CHECK_CNT]) begin
        // store byte
        if (byte_cntr[2:0] == 3'd1)
            byte_from_device[eeprom_num_regs-reg_cntr] <= i2c_rd_dat[7:0];
    end

    if (NS[INC_REG_CNTR]) begin
        // increment the address and register
        reg_cntr[5:0] <= reg_cntr[5:0] + 1'b1;
        eeprom_reg_adr[7:0] <= eeprom_reg_adr[7:0] + 1'b1;
    end

    if (NS[INC_I2C_CNTR]) begin
        // increment the address
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
