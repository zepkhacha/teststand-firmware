// Finite state machine for sending data to AMC13

module event_builder (
  // user interface clock and reset
  input wire clk,
  input wire rst,
  
  // FIFO connections
  input  wire m_trig_info_fifo_tvalid,
  output reg  m_trig_info_fifo_tready,
  input  wire [127:0] m_trig_info_fifo_tdata,

  input  wire m_pulse_info_fifo_tvalid,
  output reg  m_pulse_info_fifo_tready,
  input  wire [2047:0] m_pulse_info_fifo_tdata,

  // controls
  input wire ttc_trigger,
  
  // static event information
  input wire [   1:0] fc7_type,
  input wire [   7:0] major_rev,
  input wire [   7:0] minor_rev,
  input wire [   7:0] patch_rev,
  input wire [  10:0] board_id,
  input wire [   7:0] l12_fmc_id,
  input wire [   7:0] l8_fmc_id,
  input wire otrig_disable_a,
  input wire otrig_disable_b,
  input wire [  31:0] otrig_delay_a,
  input wire [  31:0] otrig_delay_b,
  input wire [   7:0] otrig_width_a,
  input wire [   7:0] otrig_width_b,
  input wire [  31:0] tts_lock_thres,
  input wire [  23:0] ofw_watchdog_thres,
  input wire [   7:0] l12_enabled_ports,
  input wire [   7:0] l8_enabled_ports,
  input wire [   7:0] l12_tts_mask,
  input wire [   7:0] l8_tts_mask,
  input wire [  63:0] l12_ttc_delays,
  input wire [  63:0] l8_ttc_delays,
  input wire [1023:0] l12_sfp_sn_vec,
  input wire [1023:0] l8_sfp_sn_vec,

  // variable event information
  input wire [31:0] l12_tts_state,
  input wire [31:0] l8_tts_state,
  input wire [ 7:0] l12_tts_lock,
  input wire [ 7:0] l8_tts_lock,
  input wire l12_tts_lock_mux,
  input wire l8_tts_lock_mux,
  input wire ext_clk_lock,
  input wire ttc_clk_lock,
  input wire ttc_ready,
  input wire [ 3:0] xadc_alarms,
  input wire error_flag,
  input wire error_l12_fmc_absent,
  input wire error_l8_fmc_absent,
  input wire [ 7:0] change_error_l12_mod_abs,
  input wire [ 7:0] change_error_l8_mod_abs,
  input wire [ 7:0] change_error_l12_tx_fault,
  input wire [ 7:0] change_error_l8_tx_fault,
  input wire [ 7:0] change_error_l12_rx_los,
  input wire [ 7:0] change_error_l8_rx_los,

  // interface to AMC13 DAQ Link
  input  wire daq_ready,
  input  wire daq_almost_full,
  output reg  daq_valid,
  output reg  daq_header,
  output reg  daq_trailer,
  output reg  [63:0] daq_data,

  // status
  output reg [18:0] state // state of finite state machine
);

  // idle state bit
  parameter IDLE                  =  0;
  // event builder state bits
  parameter READ_TRIG_FIFO        =  1;
  parameter READ_PULSE_FIFO       =  2;
  parameter READY_AMC13_HEADER1   =  3;
  parameter SEND_AMC13_HEADER1    =  4;
  parameter SEND_AMC13_HEADER2    =  5;
  parameter SEND_FC7_HEADER1      =  6;
  parameter SEND_DATA01           =  7; // encoder, fanout
  parameter SEND_DATA02           =  8; // encoder, fanout
  parameter SEND_DATA03           =  9; // encoder, fanout
  parameter SEND_DATA04           = 10; // encoder, fanout
  parameter SEND_DATA05           = 11; // encoder, fanout
  parameter SEND_DATA06           = 12; // encoder, fanout
  parameter SEND_DATA07           = 13; // encoder, fanout
  parameter SEND_DATA08           = 14; // encoder, fanout
  parameter SEND_DATA09_TO_DATA24 = 15; // encoder, fanout
  parameter SEND_DATA25_TO_DATA40 = 16; // fanout
  parameter SEND_PULSE_INFO       = 17; // trigger
  parameter SEND_AMC13_TRAILER    = 18;

  // internal registers
  reg [43:0] trig_timestamp;
  reg [23:0] trig_num;
  reg [ 4:0] trig_type;
  reg [31:0] trig_delay;
  reg [ 3:0] trig_index;
  reg [ 3:0] trig_sub_index;
  reg [ 4:0] sfp_cntr;
  reg [ 6:0] pulse_info_cntr;

  wire [63:0] l12_sfp_sn [15:0];
  wire [63:0] l8_sfp_sn  [15:0];
  // reg  [63:0] pulse_info [63:0];
  reg  [63:0] pulse_info [31:0];

  wire [10:0] board_sn;
  assign board_sn = board_id[10:0] - 90;

  genvar i;
  for (i = 0; i < 16; i = i + 1)
  begin
    assign l12_sfp_sn[i] = l12_sfp_sn_vec[(64*i + 63):(64*i)];
    assign l8_sfp_sn[i]  = l8_sfp_sn_vec[(64*i + 63):(64*i)];
  end

  // latched variables
  reg [7:0] latch_l8_tts_state,             latch_l12_tts_state;
  reg [7:0] latch_l8_tts_lock,              latch_l12_tts_lock;
  reg [7:0] latch_change_error_l8_mod_abs,  latch_change_error_l12_mod_abs;
  reg [7:0] latch_change_error_l8_tx_fault, latch_change_error_l12_tx_fault;
  reg [7:0] latch_change_error_l8_rx_los,   latch_change_error_l12_rx_los;
  reg       latch_l8_tts_lock_mux,          latch_l12_tts_lock_mux;
  reg       latch_error_l8_fmc_absent,      latch_error_l12_fmc_absent;
  reg [3:0] latch_xadc_alarms;
  reg       latch_ttc_clk_lock;
  reg       latch_ext_clk_lock;
  reg       latch_ttc_ready;
  reg       latch_error_flag;

  // for internal regs
  reg [18:0] nextstate;
  reg [43:0] next_trig_timestamp;
  reg [23:0] next_trig_num;
  reg [ 4:0] next_trig_type;
  reg [31:0] next_trig_delay;
  reg [ 3:0] next_trig_index;
  reg [ 3:0] next_trig_sub_index;
  reg [ 4:0] next_sfp_cntr;
  reg [ 6:0] next_pulse_info_cntr;

  reg [7:0] next_latch_l8_tts_state,             next_latch_l12_tts_state;
  reg [7:0] next_latch_l8_tts_lock,              next_latch_l12_tts_lock;
  reg [7:0] next_latch_change_error_l8_mod_abs,  next_latch_change_error_l12_mod_abs;
  reg [7:0] next_latch_change_error_l8_tx_fault, next_latch_change_error_l12_tx_fault;
  reg [7:0] next_latch_change_error_l8_rx_los,   next_latch_change_error_l12_rx_los;
  reg       next_latch_l8_tts_lock_mux,          next_latch_l12_tts_lock_mux;
  reg       next_latch_error_l8_fmc_absent,      next_latch_error_l12_fmc_absent;
  reg [3:0] next_latch_xadc_alarms;
  reg       next_latch_ext_clk_lock;
  reg       next_latch_ttc_clk_lock;
  reg       next_latch_ttc_ready;
  reg       next_latch_error_flag;

  // reg [63:0] next_pulse_info [63:0];
  reg [63:0] next_pulse_info [31:0];

  // for external regs
  reg [63:0] next_daq_data;
  reg next_daq_valid;


  // comb always block
  integer j, k;
  always @* begin
    nextstate                 = 19'd0;
    next_trig_timestamp[43:0] = trig_timestamp[43:0];
    next_trig_num[23:0]       = trig_num[23:0];
    next_trig_type[4:0]       = trig_type[4:0];
    next_trig_delay[31:0]     = trig_delay[31:0];
    next_trig_index[3:0]      = trig_index[3:0];
    next_trig_sub_index[3:0]  = trig_sub_index[3:0];
    next_sfp_cntr[4:0]        = sfp_cntr[4:0];
    next_pulse_info_cntr[6:0] = pulse_info_cntr[6:0];
    next_daq_data[63:0]       = daq_data[63:0];
    next_daq_valid            = 0; // default

    next_latch_l12_tts_state[7:0]             = latch_l12_tts_state[7:0];
    next_latch_l8_tts_state[7:0]              = latch_l8_tts_state[7:0];
    next_latch_l12_tts_lock[7:0]              = latch_l12_tts_lock[7:0];
    next_latch_l8_tts_lock[7:0]               = latch_l8_tts_lock[7:0];
    next_latch_l12_tts_lock_mux               = latch_l12_tts_lock_mux;
    next_latch_l8_tts_lock_mux                = latch_l8_tts_lock_mux;
    next_latch_ext_clk_lock                   = latch_ext_clk_lock;
    next_latch_ttc_clk_lock                   = latch_ttc_clk_lock;
    next_latch_ttc_ready                      = latch_ttc_ready;
    next_latch_xadc_alarms[3:0]               = latch_xadc_alarms[3:0];
    next_latch_error_flag                     = latch_error_flag;
    next_latch_error_l12_fmc_absent           = latch_error_l12_fmc_absent;
    next_latch_error_l8_fmc_absent            = latch_error_l8_fmc_absent;
    next_latch_change_error_l12_mod_abs[7:0]  = latch_change_error_l12_mod_abs[7:0];
    next_latch_change_error_l8_mod_abs[7:0]   = latch_change_error_l8_mod_abs[7:0];
    next_latch_change_error_l12_tx_fault[7:0] = latch_change_error_l12_tx_fault[7:0];
    next_latch_change_error_l8_tx_fault[7:0]  = latch_change_error_l8_tx_fault[7:0];
    next_latch_change_error_l12_rx_los[7:0]   = latch_change_error_l12_rx_los[7:0];
    next_latch_change_error_l8_rx_los[7:0]    = latch_change_error_l8_rx_los[7:0];

    // for (j = 0; j < 64; j = j + 1)
    for (j = 0; j < 32; j = j + 1)
    begin
      next_pulse_info[j][63:0] = pulse_info[j][63:0];
    end
    
    m_trig_info_fifo_tready  = 0; // default
    m_pulse_info_fifo_tready = 0; // default
    
    case (1'b1) // synopsys parallel_case full_case
      // idle state
      state[IDLE] : begin
        // watch for backplane triggers
        if (ttc_trigger) begin
          // latch variable event information
          next_latch_l12_tts_state[7:0]             = l12_tts_state[7:0];
          next_latch_l8_tts_state[7:0]              = l8_tts_state[7:0];
          next_latch_l12_tts_lock[7:0]              = l12_tts_lock[7:0];
          next_latch_l8_tts_lock[7:0]               = l8_tts_lock[7:0];
          next_latch_l12_tts_lock_mux               = l12_tts_lock_mux;
          next_latch_l8_tts_lock_mux                = l8_tts_lock_mux;
          next_latch_ext_clk_lock                   = ext_clk_lock;
          next_latch_ttc_clk_lock                   = ttc_clk_lock;
          next_latch_ttc_ready                      = ttc_ready;
          next_latch_xadc_alarms[3:0]               = xadc_alarms[3:0];
          next_latch_error_flag                     = error_flag;
          next_latch_error_l12_fmc_absent           = error_l12_fmc_absent;
          next_latch_error_l8_fmc_absent            = error_l8_fmc_absent;
          next_latch_change_error_l12_mod_abs[7:0]  = change_error_l12_mod_abs[7:0];
          next_latch_change_error_l8_mod_abs[7:0]   = change_error_l8_mod_abs[7:0];
          next_latch_change_error_l12_tx_fault[7:0] = change_error_l12_tx_fault[7:0];
          next_latch_change_error_l8_tx_fault[7:0]  = change_error_l8_tx_fault[7:0];
          next_latch_change_error_l12_rx_los[7:0]   = change_error_l12_rx_los[7:0];
          next_latch_change_error_l8_rx_los[7:0]    = change_error_l8_rx_los[7:0];

          nextstate[READ_TRIG_FIFO] = 1'b1;
        end
        else begin
          nextstate[IDLE] = 1'b1;
        end
      end
      // read trigger information from FIFO
      state[READ_TRIG_FIFO] : begin
        // watch for unread trigger information
        if (m_trig_info_fifo_tvalid) begin
          // extract the FIFO's data
          next_trig_timestamp[43:0] = m_trig_info_fifo_tdata[ 43:  0];
          next_trig_num[23:0]       = m_trig_info_fifo_tdata[ 67: 44];
          next_trig_type[4:0]       = m_trig_info_fifo_tdata[ 72: 68];
          next_trig_delay[31:0]     = m_trig_info_fifo_tdata[104: 73];
          next_trig_index[3:0]      = m_trig_info_fifo_tdata[108:105];
          next_trig_sub_index[3:0]  = m_trig_info_fifo_tdata[112:109];
          
          m_trig_info_fifo_tready = 1'b1; // acknowledge the data word

          if (fc7_type[1:0] == 2'b11) begin
            nextstate[READ_PULSE_FIFO] = 1'b1;
          end
          else begin
            nextstate[READY_AMC13_HEADER1] = 1'b1;
          end
        end
        else begin
          nextstate[READ_TRIG_FIFO] = 1'b1;
        end
      end
      // read pulse information from FIFO
      state[READ_PULSE_FIFO] : begin
        // watch for unread pulse information
        if (m_pulse_info_fifo_tvalid) begin
          // extract the FIFO's data
//          for (k = 0; k < 64; k = k + 1)
          for (k = 0; k < 32; k = k + 1)
          begin
            next_pulse_info[k][63:0] = m_pulse_info_fifo_tdata[(64*k + 63)-:64];
          end

          m_pulse_info_fifo_tready = 1'b1; // acknowledge the data word
          nextstate[READY_AMC13_HEADER1] = 1'b1;
        end
        else begin
          nextstate[READ_PULSE_FIFO] = 1'b1;
        end
      end
      // prepare first AMC13 header word
      state[READY_AMC13_HEADER1] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          if (fc7_type[1:0] == 2'b01) begin
            next_daq_data[19:0] = 20'd28;                                        // 1st AMC13 header
          end
          else if (fc7_type[1:0] == 2'b10) begin
            next_daq_data[19:0] = 20'd44;                                        // 1st AMC13 header
          end
          else begin
            next_daq_data[19:0] = 20'd37;                                        // 1st AMC13 header
          end

          next_daq_data[63:20] = {8'h00, trig_num[23:0], trig_timestamp[43:32]}; // 1st AMC13 header
          nextstate[SEND_AMC13_HEADER1] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[READY_AMC13_HEADER1] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[READY_AMC13_HEADER1] = 1'b1;
        end
      end
      // send first AMC13 header word
      state[SEND_AMC13_HEADER1] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = {6'd0, xadc_alarms[3:0], error_flag, trig_type[4:0], trig_timestamp[31:0], 3'd2, fc7_type[1:0], board_sn[10:0]}; // 2nd AMC13 header
          nextstate[SEND_AMC13_HEADER2] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_AMC13_HEADER1] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_AMC13_HEADER1] = 1'b1;
        end
      end
      // send second AMC13 header word
      state[SEND_AMC13_HEADER2] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = {40'd0, major_rev[7:0], minor_rev[7:0], patch_rev[7:0]}; // 1st FC7 header
          nextstate[SEND_FC7_HEADER1] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_AMC13_HEADER2] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_AMC13_HEADER2] = 1'b1;
        end
      end
      // send first FC7 header word
      state[SEND_FC7_HEADER1] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = {trig_delay[31:0], 1'b0,
                                 latch_l8_tts_lock_mux, latch_l12_tts_lock_mux,
                                 latch_ext_clk_lock, latch_ttc_clk_lock, latch_ttc_ready,
                                 latch_error_l8_fmc_absent, latch_error_l12_fmc_absent,
                                 trig_sub_index[3:0], trig_index[3:0], l8_fmc_id[7:0], l12_fmc_id[7:0]}; // 1st data word
          
          if (fc7_type[1:0] == 2'b11) begin
            next_pulse_info_cntr[6:0] = 7'd0;
            nextstate[SEND_PULSE_INFO] = 1'b1;
          end
          else begin
            nextstate[SEND_DATA01] = 1'b1;
          end
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_FC7_HEADER1] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_FC7_HEADER1] = 1'b1;
        end
      end
      // send first data word
      state[SEND_DATA01] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[23:0] = ofw_watchdog_thres[23:0]; // 2nd data word

          if (otrig_disable_a) begin
            next_daq_data[31:24] = 8'd0;                  // 2nd data word
          end
          else begin
            next_daq_data[31:24] = otrig_width_a[7:0];    // 2nd data word
          end

          if (otrig_disable_b) begin
            next_daq_data[39:32] = 8'd0;                  // 2nd data word
          end
          else begin
            next_daq_data[39:32] = otrig_width_b[7:0];    // 2nd data word
          end

          next_daq_data[40] = otrig_disable_a;            // 2nd data word
          next_daq_data[41] = otrig_disable_b;            // 2nd data word
          next_daq_data[55:48] = l12_tts_mask[7:0];       // 2nd data word
          next_daq_data[63:56] = l8_tts_mask[7:0];        // 2nd data word
          nextstate[SEND_DATA02] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA01] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA01] = 1'b1;
        end
      end
      // send second data word
      state[SEND_DATA02] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;

          if (otrig_disable_a) begin
            next_daq_data[31:0] = 32'd0;                // 3rd data word
          end
          else begin
            next_daq_data[31:0] = otrig_delay_a[31:0];  // 3rd data word
          end

          if (otrig_disable_b) begin
            next_daq_data[63:32] = 32'd0;               // 3rd data word
          end
          else begin
            next_daq_data[63:32] = otrig_delay_b[31:0]; // 3rd data word
          end

          nextstate[SEND_DATA03] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA02] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA02] = 1'b1;
        end
      end
      // send third data word
      state[SEND_DATA03] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = {16'd0,
                                 latch_change_error_l8_rx_los[7:0],   latch_change_error_l12_rx_los[7:0], 
                                 latch_change_error_l8_tx_fault[7:0], latch_change_error_l12_tx_fault[7:0], 
                                 latch_change_error_l8_mod_abs[7:0],  latch_change_error_l12_mod_abs[7:0]}; // 4th data word
          nextstate[SEND_DATA04] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA03] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA03] = 1'b1;
        end
      end
      // send fourth data word
      state[SEND_DATA04] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = {tts_lock_thres[31:0], latch_l8_tts_lock[7:0], latch_l12_tts_lock[7:0], l8_enabled_ports[7:0], l12_enabled_ports[7:0]}; // 5th data word
          nextstate[SEND_DATA05] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA04] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA04] = 1'b1;
        end
      end
      // send fifth data word
      state[SEND_DATA05] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = {l8_tts_state[31:0], l12_tts_state[31:0]}; // 6th data word
          nextstate[SEND_DATA06] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA05] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA05] = 1'b1;
        end
      end
      // send sixth data word
      state[SEND_DATA06] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = l12_ttc_delays[63:0]; // 7th data word
          nextstate[SEND_DATA07] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA06] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA06] = 1'b1;
        end
      end
      // send seventh data word
      state[SEND_DATA07] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = l8_ttc_delays[63:0]; // 8th data word
          nextstate[SEND_DATA08] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA07] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA07] = 1'b1;
        end
      end
      // send eighth data word
      state[SEND_DATA08] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;
          next_daq_data[63:0] = l12_sfp_sn[0]; // 9th data word
          next_sfp_cntr[4:0] = 5'd1;
          nextstate[SEND_DATA09_TO_DATA24] = 1'b1;
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA08] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA08] = 1'b1;
        end
      end
      // send ninth thru twenty-fourth data word
      state[SEND_DATA09_TO_DATA24] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;

          if (sfp_cntr[4:0] < 5'd16) begin
            next_daq_data[63:0] = l12_sfp_sn[sfp_cntr]; // 10th - 24th data word
            next_sfp_cntr[4:0] = sfp_cntr[4:0] + 1'b1;
            nextstate[SEND_DATA09_TO_DATA24] = 1'b1;
          end
          else begin
            if (fc7_type[1:0] == 2'b10) begin
              // is fanout
              next_daq_data[63:0] = l8_sfp_sn[0]; // 25th data word
              next_sfp_cntr[4:0] = 5'd1;
              nextstate[SEND_DATA25_TO_DATA40] = 1'b1;
            end
            else begin
              // is encoder
              next_daq_data[63:0] = {32'h00000000, trig_num[7:0], 4'h0, 20'd28}; // AMC13 trailer
              nextstate[SEND_AMC13_TRAILER] = 1'b1;
            end
          end
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA09_TO_DATA24] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA09_TO_DATA24] = 1'b1;
        end
      end
      // send twenty-fifth thru fortieth data word
      state[SEND_DATA25_TO_DATA40] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;

          if (sfp_cntr[4:0] < 5'd16) begin
            next_daq_data[63:0] = l8_sfp_sn[sfp_cntr]; // 26th - 40th data word
            next_sfp_cntr[4:0] = sfp_cntr[4:0] + 1'b1;
            nextstate[SEND_DATA25_TO_DATA40] = 1'b1;
          end
          else begin
            // is fanout
            next_daq_data[63:0] = {32'h00000000, trig_num[7:0], 4'h0, 20'd44}; // AMC13 trailer
            nextstate[SEND_AMC13_TRAILER] = 1'b1;
          end
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_DATA25_TO_DATA40] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_DATA25_TO_DATA40] = 1'b1;
        end
      end
      // send second thru one-thousand-twenty-fifth data word, for pulse information
      state[SEND_PULSE_INFO] : begin
        if (daq_ready) begin
          next_daq_valid = 1'b1;

          // if (pulse_info_cntr[6:0] < 7'd64) begin
          if (pulse_info_cntr[6:0] < 7'd32) begin
            next_daq_data[63:0] = pulse_info[pulse_info_cntr]; // 2nd - 1025th data word
            next_pulse_info_cntr[6:0] = pulse_info_cntr[6:0] + 1'b1;
            nextstate[SEND_PULSE_INFO] = 1'b1;
          end
          else begin
            // is trigger
            next_daq_data[63:0] = {32'h00000000, trig_num[7:0], 4'h0, 20'd37}; // AMC13 trailer
            nextstate[SEND_AMC13_TRAILER] = 1'b1;
          end
        end
        else if (~daq_almost_full) begin
          next_daq_valid = 1'b1;
          nextstate[SEND_PULSE_INFO] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b0;
          nextstate[SEND_PULSE_INFO] = 1'b1;
        end
      end
      // send AMC13 trailer word
      state[SEND_AMC13_TRAILER] : begin
        // assert daq_trailer, and go back to idle
        if (daq_ready) begin
          nextstate[IDLE] = 1'b1;
        end
        else begin
          next_daq_valid = 1'b1;
          nextstate[SEND_AMC13_TRAILER] = 1'b1;
        end
      end
    endcase
  end


  // sequential always block
  integer m, n;
  always @(posedge clk) begin
    if (rst) begin
      // reset values
      state <= 19'd1 << IDLE;

      trig_timestamp[43:0] <= 44'd0;
      trig_num[23:0]       <= 24'd0;
      trig_type[4:0]       <=  5'd0;
      trig_delay[31:0]     <= 32'd0;
      trig_index[3:0]      <=  4'h0;
      trig_sub_index[3:0]  <=  4'h0;
      sfp_cntr[4:0]        <=  5'd0;
      pulse_info_cntr[6:0] <=  7'd0;

      latch_l12_tts_state[7:0]             <= 8'd0;
      latch_l8_tts_state[7:0]              <= 8'd0;
      latch_l12_tts_lock[7:0]              <= 8'd0;
      latch_l8_tts_lock[7:0]               <= 8'd0;
      latch_l12_tts_lock_mux               <= 1'b0;
      latch_l8_tts_lock_mux                <= 1'b0;
      latch_ext_clk_lock                   <= 1'b0;
      latch_ttc_clk_lock                   <= 1'b0;
      latch_ttc_ready                      <= 1'b0;
      latch_xadc_alarms[3:0]               <= 3'd0;
      latch_error_flag                     <= 1'b0;
      latch_error_l12_fmc_absent           <= 1'b0;
      latch_error_l8_fmc_absent            <= 1'b0;
      latch_change_error_l12_mod_abs[7:0]  <= 8'd0;
      latch_change_error_l8_mod_abs[7:0]   <= 8'd0;
      latch_change_error_l12_tx_fault[7:0] <= 8'd0;
      latch_change_error_l8_tx_fault[7:0]  <= 8'd0;
      latch_change_error_l12_rx_los[7:0]   <= 8'd0;
      latch_change_error_l8_rx_los[7:0]    <= 8'd0;

//      for (m = 0; m < 64; m = m + 1)
      for (m = 0; m < 32; m = m + 1)
      begin
        pulse_info[m][63:0] <= 64'd0;
      end
      
      daq_data[63:0] <= 64'd0;
      daq_valid      <=  1'b0;
    end
    else begin
      state <= nextstate;

      trig_timestamp[43:0] <= next_trig_timestamp[43:0];
      trig_num[23:0]       <= next_trig_num[23:0];
      trig_type[4:0]       <= next_trig_type[4:0];
      trig_delay[31:0]     <= next_trig_delay[31:0];
      trig_index[3:0]      <= next_trig_index[3:0];
      trig_sub_index[3:0]  <= next_trig_sub_index[3:0];
      sfp_cntr[4:0]        <= next_sfp_cntr[4:0];
      pulse_info_cntr[6:0] <= next_pulse_info_cntr[6:0];

      latch_l12_tts_state[7:0]             <= next_latch_l12_tts_state[7:0];
      latch_l8_tts_state[7:0]              <= next_latch_l8_tts_state[7:0];
      latch_l12_tts_lock[7:0]              <= next_latch_l12_tts_lock[7:0];
      latch_l8_tts_lock[7:0]               <= next_latch_l8_tts_lock[7:0];
      latch_l12_tts_lock_mux               <= next_latch_l12_tts_lock_mux;
      latch_l8_tts_lock_mux                <= next_latch_l8_tts_lock_mux;
      latch_ext_clk_lock                   <= next_latch_ext_clk_lock;
      latch_ttc_clk_lock                   <= next_latch_ttc_clk_lock;
      latch_ttc_ready                      <= next_latch_ttc_ready;
      latch_xadc_alarms[3:0]               <= next_latch_xadc_alarms[3:0];
      latch_error_flag                     <= next_latch_error_flag;
      latch_error_l12_fmc_absent           <= next_latch_error_l12_fmc_absent;
      latch_error_l8_fmc_absent            <= next_latch_error_l8_fmc_absent;
      latch_change_error_l12_mod_abs[7:0]  <= next_latch_change_error_l12_mod_abs[7:0];
      latch_change_error_l8_mod_abs[7:0]   <= next_latch_change_error_l8_mod_abs[7:0];
      latch_change_error_l12_tx_fault[7:0] <= next_latch_change_error_l12_tx_fault[7:0];
      latch_change_error_l8_tx_fault[7:0]  <= next_latch_change_error_l8_tx_fault[7:0];
      latch_change_error_l12_rx_los[7:0]   <= next_latch_change_error_l12_rx_los[7:0];
      latch_change_error_l8_rx_los[7:0]    <= next_latch_change_error_l8_rx_los[7:0];

      // for (n = 0; n < 64; n = n + 1)
      for (n = 0; n < 32; n = n + 1)
      begin
        pulse_info[n][63:0] <= next_pulse_info[n][63:0];
      end

      daq_data[63:0] <= next_daq_data[63:0];
      daq_valid      <= next_daq_valid;
    end
  end


  // datapath sequential always block
  always @(posedge clk) begin
    if (rst) begin
      // reset values
      daq_header  <= 0;
      daq_trailer <= 0;
    end
    else begin
      // default values
      daq_header  <= 0;
      daq_trailer <= 0;

      case (1'b1) // synopsys parallel_case full_case
        nextstate[IDLE]                  : begin
          ;
        end
        nextstate[READ_TRIG_FIFO]        : begin
          ;
        end
        nextstate[READ_PULSE_FIFO]       : begin
          ;
        end
        nextstate[READY_AMC13_HEADER1]   : begin
          ;
        end
        nextstate[SEND_AMC13_HEADER1]    : begin
          daq_header <= 1;
        end
        nextstate[SEND_AMC13_HEADER2]    : begin
          ;
        end
        nextstate[SEND_FC7_HEADER1]      : begin
          ;
        end
        nextstate[SEND_DATA01]           : begin
          ;
        end
        nextstate[SEND_DATA02]           : begin
          ;
        end
        nextstate[SEND_DATA03]           : begin
          ;
        end
        nextstate[SEND_DATA04]           : begin
          ;
        end
        nextstate[SEND_DATA05]           : begin
          ;
        end
        nextstate[SEND_DATA06]           : begin
          ;
        end
        nextstate[SEND_DATA07]           : begin
          ;
        end
        nextstate[SEND_DATA08]           : begin
          ;
        end
        nextstate[SEND_DATA09_TO_DATA24] : begin
          ;
        end
        nextstate[SEND_DATA25_TO_DATA40] : begin
          ;
        end
        nextstate[SEND_PULSE_INFO]       : begin
          ;
        end
        nextstate[SEND_AMC13_TRAILER]    : begin
          daq_trailer <= 1;
        end
      endcase
    end
  end

endmodule
