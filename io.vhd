--TODO : MASK INPUTS
--BIT 6 AND 7 OF CTRL REGISTERS ARE READ ONLY, REFLECT THIS

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity io is 
    port(
        clk : in std_logic; -- essentially the E signal
        rst : in std_logic;
        cs : in std_logic;

        rs : in std_logic_vector(1 downto 0);

        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);

        ca1_in : in std_logic;
        ca2_in : in std_logic;
        ca2_out : out std_logic;

        cb1_in : in std_logic;
        cb2_in : in std_logic;
        cb2_out : out std_logic;

        pa_in : in std_logic_vector(7 downto 0);
        pa_out : out std_logic_vector(7 downto 0);
        pa_oe : out std_logic_vector(7 downto 0);

        pb_in : in std_logic_vector(7 downto 0);
        pb_out : out std_logic_vector(7 downto 0);
        pb_oe : out std_logic_vector(7 downto 0);

        rw : in std_logic;

        irqa : out std_logic;
        irqb : out std_logic
    );
end io;

architecture behavioral of io is
    signal ddra_reg : std_logic_vector(7 downto 0);
    signal ora_reg : std_logic_vector(7 downto 0);
    signal cra_reg : std_logic_vector(5 downto 0);
    signal pa_read : std_logic;

    signal ddrb_reg : std_logic_vector(7 downto 0);
    signal orb_reg : std_logic_vector(7 downto 0);
    signal crb_reg : std_logic_vector(5 downto 0);
    signal pb_write : std_logic;

    signal irqa1 : std_logic;
    signal irqa2 : std_logic;

    signal irqb1 : std_logic;
    signal irqb2 : std_logic;

    signal ca1_prev : std_logic;
    signal cb1_prev : std_logic;

    signal ca2 : std_logic;
    signal cb2 : std_logic;
    signal ca2_prev : std_logic;
    signal cb2_prev : std_logic;

    signal desel_pulse : std_logic;
