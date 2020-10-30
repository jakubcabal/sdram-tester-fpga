--------------------------------------------------------------------------------
-- PROJECT: SDRAM TESTER FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

LIBRARY altera_mf;
USE altera_mf.all;

entity PLL is
    Port (
        IN_CLK         : in  std_logic;
        IN_RST_BTN     : in  std_logic;
        OUT_PLL_LOCKED : out std_logic;
        OUT_CLK0       : out std_logic;
        OUT_CLK1       : out std_logic
    );
end entity;

architecture RTL of PLL is

    COMPONENT altpll
    GENERIC (
        bandwidth_type		: STRING;
        clk0_divide_by		: NATURAL;
        clk0_duty_cycle		: NATURAL;
        clk0_multiply_by		: NATURAL;
        clk0_phase_shift		: STRING;
        clk1_divide_by		: NATURAL;
        clk1_duty_cycle		: NATURAL;
        clk1_multiply_by		: NATURAL;
        clk1_phase_shift		: STRING;
        compensate_clock		: STRING;
        inclk0_input_frequency		: NATURAL;
        intended_device_family		: STRING;
        lpm_hint		: STRING;
        lpm_type		: STRING;
        operation_mode		: STRING;
        pll_type		: STRING;
        port_activeclock		: STRING;
        port_areset		: STRING;
        port_clkbad0		: STRING;
        port_clkbad1		: STRING;
        port_clkloss		: STRING;
        port_clkswitch		: STRING;
        port_configupdate		: STRING;
        port_fbin		: STRING;
        port_inclk0		: STRING;
        port_inclk1		: STRING;
        port_locked		: STRING;
        port_pfdena		: STRING;
        port_phasecounterselect		: STRING;
        port_phasedone		: STRING;
        port_phasestep		: STRING;
        port_phaseupdown		: STRING;
        port_pllena		: STRING;
        port_scanaclr		: STRING;
        port_scanclk		: STRING;
        port_scanclkena		: STRING;
        port_scandata		: STRING;
        port_scandataout		: STRING;
        port_scandone		: STRING;
        port_scanread		: STRING;
        port_scanwrite		: STRING;
        port_clk0		: STRING;
        port_clk1		: STRING;
        port_clk2		: STRING;
        port_clk3		: STRING;
        port_clk4		: STRING;
        port_clk5		: STRING;
        port_clkena0		: STRING;
        port_clkena1		: STRING;
        port_clkena2		: STRING;
        port_clkena3		: STRING;
        port_clkena4		: STRING;
        port_clkena5		: STRING;
        port_extclk0		: STRING;
        port_extclk1		: STRING;
        port_extclk2		: STRING;
        port_extclk3		: STRING;
        self_reset_on_loss_lock		: STRING;
        width_clock		: NATURAL
    );
    PORT (
            areset	: IN STD_LOGIC ;
            inclk	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
            clk	: OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
            locked	: OUT STD_LOGIC 
    );
    END COMPONENT;

    signal pll_in_clk  : std_logic_vector(1 downto 0);
    signal pll_out_clk : std_logic_vector(4 downto 0);

begin

    pll_in_clk <= '0' & IN_CLK;

    altpll_i : altpll
    generic map (
        bandwidth_type => "AUTO",
        clk0_divide_by => 6,
        clk0_duty_cycle => 50,
        clk0_multiply_by => 50,
        clk0_phase_shift => "0",
        clk1_divide_by => 6,
        clk1_duty_cycle => 50,
        clk1_multiply_by => 50,
        clk1_phase_shift => "-5000",
        compensate_clock => "CLK0",
        inclk0_input_frequency => 83333,
        intended_device_family => "Cyclone 10 LP",
        lpm_hint => "CBX_MODULE_PREFIX=pll",
        lpm_type => "altpll",
        operation_mode => "NORMAL",
        pll_type => "AUTO",
        port_activeclock => "PORT_UNUSED",
        port_areset => "PORT_USED",
        port_clkbad0 => "PORT_UNUSED",
        port_clkbad1 => "PORT_UNUSED",
        port_clkloss => "PORT_UNUSED",
        port_clkswitch => "PORT_UNUSED",
        port_configupdate => "PORT_UNUSED",
        port_fbin => "PORT_UNUSED",
        port_inclk0 => "PORT_USED",
        port_inclk1 => "PORT_UNUSED",
        port_locked => "PORT_USED",
        port_pfdena => "PORT_UNUSED",
        port_phasecounterselect => "PORT_UNUSED",
        port_phasedone => "PORT_UNUSED",
        port_phasestep => "PORT_UNUSED",
        port_phaseupdown => "PORT_UNUSED",
        port_pllena => "PORT_UNUSED",
        port_scanaclr => "PORT_UNUSED",
        port_scanclk => "PORT_UNUSED",
        port_scanclkena => "PORT_UNUSED",
        port_scandata => "PORT_UNUSED",
        port_scandataout => "PORT_UNUSED",
        port_scandone => "PORT_UNUSED",
        port_scanread => "PORT_UNUSED",
        port_scanwrite => "PORT_UNUSED",
        port_clk0 => "PORT_USED",
        port_clk1 => "PORT_USED",
        port_clk2 => "PORT_UNUSED",
        port_clk3 => "PORT_UNUSED",
        port_clk4 => "PORT_UNUSED",
        port_clk5 => "PORT_UNUSED",
        port_clkena0 => "PORT_UNUSED",
        port_clkena1 => "PORT_UNUSED",
        port_clkena2 => "PORT_UNUSED",
        port_clkena3 => "PORT_UNUSED",
        port_clkena4 => "PORT_UNUSED",
        port_clkena5 => "PORT_UNUSED",
        port_extclk0 => "PORT_UNUSED",
        port_extclk1 => "PORT_UNUSED",
        port_extclk2 => "PORT_UNUSED",
        port_extclk3 => "PORT_UNUSED",
        self_reset_on_loss_lock => "OFF",
        width_clock => 5
    )
    port map (
        areset => IN_RST_BTN,
        inclk  => pll_in_clk,
        clk    => pll_out_clk,
        locked => OUT_PLL_LOCKED
    );

    OUT_CLK0 <= pll_out_clk(0);
    OUT_CLK1 <= pll_out_clk(1);

end architecture;
