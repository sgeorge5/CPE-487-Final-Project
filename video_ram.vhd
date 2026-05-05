library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_ram is
    port (
        -- CPU port (synchronous to clk_cpu)
        clk_cpu      : in  std_logic;
        addr_cpu     : in  std_logic_vector(9 downto 0);
        data_in      : in  std_logic_vector(7 downto 0);
        data_out_cpu : out std_logic_vector(7 downto 0);
        we           : in  std_logic;

        -- VGA port (synchronous to clk_vga)
        clk_vga  : in  std_logic;
        addr_vga : in  std_logic_vector(9 downto 0);
        char_out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of video_ram is
    -- keep the same depth you used (960 entries)
    type ram_t is array (0 to 959) of std_logic_vector(7 downto 0);
    signal ram : ram_t := (others => (others => '0'));
begin

    -- CPU-side port (synchronous read/write on clk_cpu)
    process(clk_cpu)
    begin
        if rising_edge(clk_cpu) then
            if we = '1' then
                ram(to_integer(unsigned(addr_cpu))) <= data_in;
            end if;
            -- synchronous read: present data_out_cpu one cycle after address is valid
            data_out_cpu <= ram(to_integer(unsigned(addr_cpu)));
        end if;
    end process;

    -- VGA-side port (synchronous read on clk_vga)
    process(clk_vga)
    begin
        if rising_edge(clk_vga) then
            char_out <= ram(to_integer(unsigned(addr_vga)));
        end if;
    end process;

end architecture;
