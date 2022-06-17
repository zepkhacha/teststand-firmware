library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- system packages
use work.system_package.all;

entity trigger_channel_singlePhase is
port (
    clk_0                  : in  std_logic;
    seq_index_0            : in  std_logic_vector(2 downto 0);
    trigger_0              : in  std_logic;
    pulse_delay_parameters : in  array_8_4_4x7bit;
    pulse_width_parameters : in  array_8_2_4x5bit;
    pulse_enabled          : in  array_8x4bit;
    trigger_out            : out std_logic
);
end trigger_channel_singlePhase;

architecture structural of trigger_channel_singlePhase is

    signal pulse_delay_done    : std_logic_vector(7 downto 0);
    signal pulse_delay_sync    : std_logic_vector(7 downto 0);
    signal pulse_out           : std_logic_vector(7 downto 0);
    signal ambiphase_pulse_out : std_logic_vector(7 downto 0);
    signal per_pulse_out       : std_logic_vector(7 downto 0);
    signal per_seq_out         : std_logic_vector(7 downto 0);
    signal error_condition     : std_logic;
    signal pulse_0             : array_16x2bit;
    signal pulse_180           : array_16x2bit;
    signal pulse_sync          : array_16x2bit;

--    -- debugs
--     attribute mark_debug : string;
--     attribute mark_debug of seq_index_0 : signal is "true";
--     attribute mark_debug of per_seq_out : signal is "true";
--     attribute mark_debug of per_pulse_out : signal is "true";


begin

    sequence_array: for i in 0 to 7 generate
    begin
         ----------------------------
        fsm_0: entity work.all_pulse_delay_sm
        port map (
            clk            => clk_0,
            enabled        => pulse_enabled(i),
            trigger_in     => trigger_0,
            trig_delay_i   => pulse_delay_parameters(i)(0),
            trig_delay_m   => pulse_delay_parameters(i)(1),
            trig_delay_m2  => pulse_delay_parameters(i)(2),
            trig_delay_o   => pulse_delay_parameters(i)(3),
            pulse_hold     => "0011",
            trigger_out    => ambiphase_pulse_out(i),
            pulse_out      => pulse_0(i)
        );

--        sync_delay: entity work.level_to_pulse
--        port map (
--            clk   => clk_0,
--            sig_i => ambiphase_pulse_out(i),
--            sig_o => pulse_delay_sync(i)
--        );

        fsm_pulse: entity work.all_pulse_maintain_sm
        port map (
            clk            => clk_0,
            enabled        => pulse_enabled(i)(0),
            trigger_in     => ambiphase_pulse_out(i),
            pulse          => pulse_0(i),
            trig_width_i   => pulse_width_parameters(i)(0),
            trig_width_o   => pulse_width_parameters(i)(1),
            trigger_out    => pulse_out(i)
        );

        -- combine pulses for sequence
        per_seq_out(i) <=  ambiphase_pulse_out(i) or pulse_out(i);
    end generate sequence_array;

    -- route pulses for current sequence
    trigger_out <= per_seq_out(to_integer(unsigned(seq_index_0)));

end architecture structural;
