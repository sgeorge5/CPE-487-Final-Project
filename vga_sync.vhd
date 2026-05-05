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

    -- 640x480@60Hz timing (pixel clock ≈ 25 MHz)
    constant H_VISIBLE : integer := 640;
    constant H_FP      : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BP      : integer := 48;
    constant V_VISIBLE : integer := 480;
    constant V_FP      : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BP      : integer := 33;

    constant H_TOTAL : integer := H_VISIBLE + H_FP + H_SYNC + H_BP; -- 800
    constant V_TOTAL : integer := V_VISIBLE + V_FP + V_SYNC + V_BP; -- 525

    signal h_cnt : unsigned(9 downto 0) := (others => '0'); -- 0..799
    signal v_cnt : unsigned(9 downto 0) := (others => '0'); -- 0..524

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

            -- Vertical counter
            if to_integer(h_cnt) = H_TOTAL - 1 then
                if to_integer(v_cnt) = V_TOTAL - 1 then
                    v_cnt <= (others => '0');
                else
                    v_cnt <= v_cnt + 1;
                end if;
            end if;

            -- HSYNC active low during visible+front porch
            if (to_integer(h_cnt) >= H_VISIBLE + H_FP) and
               (to_integer(h_cnt) <  H_VISIBLE + H_FP + H_SYNC) then
                hsync <= '0';
            else
                hsync <= '1';
            end if;

            -- VSYNC active low during visible+front porch
            if (to_integer(v_cnt) >= V_VISIBLE + V_FP) and
               (to_integer(v_cnt) <  V_VISIBLE + V_FP + V_SYNC) then
                vsync <= '0';
            else
                vsync <= '1';
            end if;

            -- Video on region
            if (to_integer(h_cnt) < H_VISIBLE) and
               (to_integer(v_cnt) < V_VISIBLE) then
                video_on := '1';
            else
                video_on := '0';
            end if;

            -- Pixel coordinates
            pixel_col <= std_logic_vector(resize(h_cnt, pixel_col'length));
            pixel_row <= std_logic_vector(resize(v_cnt, pixel_row'length));

            -- RGB gating
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

    red_out   <= red_reg;
    green_out <= green_reg;
    blue_out  <= blue_reg;

end architecture;
