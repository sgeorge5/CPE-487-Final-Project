library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Vendor primitives for BUFG and MMCM (Vivado 7-series)
library UNISIM;
use UNISIM.VComponents.all;

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
    signal cpu_clk      : std_logic := '0';               -- 1 MHz CPU clock (derived)
    signal cpu_reset    : std_logic := '0';
    signal clk100_buf   : std_logic;
    signal clk_pix_buf  : std_logic;                      -- generated pixel clock (40 MHz)
    signal mmcm_locked  : std_logic;

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

    --------------------------------------------------------------------
    -- MMCM / BUFG primitives (Vivado 7-series)
    -- Generates 40 MHz pixel clock from 100 MHz input:
    --   CLKIN1 = 100 MHz, CLKFBOUT_MULT_F = 8.0, CLKOUT0_DIVIDE_F = 20.0 => 100*8/20 = 40 MHz
    --------------------------------------------------------------------
    signal clkfb      : std_logic;
    signal clkfb_buf  : std_logic;
    signal clk_pix_mmcm : std_logic;

begin

    --------------------------------------------------------------------
    -- Input clock buffer (BUFG)
    --------------------------------------------------------------------
    clk100_bufg : BUFG
        port map (
            I => CLK100MHZ,
            O => clk100_buf
        );

    --------------------------------------------------------------------
    -- MMCM instance to generate 40 MHz pixel clock
    -- Using MMCME2_BASE primitive from UNISIM. RST tied to cpu_reset.
    -- If your flow prefers the IP wrapper, replace this primitive with the IP core.
    --------------------------------------------------------------------
    mmcm_inst : MMCME2_BASE
        generic map (
            BANDWIDTH => "OPTIMIZED",
            CLKFBOUT_MULT_F => 8.0,
            CLKFBOUT_PHASE => 0.0,
            CLKIN1_PERIOD => 10.0,
            CLKOUT0_DIVIDE_F => 20.0,
            CLKOUT0_PHASE => 0.0,
            DIVCLK_DIVIDE => 1,
            CLKOUT0_DUTY_CYCLE => 0.5
        )
        port map (
            CLKIN1 => clk100_buf,
            CLKFBIN => clkfb_buf,
            CLKFBOUT => clkfb,
            CLKOUT0 => clk_pix_mmcm,
            PWRDWN => '0',
            RST => cpu_reset,          -- MMCM reset tied to cpu_reset
            LOCKED => mmcm_locked,
            -- unused outputs tied off or left open
            CLKOUT1 => open,
            CLKOUT2 => open,
            CLKOUT3 => open,
            CLKOUT4 => open,
            CLKOUT5 => open,
            CLKOUT6 => open,
            CLKIN2 => '0',
            CLKFBSTOPPED => open,
            CLKINSTOPPED => open,
            DO => open,
            DRDY => open,
            DADDR => (others => '0'),
            DCLK => '0',
            DEN => '0',
            DI => (others => '0'),
            DWE => '0'
        );

    -- feedback buffer
    clkfb_bufg : BUFG
        port map (
            I => clkfb,
            O => clkfb_buf
        );

    -- pixel clock buffer
    clkpix_bufg : BUFG
        port map (
            I => clk_pix_mmcm,
            O => clk_pix_buf
        );

    --------------------------------------------------------------------
    -- RESET
    --------------------------------------------------------------------
    cpu_reset <= not RESET_BTN;

    --------------------------------------------------------------------
    -- CPU CLOCK (100 MHz → 1 MHz)
    -- simple divide-by-50 toggle to produce ~1 MHz from 100 MHz
    --------------------------------------------------------------------
    process(clk100_buf)
        variable cnt : integer range 0 to 49 := 0;
    begin
        if rising_edge(clk100_buf) then
            if cnt = 49 then
                cnt := 0;
                cpu_clk <= not cpu_clk;
            else
                cnt := cnt + 1;
            end if;
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
    -- VIDEO TOP (pixel clock from MMCM)
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
            clk       => clk100_buf,
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
    -- DEBUG LEDs (single-driver, non-overlapping)
    --------------------------------------------------------------------
    LED(7 downto 0)   <= last_tx_byte;
    LED(15 downto 8)  <= std_logic_vector(tx_write_count(7 downto 0));

end architecture;
