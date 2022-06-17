// This state machine monitors and diagnoses any change to the SFP ports

module sfp_setting_change_sm (
    // clock and reset
    input clk,                             // 125-MHz clock
    input reset,                           // synchronous, active-hi reset
    // controls
    input start_sm,                        // 
    input i2c_lines_busy,                  // 
    input i2c_error,                       // 
    // current states
    input i2c_int_n,                       // 
    input sfp_enabled_ports_changed,       // 
    input [7:0] sfp_enabled_ports,         // enabled ports for transmission
    // expander, read
    input [7:0] i2c_reg_dat,               // 
    input i2c_reg_valid,                   // 
    output reg start_read,                 // 
    output reg [7:0] channel_sel,          // 
    // status connections
    output reg [ 7:0] error_mod_abs,       // 
    output reg [ 7:0] error_tx_fault,      // 
    output reg [ 7:0] error_rx_los,        // 
    output reg [ 7:0] sfp_change_mod_abs,  // 
    output reg [ 7:0] sfp_change_tx_fault, // 
    output reg [ 7:0] sfp_change_rx_los,   // 
    output reg [ 7:0] sfp_mod_abs,         // 
    output reg [ 7:0] sfp_tx_fault,        // 
    output reg [ 7:0] sfp_rx_los,          // 
    output reg sm_running,                 // 
    output reg [10:0] CS                   // current state variable
);

reg [7:0] curr_sfp_mod_abs;
reg [7:0] curr_sfp_tx_fault;
reg [7:0] curr_sfp_rx_los;

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [3:0]
    IDLE           = 4'd0,
    START_RD_I2C1  = 4'd1,
    PAUSE_RD_I2C1  = 4'd2,
    START_RD_I2C3  = 4'd3,
    PAUSE_RD_I2C3  = 4'd4,
    START_RD_I2C4  = 4'd5,
    PAUSE_RD_I2C4  = 4'd6,
    STORE_I2C4_DAT = 4'd7,
    COMPARE        = 4'd8,
    MONITOR        = 4'd9,
    ERROR_I2C      = 4'd10;

// Declare next state variable
reg [10:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 11'b0;       // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or start_sm or i2c_error or i2c_reg_valid or i2c_int_n or i2c_lines_busy or sfp_enabled_ports_changed) begin
    NS = 11'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state as soon as 'start_sm' is asserted
        CS[IDLE]: begin
            if (start_sm)
                NS[START_RD_I2C1] = 1'b1;
            else
                NS[IDLE] = 1'b1;
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
                NS[STORE_I2C4_DAT] = 1'b1;
            else
                NS[PAUSE_RD_I2C4] = 1'b1;
        end

        CS[STORE_I2C4_DAT]: begin
            NS[COMPARE] = 1'b1;
        end

        CS[COMPARE]: begin
            NS[MONITOR] = 1'b1;
        end

        // Monitor for any change(s)
        CS[MONITOR]: begin
            if ((~i2c_int_n | sfp_enabled_ports_changed) & ~i2c_lines_busy)
                NS[START_RD_I2C1] = 1'b1;
            else
                NS[MONITOR] = 1'b1;
        end

        // I2C error thrown
        CS[ERROR_I2C]: begin
            // try again
            NS[START_RD_I2C1] = 1'b1;
        end
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    start_read       <= 1'b0;
    channel_sel[7:0] <= 8'd0;
    sm_running       <= 1'b1;

    // next states
    if (NS[IDLE]) begin
        sm_running <= 1'b0;
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
        curr_sfp_mod_abs[7:0] <= i2c_reg_dat[7:0];
    end

    if (NS[PAUSE_RD_I2C3]) begin
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[START_RD_I2C4]) begin
        start_read <= 1'b1;
        channel_sel[7:0] <= 8'b000_10000;
        curr_sfp_tx_fault[7:0] <= i2c_reg_dat[7:0];
    end

    if (NS[PAUSE_RD_I2C4]) begin
        channel_sel[7:0] <= 8'b000_10000;
    end

    if (NS[STORE_I2C4_DAT]) begin
        curr_sfp_rx_los[7:0] <= i2c_reg_dat[7:0];
    end

    if (NS[COMPARE]) begin
        // determine changes
        sfp_change_mod_abs[7:0]  <= (sfp_mod_abs[7:0]  ^ curr_sfp_mod_abs[7:0] ) & sfp_enabled_ports[7:0];
        sfp_change_tx_fault[7:0] <= (sfp_tx_fault[7:0] ^ curr_sfp_tx_fault[7:0]) & sfp_enabled_ports[7:0];
        sfp_change_rx_los[7:0]   <= (sfp_rx_los[7:0]   ^ curr_sfp_rx_los[7:0]  ) & sfp_enabled_ports[7:0];

        // determine error conditions
        error_mod_abs[7:0]  <= sfp_enabled_ports[7:0] & curr_sfp_mod_abs[7:0];
        error_tx_fault[7:0] <= sfp_enabled_ports[7:0] & curr_sfp_tx_fault[7:0];
        error_rx_los[7:0]   <= sfp_enabled_ports[7:0] & curr_sfp_rx_los[7:0];

        // update the output states
        sfp_mod_abs[7:0]  <= curr_sfp_mod_abs[7:0];
        sfp_tx_fault[7:0] <= curr_sfp_tx_fault[7:0];
        sfp_rx_los[7:0]   <= curr_sfp_rx_los[7:0];
    end

    if (NS[MONITOR]) begin
        sm_running <= 1'b0;
    end

    if (NS[ERROR_I2C]) begin
    end
end

endmodule
