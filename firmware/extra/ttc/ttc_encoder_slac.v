`timescale 1ns / 1ps

// Finite state machine for encoding the TTC protocol

// Requirements:
//     (1) 'a_channel' is asserted for only one 'clk160' cycle
//     (2) 'ttc_data_valid' is asserted for four 'clk160' cycles

// As a useful reference, here's the syntax to mark signals for debug:
// (* mark_debug = "true" *) 

// ------------------------------------------------------------------------------------------------
// TTC FRAME (TDM of channels A and B):
// A channel: 1=trigger, 0=no trigger. No encoding, minimum latency.
// B channel: short broadcast or long addressed commands. Hamming check bits.
// 
// B Channel Content:
//
// IDLE=111111111111
//
// Short Broadcast, 16 bits:
// 00TTDDDDDEBHHHHH1: T=test command, 2 bits. D=Command/Data, 4 bits. E=Event Counter Reset, 1 bit.
//                    B=Bunch Counter Reset, 1 bit. H=Hamming Code, 5 bits.
// ttc hamming encoding for broadcast (d8/h5)
// /* build Hamming bits */
// hmg[0] = d[0]^d[1]^d[2]^d[3];
// hmg[1] = d[0]^d[4]^d[5]^d[6];
// hmg[2] = d[1]^d[2]^d[4]^d[5]^d[7];
// hmg[3] = d[1]^d[3]^d[4]^d[6]^d[7];
// hmg[4] = d[0]^d[2]^d[3]^d[5]^d[6]^d[7];
// /* build Hamming word */
// hamming = hmg[0] | (hmg[1]<<1) | (hmg[2]<<2) | (hmg[3]<<3) | (hmg[4]<<4);
// 
// TDM/BPM coding principle:
//   <  24.9501 ns   >
//   X---A---X---B---X
//   X=======X=======X  A=0, B=0 (no trigger, B=0) 
//   X=======X===X===X  A=0, B=1 (no trigger, B=1) - unlimited string length when IDLE 
//   X===X===X=======X  A=1, B=0 (trigger,    B=0) - max string length = 11, then switch phase
//   X===X===X===X===X  A=1, B=1 (trigger,    B=1)
// ------------------------------------------------------------------------------------------------

module ttc_encoder (
  // clock and reset
  input wire clk160,
  input wire rst,

  // input data
  input wire a_channel,
  input wire [15:0] ttc_data,
  input wire ttc_data_valid,

  // output bit
  output reg ttc_bit_out = 1'b1
);

  reg a_channel_latch       = 1'b0; // latched channel a trigger
  reg a_channel_done        = 1'b0; // the latched trigger has been encoded
  reg b_channel_done        = 1'b0; // the msb of the shift register has been encoded
  reg [15:0] ttc_data_shift = 16'hffff; // shift register for channel b data

  // state bits
  parameter BIT0 = 2'b00;
  parameter BIT1 = 2'b01;
  parameter BIT2 = 2'b10;
  parameter BIT3 = 2'b11;

  reg [1:0] state = BIT0;

  // bi-phase mark encoding sequence
  always @ (posedge clk160)
  begin
    case (state)
      // bi-phase mark encoding, bit 0
      BIT0 : begin
        // invert always
        ttc_bit_out    <= ~ttc_bit_out;
        a_channel_done <= 1'b0;
        b_channel_done <= 1'b0;
        state          <= BIT1;
      end
      // bi-phase mark encoding, bit 1
      BIT1 : begin
        // invert when Channel A = 1
        ttc_bit_out    <= ttc_bit_out^a_channel_latch;
        a_channel_done <= 1'b1;
        b_channel_done <= 1'b0;
        state          <= BIT2;
      end
      // bi-phase mark encoding, bit 2
      BIT2 : begin
        // invert always
        ttc_bit_out    <= ~ttc_bit_out;
        a_channel_done <= 1'b0;
        b_channel_done <= 1'b0;
        state          <= BIT3;
      end
      // bi-phase mark encoding, bit 3
      BIT3 : begin
        // invert when Channel B = 1
        ttc_bit_out    <= ttc_bit_out^(ttc_data_shift[15]);
        a_channel_done <= 1'b0;
        b_channel_done <= 1'b1;
        state          <= BIT0;
      end
    endcase
  end


  // data shifter for output bit
  always @ (posedge clk160)
  begin
    // ignore when in reset
    if (rst) begin
      ttc_data_shift[15:0] <= 16'hffff;
    end
    // load new data when valid
    else if (ttc_data_valid & b_channel_done) begin
      ttc_data_shift[15:0] <= ttc_data[15:0];
    end
    // shift the register after encoding
    else if (b_channel_done) begin
      ttc_data_shift[15:0] <= {ttc_data_shift[14:0], 1'b1};
    end
    // hold the current value
    else begin
      ttc_data_shift[15:0] <= ttc_data_shift[15:0];
    end
  end


  // latch the channel-a trigger
  always @ (posedge clk160)
  begin
    // ignore when in reset
    if (rst) begin
      a_channel_latch <= 1'b0;
    end
    // latch the trigger for the encoding
    else if (a_channel) begin // & a_channel_done) begin
      a_channel_latch <= 1'b1;
    end
    // clear the latched value after encoding
    else if (a_channel_done) begin
      a_channel_latch <= 1'b0;
    end
    // hold the current value
    else begin
      a_channel_latch <= a_channel_latch;
    end
  end

endmodule
