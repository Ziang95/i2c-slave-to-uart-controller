library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_internal is
	Port(	clk_50m : in std_logic;
			clk_out : out std_logic);
end clock_internal;

architecture behavioral of clock_internal is

begin

process(clk_50m)
variable count : natural := 0;
begin
	if rising_edge(clk_50m) then
		count := count + 1;
		if count < 1 then
			clk_out <= '0';
		elsif count < 2 then
			clk_out <= '1';
		else
			count := 0;
		end if;
	end if;
end process;

end behavioral;