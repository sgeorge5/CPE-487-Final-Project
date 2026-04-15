LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY register_file IS
    PORT (
        CLK, RW, RST : IN STD_LOGIC;

        DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        REG_SEL : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        ACC, X, Y, SPTR, STAT  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        PC : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END register_file;

ARCHITECTURE Behavioral OF register_file IS
    SIGNAL REGISTER_BUS : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    PROCESS(CLK) IS
    BEGIN
        IF RST = '1' THEN
            ACC <= (OTHERS => '0');
            X <= (OTHERS => '0');
            Y <= (OTHERS => '0');
            SPTR <= (OTHERS => '0');
            STAT <= (OTHERS => '0');
            PC <= (OTHERS => '0');
        ELSIF RISING_EDGE(CLK) THEN
            IF RW = '1' THEN
                CASE REG_SEL IS
                    WHEN "000" => ACC <= DATA;
                    WHEN "001" => X <= DATA;
                    WHEN "010" => Y <= DATA;
                    WHEN "011" => SPTR <= DATA;
                    WHEN "100" => STAT <= DATA;
                    WHEN OTHERS => NULL
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END Behavioral;