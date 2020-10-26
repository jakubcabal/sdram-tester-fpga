--------------------------------------------------------------------------------
-- PROJECT: SDRAM TESTER FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SDRAM_TESTER is
    Generic (
        DATA_WIDTH : natural := 16;
        ADDR_WIDTH : natural := 16 -- minimum is 16
    );
    Port (
        -- CLOCK AND RESET
        CLK      : in  std_logic;
        RST      : in  std_logic;

        -- WISHBONE SLAVE INTERFACE
        WB_CYC     : in  std_logic;
        WB_STB     : in  std_logic;
        WB_WE      : in  std_logic;
        WB_ADDR    : in  std_logic_vector(15 downto 0);
        WB_DIN     : in  std_logic_vector(31 downto 0);
        WB_STALL   : out std_logic;
        WB_ACK     : out std_logic;
        WB_DOUT    : out std_logic_vector(31 downto 0);

        -- SDRAM TEST INTERFACE
        TEST_ADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        TEST_DWR   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        TEST_WR    : out std_logic;
        TEST_VLD   : out std_logic;
        TEST_RDY   : in  std_logic;
        TEST_DRD   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        TEST_DRD_V : in  std_logic
    );
end entity;

architecture RTL of SDRAM_TESTER is

    signal ctrl_reg_sel : std_logic;
    signal ctrl_reg_we  : std_logic;
    signal ctrl_reg     : std_logic_vector(31 downto 0);

    signal len_reg_sel  : std_logic;
    signal len_reg_we   : std_logic;
    signal len_reg      : std_logic_vector(31 downto 0);

    signal test_run     : std_logic;
    signal test_clr     : std_logic;
    signal test_mode    : std_logic;
    signal test_ready   : std_logic;

    signal addr_cnt     : unsigned(ADDR_WIDTH-1 downto 0);
    signal tick_cnt     : unsigned(31 downto 0);
    signal tick_cnt_max : std_logic;
    signal req_cnt      : unsigned(31 downto 0);
    signal rdresp_cnt   : unsigned(31 downto 0);

begin

    ctrl_reg_sel <= '1' when (WB_ADDR = X"0000") else '0';
    ctrl_reg_we  <= WB_STB and WB_WE and ctrl_reg_sel;

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (ctrl_reg_we = '1') then
                ctrl_reg <= WB_DIN;
            end if;
        end if;
    end process;

    len_reg_sel <= '1' when (WB_ADDR = X"0008") else '0';
    len_reg_we  <= WB_STB and WB_WE and len_reg_sel;

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                len_reg <= X"0FFFFFFF";
            elsif (len_reg_we = '1') then
                len_reg <= WB_DIN;
            end if;
        end if;
    end process;

    WB_STALL <= '0';

    wb_ack_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            WB_ACK <= WB_CYC and WB_STB;
        end if;
    end process;

    wb_dout_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            case WB_ADDR is
                when X"0000" => -- control register
                    WB_DOUT <= ctrl_reg;
                when X"0004" => -- status register
                    WB_DOUT    <= (others => '0');
                    WB_DOUT(0) <= tick_cnt_max;
                when X"0008" => -- length register
                    WB_DOUT <= len_reg;
                when X"0010" => -- tick counter
                    WB_DOUT <= std_logic_vector(tick_cnt);
                when X"0014" => -- request counter
                    WB_DOUT <= std_logic_vector(req_cnt);
                when X"0018" => -- read response counter
                    WB_DOUT <= std_logic_vector(rdresp_cnt);
                when others =>
                    WB_DOUT <= X"DEADCAFE";
            end case;
        end if;
    end process;

    test_run   <= ctrl_reg(0) and not tick_cnt_max;
    test_clr   <= ctrl_reg(1);
    test_mode  <= ctrl_reg(4);
    test_ready <= test_run and TEST_RDY;

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1' or test_clr = '1') then
                addr_cnt <= (others => '0');
            elsif (test_ready = '1') then
                addr_cnt <= addr_cnt + 1;
            end if;
        end if;
    end process;

    TEST_ADDR <= std_logic_vector(addr_cnt);
    TEST_DWR  <= std_logic_vector(resize(addr_cnt(16-1 downto 0),DATA_WIDTH));
    TEST_WR   <= test_mode;
    TEST_VLD  <= test_run;

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1' or test_clr = '1') then
                tick_cnt <= (others => '0');
            elsif (test_run = '1' and tick_cnt_max = '0') then
                tick_cnt <= tick_cnt + 1;
            end if;
        end if;
    end process;

    tick_cnt_max <= '1' when (tick_cnt = unsigned(len_reg)) else '0';

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1' or test_clr = '1') then
                req_cnt <= (others => '0');
            elsif (test_ready = '1') then
                req_cnt <= req_cnt + 1;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1' or test_clr = '1') then
                rdresp_cnt <= (others => '0');
            elsif (TEST_DRD_V = '1') then
                rdresp_cnt <= rdresp_cnt + 1;
            end if;
        end if;
    end process;

end architecture;