begin
    process(rs, cs, pa_in, ora_reg, cra_reg, ddra_reg, irqa1, irqa2,
                    pb_in, orb_reg, crb_reg, ddrb_reg, irqb1, irqb2)
    begin
        case rs is
            when "00" =>
                for i in 0 to 7 loop
                    if cra_reg(2) = '0' then
                        data_out(i) <= ddra_reg(i);
                        pa_read <= '0';
                    else
                        if ddra_reg(i) = '0' then
                            data_out(i) <= pa_in(i);
                        else
                            data_out(i) <= ora_reg(i);
                        end if;
                        if cs = '1' then
                            irqa1 <= '0';
                            irqa2 <= '0';
                        end if;
                        pa_read <= cs;
                    end if;
                end loop;
            
            when "01" =>
                data_out <= irqa1 & irqa2 & cra_reg;
                pa_read <= '0';

            when "10" =>
                for i in 0 to 7 loop
                    if crb_reg(2) = '0' then
                        data_out(i) <= ddrb_reg(i);
                    else 
                        if ddrb_reg(i) = '0' then
                            data_out(i) <= pb_in(i);
                        else
                            data_out(i) <= orb_reg(i);
                        end if;
                        if cs = '1' then
                            irqb1 <= '0';
                            irqb2 <= '0';
                        end if;
                    end if;
                end loop;
                pa_read <= '0';

            when "11" =>
                data_out <= irqb1 & irqb2 & crb_reg;
                pa_read <= '0';

            when others =>
                data_out <= "00000000";
                pa_read <= '0';
        end case;
    end process;

    process(rst, clk)
    begin
        if rst = '0' then
            irqa1 <= '0';
            irqa2 <= '0';
            
            irqb1 <= '0';
            irqb2 <= '0';
        elsif rising_edge(clk) then
            if pa_read = '1' then
                irqa1 <= '0';
                irqa2 <= '0';
            end if;

            if pb_read = '1' then
                irqb1 <= '0';
                irqb2 <= '0';
            end if;
        end if;
    end process;

    process(rst, clk)
    begin
        if rst = '0' then
            ddra_reg <= "00000000";
            ora_reg <= "00000000";
            cra_reg <= "000000";
            pa_read <= '0';

            ddrb_reg <= "00000000";
            orb_reg <= "00000000";
            crb_reg <= "000000";
            pb_read <= '0';
        
            ca1_prev <= '0';
            cb1_prev <= '0';
            
            ca2 <= '0';
            cb2 <= '0';
            ca2_prev <= '0';
            cb2_prev <= '0';
        end if;
        
        if rising_edge(clk) then
            if cs = '1' AND rw = '0' then
                case rs is
                    when "00" =>
                        if cra_reg(2) = '0' then
                            ddra_reg <= data_in;
                        else
                            ora_reg <= data_in;
                        end if;
                        pb_write <= '0';

                    when "01" =>
                        cra_reg(5 downto 0) <= data_in(5 downto 0);
                        pb_write <= '0';
                        
                    when "10" =>
                        if crb_reg(2) = '0' then
                            ddrb_reg <= data_in;
                            pb_write <= '0';
                        else
                            orb_reg <= data_in;
                            pb_write <= '1';
                        end if;

                    when "11" =>
                        crb_reg(5 downto 0) <= data_in(5 downto 0);
                        pb_write <= '0';
                        
                    when others =>
                        pb_write <= '0';

                end case;
            end if;
            if cs = '0' then
                desel_pulse <= '1'
            end if;
        end if;
        ca1_prev <= ca1_in;
        ca2_prev <= ca2;
           
        if cra_reg(0) = '1' then --enable IRQA(B)1
            if ca1_in = '1' AND ca1_prev = '0' AND cra_reg(1) = '1' then
                irqa1 <= '1';
            elsif ca1_in = '0' AND ca1_prev = '1' AND cra_reg(1) = '0' then
                irqa1 <= '1';
            end if;
        end if;

        if cra_reg(5) = '0' then --enable IRQA(B)2 (only for CA(B)2 as input)
            if cra_reg(3) = '1' then
                if ca2_in = '1' AND ca2_prev = '0' AND cra_reg(4) = '1' then
                    irqa2 <= '1';
                elsif ca2_in = '0' AND ca2_prev = '1' AND cra_reg(4) = '0' then
                    irqa2 <= '1';
                end if;
            end if;
        elsif cra_reg(5) = '1' then
            irqa2 <= '0';
            if cra_reg(4) = '0' then
                if cra_reg(3) = '0' then
                    if falling_edge(clk) AND pa_read = '1' then
                        ca2 <= '0';
                    end if;
                    if ca1_in = '1' AND ca1_prev = '0' AND cra_reg(1) = '1' then
                        ca2 <= '1';
                    elsif ca1_in = '0' AND ca1_prev = '1' AND cra_reg(1) = '0' then
                        ca2 <= '1';
                    end if;
                elsif cra_reg(3) = '1' then
                    if falling_edge(clk) AND pa_read = '1' then
                        ca2 <= '0';
                    elsif falling_edge(clk) AND cs = '0' then
                        ca2 <= '1';
                    end if;
                end if;
            elsif cra_reg(4) = '1' then
                if cra_reg(3) = '1' then
                    ca2 <= '1';
                elsif cra_reg(3) = '0' then
                    ca2 <= '0';
                end if;
            end if;
        end if;

        cb1_prev <= cb1_in;
        cb2_prev <= cb2;
           
        if crb_reg(0) = '1' then --enable IRQA(B)1
            if cb1_in = '1' AND cb1_prev = '0' AND crb_reg(1) = '1' then
                irqb1 <= '1';
            elsif cb1_in = '0' AND cb1_prev = '1' AND crb_reg(1) = '0' then
                irqb1 <= '1';
            end if;
        end if;

        if crb_reg(5) = '0' then --enable IRQA(B)2 (only for CA(B)2 as input)
            if crb_reg(3) = '1' then
                if cb2 = '1' AND cb2_prev = '0' AND crb_reg(4) = '1' then
                    irqb2 <= '1';
                elsif cb2 = '0' AND cb2_prev = '1' AND crb_reg(4) = '0' then
                    irqb2 <= '1';
                end if;
            end if;
        elsif crb_reg(5) = '1' then
            irqb2 <= '0';
            if crb_reg(4) = '0' then
                if crb_reg(3) = '0' then
                    if rising_edge(clk) AND pb_write = '1' then
                        cb2 <= '0';
                    end if;
                    if cb1_in = '1' AND cb1_prev = '0' AND crb_reg(1) = '1' AND irqb1 = '0' then
                        cb2 <= '1';
                    elsif cb1_in = '0' AND cb1_prev = '1' AND crb_reg(1) = '0' AND irqb1 = '0' then
                        cb2 <= '1';
                    end if;
                elsif crb_reg(3) = '1' then
                    if rising_edge(clk) AND pb_write = '1' then
                        cb2 <= '0';
                    elsif rising_edge(clk) AND desel_pulse = '1' then
                        cb2 <= '1';
                    end if;
                end if;
            elsif crb_reg(4) = '1' then
                if crb_reg(3) = '1' then
                    cb2 <= '1';
                elsif crb_reg(3) = '0' then
                    cb2 <= '0';
                end if;
            end if;
        end if;
    end process;

    pa_out <= ora_reg;
    pa_oe <= ddra_reg;

    pb_out <= orb_reg;
    pb_oe <= ddrb_reg;
end architecture;