library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity char_rom is
    port (
        clk  : in  std_logic;
        addr : in  std_logic_vector(10 downto 0);  -- char_code(7:0) & row(2:0)
        data : out std_logic_vector(7 downto 0)    -- 8 pixels for that row
    );
end entity;

architecture rtl of char_rom is

    -- 2048 x 8-bit ROM (256 chars × 8 rows)
    type rom_t is array (0 to 2047) of std_logic_vector(7 downto 0);

    -- NOTE:
    -- This is a placeholder font. Replace or expand as needed.
    -- Each character has 8 rows. For example:
    --   Address = char_code * 8 + row_index
    --
    -- Below is a minimal ASCII set with a few characters defined.
    -- You can fill in more glyphs later.

    signal rom : rom_t := (
        -- SPACE (0x20)
        32*8 + 0 => "00000000",
        32*8 + 1 => "00000000",
        32*8 + 2 => "00000000",
        32*8 + 3 => "00000000",
        32*8 + 4 => "00000000",
        32*8 + 5 => "00000000",
        32*8 + 6 => "00000000",
        32*8 + 7 => "00000000",

        -- 'A' (0x41)
        65*8 + 0 => "00011000",
        65*8 + 1 => "00100100",
        65*8 + 2 => "01000010",
        65*8 + 3 => "01000010",
        65*8 + 4 => "01111110",
        65*8 + 5 => "01000010",
        65*8 + 6 => "01000010",
        65*8 + 7 => "00000000",

        -- 'B' (0x42)
        66*8 + 0 => "01111100",
        66*8 + 1 => "01000010",
        66*8 + 2 => "01000010",
        66*8 + 3 => "01111100",
        66*8 + 4 => "01000010",
        66*8 + 5 => "01000010",
        66*8 + 6 => "01111100",
        66*8 + 7 => "00000000",

        -- 'C' (0x43)
        67*8 + 0 => "00111100",
        67*8 + 1 => "01000010",
        67*8 + 2 => "01000000",
        67*8 + 3 => "01000000",
        67*8 + 4 => "01000000",
        67*8 + 5 => "01000010",
        67*8 + 6 => "00111100",
        67*8 + 7 => "00000000",

        -- DEFAULT for undefined characters
        others => "00000000"
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            data <= rom(to_integer(unsigned(addr)));
        end if;
    end process;

end architecture;
