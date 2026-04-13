LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY control IS 
    PORT (
        WE : OUT STD_LOGIC;
        REG_SEL : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        ALU_SEL : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

        OP : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END control;

ARCHITECTURE Behavioral OF control IS
    TYPE STATE IS (T0, T1, T2, T3, T4, T5, T6);
    SIGNAL PS, NS : STATE;
BEGIN
    PROCESS(PS, OP) IS
    BEGIN
        CASE T0 IS;
            REG_SEL <= 
        CASE T1 IS;
        END CASE;
    END PROCESS;

END Behavioral;