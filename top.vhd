library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apple1_top is
    port (
        CLK100MHZ : in  std_logic;
        RESET_BTN : in  std_logic;
        LED       : out std_logic_vector(15 downto 0);

        VGA_R     : out std_logic_vector(3 downto 0);
        VGA_G     : out std_logic_vector(3 downto 0);
        VGA_B     : out std_logic_vector(3 downto 0);
        VGA_HS    : out std_logic;
        VGA_VS    : out std_logic;

        UART_RX   : in  std_logic;
        UART_TX   : out std_logic
    );
end entity;

architecture rtl of apple1_top is

    --------------------------------------------------------------------
    -- Clocking / reset
    --------------------------------------------------------------------
    signal cpu_clk      : std_logic := '0';               -- ~1 MHz CPU clock (derived)
    signal cpu_reset    : std_logic := '0';

    -- We'll just use CLK100MHZ directly as the pixel clock
    signal clk_pix_buf  : std_logic := '0';

    --------------------------------------------------------------------
    -- CPU bus
    --------------------------------------------------------------------
    signal cpu_addr     : std_logic_vector(15 downto 0);
    signal cpu_din      : std_logic_vector(7 downto 0);
    signal cpu_dout     : std_logic_vector(7 downto 0);
    signal cpu_we       : std_logic;
    signal mx_rw        : std_logic;

    --------------------------------------------------------------------
    -- Memory + UART + video
    --------------------------------------------------------------------
    signal ram_data_out  : std_logic_vector(7 downto 0);
    signal ram_ce        : std_logic;

    signal rom_data_out  : std_logic_vector(7 downto 0);
    signal rom_ce        : std_logic;

    signal vram_cpu_din  : std_logic_vector(7 downto 0);

    -- UART / PIA signals
    signal uart_tx_start : std_logic := '0';
    signal uart_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_busy  : std_logic := '0';
    signal uart_rx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_rx_ready : std_logic := '0';
    signal uart_data_out : std_logic_vector(7 downto 0) := (others => '0');

    -- debug
    signal last_tx_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_write_count : unsigned(15 downto 0) := (others => '0');
    signal pix_div : unsigned(1 downto 0) := (others => '0');
    signal clk_pix : std_logic := '0';


    --------------------------------------------------------------------
    -- COMPONENTS
    --------------------------------------------------------------------
    component mx65 is
        port (
            clock    : in  std_logic;
            reset    : in  std_logic;
            ce       : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            address  : out std_logic_vector(15 downto 0);
            rw       : out std_logic;
            sync     : out std_logic;
            nmi      : in  std_logic;
            irq      : in  std_logic
        );
    end component;

    component memory is
        port (
            clk      : in  std_logic;
            addr     : in  std_logic_vector(15 downto 0);
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            ce       : in  std_logic;
            we       : in  std_logic
        );
    end component;

    component rom is
        port (
            clock    : in  std_logic;
            address  : in  std_logic_vector(7 downto 0);
            ce       : in  std_logic;
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    component video_top is
        port (
            clk_cpu  : in  std_logic;
            clk_pix  : in  std_logic;
            reset    : in  std_logic;

            cpu_addr : in  std_logic_vector(15 downto 0);
            cpu_dout : in  std_logic_vector(7 downto 0);
            cpu_din  : out std_logic_vector(7 downto 0);
            cpu_we   : in  std_logic;

            vga_hs   : out std_logic;
            vga_vs   : out std_logic;
            vga_r    : out std_logic_vector(3 downto 0);
            vga_g    : out std_logic_vector(3 downto 0);
            vga_b    : out std_logic_vector(3 downto 0)
        );
    end component;

    component uart is
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;

            tx_start  : in  std_logic;
            tx_data   : in  std_logic_vector(7 downto 0);
            tx_busy   : out std_logic;

            rx_data   : out std_logic_vector(7 downto 0);
            rx_ready  : out std_logic;

            rx        : in  std_logic;
            tx        : out std_logic
        );
    end component;

    component pia_wrapper is
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;

            cpu_addr  : in  std_logic_vector(15 downto 0);
            cpu_din   : out std_logic_vector(7 downto 0);
            cpu_dout  : in  std_logic_vector(7 downto 0);
            cpu_we    : in  std_logic;

            uart_rx_data  : in  std_logic_vector(7 downto 0);
            uart_rx_ready : in  std_logic;
            uart_tx_busy  : in  std_logic;
            uart_tx_start : out std_logic;
            uart_tx_data  : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    --------------------------------------------------------------------
    -- RESET
    --------------------------------------------------------------------
    cpu_reset <= not RESET_BTN;

    --------------------------------------------------------------------
    -- Pixel clock (no MMCM/BUFG: just pass through 100 MHz)
    --------------------------------------------------------------------
    clk_pix_buf <= clk_pix;


    --------------------------------------------------------------------
    -- CPU CLOCK (100 MHz → ~1 MHz)
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
    
    -- Generate 25 MHz pixel clock from 100 MHz input
