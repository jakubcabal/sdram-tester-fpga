--------------------------------------------------------------------------------
-- PROJECT: SDRAM TESTER FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LFSR_GEN32 is
    Generic(
        SEED : natural := 0
    );
    Port (
        CLK  : in  std_logic;
        RST  : in  std_logic;
        EN   : in  std_logic;
        DOUT : out std_logic_vector(32-1 downto 0)
    );
end entity;

architecture RTL of LFSR_GEN32 is
    
    signal lfsr_xnor : std_logic;
    signal lfsr_reg  : std_logic_vector(32-1 downto 0);

begin

    lfsr_xnor <= lfsr_reg(31) xnor lfsr_reg(21) xnor lfsr_reg(1) xnor lfsr_reg(0);

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                lfsr_reg <= std_logic_vector(to_unsigned(SEED,32));
            elsif (EN = '1') then
                lfsr_reg <= lfsr_reg(30 downto 0) & lfsr_xnor;
            end if;
        end if;
    end process;

    DOUT <= lfsr_reg;

end architecture;
