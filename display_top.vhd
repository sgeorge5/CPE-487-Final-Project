LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity display_top is
    port(
        CLK_IN              : in std_logic;
        CLR_SCREEN          : in std_logic;
        RED_OUT             : out std_logic_vector(2 downto 0);
        GREEN_OUT           : out std_logic_vector(2 downto 0);
        BLUE_OUT            : out std_logic_vector(1 downto 0);
        H_SYNC              : out std_logic;
        V_SYNC              : out std_logic;
        CHAR_CODE           : in std_logic_vector(6 downto 0);
        DATA_AVAILABLE      : in std_logic;
        READY_DATA_ACCEPT   : out std_logic
    );
end display_top;

architecture rtl of display_top is
    --signal CLK_IN : std_logic;
    --signal char_code : std_logic_vector(6 downto 0);
    --signal data_available : std_logic := '0';
    --signal ready_data_accept : std_logic;
    --signal clr_screen : std_logic;

    component dsp_shift_register is
        port (
            clr_screen              : in std_logic;
            pixel_clk               : in std_logic;
            is_first_scanline_of_row: in std_logic;
            h_blank                 : in std_logic;
            v_blank                 : in std_logic;
            buf_write_addr          : out integer range 0 to 39;
            buf_write_data          : out std_logic_vector(5 downto 0);
            buf_we                  : out std_logic;
            ready_data_accept       : out std_logic;
            data_available          : in std_logic;
            char_code_in            : in std_logic_vector(6 downto 0)
        );
    end component;

    component vga_sync is
        port (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            green_in  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            blue_in   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            red_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            green_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            blue_out  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            hsync     : OUT STD_LOGIC;
            vsync     : OUT STD_LOGIC;
            hblank    : OUT STD_LOGIC;
            vblank    : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    end component;

    component pixel_decode is
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
    end component;

    component line_buffer is
        port (
            pixel_clk   : in std_logic;
            write_addr  : in integer range 0 to 39;
            read_addr   : in integer range 0 to 39;
            data_in     : in std_logic_vector(5 downto 0);
            data_out    : out std_logic_vector(5 downto 0);
            we          : in std_logic
        );
    end component;

    component clk_wiz_0 is
        port (
            clk_in1  : in std_logic;
            clk_out1 : out std_logic
        );
    end component;

    signal S_pixel_clk                  : std_logic;
    signal S_is_first_scanline_of_row   : std_logic;
    signal S_hsync                      : std_logic;
    signal S_vsync                      : std_logic;
    signal S_hblank                     : std_logic;
    signal S_vblank                     : std_logic;
    signal S_lbf_write_addr             : integer range 0 to 39;
    signal S_lbf_read_addr              : integer range 0 to 39;
    signal S_lbf_data_in                : std_logic_vector(5 downto 0);
    signal S_lbf_data_out               : std_logic_vector(5 downto 0);
    signal S_lbf_we                     : std_logic;
    signal S_red                        : std_logic_vector(2 downto 0);
    signal S_green                      : std_logic_vector(2 downto 0);
    signal S_blue                       : std_logic_vector(1 downto 0);
    signal S_pixel_row                  : std_logic_vector(10 downto 0);
    signal S_pixel_col                  : std_logic_vector(10 downto 0);

begin

    sr1 : dsp_shift_register
        port map (
            clr_screen                  => CLR_SCREEN,
            pixel_clk                   => S_pixel_clk,
            is_first_scanline_of_row    => S_is_first_scanline_of_row,
            h_blank                     => S_hblank,
            v_blank                     => S_vblank,
            buf_write_addr              => S_lbf_write_addr,
            buf_write_data              => S_lbf_data_in,
            buf_we                      => S_lbf_we,
            ready_data_accept           => READY_DATA_ACCEPT,
            data_available              => DATA_AVAILABLE,
            char_code_in                => CHAR_CODE
        );

    vga1 : vga_sync
        port map (
            pixel_clk   => S_pixel_clk,
            red_in      => S_red,
            green_in    => S_green,
            blue_in     => S_blue,
            red_out     => RED_OUT,
            green_out   => GREEN_OUT,
            blue_out    => BLUE_OUT,
            hsync       => S_hsync,
            vsync       => S_vsync,
            hblank      => S_hblank,
            vblank      => S_vblank,
            pixel_row   => S_pixel_row,
            pixel_col   => S_pixel_col
        );

    pd1 : pixel_decode
        port map (
            pixel_clk                   => S_pixel_clk,
            buf_addr                    => S_lbf_read_addr,
            buf_data                    => S_lbf_data_out,
            pixel_row                   => S_pixel_row,
            pixel_col                   => S_pixel_col,
            red_out                     => S_red,
            green_out                   => S_green,
            blue_out                    => S_blue,
            is_first_scanline_of_row    => S_is_first_scanline_of_row  
        );

    lb1 : line_buffer
        port map (
            pixel_clk   => S_pixel_clk,
            write_addr  => S_lbf_write_addr,
            read_addr   => S_lbf_read_addr,
            data_in     => S_lbf_data_in,
            data_out    => S_lbf_data_out,
            we          => S_lbf_we  
        );

    clk_wiz_0_inst : clk_wiz_0
        port map (
            clk_in1 => CLK_IN,
            clk_out1 => S_pixel_clk
        );
        
    --process
    --begin
    --   clk_in <= '1';
    --    wait for 5ns;
    --   clk_in <= '0';
    --   wait for 5ns;
    --end process;

    H_SYNC <= S_hsync;
    V_SYNC <= S_vsync;

end architecture;