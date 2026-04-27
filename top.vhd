library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apple1_top is
    port (
        CLK100MHZ : in  std_logic;
        RESET_BTN : in  std_logic;      -- btnC
        LED       : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of apple1_top is

    signal cpu_clk   : std_logic := '0';
    signal cpu_reset : std_logic;
    signal we_sig : std_logic;
    signal addr      : std_logic_vector(15 downto 0);
    signal data_in   : std_logic_vector(7 downto 0);
    signal data_out  : std_logic_vector(7 downto 0);
    signal rw        : std_logic;

begin

    --------------------------------------------------------------------
    -- Reset (btnC is active LOW on Nexys)
    --------------------------------------------------------------------
    cpu_reset <= not RESET_BTN;
    we_sig <= not rw;


    --------------------------------------------------------------------
    -- Clock divider: 100 MHz → 1 MHz
    --------------------------------------------------------------------
    process(CLK100MHZ)
        variable cnt : integer range 0 to 49 := 0;
    begin
        if rising_edge(CLK100MHZ) then
            if cnt = 49 then
                cnt := 0;
                cpu_clk <= not cpu_clk;
            else
                cnt := cnt + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Instantiate the 6502 CPU
    --------------------------------------------------------------------
    CPU : entity work.mx65
        port map (
            clock    => cpu_clk,
            reset    => cpu_reset,
            ce       => '1',
            data_in  => data_in,
            data_out => data_out,
            address  => addr,
            rw       => rw,
            sync     => open,
            nmi      => '1',
            irq      => '1'
        );

    --------------------------------------------------------------------
    -- Simple 64K RAM/ROM memory
    --------------------------------------------------------------------
    MEM : entity work.memory
        port map (
            clk      => cpu_clk,
            addr     => addr,
            data_in  => data_out,
            data_out => data_in,
            we       => we_sig
        );

    --------------------------------------------------------------------
    -- Debug: show address on LEDs
    --------------------------------------------------------------------
    LED <= addr;

end architecture;
