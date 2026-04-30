--TODO : MASK INPUTS
--BIT 6 AND 7 OF CTRL REGISTERS ARE READ ONLY, REFLECT THIS

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity io is 
    port(
        clk : in std_logic; -- essentially the E signal
        rst
        address : in std_logic_vector(15 downto 0);
        cs

        rs

        data_in
        data_out

        ca1_in
        ca2_in
        ca2_out

        cb1_in
        cb2_in
        cb2_out

        pa_in
        pa_out

        pb_in
        pb_out

        rw

        irqa
        irqb

        clk : in std_logic;
        address : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        kbd_in : in std_logic_vector(7 downto 0);
        strb_kbd : in std_logic; -- strobe signal
        strb_b : in std_logic; -- strobe signal
        rw : in std_logic; -- 0 for write, 1 for read

        kbd_out : out std_logic_vector(7 downto 0);
        kbd_in : in std_logic_vector(7 downto 0);

        dsp_out : out std_logic_vector(7 downto 0);
        dsp_in : in std_logic_vector(7 downto 0);

        data_out : out std_logic_vector(7 downto 0)
    );
end io;

architecture behavioral of io is
    signal ddra_reg
    signal ora_reg
    signal cra_reg

    signal ddrb_reg
    signal orb_reg
    signal crb_reg
begin
    process(rst)
    begin
        if rst = '0' then
            ddra_reg <= "00000000";
            ora_reg <= "00000000";
            cra_reg <= "00000000";

            ddrb_reg <= "00000000";
            orb_reg <= "00000000";
            crb_reg <= "00000000";

            ca1_prev
            cb1_prev
        end if;
    end process;

    process(rs)
    begin
        case rs is
            when "00" =>
                for i in 0 to 7 loop
                    if cra_reg(2) = '0' then
                        data_out(i) <= ddra_reg(i);
                    else
                        if ddra_reg(i) = '0' then
                            data_out(i) <= pa_i(i);
                        else
                            data_out(i) <= ora_reg(i);
                        end if;
                        if cs = '1' then
                            irqa <= '0'
                        end if;
                    end if;
                end loop;
            
            when "01" =>
                data_out <= cra_reg;

            when "10" =>
                for i in 0 to 7 loop
                    if crb_reg(2) = '0' then
                        data_out(i) <= ddrb_reg(i);
                    else 
                        if ddra_reg(i) = '0' then
                            data_out(i) <= pb_i(i);
                        else
                            data_out(i) <= orb_reg(i);
                        end if;
                        if cs = '1' then
                            irqb <= '0';
                        end if;
                    end if;
                end loop;

            when "11" =>
                data_out <= crb_reg;

            when others =>
                data_out <= "00000000";
        end case;
    end process;

    process(clk)
        if rising_edge(clk) then
            if rw = '0' then
                case rs is
                    when "00" =>
                        if cra_reg(2) = '0' then
                            ddra_reg <= data_in;
                        else
                            ora_reg <= data_in;
                        end if;

                    when "01" =>
                        cra_reg(4 downto 0) <= data_in(4 downto 0);
                        
                    when "10" =>
                        if crb_reg(2) = '0' then
                            ddrb_reg <= data_in;
                        else
                            orb_reg <= data_in;
                        end if;

                    when "11" =>
                        crb_reg(4 downto 0) <= data_in(4 downto 0);

                end case;
            end if;

            ca1_prev <= ca1_in;
            cb1_prev <= cb1_in;

            if ca1_in = '1' AND ca1_prev = '0' AND cra_reg(1) = '0' then
                cra_reg(6) = '1';
                if cra_reg(0) = '1' then
                    irqa <= '1';
                end if;
            elsif ca1_in = '0' AND ca1_prev = '1' AND cra_reg(1) = '1' then
                cra_reg(6) = '1';
                if cra_reg(0) = '1' then
                    irqa <= '1';
                end if;
            end if;

            
                
        end if;
    end process;

end architecture;

