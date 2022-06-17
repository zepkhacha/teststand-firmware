// This state machine generically reads information registers

module sfp_generic_read_sm (
    // clock and reset
    input clk,                      // 125-MHz clock
    input reset,                    // synchronous, active-hi reset
    // controls
    input start_sm,                 // 
    input i2c_lines_busy,           // 
    input i2c_error,                // 
    // transceiver, read
    input [127:0] i2c_reg_sfp_dat,  // 
    input i2c_reg_sfp_valid,        // 
    output reg start_read_sfp,      // 
    // status connections
    output reg [127:0] sfp_reg_out, // 
    output reg sfp_reg_out_valid,   // 
    output reg error_i2c_chip,      // 
    output reg sm_running,          // 
    output reg [6:0] CS             // current state variable
);

// Create a counter used for pausing between states
reg init_pause_cntr, dec_pause_cntr;
reg [23:0] pause_cntr;
always @(posedge clk) begin
    if (reset | init_pause_cntr)
        pause_cntr[23:0] <= 24'd12500000; // 12,500,000 = 100 msec @ 125 MHz
    else if (dec_pause_cntr)
        pause_cntr[23:0] <= pause_cntr[23:0] - 1;
end

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [2:0]
    IDLE         = 3'd0,
    START_RD_REG = 3'd1,
    PAUSE_RD_REG = 3'd2,
    STORE_RD_REG = 3'd3,
    WAIT         = 3'd4,
    DONE         = 3'd5,
    ERROR_I2C    = 3'd6;

// Declare next state variable
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
always @(CS or start_sm or i2c_lines_busy or i2c_error or i2c_reg_sfp_valid or pause_cntr[23:0]) begin
    NS = 7'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state when requested and ready
        CS[IDLE]: begin
            if (start_sm & ~i2c_lines_busy)
                NS[START_RD_REG] = 1'b1;
            else
                NS[IDLE] = 1'b1;
        end

        CS[START_RD_REG]: begin
            NS[PAUSE_RD_REG] = 1'b1;
        end

        CS[PAUSE_RD_REG]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_sfp_valid)
                NS[STORE_RD_REG] = 1'b1;
            else
                NS[PAUSE_RD_REG] = 1'b1;
        end

        CS[STORE_RD_REG]: begin
            NS[WAIT] = 1'b1;
        end

        CS[WAIT]: begin
            if (pause_cntr[23:0] == 24'd0)
                NS[DONE] = 1'b1;
            else
                NS[WAIT] = 1'b1;
        end

        CS[DONE]: begin
            NS[IDLE] = 1'b1;
        end

        CS[ERROR_I2C]: begin
            NS[IDLE] = 1'b1;
        end
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    init_pause_cntr   <= 1'b0;
    dec_pause_cntr    <= 1'b0;
    start_read_sfp    <= 1'b0;
    sm_running        <= 1'b1;
    sfp_reg_out_valid <= 1'b0;
    error_i2c_chip    <= 1'b0;

    // next states
    if (NS[IDLE]) begin
        sm_running <= 1'b0;
    end

    if (NS[START_RD_REG]) begin
        start_read_sfp <= 1'b1;
    end

    if (NS[PAUSE_RD_REG]) begin
    end

    if (NS[STORE_RD_REG]) begin
        sfp_reg_out[127:0] <= i2c_reg_sfp_dat[127:0];
        init_pause_cntr <= 1'b1;
    end

    if (NS[WAIT]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[DONE]) begin
        sfp_reg_out_valid <= 1'b1;
    end

    if (NS[ERROR_I2C]) begin
        error_i2c_chip <= 1'b1;
    end
end

endmodule
