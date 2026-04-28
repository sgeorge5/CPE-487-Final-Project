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

        -- 8-bit row bitmap from char ROM
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

    -- character cell size (scaled)
    constant CHAR_W : integer := 16;  -- width in pixels
    constant CHAR_H : integer := 16;  -- height in pixels

    -- text resolution
    constant COLS : integer := 40;
    constant ROWS : integer := 24;

    signal col_idx  : integer range 0 to COLS-1;
    signal row_idx  : integer range 0 to ROWS-1;

    signal row_in_char : integer range 0 to 7;
    signal col_in_char : integer range 0 to 7;

    signal pixel_on : std_logic;

begin

    col_idx <= to_integer(unsigned(pixel_col)) / CHAR_W;
    row_idx <= to_integer(unsigned(pixel_row)) / CHAR_H;

    
    vram_addr <= std_logic_vector(
                    to_unsigned(row_idx * COLS + col_idx, 10)
                 );

    row_in_char <= (to_integer(unsigned(pixel_row)) mod CHAR_H) / 2;  -- scale 2×
    col_in_char <= (to_integer(unsigned(pixel_col)) mod CHAR_W) / 2;


    pixel_on <= char_bitmap(7 - col_in_char);


    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if pixel_on = '1' then
                red   <= "1111";
                green <= "1111";
                blue  <= "1111";
            else
                red   <= "0000";
                green <= "0000";
                blue  <= "0000";
            end if;
        end if;
    end process;

end architecture;
