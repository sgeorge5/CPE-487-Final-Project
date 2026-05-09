LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity dsp_shift_register is
    port (
        clr_screen              : in std_logic;
        pixel_clk               : in std_logic;
        is_first_scanline_of_row: in std_logic;
        h_blank                 : in std_logic;
        v_blank                 : in std_logic;
        buf_write_addr          : out integer range 0 to 39;
        buf_write_data          : out std_logic_vector(5 downto 0);
        buf_we                  : out std_logic;
        ready_data_accept       : out std_logic;
        data_available          : in std_logic;
        char_code_in            : in std_logic_vector(6 downto 0)
    );
end dsp_shift_register;

architecture behavioral of dsp_shift_register is

type r_shift_t is array(1023 downto 0) of std_logic_vector(6 downto 0);
type state_type is (NORMAL, CR, SCROLL, CLEARING);

signal r_shift          : r_shift_t := (1023 => "0000000", others => "1000001");

signal state            : state_type := NORMAL;

signal h_blank_prev     : std_logic := '0'; 
signal v_blank_prev     : std_logic := '0';

signal row_counter      : integer range 0 to 23 := 0;
signal cursor_x         : integer range 0 to 39 := 0;

signal burst_ptr        : integer range 0 to 104 := 0;
signal v_burst_done     : std_logic := '0';

signal cursor_inject    : std_logic := '0';

signal scroll_pending   : std_logic := '0';

signal clear_counter : integer range 0 to 1024 := 0;

begin
    process (pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if clr_screen = '1' and state /= CLEARING then
                state <= CLEARING;
                clear_counter <= 1024;
            end if;
            
            h_blank_prev <= h_blank;
            v_blank_prev <= v_blank;
        	
        	if state /= CLEARING then
                --normal register shift
                if h_blank = '1' and h_blank_prev = '0' then
    
                    --vertical blanking (once per frame)
                    --trigger 64 pulses when v-blank starts to wrap back 
                    -- around for next frame
                    --add 40 pulses if we are scrolling
                    if v_blank = '1' and v_burst_done = '0' then
                        burst_ptr <= 64;
                        if scroll_pending = '1' then
                            burst_ptr <= 64 + 40;
                            state <= SCROLL;
                            scroll_pending <= '0';
                        end if;
                        v_burst_done <= '1';
    
                    --visible rows
                    --only trigger if not vblanking
                    elsif v_blank = '0' and is_first_scanline_of_row = '1' then
                        burst_ptr <= 40;
                        v_burst_done <= '0';
    
                    else
                        --scanlines 1-7 or middle of v-blank
                        burst_ptr <= 0;
    
                    end if;
                
                end if;
    
                ready_data_accept <= '0';
    
                if burst_ptr > 0 then
                    --write to line buffer when not in vblank
                    buf_we <= '0';
                    if v_blank = '0' and burst_ptr <= 40 then
                        buf_write_addr <= 40 - burst_ptr;
                        buf_write_data <= r_shift(1023)(6 downto 1);
                        buf_we         <= '1';
                    end if;
    
                    if v_blank = '1' then
                        r_shift(0)(6 downto 0) <= "1000001";
                        r_shift(1023 downto 1) <= r_shift (1022 downto 0);
                    else
                        r_shift(0) <= r_shift(1023);
                        r_shift(1023 downto 1) <= r_shift(1022 downto 0);
                    end if;
                    
                    if burst_ptr = 1 and v_blank = '1' and state = SCROLL then
                        --cursor_inject <= '1';
                        state <= NORMAL;
                    end if;
    
                    if cursor_inject = '1' then
                        r_shift(0) <= "0000000";
                        cursor_inject <= '0';
                    end if;
    
                    if v_blank = '0' then
                        --logic for writing to shift register
                        if state = NORMAL then
                            if r_shift(1023)(0) = '0' and data_available = '1' then
                                --only print if not control character
                                ready_data_accept <= '1';
                                
                                if char_code_in(6) = '1' or char_code_in(5) = '1' then
                                    r_shift(0)(6 downto 1) <= char_code_in(5 downto 0);
                                    r_shift(0)(0) <= '1';
                                    cursor_inject <= '1';
                                    
                                    if cursor_x = 39 then
                                        cursor_x <= 0;
                                        if row_counter = 23 then
                                            scroll_pending <= '1';
                                        else
                                            row_counter <= row_counter + 1;
                                        end if;
                                    else
                                        cursor_x <= cursor_x + 1;
                                    end if;
                                    
                                elsif char_code_in(3 downto 0) = "1101" then
                                    r_shift(0) <= "1000001";
                                    state <= CR;
                                    ready_data_accept <= '0'; --set RDA back to 0 until CR is done
                                end if;
                                            
                            end if;
        
                        elsif state = CR then
                            --STOP typing and wait for the row to end
                            if burst_ptr = 1 then
                                cursor_x <= 0;
                                if row_counter = 23 then
                                    cursor_inject <= '1';
                                    scroll_pending <= '1';
                                    state <= SCROLL;
                                else
                                    cursor_inject <= '1';
                                    row_counter <= row_counter + 1;
                                    state <= NORMAL;
                                end if;
                                state <= NORMAL;
                                ready_data_accept <= '1';
                            end if;
        
                        end if;
                        
                    end if;
    
                    burst_ptr <= burst_ptr - 1;
    
                end if;
            else
                if clear_counter > 0 then
                   r_shift(0) <= "1000001";
                   r_shift(1023 downto 1) <= r_shift(1022 downto 0);
                   clear_counter <= clear_counter - 1;
                else
                   if v_blank = '1' and v_blank_prev = '0' then  --wait for vblank to perform full screen reset
                       r_shift(1023) <= "0000000";
                       cursor_inject <= '0';
                       scroll_pending <= '0';
                       cursor_x <= 0;
                       row_counter <= 0;
                       v_burst_done <= '1';
                       burst_ptr <= 0;
                       state <= NORMAL;
                   end if;
                   
                end if;
                
            end if;

        end if;
        
    end process;

end architecture;