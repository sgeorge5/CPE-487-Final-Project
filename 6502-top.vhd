LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY MCS6502 IS
    PORT (
        CLK : IN STD_LOGIC;
        RDY : IN STD_LOGIC;
        IRQ_N : IN STD_LOGIC;
        NMI_N : IN STD_LOGIC;
        RES : IN STD_LOGIC;
        S_O : IN STD_LOGIC;
        DATA_BUS_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

        SYNC : OUT STD_LOGIC;
        RW : OUT STD_LOGIC;
        ADDR_BUS : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); 
        DATA_BUS_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    );
END MCS6502;

ARCHITECTURE Behavioral OF MCS6502 IS
    COMPONENT alu IS
        PORT (
            A : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            B : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            ALU_SEL : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            CIN : IN STD_LOGIC;

            RESULT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            STATUS_FLAGS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT register_file IS
        PORT (
            CLK : IN STD_LOGIC;
            RW : IN STD_LOGIC;
            RST : IN STD_LOGIC;
            DATA_BUS : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            REG_SEL : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

            ACC, X, Y, SPTR, STAT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            PC : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT control IS
        PORT (
            RW : OUT STD_LOGIC;
            REG_SEL : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            ALU_SEL : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            SYNC : OUT STD_LOGIC;
            EN_ALL_FLAGS, EN_NZ_FLAGS, EN_NZC_FLAGS, SET_C, CLR_C, EN_BIT_FLAGS : OUT STD_LOGIC;
            
            ADDR_BUS : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            DATA_BUS : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            RST : IN STD_LOGIC
        );
    END COMPONENT;

    SIGNAL alu_in_a : STD_LOGIC_VECTOR(7 DOWNTO 0);     --source can come from data bus, 
    SIGNAL alu_status_flags : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL reg_stat : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ctrl_en_all_flags : STD_LOGIC;
BEGIN
    ALU: alu PORT MAP (
        A => alu_in_a,
        B => alu_in_b,
        ALU_SEL => alu_sel,
        CIN => alu_cin,

        RESULT => alu_result,
        STATUS_FLAGS => alu_status_flags
    );

    REGISTER_FILE: register_file PORT MAP (
        CLK => CLK,
        RW => RW,
        RST => RST,
        DATA_BUS => DATA_BUS_IN,
        REG_SEL => reg_sel,

        ACC => reg_acc,
        X => reg_x,
        Y => reg_y,
        SPTR => reg_sptr,
        STAT => reg_stat,
        PC => reg_pc
    );

    CONTROL: control PORT MAP (
        RW => CLK,
        REG_SEL => RW,
        ALU_SEL => alu_sel,
        SYNC => SYNC,
        EN_ALL_FLAGS => ctrl_en_all_flags,

        ADDR_BUS => ADDR_BUS,
        DATA_BUS => DATA_BUS,
        RST => RST
    );

    -- N V 1 B D I Z C
    reg_stat <= alu_status_flags(3 DOWNTO 2) & '1' & reg_stat(4 DOWNTO 2) & alu_status_flags(1 DOWNTO 0) WHEN ctrl_en_all_flags = '1'

END ARCHITECTURE;