LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

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
    signal crom : crom_t := (others => (others => (others => '0')));
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

    type font_rom_t is array (0 to 2047) of std_logic_vector(6 downto 0);
    constant font_rom : font_rom_t := (
        --@ character
        0 => "0000000",
        1 => "0111000",
        2 => "1000100",
        3 => "1010100",
        4 => "1011100",
        5 => "1011000",
        6 => "1000000",
        7 => "0111000",
        others => (others => '0')
    );

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
    process (pixel_clk)
        variable h_sync_prev : std_logic;
        variable v_sync_prev : std_logic;
    begin
        if rising_edge(pixel_clk) then
            if (fp_count >= H_FP) then
                if font_rom(to_integer(unsigned(crom(draw_row_index)(draw_col_index))) * 8 + (vpixel_count / 2))(hpixel_count / 2) = '1' then
                    draw_pixel <= '1';
                else
                    draw_pixel <= '0';
                end if;
        
                if (hpixel_count = 13) then
                    hpixel_count <= 0;
                    if (draw_col_index = 39) then
                        --stop drawing
                    else
                        draw_col_index <= draw_col_index + 1;
                    end if;
                else
                    hpixel_count <= hpixel_count + 1;
                end if;
        
                if h_sync = '1' AND h_sync_prev = '0' then
                    draw_col_index <= 0;
                    hpixel_count <= 0;
                    fp_count <= (others => '0');
        
                    if (vpixel_count = 15) then
                        vpixel_count <= 0;
                        if (draw_row_index = 23) then
                            --stop drawing
                        else
                            draw_row_index <= draw_row_index + 1;
                        end if;
                    else
                        vpixel_count <= vpixel_count + 1;
                    end if;
                end if;
            else
                fp_count <= fp_count + 1;
            end if;
    
            if v_sync = '1' AND v_sync_prev = '0' then
                draw_row_index <= 0;
                vpixel_count <= 0;
            end if;
    
            h_sync_prev := h_sync;
            v_sync_prev := v_sync;
        end if;

    end process;

    red <= draw_pixel & draw_pixel & draw_pixel;
    green <= draw_pixel & draw_pixel & draw_pixel;
    blue <= draw_pixel & draw_pixel;
end architecture;