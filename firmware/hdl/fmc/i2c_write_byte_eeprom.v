// This module will write one byte from an EEPROM

module i2c_write_byte_eeprom (
    // inputs
    input clk,               // 125-MHz clock
    input reset,             // reset
    input i2c_dev_ext,       // EEPROM has extended address width
    input [6:0] i2c_dev_adr, // EEPROM memory map section
    input [7:0] i2c_reg_adr, // memory location within the EEPROM
    input [7:0] i2c_reg_dat, // data register value
    input i2c_start_write,   // initiate a byte write
    // outputs
    output reg i2c_wr_done,  // the byte has been written
    output reg error,        // error has occured
    // I2C signals
    input  scl_pad_i,        // 'clock' input from external pin
    output scl_pad_o,        // 'clock' output to tri-state driver
    output scl_padoen_o,     // 'clock' enable signal for tri-state driver
    input  sda_pad_i,        // 'data' input from external pin
    output sda_pad_o,        // 'data' output to tri-state driver
    output sda_padoen_o      // 'data' enable signal for tri-state driver
);

// Create an counter used for pausing between bytes
reg init_pause_cntr, dec_pause_cntr;
reg [20:0] pause_cntr;
always @(posedge clk) begin
    if (reset | init_pause_cntr)
        pause_cntr[20:0] <= 21'd1250000; // 1,250,000 = 10 msec @ 125 MHz
    else if (dec_pause_cntr)
        pause_cntr[20:0] <= pause_cntr[20:0] - 1;
end

// Create registers for the state machine outputs
reg tx_reg_init1, tx_reg_init2, tx_reg_init3, tx_reg_init4;
reg core_en;
reg i2c_start;
reg i2c_stop;
reg i2c_write;
reg i2c_read;

wire irxack;
wire cmd_ack;

