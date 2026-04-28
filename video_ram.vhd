LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.numeric_std.all;


entity video_ram is
    port (
        clk_cpu : in std_logic;
        addr_cpu : in std_logic_vector(9 DOWNTO 0);
        data_in : in std_logic_vector(7 DOWNTO 0);
        data_out : out std_logic_vector(7 DOWNTO 0);
        we : in std_logic;
        clk_vga  : in  std_logic;
        addr_vga : in  std_logic_vector(9 downto 0);
        char_out : out std_logic_vector(7 downto 0)
    );
    end entity;

architecture rtl of video_ram  is 
        type ram_t is array (0 to 959) of std_logic_vector(7 DOWNTO 0);
        signal ram : ram_t := (others => (others => '0'));
begin
    process(clk_cpu)
    begin 
        if rising_edge(clk_cpu) then
            if we = '1' then
                ram(to_integer(unsigned(addr_cpu))) <= data_in;
            end if;
            data_out <= ram(to_integer(unsigned(addr_cpu)));
        end if;
    end process;
    
    process(clk_vga)
    begin
        if rising_edge(clk_vga) then
            char_out <= ram(to_integer(unsigned(addr_vga)));
        end if;
    end process;

end architecture;
