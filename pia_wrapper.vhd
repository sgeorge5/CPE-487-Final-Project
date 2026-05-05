--claude + deepseek wanted this when I sent the image that cronk sent about the keyboard + uart stuff
-- pia_wrapper.vhd
-- Emulates a 6821 PIA for keyboard input only
-- Maps to Apple-1 addresses: 0xD010 (PIA Data A / Control A)
--                          0xD011 (PIA Data B / Control B) - used for status
--
-- WOZMON expects:
--   Read 0xD011 -> bit 0 = 1 when key available
--   Read 0xD010 -> returns ASCII key, clears status
--   Write 0xD010 -> not used (display output is separate)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pia_wrapper is
    port (
        clk       : in  std_logic;          -- system clock (100 MHz)
        reset     : in  std_logic;
        
        -- CPU interface
        addr      : in  std_logic_vector(15 downto 0);
        data_in   : in  std_logic_vector(7 downto 0);
        data_out  : out std_logic_vector(7 downto 0);
        we        : in  std_logic;           -- write enable
        cs        : in  std_logic;           -- chip select (from address decoder)
        
        -- UART RX input
        uart_rx_char : in  std_logic_vector(7 downto 0);
        uart_rx_ready: in  std_logic
    );
end entity;

architecture rtl of pia_wrapper is
    -- Registers
    signal pia_data_a   : std_logic_vector(7 downto 0) := (others => '0');  -- keyboard data
    signal pia_control_a: std_logic_vector(7 downto 0) := (others => '0');  -- not used, mirrors Apple-1
    signal pia_data_b   : std_logic_vector(7 downto 0) := (others => '0');  -- status/flags
    signal pia_control_b: std_logic_vector(7 downto 0) := (others => '0');
    
    -- Status flags
    signal key_ready    : std_logic := '0';   -- CA1 / IRQ flag
    signal data_read    : std_logic := '0';   -- has data been read?
    
    -- Registered outputs
    signal data_out_reg : std_logic_vector(7 downto 0) := (others => '0');
    
begin
    
    process(clk, reset)
    begin
        if reset = '1' then
            pia_data_a    <= (others => '0');
            pia_control_a <= (others => '0');
            pia_data_b    <= (others => '0');
            pia_control_b <= (others => '0');
            key_ready     <= '0';
            data_read     <= '0';
            data_out_reg  <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Handle new character from UART (latched)
            if uart_rx_ready = '1' and key_ready = '0' then
                pia_data_a <= uart_rx_char;
                key_ready  <= '1';
                data_read  <= '0';
            end if;
            
            -- CPU access when selected
            if cs = '1' then
                if we = '1' then
                    -- Write to PIA
                    case addr(0) is
                        when '0' =>   -- 0xD010: Data A / Control A
                            if data_in(2) = '1' then
                                -- Control register write (bit 2 = 1 means control reg)
                                pia_control_a <= data_in;
                            else
                                -- Data register write (not normally used for keyboard)
                                -- Apple-1 uses this for display sometimes, but we ignore
                                pia_data_a <= data_in;
                            end if;
                        when '1' =>   -- 0xD011: Data B / Control B
                            if data_in(2) = '1' then
                                pia_control_b <= data_in;
                            else
                                pia_data_b <= data_in;
                            end if;
                        when others => null;
                    end case;
                    
                else
                    -- Read from PIA
                    case addr(0) is
                        when '0' =>   -- 0xD010: Data A
                            if pia_control_a(2) = '1' then
                                -- Reading Control Register A
                                data_out_reg <= pia_control_a;
                            else
                                -- Reading Data Register A (keyboard character)
                                data_out_reg <= pia_data_a;
                                -- Clear key_ready on read (CA1 edge detection)
                                key_ready <= '0';
                            end if;
                            
                        when '1' =>   -- 0xD011: Data B / Status
                            if pia_control_b(2) = '1' then
                                -- Reading Control Register B
                                data_out_reg <= pia_control_b;
                            else
                                -- Reading Data Register B (status)
                                -- Bit 0 = CA1 flag (key ready)
                                data_out_reg <= (0 => key_ready, others => '0');
                            end if;
                            
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    data_out <= data_out_reg;
    
end architecture;
