library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_top is
    port (
        -- clocks / reset
        clk_cpu   : in  std_logic;   -- same clock as 6502
        clk_pix   : in  std_logic;   -- pixel clock for VGA
        reset     : in  std_logic;

        -- CPU side bus
        cpu_addr  : in  std_logic_vector(15 downto 0);
        cpu_dout  : in  std_logic_vector(7 downto 0);  -- from CPU
        cpu_din   : out std_logic_vector(7 downto 0);  -- to CPU
        cpu_we    : in  std_logic;                     -- write enable (active high)

        -- VGA outputs
        vga_hs    : out std_logic;
        vga_vs    : out std_logic;
        vga_r     : out std_logic_vector(3 downto 0);
        vga_g     : out std_logic_vector(3 downto 0);
        vga_b     : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of video_top is

    ----------------------------------------------------------------
    -- Component declarations
    ----------------------------------------------------------------
    component vga_sync is
        port (
            pixel_clk : in  std_logic;
            red_in    : in  std_logic_vector(3 downto 0);
            green_in  : in  std_logic_vector(3 downto 0);
            blue_in   : in  std_logic_vector(3 downto 0);
            red_out   : out std_logic_vector(3 downto 0);
            green_out : out std_logic_vector(3 downto 0);
            blue_out  : out std_logic_vector(3 downto 0);
            hsync     : out std_logic;
            vsync     : out std_logic;
            pixel_row : out std_logic_vector(10 downto 0);
            pixel_col : out std_logic_vector(10 downto 0)
        );
    end component;

    component video_ram is
        port (
            -- CPU port
            clk_cpu      : in  std_logic;
            addr_cpu     : in  std_logic_vector(9 downto 0);
            data_in      : in  std_logic_vector(7 downto 0);
            we           : in  std_logic;
            data_out_cpu : out std_logic_vector(7 downto 0);

            -- VGA port
            clk_vga   : in  std_logic;
            addr_vga  : in  std_logic_vector(9 downto 0);
            char_out  : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Match your actual char_rom entity:
    --   port ( clk, addr, ce, data_out )
    component char_rom is
        port (
            clk      : in  std_logic;
            addr     : in  std_logic_vector(10 downto 0);
            ce       : in  std_logic;
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    component pixel_gen is
        port (
            pixel_clk   : in  std_logic;
            pixel_row   : in  std_logic_vector(10 downto 0);
            pixel_col   : in  std_logic_vector(10 downto 0);

            char_code   : in  std_logic_vector(7 downto 0);
            char_bitmap : in  std_logic_vector(7 downto 0);

            vram_addr   : out std_logic_vector(9 downto 0);

            red         : out std_logic_vector(3 downto 0);
            green       : out std_logic_vector(3 downto 0);
            blue        : out std_logic_vector(3 downto 0)
        );
    end component;

    ----------------------------------------------------------------
    -- Internal signals
    ----------------------------------------------------------------
    signal pixel_row   : std_logic_vector(10 downto 0);
    signal pixel_col   : std_logic_vector(10 downto 0);

    signal rgb_r_in    : std_logic_vector(3 downto 0);
    signal rgb_g_in    : std_logic_vector(3 downto 0);
    signal rgb_b_in    : std_logic_vector(3 downto 0);

    signal rgb_r_out   : std_logic_vector(3 downto 0);
    signal rgb_g_out   : std_logic_vector(3 downto 0);
    signal rgb_b_out   : std_logic_vector(3 downto 0);

    -- video RAM / character ROM
    signal vram_addr_vga : std_logic_vector(9 downto 0);
    signal vram_char     : std_logic_vector(7 downto 0);  -- VGA-side character code
    signal vram_char_cpu : std_logic_vector(7 downto 0);  -- CPU-side read data
    signal char_bitmap   : std_logic_vector(7 downto 0);
    signal char_addr     : std_logic_vector(10 downto 0);

    -- CPU write into video RAM
    signal vram_cs       : std_logic;
    signal vram_we_cpu   : std_logic;

begin

    ----------------------------------------------------------------
    -- Video RAM chip select and write enable
    -- 0x0400..0x07FF -> cpu_addr(15 downto 10) = "000001"
    ----------------------------------------------------------------
    vram_cs     <= '1' when cpu_addr(15 downto 10) = "000001" else '0';
    vram_we_cpu <= cpu_we and vram_cs;

    ----------------------------------------------------------------
    -- CPU read from video RAM (CPU-domain output)
    ----------------------------------------------------------------
    cpu_din <= vram_char_cpu when vram_cs = '1' else (others => '0');

    ----------------------------------------------------------------
    -- Character ROM address (character code + row within character)
    -- row index = pixel_row(2 downto 0) for 8 rows
    ----------------------------------------------------------------
    char_addr <= vram_char & pixel_row(2 downto 0);

    ----------------------------------------------------------------
    -- Dual-port video RAM instantiation (CPU and VGA ports)
    ----------------------------------------------------------------
    vram_inst : video_ram
        port map (
            clk_cpu      => clk_cpu,
            addr_cpu     => cpu_addr(9 downto 0),
            data_in      => cpu_dout,
            we           => vram_we_cpu,
            data_out_cpu => vram_char_cpu,

            clk_vga      => clk_pix,
            addr_vga     => vram_addr_vga,
            char_out     => vram_char
        );

    ----------------------------------------------------------------
    -- Character ROM (provides bitmap for a character row)
    ----------------------------------------------------------------
    char_rom_inst : char_rom
        port map (
            clk      => clk_pix,
            addr     => char_addr,
            ce       => '1',
            data_out => char_bitmap
        );

    ----------------------------------------------------------------
    -- Pixel generator: converts char code + bitmap to RGB and provides VRAM address
    ----------------------------------------------------------------
    pix_inst : pixel_gen
        port map (
            pixel_clk   => clk_pix,
            pixel_row   => pixel_row,
            pixel_col   => pixel_col,

            char_code   => vram_char,
            char_bitmap => char_bitmap,

            vram_addr   => vram_addr_vga,

            red         => rgb_r_in,
            green       => rgb_g_in,
            blue        => rgb_b_in
        );

    ----------------------------------------------------------------
    -- VGA sync and output formatting
    ----------------------------------------------------------------
    vga_sync_inst : vga_sync
        port map (
            pixel_clk => clk_pix,
            red_in    => rgb_r_in,
            green_in  => rgb_g_in,
            blue_in   => rgb_b_in,
            red_out   => rgb_r_out,
            green_out => rgb_g_out,
            blue_out  => rgb_b_out,
            hsync     => vga_hs,
            vsync     => vga_vs,
            pixel_row => pixel_row,
            pixel_col => pixel_col
        );

    vga_r <= rgb_r_out;
    vga_g <= rgb_g_out;
    vga_b <= rgb_b_out;

end architecture;
