`timescale 1ns / 1ps

// Finite state machine for encoding the TTC protocol
// TESTBENCH 

module ttc_encoder_tb;

  // inputs
  reg clk160;
  reg rst;
  reg a_channel;
  reg [15:0] ttc_data;
  reg ttc_data_valid;

  // outputs
  wire ttc_bit_out;

  // instantiate the Unit-Under-Test (UUT)
  ttc_encoder uut (
    // clock and reset
    .clk160(clk160),
    .rst(rst),

    // input data
    .a_channel(a_channel),
    .ttc_data(ttc_data),
    .ttc_data_valid(ttc_data_valid),

    // output bit
    .ttc_bit_out(ttc_bit_out)
  );

  initial begin
    // initialize inputs
    clk160         = 1'b0;
    rst            = 1'b0;
    a_channel      = 1'b0;
    ttc_data       = 16'hffff;
    ttc_data_valid = 1'b0;
    
    // wait 100 ns for global reset to finish
    #100;

    // add stimulus here
    #3.125; // move to next rising clock edge
    
    //#6.25 a_channel = 1'b1;
    //#6.25 a_channel = 1'b0;
    
    #6.25 ttc_data = 16'b0010100000010101;
    #25;
    #6.25 ttc_data_valid = 1'b1;
    #6.25 ttc_data_valid = 1'b0;
  end

  always begin
    #3.125 clk160 = ~clk160; // 160 MHz
  end

endmodule
