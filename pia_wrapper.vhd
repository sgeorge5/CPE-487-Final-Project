library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pia_wrapper is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;

        -- CPU bus
        cpu_addr  : in  std_logic_vector(15 downto 0);
        cpu_din   : out std_logic_vector(7 downto 0);
        cpu_dout  : in  std_logic_vector(7 downto 0);
        cpu_we    : in  std_logic;

        -- UART interface
        uart_rx_data  : in  std_logic_vector(7 downto 0);
        uart_rx_ready : in  std_logic;
        uart_tx_busy  : in  std_logic;
        uart_tx_start : out std_logic;
        uart_tx_data  : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of pia_wrapper is

    -- Registered CPU signals (avoid combinational hazards)
    signal cpu_addr_r  : std_logic_vector(15 downto 0) := (others => '0');
    signal cpu_we_r    : std_logic := '1';  -- default idle (reads)
    signal cpu_we_r2   : std_logic := '1';

    -- Latched RX ready (cleared on CPU read of D010)
    signal rx_ready_latched : std_logic := '0';

    -- Internal TX start pulse generator (one cycle on clk)
    signal tx_start_int : std_logic := '0';

    -- Control register (D013) for future expansion
    signal ctrl_reg : std_logic_vector(7 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------
    -- Register CPU address and WE to the local clock domain
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cpu_addr_r <= (others => '0');
                cpu_we_r   <= '1';
                cpu_we_r2  <= '1';
            else
                cpu_addr_r <= cpu_addr;
                cpu_we_r2  <= cpu_we_r;
                cpu_we_r   <= cpu_we;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Latch UART RX ready; clear on CPU read of D010
    -- (rx_ready_latched is set whenever uart_rx_ready pulses)
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_ready_latched <= '0';
            else
                if uart_rx_ready = '1' then
                    rx_ready_latched <= '1';
                end if;

                -- Clear when CPU performs a read of D010
                -- A read is indicated by cpu_we = '0' while address = D010.
                if cpu_we_r = '0' and cpu_addr_r = x"D010" then
                    rx_ready_latched <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- CPU read data (cpu_din)
    -- D010: RX data
    -- D011: status: bit0 = rx_ready, bit1 = tx_ready (1 = ready)
    --------------------------------------------------------------------
    cpu_din <= uart_rx_data when cpu_addr_r = x"D010" else
               (7 downto 2 => '0') &
               (not uart_tx_busy) &
               rx_ready_latched when cpu_addr_r = x"D011" else
               (others => '0');

    --------------------------------------------------------------------
    -- CPU writes handling (generate one-cycle tx_start pulse)
    -- D012: write -> TX data (start transmit if UART not busy)
    -- D013: control register (simple latch)
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tx_start_int <= '0';
                uart_tx_data <= (others => '0');
                ctrl_reg     <= (others => '0');
            else
                -- default: no start
                tx_start_int <= '0';

                -- Detect write condition: cpu_we_r = '1' and address matches
                if cpu_we_r = '1' then
                    if cpu_addr_r = x"D012" then
                        -- Only start if UART not busy
                        if uart_tx_busy = '0' then
                            uart_tx_data <= cpu_dout;
                            tx_start_int <= '1';
                        end if;
                    elsif cpu_addr_r = x"D013" then
                        ctrl_reg <= cpu_dout;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Drive the output start signal (one-cycle pulse)
    uart_tx_start <= tx_start_int;

end architecture;
