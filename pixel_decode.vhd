LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

library work;
use work.font_rom_pkg.all;

entity pixel_decode is
    port (
        pixel_clk                   : in std_logic;
        buf_addr                    : out integer range 0 to 39;
        buf_data                    : in std_logic_vector(5 downto 0);
        pixel_row                   : in std_logic_vector(10 downto 0);
        pixel_col                   : in std_logic_vector(10 downto 0);
        red_out                     : out std_logic_vector(2 downto 0);
        green_out                   : out std_logic_vector(2 downto 0);
        blue_out                    : out std_logic_vector(1 downto 0);
        is_first_scanline_of_row    : out std_logic
    );
end pixel_decode;

architecture behavioral of pixel_decode is

begin
    process (pixel_clk) is
        variable ipixel_row : integer range 0 to 1023 := 0;
        variable ipixel_col : integer range 0 to 1023 := 0;

        variable scanline   : integer range 0 to 15 := 0;
        variable char_col   : integer range 0 to 39 := 0;
        variable vindex     : integer range 0 to 7 := 0;
        variable hindex     : integer range 0 to 6 := 0;
    begin
        if rising_edge(pixel_clk) then
            ipixel_row := to_integer(unsigned(pixel_row)); 
            ipixel_col := to_integer(unsigned(pixel_col));
    
            --120px to 680px horizontal
            --108px to 492px vertical
    
            if ipixel_row >= 108 and ipixel_row < 492 then
                scanline   := (ipixel_row - 108) mod 16; 
                vindex     := scanline / 2; --vertical index within character
                hindex     := ((ipixel_col - 120) mod 14) / 2; --horizontal within character
                char_col   := (ipixel_col - 120) / 14; 
    
                --begin loading of first line 
                if scanline = 0 and ipixel_row < 492 then 
                    is_first_scanline_of_row <= '1'; 
                else
                    is_first_scanline_of_row <= '0';
                end if;
    
                if ipixel_col >= 120 and ipixel_col < 680 then
                    buf_addr <= char_col;
                    if font_rom((to_integer(unsigned(buf_data)) * 8) + vindex)(hindex) = '1' then
                        red_out <= "111";
                        green_out <= "111";
                        blue_out <= "11";
                    else
                        red_out <= "000";
                        green_out <= "000";
                        blue_out <= "00";
                    end if;
                else
                    red_out <= "111";
                    green_out <= "111";
                    blue_out <= "11";
    
                end if;
    
            else
                is_first_scanline_of_row <= '0';
    
                red_out <= "111";
                green_out <= "111";
                blue_out <= "11";
    
            end if;
           
        end if;

    end process;

end architecture;