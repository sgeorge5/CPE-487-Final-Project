LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY vga_top IS
    PORT (
        clk_in    : IN STD_LOGIC;
        vga_red   : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
        vga_green : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
        vga_blue  : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        vga_hsync : OUT STD_LOGIC;
        vga_vsync : OUT STD_LOGIC;
        
        SW : in std_logic_vector(6 downto 0);
        BTNC : in std_logic;
        BTNU : in std_logic
    );
END vga_top;

ARCHITECTURE Behavioral OF vga_top IS
    --SIGNAL clk_in : STD_LOGIC;
    SIGNAL pxl_clk : STD_LOGIC;
    -- internal signals to connect modules
    SIGNAL S_red, S_green : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL S_blue : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL S_vsync : STD_LOGIC;
    SIGNAL S_hsync : STD_LOGIC;
    SIGNAL S_pixel_row, S_pixel_col : STD_LOGIC_VECTOR (10 DOWNTO 0);
    Signal S_rda, S_da : STD_LOGIC;
    Signal S_data_in : STD_LOGIC_VECTOR(6 downto 0);
    Signal S_rst : std_logic;
    
    COMPONENT crom IS
        port (
            --clk : in std_logic;
            clk : in std_logic;
            pixel_clk : in std_logic;
            rst : in std_logic;
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
    END COMPONENT;
    
    signal da_sync, da_prev : std_logic;
    signal da_pulse : std_logic;
    
    signal rst_sync, rst_prev : std_logic;
    signal rst_pulse : std_logic;
    
    COMPONENT vga_sync IS
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC;
            green_in  : IN STD_LOGIC;
            blue_in   : IN STD_LOGIC;
            red_out   : OUT STD_LOGIC;
            green_out : OUT STD_LOGIC;
            blue_out  : OUT STD_LOGIC;
            hsync     : OUT STD_LOGIC;
            vsync     : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    END COMPONENT;
    
    component clk_wiz_0 is
    port (
      clk_in1  : in std_logic;
      clk_out1 : out std_logic
    );
    end component;
    
    
BEGIN
    -- vga_driver only drives MSB of red, green & blue
    -- so set other bits to zero
    
    --clock : process
    --begin
    --    clk_in <= '1';
    --    wait for 5ns;
    --    clk_in <= '0';
    --    wait for 5ns;
    --end process;
    
    vga_red(1 DOWNTO 0) <= "00";
    vga_green(1 DOWNTO 0) <= "00";
    vga_blue(0) <= '0';

    u1 : crom
    PORT MAP(
        --instantiate ball component
        clk => clk_in,
        pixel_clk => pxl_clk,
        rst => S_rst,
        da => S_da,
        rda => S_rda,
        data_in => S_data_in,
        pixel_row => S_pixel_row,
        pixel_col => S_pixel_col,
        red => S_red,
        green => S_green,
        blue => S_blue,
        v_sync => S_vsync,
        h_sync => S_hsync
    );
    
    --switch debounce
    process (clk_in)
    begin
        if rising_edge(clk_in) then
            da_sync <= BTNC;
            da_pulse <= da_sync and not da_prev;
            da_prev <= da_sync;
            
            rst_sync <= BTNU;
            rst_pulse <= rst_sync and not rst_prev;
            rst_prev <= rst_sync;
        end if;
    end process;
    
    S_da <= da_pulse;
    S_rst <= rst_pulse;

    --register switch values
    process(clk_in)
    begin
        if rising_edge(clk_in) then
            S_data_in <= SW;
        end if;
    end process;

    vga_driver : vga_sync
    PORT MAP(
        --instantiate vga_sync component
        pixel_clk => pxl_clk, 
        red_in    => S_red(2), 
        green_in  => S_green(2), 
        blue_in   => S_blue(1), 
        red_out   => vga_red(2), 
        green_out => vga_green(2), 
        blue_out  => vga_blue(1), 
        pixel_row => S_pixel_row, 
        pixel_col => S_pixel_col, 
        hsync     => S_hsync, 
        vsync     => S_vsync
    );
    vga_vsync <= S_vsync; --connect output vsync
    vga_hsync <= S_hsync;
        
    clk_wiz_0_inst : clk_wiz_0
    port map (
      clk_in1 => clk_in,
      clk_out1 => pxl_clk
    );
    
END Behavioral;