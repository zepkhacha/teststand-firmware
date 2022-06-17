// This state machine enables the data transmission of a subset of SFP ports

module sfp_transmission_sm (
    // clock and reset
    input clk,                                   // 125-MHz clock
    input reset,                                 // synchronous, active-hi reset
    // controls
    input start_sm,                              // from IPbus
    input [7:0] sfp_requested_ports,             // from IPbus
    input i2c_lines_busy,                        // 
    input i2c_error,                             // 
    // expander, read
    input [7:0] i2c_reg_exp_dat,                 // 
    input i2c_reg_exp_valid,                     // 
    output reg start_read_exp,                   // 
    // exander, write
    input i2c_wr_exp_rdy,                        // 
    output reg start_write_exp,                  // 
    output reg [7:0] wr_ctrl_reg,                // 
    // transceiver, read
    input [127:0] i2c_reg_sfp_dat,               // 
    input i2c_reg_sfp_valid,                     // 
    output reg start_read_sfp,                   // 
    // configuration
    output reg [7:0] channel_sel,                // 
    output reg eeprom_map_sel,                   // SFP MSA = 0, digital diagnostic = 1
    output reg [7:0] eeprom_start_adr,           // EEPROM register address to read
    output reg [5:0] eeprom_num_regs,            // number of registers to read sequentially
    // error statuses
    output reg [7:0] error_mod_abs,              // to status registers
    output reg [1:0] error_sfp_type,             // to status registers
    output reg [7:0] error_tx_fault,             // to status registers
    output reg error_sfp_alarms,                 // to status registers
    output reg error_i2c_chip,                   // to status registers
    // SFP alarm flags
    output reg [7:0] sfp_alarm_temp_high,
    output reg [7:0] sfp_alarm_temp_low,
    output reg [7:0] sfp_alarm_vcc_high,
    output reg [7:0] sfp_alarm_vcc_low,
    output reg [7:0] sfp_alarm_tx_bias_high,
    output reg [7:0] sfp_alarm_tx_bias_low,
    output reg [7:0] sfp_alarm_tx_power_high,
    output reg [7:0] sfp_alarm_tx_power_low,
    output reg [7:0] sfp_alarm_rx_power_high,
    output reg [7:0] sfp_alarm_rx_power_low,
    // SFP warning flags
    output reg [7:0] sfp_warning_temp_high,
    output reg [7:0] sfp_warning_temp_low,
    output reg [7:0] sfp_warning_vcc_high,
    output reg [7:0] sfp_warning_vcc_low,
    output reg [7:0] sfp_warning_tx_bias_high,
    output reg [7:0] sfp_warning_tx_bias_low,
    output reg [7:0] sfp_warning_tx_power_high,
    output reg [7:0] sfp_warning_tx_power_low,
    output reg [7:0] sfp_warning_rx_power_high,
    output reg [7:0] sfp_warning_rx_power_low,
    // status connections
    output reg  [   7:0] sfp_enabled_ports,      // 
    output wire [1023:0] sfp_sn_vec,             // SFP transceiver serial numbers
    output reg  sm_running,                      // 
    output reg  [  32:0] CS                      // current state variable
);

// Internal registers
reg [4:0] sfp_cntr;
reg read_ddmi, ports_enabled, passed_checks;

// Create a memory for the transceiver serial numbers
reg [127:0] sfp_sn [7:0];

genvar i;
for (i = 0; i < 8; i = i + 1)
begin
    assign sfp_sn_vec[(128*i + 127):(128*i)] = sfp_sn[i];
end

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
parameter [5:0]
    IDLE           = 6'd0,
    START_RD_I2C1  = 6'd1,
    PAUSE_RD_I2C1  = 6'd2,
    CHECK_MOD_ABS  = 6'd3,
    INC_CNTR       = 6'd4,
    CHECK_SFP_EN   = 6'd5,
    START_RD_ID    = 6'd6,
    PAUSE_RD_ID    = 6'd7,
    STORE_RD_ID    = 6'd8,
    START_RD_PN    = 6'd9,
    PAUSE_RD_PN    = 6'd10,
    STORE_RD_PN    = 6'd11,
    CHECK_SFP_MSA  = 6'd12,
    START_RD_AW    = 6'd13,
    PAUSE_RD_AW    = 6'd14,
    STORE_RD_AW    = 6'd15,
    CHECK_SFP_DDMI = 6'd16,
    START_RD_I2C3  = 6'd17,
    PAUSE_RD_I2C3  = 6'd18,
    CHECK_TX_FAULT = 6'd19,
    START_WR_I2C2  = 6'd20,
    PAUSE_WR_I2C2  = 6'd21,
    WAIT1          = 6'd22,
    CHECK_SFP_PWR  = 6'd23,
    START_DIS_SFPS = 6'd24,
    PAUSE_DIS_SFPS = 6'd25,
    WAIT2          = 6'd26,
    START_RD_SN    = 6'd27,
    PAUSE_RD_SN    = 6'd28,
    STORE_RD_SN    = 6'd29,
    DONE           = 6'd30,
    ERROR_I2C      = 6'd31,
    ERROR_SYS      = 6'd32;