// Create a transmit register to hold the byte that we send out on the I2C link
reg [7:0] tx_reg;
always @(posedge clk) begin
    if (tx_reg_init1) tx_reg <= {i2c_dev_adr, 1'b0}; // address phase for a WRITE
    if (tx_reg_init2) tx_reg <= 8'd0;                // EEPROM address, MSB
    if (tx_reg_init3) tx_reg <= i2c_reg_adr;         // EEPROM address, LSB
    if (tx_reg_init4) tx_reg <= i2c_reg_dat;         // data register
end

// Connect the I2C controller module
// This came from the 'opencores' website at http://opencores.org/project,i2c
// The 'wishbone' interface was eliminated, and direct connections made to the 'byte controller' block
i2c_master_byte_ctrl byte_controller (
    // inputs
    .clk(clk),              // master clock
    .rst(reset),            // synchronous active high reset
    .nReset(1'b1),          // asynchronous active low reset, NOT USED SO HELD HIGH
    .ena(core_en),          // core enable signal
    .clk_cnt(16'd499),      // = (clk/(5*SCL)) - 1, so for 125-MHz 'clk' and 50-kHz SCL, need 499
    .start(i2c_start),      // prepend an I2C 'start' cycle
    .stop(i2c_stop),        // post-pend an I2C 'stop' cycle
    .read(i2c_read),        // do an I2C 'read' operation
    .write(i2c_write),      // do an I2C 'write' operation
    .ack_in(1'b0),          // ACK/NACK to send out on I2C bus after a READ
    .din(tx_reg[7:0]),      // byte that we send out on the EEPROM
    // outputs
    .cmd_ack(cmd_ack),      // the command is complete
    .ack_out(irxack),       // status of the ACK bit from the I2C bus
    .dout(),                // byte read from EEPROM
    // I2C signals
    .scl_i(scl_pad_i),      // 'clock' input from external pin
    .scl_o(scl_pad_o),      // 'clock' output to tri-state driver
    .scl_oen(scl_padoen_o), // 'clock' enable signal for tri-state driver
    .sda_i(sda_pad_i),      // 'data' input from external pin
    .sda_o(sda_pad_o),      // 'data' output to tri-state driver
    .sda_oen(sda_padoen_o)  // 'data' enable signal for tri-state driver
);

// Connect a state machine that will drive the 'byte_controller' through the whole
// sequence required to read a byte from the EEPROM. This is replacing the 'wishbone'
// interface of the original 'opencores' project.

// Declare the symbolic names for states
// Simplified one-hot encoding (each constant is an index into an array of bits)
parameter [4:0]
    IDLE       = 5'd0,
    ENABLE     = 5'd1,
    WAIT1      = 5'd2,
    DEV_INIT1  = 5'd3,
    DEV_INIT2  = 5'd4,
    DEV_INIT3  = 5'd5,
    DEV_INIT4  = 5'd6,
    PAUSE1     = 5'd7,
    ADR1_INIT1 = 5'd8,
    ADR1_INIT2 = 5'd9,
    ADR1_INIT3 = 5'd10,
    ADR1_INIT4 = 5'd11,
    PAUSE2     = 5'd12,
    ADR2_INIT1 = 5'd13,
    ADR2_INIT2 = 5'd14,
    ADR2_INIT3 = 5'd15,
    ADR2_INIT4 = 5'd16,
    PAUSE3     = 5'd17,
    DAT_INIT1  = 5'd18,
    DAT_INIT2  = 5'd19,
    DAT_INIT3  = 5'd20,
    DAT_INIT4  = 5'd21,
    ERROR      = 5'd22,
    DONE       = 5'd23;

// Declare current state and next state variables
reg [23:0] /* synopsys enum STATE_TYPE */ CS;
reg [23:0] /* synopsys enum STATE_TYPE */ NS;
// synopsys state_vector CS
 
// sequential always block for state transitions (use non-blocking [<=] assignments)
always @ (posedge clk) begin
    if (reset) begin
        CS <= 24'b0;      // set all state bits to 0
        CS[IDLE] <= 1'b1; // set IDLE state bit to 1
    end
    else
        CS <= NS;         // set state bits to next state
end

// combinational always block to determine next state (use blocking [=] assignments)
always @ (CS or i2c_start_write or cmd_ack or irxack or pause_cntr[20:0] or i2c_dev_ext) begin
    NS = 24'b0; // default all bits to zero; will override one bit

    case (1'b1) // synopsys full_case parallel_case
        // Leave the IDLE state as soon as 'reset' is negated
        CS[IDLE]: begin
            NS[ENABLE] = 1'b1;
        end

        // Enable the I2C controller; it will start up using the counter pre-scale value
        CS[ENABLE]: begin
            NS[WAIT1] = 1'b1;
        end

        // Wait for a request to read a byte
        CS[WAIT1]: begin
            if (i2c_start_write)
                NS[DEV_INIT1] = 1'b1;
            else
                NS[WAIT1] = 1'b1;           
        end

        // Initialize the device address and the WR bit
        CS[DEV_INIT1]: begin
            NS[DEV_INIT2] = 1'b1;
        end

        // Send the device address and the WR bit
        CS[DEV_INIT2]: begin
            NS[DEV_INIT3] = 1'b1;
        end

        // Wait for completion of the transfer
        CS[DEV_INIT3]: begin
            if (cmd_ack)
                NS[DEV_INIT4] = 1'b1;
            else
                NS[DEV_INIT3] = 1'b1;
        end

        // Check the state of the ACK bit on the I2C bus
        CS[DEV_INIT4]: begin
            if (irxack)
                NS[ERROR] = 1'b1;
            else
                NS[PAUSE1] = 1'b1;
        end

        // Insert a delay between bytes
        CS[PAUSE1]: begin
            if (pause_cntr[20:0] == 21'd0) begin
                if (i2c_dev_ext)
                    NS[ADR1_INIT1] = 1'b1;
                else
                    NS[ADR2_INIT1] = 1'b1;
            end
            else
                NS[PAUSE1] = 1'b1;
        end
        
        // Send the EEPROM address, MSB
        CS[ADR1_INIT1]: begin
            NS[ADR1_INIT2] = 1'b1;
        end

        // Send the EEPROM address, MSB
        CS[ADR1_INIT2]: begin
            NS[ADR1_INIT3] = 1'b1;
        end

        // Wait for completion of the transfer
        CS[ADR1_INIT3]: begin
            if (cmd_ack)
                NS[ADR1_INIT4] = 1'b1;
            else
                NS[ADR1_INIT3] = 1'b1;
        end

        // Check the state of the ACK bit on the I2C bus
        CS[ADR1_INIT4]: begin
            if (irxack)
                NS[ERROR] = 1'b1;
            else
                NS[PAUSE2] = 1'b1;
        end

        // Insert a delay between bytes
        CS[PAUSE2]: begin
            if (pause_cntr[20:0] == 21'd0)
                NS[ADR2_INIT1] = 1'b1;
            else
                NS[PAUSE2] = 1'b1;
        end
        
        // Send the EEPROM address, LSB
        CS[ADR2_INIT1]: begin
            NS[ADR2_INIT2] = 1'b1;
        end

        // Send the EEPROM addressm LSB
        CS[ADR2_INIT2]: begin
            NS[ADR2_INIT3] = 1'b1;
        end

        // Wait for completion of the transfer
        CS[ADR2_INIT3]: begin
            if (cmd_ack)
                NS[ADR2_INIT4] = 1'b1;
            else
                NS[ADR2_INIT3] = 1'b1;
        end

        // Check the state of the ACK bit on the I2C bus
        CS[ADR2_INIT4]: begin
            if (irxack)
                NS[ERROR] = 1'b1;
            else
                NS[PAUSE3] = 1'b1;
        end

        // Insert a delay between bytes
        CS[PAUSE3]: begin
            if (pause_cntr[20:0] == 21'd0)
                NS[DAT_INIT1] = 1'b1;
            else
                NS[PAUSE3] = 1'b1;
        end

        // Send the data register
        CS[DAT_INIT1]: begin
            NS[DAT_INIT2] = 1'b1;
        end

        // Send the data register
        CS[DAT_INIT2]: begin
            NS[DAT_INIT3] = 1'b1;
        end

        // Wait for completion of the transfer
        CS[DAT_INIT3]: begin
            if (cmd_ack)
                NS[DAT_INIT4] = 1'b1;
            else
                NS[DAT_INIT3] = 1'b1;
        end

        // Check the state of the ACK bit on the I2C bus
        CS[DAT_INIT4]: begin
            if (irxack)
                NS[ERROR] = 1'b1;
            else
                NS[DONE] = 1'b1;
        end

        // Do some type of error reporting
        CS[ERROR]: begin
            NS[DONE] = 1'b1;
        end

        // Done
        CS[DONE]: begin
            NS[IDLE] = 1'b1;
        end
    endcase
end // combinational always block to determine next state

// Drive outputs for each state at the same time as when we enter the state.
// Use the NS[] array.
always @(posedge clk) begin
    // defaults
    core_en         <= 1'b1; // enabled except when explicitly disabled
    tx_reg_init1    <= 1'b0;
    tx_reg_init2    <= 1'b0;
    tx_reg_init3    <= 1'b0;
    tx_reg_init4    <= 1'b0;
    i2c_start       <= 1'b0;
    i2c_stop        <= 1'b0;
    i2c_write       <= 1'b0;
    i2c_read        <= 1'b0;
    i2c_wr_done     <= 1'b0;
    init_pause_cntr <= 1'b0;
    dec_pause_cntr  <= 1'b0;
    error           <= 1'b0;
    
    // next states
    if (NS[IDLE]) begin
        // disable the core when idle
        core_en <= 1'b0;
    end
    
    if (NS[ENABLE]) begin
    end

    if (NS[WAIT1]) begin
    end

    if (NS[DEV_INIT1]) begin
        // set the transmit register to the device address and RD/WR=0
        tx_reg_init1 <= 1'b1;
    end

    if (NS[DEV_INIT2]) begin
        // set the byte controller's STA and WR bits
        i2c_start <= 1'b1;
        i2c_write <= 1'b1;
    end

    if (NS[DEV_INIT3]) begin
    end

    if (NS[DEV_INIT4]) begin
        init_pause_cntr <= 1'b1;
    end

    if (NS[PAUSE1]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[ADR1_INIT1]) begin
        // set the transmit register to the EEPROM address
        tx_reg_init2 <= 1'b1;
    end

    if (NS[ADR1_INIT2]) begin
        // set the byte controller's WR bit
        i2c_write <= 1'b1;
    end

    if (NS[ADR1_INIT3]) begin
    end

    if (NS[ADR1_INIT4]) begin
        init_pause_cntr <= 1'b1;
    end

    if (NS[PAUSE2]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[ADR2_INIT1]) begin
        // set the transmit register to the EEPROM address
        tx_reg_init3 <= 1'b1;
    end

    if (NS[ADR2_INIT2]) begin
        // set the byte controller's WR bit
        i2c_write <= 1'b1;
    end

    if (NS[ADR2_INIT3]) begin
    end

    if (NS[ADR2_INIT4]) begin
        init_pause_cntr <= 1'b1;
    end

    if (NS[PAUSE3]) begin
        dec_pause_cntr <= 1'b1;
    end

    if (NS[DAT_INIT1]) begin
        // set the transmit register to the data register
        tx_reg_init4 <= 1'b1;
    end

    if (NS[DAT_INIT2]) begin
        // set the byte controller's WR bit
        i2c_write <= 1'b1;
    end

    if (NS[DAT_INIT3]) begin
        // set STO bit
        i2c_stop <= 1'b1;
    end

    if (NS[DAT_INIT4]) begin
        init_pause_cntr <= 1'b1;
    end

    if (NS[ERROR]) begin
        error <= 1'b1;
    end

    if (NS[DONE]) begin
        i2c_wr_done <= 1'b1;
    end
end

endmodule
