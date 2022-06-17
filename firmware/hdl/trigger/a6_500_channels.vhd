library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity a6_500_channels is 
generic (nbr_500M_channels : positive := 7);
port (
    -- ttc clocks and sequence counting reset
    ttc_clk       : in  std_logic; -- 40 MHz
    reset         : in  std_logic;
    clock_locks   : out std_logic_vector(2 downto 0);

    -- A6 and supercycle start inputs
    a6               : in  std_logic; -- from aux_lemo_a_internal
    begin_of_cycle   : in  std_logic; -- from aux_lemo_b_internal
    penultimate_seq  : in  std_logic;

    -- pulse parameters
    pulse_delays     : in array_7_8_4_4x7bit;
    pulse_widths     : in array_7_8_2_4x5bit;
    enabled          : in array_7_8x4bit;

    -- trigger out
    trigger_out      : out std_logic_vector(nbr_500M_channels-1 downto  0)
);
end a6_500_channels;

architecture behavioral of a6_500_channels is

    -- derived clocks
    signal ttc_clk_x12p5_0   : std_logic_vector(1 downto 0);
    signal ttc_clk_x12p5_180 : std_logic_vector(1 downto 0);
    signal ttc_clk_x5        : std_logic;

    -- derived clocks locked
    signal ttc_clk_locks      : std_logic_vector(2 downto 0);

    -- accelerator logic
   signal acc_trigger_0       : std_logic_vector(1 downto 0);
   signal acc_trigger_180     : std_logic_vector(1 downto 0);
   signal acc_cycle_start_0   : std_logic_vector(1 downto 0);
   signal acc_cycle_start_180 : std_logic_vector(1 downto 0);

   signal trigger_fanout_0    : std_logic_vector(nbr_500M_channels-1 downto 0);
   signal trigger_fanout_180    : std_logic_vector(nbr_500M_channels-1 downto 0);

   -- sequence counting in a cycle
   signal seq_index_0   : array_7x4bit;
   signal seq_index_180 : array_7x4bit;

   -- outputs
   signal triggers : std_logic_vector(nbr_500M_channels-1 downto 0);

begin

    -- ------
    -- clocks
    -- ------

    -- for width
    clk_200M: entity work.clk_wiz_trig_200M
    port map (
        clk_in1  => ttc_clk,
        clk_out1 => ttc_clk_x5,
        locked   => ttc_clk_locks(2)
    );

    clock_array: for iclock in 0 to 1 generate
    begin
        -- for delay
        clk_500M: entity work.clk_wiz_trig_500M
        port map (
            clk_in1  => ttc_clk,
            clk_out1 => ttc_clk_x12p5_0(iclock),
            clk_out2 => ttc_clk_x12p5_180(iclock),
            locked   => ttc_clk_locks(iclock)
        );

        -- trigger level-to-pulse conversions
        trx_conv0: entity work.level_to_pulse port map (clk => ttc_clk_x12p5_0(iclock),   sig_i => a6,             sig_o => acc_trigger_0(iclock)   );
        trx_conv1: entity work.level_to_pulse port map (clk => ttc_clk_x12p5_180(iclock), sig_i => a6,             sig_o => acc_trigger_180(iclock) );

         -- begin of supercycle level-to-pulse conversions
        boc_conv0: entity work.level_to_pulse port map (clk => ttc_clk_x12p5_0(iclock),   sig_i => begin_of_cycle, sig_o => acc_cycle_start_0(iclock)   );
        boc_conv1: entity work.level_to_pulse port map (clk => ttc_clk_x12p5_180(iclock), sig_i => begin_of_cycle, sig_o => acc_cycle_start_180(iclock) );

        -- sequence counter for the two phases of clocks
        seq_counter_0: entity work.counter_sm
        generic map (n => 4)
        port map (
            clk               => ttc_clk_x12p5_0(iclock),
            reset             => reset,
            trigger_in        => acc_trigger_0(iclock),
            cycle_start       => acc_cycle_start_0(iclock),
            penultimate_seq   => penultimate_seq,
            seq_index         => seq_index_0(iclock)
        );

        -- ------------------------------------
        seq_counter_180: entity work.counter_sm
        generic map (n => 4)
        port map (
            clk               => ttc_clk_x12p5_180(iclock),
            reset             => reset,
            trigger_in        => acc_trigger_180(iclock),
            cycle_start       => acc_cycle_start_180(iclock),
            penultimate_seq   => penultimate_seq,
            seq_index         => seq_index_180(iclock)
        );
    end generate;

    trigger_fanout_0(3 downto 0)   <= (others => acc_trigger_0(0));
    trigger_fanout_0(6 downto 4)   <= (others => acc_trigger_0(1));
    trigger_fanout_180(3 downto 0) <= (others => acc_trigger_180(0));
    trigger_fanout_180(6 downto 4) <= (others => acc_trigger_180(1));

    -- high speed channels counting channels
    channel_array_c0: for i in 0 to 3 generate
    begin

        -- --------------------------------------
        channel_inst: entity work.trigger_channel
        port map (
            clk_0                  => ttc_clk_x12p5_0(0),
            clk_180                => ttc_clk_x12p5_180(0),
            clk_slower             => ttc_clk_x5,
            seq_index_0            => seq_index_0(0)(2 downto 0),
            seq_index_180          => seq_index_180(0)(2 downto 0),
            trigger_0              => acc_trigger_0(0),
            trigger_180            => acc_trigger_180(0),
            pulse_delay_parameters => pulse_delays(i),
            pulse_width_parameters => pulse_widths(i),
            pulse_enabled          => enabled(i),
            trigger_out            => triggers(i)
        );
    end generate;

    -- high speed channels counting channels
    channel_array_c1: for i in 4 to nbr_500M_channels-1 generate
    begin

        -- --------------------------------------
        channel_inst: entity work.trigger_channel
        port map (
            clk_0                  => ttc_clk_x12p5_0(1),
            clk_180                => ttc_clk_x12p5_180(1),
            clk_slower             => ttc_clk_x5,
            seq_index_0            => seq_index_0(1)(2 downto 0),
            seq_index_180          => seq_index_180(1)(2 downto 0),
            trigger_0              => acc_trigger_0(1),
            trigger_180            => acc_trigger_180(1),
            pulse_delay_parameters => pulse_delays(i),
            pulse_width_parameters => pulse_widths(i),
            pulse_enabled          => enabled(i),
            trigger_out            => triggers(i)
        );
    end generate;

--    clocks_locked <= '1';

--    triggers <= (others => '0');
    clock_locks <= ttc_clk_locks;
    trigger_out <= triggers;

end architecture behavioral;
