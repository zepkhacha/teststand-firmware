// This module will activate the appropriate SFP on the TCDS card

module i2c_top (
    // clock and reset
    input clk,   // 125-MHz clock
    input reset, // synchronous, active-high reset

    // control signals
    input [1:0] fmc_loc,               // L8 or L12 LOC
    input [7:0] fmc_mod_type,          // EDA-02707 or EDA-02708 FMC
    input fmc_absent,                  // FMC absent signal
    input [7:0] sfp_requested_ports_i, // from IPbus
    input i2c_en_start,                // from IPbus
    input i2c_rd_start,                // from IPbus

    // generic read interface
    input  [  7:0] channel_sel_in,
    input  eeprom_map_sel_in,
    input  [  7:0] eeprom_start_adr_in,
    input  [  5:0] eeprom_num_regs_in,
    output [127:0] eeprom_reg_out,
    output eeprom_reg_out_valid,

    // status signals
    output [   7:0] sfp_enabled_ports,
    output [1023:0] sfp_sn_vec,
    output [   7:0] sfp_mod_abs,
    output [   7:0] sfp_tx_fault,
    output [   7:0] sfp_rx_los,

    output [7:0] change_mod_abs,
    output [7:0] change_tx_fault,
    output [7:0] change_rx_los,

    output [27:0] fs_state,
    output [32:0] st_state,
    output [10:0] ssc_state,
    output [ 6:0] sgr_state,

    // warning signals
    output [7:0] change_error_mod_abs,
    output [7:0] change_error_tx_fault,
    output [7:0] change_error_rx_los,

    // error signals
    output error_fmc_absent,
    output error_fmc_mod_type,
    output error_fmc_int_n,
    output error_startup_i2c,

    output [7:0] sfp_en_error_mod_abs,
    output [1:0] sfp_en_error_sfp_type,
    output [7:0] sfp_en_error_tx_fault,
    output sfp_en_error_sfp_alarms,
    output sfp_en_error_i2c_chip,

    // SFP alarm flags
    output [7:0] sfp_alarm_temp_high,
    output [7:0] sfp_alarm_temp_low,
    output [7:0] sfp_alarm_vcc_high,
    output [7:0] sfp_alarm_vcc_low,
    output [7:0] sfp_alarm_tx_bias_high,
    output [7:0] sfp_alarm_tx_bias_low,
    output [7:0] sfp_alarm_tx_power_high,
    output [7:0] sfp_alarm_tx_power_low,
    output [7:0] sfp_alarm_rx_power_high,
    output [7:0] sfp_alarm_rx_power_low,

    // SFP warning flags
    output [7:0] sfp_warning_temp_high,
    output [7:0] sfp_warning_temp_low,
    output [7:0] sfp_warning_vcc_high,
    output [7:0] sfp_warning_vcc_low,
    output [7:0] sfp_warning_tx_bias_high,
    output [7:0] sfp_warning_tx_bias_low,
    output [7:0] sfp_warning_tx_power_high,
    output [7:0] sfp_warning_tx_power_low,
    output [7:0] sfp_warning_rx_power_high,
    output [7:0] sfp_warning_rx_power_low,

    // I2C signals
    input  i2c_int_n_i,  // active-low I2C interrupt signal
    input  scl_pad_i,    // 'clock' input from external pin
    output scl_pad_o,    // 'clock' output to tri-state driver
    output scl_padoen_o, // 'clock' enable signal for tri-state driver
    input  sda_pad_i,    // 'data' input from external pin
    output sda_pad_o,    // 'data' output to tri-state driver
    output sda_padoen_o  // 'data' enable signal for tri-state driver
);

// -----------------
// wire declarations
// -----------------

wire wr_exp_sm_running;
wire rd_exp_sm_running;

wire [7:0] i2c_dev_adr;
wire [7:0] i2c_reg_dat;

wire [7:0] i2c_dev_adr_wr_exp;
wire [7:0] i2c_dev_adr_rd_exp;
wire [7:0] i2c_dev_adr_rd_sfp;

wire [7:0] i2c_reg_dat_wr_exp;
wire [7:0] i2c_reg_dat_rd_exp;
wire [7:0] i2c_reg_dat_rd_sfp;

wire i2c_start_write_exp;
wire i2c_start_read_exp;
wire i2c_start_read_sfp;

