LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY register IS
    PORT (
        CLK : IN STD_LOGIC;

        A : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        B : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

        WE : IN STD_LOGIC;
        RST : IN STD_LOGIC
    );
END register;

ARCHITECTURE Behavioral OF register IS
BEGIN
    PROCESS(CLK) IS
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RST = '1' THEN
                B <= (OTHERS => '0');
            ELSIF WE = '1' THEN
                B <= A;
            END IF;
        END IF;
    END PROCESS;
END Behavioral;