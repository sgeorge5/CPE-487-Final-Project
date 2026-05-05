library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    port (
        clk      : in  std_logic;
        addr     : in  std_logic_vector(15 downto 0);
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        ce       : in  std_logic;
        we       : in  std_logic
    );
end entity;

architecture rtl of memory is
    -- 4K x 8 RAM
    type ram_t is array (0 to 4095) of std_logic_vector(7 downto 0);
    signal ram : ram_t := (others => (others => '0'));

    -- internal registered output
    signal data_out_r : std_logic_vector(7 downto 0) := (others => '0');

    -- local address width (12 bits for 4096 entries)
    constant ADDR_WIDTH : integer := 12;
begin

    -- Synchronous RAM: CPU clock domain
    -- Behavior: synchronous write when we='1' and ce='1'.
    --           synchronous read when ce='1' and we='0' (data_out_r <= ram[addr]).
    --           when we='1' (write cycle) data_out_r is not updated (no read).
    -- If you prefer read-during-write to return new data or old data, change logic accordingly.
    process(clk)
        variable addr_index : integer;
    begin
        if rising_edge(clk) then
            if ce = '1' then
                -- slice address to RAM depth
                addr_index := to_integer(unsigned(addr(ADDR_WIDTH-1 downto 0)));

                if we = '1' then
                    -- write cycle (synchronous)
                    ram(addr_index) <= data_in;
                    -- data_out_r unchanged on write cycle (explicit)
                else
                    -- read cycle (synchronous)
                    data_out_r <= ram(addr_index);
                end if;
            else
                -- chip disabled: drive a defined value (here zeros)
                data_out_r <= (others => '0');
            end if;
        end if;
    end process;

    data_out <= data_out_r;

end architecture;
