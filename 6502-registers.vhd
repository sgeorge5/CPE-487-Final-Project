LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY register_file IS
    PORT (
        CLK : IN STD_LOGIC; 
        RST : IN STD_LOGIC;

        DATA_BUS : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        --WE inputs for each register
        WE_ACC, WE_X, WE_Y, WE_SPTR, WE_STAT : IN STD_LOGIC;

        --status register specific enable inputs and flags
        --N V 1 B D I Z C
        ALU_FLAG_N, ALU_FLAG_V, ALU_FLAG_Z, ALU_FLAG_C : IN STD_LOGIC;
        EN_ALL_FLAGS, EN_NZ_FLAGS, EN_NZC_FLAGS, EN_NVZC_FLAGS, EN_BIT_FLAGS : IN STD_LOGIC;
        SET_C, CLR_C, SET_D, CLR_D, SET_I, CLR_I, CLR_V : IN STD_LOGIC;

        ACC, X, Y, SPTR, STAT  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        PC : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END register_file;

ARCHITECTURE Behavioral OF register_file IS
    SIGNAL r_acc, r_x, r_y, r_sptr, r_stat : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    PROCESS(CLK) IS
    BEGIN
        IF RST = '1' THEN
            r_acc <= (OTHERS => '0');
            r_stat <= "00100000";
        ELSIF RISING_EDGE(CLK) THEN
            IF WE_ACC = '1' THEN
                r_acc <= DATA_BUS;
            END IF;

            IF WE_X = '1' THEN
                r_x <= DATA_BUS;
            END IF;

            IF WE_Y = '1' THEN
                r_y <= DATA_BUS;
            END IF;

            IF WE_SPTR = '1' THEN
                r_sptr <= DATA_BUS;
            END IF;

            IF WE_STAT = '1' THEN
                IF EN_ALL_FLAGS = '1' THEN
                    r_stat(7) <= DATA_BUS(7);
                    r_stat(6) <= DATA_BUS(6);
                    r_stat(3) <= DATA_BUS(3);
                    r_stat(2) <= DATA_BUS(2);
                    r_stat(1) <= DATA_BUS(1);
                    r_stat(0) <= DATA_BUS(0);
                ELSIF EN_NZ_FLAGS = '1' THEN
                    r_stat(7) <= ALU_FLAG_N;
                    r_stat(1) <= ALU_FLAG_Z;
                ELSIF EN_NZC_FLAGS = '1' THEN
                    r_stat(7) <= ALU_FLAG_N;
                    r_stat(1) <= ALU_FLAG_Z;
                    r_stat(0) <= ALU_FLAG_C;
                ELSIF EN_NVZC_FLAGS = '1' THEN
                    r_stat(7) <= ALU_FLAG_N;
                    r_stat(6) <= ALU_FLAG_V;
                    r_stat(1) <= ALU_FLAG_Z;
                    r_stat(0) <= ALU_FLAG_C;
                ELSIF EN_BIT_FLAGS = '1' THEN
                    r_stat(7) <= DATA_BUS(7);
                    r_stat(6) <= DATA_BUS(6);
                    r_stat(1) <= ALU_FLAG_Z;
                ELSIF SET_C = '1' THEN r_stat(0) <= '1';
                ELSIF CLR_C = '1' THEN r_stat(0) <= '0';
                ELSIF SET_D = '1' THEN r_stat(3) <= '1';
                ELSIF CLR_D = '1' THEN r_stat(3) <= '0';
                ELSIF SET_I = '1' THEN r_stat(2) <= '1';
                ELSIF CLR_I = '1' THEN r_stat(2) <= '0';
                ELSIF CLR_V = '1' THEN r_stat(6) <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    ACC <= r_acc;
    X <= r_x;
    Y <= r_y;
    SPTR <= r_sptr;
    STAT <= r_stat;
END Behavioral;