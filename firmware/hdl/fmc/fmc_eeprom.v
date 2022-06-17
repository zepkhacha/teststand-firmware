// This state machine interfaces to each installed FMC EEPROM

module fmc_eeprom (
    // clock and reset
    input clk, // 125-MHz clock
    input rst, // synchronous, active-hi reset

    // status
    input l12_dev_active, // L12 device has an active EEPROM
    input l08_dev_active, // L08 device has an active EEPROM
    input l12_dev_ext,    // L12 FMC EEPROM extended size
    input l08_dev_ext,    // L08 FMC EEPROM extended size
    input fmcs_ready,     // FMCs are ready for EEPROM communication
    output reg error_i2c, // I2C chip error found
    output reg error_id,  // FMC ID error found
    output reg [11:0] CS, // finite state machine's current state

    // write interface
    input wire [7:0] l12_fmc_id_request, // ID to store in L12 FMC
    input wire [7:0] l08_fmc_id_request, // ID to store in L08 FMC
    input wire write_start,              // initiate ID write on FMCs

    // read interface
    output reg [7:0] l12_fmc_id, // L12 FMC stored ID
    output reg [7:0] l08_fmc_id, // L08 FMC stored ID
    output reg fmc_ids_valid,    // ID values are valid

    // I2C signals
    input  scl_pad_i,    // 'clock' input from external pin
    output scl_pad_o,    // 'clock' output to tri-state driver
    output scl_padoen_o, // 'clock' enable signal for tri-state driver
    input  sda_pad_i,    // 'data' input from external pin
    output sda_pad_o,    // 'data' output to tri-state driver
    output sda_padoen_o  // 'data' enable signal for tri-state driver
);

// -------------------
// Signal declarations
// -------------------

reg i2c_wr_byte_ctrl = 1'b0;
reg update_regs      = 1'b0;

reg init_pause_cntr, dec_pause_cntr;
reg [20:0] pause_cntr;

wire rd_scl_pad_o,    wr_scl_pad_o;
wire rd_scl_padoen_o, wr_scl_padoen_o;
wire rd_sda_pad_o,    wr_sda_pad_o;
wire rd_sda_padoen_o, wr_sda_padoen_o;

reg i2c_dev_ext;
reg [6:0] i2c_dev_adr;
reg [7:0] i2c_reg_dat;

reg  i2c_active;
reg  i2c_start_write;
wire i2c_wr_done;
wire i2c_wr_error;

reg  i2c_start_read;
wire i2c_rd_rdy;
wire [7:0] i2c_rd_dat;
wire i2c_rd_error;


// ---------------------
// MUX interface signals
// ---------------------

// Route outputs from read or write byte controller
assign scl_pad_o    = (i2c_wr_byte_ctrl) ? wr_scl_pad_o    : rd_scl_pad_o;
assign scl_padoen_o = (i2c_wr_byte_ctrl) ? wr_scl_padoen_o : rd_scl_padoen_o;
assign sda_pad_o    = (i2c_wr_byte_ctrl) ? wr_sda_pad_o    : rd_sda_pad_o;
assign sda_padoen_o = (i2c_wr_byte_ctrl) ? wr_sda_padoen_o : rd_sda_padoen_o;


// -----------------------
// I2C interface instances
// -----------------------

