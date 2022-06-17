// This state machine conducts FMC connectivity checks and initial configuration

module fpga_startup_sm (
    // clock and reset
    input clk,                     // 125-MHz clock
    input reset,                   // synchronous, active-hi reset
    // controls
    input [7:0] fmc_mod_type,      // 
    input fmc_absent,              // 
    input i2c_int_n,               // 
    input i2c_error,               // 
    // expander, read
    input [7:0] i2c_reg_dat,       // 
    input i2c_reg_valid,           // 
    output reg start_read,         // 
    // expander, write
    input i2c_wr_rdy,              // 
    output reg start_write,        // 
    output wire [7:0] wr_ctrl_reg, // 
    // configuration
    output reg [7:0] channel_sel,  // 
    // status connections
    output reg error_i2c_chip,     // 
    output reg error_fmc_absent,   // 
    output reg error_fmc_mod_type, // 
    output reg error_fmc_int_n,    // 
    output reg sm_running,         // 
    output reg [27:0] CS           // current state variable
);

// Create a counter used for pausing between states
reg init_pause_cntr, dec_pause_cntr;
reg [26:0] pause_cntr;
always @(posedge clk) begin
    if (reset | init_pause_cntr)
        pause_cntr[26:0] <= 27'd125000000; // 125,000,000 = 1 sec @ 125 MHz
    else if (dec_pause_cntr)
        pause_cntr[26:0] <= pause_cntr[26:0] - 1;
end

// write all ones to expanders
assign wr_ctrl_reg = 8'hFF;

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [4:0]
    IDLE           = 5'd0,
    PRE_WAIT       = 5'd1,
    CHECK_FMC_ABS  = 5'd2,
    START_WR_I2C0  = 5'd3,
    PAUSE_WR_I2C0  = 5'd4,
    START_WR_I2C1  = 5'd5,
    PAUSE_WR_I2C1  = 5'd6,
    START_WR_I2C2  = 5'd7,
    PAUSE_WR_I2C2  = 5'd8,
    START_WR_I2C3  = 5'd9,
    PAUSE_WR_I2C3  = 5'd10,
    START_WR_I2C4  = 5'd11,
    PAUSE_WR_I2C4  = 5'd12,
    START_RD_I2C0  = 5'd13,
    PAUSE_RD_I2C0  = 5'd14,
    START_RD_I2C1  = 5'd15,
    PAUSE_RD_I2C1  = 5'd16,
    START_RD_I2C3  = 5'd17,
    PAUSE_RD_I2C3  = 5'd18,
    START_RD_I2C4  = 5'd19,
    PAUSE_RD_I2C4  = 5'd20,
    POST_WAIT      = 5'd21,
    CHECK_INT_N    = 5'd22,
    MONITOR        = 5'd23,
    ERROR_I2C      = 5'd24,
    ERROR_FMC_ABS  = 5'd25,
    ERROR_MOD_TYPE = 5'd26,
    ERROR_INT_N    = 5'd27;

