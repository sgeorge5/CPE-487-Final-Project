--TODO: add reset states

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

library work;
use work.font_rom_pkg.all;

entity crom is
    port (
        clk : in std_logic;
        pixel_clk : in std_logic;
        rst : in std_logic;
        da : in std_logic; --data available
        rda : out std_logic; --ready data accept
        data_in : in std_logic_vector(6 downto 0); --7 bit ascii value from PIA

        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        
        red : out std_logic_vector(2 downto 0);
        green : out std_logic_vector(2 downto 0);
        blue : out std_logic_vector(1 downto 0);
        
        v_sync : in std_logic;
        h_sync : in std_logic
    );
end crom;

architecture Behavioral of crom is
    type crom_t is array (0 to 959) of std_logic_vector(6 downto 0);
    signal crom : crom_t := (others => (others => '0'));

    --character memory process signals
    signal char_row : integer range 0 to 23;
    signal char_col : integer range 0 to 39;
    signal top_row_pointer : integer;
    signal screen_full : std_logic;
    
    signal draw_pixel : std_logic := '0';
    signal rda_s : std_logic := '1'; --signal should default to 1 : start out "waiting" for data
begin
    --character memory process
    process (clk)
    begin
        if rst = '1' then
            rda_s <= '1';
            char_row <= 0;
            char_col <= 0;
            crom <= (others => "0100000");
            top_row_pointer <= 0;
            screen_full <= '0';
        elsif rising_edge(clk) then
            crom(23 * 40 + 36) <= "000000" & screen_full;
            crom(23 * 40 + 37) <= std_logic_vector(to_unsigned(top_row_pointer, 7));
            crom(23 * 40 + 38) <= std_logic_vector(to_unsigned(char_row, 7));
            crom(23 * 40 + 39) <= std_logic_vector(to_unsigned(char_col, 7));
            --only sample data when data available signal is high
            if (da = '1') then
                --draw stuff
                crom(char_row * 40 + char_col) <= data_in;

                if (char_col = 39) then --if out of characters on a line
                    if (char_row = 23) OR screen_full = '1' then --if out of rows
                        if (top_row_pointer = 23) then
                            top_row_pointer <= 0;
                        else
                            top_row_pointer <= top_row_pointer + 1;
                        end if;
                        
                        --clear top row
                        for i in 0 to 39 loop
                            crom(top_row_pointer * 40 + i) <= "0100000";
                        end loop;
                        char_row <= top_row_pointer;
                        char_col <= 0;
                        screen_full <= '1';
                    else
                        char_row <= char_row + 1;
                        char_col <= 0;
                    end if;
                else 
                    char_col <= char_col + 1;
                end if;

                --set RDA to 1 when done drawing to effectively set DA to 0
                rda <= '1';
            else
                --set RDA to 0 until the PIA is written to by the CPU to clear CB2 and set DA back to 1
                rda <= '0';
            end if;
        end if;
    end process;

    --vga drawing process
    draw: process (pixel_clk)
        constant ROW_OFFSET : integer := 108;
        constant COL_OFFSET : integer := 120;
        constant ROWS : integer := 24;
        constant COLS : integer := 40;
        
        variable r : integer;
        variable c : integer;
        
        variable tile_row : integer range 0 to 23;
        variable tile_col : integer range 0 to 39;
        variable adj_tile_row : integer;
        
        variable char_val : integer;
        
        variable font_row : integer;
        variable font_col : integer;
    begin
        --pixel_row : height of screen is 600
		--pixel_col : width of screen is 800

        --map text rendering to center of screen where each character is 14px wide, 16px tall
        --need 14*40 = 560px of horizontal space, 16*23 = 368px of vertical space
        --can add (width - hspace) / 2 and (height - vspace) / 2 of padding (120px and 116px)
        --so we want to draw if 120 < pixel_col < 680 and 108 < pixel_row < 492  
        --determine index in font_rom using mod, taxing but can change later

        if rising_edge(pixel_clk) then
            r := to_integer(unsigned(pixel_row));
            c := to_integer(unsigned(pixel_col));
            
            draw_pixel <= '1';
    
            -- >= row 0x74
            -- >= col 0x78
            if (r >= ROW_OFFSET) AND (r < ROW_OFFSET + (ROWS * 16)) AND 
               (c >= COL_OFFSET) AND (c < COL_OFFSET + (COLS * 14)) then
                tile_row := (r - ROW_OFFSET) / 16;
                tile_col := (c - COL_OFFSET) / 14;
                
                adj_tile_row := (tile_row + top_row_pointer) mod 24;
                
                char_val := to_integer(unsigned(crom(adj_tile_row * 40 + tile_col)));
                
                if (char_val < 0) OR (char_val >= 64) then
                    char_val := 0;
                end if;
                
                font_row := (char_val * 8) + (((r - ROW_OFFSET) mod 16) / 2);
                font_col := ((c - COL_OFFSET) mod 14) / 2;
                draw_pixel <= font_rom(font_row)(font_col);
            else
                draw_pixel <= '1';
            end if;
        end if;
        
    end process;

    red <= draw_pixel & draw_pixel & draw_pixel;
    green <= draw_pixel & draw_pixel & draw_pixel;
    blue <= draw_pixel & draw_pixel;
end architecture;