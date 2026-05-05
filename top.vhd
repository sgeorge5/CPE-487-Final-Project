--so basically replace Shaun's top.vhd with this:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    port (
        clk       : in  std_logic;                     -- system clock (100 MHz)
        reset     : in  std_logic;
        -- CPU interface
        cpu_addr  : in  std_logic_vector(15 downto 0);
        cpu_din   : out std_logic_vector(7 downto 0);
        cpu_dout  : in  std_logic_vector(7 downto 0);
        cpu_we    : in  std_logic;
        -- UART pins (to Nexys A7 USB-UART)
        rx        : in  std_logic;
        tx        : out std_logic;
        -- New: output to PIA
        char_out  : out std_logic_vector(7 downto 0);
        ready_out : out std_logic
    );
end entity;

architecture rtl of uart is

    constant CLK_FREQ  : integer := 100_000_000;  -- 100 MHz
    constant BAUD_RATE : integer := 115200;
    constant BAUD_DIV  : integer := CLK_FREQ / BAUD_RATE;

    signal baud_cnt : integer range 0 to BAUD_DIV := 0;
    signal baud_tick : std_logic := '0';

    -- RX signals
    signal rx_shift : std_logic_vector(9 downto 0) := (others => '1');
    signal rx_busy  : std_logic := '0';
    signal rx_bit   : integer range 0 to 9 := 0;
    signal rx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ready : std_logic := '0';

    -- TX signals
    signal tx_shift : std_logic_vector(9 downto 0) := (others => '1');
    signal tx_busy  : std_logic := '0';
    signal tx_bit   : integer range 0 to 9 := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if baud_cnt = BAUD_DIV then
                baud_cnt  <= 0;
                baud_tick <= '1';
            else
                baud_cnt  <= baud_cnt + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_busy  <= '0';
                rx_ready <= '0';
            elsif baud_tick = '1' then
                if rx_busy = '0' then
                    if rx = '0' then  -- start bit
                        rx_busy <= '1';
                        rx_bit  <= 0;
                    end if;
                else
                    rx_shift(rx_bit) <= rx;
                    if rx_bit = 9 then
                        rx_busy  <= '0';
                        rx_ready <= '1';
                        rx_data  <= rx_shift(8 downto 1); -- data bits
                    else
                        rx_bit <= rx_bit + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tx_busy <= '0';
                tx      <= '1';
            elsif baud_tick = '1' then
                if tx_busy = '0' then
                    if cpu_we = '1' and cpu_addr = x"D011" then
                        tx_shift <= '1' & cpu_dout & '0';
                        tx_busy  <= '1';
                        tx_bit   <= 0;
                    end if;
                else
                    tx <= tx_shift(tx_bit);
                    if tx_bit = 9 then
                        tx_busy <= '0';
                        tx      <= '1';
                    else
                        tx_bit <= tx_bit + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- CPU direct read (legacy, but we keep for compatibility)
    cpu_din <= rx_data when cpu_addr = x"D010" else
               (7 downto 1 => '0') & rx_ready when cpu_addr = x"D011" else
               (others => '0');
    
    -- Output to PIA
    char_out  <= rx_data;
    ready_out <= rx_ready;

end architecture;
