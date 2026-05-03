----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/03/2026 06:56:40 PM
-- Design Name: 
-- Module Name: rom_wrapper - Behavioral
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

entity rom_wrapper is
   Port ( 
    clk: in STD_LOGIC;
    addr: in std_logic_vector(15 DOWNTO 0);
    ce: in std_logic;
    data_out: out STD_LOGIC_VECTOR(7 DOWNTO 0)
    
   );
end entity;

architecture rtl of rom_wrapper is
    signal rom_addr: std_logic_vector(7 DOWNTO 0);
    signal rom_data: STD_LOGIC_VECTOR(7 DOWNTO 0);
begin
    rom_addr <= addr(7 DOWNTO 0);
    
    rom_inst: entity work.rom
        port map(
            clock => clk,
            address => rom_addr,
            ce => ce,
            data_out => rom_data
         );
         data_out <= rom_data;

end architecture;