architecture behavioral of io is 
    signal dsp_reg : std_logic_vector(7 downto 0); -- D012
    signal dspcr_reg : std_logic_vector(7 downto 0); -- D013
    signal kbd_reg : std_logic_vector(7 downto 0); -- D010
    signal kbdcr_reg : std_logic_vector(7 downto 0); -- D011

    -- these registers go unused, remnant of the 6821 bidirectional bus
    -- still here to give WOZMON something to write to
    signal ddrdsp_reg : std_logic_vector(7 downto 0); -- same loc as dsp_reg
    signal ddrkbd_reg : std_logic_vector(7 downto 0); -- same loc as kbd_reg
    signal kbd_in_mask : std_logic_vector(7 downto 0);
    signal dsp_in_mask : std_logic_vector(7 downto 0);

    signal kbd_in : std_logic_vector(7 downto 0);
    signal dsp_out : std_logic_vector(7 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            strb_kbd_last <= strb_kbd; 

            if rw = '0' then
                case address is 
                    when X"D012" =>
                        if dspcr_reg(2) = '0' then
                            ddrdsp_reg <= data_in;
                        else
                            dsp_reg <= data_in;
                        end if;
                    when X"D013" =>
                        dspcr_reg <= data_in;
                    when X"D010" =>
                        if kbdcr_reg(2) = '0' then
                            ddrkbd_reg <= data_in;
                        else
                            kbd_reg <= data_in;
                        end if;
                    when X"D011" =>
                        kbdcr_reg <= data_in;
                end case;
            end if;
            
            if ca1_in = '1' AND ca1_in_last = '0' AND kbdcr_reg(1) = '1' then
                kbd_reg <= kbd_in;
                kbdcr_reg(7) <= '1';
            else if ca1_in = '0' AND ca1_in_last = '1' then
                kbd_reg <= kbd_in;
                kbdcr_reg(7) <= '1';
            end if;

            if cb1_in = '1' AND cb1_in_last = '0' AND dspcr_reg(1) = '1' then
                dsp_reg <= dsp_in;
                dspcr_reg(7) <= '1';
            else if cb1_in = '0' AND cb1_in_last = '1' then
                dsp_reg <= dsp_in;
                dspcr_reg(7) <= '1';
            end if;

            if ca2_in = '1' AND ca2_in_last = '0' AND kbdcr_reg(1) = '1' then
                kbd_reg <= kbd_in;
                kbdcr_reg(6) <= '1';
            else if ca1_in = '0' AND ca1_in_last = '1' then
                kbd_reg <= kbd_in;
                kbdcr_reg(6) <= '1';
            end if;
        end if;

        if rw = '1' then
            case address is 
                when X"D012" =>
                    if dspcr_reg(2) = '0' then
                        data_out <= ddrdsp_reg;
                    else
                        data_out <= dsp_reg;
                        dspcr_reg(7) <= '0';
                        dspcr_reg(6) <= '0';
                    end if;
                when X"D013" =>
                    data_out <= dspcr_reg;
                when X"D010" =>
                    if kbdcr_reg(2) = '0' then
                        data_out <= ddrkbd_reg;
                    else
                        data_out <= kbd_reg;
                        kbdcr_reg(7) <= '0';
                        kbdcr_reg(6) <= '0';
                    end if;
                when X"D011" =>
                    data_out <= kbdcr_reg;
            end case;
        end if;
    end process;

    process(kbd_reg, ddrkbd_reg)
    begin
        for i in 0 to 7 loop
            if ddrkbd_reg(i) = '1' then
                kbd_out(i) <= kbd_reg(i);
                kbd_in_mask(i) <= 'Z';
            else
                kbd_out(i) <= 'Z';
                kbd_in_mask(i) <= kbd_reg(i)
            end if;
        end loop;
    end process;

    process(dsp_reg, ddrdsp_reg)
    begin
        for i in 0 to 7 loop
            if ddrdsp_reg(i) = '1' then
                dsp_out(i) <= dsp_reg(i);
                dsp_in_mask(i) <= 'Z';
            else
                dsp_out(i) <= 'Z';
                dsp_in_mask(i) <= dsp_reg(i)
            end if;
        end loop;
    end process;
end architecture;