wire i2c_start_write_from_wr_exp;
wire i2c_start_write_from_rd_exp;
wire i2c_start_write_from_rd_sfp;

wire i2c_rd_byte_ctrl_exp;
wire i2c_rd_byte_ctrl_sfp;

wire exp_i2c_byte_rdy;
wire sfp_i2c_byte_rdy;
wire [7:0] exp_i2c_rd_dat;
wire [7:0] sfp_i2c_rd_dat;

wire i2c_wr_error;
wire i2c_rd_error;
wire i2c_rd_transceiver_error;
wire i2c_rd_exp_error;
wire i2c_rd_sfp_error;
wire write_exp_error;
wire read_exp_error;
wire read_sfp_error;
wire i2c_fs_error;
wire i2c_st_error;

wire rd_scl_pad_o,    wr_scl_pad_o,    rd_sfp_scl_pad_o;
wire rd_scl_padoen_o, wr_scl_padoen_o, rd_sfp_scl_padoen_o;
wire rd_sda_pad_o,    wr_sda_pad_o,    rd_sfp_sda_pad_o;
wire rd_sda_padoen_o, wr_sda_padoen_o, rd_sfp_sda_padoen_o;

wire fs_sm_running;
wire st_sm_running, st_sm_running_n;
wire ssc_sm_running;
wire sgr_sm_running;

wire [  7:0] reg_from_rd_exp;
wire [127:0] reg_from_rd_sfp;
wire reg_valid_from_rd_exp;
wire reg_valid_from_rd_sfp;

wire eeprom_map_sel;
wire eeprom_map_sel_from_st;
wire [7:0] eeprom_start_adr;
wire [7:0] eeprom_start_adr_from_st;
wire [5:0] eeprom_num_regs;
wire [5:0] eeprom_num_regs_from_st;

wire i2c_wr_done;
wire i2c_en_start_pulse;
wire i2c_rd_start_pulse;
wire write_done;
wire startup_done;
wire i2c_int_n;
wire sfp_enabled_ports_changed;
wire [7:0] sfp_requested_ports;
wire reset_by_mod_type;

wire [7:0] channel_sel;
wire [7:0] channel_sel_fs;
wire [7:0] channel_sel_st;
wire [7:0] channel_sel_ssc;

wire start_write_exp;
wire start_write_exp_from_fs;
wire start_write_exp_from_st;

wire start_read_exp;
wire start_read_exp_from_fs;
wire start_read_exp_from_st;
wire start_read_exp_from_ssc;

wire start_read_sfp;
wire start_read_sfp_from_st;
wire start_read_sfp_from_sgr;

wire [7:0] wr_ctrl_reg;
wire [7:0] wr_ctrl_reg_from_fs;
wire [7:0] wr_ctrl_reg_from_st;

wire i2c_lines_busy_st;
wire i2c_lines_busy_ssc;
wire i2c_lines_busy_sgr;


// ----------------
// wire assignments
// ----------------

// static assignments
assign startup_done      = ~fs_sm_running;
assign st_sm_running_n   = ~st_sm_running;
assign reset_by_mod_type = reset | (fmc_mod_type[7:0] == 8'b00000001) | (fmc_mod_type[7:0] == 8'b00000010);

assign i2c_lines_busy_st  = ssc_sm_running | sgr_sm_running;
assign i2c_lines_busy_ssc = st_sm_running  | sgr_sm_running;
assign i2c_lines_busy_sgr = st_sm_running  | ssc_sm_running;

assign i2c_rd_exp_error = i2c_wr_error | i2c_rd_error;
assign i2c_rd_sfp_error = i2c_wr_error | i2c_rd_transceiver_error;

assign i2c_fs_error = write_exp_error | read_exp_error;
assign i2c_st_error = write_exp_error | read_exp_error | read_sfp_error;

// convert TX-enable trigger into a pulse
level_to_pulse i2c_en_start_conv (
    .clk(clk),
    .sig_i(i2c_en_start),
    .sig_o(i2c_en_start_pulse)
);

// convert TX-enable trigger into a pulse
level_to_pulse i2c_rd_start_conv (
    .clk(clk),
    .sig_i(i2c_rd_start),
    .sig_o(i2c_rd_start_pulse)
);

