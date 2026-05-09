LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity uart is
    port (
        CLK_IN : in std_logic; --100MHz
        UART_IN : in std_logic;
        ASCII_OUT : out std_logic_vector(7 downto 0);
        STROBE : out std_logic
    );
end uart;

architecture behavioral of uart is
    signal uart_sync    : std_logic_vector(1 downto 0) := "11";
    signal uart_stable  : std_logic := '1';
    signal uart_prev    : std_logic := '1';

    signal bit_count    : integer range 0 to 9 := 0; --start bit (0) + 8 bits + stop bit (1)
    signal sync         : integer range 0 to 650 := 0; --counter for 9600 baud with 16x oversampling
    signal sync_count   : integer range 0 to 15 := 0;

    type state_t is (IDLE, CAPTURE);
    signal state : state_t := IDLE; 

    signal shift_reg10   : std_logic_vector(9 downto 0);
    signal captured_data : std_logic_vector(9 downto 0);
    signal data_ready    : std_logic := '0';
begin
    process (CLK_IN)
    begin
        if rising_edge(CLK_IN) then
            uart_sync <= uart_sync(0) & UART_IN;
            uart_stable <= uart_sync(1);
            uart_prev <= uart_stable;

            if data_ready = '1' then
                if captured_data(9) = '1' and captured_data(0) = '0' then
                    ASCII_OUT <= captured_data(8 downto 1);
                    STROBE <= '1';
                end if;
                data_ready <= '0';
            else
                STROBE <= '0';
            end if;

            case state is
                when IDLE =>
                    if uart_prev = '1' and uart_stable = '0' then
                        sync_count <= 0;
                        sync <= 0;
                        bit_count <= 0;
                        state <= CAPTURE;
                    end if;

                when CAPTURE =>
                    --end of sampling tick
                    if sync = 650 then  
                        if sync_count = 15 then
                            sync_count <= 0;

                            if bit_count = 9 then
                                bit_count <= 0;
                                captured_data <= shift_reg10;
                                data_ready <= '1';
                                state <= IDLE;
                            else
                                bit_count <= bit_count + 1;
                            end if;

                        elsif sync_count = 7 then
                            if bit_count = 0 and uart_stable /= '0' then
                                state <= IDLE;
                            else
                                shift_reg10 <= uart_stable & shift_reg10(9 downto 1);           
                            end if;
                            sync_count <= sync_count + 1;
                        else
                            sync_count <= sync_count + 1;
                        end if; 
                        
                        sync <= 0;
                    else 
                        sync <= sync + 1;
                    end if;
          
            end case;

        end if;

    end process;

end architecture;