process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        pix_div <= pix_div + 1;
        clk_pix <= pix_div(1);  -- divide-by-4 output
    end if;
end process;


    --------------------------------------------------------------------
    -- Debug capture: latch last byte written to D012 and count writes
    --------------------------------------------------------------------
    process(cpu_clk)
    begin
        if rising_edge(cpu_clk) then
            if cpu_we = '1' and cpu_addr = x"D012" then
                last_tx_byte <= cpu_dout;
                tx_write_count <= tx_write_count + 1;
            end if;
        end if;
    end process;

    cpu_we <= not mx_rw;

    --------------------------------------------------------------------
    -- CPU core
    --------------------------------------------------------------------
    cpu_core : mx65
        port map (
            clock    => cpu_clk,
            reset    => cpu_reset,
            ce       => '1',
            data_in  => cpu_din,
            data_out => cpu_dout,
            address  => cpu_addr,
            rw       => mx_rw,
            sync     => open,
            nmi      => '1',
            irq      => '1'
        );

    --------------------------------------------------------------------
    -- RAM (0000-0FFF)
    --------------------------------------------------------------------
    ram_ce <= '1' when cpu_addr(15 downto 12) = x"0" else '0';

    ram_inst : memory
        port map (
            clk      => cpu_clk,
            addr     => cpu_addr,
            data_in  => cpu_dout,
            data_out => ram_data_out,
            ce       => ram_ce,
            we       => cpu_we
        );

    --------------------------------------------------------------------
    -- ROM (FF00-FFFF)
    --------------------------------------------------------------------
    rom_ce <= '1' when cpu_addr(15 downto 8) = x"FF" else '0';

    rom_inst : rom
        port map (
            clock    => cpu_clk,
            address  => cpu_addr(7 downto 0),
            ce       => rom_ce,
            data_out => rom_data_out
        );

    --------------------------------------------------------------------
    -- CPU DATA BUS MUX
    --------------------------------------------------------------------
    cpu_din <=
        ram_data_out  when ram_ce = '1' else
        rom_data_out  when rom_ce = '1' else
        vram_cpu_din  when cpu_addr(15 downto 10) = "000001" else
        uart_data_out when cpu_addr(15 downto 8) = x"D0" else
        (others => '0');

    --------------------------------------------------------------------
    -- VIDEO TOP (pixel clock = clk_pix_buf)
    --------------------------------------------------------------------
    video : video_top
        port map (
            clk_cpu  => cpu_clk,
            clk_pix  => clk_pix_buf,
            reset    => cpu_reset,

            cpu_addr => cpu_addr,
            cpu_dout => cpu_dout,
            cpu_din  => vram_cpu_din,
            cpu_we   => cpu_we,

            vga_hs   => VGA_HS,
            vga_vs   => VGA_VS,
            vga_r    => VGA_R,
            vga_g    => VGA_G,
            vga_b    => VGA_B
        );

    --------------------------------------------------------------------
    -- UART instance
    --------------------------------------------------------------------
    uart_inst : uart
        port map (
            clk       => CLK100MHZ,
            reset     => cpu_reset,

            tx_start  => uart_tx_start,
            tx_data   => uart_tx_data,
            tx_busy   => uart_tx_busy,

            rx_data   => uart_rx_data,
            rx_ready  => uart_rx_ready,

            rx        => UART_RX,
            tx        => UART_TX
        );

    --------------------------------------------------------------------
    -- PIA wrapper instance (Apple-1 PIA semantics)
    --------------------------------------------------------------------
    pia_inst : pia_wrapper
        port map (
            clk       => cpu_clk,
            reset     => cpu_reset,

            cpu_addr  => cpu_addr,
            cpu_din   => uart_data_out,
            cpu_dout  => cpu_dout,
            cpu_we    => cpu_we,

            uart_rx_data  => uart_rx_data,
            uart_rx_ready => uart_rx_ready,
            uart_tx_busy  => uart_tx_busy,
            uart_tx_start => uart_tx_start,
            uart_tx_data  => uart_tx_data
        );

    --------------------------------------------------------------------
    -- DEBUG LEDs
    --------------------------------------------------------------------
    LED(7 downto 0)   <= last_tx_byte;
    LED(15 downto 8)  <= std_logic_vector(tx_write_count(7 downto 0));

end architecture;
