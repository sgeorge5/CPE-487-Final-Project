LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity line_buffer is
    port (
        pixel_clk : in std_logic;
        write_addr : in integer range 0 to 39;
        read_addr : in integer range 0 to 39;
        data_in : in std_logic_vector(5 downto 0);
        data_out : out std_logic_vector(5 downto 0);
        we : in std_logic
    );
end line_buffer;

architecture rtl of line_buffer is
    type line_buf_t is array (0 to 39) of std_logic_vector(5 downto 0);
    signal line_buf : line_buf_t;
begin
    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if we = '1' then
                line_buf(write_addr) <= data_in;
            end if;
        end if;
        data_out <= line_buf(read_addr);
    end process;

end architecture;