library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity io is 
    port(
        address : in std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(7 downto 0)
    );
end io;

architecture behavioral of io is 
    signal dsp_reg : std_logic_vector(7 downto 0); -- D012
    signal dspcr_reg : std_logic_vector(7 downto 0); -- D013
    signal kbd_reg : std_logic_vector(7 downto 0); -- D010
    signal kbdcr_reg : std_logic_vector(7 downto 0); -- D011
begin
    with address select
        data_out <= dsp_reg when X"D012",
                    dspcr_reg when X"D013",
                    kbd_reg when X"D010",
                    kbdcr_reg when X"D011",
                    "00000000" when others;

end architecture;