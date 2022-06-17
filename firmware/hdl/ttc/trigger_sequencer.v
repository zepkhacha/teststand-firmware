`include "ttc_commands.txt"

// Finite state machine for sending TTC triggers and commands.

// As a useful reference, here's the syntax to mark signals for debug:
// (* mark_debug = "true" *) 

module trigger_sequencer (
  // clock and reset
  input wire clk,
  input wire rst,

  // reset interface
  input wire [31:0] post_rst_delay_evt_cnt,
  input wire [31:0] post_rst_delay_timestamp,
  input wire [23:0] post_rst_delay_async,

  // trigger interface
  input  wire run_enable,                   // if the run is enabled
  input  wire run_pause,                    // if to pause sending trigger mid-run
  input  wire abort_run,                    // abort signal
  input  wire no_beam_structure,            // high signals no structure to beam, so no synchronization step should happen
  input  wire enable_async_storage,         // enable WFD5 asynchronous storage in run
  input  wire [ 3:0] global_count,          // number of sequences
  input  wire [23:0] ofw_cycle_threshold,   // overflow warning watchdog threshold
  input  wire [31:0] cycle_start_threshold, // super-cycle start wait threshold
  input  wire [31:0] eor_wait_count,        // wait period at the end-of-run
  input  wire trigger,                      // front-panel trigger
  input  wire send_ofw_boc,                 // if to send begin-of-cycle output trigger in overflow warning state
  output reg  begin_of_cycle,               // begin-of-cycle output trigger
  input  wire internal_trigger_strt,        // indicates internal triggering is transitioning on
  input  wire internal_trigger_stop,        // indicates internal triggering is transitioning off
  input  wire a6_missed_restart,            // indicates that an a6 was missed, requiring re-alignment of the supercycle
  output reg  trigger_clear,                // let the trigger latch know that we have used this trigger, and prepare to latch the next one

  // transceiver checks
  output reg  [  7:0] eeprom_channel_sel,
  output reg  eeprom_map_sel,
  output reg  [  7:0] eeprom_start_adr,
  output reg  [  5:0] eeprom_num_regs,
  output reg  eeprom_read_start,
  input  wire [127:0] eeprom_reg,
  input  wire eeprom_reg_valid,

  // trigger counts
  input wire [3:0] trig_count_seq0,
  input wire [3:0] trig_count_seq1,
  input wire [3:0] trig_count_seq2,
  input wire [3:0] trig_count_seq3,
  input wire [3:0] trig_count_seq4,
  input wire [3:0] trig_count_seq5,
  input wire [3:0] trig_count_seq6,
  input wire [3:0] trig_count_seq7,
  input wire [3:0] trig_count_seq8,
  input wire [3:0] trig_count_seq9,
  input wire [3:0] trig_count_seqa,
  input wire [3:0] trig_count_seqb,
  input wire [3:0] trig_count_seqc,
  input wire [3:0] trig_count_seqd,
  input wire [3:0] trig_count_seqe,
  input wire [3:0] trig_count_seqf,

  // fill types
  input wire [79:0] trig_type_seq0,
  input wire [79:0] trig_type_seq1,
  input wire [79:0] trig_type_seq2,
  input wire [79:0] trig_type_seq3,
  input wire [79:0] trig_type_seq4,
  input wire [79:0] trig_type_seq5,
  input wire [79:0] trig_type_seq6,
  input wire [79:0] trig_type_seq7,
  input wire [79:0] trig_type_seq8,
  input wire [79:0] trig_type_seq9,
  input wire [79:0] trig_type_seqa,
  input wire [79:0] trig_type_seqb,
  input wire [79:0] trig_type_seqc,
  input wire [79:0] trig_type_seqd,
  input wire [79:0] trig_type_seqe,
  input wire [79:0] trig_type_seqf,

  // pre-trigger gaps
  input wire [511:0] pre_trig_gap_seq0,
  input wire [511:0] pre_trig_gap_seq1,
  input wire [511:0] pre_trig_gap_seq2,
  input wire [511:0] pre_trig_gap_seq3,
  input wire [511:0] pre_trig_gap_seq4,
  input wire [511:0] pre_trig_gap_seq5,
  input wire [511:0] pre_trig_gap_seq6,
  input wire [511:0] pre_trig_gap_seq7,
  input wire [511:0] pre_trig_gap_seq8,
  input wire [511:0] pre_trig_gap_seq9,
  input wire [511:0] pre_trig_gap_seqa,
  input wire [511:0] pre_trig_gap_seqb,
  input wire [511:0] pre_trig_gap_seqc,
  input wire [511:0] pre_trig_gap_seqd,
  input wire [511:0] pre_trig_gap_seqe,
  input wire [511:0] pre_trig_gap_seqf,

  // TTC interface
  output reg channel_a,
  output reg [7:0] channel_b_data,
  output reg channel_b_valid,

  // trigger FIFO interface
  output reg  [ 43:0] trig_timestamp,
  output reg  [ 23:0] trig_num,
  output wire [767:0] trig_type_num_vec,
  output reg  [  4:0] trig_type,
  output reg  [ 31:0] trig_delay,
  output reg  [  3:0] trig_index,
  output reg  [  3:0] trig_sub_index,
  output reg  trig_info_valid,

  // status signals
  input  wire overflow_warning,
  input  wire [ 7:0] sfp_enabled_ports,
  output reg  [17:0] state,
  output reg  [63:0] run_timer,
  output reg  [23:0] ofw_cycle_count_running,
  output reg  [23:0] ofw_cycle_count,
  output reg  ofw_limit_reached,
  output wire run_in_progress,
  output wire doing_run_checks,
  output wire resetting_clients,
  output wire finding_cycle_start,
  output wire run_aborted,
  output reg  missing_trigger,
  output reg  async_enable_sent
);

  // combine the triggering parameters into memories,
  // indexing is: [sequence #][trigger #]
  wire [ 3:0] seq_trig_count   [15:0];       // one-dimensional memory for the trigger counts
  wire [ 4:0] seq_trig_type    [15:0][15:0]; // two-dimensional memory for the fill types for each sequence
  wire [31:0] seq_pre_trig_gap [15:0][15:0]; // two-dimensional memory for the pre-trigger gaps for each sequence

  // join together the trigger counts
  assign seq_trig_count[ 0] = trig_count_seq0[3:0];
  assign seq_trig_count[ 1] = trig_count_seq1[3:0];
  assign seq_trig_count[ 2] = trig_count_seq2[3:0];
  assign seq_trig_count[ 3] = trig_count_seq3[3:0];
  assign seq_trig_count[ 4] = trig_count_seq4[3:0];
  assign seq_trig_count[ 5] = trig_count_seq5[3:0];
  assign seq_trig_count[ 6] = trig_count_seq6[3:0];
  assign seq_trig_count[ 7] = trig_count_seq7[3:0];
  assign seq_trig_count[ 8] = trig_count_seq8[3:0];
  assign seq_trig_count[ 9] = trig_count_seq9[3:0];
  assign seq_trig_count[10] = trig_count_seqa[3:0];
  assign seq_trig_count[11] = trig_count_seqb[3:0];
  assign seq_trig_count[12] = trig_count_seqc[3:0];
  assign seq_trig_count[13] = trig_count_seqd[3:0];
  assign seq_trig_count[14] = trig_count_seqe[3:0];
  assign seq_trig_count[15] = trig_count_seqf[3:0];

  genvar i;
  for (i = 0; i < 16; i = i + 1)
  begin
    // separate out the fill types
    assign seq_trig_type[ 0][i] = trig_type_seq0[(5*i + 4):(5*i)];
    assign seq_trig_type[ 1][i] = trig_type_seq1[(5*i + 4):(5*i)];
    assign seq_trig_type[ 2][i] = trig_type_seq2[(5*i + 4):(5*i)];
    assign seq_trig_type[ 3][i] = trig_type_seq3[(5*i + 4):(5*i)];
    assign seq_trig_type[ 4][i] = trig_type_seq4[(5*i + 4):(5*i)];
    assign seq_trig_type[ 5][i] = trig_type_seq5[(5*i + 4):(5*i)];
    assign seq_trig_type[ 6][i] = trig_type_seq6[(5*i + 4):(5*i)];
    assign seq_trig_type[ 7][i] = trig_type_seq7[(5*i + 4):(5*i)];
    assign seq_trig_type[ 8][i] = trig_type_seq8[(5*i + 4):(5*i)];
    assign seq_trig_type[ 9][i] = trig_type_seq9[(5*i + 4):(5*i)];
    assign seq_trig_type[10][i] = trig_type_seqa[(5*i + 4):(5*i)];
    assign seq_trig_type[11][i] = trig_type_seqb[(5*i + 4):(5*i)];
    assign seq_trig_type[12][i] = trig_type_seqc[(5*i + 4):(5*i)];
    assign seq_trig_type[13][i] = trig_type_seqd[(5*i + 4):(5*i)];
    assign seq_trig_type[14][i] = trig_type_seqe[(5*i + 4):(5*i)];
    assign seq_trig_type[15][i] = trig_type_seqf[(5*i + 4):(5*i)];

    // separate out the pre-trigger gaps
    assign seq_pre_trig_gap[ 0][i] = pre_trig_gap_seq0[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 1][i] = pre_trig_gap_seq1[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 2][i] = pre_trig_gap_seq2[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 3][i] = pre_trig_gap_seq3[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 4][i] = pre_trig_gap_seq4[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 5][i] = pre_trig_gap_seq5[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 6][i] = pre_trig_gap_seq6[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 7][i] = pre_trig_gap_seq7[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 8][i] = pre_trig_gap_seq8[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[ 9][i] = pre_trig_gap_seq9[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[10][i] = pre_trig_gap_seqa[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[11][i] = pre_trig_gap_seqb[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[12][i] = pre_trig_gap_seqc[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[13][i] = pre_trig_gap_seqd[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[14][i] = pre_trig_gap_seqe[(32*i + 31):(32*i)];
    assign seq_pre_trig_gap[15][i] = pre_trig_gap_seqf[(32*i + 31):(32*i)];
  end

  // expand trigger number memory into a vector,
  // indexing is: [type #]
  reg [23:0] trig_type_num [31:0];

  genvar j;
  for (j = 0; j < 32; j = j + 1)
  begin
    assign trig_type_num_vec[(24*j + 23):(24*j)] = trig_type_num[j];
  end


  // state bits
  parameter IDLE             =  0;
  parameter INC_SFP_COUNTER  =  1;
  parameter CHECK_SFP_ENABLE =  2;
  parameter CHECK_SFP_STATUS =  3;
  parameter SEND_EVENT_RESET =  4;
  parameter SEND_COUNT_RESET =  5;
  parameter SEND_ASYNC_START =  6;
  parameter POST_ASYNC_START_DELAY =  7;
  parameter FIND_CYCLE_START =  8;
  parameter CHECK_RUN_STATUS =  9;
  parameter SET_TRIGGER_TYPE = 10;
  parameter PRE_TRIGGER_WAIT = 11;
  parameter SEND_TRIGGER     = 12;
  parameter SEND_ASYNC_STOP  = 13;
  parameter SEND_ASYNC_TYPE  = 14;
  parameter SEND_ASYNC_TRIG  = 15;
  parameter DELAY_ASYNC_START= 16;
  parameter ABORT            = 17;

  reg [31:0] wait_count;         // multiple-use counter for wait conditions
  reg [ 3:0] seq_index;          // sequence index
  reg [ 3:0] sub_seq_index;      // sub-sequence trigger index
  reg [43:0] trig_timestamp_cnt; // counter for timestamp
  reg [ 4:0] sfp_cntr;
  reg abort_run_latch;
  reg ofw_state_latch;

  // for internal regs
  reg [31:0] next_wait_count;
  reg [ 3:0] next_seq_index;
  reg [ 3:0] next_sub_seq_index;
  reg [43:0] next_trig_timestamp_cnt;
  reg [ 4:0] next_sfp_cntr;
  reg next_abort_run_latch;
  reg next_ofw_state_latch;
  reg [23:0] next_trig_type_num [31:0];

  // for external regs
  reg [17:0] nextstate;
  reg next_begin_of_cycle;
  reg [63:0] next_run_timer;
  reg next_channel_a;
  reg [ 7:0] next_channel_b_data;
  reg next_channel_b_valid;
  reg [43:0] next_trig_timestamp;
  reg [23:0] next_trig_num;
  reg [ 4:0] next_trig_type;
  reg [31:0] next_trig_delay;
  reg [ 3:0] next_trig_index;
  reg [ 3:0] next_trig_sub_index;
  reg next_trig_info_valid;
  reg [ 7:0] next_eeprom_channel_sel;
  reg next_eeprom_map_sel;
  reg [ 7:0] next_eeprom_start_adr;
  reg [ 5:0] next_eeprom_num_regs;
  reg next_eeprom_read_start;
  reg [23:0] next_ofw_cycle_count_running;
  reg [23:0] next_ofw_cycle_count;
  reg next_ofw_limit_reached;
  reg next_trigger_clear;
  reg next_async_enable_sent;

  // comb always block
  integer k, m;
  always @* begin
    nextstate = 17'd0;

    next_begin_of_cycle     = 1'b0; // default
    next_run_timer[63:0]    = run_timer[63:0];
    next_wait_count[31:0]   = wait_count[31:0];
    next_seq_index[3:0]     = seq_index[3:0];
    next_sub_seq_index[3:0] = sub_seq_index[3:0];
    next_sfp_cntr[4:0]      = sfp_cntr[4:0];
    next_abort_run_latch    = abort_run_latch;
    next_ofw_state_latch    = ofw_state_latch;
    next_trigger_clear      = 1'b0; // default
    next_async_enable_sent  = async_enable_sent;

    for (k = 0; k < 32; k = k + 1)
    begin
      next_trig_type_num[k][23:0] = trig_type_num[k][23:0];
    end

    next_channel_a           = 1'b0; // default
    next_channel_b_data[7:0] = channel_b_data[7:0];
    next_channel_b_valid     = 1'b0; // default

    next_trig_timestamp[43:0]     = trig_timestamp[43:0];
    next_trig_timestamp_cnt[43:0] = trig_timestamp_cnt[43:0] + 1'b1; // continuously increment counter
    next_trig_num[23:0]           = trig_num[23:0];
    next_trig_type[4:0]           = trig_type[4:0];
    next_trig_delay[31:0]         = trig_delay[31:0];
    next_trig_index[3:0]          = trig_index[3:0];
    next_trig_sub_index[3:0]      = trig_sub_index[3:0];
    next_trig_info_valid          = 1'b0; // default

    next_eeprom_channel_sel[7:0] = 8'd0; // default
    next_eeprom_map_sel          = eeprom_map_sel;
    next_eeprom_start_adr[7:0]   = eeprom_start_adr[7:0];
    next_eeprom_num_regs[5:0]    = eeprom_num_regs[5:0];
    next_eeprom_read_start       = 1'b0; // default

    next_ofw_cycle_count_running[23:0] = ofw_cycle_count_running[23:0];
    next_ofw_cycle_count[23:0]         = ofw_cycle_count[23:0];
    next_ofw_limit_reached             = ofw_limit_reached;
    
    case (1'b1) // synopsys parallel_case full_case
      // ---------------------------------------------------------------------------------------- //
      // idle state
      state[IDLE] : begin
        next_run_timer[63:0]    = 64'd0;
        next_wait_count[31:0]   = 32'd0;
        next_seq_index[3:0]     =  4'h0;
        next_sub_seq_index[3:0] =  4'h0;
        next_trigger_clear      =  1'b0;
        next_async_enable_sent  =  1'b0;

        // watch for the beginning of a new run
        if (run_enable) begin
          // clear counters
          next_sfp_cntr[4:0] = 5'd0;
          next_ofw_state_latch               =  1'b0;
          next_ofw_cycle_count_running[23:0] = 24'd0;
          next_ofw_cycle_count[23:0]         = 24'd0;
          next_ofw_limit_reached             =  1'b0;

          // a system error has occurred, so abort run
          if (abort_run | (sfp_enabled_ports[7:0] == 8'd0)) begin
            next_abort_run_latch = 1'b1;
            nextstate[ABORT] = 1'b1;
          end
          // initial check passed, continue with run
          else begin
            nextstate[CHECK_SFP_ENABLE] = 1'b1;
          end
        end
        // we're still deactivated
        else begin
          nextstate[IDLE] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // increment port counter
      state[INC_SFP_COUNTER] : begin
        next_sfp_cntr[4:0] <= sfp_cntr[4:0] + 1'b1;
        nextstate[CHECK_SFP_ENABLE] = 1'b1;
      end
      // ---------------------------------------------------------------------------------------- //
      // check if this port is enabled
      state[CHECK_SFP_ENABLE] : begin
        // we're done checking ports, go on to resets
        if (sfp_cntr[4:0] == 5'd8) begin
          // set up channel b for event count reset
          next_channel_b_data[7:0] = `EVENT_COUNT_RESET;
          next_channel_b_valid     =  1'b1;

          next_trig_num[23:0]           = 24'd0;
          next_trig_timestamp[43:0]     = 44'd0;
          next_trig_timestamp_cnt[43:0] = 44'd0;
          next_trig_type[4:0]           =  5'd0;
          next_trig_delay[31:0]         = 32'd0;
          next_trig_index[3:0]          =  4'h0;
          next_trig_sub_index[3:0]      =  4'h0;

          for (m = 0; m < 32; m = m + 1)
          begin
            next_trig_type_num[m][23:0] = 24'd0;
          end

          nextstate[SEND_EVENT_RESET] = 1'b1;
        end
        // this port is enabled
        else if (sfp_enabled_ports[sfp_cntr]) begin
          next_eeprom_channel_sel[sfp_cntr] = 1'b1;
          next_eeprom_map_sel               = 1'b1;
          next_eeprom_start_adr[7:0]        = 8'd112;
          next_eeprom_num_regs[5:0]         = 6'd6;
          next_eeprom_read_start            = 1'b1;

          nextstate[CHECK_SFP_STATUS] = 1'b1;
        end
        // skip this port
        else begin
          nextstate[INC_SFP_COUNTER] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // check the transceiver alarms and warnings
      state[CHECK_SFP_STATUS] : begin
        // the register has been read from transceiver
        if (eeprom_reg_valid) begin
          // no alarm or warning flags detected
          if (eeprom_reg[127:0] == 128'd0) begin
            nextstate[INC_SFP_COUNTER] = 1'b1;
          end
          // an alarm or warning has been detected
          else begin
            next_abort_run_latch = 1'b1;
            nextstate[ABORT] = 1'b1;
          end
        end
        // continue to wait for the register to be read
        else begin
          next_eeprom_channel_sel[sfp_cntr] = 1'b1;
          nextstate[CHECK_SFP_STATUS] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // reset the client's event count
      state[SEND_EVENT_RESET] : begin
        // the complete command has been pushed out, plus any extra delay
        if (wait_count[31:0] > post_rst_delay_evt_cnt[31:0]) begin
          // set up channel b for timestamp count reset
          next_channel_b_data[7:0] = `TIMESTAMP_RESET;
          next_channel_b_valid     =  1'b1;
          next_wait_count[31:0]    = 32'd0;

          nextstate[SEND_COUNT_RESET] = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SEND_EVENT_RESET] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // reset the client's timestamp count
      state[SEND_COUNT_RESET] : begin
        // the complete command has been pushed out, plus any extra delay
        if (wait_count[31:0] > post_rst_delay_timestamp[31:0]) begin
          next_wait_count[31:0] = 32'd0;

          if (no_beam_structure) begin
            if (enable_async_storage) begin
              nextstate[DELAY_ASYNC_START] = 1'b1;
            end
            else begin
              nextstate[CHECK_RUN_STATUS] = 1'b1;
            end
          end
          else begin
            nextstate[FIND_CYCLE_START] = 1'b1;
          end
// - lkg          if (enable_async_storage) begin
// - lkg            // set up channel b for asynchronous storage start
// - lkg            next_channel_b_data[7:0] = `START_ASYNC_STORAGE;
// - lkg            next_channel_b_valid     = 1'b1;
// - lkg
// - lkg            nextstate[SEND_ASYNC_START] = 1'b1;
// - lkg          end
// - lkg          else begin
// - lkg            nextstate[FIND_CYCLE_START] = 1'b1;
// - lkg          end
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SEND_COUNT_RESET] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // configurable delay before starting asynchronouse storage
      state[DELAY_ASYNC_START] : begin
        // the async start delay has completed
        //lkg if (wait_count[23:0] > post_rst_delay_async[23:0]) begin
        //lkg   next_wait_count[31:0] = 32'd0;
          
          // set up channel b for asynchronous storage start
          next_channel_b_data[7:0] = `START_ASYNC_STORAGE;
          next_channel_b_valid     = 1'b1;

          nextstate[SEND_ASYNC_START] = 1'b1;
          //lkg end
          //lkg else begin
            //lkg next_wait_count[23:0] = wait_count[23:0] + 1'b1;
            //lkg nextstate[DELAY_ASYNC_START] = 1'b1;
          //lkg end
      end
      // ---------------------------------------------------------------------------------------- //
      // start WFD5 asynchronous storage
      state[SEND_ASYNC_START] : begin
        // the complete command has been pushed out
        if (wait_count[31:0] > 32'd16) begin
          next_wait_count[31:0] = 32'd0;
          next_async_enable_sent = 1'b1;
          nextstate[POST_ASYNC_START_DELAY] = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SEND_ASYNC_START] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // wait for the next accelerator trigger to synchronize the next state
      state[POST_ASYNC_START_DELAY] : begin
        if (wait_count[31:0] > 32'd4000) begin
          next_wait_count[31:0] = 32'd0;
          nextstate[CHECK_RUN_STATUS] = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[POST_ASYNC_START_DELAY] = 1'b1;
        end

      end
      // ---------------------------------------------------------------------------------------- //
      // detect the start of the super-cycle
      state[FIND_CYCLE_START] : begin
        // turn off the trigger clear signal so that we can accept the next input trigger
        if ( trigger_clear ) begin
           next_trigger_clear = 1'b0;
        end
        
        // check run state to allow for a software exit
        if (~run_enable) begin
          next_wait_count[31:0]   = 32'd0;
          next_seq_index[3:0]     =  4'h0;
          next_sub_seq_index[3:0] =  4'h0;

          if (enable_async_storage) begin
            // set up channel b for asynchronous storage stop
            next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_STOP] = 1'b1;
          end
          else begin
            nextstate[IDLE] = 1'b1;
          end
        end
        // the next trigger will be the first of the super-cycle
        else if (wait_count[31:0] > cycle_start_threshold[31:0]) begin
          // if async triggers will be accepted, set up for the configured delay before enabling front panels
          if (enable_async_storage) begin
            next_wait_count[31:0]        = 32'd0;
            nextstate[DELAY_ASYNC_START] = 1'b1;
          end
          // proceed to check that run has not completed
          else begin
            nextstate[CHECK_RUN_STATUS] = 1'b1;
          end
        end
        // this is a mid-cycle trigger, so reset the counter
        else if (trigger) begin
          next_wait_count[31:0] = 32'd0;
          nextstate[FIND_CYCLE_START] = 1'b1;
          next_trigger_clear = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[FIND_CYCLE_START] = 1'b1;
          next_trigger_clear = 1'b0;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // check the run status before continuing
      state[CHECK_RUN_STATUS] : begin
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer
        next_trigger_clear = 1'b0;

        // the run has been stopped, so quit
        if (~run_enable) begin
          next_wait_count[31:0]   = 32'd0;
          next_seq_index[3:0]     =  4'h0;
          next_sub_seq_index[3:0] =  4'h0;

          if (enable_async_storage) begin
            // set up channel b for asynchronous storage stop
            next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_STOP] = 1'b1;
          end
          else begin
            nextstate[IDLE] = 1'b1;
          end
        end
        // a system error has occurred, so abort run
        else if (abort_run) begin
          next_wait_count[31:0] = 32'd0;
          next_abort_run_latch  =  1'b1;

          if (enable_async_storage) begin
            // set up channel b for asynchronous storage stop
            next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_STOP] = 1'b1;
          end
          else begin
            nextstate[ABORT] = 1'b1;
          end
        end
        // the run has been paused, wait here
        else if (run_pause) begin
          nextstate[CHECK_RUN_STATUS] = 1'b1;
        end
        // overflow warning has been asserted for too long, so abort run
        else if (ofw_cycle_count[23:0] > ofw_cycle_threshold[23:0]) begin
          next_ofw_limit_reached =  1'b1;
          next_wait_count[31:0]  = 32'd0;
          next_abort_run_latch   =  1'b1;

          if (enable_async_storage) begin
            // set up channel b for asynchronous storage stop
            next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_STOP] = 1'b1;
          end
          else begin
            nextstate[ABORT] = 1'b1;
          end
        end
        // continue with the run
        else begin
          // issue the begin-of-cycle trigger
          next_begin_of_cycle = (~overflow_warning) | send_ofw_boc;

          // latch overflow warning state
          next_ofw_state_latch = overflow_warning;

          // overflow warning counting
          if (overflow_warning) begin
            // count the number of super-cycles while in overflow warning
            next_ofw_cycle_count_running[23:0] = ofw_cycle_count_running[23:0] + 1'b1;
            next_ofw_cycle_count[23:0]         = ofw_cycle_count[23:0] + 1'b1;
          end
          else begin
            // clear overflow warning count
            next_ofw_cycle_count[23:0] = 24'd0;
          end

          // set up channel b for fill type
          next_channel_b_data[7:0] = {seq_trig_type[seq_index][sub_seq_index], 3'b100};
          next_channel_b_valid     =  1'b1;
          next_wait_count[31:0]    = 32'd0;
          next_sub_seq_index[3:0]  =  4'h0;
          nextstate[SET_TRIGGER_TYPE] = 1'b1;
        end
      end
      // ---------------------------------------------------------------------------------------- //
      // set the fill type for the next trigger
      state[SET_TRIGGER_TYPE] : begin
        if ( trigger_clear ) begin
           next_trigger_clear = 1'b0;
        end
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer

        // the complete command has been pushed out
        if (wait_count[31:0] > 32'd16) begin
          // a system error has occurred, so abort run
          if (abort_run) begin
            next_wait_count[31:0] = 32'd0;
            next_abort_run_latch  =  1'b1;

            if (enable_async_storage) begin
              // set up channel b for asynchronous storage stop
              next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
              next_channel_b_valid     = 1'b1;
              nextstate[SEND_ASYNC_STOP] = 1'b1;
            end
            else begin
              nextstate[ABORT] = 1'b1;
            end
          end
          // we're in the middle of a sequence
          else if (sub_seq_index[3:0] > 4'h0) begin
            next_wait_count[31:0] = 32'd0; // clear the count
            nextstate[PRE_TRIGGER_WAIT] = 1'b1;
          end
          // start the sequence on the accelerator trigger
          else if (trigger) begin
            next_wait_count[31:0] = 32'd0; // clear the count
            // we are transitioning to/from internal trigger, or we've missed an a6, so need to resynchronize with the supercycle
            if ( (internal_trigger_strt || internal_trigger_stop || a6_missed_restart) && !no_beam_structure ) begin
              next_seq_index[3:0]     = 4'h0;
              next_sub_seq_index[3:0] = 4'h0;
              nextstate[FIND_CYCLE_START] = 1'b1;
            end
            else begin
              nextstate[PRE_TRIGGER_WAIT] = 1'b1;
            end
            next_trigger_clear = 1'b1;
          end
          // wait for the next accelerator trigger
          else begin
            nextstate[SET_TRIGGER_TYPE] = 1'b1;
          end
        end
        else begin
          // we're still waiting; increment the count
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SET_TRIGGER_TYPE] = 1'b1;
        end
      end
      // wait for the prescribed gap length
      state[PRE_TRIGGER_WAIT] : begin
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer
        next_trigger_clear = 1'b0;

        // a system error has occurred, so abort run
        if (abort_run) begin
          next_wait_count[31:0] = 32'd0;
          next_abort_run_latch  =  1'b1;

          if (enable_async_storage) begin
            // set up channel b for asynchronous storage stop
            next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_STOP] = 1'b1;
          end
          else begin
            nextstate[ABORT] = 1'b1;
          end
        end
        // the pre-trigger wait is over
        else if (wait_count[31:0] >= seq_pre_trig_gap[seq_index][sub_seq_index]) begin
          // only issue the trigger when not in an overflow warning state
          if (~ofw_state_latch) begin
            // issue the trigger
            next_channel_a = 1'b1;

            // latch this trigger's information
            next_trig_num[23:0]       = trig_num[23:0] + 1'b1;
            next_trig_timestamp[43:0] = trig_timestamp_cnt[43:0];
            next_trig_type[4:0]       = seq_trig_type[seq_index][sub_seq_index];
            next_trig_delay[31:0]     = seq_pre_trig_gap[seq_index][sub_seq_index];
            next_trig_index[3:0]      = seq_index[3:0];
            next_trig_sub_index[3:0]  = sub_seq_index[3:0];
            next_trig_info_valid      = 1'b1;

            // increment count for this trigger type
            next_trig_type_num[ seq_trig_type[seq_index][sub_seq_index] ][23:0] = trig_type_num[ seq_trig_type[seq_index][sub_seq_index] ][23:0] + 1'b1;
          end
          
          nextstate[SEND_TRIGGER] = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[PRE_TRIGGER_WAIT] = 1'b1;
        end
      end
      // issue a trigger to the client
      state[SEND_TRIGGER] : begin
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer
        if ( trigger_clear ) begin
           next_trigger_clear = 1'b0;
        end

        // a system error has occurred, so abort run
        if (abort_run) begin
          next_wait_count[31:0] = 32'd0;
          next_abort_run_latch  =  1'b1;

          if (enable_async_storage) begin
            // set up channel b for asynchronous storage stop
            next_channel_b_data[7:0] = `STOP_ASYNC_STORAGE;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_STOP] = 1'b1;
          end
          else begin
            nextstate[ABORT] = 1'b1;
          end
        end
        // the super-cycle is complete
        else if ((seq_index[3:0] == global_count[3:0]) & (sub_seq_index[3:0] == seq_trig_count[seq_index][3:0])) begin
          next_seq_index[3:0]     = 4'h0;
          next_sub_seq_index[3:0] = 4'h0;

          nextstate[CHECK_RUN_STATUS] = 1'b1;
        end
        // prepare for the next trigger in the sequence
        else begin
          // the sequence is complete
          if (sub_seq_index[3:0] == seq_trig_count[seq_index][3:0]) begin
            next_seq_index[3:0]     = seq_index[3:0] + 1'b1;
            next_sub_seq_index[3:0] = 4'h0;
            next_channel_b_data[7:0] = {seq_trig_type[seq_index+1][0], 3'b100};
          end
          else begin
            next_sub_seq_index[3:0]  = sub_seq_index[3:0] + 1'b1;
            next_channel_b_data[7:0] = {seq_trig_type[seq_index][sub_seq_index+1], 3'b100};
          end

          // set up channel b for trigger type
          next_channel_b_valid  =  1'b1;
          next_wait_count[31:0] = 32'd0;
          nextstate[SET_TRIGGER_TYPE] = 1'b1;
        end
      end
      // stop WFD5 asynchronous storage
      state[SEND_ASYNC_STOP] : begin
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer
        if ( trigger_clear ) begin
           next_trigger_clear = 1'b0;
        end

        // the complete command has been pushed out
        if (wait_count[31:0] > 32'd16) begin
          next_wait_count[31:0] = 32'd0;

          if (abort_run_latch) begin
            nextstate[ABORT] = 1'b1;
          end
          else begin
            // set up channel b for asynchronous readout trigger type
            next_channel_b_data[7:0] = 8'b00100_1_00;
            next_channel_b_valid     = 1'b1;
            nextstate[SEND_ASYNC_TYPE] = 1'b1;
          end
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SEND_ASYNC_STOP] = 1'b1;
        end
      end
      // set the fill type for the next trigger
      state[SEND_ASYNC_TYPE] : begin
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer
        if ( trigger_clear ) begin
           next_trigger_clear = 1'b0;
        end

        // the complete command has been pushed out
        if (wait_count[31:0] > 32'd16) begin
          next_wait_count[31:0] = 32'd0;
          nextstate[SEND_ASYNC_TRIG] = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SEND_ASYNC_TYPE] = 1'b1;
        end
      end
      // wait here before issuing trigger
      state[SEND_ASYNC_TRIG] : begin
        next_run_timer[63:0] = run_timer[63:0] + 1'b1; // increment run timer
        if ( trigger_clear ) begin
           next_trigger_clear = 1'b0;
        end

        if (wait_count[31:0] >= eor_wait_count[31:0]) begin
          next_wait_count[31:0]   = 32'd0;
          next_seq_index[3:0]     =  4'h0;
          next_sub_seq_index[3:0] =  4'h0;

          // issue the trigger
          next_channel_a = 1'b1;

          // latch this trigger's information
          next_trig_num[23:0]       = trig_num[23:0] + 1'b1;
          next_trig_timestamp[43:0] = trig_timestamp_cnt[43:0];
          next_trig_type[4:0]       = 5'b00100;
          next_trig_delay[31:0]     = eor_wait_count[31:0];
          next_trig_index[3:0]      = 4'h0;
          next_trig_sub_index[3:0]  = 4'h0;
          next_trig_info_valid      = 1'b1;

          // increment count for this trigger type
          next_trig_type_num[4][23:0] = trig_type_num[4][23:0] + 1'b1;

          nextstate[IDLE] = 1'b1;
        end
        else begin
          next_wait_count[31:0] = wait_count[31:0] + 1'b1;
          nextstate[SEND_ASYNC_TRIG] = 1'b1;
        end
      end
      // abort the run immediately
      state[ABORT] : begin
        // stay here until the run is disabled
        if (run_enable) begin
          nextstate[ABORT] = 1'b1;
        end
        else begin
          next_seq_index[3:0]     = 4'h0;
          next_sub_seq_index[3:0] = 4'h0;

          next_ofw_state_latch       =  1'b0;
          next_ofw_cycle_count[23:0] = 24'd0;
          next_ofw_limit_reached     =  1'b0;

          next_trigger_clear = 1'b0;

          next_abort_run_latch = 1'b0;
          nextstate[IDLE] = 1'b1;
        end
      end
    endcase
  end


  // sequential always block
  integer n, o;
  always @(posedge clk) begin
    if (rst) begin
      // reset values
      state <= 17'd1;

      begin_of_cycle     <=  1'b0;
      run_timer[63:0]    <= 64'd0;
      wait_count[31:0]   <= 32'd0;
      seq_index[3:0]     <=  4'h0;
      sub_seq_index[3:0] <=  4'h0;
      sfp_cntr[4:0]      <=  5'd0;
      abort_run_latch    <=  1'b0;
      ofw_state_latch    <=  1'b0;
      trigger_clear      <=  1'b0;
      async_enable_sent  <=  1'b0;

      channel_a           <= 1'b0;
      channel_b_data[7:0] <= 8'd0;
      channel_b_valid     <= 1'b0;

      trig_timestamp[43:0]     <= 44'd0;
      trig_timestamp_cnt[43:0] <= 44'd0;
      trig_num[23:0]           <= 24'd0;
      trig_type[4:0]           <=  5'd0;
      trig_delay[31:0]         <= 32'd0;
      trig_index[3:0]          <=  4'h0;
      trig_sub_index[3:0]      <=  4'h0;
      trig_info_valid          <=  1'b0;

      for (n = 0; n < 32; n = n + 1)
      begin
        trig_type_num[n][23:0] <= 24'd0;
      end

      eeprom_channel_sel[7:0] <= 8'd0;
      eeprom_map_sel          <= 1'b0;
      eeprom_start_adr[7:0]   <= 8'd0;
      eeprom_num_regs[5:0]    <= 6'd0;
      eeprom_read_start       <= 1'b0;

      ofw_cycle_count_running[23:0] <= 24'd0;
      ofw_cycle_count[23:0]         <= 24'd0;
      ofw_limit_reached             <=  1'b0;
    end
    else begin
      state <= nextstate;

      begin_of_cycle     <= next_begin_of_cycle;
      run_timer[63:0]    <= next_run_timer[63:0];
      wait_count[31:0]   <= next_wait_count[31:0];
      seq_index[3:0]     <= next_seq_index[3:0];
      sub_seq_index[3:0] <= next_sub_seq_index[3:0];
      sfp_cntr[4:0]      <= next_sfp_cntr[4:0];
      abort_run_latch    <= next_abort_run_latch;
      ofw_state_latch    <= next_ofw_state_latch;
      trigger_clear      <= next_trigger_clear;
      async_enable_sent  <= next_async_enable_sent;

      channel_a           <= next_channel_a;
      channel_b_data[7:0] <= next_channel_b_data[7:0];
      channel_b_valid     <= next_channel_b_valid;

      trig_timestamp[43:0]     <= next_trig_timestamp[43:0];
      trig_timestamp_cnt[43:0] <= next_trig_timestamp_cnt[43:0];
      trig_num[23:0]           <= next_trig_num[23:0];
      trig_type[4:0]           <= next_trig_type[4:0];
      trig_delay[31:0]         <= next_trig_delay[31:0];
      trig_index[3:0]          <= next_trig_index[3:0];
      trig_sub_index[3:0]      <= next_trig_sub_index[3:0];
      trig_info_valid          <= next_trig_info_valid;

      for (o = 0; o < 32; o = o + 1)
      begin
        trig_type_num[o][23:0] <= next_trig_type_num[o][23:0];
      end

      eeprom_channel_sel[7:0] <= next_eeprom_channel_sel[7:0];
      eeprom_map_sel          <= next_eeprom_map_sel;
      eeprom_start_adr[7:0]   <= next_eeprom_start_adr[7:0];
      eeprom_num_regs[5:0]    <= next_eeprom_num_regs[5:0];
      eeprom_read_start       <= next_eeprom_read_start;

      ofw_cycle_count_running[23:0] <= next_ofw_cycle_count_running[23:0];
      ofw_cycle_count[23:0]         <= next_ofw_cycle_count[23:0];
      ofw_limit_reached             <= next_ofw_limit_reached;
    end
  end


  // static assignments
  assign run_in_progress     = ~state[IDLE];
  assign doing_run_checks    = state[INC_SFP_COUNTER] | state[CHECK_SFP_ENABLE] | state[CHECK_SFP_STATUS];
  assign resetting_clients   = state[SEND_EVENT_RESET] | state[SEND_COUNT_RESET];
  assign finding_cycle_start = state[FIND_CYCLE_START];
  assign run_aborted         = state[ABORT];

endmodule
