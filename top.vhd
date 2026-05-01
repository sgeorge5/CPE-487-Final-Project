library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apple1_top is
    port (
        CLK100MHZ : in  std_logic;
        RESET_BTN : in  std_logic;
        LED       : out std_logic_vector(15 downto 0);

        -- VGA outputs (match your XDC)
        VGA_R     : out std_logic_vector(3 downto 0);
        VGA_G     : out std_logic_vector(3 downto 0);
        VGA_B     : out std_logic_vector(3 downto 0);
        VGA_HS    : out std_logic;
        VGA_VS    : out std_logic
    );
end entity;

architecture rtl of apple1_top is

    --------------------------------------------------------------------
    -- CPU universal bus
    --------------------------------------------------------------------
    signal cpu_clk      : std_logic := '0';
    signal cpu_reset    : std_logic := '0';
    signal cpu_addr     : std_logic_vector(15 downto 0);
    signal cpu_din      : std_logic_vector(7 downto 0);
    signal cpu_dout     : std_logic_vector(7 downto 0);
    signal cpu_we       : std_logic;
    
    signal mx_rw : std_logic;

    --------------------------------------------------------------------
    -- RAM / ROM
    --------------------------------------------------------------------
    signal ram_data_out : std_logic_vector(7 downto 0);
    signal ram_ce       : std_logic;

    signal rom_data_out : std_logic_vector(7 downto 0);
    signal rom_ce       : std_logic;

    --------------------------------------------------------------------
    -- COMPONENT DECLARATIONS
    --------------------------------------------------------------------
    component mx65 is
        port (
            clock    : in  std_logic;
            reset    : in  std_logic;
            ce       : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            address  : out std_logic_vector(15 downto 0);
            rw       : out std_logic;
            sync     : out std_logic;
            nmi      : in  std_logic;
            irq      : in  std_logic
        );
    end component;
    
    component video_ram is
    port (
        clk_cpu   : in  std_logic;
        addr_cpu  : in  std_logic_vector(9 downto 0);
        data_in   : in  std_logic_vector(7 downto 0);
        data_out  : out std_logic_vector(7 downto 0);  -- ← add this if missing
        we        : in  std_logic;
        clk_vga   : in  std_logic;
        addr_vga  : in  std_logic_vector(9 downto 0);
        char_out  : out std_logic_vector(7 downto 0)
    );
end component;


    component memory is
        port (
            clk      : in  std_logic;
            addr     : in  std_logic_vector(15 downto 0);
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            ce       : in  std_logic;
            we       : in  std_logic
        );
    end component;

    component rom is
        port (
            clock    : in  std_logic;
            address  : in  std_logic_vector(7 downto 0);
            ce       : in  std_logic;
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    component video_top is
        port (
            clk_cpu  : in  std_logic;
            clk_pix  : in  std_logic;
            reset    : in  std_logic;

            cpu_addr : in  std_logic_vector(15 downto 0);
            cpu_dout : in  std_logic_vector(7 downto 0);
            cpu_din  : out std_logic_vector(7 downto 0);
            cpu_we   : in  std_logic;

            vga_hs   : out std_logic;
            vga_vs   : out std_logic;
            vga_r    : out std_logic_vector(3 downto 0);
            vga_g    : out std_logic_vector(3 downto 0);
            vga_b    : out std_logic_vector(3 downto 0)
        );
    end component;

begin

    --------------------------------------------------------------------
    -- RESET (active low button)
    --------------------------------------------------------------------
    cpu_reset <= not RESET_BTN;

    --------------------------------------------------------------------
    -- CPU CLOCK DIVIDER (100 MHz → 1 MHz)
    --------------------------------------------------------------------
    process(CLK100MHZ)
        variable cnt : integer range 0 to 49 := 0;
    begin
        if rising_edge(CLK100MHZ) then
            if cnt = 49 then
                cnt := 0;
                cpu_clk <= not cpu_clk;
            else
                cnt := cnt + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- CPU
    --------------------------------------------------------------------
    cpu_we <= not mx_rw;

    mx6502 : mx65
        port map (
            clock    => cpu_clk,
            reset    => cpu_reset,
            ce       => '1',
            data_in  => cpu_din,
            data_out => cpu_dout,
            address  => cpu_addr,
            rw       => mx_rw,
            sync     => open,
            nmi      => '1',
            irq      => '1'
        );

    --------------------------------------------------------------------
    -- RAM (4 KB)
    --------------------------------------------------------------------
    ram_ce <= '1' when cpu_addr(15 downto 12) = x"0" else '0';

    mem : memory
        port map (
            clk      => cpu_clk,
            addr     => cpu_addr,
            data_in  => cpu_dout,
            data_out => ram_data_out,
            ce       => ram_ce,
            we       => cpu_we
        );

    --------------------------------------------------------------------
    -- ROM (WOZMON at FF00-FFFF)
    --------------------------------------------------------------------
    rom_ce <= '1' when cpu_addr(15 downto 8) = x"FF" else '0';

    wozrom : rom
        port map (
            clock    => cpu_clk,
            address  => cpu_addr(7 downto 0),
            ce       => rom_ce,
            data_out => rom_data_out
        );

    --------------------------------------------------------------------
    -- CPU DATA BUS MUX
    --------------------------------------------------------------------
    cpu_din <=
        ram_data_out when ram_ce = '1' else
        rom_data_out when rom_ce = '1' else
        (others => '0');

    --------------------------------------------------------------------
    -- VGA SUBSYSTEM
    --------------------------------------------------------------------
    video : video_top
        port map (
            clk_cpu  => cpu_clk,
            clk_pix  => CLK100MHZ,   -- TEMPORARY: replace with PLL later
            reset    => cpu_reset,

            cpu_addr => cpu_addr,
            cpu_dout => cpu_dout,
            cpu_din  => open,        -- not used yet
            cpu_we   => cpu_we,

            vga_hs   => VGA_HS,
            vga_vs   => VGA_VS,
            vga_r    => VGA_R,
            vga_g    => VGA_G,
            vga_b    => VGA_B
        );
        

    --------------------------------------------------------------------
    -- DEBUG: show address on LEDs
    --------------------------------------------------------------------
    LED <= cpu_addr;

end architecture;