// convert SFP-enable trigger into a pulse
level_to_pulse st_sm_running_n_conv (
    .clk(clk),
    .sig_i(st_sm_running_n),
    .sig_o(sfp_enabled_ports_changed)
);

// synchronize \INT
sync_2stage i2c_int_n_sync (
    .clk(clk),
    .sig_i(i2c_int_n_i),
    .sig_o(i2c_int_n)
);

// synchronize requested ports
sync_2stage #(
    .nbr_bits(8)
) seq_count_ext_sync (
    .clk(clk),
    .sig_i(sfp_requested_ports_i[7:0]),
    .sig_o(sfp_requested_ports[7:0])
);


// ---------------------
// MUX interface signals
// ---------------------

// route outputs to read or write byte controller
assign i2c_dev_adr         = (wr_exp_sm_running) ? i2c_dev_adr_wr_exp : (rd_exp_sm_running) ? i2c_dev_adr_rd_exp : i2c_dev_adr_rd_sfp;
assign i2c_reg_dat         = (wr_exp_sm_running) ? i2c_reg_dat_wr_exp : (rd_exp_sm_running) ? i2c_reg_dat_rd_exp : i2c_reg_dat_rd_sfp;
assign i2c_start_write_exp = i2c_start_write_from_wr_exp | i2c_start_write_from_rd_exp | i2c_start_write_from_rd_sfp;

// route outputs from read or write byte controller
assign scl_pad_o    = (i2c_rd_byte_ctrl_exp) ? rd_scl_pad_o    : (i2c_rd_byte_ctrl_sfp) ? rd_sfp_scl_pad_o    : wr_scl_pad_o;
assign scl_padoen_o = (i2c_rd_byte_ctrl_exp) ? rd_scl_padoen_o : (i2c_rd_byte_ctrl_sfp) ? rd_sfp_scl_padoen_o : wr_scl_padoen_o;
assign sda_pad_o    = (i2c_rd_byte_ctrl_exp) ? rd_sda_pad_o    : (i2c_rd_byte_ctrl_sfp) ? rd_sfp_sda_pad_o    : wr_sda_pad_o;
assign sda_padoen_o = (i2c_rd_byte_ctrl_exp) ? rd_sda_padoen_o : (i2c_rd_byte_ctrl_sfp) ? rd_sfp_sda_padoen_o : wr_sda_padoen_o;

// route outputs to device interfaces
assign channel_sel      = (fs_sm_running) ? channel_sel_fs[7:0] : (ssc_sm_running) ? channel_sel_ssc[7:0] : (st_sm_running) ? channel_sel_st[7:0] : channel_sel_in[7:0];
assign wr_ctrl_reg      = (fs_sm_running) ? wr_ctrl_reg_from_fs[7:0] : wr_ctrl_reg_from_st[7:0];
assign eeprom_map_sel   = (st_sm_running) ? eeprom_map_sel_from_st : eeprom_map_sel_in;
assign eeprom_start_adr = (st_sm_running) ? eeprom_start_adr_from_st[7:0] : eeprom_start_adr_in[7:0];
assign eeprom_num_regs  = (st_sm_running) ? eeprom_num_regs_from_st[5:0] : eeprom_num_regs_in[5:0];
assign start_write_exp  = start_write_exp_from_fs | start_write_exp_from_st;
assign start_read_exp   = start_read_exp_from_fs  | start_read_exp_from_st  | start_read_exp_from_ssc;
assign start_read_sfp   = start_read_sfp_from_st  | start_read_sfp_from_sgr;


// -----------------------
// I2C interface instances
// -----------------------

