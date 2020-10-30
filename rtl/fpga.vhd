--------------------------------------------------------------------------------
-- PROJECT: SDRAM TESTER FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FPGA is
    Generic(
        SDRAM_CTRL_SEL : natural := 0
    );
    Port (
        -- System clock and reset button
        CLK_12M     : in    std_logic;
        RST_BTN_N   : in    std_logic;
        -- SDRAM interface
        SDRAM_A     : out   std_logic_vector(12-1 downto 0);
        SDRAM_BA    : out   std_logic_vector(2-1 downto 0);
        SDRAM_DQ    : inout std_logic_vector(16-1 downto 0);
        SDRAM_DQM   : out   std_logic_vector(2-1 downto 0);
        SDRAM_CLK   : out   std_logic;
        SDRAM_CS_N  : out   std_logic;
        SDRAM_CKE   : out   std_logic;
        SDRAM_RAS_N : out   std_logic;
        SDRAM_CAS_N : out   std_logic;
        SDRAM_WE_N  : out   std_logic;
        -- UART interface
        UART_RXD    : in    std_logic;
        UART_TXD    : out   std_logic;
        -- LED output
        LED_OUT     : out   std_logic_vector(8-1 downto 0)
    );
end entity;

architecture FULL of FPGA is

    constant WB_BASE_PORTS  : natural := 4;  -- system, test, reserved, reserved
    constant WB_BASE_OFFSET : natural := 14;
    constant TESTER_DATA_W  : natural := 32;
    constant TESTER_ADDR_W  : natural := 21;

    signal rst_btn          : std_logic;

    signal pll_locked       : std_logic;
    signal pll_locked_n     : std_logic;

    signal clk_sdram        : std_logic;
    signal rst_sdram        : std_logic;
    signal rst_sdram_n      : std_logic;

    signal wb_master_cyc    : std_logic;
    signal wb_master_stb    : std_logic;
    signal wb_master_we     : std_logic;
    signal wb_master_addr   : std_logic_vector(15 downto 0);
    signal wb_master_dout   : std_logic_vector(31 downto 0);
    signal wb_master_stall  : std_logic;
    signal wb_master_ack    : std_logic;
    signal wb_master_din    : std_logic_vector(31 downto 0);

    signal wb_mbs_cyc       : std_logic_vector(WB_BASE_PORTS-1 downto 0);
    signal wb_mbs_stb       : std_logic_vector(WB_BASE_PORTS-1 downto 0);
    signal wb_mbs_we        : std_logic_vector(WB_BASE_PORTS-1 downto 0);
    signal wb_mbs_addr      : std_logic_vector(WB_BASE_PORTS*16-1 downto 0);
    signal wb_mbs_din       : std_logic_vector(WB_BASE_PORTS*32-1 downto 0);
    signal wb_mbs_stall     : std_logic_vector(WB_BASE_PORTS-1 downto 0);
    signal wb_mbs_ack       : std_logic_vector(WB_BASE_PORTS-1 downto 0);
    signal wb_mbs_dout      : std_logic_vector(WB_BASE_PORTS*32-1 downto 0);

    signal test_addr        : std_logic_vector(TESTER_ADDR_W-1 downto 0);
    signal test_addr_ext    : std_logic_vector(TESTER_ADDR_W+2-1 downto 0);
    signal test_dwr         : std_logic_vector(TESTER_DATA_W-1 downto 0);
    signal test_wr          : std_logic;
    signal test_vld         : std_logic;
    signal test_rdy         : std_logic;
    signal test_drd         : std_logic_vector(TESTER_DATA_W-1 downto 0);
    signal test_drd_v       : std_logic;
    signal test_en          : std_logic;
    signal test_read        : std_logic;
    signal test_drd_v_shreg : std_logic_vector(8-1 downto 0);

    signal sdram_a_uns      : unsigned(12-1 downto 0);
    signal sdram_ba_uns     : unsigned(2-1 downto 0);

    COMPONENT ahb_lite_sdram
    generic (
        ADDR_BITS          : natural;
        ROW_BITS           : natural;
        COL_BITS           : natural;
        DQ_BITS            : natural;
        DM_BITS            : natural;
        BA_BITS            : natural;
        DELAY_nCKE         : natural;
        DELAY_tREF         : natural;
        DELAY_tRP          : natural;
        DELAY_tRFC         : natural;
        DELAY_tMRD         : natural;
        DELAY_tRCD         : natural;
        DELAY_tCAS         : natural;
        DELAY_afterREAD    : natural;
        DELAY_afterWRITE   : natural;
        COUNT_initAutoRef  : natural
    );
    PORT (
        HCLK      : in  std_logic;
        HRESETn   : in  std_logic;
        HADDR     : in  std_logic_vector(31 downto 0);
        HBURST    : in  std_logic_vector(2 downto 0);
        HMASTLOCK : in  std_logic;
        HPROT     : in  std_logic_vector(3 downto 0);
        HSEL      : in  std_logic;
        HSIZE     : in  std_logic_vector(2 downto 0);
        HTRANS    : in  std_logic_vector(1 downto 0);
        HWDATA    : in  std_logic_vector(31 downto 0);
        HWRITE    : in  std_logic;
        HREADY    : in  std_logic;
        HRDATA    : out std_logic_vector(31 downto 0);
        HREADYOUT : out std_logic;
        HRESP     : out std_logic;
        SI_Endian : in  std_logic;
        CKE       : out std_logic;
        CSn       : out std_logic;
        RASn      : out std_logic;
        CASn      : out std_logic;
        WEn       : out std_logic;
        ADDR      : out std_logic_vector(ADDR_BITS-1 downto 0);
        BA        : out std_logic_vector(BA_BITS-1 downto 0);
        DQ        : inout std_logic_vector(DQ_BITS-1 downto 0);
        DQM       : out std_logic_vector(DM_BITS-1 downto 0)
    );
    END COMPONENT;