// Connect the controller that writes one byte to the EEPROM
i2c_write_byte_eeprom i2c_write_byte_eeprom (
    // inputs
    .clk(clk),
    .reset(rst),
    .i2c_dev_ext(i2c_dev_ext),         // EEPROM has extended address width
    .i2c_dev_adr(i2c_dev_adr[6:0]),    // address of the device on the I2C bus
    .i2c_reg_adr(8'h00),               // EEPROM register address to write
    .i2c_reg_dat(i2c_reg_dat[7:0]),    // data register value
    .i2c_start_write(i2c_start_write), // initiate a byte write
    // outputs
    .i2c_wr_done(i2c_wr_done),         // the byte has been written
    .error(i2c_wr_error),
    // I2C signals
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(wr_scl_pad_o),
    .scl_padoen_o(wr_scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(wr_sda_pad_o),
    .sda_padoen_o(wr_sda_padoen_o)
);

// Connect the controller that reads one byte from the EEPROM
i2c_read_byte_eeprom i2c_read_byte_eeprom (
    // inputs
    .clk(clk),
    .reset(rst),
    .i2c_dev_ext(i2c_dev_ext),       // EEPROM has extended address width
    .i2c_dev_adr(i2c_dev_adr[6:0]),  // address of the device on the I2C bus
    .i2c_reg_adr(8'h00),             // EEPROM register address to read
    .i2c_start_read(i2c_start_read), // initiate a byte read
    // outputs
    .i2c_byte_rdy(i2c_rd_rdy),       // the byte is ready
    .i2c_rd_dat(i2c_rd_dat[7:0]),    // byte read from I2C device
    .error(i2c_rd_error),
    // I2C signals
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(rd_scl_pad_o),
    .scl_padoen_o(rd_scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(rd_sda_pad_o),
    .sda_padoen_o(rd_sda_padoen_o)
);


// ----------------------------------
// FMC EEPROM interface state machine
// ----------------------------------

// Create an counter used for pausing between bytes
always @(posedge clk) begin
    if (rst | init_pause_cntr)
        pause_cntr[20:0] <= 21'd1250000; // 1,250,000 = 10 msec @ 125 MHz
    else if (dec_pause_cntr)
        pause_cntr[20:0] <= pause_cntr[20:0] - 1;
end

// Select between device addresses
always @(posedge clk) begin
    if (update_regs) begin
        i2c_active       <= l08_dev_active;          // L08 FMC has an accessible EEPROM
        i2c_dev_ext      <= l08_dev_ext;             // L08 FMC EEPROM extended size
        i2c_dev_adr[6:0] <= 7'b1010_011;             // L08 FMC EEPROM address
        i2c_reg_dat[7:0] <= l08_fmc_id_request[7:0]; // L08 FMC ID request
    end
    else begin
        i2c_active       <= l12_dev_active;          // L12 FMC has an accessible EEPROM
        i2c_dev_ext      <= l12_dev_ext;             // L12 FMC EEPROM extended size
        i2c_dev_adr[6:0] <= 7'b1010_000;             // L12 FMC EEPROM address
        i2c_reg_dat[7:0] <= l12_fmc_id_request[7:0]; // L12 FMC ID request
    end
end

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [3:0]
    IDLE        = 4'd0,
    INIT_READ   = 4'd1,
    PAUSE       = 4'd2,
    REQ_BYTE    = 4'd3,
    WAIT_BYTE   = 4'd4,
    DONE_CHECK  = 4'd5,
    UPDATE_REGS = 4'd6,
    DONE_READ   = 4'd7,
    INIT_WRITE  = 4'd8,
    ERROR_I2C   = 4'd9,
    ERROR_ID    = 4'd10,
    SKIP_FMC    = 4'd11;

// Declare next state variable
reg [11:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (rst) begin
        CS <= 11'b0;      // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or fmcs_ready or i2c_rd_error or i2c_wr_error or i2c_rd_rdy or i2c_wr_done or update_regs or i2c_wr_byte_ctrl or write_start or l08_fmc_id[7:0] or l12_fmc_id[7:0] or pause_cntr[20:0]) begin
    NS = 11'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state as soon as 'rst' is negated
        CS[IDLE]: begin
            NS[INIT_READ] = 1'b1;
        end

        // Wait for FMCs to be ready
        CS[INIT_READ]: begin
            if (fmcs_ready) begin
                if ( i2c_active )
                    NS[PAUSE] = 1'b1;
                else
                    NS[SKIP_FMC] = 1'b1;
            end
            else
                NS[INIT_READ] = 1'b1;

        end

        // Pause before reading again
        CS[PAUSE]: begin
            if (pause_cntr[20:0] == 21'd0)
                NS[REQ_BYTE] = 1'b1;
            else
                NS[PAUSE] = 1'b1;
        end

        // Request a byte
        CS[REQ_BYTE]: begin
            NS[WAIT_BYTE] = 1'b1;
        end

        // Wait for the byte
        CS[WAIT_BYTE]: begin
            if (i2c_rd_error | i2c_wr_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_rd_rdy | i2c_wr_done)
                NS[DONE_CHECK] = 1'b1;
            else
                NS[WAIT_BYTE] = 1'b1;
        end

        // Check if all registers are done
        CS[DONE_CHECK]: begin
            if (update_regs) begin
                if (i2c_wr_byte_ctrl)
                    NS[INIT_READ] = 1'b1;
                else
                    NS[DONE_READ] = 1'b1;
            end
            else
                NS[UPDATE_REGS] = 1'b1;
        end

        // Update the registers
        CS[UPDATE_REGS]: begin
            NS[PAUSE] = 1'b1;
        end

        // Done
        CS[DONE_READ]: begin
            if ((l12_fmc_id[7:0] == 8'h00) | (l12_fmc_id[7:0] == 8'hFF) | (l08_fmc_id[7:0] == 8'h00) | (l08_fmc_id[7:0] == 8'hFF))
                NS[ERROR_ID] = 1'b1;
            else if (write_start)
                NS[INIT_WRITE] = 1'b1;
            else
                NS[DONE_READ] = 1'b1;
        end

        // Initiate a write
        CS[INIT_WRITE]: begin
            NS[PAUSE] = 1'b1;
        end

        // I2C error
        CS[ERROR_I2C]: begin
            NS[ERROR_I2C] = 1'b1;
        end

        // ID error
        CS[ERROR_ID]: begin
            if (write_start)
                NS[INIT_WRITE] = 1'b1;
            else
                NS[ERROR_ID] = 1'b1;
        end

        // FMC does not have an active FMC
        CS[SKIP_FMC]: begin
            if (update_regs)
                NS[DONE_READ] = 1'b1;
            else
                NS[UPDATE_REGS] = 1'b1;
        end

    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    i2c_start_write <= 1'b0;
    i2c_start_read  <= 1'b0;
    fmc_ids_valid   <= 1'b0;
    init_pause_cntr <= 1'b0;
    dec_pause_cntr  <= 1'b0;
    error_i2c       <= 1'b0;
    error_id        <= 1'b0;
    
    // Next states
    if (NS[IDLE]) begin
    end

    if (NS[INIT_READ]) begin
        // initialize the address and registers
        init_pause_cntr  <= 1'b1;
        i2c_wr_byte_ctrl <= 1'b0;
        update_regs      <= 1'b0;
        l12_fmc_id[7:0]  <= 8'h00;
        l08_fmc_id[7:0]  <= 8'h00;
    end

    if (NS[PAUSE]) begin
        dec_pause_cntr <= 1'b1;
    end
   
    if (NS[REQ_BYTE]) begin
        // kick off an I2C read or write
        if (i2c_wr_byte_ctrl)
            i2c_start_write <= 1'b1;
        else
            i2c_start_read  <= 1'b1;
    end

    if (NS[WAIT_BYTE]) begin
        // kick off an I2C read or write
        if (i2c_wr_byte_ctrl)
            i2c_start_write <= 1'b1;
        else
            i2c_start_read  <= 1'b1;
    end

    if (NS[DONE_CHECK]) begin
        init_pause_cntr <= 1'b1;

        if (~i2c_wr_byte_ctrl) begin
            if (update_regs)
                l08_fmc_id[7:0] <= i2c_rd_dat[7:0];
            else
                l12_fmc_id[7:0] <= i2c_rd_dat[7:0];
        end
    end

    if (NS[UPDATE_REGS]) begin
        init_pause_cntr <= 1'b1;
        update_regs     <= 1'b1;
    end

    if (NS[DONE_READ]) begin
        fmc_ids_valid <= 1'b1;
    end

    if (NS[INIT_WRITE]) begin
        init_pause_cntr  <= 1'b1;
        i2c_wr_byte_ctrl <= 1'b1;
        update_regs      <= 1'b0;
    end

    if (NS[ERROR_I2C]) begin
        error_i2c <= 1'b1;
    end

    if (NS[ERROR_ID]) begin
        error_id <= 1'b1;
    end

    if (NS[SKIP_FMC]) begin
        init_pause_cntr <= 1'b1;
        if (update_regs)
            l08_fmc_id[7:0] <= 8'hFE;
        else
            l12_fmc_id[7:0] <= 8'hFE;
    end
end

endmodule