// Declare next state variable
reg [27:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 28'b0;      // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or pause_cntr[26:0] or fmc_absent or i2c_wr_rdy or i2c_reg_valid or i2c_reg_dat[7:0] or fmc_mod_type[7:0] or i2c_int_n or i2c_error) begin
    NS = 28'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state as soon as 'reset' is negated
        CS[IDLE]: begin
            NS[PRE_WAIT] = 1'b1;
        end

        // --------------
        // Initial checks
        // --------------

        // Wait for I2C chips to be ready
        CS[PRE_WAIT]: begin
            if (pause_cntr[26:0] == 27'd0)
                NS[CHECK_FMC_ABS] = 1'b1;
            else
                NS[PRE_WAIT] = 1'b1;
        end

        // Check that the FMC is attached
        CS[CHECK_FMC_ABS]: begin
            if (fmc_absent)
                NS[ERROR_FMC_ABS] = 1'b1; // hard error
            else begin
                if (fmc_mod_type[7:0] == 8'b00000010)
                    NS[MONITOR] = 1'b1;
                else
                    NS[START_WR_I2C0] = 1'b1; // EDA-270X-V2 FMC startup
            end
        end

        // -----------------
        // PCA8574APW writes
        // -----------------

        CS[START_WR_I2C0]: begin
            NS[PAUSE_WR_I2C0] = 1'b1;
        end

        CS[PAUSE_WR_I2C0]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_rdy)
                NS[START_WR_I2C1] = 1'b1;
            else
                NS[PAUSE_WR_I2C0] = 1'b1;
        end

        CS[START_WR_I2C1]: begin
            NS[PAUSE_WR_I2C1] = 1'b1;
        end

        CS[PAUSE_WR_I2C1]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_rdy)
                NS[START_WR_I2C2] = 1'b1;
            else
                NS[PAUSE_WR_I2C1] = 1'b1;
        end

        CS[START_WR_I2C2]: begin
            NS[PAUSE_WR_I2C2] = 1'b1;
        end

        CS[PAUSE_WR_I2C2]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_rdy)
                NS[START_WR_I2C3] = 1'b1;
            else
                NS[PAUSE_WR_I2C2] = 1'b1;
        end

        CS[START_WR_I2C3]: begin
            NS[PAUSE_WR_I2C3] = 1'b1;
        end

        CS[PAUSE_WR_I2C3]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_rdy)
                NS[START_WR_I2C4] = 1'b1;
            else
                NS[PAUSE_WR_I2C3] = 1'b1;
        end

        CS[START_WR_I2C4]: begin
            NS[PAUSE_WR_I2C4] = 1'b1;
        end

        CS[PAUSE_WR_I2C4]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_rdy)
                NS[START_RD_I2C0] = 1'b1;
            else
                NS[PAUSE_WR_I2C4] = 1'b1;
        end

        // ----------------
        // PCA8574APW reads
        // ----------------

        CS[START_RD_I2C0]: begin
            NS[PAUSE_RD_I2C0] = 1'b1;
        end

        // Check the FMC module type
        CS[PAUSE_RD_I2C0]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_valid) begin
                if (i2c_reg_dat[7:0] == fmc_mod_type[7:0])
                    NS[START_RD_I2C1] = 1'b1;
                else
                    NS[ERROR_MOD_TYPE] = 1'b1; // hard error
            end
            else
                NS[PAUSE_RD_I2C0] = 1'b1;
        end

        CS[START_RD_I2C1]: begin
            NS[PAUSE_RD_I2C1] = 1'b1;
        end

        CS[PAUSE_RD_I2C1]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_valid)
                NS[START_RD_I2C3] = 1'b1;
            else
                NS[PAUSE_RD_I2C1] = 1'b1;
        end

        CS[START_RD_I2C3]: begin
            NS[PAUSE_RD_I2C3] = 1'b1;
        end

        CS[PAUSE_RD_I2C3]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_valid)
                NS[START_RD_I2C4] = 1'b1;
            else
                NS[PAUSE_RD_I2C3] = 1'b1;
        end

        CS[START_RD_I2C4]: begin
            NS[PAUSE_RD_I2C4] = 1'b1;
        end

        CS[PAUSE_RD_I2C4]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_valid)
                NS[POST_WAIT] = 1'b1;
            else
                NS[PAUSE_RD_I2C4] = 1'b1;
        end
        
        // ------------
        // Final checks
        // ------------

        CS[POST_WAIT]: begin
            if (pause_cntr[26:0] == 27'd0)
                NS[CHECK_INT_N] = 1'b1;
            else
                NS[POST_WAIT] = 1'b1;
        end

        // Check that the signals have not changed
        CS[CHECK_INT_N]: begin
            if (i2c_int_n)
                NS[MONITOR] = 1'b1;
            else
                NS[ERROR_INT_N] = 1'b1; // hard error
        end

        // Check that the FMC remains attached
        CS[MONITOR]: begin
            if (fmc_absent)
                NS[ERROR_FMC_ABS] = 1'b1;
            else
                NS[MONITOR] = 1'b1;
        end

        // ------------
        // Error states
        // ------------

        // I2C error thrown
        CS[ERROR_I2C]: begin
            NS[ERROR_I2C] = 1'b1;
        end

        // FMC is absent
        CS[ERROR_FMC_ABS]: begin
            NS[ERROR_FMC_ABS] = 1'b1;
        end

        // Wrong module type
        CS[ERROR_MOD_TYPE]: begin
            NS[ERROR_MOD_TYPE] = 1'b1;
        end

        // Interrupt signal is high
        CS[ERROR_INT_N]: begin
            NS[ERROR_INT_N] = 1'b1;
        end
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    sm_running         <= 1'b1;
    init_pause_cntr    <= 1'b0;
    dec_pause_cntr     <= 1'b0;
    start_write        <= 1'b0;
    start_read         <= 1'b0;
    channel_sel[7:0]   <= 8'd0;
    error_i2c_chip     <= 1'b0;
    error_fmc_absent   <= 1'b0;
    error_fmc_mod_type <= 1'b0;
    error_fmc_int_n    <= 1'b0;

    // next states
    if (NS[IDLE]) begin
        init_pause_cntr <= 1'b1;
    end

    if (NS[PRE_WAIT]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[START_WR_I2C0]) begin
        start_write <= 1'b1;
        channel_sel[7:0] <= 8'b000_00001;
    end

    if (NS[PAUSE_WR_I2C0]) begin
        channel_sel[7:0] <= 8'b000_00001;
    end

    if (NS[START_WR_I2C1]) begin
        start_write <= 1'b1;
        channel_sel[7:0] <= 8'b000_00010;
    end

    if (NS[PAUSE_WR_I2C1]) begin
        channel_sel[7:0] <= 8'b000_00010;
    end

    if (NS[START_WR_I2C2]) begin
        start_write <= 1'b1;
        channel_sel[7:0] <= 8'b000_00100;
    end

    if (NS[PAUSE_WR_I2C2]) begin
        channel_sel[7:0] <= 8'b000_00100;
    end

    if (NS[START_WR_I2C3]) begin
        start_write <= 1'b1;
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[PAUSE_WR_I2C3]) begin
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[START_WR_I2C4]) begin
        start_write <= 1'b1;
        channel_sel[7:0] <= 8'b000_10000;
    end

    if (NS[PAUSE_WR_I2C4]) begin
        channel_sel[7:0] <= 8'b000_10000;
    end

    if (NS[START_RD_I2C0]) begin
        start_read <= 1'b1;
        channel_sel[7:0] <= 8'b000_00001;
    end

    if (NS[PAUSE_RD_I2C0]) begin
        channel_sel[7:0] <= 8'b000_00001;
    end

    if (NS[START_RD_I2C1]) begin
        start_read <= 1'b1;
        channel_sel[7:0] <= 8'b000_00010;
    end

    if (NS[PAUSE_RD_I2C1]) begin
        channel_sel[7:0] <= 8'b000_00010;
    end

    if (NS[START_RD_I2C3]) begin
        start_read <= 1'b1;
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[PAUSE_RD_I2C3]) begin
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[START_RD_I2C4]) begin
        start_read <= 1'b1;
        channel_sel[7:0] <= 8'b000_10000;
    end

    if (NS[PAUSE_RD_I2C4]) begin
        channel_sel[7:0] <= 8'b000_10000;
        init_pause_cntr <= 1'b1;
    end

    if (NS[POST_WAIT]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[CHECK_INT_N]) begin
    end

    if (NS[MONITOR]) begin
        sm_running <= 1'b0;
    end

    if (NS[ERROR_I2C]) begin
        error_i2c_chip <= 1'b1;
    end

    if (NS[ERROR_FMC_ABS]) begin
        error_fmc_absent <= 1'b1;
    end

    if (NS[ERROR_MOD_TYPE]) begin
        error_fmc_mod_type <= 1'b1;
    end

    if (NS[ERROR_INT_N]) begin
        error_fmc_int_n <= 1'b1;
    end
end

endmodule
