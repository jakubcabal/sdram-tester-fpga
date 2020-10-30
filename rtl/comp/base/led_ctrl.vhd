--------------------------------------------------------------------------------
-- PROJECT: SDRAM TESTER FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity LED_CTRL is
    Generic(
        CLK_FREQ : natural := 100e6;
        LEDS     : natural := 8
    );
    Port (
        CLK       : in  std_logic;
        RST       : in  std_logic;
        LED_BLINK : in  std_logic_vector(LEDS-1 downto 0);
        LED_OUT   : out std_logic_vector(LEDS-1 downto 0)
    );
end entity;

architecture RTL of LED_CTRL is

    constant LED_CNT_WIDTH : natural := natural(ceil(log2(real(CLK_FREQ/4))));
    
    signal led_cnt       : unsigned(LED_CNT_WIDTH-1 downto 0);
    signal led_flash     : std_logic;
    signal led_blink_reg : std_logic_vector(LEDS-1 downto 0);

begin

    process (CLK)
    begin
        if (RST = '1') then
            led_cnt <= (others => '0');
        elsif (rising_edge(CLK)) then
            led_cnt <= led_cnt + 1;
        end if;
    end process;

    led_flash <= led_cnt(LED_CNT_WIDTH-1);

    led_g : for i in 0 to LEDS-1 generate
        process (CLK)
        begin
            if (rising_edge(CLK)) then
                if (LED_BLINK(i) = '1') then
                    led_blink_reg(i) <= '1';
                elsif (led_flash = '1') then
                    led_blink_reg(i) <= '0';
                end if;
            end if;
        end process;

        process (CLK)
        begin
            if (rising_edge(CLK)) then
                LED_OUT(i) <= led_flash and led_blink_reg(i);
            end if;
        end process;
    end generate;

end architecture;
