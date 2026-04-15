LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY control IS 
    PORT (
        RW  : OUT STD_LOGIC;                        --select read or write mode to addr bus
        REG_SEL     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);     --select register
        ALU_SEL     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);     --select ALU operational mode
        SYNC        : OUT STD_LOGIC;                        --SYNC pin high when in FETCH state T0

        RST         : IN STD_LOGIC;
        ADDR_BUS    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);    --16-bit address bus
        DATA_BUS    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);      --8-bit data bus
    );
END control;

ARCHITECTURE Behavioral OF control IS
    TYPE STATE IS (T0, T1, T2, T3, T4, T5, T6);
    SIGNAL PS, NS       : STATE;
    SIGNAL INSTR_REG    : STD_LOGIC_VECTOR(7 DOWNTO 0);     --instruction register internal to control logic
    SIGNAL PC_REG       : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL PC_NEXT      : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN
    PROCESS(CLK, RST) IS
    BEGIN
        IF RST = '1' THEN
            PS <= 0;
        ELSIF RISING_EDGE(CLK) THEN
            PS <= NS;

            IF PS = T0 THEN
                INSTR_REG <= DATA_BUS;
            END IF;

            PC_REG <= PC_NEXT;
        END IF
    END PROCESS;

    PROCESS(PS, INSTR_REG) IS
    --TODO: add defaults to avoid latching 
    BEGIN
        CASE PS IS
            WHEN T0 =>       
                ADDR_BUS <= PC_REG;                     --fetch instruction
                READ_WRITE <= '1'; 
                SYNC <= '1';  
                NS <= T1;

            WHEN T1 =>                                
                CASE INSTR_REG IS
                    WHEN X"69" THEN                     --ADC IMM 1/1
                        ADDR_BUS <= PC_REG + 1;
                        ALU_SEL <= "000";
                        REG_SEL <= "000";
                        READ_WRITE <= '1';
                        PC_NEXT <= PC_REG + 2;
                        NS <= T0;

                    WHEN X"EA" THEN                     --NOP IMP 1/1
                        PC_NEXT <= PC_REG + 1;
                        NS <= T0;

                    WHEN X"A9" THEN                     --LDA IMM 1/1
                        ADDR_BUS <= PC_REG + 1;
                        ALU_SEL <= "1001";
                        REG_SEL <= "000";
                        READ_WRITE <= '1';
                        PC_NEXT <= PC_REG + 2;
                        NS <= T0;

                    WHEN X"A2" THEN                     --LDX IMM 1/1
                        ADDR_BUS <= PC_REG + 1;
                        ALU_SEL <= "1001";
                        REG_SEL <= "001";
                        READ_WRITE <= '1';
                        PC_NEXT <= PC_REG + 2;
                        NS <= T0;

                    WHEN X"A0" THEN                     --LDY IMM 1/1
                        ADDR_BUS <= PC_REG + 1;
                        ALU_SEL <= "1001";
                        REG_SEL <= "010";
                        READ_WRITE <= '1';
                        PC_NEXT <= PC_REG + 2;
                        NS <= T0;

                    WHEN X"E8" THEN                     --INX IMP 1/1
                        ALU_SEL <= "1010";
                        REG_SEL <= "001";
                        READ_WRITE <= '1';
                        PC_NEXT <= PC_REG + 1;
                        NS <= T0;

                    WHEN X"C8" THEN                     --INY IMP 1/1
                        ALU_SEL <= "1010";
                        REG_SEL <= "010";
                        READ_WRITE <= '1';
                        PC_NEXT <= PC_REG + 1;
                    
                    WHEN X"4C" THEN                     --JMP ABS 1/2
                        ADDR_BUS <= PC_REG;
                        TMP_LOW <= DATA_BUS;
                        PC_NEXT <= PC_REG + 1;
                        NS <= T2;
                END CASE;
            
            WHEN T2 =>
                CASE INSTR_REG IS                       --JMP ABS 2/2
                    WHEN X"4C" THEN
                        ADDR_BUS <= PC_REG;
                        PC_NEXT <= DATA_BUS & TMP_LOW;
                        NS <= T0;
                END CASE;
        END CASE;
    END PROCESS;
END Behavioral;