// Connect the controller that writes one byte to the I2C chip
i2c_write_byte i2c_write_byte (
    // inputs
    .clk(clk),
    .reset(reset),
    .i2c_dev_adr(i2c_dev_adr[7:0]),        // address of the device on the I2C bus
    .i2c_reg_dat(i2c_reg_dat[7:0]),        // chip register value to write
    .i2c_start_write(i2c_start_write_exp), // initiate a byte write
    // outputs
    .i2c_wr_done(i2c_wr_done),             // the byte has been written
    .error(i2c_wr_error),
    // I2C signals
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(wr_scl_pad_o),
    .scl_padoen_o(wr_scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(wr_sda_pad_o),
    .sda_padoen_o(wr_sda_padoen_o)
);

// Connect the controller that reads one byte from the I2C chip
i2c_read_byte i2c_read_byte (
    // inputs
    .clk(clk),
    .reset(reset),
    .i2c_dev_adr(i2c_dev_adr[7:0]),      // address of the device on the I2C bus
    .i2c_start_read(i2c_start_read_exp), // initiate a byte read
    // outputs
    .i2c_byte_rdy(exp_i2c_byte_rdy),     // the byte is ready
    .i2c_rd_dat(exp_i2c_rd_dat[7:0]),    // byte read from I2C device
    .error(i2c_rd_error),
    // I2C signals
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(rd_scl_pad_o),
    .scl_padoen_o(rd_scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(rd_sda_pad_o),
    .sda_padoen_o(rd_sda_padoen_o)
);

// Connect the controller that reads one byte from the SFP transceiver
i2c_read_byte_eeprom i2c_read_byte_eeprom (
    // inputs
    .clk(clk),
    .reset(reset),
    .i2c_dev_ext(1'b0),                  // EEPROM has extended address width
    .i2c_dev_adr(i2c_dev_adr[7:1]),      // address of the device on the I2C bus
    .i2c_reg_adr(i2c_reg_dat[7:0]),      // EEPROM register address to read
    .i2c_start_read(i2c_start_read_sfp), // initiate a byte read
    // outputs
    .i2c_byte_rdy(sfp_i2c_byte_rdy),     // the byte is ready
    .i2c_rd_dat(sfp_i2c_rd_dat[7:0]),    // byte read from I2C device
    .error(i2c_rd_transceiver_error),
    // I2C signals
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(rd_sfp_scl_pad_o),
    .scl_padoen_o(rd_sfp_scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(rd_sfp_sda_pad_o),
    .sda_padoen_o(rd_sfp_sda_padoen_o)
);


// --------------------------
// device interface instances
// --------------------------

// Connect the controller that interfaces writes to the PCA8574APW
i2c_write_expander i2c_write_expander (
    // clock and reset
    .clk(clk),
    .reset(reset),
    // controls
    .sm_start(start_write_exp),
    .sm_running(wr_exp_sm_running),
    // write information
    .fmc_loc(fmc_loc[1:0]),
    .channel_sel(channel_sel[7:0]),
    .ctrl_reg(wr_ctrl_reg[7:0]),
    .write_done(write_done),
    .write_error(write_exp_error),
    // I2C interface
    .i2c_wr_byte_done(i2c_wr_done),
    .i2c_wr_byte_error(i2c_wr_error),
    .i2c_dev_adr(i2c_dev_adr_wr_exp[7:0]),
    .i2c_reg_dat(i2c_reg_dat_wr_exp[7:0]),
    .i2c_start_write(i2c_start_write_from_wr_exp)
);

// Connect the controller that interfaces reads from the PCA8574APW
i2c_read_expander i2c_read_expander (
    // clock and reset
    .clk(clk),
    .reset(reset),
    // controls
    .sm_start(start_read_exp),
    .sm_running(rd_exp_sm_running),
    // write information
    .fmc_loc(fmc_loc[1:0]),
    .channel_sel(channel_sel[7:0]),
    .reg_out(reg_from_rd_exp[7:0]),
    .reg_out_valid(reg_valid_from_rd_exp),
    .read_error(read_exp_error),
    // I2C interface
    .i2c_wr_byte_done(i2c_wr_done),
    .i2c_byte_error(i2c_rd_exp_error),
    .i2c_byte_rdy(exp_i2c_byte_rdy),
    .i2c_rd_dat(exp_i2c_rd_dat[7:0]),
    .i2c_rd_byte_ctrl(i2c_rd_byte_ctrl_exp),
    .i2c_dev_adr(i2c_dev_adr_rd_exp[7:0]),
    .i2c_reg_dat(i2c_reg_dat_rd_exp[7:0]),
    .i2c_start_write(i2c_start_write_from_rd_exp),
    .i2c_start_read(i2c_start_read_exp)
);

// Connect the controller that interfaces reads from the SFP transceiver
i2c_read_transceiver i2c_read_transceiver (
    // clock and reset
    .clk(clk),
    .reset(reset),
    // controls
    .sm_start(start_read_sfp),
    // write information
    .fmc_loc(fmc_loc[1:0]),
    .channel_sel(channel_sel[7:0]),
    .eeprom_map_sel(eeprom_map_sel),
    .eeprom_start_adr(eeprom_start_adr[7:0]),
    .eeprom_num_regs(eeprom_num_regs[5:0]),
    .reg_out(reg_from_rd_sfp[127:0]),
    .reg_out_valid(reg_valid_from_rd_sfp),
    .read_error(read_sfp_error),
    // I2C interface
    .i2c_wr_byte_done(i2c_wr_done),
    .i2c_byte_error(i2c_rd_sfp_error),
    .i2c_byte_rdy(sfp_i2c_byte_rdy),
    .i2c_rd_dat(sfp_i2c_rd_dat[7:0]),
    .i2c_rd_byte_ctrl(i2c_rd_byte_ctrl_sfp),
    .i2c_dev_adr(i2c_dev_adr_rd_sfp[7:0]),
    .i2c_reg_dat(i2c_reg_dat_rd_sfp[7:0]),
    .i2c_start_write(i2c_start_write_from_rd_sfp),
    .i2c_start_read(i2c_start_read_sfp)
);


// -----------------------
// state machine instances
// -----------------------

// Connect a state machine that will perform the startup procedure
fpga_startup_sm fpga_startup_sm (
    // clock and reset
    .clk(clk),
    .reset(reset),
    // controls
    .fmc_mod_type(fmc_mod_type[7:0]),
    .fmc_absent(fmc_absent),
    .i2c_int_n(i2c_int_n),
    .i2c_error(i2c_fs_error),
    // expander, read
    .i2c_reg_dat(reg_from_rd_exp[7:0]),
    .i2c_reg_valid(reg_valid_from_rd_exp),
    .start_read(start_read_exp_from_fs),
    // expander, write
    .i2c_wr_rdy(write_done),
    .start_write(start_write_exp_from_fs),
    .wr_ctrl_reg(wr_ctrl_reg_from_fs[7:0]),
    // configuration
    .channel_sel(channel_sel_fs[7:0]),
    // status connections
    .error_i2c_chip(error_startup_i2c),
    .error_fmc_absent(error_fmc_absent),
    .error_fmc_mod_type(error_fmc_mod_type),
    .error_fmc_int_n(error_fmc_int_n),
    .sm_running(fs_sm_running),
    .CS(fs_state[27:0])
);

// Connect a state machine that will enable data transmission of SFP ports
sfp_transmission_sm sfp_transmission_sm (
    // inputs
    .clk(clk),
    .reset(reset_by_mod_type),
    // controls
    .start_sm(i2c_en_start_pulse),
    .sfp_requested_ports(sfp_requested_ports[7:0]),
    .i2c_lines_busy(i2c_lines_busy_st),
    .i2c_error(i2c_st_error),
    // expander, read
    .i2c_reg_exp_dat(reg_from_rd_exp[7:0]),
    .i2c_reg_exp_valid(reg_valid_from_rd_exp),
    .start_read_exp(start_read_exp_from_st),
    // expander, write
    .i2c_wr_exp_rdy(write_done),
    .start_write_exp(start_write_exp_from_st),
    .wr_ctrl_reg(wr_ctrl_reg_from_st[7:0]),
    // transceiver, read
    .i2c_reg_sfp_dat(reg_from_rd_sfp[127:0]),
    .i2c_reg_sfp_valid(reg_valid_from_rd_sfp),
    .start_read_sfp(start_read_sfp_from_st),
    // configuration
    .channel_sel(channel_sel_st[7:0]),
    .eeprom_map_sel(eeprom_map_sel_from_st),
    .eeprom_start_adr(eeprom_start_adr_from_st[7:0]),
    .eeprom_num_regs(eeprom_num_regs_from_st[5:0]),
    // error status
    .error_mod_abs(sfp_en_error_mod_abs[7:0]),
    .error_sfp_type(sfp_en_error_sfp_type[1:0]),
    .error_tx_fault(sfp_en_error_tx_fault[7:0]),
    .error_sfp_alarms(sfp_en_error_sfp_alarms),
    .error_i2c_chip(sfp_en_error_i2c_chip),
    // SFP alarm flags
    .sfp_alarm_temp_high(sfp_alarm_temp_high[7:0]),
    .sfp_alarm_temp_low(sfp_alarm_temp_low[7:0]),
    .sfp_alarm_vcc_high(sfp_alarm_vcc_high[7:0]),
    .sfp_alarm_vcc_low(sfp_alarm_vcc_low[7:0]),
    .sfp_alarm_tx_bias_high(sfp_alarm_tx_bias_high[7:0]),
    .sfp_alarm_tx_bias_low(sfp_alarm_tx_bias_low[7:0]),
    .sfp_alarm_tx_power_high(sfp_alarm_tx_power_high[7:0]),
    .sfp_alarm_tx_power_low(sfp_alarm_tx_power_low[7:0]),
    .sfp_alarm_rx_power_high(sfp_alarm_rx_power_high[7:0]),
    .sfp_alarm_rx_power_low(sfp_alarm_rx_power_low[7:0]),
    // SFP warning flags
    .sfp_warning_temp_high(sfp_warning_temp_high[7:0]),
    .sfp_warning_temp_low(sfp_warning_temp_low[7:0]),
    .sfp_warning_vcc_high(sfp_warning_vcc_high[7:0]),
    .sfp_warning_vcc_low(sfp_warning_vcc_low[7:0]),
    .sfp_warning_tx_bias_high(sfp_warning_tx_bias_high[7:0]),
    .sfp_warning_tx_bias_low(sfp_warning_tx_bias_low[7:0]),
    .sfp_warning_tx_power_high(sfp_warning_tx_power_high[7:0]),
    .sfp_warning_tx_power_low(sfp_warning_tx_power_low[7:0]),
    .sfp_warning_rx_power_high(sfp_warning_rx_power_high[7:0]),
    .sfp_warning_rx_power_low(sfp_warning_rx_power_low[7:0]),
    // status connections
    .sfp_enabled_ports(sfp_enabled_ports[7:0]),
    .sfp_sn_vec(sfp_sn_vec[1023:0]),
    .sm_running(st_sm_running),
    .CS(st_state[32:0])
);

// Connect a state machine that will monitor any SFP changes
sfp_setting_change_sm sfp_setting_change_sm (
    // clock and reset
    .clk(clk),
    .reset(reset_by_mod_type),
    // controls
    .start_sm(startup_done),
    .i2c_lines_busy(i2c_lines_busy_ssc),
    .i2c_error(read_exp_error),
    // current states
    .i2c_int_n(i2c_int_n),
    .sfp_enabled_ports_changed(sfp_enabled_ports_changed),
    .sfp_enabled_ports(sfp_enabled_ports[7:0]),
    // expander, read
    .i2c_reg_dat(reg_from_rd_exp[7:0]),
    .i2c_reg_valid(reg_valid_from_rd_exp),
    .start_read(start_read_exp_from_ssc),
    .channel_sel(channel_sel_ssc[7:0]),
    // status connections
    .error_mod_abs(change_error_mod_abs[7:0]),
    .error_tx_fault(change_error_tx_fault[7:0]),
    .error_rx_los(change_error_rx_los[7:0]),
    .sfp_change_mod_abs(change_mod_abs[7:0]),
    .sfp_change_tx_fault(change_tx_fault[7:0]),
    .sfp_change_rx_los(change_rx_los[7:0]),
    .sfp_mod_abs(sfp_mod_abs[7:0]),
    .sfp_tx_fault(sfp_tx_fault[7:0]),
    .sfp_rx_los(sfp_rx_los[7:0]),
    .sm_running(ssc_sm_running),
    .CS(ssc_state[10:0])
);

// Connect a state machine that will generically read information registers
sfp_generic_read_sm sfp_generic_read_sm (
    // inputs
    .clk(clk),
    .reset(reset_by_mod_type),
    // controls
    .start_sm(i2c_rd_start_pulse),
    .i2c_lines_busy(i2c_lines_busy_sgr),
    .i2c_error(read_sfp_error),
    // transceiver, read
    .i2c_reg_sfp_dat(reg_from_rd_sfp[127:0]),
    .i2c_reg_sfp_valid(reg_valid_from_rd_sfp),
    .start_read_sfp(start_read_sfp_from_sgr),
    // status connections
    .sfp_reg_out(eeprom_reg_out[127:0]),
    .sfp_reg_out_valid(eeprom_reg_out_valid),
    .error_i2c_chip(),
    .sm_running(sgr_sm_running),
    .CS(sgr_state[6:0])
);

endmodule
