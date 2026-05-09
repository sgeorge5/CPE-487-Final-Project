LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity io_top is
    port(
        CLK_IN              : in std_logic;

        UART_IN             : in std_logic;

        CLR_SCREEN          : in std_logic;
        RED_OUT             : out std_logic_vector(2 downto 0);
        GREEN_OUT           : out std_logic_vector(2 downto 0);
        BLUE_OUT            : out std_logic_vector(1 downto 0);
        H_SYNC              : out std_logic;
        V_SYNC              : out std_logic;

        RST_6821            : in std_logic;
        CS_6821             : in std_logic;
        RS_6821             : in std_logic_vector(1 downto 0);
        DATA_IN_6821        : in std_logic_vector(7 downto 0);
        DATA_OUT_6821       : out std_logic_vector(7 downto 0);
        RW_6821             : in std_logic
    );
end entity;

architecture behavioral of io_top is
    signal S_ascii_out : std_logic_vector(7 downto 0);
    signal S_strobe : std_logic;
    signal S_char_code : std_logic_vector(6 downto 0);
    signal S_data_available : std_logic;
    signal S_ready_data_accept : std_logic;
    signal S_ca1_in : std_logic;
    signal S_cb1_in : std_logic;
    signal S_cb2_out : std_logic;
    signal S_cb2_oe : std_logic;
    signal S_pa_in : std_logic_vector(7 downto 0);
    signal S_pb_in : std_logic_vector(7 downto 0);
    signal S_pb_out : std_logic_vector(7 downto 0);
    signal S_pb_oe : std_logic_vector(7 downto 0);
    
    --signal clk_in : std_logic;
begin
    --clock : process
    --begin
    --    clk_in <= '1';
    --    wait for 5ns;
    --    clk_in <= '0';
    --    wait for 5ns;
    --end process;

    uart1 : entity work.uart(behavioral)
        port map (
            CLK_IN => CLK_IN,
            UART_IN => UART_IN,
            ASCII_OUT => S_ascii_out,
            STROBE => S_strobe
        );

    dsp1 : entity work.display_top(rtl)
        port map (
            CLK_IN              => CLK_IN,
            CLR_SCREEN          => CLR_SCREEN,
            RED_OUT             => RED_OUT,
            GREEN_OUT           => GREEN_OUT, 
            BLUE_OUT            => BLUE_OUT,
            H_SYNC              => H_SYNC,
            V_SYNC              => V_SYNC,
            CHAR_CODE           => S_char_code,
            DATA_AVAILABLE      => S_data_available,
            READY_DATA_ACCEPT   => S_ready_data_accept
        );

    iocore1 : entity work.io(behavioral)
        port map (
            clk => CLK_IN,
            rst => RST_6821,
            cs => CS_6821,

            rs => RS_6821,

            data_in => DATA_IN_6821,
            data_out => DATA_OUT_6821,

            ca1_in => S_ca1_in,
            ca2_in => '0',
            ca2_out => open,
            ca2_oe => open,

            cb1_in => S_cb1_in,
            cb2_in => '0',
            cb2_out => S_cb2_out,
            cb2_oe => S_cb2_oe,

            pa_in => S_pa_in,
            pa_out => open,
            pa_oe => open,

            pb_in => S_pb_in,
            pb_out => S_pb_out,
            pb_oe => S_pb_oe,

            rw => RW_6821,

            irqa => open,
            irqb => open
        );

    S_data_available <= not (S_cb2_out and S_cb2_oe);
    S_ca1_in <= S_strobe;
    S_cb1_in <= S_ready_data_accept;
    S_pa_in <= '1' & S_ascii_out(6 downto 0);
    S_pb_in <= S_data_available & "0000000";
    S_char_code <= S_pb_out(6 downto 0) and S_pb_oe(6 downto 0);

end architecture;