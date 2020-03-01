library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity uart_ctrler is
	generic(
		constant baut_rate : positive;
		constant clk_freq : positive
	);
	port(
		clk		: in		std_logic;
		rst		: in		std_logic;
		rx			: in		std_logic;
		tx			: out		std_logic;
		byte_rdy	: out		std_logic
		
	);
end uart_ctrler;