// Finite state machine for storing trigger information.

module trigger_info_storer (
  // clock and reset
  input wire clk,
  input wire rst,

  // TTC information
  input wire trigger,           // L1Accept from TTC decoder
  input wire [5:0] broadcast,   // Brcst from TTC decoder, Brcst[7:2] = broadcast[5:0]
  input wire broadcast_valid,   // BrcstStr from TTC_decoder
  input wire event_count_reset, // EvCntRes from TTC_decoder

  // FIFO interface
  input wire fifo_ready,
  output reg [127:0] fifo_data,
  output reg fifo_valid,

  // trigger information
  output reg  [ 43:0] trig_timestamp,
  output reg  [ 23:0] trig_num,
  output wire [767:0] trig_type_num_vec,
  output reg  [  4:0] trig_type,

  // status
  output reg [1:0] state
);

  // expand trigger number memory into a vector,
  // indexing is: [type #]
  reg [23:0] trig_type_num [31:0];

  genvar i;
  for (i = 0; i < 32; i = i + 1)
  begin
    assign trig_type_num_vec[(24*i + 23):(24*i)] = trig_type_num[i];
  end

  // state bits
  parameter IDLE  = 0;
  parameter STORE = 1;

  // internal registers
  reg [43:0] trig_timestamp_cnt;

  // for internal regs
  reg [43:0] next_trig_timestamp_cnt;
  reg [23:0] next_trig_type_num [31:0];

  // for external regs
  reg [  1:0] nextstate;
  reg [127:0] next_fifo_data;
  reg next_fifo_valid;
  reg [ 43:0] next_trig_timestamp;
  reg [ 23:0] next_trig_num;
  reg [  4:0] next_trig_type;

  // comb always block
  integer j, k;
  always @* begin
    nextstate = 2'd0;

    next_fifo_data[127:0] = fifo_data[127:0];
    next_fifo_valid       = 1'b0;

    next_trig_timestamp[43:0]     = trig_timestamp[43:0];
    next_trig_timestamp_cnt[43:0] = trig_timestamp_cnt[43:0] + 1'b1; // continuously increment counter
    next_trig_num[23:0]           = trig_num[23:0];
    next_trig_type[4:0]           = trig_type[4:0];

    for (j = 0; j < 32; j = j + 1)
    begin
      next_trig_type_num[j][23:0] = trig_type_num[j][23:0];
    end
    
    case (1'b1) // synopsys parallel_case full_case
      // idle state
      state[IDLE] : begin
        // reset event count
        if (event_count_reset) begin
          next_trig_num[23:0] = 24'd0;

          for (k = 0; k < 32; k = k + 1)
          begin
            next_trig_type_num[k][23:0] = 24'd0;
          end
        end

        // interpret valid broadcast
        if (broadcast_valid) begin
          // reset timestamp counter
          if (broadcast[5:0] == 6'b001010) begin
            next_trig_timestamp_cnt[43:0] = 44'd0;
          end
          
          // update trigger type
          else if (broadcast[0]) begin
            next_trig_type[4:0] = broadcast[5:1];
          end
        end

        // store trigger information
        if (trigger) begin
          next_trig_timestamp[43:0] = trig_timestamp_cnt[43:0];
          next_trig_num[23:0]       = trig_num[23:0] + 1'b1;

          next_fifo_data[43: 0] = trig_timestamp_cnt[43:0];
          next_fifo_data[67:44] = trig_num[23:0] + 1'b1;
          next_fifo_data[72:68] = trig_type[4:0];
          next_fifo_valid       = 1'b1;

          // increment count for this trigger type
          next_trig_type_num[trig_type][23:0] = trig_type_num[trig_type][23:0] + 1'b1;

          nextstate[STORE] = 1'b1;
        end
        else begin
          nextstate[IDLE] = 1'b1;
        end
      end
      // store trigger information
      state[STORE] : begin
        // FIFO accepted data
        if (fifo_ready) begin
          nextstate[IDLE] = 1'b1;
        end
        // FIFO not ready, so wait here
        else begin
          next_fifo_valid = 1'b1;
          nextstate[STORE] = 1'b1;
        end
      end
    endcase
  end


  // sequential always block
  integer m, n;
  always @(posedge clk) begin
    if (rst) begin
      // reset values
      state <= 2'd1;

      fifo_data[127:0] <= 128'd0;
      fifo_valid       <=   1'b0;

      trig_timestamp[43:0]     <= 44'd0;
      trig_timestamp_cnt[43:0] <= 44'd0;
      trig_num[23:0]           <= 24'd0;
      trig_type[4:0]           <=  5'd0;

      for (m = 0; m < 32; m = m + 1)
      begin
        trig_type_num[m][23:0] <= 24'd0;
      end
    end
    else begin
      state <= nextstate;

      fifo_data[127:0] <= next_fifo_data[127:0];
      fifo_valid       <= next_fifo_valid;

      trig_timestamp[43:0]     <= next_trig_timestamp[43:0];
      trig_timestamp_cnt[43:0] <= next_trig_timestamp_cnt[43:0];
      trig_num[23:0]           <= next_trig_num[23:0];
      trig_type[4:0]           <= next_trig_type[4:0];

      for (n = 0; n < 32; n = n + 1)
      begin
        trig_type_num[n][23:0] <= next_trig_type_num[n][23:0];
      end
    end
  end

endmodule
