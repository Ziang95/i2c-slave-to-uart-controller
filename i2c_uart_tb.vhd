library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity i2c_uart_tb is
	port(	rst	:	in std_logic
			);
end entity;
			
architecture test of i2c_uart_tb is

signal scl : std_logic;
signal clk : std_logic;
signal sda : std_logic;
signal rst_i : std_logic;

signal state_led_i : std_logic_vector(3 downto 0);

component i2c_uart is
port
(
	rst	:	in std_logic;
	clk	:	in std_logic;
	scl	:	inout std_logic;
	sda	:	inout std_logic;
	empty :	out std_logic;
	full	:	out std_logic;
	state_led : out std_logic_vector(3 downto 0)
);
end component;

begin


LINKED:i2c_uart port map(
									rst => rst_i,
									clk => clk,
									scl => scl,
									sda => sda,
									state_led => state_led_i);
									
process
begin	
	clk <= '1';
	wait for 20 ns;
	clk <= '0';
	wait for 20 ns;
end process;

process
begin
	scl <= 'Z';
	sda <= 'Z';
	wait for 25 ms; 
	sda <= '0';
	wait for 25 ms;
	scl <= '0';
	
	for I in 1 to 8 loop
		wait for 25 ms;
		sda <= 'Z';
		scl <= '0';
		wait for 25 ms;
		scl <= 'Z';
		wait for 50 ms;
		scl <= '0';
	end loop;
	
	wait for 50 ms;
	scl <= 'Z';
	sda <= 'Z';
	wait for 50 ms;
	scl <= '0';
	wait for 25 ms;
	sda <= '0';
	wait for 25 ms;
	scl <= 'Z';
	wait for 25 ms;
	sda <= 'Z';
	wait for 25 ms;
end process;

end test;