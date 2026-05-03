library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apple1_top is
    port (
        CLK100MHZ : in  std_logic;      -- CLK from board
        RESET_BTN : in  std_logic;      -- btnC
        LED       : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of apple1_top is
    --universal signals
    signal univ_clk : std_logic;
    signal univ_data_bus : std_logic_vector(7 downto 0);
    signal univ_addr_bus : std_logic_vector(15 downto 0);
    signal univ_we : std_logic;
    
    --mx65 signals
    signal mx_reset : std_logic;
    --signal mx_ce : in std_logic;
    signal mx_data_out : std_logic_vector(7 downto 0);
    signal mx_rw : std_logic;
    signal mx_sync : std_logic;
    --signal mx_nmi : std_logic;
    --signal mx_irq : std_logic;
    
    --ram signals
    signal ram_data_out : std_logic_vector(7 downto 0);
    signal ram_ce : std_logic;
    
    --rom signals
    signal rom_data_out : std_logic_vector(7 downto 0);
    signal rom_ce : std_logic;
    
    --pia signals
    signal pia_ce : std_logic;
    signal pia_rs : std_logic_vector(1 downto 0);
    signal pia_data_out : std_logic_vector(7 downto 0);
    signal pia_ca1_in : std_logic;
    signal pia_ca2_in : std_logic;
    signal pia_ca2_out : std_logic;
    signal pia_cb1_in : std_logic;
    signal pia_cb2_in : std_logic;
    signal pia_cb2_out : std_logic;
    signal pia_pa_in : std_logic_vector(7 downto 0);
    signal pia_pa_out : std_logic_vector(7 downto 0);
    signal pia_pa_oe_out : std_logic_vector(7 downto 0);
    signal pia_pb_in : std_logic_vector(7 downto 0);
    signal pia_pb_out : std_logic_vector(7 downto 0);
    signal pia_pb_oe_out : std_logic_vector(7 downto 0);
    signal pia_irqa : std_logic;
    signal pia_irqb : std_logic;

    component mx65 is 
        port (
            clock	: in std_logic;
            reset	: in std_logic;	  
            ce		: in std_logic;
            data_in	: in std_logic_vector(7 downto 0);
            data_out: out std_logic_vector(7 downto 0);
            address	: out std_logic_vector(15 downto 0);
            rw		: out std_logic;
            sync	: out std_logic;
            nmi		: in std_logic;
            irq		: in std_logic
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
            clock:    in std_logic;
            address:  in std_logic_vector(7 downto 0); 
            ce:       in std_logic;
            data_out: out std_logic_vector(7 downto 0)
        );
    end component;
    
    component io is 
    port(
        clk : in std_logic; -- essentially the E signal
        rst : in std_logic;
        cs : in std_logic;

        rs : in std_logic_vector(1 downto 0);

        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);

        ca1_in : in std_logic;
        ca2_in : in std_logic;
        ca2_out : out std_logic;

        cb1_in : in std_logic;
        cb2_in : in std_logic;
        cb2_out : out std_logic;

        pa_in : in std_logic_vector(7 downto 0);
        pa_out : out std_logic_vector(7 downto 0);
        pa_oe : out std_logic_vector(7 downto 0);

        pb_in : in std_logic_vector(7 downto 0);
        pb_out : out std_logic_vector(7 downto 0);
        pb_oe : out std_logic_vector(7 downto 0);

        rw : in std_logic;

        irqa : out std_logic;
        irqb : out std_logic
    );
    end component;

begin
    -- reset button for NEXYS (active low)
    --mx_reset <= not RESET_BTN;
    prc_reset : process
    begin
        mx_reset <= '1';
        wait for 100ms;
        mx_reset <= '0';
        wait;
    end process;

    -- clock 
    --process(CLK100MHZ)
    --    variable cnt : integer range 0 to 49 := 0;
    --begin
    --    if rising_edge(CLK100MHZ) then
    --        if cnt = 49 then
    --            cnt := 0;
    --            univ_clk <= not univ_clk;
    --        else
    --            cnt := cnt + 1;
    --        end if;
    --    end if;
    --end process;
    
    clk_process : process
    begin
        univ_clk <= '0';
        wait for 500ns;
        univ_clk <= '1';
        wait for 500ns;
    end process;

    mx6502 : mx65
        port map (
            clock    => univ_clk,
            reset    => mx_reset,
            ce       => '1',
            data_in  => univ_data_bus,
            data_out => mx_data_out,
            address  => univ_addr_bus,
            rw       => mx_rw,
            sync     => mx_sync,
            nmi      => '1',
            irq      => '1'
        );

    -- 64K memory
    mem : memory
        port map (
            clk      => univ_clk,
            addr     => univ_addr_bus,
            data_in  => univ_data_bus,
            data_out => ram_data_out,
            ce       => ram_ce,
            we       => univ_we
        );

    wozrom : rom
        port map (
            clock       => univ_clk,
            address     => univ_addr_bus(7 downto 0),
            ce          => rom_ce,
            data_out    => rom_data_out
        );
        
    pia : io
        port map (
            clk => univ_clk,
            rst => '1',
            cs => pia_ce,

            rs => pia_rs,

            data_in => univ_data_bus,
            data_out => pia_data_out,

            ca1_in => pia_ca1_in,
            ca2_in => pia_ca2_in,
            ca2_out => pia_ca2_out,

            cb1_in => pia_cb1_in,
            cb2_in => pia_cb2_in,
            cb2_out => pia_cb2_out,

            pa_in => pia_pa_in,
            pa_out => pia_pa_out,
            pa_oe => pia_pa_oe_out,

            pb_in => pia_pb_in,
            pb_out => pia_pb_out,
            pb_oe => pia_pb_oe_out,
    
            rw => mx_rw,

            irqa => pia_irqa,
            irqb => pia_irqb
        );

    ram_ce <= '1' WHEN univ_addr_bus(15 downto 12) = X"0" else '0';
    rom_ce <= '1' WHEN univ_addr_bus(15 downto 8) = X"FF" else '0';
    pia_ce <= '1' WHEN univ_addr_bus = X"D010" or
                       univ_addr_bus = X"D011" or
                       univ_addr_bus = X"D012" or
                       univ_addr_bus = X"D013";
    univ_we <= not mx_rw;
    with univ_addr_bus select
        pia_rs <= "00" when X"D010",
                  "01" when X"D011",
                  "10" when X"D012",
                  "11" when X"D013",
                  "00" when others;

    univ_data_bus <=
            mx_data_out WHEN mx_rw = '0' ELSE
            ram_data_out WHEN ram_ce = '1' ELSE
            rom_data_out WHEN rom_ce = '1' else
            pia_data_out WHEN pia_ce = '1' else
            "00000000";

    -- address on LEDs
    LED <= univ_addr_bus;
end architecture;