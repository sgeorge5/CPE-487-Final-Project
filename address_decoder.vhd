----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/03/2026 06:23:59 PM
-- Design Name: 
-- Module Name: address_decoder - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity address_decoder is
    port (
        addr: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        we: in STD_LOGIC;
        ram_cs: OUT STD_LOGIC;
        vram_cs: out STD_LOGIC;
        rom_cs: out STD_logic;
        uart_cs : out std_logic;
        ram_we: out std_logic;
        vram_we: out std_logic;
        uart_we: out std_logic
     ); 
    end entity;
architecture rtl of address_decoder is
    signal ram_cs_i  : std_logic;
    signal vram_cs_i : std_logic;
    signal uart_cs_i : std_logic;
begin
    ram_cs_i  <= '1' when addr(15 downto 12) = "0000" else '0';
    vram_cs_i <= '1' when addr(15 downto 10) = "000001" else '0';
    uart_cs_i <= '1' when addr(15 downto 4) = x"D01" else '0';
    rom_cs    <= '1' when addr(15 downto 8) = x"FF" else '0';

    ram_we  <= we and ram_cs_i;
    vram_we <= we and vram_cs_i;
    uart_we <= we and uart_cs_i;
    
    ram_cs  <= ram_cs_i;
    vram_cs <= vram_cs_i;
    uart_cs <= uart_cs_i;
end architecture;