// Declare next state variable
reg [32:0] NS;

// Sequential always block for state transitions (use non-blocking [<=] assignments)
always @(posedge clk) begin
    if (reset) begin
        CS <= 33'b0;      // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else begin
        CS <= NS;         // set state bits to next state
    end
end

// Combinational always block to determine next state (use blocking [=] assignments)
always @(CS or start_sm or i2c_lines_busy or i2c_error or i2c_reg_exp_valid or error_mod_abs[7:0] or sfp_requested_ports[7:0] or sfp_cntr[4:0] or passed_checks or ports_enabled or read_ddmi or i2c_reg_sfp_valid or error_sfp_type[1:0] or error_sfp_alarms or error_tx_fault[7:0] or i2c_wr_exp_rdy or pause_cntr[23:0]) begin
    NS = 33'b0; // default all bits to zero; will override one bit

    case (1'b1)
        // Leave the IDLE state when requested and ready
        CS[IDLE]: begin
            if (start_sm & ~i2c_lines_busy)
                NS[START_RD_I2C1] = 1'b1;
            else
                NS[IDLE] = 1'b1;
        end

        // ---------------------
        // Module absent reading
        // ---------------------

        CS[START_RD_I2C1]: begin
            NS[PAUSE_RD_I2C1] = 1'b1;
        end

        CS[PAUSE_RD_I2C1]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_exp_valid)
                NS[CHECK_MOD_ABS] = 1'b1;
            else
                NS[PAUSE_RD_I2C1] = 1'b1;
        end

        CS[CHECK_MOD_ABS]: begin
            if (error_mod_abs[7:0] == 8'h00)
                NS[CHECK_SFP_EN] = 1'b1;
            else
                NS[ERROR_SYS] = 1'b1;
        end

        // -----------------
        // Transceiver reads
        // -----------------

        CS[INC_CNTR]: begin
            NS[CHECK_SFP_EN] = 1'b1;
        end

        // Check if this port is requested
        CS[CHECK_SFP_EN]: begin
            // We're done checking ports
            if (sfp_cntr[4:0] == 5'd8)
                // Done
                if (passed_checks)
                    NS[DONE] = 1'b1;
                // Check DDMI information
                else if (ports_enabled)
                    NS[CHECK_SFP_PWR] = 1'b1;
                // Check DDMI information
                else if (read_ddmi)
                    NS[CHECK_SFP_DDMI] = 1'b1;
                // Check MSA information
                else
                    NS[CHECK_SFP_MSA] = 1'b1;

            // This port is requested to be enabled
            else if (sfp_requested_ports[sfp_cntr])
                // Read DDMI information
                if (passed_checks)
                    NS[START_RD_SN] = 1'b1;
                // Read DDMI information
                else if (read_ddmi)
                    NS[START_RD_AW] = 1'b1;
                // Read MSA information
                else
                    NS[START_RD_ID] = 1'b1;

            // Skip this port
            else
                NS[INC_CNTR] = 1'b1;
        end

        CS[START_RD_ID]: begin
            NS[PAUSE_RD_ID] = 1'b1;
        end

        CS[PAUSE_RD_ID]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_sfp_valid)
                NS[STORE_RD_ID] = 1'b1;
            else
                NS[PAUSE_RD_ID] = 1'b1;
        end

        CS[STORE_RD_ID]: begin
            NS[START_RD_PN] = 1'b1;
        end

        CS[START_RD_PN]: begin
            NS[PAUSE_RD_PN] = 1'b1;
        end

        CS[PAUSE_RD_PN]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_sfp_valid)
                NS[STORE_RD_PN] = 1'b1;
            else
                NS[PAUSE_RD_PN] = 1'b1;
        end

        CS[STORE_RD_PN]: begin
            NS[INC_CNTR] = 1'b1;
        end

        CS[CHECK_SFP_MSA]: begin
            if (error_sfp_type[1:0])
                NS[ERROR_SYS] = 1'b1;
            else
                NS[CHECK_SFP_EN] = 1'b1;
        end

        CS[START_RD_AW]: begin
            NS[PAUSE_RD_AW] = 1'b1;
        end

        CS[PAUSE_RD_AW]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_sfp_valid)
                NS[STORE_RD_AW] = 1'b1;
            else
                NS[PAUSE_RD_AW] = 1'b1;
        end

        CS[STORE_RD_AW]: begin
            NS[INC_CNTR] = 1'b1;
        end

        CS[CHECK_SFP_DDMI]: begin
            if (error_sfp_alarms)
                NS[ERROR_SYS] = 1'b1;
            else
                NS[START_RD_I2C3] = 1'b1;
        end

        // ----------------
        // TX fault reading
        // ----------------

        CS[START_RD_I2C3]: begin
            NS[PAUSE_RD_I2C3] = 1'b1;
        end

        CS[PAUSE_RD_I2C3]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_exp_valid)
                NS[CHECK_TX_FAULT] = 1'b1;
            else
                NS[PAUSE_RD_I2C3] = 1'b1;
        end

        CS[CHECK_TX_FAULT]: begin
            if (error_tx_fault[7:0] == 8'h00)
                NS[START_WR_I2C2] = 1'b1;
            else
                NS[ERROR_SYS] = 1'b1;
        end

        // ---------------
        // SFP TX enabling
        // ---------------

        CS[START_WR_I2C2]: begin
            NS[PAUSE_WR_I2C2] = 1'b1;
        end

        CS[PAUSE_WR_I2C2]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_exp_rdy)
                NS[WAIT1] = 1'b1;
            else
                NS[PAUSE_WR_I2C2] = 1'b1;
        end

        CS[WAIT1]: begin
            if (pause_cntr[23:0] == 24'd0)
                NS[CHECK_SFP_EN] = 1'b1;
            else
                NS[WAIT1] = 1'b1;
        end

        CS[CHECK_SFP_PWR]: begin
            if (error_sfp_alarms)
                NS[START_DIS_SFPS] = 1'b1;
            else
                NS[CHECK_SFP_EN] = 1'b1;
        end

        CS[START_DIS_SFPS]: begin
            NS[PAUSE_DIS_SFPS] = 1'b1;
        end

        CS[PAUSE_DIS_SFPS]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_wr_exp_rdy)
                NS[WAIT2] = 1'b1;
            else
                NS[PAUSE_DIS_SFPS] = 1'b1;
        end

        CS[WAIT2]: begin
            if (pause_cntr[23:0] == 24'd0)
                NS[ERROR_SYS] = 1'b1;
            else
                NS[WAIT2] = 1'b1;
        end

        CS[START_RD_SN]: begin
            NS[PAUSE_RD_SN] = 1'b1;
        end

        CS[PAUSE_RD_SN]: begin
            if (i2c_error)
                NS[ERROR_I2C] = 1'b1;
            else if (i2c_reg_sfp_valid)
                NS[STORE_RD_SN] = 1'b1;
            else
                NS[PAUSE_RD_SN] = 1'b1;
        end

        CS[STORE_RD_SN]: begin
            NS[INC_CNTR] = 1'b1;
        end

        CS[DONE]: begin
            NS[IDLE] = 1'b1;
        end

        // ------------
        // Error states
        // ------------

        // I2C error thrown
        CS[ERROR_I2C]: begin
            NS[IDLE] = 1'b1;
        end

        // Not all transceivers are attached, or
        // alarm/warning or device type detected in a transceiver, or
        // a transceiver reports a TX fault
        CS[ERROR_SYS]: begin
            NS[IDLE] = 1'b1;
        end
    endcase
end

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    init_pause_cntr  <= 1'b0;
    dec_pause_cntr   <= 1'b0;
    start_read_exp   <= 1'b0;
    start_read_sfp   <= 1'b0;
    start_write_exp  <= 1'b0;
    channel_sel[7:0] <= 8'd0;
    sm_running       <= 1'b1;

    // next states
    if (NS[IDLE]) begin
        sfp_cntr[4:0] <= 5'd0;
        ports_enabled <= 1'b0;
        read_ddmi     <= 1'b0;
        passed_checks <= 1'b0;
        sm_running    <= 1'b0;

        if (reset) begin
            // clear enabled ports
            // they will be all disabled by 'fpga_startup_sm'
            sfp_enabled_ports[7:0] <= 8'd0;

            // clear error statuses
            error_mod_abs[7:0]  <= 8'd0;
            error_sfp_type[1:0] <= 2'd0;
            error_tx_fault[7:0] <= 8'd0;
            error_sfp_alarms    <= 1'b0;
            error_i2c_chip      <= 1'b0;

            // clear alarm flags
            sfp_alarm_temp_high[7:0]     <= 8'd0;
            sfp_alarm_temp_low[7:0]      <= 8'd0;
            sfp_alarm_vcc_high[7:0]      <= 8'd0;
            sfp_alarm_vcc_low[7:0]       <= 8'd0;
            sfp_alarm_tx_bias_high[7:0]  <= 8'd0;
            sfp_alarm_tx_bias_low[7:0]   <= 8'd0;
            sfp_alarm_tx_power_high[7:0] <= 8'd0;
            sfp_alarm_tx_power_low[7:0]  <= 8'd0;
            sfp_alarm_rx_power_high[7:0] <= 8'd0;
            sfp_alarm_rx_power_low[7:0]  <= 8'd0;

            // clear warning flags
            sfp_warning_temp_high[7:0]     <= 8'd0;
            sfp_warning_temp_low[7:0]      <= 8'd0;
            sfp_warning_vcc_high[7:0]      <= 8'd0;
            sfp_warning_vcc_low[7:0]       <= 8'd0;
            sfp_warning_tx_bias_high[7:0]  <= 8'd0;
            sfp_warning_tx_bias_low[7:0]   <= 8'd0;
            sfp_warning_tx_power_high[7:0] <= 8'd0;
            sfp_warning_tx_power_low[7:0]  <= 8'd0;
            sfp_warning_rx_power_high[7:0] <= 8'd0;
            sfp_warning_rx_power_low[7:0]  <= 8'd0;

            // clear serial numbers
            sfp_sn[0] <= 128'd0;
            sfp_sn[1] <= 128'd0;
            sfp_sn[2] <= 128'd0;
            sfp_sn[3] <= 128'd0;
            sfp_sn[4] <= 128'd0;
            sfp_sn[5] <= 128'd0;
            sfp_sn[6] <= 128'd0;
            sfp_sn[7] <= 128'd0;
        end
    end

    if (NS[START_RD_I2C1]) begin
        // clear error statuses
        error_mod_abs[7:0]  <= 8'd0;
        error_sfp_type[1:0] <= 2'd0;
        error_tx_fault[7:0] <= 8'd0;
        error_sfp_alarms    <= 1'b0;
        error_i2c_chip      <= 1'b0;

        // clear alarm flags
        sfp_alarm_temp_high[7:0]     <= 8'd0;
        sfp_alarm_temp_low[7:0]      <= 8'd0;
        sfp_alarm_vcc_high[7:0]      <= 8'd0;
        sfp_alarm_vcc_low[7:0]       <= 8'd0;
        sfp_alarm_tx_bias_high[7:0]  <= 8'd0;
        sfp_alarm_tx_bias_low[7:0]   <= 8'd0;
        sfp_alarm_tx_power_high[7:0] <= 8'd0;
        sfp_alarm_tx_power_low[7:0]  <= 8'd0;
        sfp_alarm_rx_power_high[7:0] <= 8'd0;
        sfp_alarm_rx_power_low[7:0]  <= 8'd0;

        // clear warning flags
        sfp_warning_temp_high[7:0]     <= 8'd0;
        sfp_warning_temp_low[7:0]      <= 8'd0;
        sfp_warning_vcc_high[7:0]      <= 8'd0;
        sfp_warning_vcc_low[7:0]       <= 8'd0;
        sfp_warning_tx_bias_high[7:0]  <= 8'd0;
        sfp_warning_tx_bias_low[7:0]   <= 8'd0;
        sfp_warning_tx_power_high[7:0] <= 8'd0;
        sfp_warning_tx_power_low[7:0]  <= 8'd0;
        sfp_warning_rx_power_high[7:0] <= 8'd0;
        sfp_warning_rx_power_low[7:0]  <= 8'd0;

        // clear serial numbers
        sfp_sn[0] <= 128'd0;
        sfp_sn[1] <= 128'd0;
        sfp_sn[2] <= 128'd0;
        sfp_sn[3] <= 128'd0;
        sfp_sn[4] <= 128'd0;
        sfp_sn[5] <= 128'd0;
        sfp_sn[6] <= 128'd0;
        sfp_sn[7] <= 128'd0;

        start_read_exp   <= 1'b1;
        channel_sel[7:0] <= 8'b000_00010;
    end

    if (NS[PAUSE_RD_I2C1]) begin
        channel_sel[7:0] <= 8'b000_00010;
    end

    if (NS[CHECK_MOD_ABS]) begin
        error_mod_abs[7:0] <= sfp_requested_ports[7:0] & i2c_reg_exp_dat[7:0]; 
    end

    if (NS[INC_CNTR]) begin
        sfp_cntr[4:0] <= sfp_cntr[4:0] + 1'b1;
    end

    if (NS[CHECK_SFP_EN]) begin
    end

    if (NS[START_RD_ID]) begin
        start_read_sfp        <= 1'b1;
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b0;
        eeprom_start_adr[7:0] <= 8'd37;
        eeprom_num_regs[5:0]  <= 6'd3;
    end

    if (NS[PAUSE_RD_ID]) begin
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b0;
        eeprom_start_adr[7:0] <= 8'd37;
        eeprom_num_regs[5:0]  <= 6'd3;
    end

    if (NS[STORE_RD_ID]) begin
        if (i2c_reg_sfp_dat[23:0] != 24'h00_90_65)
            error_sfp_type[0] <= 1'b1;
    end

    if (NS[START_RD_PN]) begin
        start_read_sfp        <= 1'b1;
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b0;
        eeprom_start_adr[7:0] <= 8'd40;
        eeprom_num_regs[5:0]  <= 6'd16;
    end

    if (NS[PAUSE_RD_PN]) begin
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b0;
        eeprom_start_adr[7:0] <= 8'd40;
        eeprom_num_regs[5:0]  <= 6'd16;
    end

    if (NS[STORE_RD_PN]) begin
        if (i2c_reg_sfp_dat[127:0] != 128'h46_54_4c_46_31_33_31_38_50_33_42_54_4c_20_20_20)
            error_sfp_type[1] <= 1'b1;
    end

    if (NS[CHECK_SFP_MSA]) begin
        sfp_cntr[4:0] <= 5'd0;
        read_ddmi     <= 1'b1;
    end

    if (NS[START_RD_AW]) begin
        start_read_sfp        <= 1'b1;
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b1;
        eeprom_start_adr[7:0] <= 8'd112;
        eeprom_num_regs[5:0]  <= 6'd6;
    end

    if (NS[PAUSE_RD_AW]) begin
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b1;
        eeprom_start_adr[7:0] <= 8'd112;
        eeprom_num_regs[5:0]  <= 6'd6;
    end

    if (NS[STORE_RD_AW]) begin
        // alarm flags
        sfp_alarm_temp_high[sfp_cntr]     <= i2c_reg_sfp_dat[47];
        sfp_alarm_temp_low[sfp_cntr]      <= i2c_reg_sfp_dat[46];
        sfp_alarm_vcc_high[sfp_cntr]      <= i2c_reg_sfp_dat[45];
        sfp_alarm_vcc_low[sfp_cntr]       <= i2c_reg_sfp_dat[44];
        sfp_alarm_tx_bias_high[sfp_cntr]  <= i2c_reg_sfp_dat[43];
        sfp_alarm_tx_bias_low[sfp_cntr]   <= i2c_reg_sfp_dat[42];
        sfp_alarm_tx_power_high[sfp_cntr] <= i2c_reg_sfp_dat[41];
        sfp_alarm_tx_power_low[sfp_cntr]  <= i2c_reg_sfp_dat[40];
        sfp_alarm_rx_power_high[sfp_cntr] <= i2c_reg_sfp_dat[39];
        sfp_alarm_rx_power_low[sfp_cntr]  <= i2c_reg_sfp_dat[38];

        // warning flags
        sfp_warning_temp_high[sfp_cntr]     <= i2c_reg_sfp_dat[15];
        sfp_warning_temp_low[sfp_cntr]      <= i2c_reg_sfp_dat[14];
        sfp_warning_vcc_high[sfp_cntr]      <= i2c_reg_sfp_dat[13];
        sfp_warning_vcc_low[sfp_cntr]       <= i2c_reg_sfp_dat[12];
        sfp_warning_tx_bias_high[sfp_cntr]  <= i2c_reg_sfp_dat[11];
        sfp_warning_tx_bias_low[sfp_cntr]   <= i2c_reg_sfp_dat[10];
        sfp_warning_tx_power_high[sfp_cntr] <= i2c_reg_sfp_dat[ 9];
        sfp_warning_tx_power_low[sfp_cntr]  <= i2c_reg_sfp_dat[ 8];
        sfp_warning_rx_power_high[sfp_cntr] <= i2c_reg_sfp_dat[ 7];
        sfp_warning_rx_power_low[sfp_cntr]  <= i2c_reg_sfp_dat[ 6];

        if (ports_enabled) begin
            if (i2c_reg_sfp_dat[47:39] | i2c_reg_sfp_dat[15:7])
                error_sfp_alarms <= 1'b1;
        end
        else begin
            if (i2c_reg_sfp_dat[47:43] | i2c_reg_sfp_dat[41] | i2c_reg_sfp_dat[39] | i2c_reg_sfp_dat[15:11] | i2c_reg_sfp_dat[9] | i2c_reg_sfp_dat[7])
                error_sfp_alarms <= 1'b1;
        end
    end

    if (NS[CHECK_SFP_DDMI]) begin
    end

    if (NS[START_RD_I2C3]) begin
        start_read_exp <= 1'b1;
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[PAUSE_RD_I2C3]) begin
        channel_sel[7:0] <= 8'b000_01000;
    end

    if (NS[CHECK_TX_FAULT]) begin
        error_tx_fault[7:0] <= sfp_requested_ports[7:0] & i2c_reg_exp_dat[7:0];
    end

    if (NS[START_WR_I2C2]) begin
        start_write_exp  <= 1'b1;
        channel_sel[7:0] <= 8'b000_00100;
        wr_ctrl_reg[7:0] <= ~sfp_requested_ports[7:0];
    end

    if (NS[PAUSE_WR_I2C2]) begin
        channel_sel[7:0] <= 8'b000_00100;
        wr_ctrl_reg[7:0] <= ~sfp_requested_ports[7:0];
        init_pause_cntr  <= 1'b1;
    end

    if (NS[WAIT1]) begin
        error_sfp_alarms <= 1'b0;
        sfp_cntr[4:0]    <= 5'd0;
        ports_enabled    <= 1'b1;
        dec_pause_cntr   <= 1'b1;
    end

    if (NS[CHECK_SFP_PWR]) begin
        sfp_cntr[4:0] <= 5'd0;
        passed_checks <= 1'b1;
    end

    if (NS[START_DIS_SFPS]) begin
        start_write_exp  <= 1'b1;
        channel_sel[7:0] <= 8'b000_00100;
        wr_ctrl_reg[7:0] <= 8'hFF;
    end

    if (NS[PAUSE_DIS_SFPS]) begin
        channel_sel[7:0] <= 8'b000_00100;
        wr_ctrl_reg[7:0] <= 8'hFF;
        init_pause_cntr  <= 1'b1;
    end

    if (NS[WAIT2]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[START_RD_SN]) begin
        start_read_sfp        <= 1'b1;
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b0;
        eeprom_start_adr[7:0] <= 8'd68;
        eeprom_num_regs[5:0]  <= 6'd16;
    end

    if (NS[PAUSE_RD_SN]) begin
        channel_sel[sfp_cntr] <= 1'b1;
        eeprom_map_sel        <= 1'b0;
        eeprom_start_adr[7:0] <= 8'd68;
        eeprom_num_regs[5:0]  <= 6'd16;
    end

    if (NS[STORE_RD_SN]) begin
        sfp_sn[sfp_cntr] <= i2c_reg_sfp_dat[127:0];
    end

    if (NS[DONE]) begin
        sfp_enabled_ports[7:0] <= sfp_requested_ports[7:0];
    end

    if (NS[ERROR_I2C]) begin
        error_i2c_chip <= 1'b1;
    end

    if (NS[ERROR_SYS]) begin
    end
end

endmodule
