library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity i2c_uart is
	port(	rst	:	in std_logic;
			clk	:	in std_logic;
			sda	:	inout std_logic;
			scl	:	inout std_logic;
			state_led : out std_logic_vector(2 downto 0)
			);
end i2c_uart;

architecture portlink of i2c_uart is

component i2c_slave is
	generic(
		i2c_address	:	std_logic_vector(7 downto 0) := x"24"
	);
	port(	
		rst		:	in std_logic;
		clk		:	in std_logic;
		scl_in	: 	in std_logic;
		sda_in	:	in std_logic;
		scl_out	:	out std_logic;
		sda_out	:	out std_logic;
		state_led : out std_logic_vector(2 downto 0)
	);
end component;

signal scl_in : std_logic;
signal sda_in : std_logic;
signal scl_out : std_logic;
signal sda_out : std_logic;

begin
													
	SLAVE_CTL:i2c_slave port map(	rst => rst,
											clk => clk,
											scl_in => scl_in,
											sda_in => sda_in,
											scl_out => scl_out,
											sda_out => sda_out,
											state_led => state_led);

	scl_in 	<= '0' when scl = '0' 		else '1';
	sda_in 	<= '0' when sda = '0' 		else '1';
	scl 		<= '0' when scl_out = '0' 	else 'Z';
	sda 		<= '0' when sda_out = '0' 	else 'Z';

end portlink;