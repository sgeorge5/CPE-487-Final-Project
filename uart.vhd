library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    port (
        clk       : in  std_logic;                     -- 100 MHz
        reset     : in  std_logic;

        -- TX interface
        tx_start  : in  std_logic;                     -- pulse to start TX
        tx_data   : in  std_logic_vector(7 downto 0);
        tx_busy   : out std_logic;

        -- RX interface
        rx_data   : out std_logic_vector(7 downto 0);
        rx_ready  : out std_logic;

        -- UART pins
        rx        : in  std_logic;
        tx        : out std_logic
    );
end entity;

architecture rtl of uart is

    constant CLK_FREQ  : integer := 100_000_000;
    constant BAUD_RATE : integer := 115200;
    constant BAUD_DIV  : integer := CLK_FREQ / BAUD_RATE - 1;

    signal baud_cnt  : integer := 0;
    signal baud_tick : std_logic := '0';

    -- RX
    signal rx_shift  : std_logic_vector(9 downto 0) := (others => '1');
    signal rx_busy_i : std_logic := '0';
    signal rx_bit    : integer range 0 to 9 := 0;
    signal rx_data_i : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ready_i: std_logic := '0';

    -- TX
    signal tx_shift  : std_logic_vector(9 downto 0) := (others => '1');
    signal tx_busy_i : std_logic := '0';
    signal tx_bit    : integer range 0 to 9 := 0;

begin

    tx_busy  <= tx_busy_i;
    rx_data  <= rx_data_i;
    rx_ready <= rx_ready_i;

    --------------------------------------------------------------------
    -- Baud generator
    --------------------------------------------------------------------
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

    --------------------------------------------------------------------
    -- RX
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_busy_i  <= '0';
                rx_ready_i <= '0';
                rx_bit     <= 0;
            elsif baud_tick = '1' then
                rx_ready_i <= '0';

                if rx_busy_i = '0' then
                    if rx = '0' then
                        rx_busy_i <= '1';
                        rx_bit    <= 0;
                    end if;
                else
                    rx_shift(rx_bit) <= rx;
                    if rx_bit = 9 then
                        rx_busy_i  <= '0';
                        rx_ready_i <= '1';
                        rx_data_i  <= rx_shift(8 downto 1);
                    else
                        rx_bit <= rx_bit + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- TX
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tx_busy_i <= '0';
                tx        <= '1';
            elsif baud_tick = '1' then
                if tx_busy_i = '0' then
                    if tx_start = '1' then
                        tx_shift(0) <= '0';
                        tx_shift(1) <= tx_data(0);
                        tx_shift(2) <= tx_data(1);
                        tx_shift(3) <= tx_data(2);
                        tx_shift(4) <= tx_data(3);
                        tx_shift(5) <= tx_data(4);
                        tx_shift(6) <= tx_data(5);
                        tx_shift(7) <= tx_data(6);
                        tx_shift(8) <= tx_data(7);
                        tx_shift(9) <= '1';
                        tx_busy_i   <= '1';
                        tx_bit      <= 0;
                    end if;
                else
                    tx <= tx_shift(tx_bit);
                    if tx_bit = 9 then
                        tx_busy_i <= '0';
                        tx        <= '1';
                    else
                        tx_bit <= tx_bit + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;
