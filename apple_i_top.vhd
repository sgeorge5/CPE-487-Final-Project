library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity applei_top is
    port (
        CLK_IN      : in std_logic;
        RESET       : in std_logic;

        UART_IN     : in std_logic;             

        CLR_SCREEN  : in std_logic;
        RED_OUT     : out std_logic_vector(2 downto 0);
        GREEN_OUT   : out std_logic_vector(2 downto 0);
        BLUE_OUT    : out std_logic_vector(1 downto 0);
        H_SYNC      : out std_logic;
        V_SYNC      : out std_logic
    );
end entity;

architecture rtl of applei_top is
    signal S_univ_data_bus : std_logic_vector(7 downto 0);
    signal S_univ_addr_bus : std_logic_vector(15 downto 0);
    signal S_univ_we : std_logic;
    
    signal S_mx65_data_out : std_logic_vector(7 downto 0);
    signal S_mx65_rw : std_logic;
    
    signal S_rom_addr : std_logic_vector(7 downto 0);
    signal S_rom_ce : std_logic;
    signal S_rom_data_out : std_logic_vector(7 downto 0);
    
    signal S_ram_addr : std_logic_vector(15 downto 0);
    signal S_ram_data_in : std_logic_vector(7 downto 0);
    signal S_ram_data_out : std_logic_vector(7 downto 0);
    signal S_ram_ce : std_logic;
    signal S_ram_we : std_logic;
    
    signal S_6821_rst_n : std_logic;
    signal S_6821_cs : std_logic;
    signal S_6821_rs : std_logic_vector(1 downto 0);
    signal S_6821_data_out : std_logic_vector(7 downto 0);
    signal S_6821_rw : std_logic;
    
    --signal clk_in : std_logic;
begin
    --clock : process
    --begin
    --    clk_in <= '1';
    --    wait for 5ns;
    --    clk_in <= '0';
    --    wait for 5ns;
    --end process;

    S_rom_ce <= '1' when S_univ_addr_bus(15 downto 8) = x"FF" else '0';
    S_ram_ce <= '1' when S_univ_addr_bus(15 downto 12) = x"0" else '0';
    S_6821_cs <= '1' when   S_univ_addr_bus = X"D010" or
                            S_univ_addr_bus = X"D011" or
                            S_univ_addr_bus = X"D012" or
                            S_univ_addr_bus = X"D013";
    
    S_univ_we <= not S_mx65_rw;

    with S_univ_addr_bus select 
        S_6821_rs <=    "00" when x"D010",
                        "01" when x"D011",
                        "10" when x"D012",
                        "11" when x"D013",
                        "00" when others;

    S_univ_data_bus <=  S_mx65_data_out when S_mx65_rw = '0' else
                        S_rom_data_out when S_rom_ce = '1' else
                        S_ram_data_out when S_ram_ce = '1' else
                        S_6821_data_out when S_6821_cs = '1' else
                        "00000000"; 
                        
    cpu1 : entity work.mx65(rtl)
        port map (
           clock	=> CLK_IN,
	       reset	=> RESET,
	       ce		=> '1',
	       data_in	=> S_univ_data_bus,
	       data_out => S_mx65_data_out,
	       address	=> S_univ_addr_bus,
	       rw		=> S_mx65_rw,
	       sync	    => open,
	       nmi		=> '1',
	       irq		=> '1'
        );
        
    rom1 : entity work.rom(rtl)
        port map (
            clock     => CLK_IN,
            address   => S_univ_addr_bus(7 downto 0),
            ce        => S_rom_ce,
            data_out  => S_rom_data_out
        );
        
    ram1 : entity work.memory(rtl)
        port map (
            clk      => CLK_IN,
            addr     => S_univ_addr_bus,
            data_in  => S_univ_data_bus,
            data_out => S_ram_data_out,
            ce       => S_ram_ce,
            we       => S_univ_we
        );

    io1 : entity work.io_top(behavioral)
        port map (
            CLK_IN              => CLK_IN,

            UART_IN             => UART_IN,

            CLR_SCREEN          => CLR_SCREEN,
            RED_OUT             => RED_OUT,
            GREEN_OUT           => GREEN_OUT,
            BLUE_OUT            => BLUE_OUT,
            H_SYNC              => H_SYNC,
            V_SYNC              => V_SYNC,

            RST_6821            => S_6821_rst_n,
            CS_6821             => S_6821_cs,
            RS_6821             => S_6821_rs,
            DATA_IN_6821        => S_univ_data_bus,
            DATA_OUT_6821       => S_6821_data_out,
            RW_6821             => S_6821_rw
        );

    S_6821_rst_n <= not RESET;
    S_6821_rw <= S_mx65_rw;

end architecture;