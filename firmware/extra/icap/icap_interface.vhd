library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-- system packages
use work.icap_package.all;

entity icap_interface is
port (
    -- control
    reset_i : in  std_logic;
    clk_i   : in  std_logic;
    -- logic fabric
    cs_i    : in  std_logic;
    write_i : in  std_logic;
    data_i  : in  std_logic_vector(31 downto 0);
    data_o  : out std_logic_vector(31 downto 0);
    ack_o   : out std_logic
);
end icap_interface;

architecture structural of icap_interface is

    signal data_i_ord         : std_logic_vector(31 downto 0);
    signal cs_b_from_fsm      : std_logic;
    signal write_b_from_fsm   : std_logic;
    signal data_from_icap     : std_logic_vector(31 downto 0);
    signal data_from_icap_ord : std_logic_vector(31 downto 0);

    attribute keep : string;
    attribute keep of data_i_ord : signal is "true";

begin

    -- combinatorial logic
    selectmapdataordering_generate: for i in 0 to 7 generate
        -- input
        data_i_ord( 7 - i) <= data_i(     i);
        data_i_ord(15 - i) <= data_i( 8 + i);
        data_i_ord(23 - i) <= data_i(16 + i);
        data_i_ord(31 - i) <= data_i(24 + i);

        -- output
        data_from_icap_ord( 7 - i) <= data_from_icap(     i);
        data_from_icap_ord(15 - i) <= data_from_icap( 8 + i);
        data_from_icap_ord(23 - i) <= data_from_icap(16 + i);
        data_from_icap_ord(31 - i) <= data_from_icap(24 + i);
    end generate;

    -- secuential logic
    main_process: process(reset_i, clk_i)
        variable startwrite         : boolean;
        variable startread          : boolean;
        variable counter            : natural range 0 to ipbusdelay - 1;
        variable c_state            : c_statet;
        variable w_state            : w_statet;
        variable r_state            : r_statet;
        variable writedone_from_fsm : std_logic;
        variable readdone_from_fsm  : std_logic;
        variable read_delay         : integer range 0 to 7;
        variable icap_data_out      : std_logic_vector(31 downto 0);
    begin
        if reset_i = '1' then
            startwrite         := false;
            startread          := false;
            counter            := 0;
            c_state            := c_s0;
            w_state            := w_s0;
            r_state            := r_s0;
            writedone_from_fsm := '0';
            readdone_from_fsm  := '0';
            cs_b_from_fsm      <= '1';
            write_b_from_fsm   <= '1';
            ack_o              <= '0';
            data_o             <= (others => '0');

        elsif rising_edge(clk_i) then
            -- control FSM
            case c_state is
                when c_s0 =>
                    if cs_i = '1' then
                        if write_i = '1' then
                            startwrite := true;
                        else
                            startread := true;
                        end if;
                        c_state := c_s1;
                    end if;
                when c_s1 =>
                    if writedone_from_fsm = '1' or readdone_from_fsm = '1' then
                        c_state := c_s0;
                    end if;
            end case;

            -- write FSM
            case w_state is
                when w_s0 =>
                    writedone_from_fsm := '0';
                    if startwrite = true then
                        w_state          := w_s1;
                        write_b_from_fsm <= '0';
                    end if;
                when w_s1 =>
                    w_state       := w_s2;
                    cs_b_from_fsm <= '0';
                when w_s2 =>
                    w_state       := w_s3;
                    cs_b_from_fsm <= '1';
                when w_s3 =>
                    w_state          := w_s4;
                    write_b_from_fsm <= '1';         
                when w_s4 =>
                    w_state := w_s5;
                    ack_o   <= '1';
                when w_s5 =>
                    ack_o <= '0';
                    if counter = ipbusdelay - 1 then
                        w_state            := w_s0;
                        counter            := 0;
                        startwrite         := false;
                        writedone_from_fsm := '1'; 
                    else
                        counter := counter + 1;
                    end if;
            end case;

            -- read FSM
            case r_state is
                when r_s0 =>
                    readdone_from_fsm := '0';
                    if startread = true then
                        r_state       := r_s1;
                        cs_b_from_fsm <= '0';
                        read_delay    :=4;
                    end if;
                when r_s1 =>
                    if read_delay = 0 then
                        r_state       := r_s2;
                        cs_b_from_fsm <= '1';
                        data_o        <= icap_data_out;
                    else
                        read_delay := read_delay-1;
                    end if;
                when r_s2 =>
                    r_state := r_s3;
                    ack_o   <= '1';
                when r_s3 =>
                    ack_o <= '0';
                    if counter = ipbusdelay - 1 then 
                        r_state           := r_s0;
                        counter           := 0;
                        startread         := false;
                        readdone_from_fsm := '1';
                    else
                        counter := counter + 1;
                    end if;
            end case;

            icap_data_out := data_from_icap_ord;
        end if;
    end process;

    -- ICAPE2
    icap: icape2
    generic map (
        device_id         => x"0424a093",
        icap_width        => "x32",
        sim_cfg_file_name => "none"
    )
    port map (
        o     => data_from_icap,
        clk   => clk_i,
        csib  => cs_b_from_fsm,
        i     => data_i_ord,
        rdwrb => write_b_from_fsm
    );

end structural;
