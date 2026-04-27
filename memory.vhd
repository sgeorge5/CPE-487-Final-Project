library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    port (
        clk      : in  std_logic;
        addr     : in  std_logic_vector(15 downto 0);
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        we       : in  std_logic
    );
end entity;

architecture rtl of memory is
    type ram_t is array (0 to 65535) of std_logic_vector(7 downto 0);
    signal ram : ram_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= data_in;
            end if;
            data_out <= ram(to_integer(unsigned(addr)));
        end if;
    end process;
end architecture;
