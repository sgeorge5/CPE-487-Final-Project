library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_gen is
    port (
        pixel_clk   : in  std_logic;
        pixel_row   : in  std_logic_vector(10 downto 0);
        pixel_col   : in  std_logic_vector(10 downto 0);

        -- character from video RAM
        char_code   : in  std_logic_vector(7 downto 0);

        -- 8-bit row bitmap from char ROM (one byte = 8 horizontal pixels)
        char_bitmap : in  std_logic_vector(7 downto 0);

        -- address into video RAM (0-959)
        vram_addr   : out std_logic_vector(9 downto 0);

        -- RGB pixel output
        red         : out std_logic_vector(3 downto 0);
        green       : out std_logic_vector(3 downto 0);
        blue        : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of pixel_gen is

    -- character cell size (scaled 2x from 8x8 font)
    constant FONT_W : integer := 8;   -- font width in pixels
    constant FONT_H : integer := 8;   -- font height in pixels
    constant SCALE  : integer := 2;   -- scale factor (2x)
    constant CHAR_W : integer := FONT_W * SCALE;  -- 16
    constant CHAR_H : integer := FONT_H * SCALE;  -- 16

    -- text resolution
    constant COLS : integer := 40;
    constant ROWS : integer := 24;

    -- internal registered signals
    signal col_idx_r      : integer range 0 to COLS-1 := 0;
    signal row_idx_r      : integer range 0 to ROWS-1 := 0;
    signal row_in_char_r  : integer range 0 to FONT_H-1 := 0; -- 0..7
    signal col_in_char_r  : integer range 0 to FONT_W-1 := 0; -- 0..7
    signal pixel_on_r     : std_logic := '0';
    signal vram_addr_r    : std_logic_vector(9 downto 0) := (others => '0');

begin

    ----------------------------------------------------------------
    -- Compute indices and pixel_on synchronously to pixel_clk
    -- Use bit-slicing for division by CHAR_W/CHAR_H (CHAR_W/CHAR_H are 16)
    ----------------------------------------------------------------
    process(pixel_clk)
        variable pcol : integer;
        variable prow : integer;
        variable cidx : integer;
        variable ridx : integer;
        variable col_in_font : integer;
        variable row_in_font : integer;
        variable bit_index : integer;
    begin
        if rising_edge(pixel_clk) then
            -- convert pixel coordinates to integers
            pcol := to_integer(unsigned(pixel_col));
            prow := to_integer(unsigned(pixel_row));

            -- compute character column/row (division by 16 -> shift right 4)
            cidx := pcol / CHAR_W;  -- safe: CHAR_W is constant 16
            ridx := prow / CHAR_H;

            if cidx < COLS then
                col_idx_r <= cidx;
            else
                col_idx_r <= COLS - 1;
            end if;

            if ridx < ROWS then
                row_idx_r <= ridx;
            else
                row_idx_r <= ROWS - 1;
            end if;

            -- compute position inside the 16x16 character cell
            -- scale factor 2: map 16x16 -> 8x8 font by dividing by 2
            row_in_font := (prow mod CHAR_H) / SCALE;  -- 0..7
            col_in_font := (pcol mod CHAR_W) / SCALE;  -- 0..7

            row_in_char_r <= row_in_font;
            col_in_char_r <= col_in_font;

            -- compute VRAM address: row * COLS + col
            vram_addr_r <= std_logic_vector(to_unsigned(row_idx_r * COLS + col_idx_r, 10));

            -- compute pixel_on from char_bitmap: bit 7 is leftmost
            -- ensure col_in_font in 0..7
            if (col_in_font >= 0) and (col_in_font <= 7) then
                bit_index := 7 - col_in_font;
                if char_bitmap(bit_index) = '1' then
                    pixel_on_r <= '1';
                else
                    pixel_on_r <= '0';
                end if;
            else
                pixel_on_r <= '0';
            end if;
        end if;
    end process;

    -- drive outputs
    vram_addr <= vram_addr_r;

    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if pixel_on_r = '1' then
                red   <= (others => '1');
                green <= (others => '1');
                blue  <= (others => '1');
            else
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            end if;
        end if;
    end process;

end architecture;
