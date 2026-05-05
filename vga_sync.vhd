library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
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
end entity;

architecture rtl of vga_sync is

    -- Timing constants for 800x600@60 (example)
    constant H_VISIBLE  : integer := 800;
    constant H_FP       : integer := 40;
    constant H_SYNC     : integer := 128;
    constant H_BP       : integer := 88;
    constant V_VISIBLE  : integer := 600;
    constant V_FP       : integer := 1;
    constant V_SYNC     : integer := 4;
    constant V_BP       : integer := 23;

    constant H_TOTAL : integer := H_VISIBLE + H_FP + H_SYNC + H_BP;
    constant V_TOTAL : integer := V_VISIBLE + V_FP + V_SYNC + V_BP;

    signal h_cnt : unsigned(11 downto 0) := (others => '0'); -- enough bits for H_TOTAL
    signal v_cnt : unsigned(11 downto 0) := (others => '0');

    signal red_reg   : std_logic_vector(3 downto 0) := (others => '0');
    signal green_reg : std_logic_vector(3 downto 0) := (others => '0');
    signal blue_reg  : std_logic_vector(3 downto 0) := (others => '0');

begin

    process(pixel_clk)
        variable video_on : std_logic;
    begin
        if rising_edge(pixel_clk) then

            -- Horizontal counter
            if to_integer(h_cnt) = H_TOTAL - 1 then
                h_cnt <= (others => '0');
            else
                h_cnt <= h_cnt + 1;
            end if;

            -- Horizontal sync: active low during H_VISIBLE+H_FP .. H_VISIBLE+H_FP+H_SYNC-1
            if (to_integer(h_cnt) >= H_VISIBLE + H_FP) and (to_integer(h_cnt) < H_VISIBLE + H_FP + H_SYNC) then
                hsync <= '0';
            else
                hsync <= '1';
            end if;

            -- Vertical counter increments at end of each horizontal line
            if to_integer(h_cnt) = H_TOTAL - 1 then
                if to_integer(v_cnt) = V_TOTAL - 1 then
                    v_cnt <= (others => '0');
                else
                    v_cnt <= v_cnt + 1;
                end if;
            end if;

            -- Vertical sync: active low during V_VISIBLE+V_FP .. V_VISIBLE+V_FP+V_SYNC-1
            if (to_integer(v_cnt) >= V_VISIBLE + V_FP) and (to_integer(v_cnt) < V_VISIBLE + V_FP + V_SYNC) then
                vsync <= '0';
            else
                vsync <= '1';
            end if;

            -- Video on when within visible area
            if (to_integer(h_cnt) < H_VISIBLE) and (to_integer(v_cnt) < V_VISIBLE) then
                video_on := '1';
            else
                video_on := '0';
            end if;

            -- Pixel coordinates (registered outputs)
            pixel_col <= std_logic_vector(resize(h_cnt, pixel_col'length));
            pixel_row <= std_logic_vector(resize(v_cnt, pixel_row'length));

            -- Output RGB only when video_on
            if video_on = '1' then
                red_reg   <= red_in;
                green_reg <= green_in;
                blue_reg  <= blue_in;
            else
                red_reg   <= (others => '0');
                green_reg <= (others => '0');
                blue_reg  <= (others => '0');
            end if;
        end if;
    end process;

    -- Drive outputs
    red_out   <= red_reg;
    green_out <= green_reg;
    blue_out  <= blue_reg;

end architecture;
