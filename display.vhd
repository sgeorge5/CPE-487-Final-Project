LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.font_rom_pkg.all;

entity crom is
    port (
        clk : in std_logic;
        pixel_clk : in std_logic;
        da : in std_logic; --data available
        rda : out std_logic; --ready data accept
        data_in : in std_logic_vector(6 downto 0); --6 bit ascii value from PIA

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
    type crom_col_t is array (0 to 39) of std_logic_vector(6 downto 0);
    type crom_t is array (0 to 23) of crom_col_t;
    --signal crom : crom_t := (others => (others => (others => '0')));
    constant crom : crom_t := (
        ("0000000","0000001","0000010","0000011","0000100","0000101","0000110","0000111","0001000","0001001","0001010","0001011","0001100","0001101","0001110","0001111","0010000","0010001","0010010","0010011","0010100","0010101","0010110","0010111","0011000","0011001","0011010","0011011","0011100","0011101","0011110","0011111","0100000","0100001","0100010","0100011","0100100","0100101","0100110","0100111"),
        ("0101000","0101001","0101010","0101011","0101100","0101101","0101110","0110000","0110001","0110010","0110011","0110100","0111000","0111001","0111010","0111011","0111100","0111101","0111110","0111111", others => (others => '0')),
        others => (others => (others => '0'))
    );

    signal crom_col_index : integer range 0 to 39 := 0;
    signal crom_row_index : integer range 0 to 23 := 0;
    signal top_row_pointer : integer range 0 to 23 := 0;

    signal screen_full : std_logic := '0';
    signal da_prev : std_logic := '0';

    signal draw_row_index : integer range 0 to 23 := 0;
    signal draw_col_index : integer range 0 to 39 := 0;
    CONSTANT H_FP   : INTEGER := 88;
    signal fp_count : std_logic_vector(10 downto 0) := "00000000000";
    signal hpixel_count : integer range 0 to 13 := 0;
    signal vpixel_count : integer range 0 to 15 := 0;
    
    signal draw_pixel : std_logic := '0';

    signal dbg_crom_row_indx : integer;
    signal dbg_crom_col_indx : integer;
    signal dbg_from_row_indx : integer;
    signal dbg_from_col_indx : integer;
begin
    --character memory process
    process (clk)
    begin
        if da = '1' then
            --draw stuff
            crom(crom_row_index)(crom_col_index) <= data_in;

            if (crom_col_index = 39) then --if out of characters on a line
                if (crom_row_index = 23) OR screen_full = '1' then --if out of rows
                    if (top_row_pointer = 23) then
                        top_row_pointer <= 0;
                    else
                        top_row_pointer <= top_row_pointer + 1;
                    end if;
                    crom(top_row_pointer) <= (others => (others => '0'));
                    crom_row_index <= top_row_pointer;
                    crom_col_index <= 0;
                    screen_full <= '1';
                else
                    crom_row_index <= crom_row_index + 1;
                    crom_col_index <= 0;
                end if;
            else 
                crom_col_index <= crom_col_index + 1;
            end if;
            rda <= '1';
        else
            rda <= '0';
        end if;
    end process;

    --vga drawing process
    draw: process (pixel_row, pixel_col)
        variable int_pixel_row : integer;
        variable int_pixel_col : integer;

        variable v_crom_row_index : integer;
        variable v_crom_col_index : integer;

        variable v_from_row_index : integer;
        variable v_from_col_index : integer;
    begin
        --pixel_row : height of screen is 600
		--pixel_col : width of screen is 800

        --map text rendering to center of screen where each character is 14px wide, 16px tall
        --need 14*40 = 560px of horizontal space, 16*23 = 368px of vertical space
        --can add (width - hspace) / 2 and (height - vspace) / 2 of padding (120px and 116px)
        --so we want to draw if 120 < pixel_col < 680 and 116 < pixel_row < 484  
        --determine index in font_rom using mod, taxing but can change later

        int_pixel_row := to_integer(unsigned(pixel_row));
        int_pixel_col := to_integer(unsigned(pixel_col));

        v_crom_row_index := (int_pixel_row - 116) / 16;
        v_crom_col_index := (int_pixel_col - 120) / 14;

        if ((pixel_row >= 116) AND (pixel_row < 484)) AND ((pixel_col >= 120) AND (pixel_col < 680)) then
            v_from_row_index := to_integer(unsigned(crom(v_crom_row_index)(v_crom_col_index))) * 8 + (((int_pixel_row - 116) mod 16) / 2);
            v_from_col_index := ((int_pixel_col - 120) mod 14) / 2;
            draw_pixel <= font_rom(v_from_row_index)(v_from_col_index);
        else
            draw_pixel <= '1';
        end if;

        dbg_crom_row_indx <= v_crom_row_index;
        dbg_crom_col_indx <= v_crom_col_index;
        dbg_from_row_indx <= v_from_row_index;
        dbg_from_col_indx <= v_from_col_index;

    end process;

    red <= draw_pixel & draw_pixel & draw_pixel;
    green <= draw_pixel & draw_pixel & draw_pixel;
    blue <= draw_pixel & draw_pixel;
end architecture;