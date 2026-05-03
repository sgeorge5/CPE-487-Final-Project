----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/03/2026 06:44:47 PM
-- Design Name: 
-- Module Name: memory_map - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory_map is
 Port ( 
  clk: in STD_LOGIC;
  addr: in STD_LOGIC_VECTOR(15 DOWNTO 0);
  data_in: in STD_LOGIC_VECTOR(7 DOWNTO 0);
  data_out: out STD_LOGIC_VECTOR(7 DOWNTO 0);
  we: in STD_LOGIC;
  ram_cs: in STD_LOGIC;
  vram_cs: in STD_LOGIC;
  rom_cs: in STD_LOGIC;
  uart_cs: in STD_LOGIC;
  ram_data: in STD_LOGIC_VECTOR(7 DOWNTO 0);
  vram_data: in STD_LOGIC_VECTOR(7 DOWNTO 0);
  rom_data: in STD_LOGIC_VECTOR(7 DOWNTO 0);
  uart_data: in STD_LOGIC_VECTOR(7 DOWNTO 0)
 );
end entity;

architecture rtl of memory_map is

begin
      process(ram_cs, vram_cs, rom_cs, uart_cs, ram_data, vram_data, rom_data, uart_data)
      begin
        if ram_cs = '1' then
            data_out <= ram_data;
        elsif vram_cs = '1' then
            data_out <= vram_data;
        elsif rom_cs = '1' then
            data_out <= rom_data;
        elsif uart_cs = '1' then
            data_out <= uart_data;
        else
            data_out <= (others => '0');
        end if;
end process;
end architecture;