begin

    rst_btn <= not RST_BTN_N;

    pll_i : entity work.PLL
    port map (
        IN_CLK         => CLK_12M,
        IN_RST_BTN     => rst_btn,
        OUT_PLL_LOCKED => pll_locked,
        OUT_CLK0       => clk_sdram,
        OUT_CLK1       => SDRAM_CLK
    );

    pll_locked_n <= not pll_locked;

    rst_sdram_sync_i : entity work.RST_SYNC
    port map (
        CLK        => clk_sdram,
        ASYNC_RST  => pll_locked_n,
        SYNCED_RST => rst_sdram
    );

    rst_sdram_n <= not rst_sdram;

    led_ctrl_i : entity work.LED_CTRL
    generic map (
        CLK_FREQ  => 100e6,
        LEDS      => 2
    )
    port map (
        CLK          => clk_sdram,
        RST          => rst_sdram,
        LED_BLINK(0) => test_en,
        LED_BLINK(1) => test_drd_v,
        LED_OUT      => LED_OUT(2-1 downto 0)
    );

    LED_OUT(8-1 downto 2) <= (others => '0');

    uart2wbm_i : entity work.UART2WBM
    generic map (
        CLK_FREQ  => 100e6,
        BAUD_RATE => 9600
    )
    port map (
        CLK      => clk_sdram,
        RST      => rst_sdram,
        -- UART INTERFACE
        UART_TXD => UART_TXD,
        UART_RXD => UART_RXD,
        -- WISHBONE MASTER INTERFACE
        WB_CYC   => wb_master_cyc,
        WB_STB   => wb_master_stb,
        WB_WE    => wb_master_we,
        WB_ADDR  => wb_master_addr,
        WB_DOUT  => wb_master_dout,
        WB_STALL => wb_master_stall,
        WB_ACK   => wb_master_ack,
        WB_DIN   => wb_master_din
    );

    wb_splitter_base_i : entity work.WB_SPLITTER
    generic map (
        MASTER_PORTS => WB_BASE_PORTS,
        ADDR_OFFSET  => WB_BASE_OFFSET
    )
    port map (
        CLK        => clk_sdram,
        RST        => rst_sdram,

        WB_S_CYC   => wb_master_cyc,
        WB_S_STB   => wb_master_stb,
        WB_S_WE    => wb_master_we,
        WB_S_ADDR  => wb_master_addr,
        WB_S_DIN   => wb_master_dout,
        WB_S_STALL => wb_master_stall,
        WB_S_ACK   => wb_master_ack,
        WB_S_DOUT  => wb_master_din,

        WB_M_CYC   => wb_mbs_cyc,
        WB_M_STB   => wb_mbs_stb,
        WB_M_WE    => wb_mbs_we,
        WB_M_ADDR  => wb_mbs_addr,
        WB_M_DOUT  => wb_mbs_dout,
        WB_M_STALL => wb_mbs_stall,
        WB_M_ACK   => wb_mbs_ack,
        WB_M_DIN   => wb_mbs_din
    );

    sys_module_i : entity work.SYS_MODULE
    port map (
        -- CLOCK AND RESET
        CLK      => clk_sdram,
        RST      => rst_sdram,

        -- WISHBONE SLAVE INTERFACE
        WB_CYC   => wb_mbs_cyc(0),
        WB_STB   => wb_mbs_stb(0),
        WB_WE    => wb_mbs_we(0),
        WB_ADDR  => wb_mbs_addr((0+1)*16-1 downto 0*16),
        WB_DIN   => wb_mbs_dout((0+1)*32-1 downto 0*32),
        WB_STALL => wb_mbs_stall(0),
        WB_ACK   => wb_mbs_ack(0),
        WB_DOUT  => wb_mbs_din((0+1)*32-1 downto 0*32)
    );

    tester_i : entity work.SDRAM_TESTER
    generic map (
        DATA_WIDTH => TESTER_DATA_W,
        ADDR_WIDTH => TESTER_ADDR_W
    )
    port map (
        -- CLOCK AND RESET
        CLK        => clk_sdram,
        RST        => rst_sdram,

        -- WISHBONE SLAVE INTERFACE
        WB_CYC     => wb_mbs_cyc(1),
        WB_STB     => wb_mbs_stb(1),
        WB_WE      => wb_mbs_we(1),
        WB_ADDR    => wb_mbs_addr((1+1)*16-1 downto 1*16),
        WB_DIN     => wb_mbs_dout((1+1)*32-1 downto 1*32),
        WB_STALL   => wb_mbs_stall(1),
        WB_ACK     => wb_mbs_ack(1),
        WB_DOUT    => wb_mbs_din((1+1)*32-1 downto 1*32),

        TEST_ADDR  => test_addr,
        TEST_DWR   => test_dwr,
        TEST_WR    => test_wr,
        TEST_VLD   => test_vld,
        TEST_RDY   => test_rdy,
        TEST_DRD   => test_drd,
        TEST_DRD_V => test_drd_v
    );

    test_en <= test_vld and test_rdy;

    sdram_ctrl0_g: if SDRAM_CTRL_SEL=0 generate
        sdram_ctrl_i : entity work.sdram
        generic map (
            CLK_FREQ         => 100.0,
            ADDR_WIDTH       => TESTER_ADDR_W,
            DATA_WIDTH       => TESTER_DATA_W,
            SDRAM_ADDR_WIDTH => 12,
            SDRAM_DATA_WIDTH => 16,
            SDRAM_COL_WIDTH  => 8,
            SDRAM_ROW_WIDTH  => 12,
            SDRAM_BANK_WIDTH => 2,
            CAS_LATENCY      => 2, -- 2=below 133MHz, 3=above 133MHz
            BURST_LENGTH     => 2,
            T_DESL           => 200000.0, -- startup delay
            T_MRD            =>     20.0, -- mode register cycle time OK
            T_RC             =>     60.0, -- row cycle time OK
            T_RCD            =>     15.0, -- RAS to CAS delay OK
            T_RP             =>     15.0, -- precharge to activate delay OK
            T_WR             =>     20.0, -- write recovery time OK
            T_REFI           =>  15625.0 -- average refresh interval
        )
        port map (
            reset       => rst_sdram,
            clk         => clk_sdram,
            addr        => unsigned(test_addr),
            data        => test_dwr,
            we          => test_wr,
            req         => test_vld,
            ack         => test_rdy,
            valid       => test_drd_v,
            q           => test_drd,
    
            sdram_a     => sdram_a_uns,
            sdram_ba    => sdram_ba_uns,
            sdram_dq    => SDRAM_DQ,
            sdram_cke   => SDRAM_CKE,
            sdram_cs_n  => SDRAM_CS_N,
            sdram_ras_n => SDRAM_RAS_N,
            sdram_cas_n => SDRAM_CAS_N,
            sdram_we_n  => SDRAM_WE_N,
            sdram_dqml  => SDRAM_DQM(0),
            sdram_dqmh  => SDRAM_DQM(1)
        );
    
        SDRAM_A   <= std_logic_vector(sdram_a_uns);
        SDRAM_BA  <= std_logic_vector(sdram_ba_uns);
    end generate;

    sdram_ctrl1_g: if SDRAM_CTRL_SEL=1 generate
        test_addr_ext <= test_addr & "00";

        sdram_ctrl_i : ahb_lite_sdram
        generic map (
            ADDR_BITS           => 12,
            ROW_BITS            => 12,
            COL_BITS            => 8,
            DQ_BITS             => 16,
            DM_BITS             => 2,
            BA_BITS             => 2,
            DELAY_nCKE          => 20000,
            DELAY_tREF          => 1520,
            DELAY_tRP           => 2,
            DELAY_tRFC          => 6,
            DELAY_tMRD          => 2,
            DELAY_tRCD          => 2,
            DELAY_tCAS          => 1,
            DELAY_afterREAD     => 4,
            DELAY_afterWRITE    => 4,
            COUNT_initAutoRef   => 8 
        )
        port map (
            HCLK      => clk_sdram,
            HRESETn   => rst_sdram_n,
            HADDR     => std_logic_vector(resize(unsigned(test_addr_ext),32)),
            HBURST    => (others => '0'),
            HMASTLOCK => '0',
            HPROT     => (others => '0'),
            HSEL      => '1',
            HSIZE     => "010",
            HTRANS    => "10",
            HWDATA    => test_dwr,
            HWRITE    => test_wr,
            HREADY    => test_vld,
            HRDATA    => test_drd,
            HREADYOUT => test_rdy,
            HRESP     => open,
            SI_Endian => '0',
            CKE       => SDRAM_CKE,
            CSn       => SDRAM_CS_N,
            RASn      => SDRAM_RAS_N,
            CASn      => SDRAM_CAS_N,
            WEn       => SDRAM_WE_N,
            ADDR      => SDRAM_A,
            BA        => SDRAM_BA,
            DQ        => SDRAM_DQ,
            DQM       => SDRAM_DQM
        );

        test_read <= test_vld and test_rdy and not test_wr;

        process (clk_sdram)
        begin
            if (rising_edge(clk_sdram)) then
                test_drd_v_shreg <= test_drd_v_shreg(6 downto 0) & test_read;
                if (rst_sdram = '1') then
                    test_drd_v_shreg <= (others => '0');
                end if;
            end if;
        end process;

        test_drd_v <= test_drd_v_shreg(7);
    end generate;

end architecture;
