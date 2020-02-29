library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity i2c_slave is
	generic(
		i2c_address	:	std_logic_vector(7 downto 0) := x"24"
	);
	port(	
		rst		:	in std_logic;
		clk		:	in std_logic;
		sda_in	:	in std_logic;
		scl_in	: 	in std_logic;
		scl_out	:	out std_logic;
		sda_out	:	out std_logic;
		state_led : out std_logic_vector(2 downto 0)
	);
end i2c_slave;

architecture behavioral of i2c_slave is

type slave_state is (IDLE, RECEV, ACK);

signal state : slave_state;
signal next_state : slave_state;

signal scl_ris, scl_fal : std_logic;
signal sda_ris, sda_fal : std_logic;
signal bit_cnt : integer range 0 to 8;
signal byte : std_logic_vector(7 downto 0);
signal ack_flg : std_logic;
signal start : std_logic;
signal stop : std_logic;

signal sda_p, sda_pp: std_logic;
signal scl_p, scl_pp: std_logic;

begin

	EDGE_MONITOR:process(clk, rst)
	begin
		if (rst = '0') then
			sda_p <= '1';
			sda_pp <= '1';
			scl_p <= '1';
			scl_pp <= '1';
		elsif rising_edge(clk) then
			sda_p <= sda_in;
			sda_pp <= sda_p;
			scl_p <= scl_in;
			scl_pp <= scl_p;
		end if;
	end process EDGE_MONITOR;

	scl_ris <= scl_p and not scl_pp;
	scl_fal <= not scl_p and scl_pp;
	sda_ris <= sda_p and not sda_pp;
	sda_fal <= not sda_p and sda_pp;

	START_SIGN:process(clk, rst)
	begin
		if rst = '0' then
			start <= '0';
		elsif falling_edge(clk) then
			if sda_fal = '1' and scl_pp = '1' then
				start <= '1';
			else
				start <= '0';
			end if;
		end if;
	end process START_SIGN;
	
	STOP_SIGN:process(clk, rst)
	begin
		if rst = '0' then
			stop <= '0';
		elsif falling_edge(clk) then
			if sda_ris = '1' and scl_pp = '1' then
				stop <= '1';
			else
				stop <= '0';
			end if;
		end if;
	end process STOP_SIGN;
	
	SYNC_PROC:process(clk, rst)
	begin
		if rst = '0' then
			state <= IDLE;
		elsif rising_edge(clk) then
			state <= next_state;
		end if;
 	end process SYNC_PROC;
	
	COUNT_DEC:process(clk, rst)
	begin
		if rst = '0' then
			bit_cnt <= 8;
		elsif falling_edge(clk) then
			if state = RECEV then
				if scl_ris = '1' then
					byte(bit_cnt - 1) <= sda_p;
					bit_cnt <= bit_cnt - 1;
				end if;
			else
				bit_cnt <= 8;
			end if;
		end if;
	end process COUNT_DEC;
	
	BYTE_FLG:process(clk, rst)
	begin
		if rst = '0' then
			ack_flg <= '0';
		elsif falling_edge(clk) and scl_fal = '1' then
			if bit_cnt = 0 then
				ack_flg <= '1';
			else
				ack_flg <= '0';
			end if;
		end if;
	end process BYTE_FLG;
	
	OUTPUT_DECODE:process(rst, state, start, stop, ack_flg)
	begin
		if (rst = '0') then
			next_state <= IDLE;
			sda_out <= '1';
			scl_out <= '1';
		else
			case state is
				when IDLE =>
					state_led <= "110";
					sda_out <= '1';
					scl_out <= '1';
					if start = '1' then
						next_state <= RECEV;
					else
						next_state <= IDLE;
					end if;
				when RECEV =>
					state_led <= "101";
					sda_out <= '1';
					scl_out <= '1';
					if ack_flg = '1' then
						next_state <= ACK;
					elsif stop = '1' then
						next_state <= IDLE;
					else
						next_state <= RECEV;
					end if;
				when ACK =>
					state_led <= "011";
					if byte(7 downto 1) = i2c_address(6 downto 0) then
						sda_out <= '0';
					end if;
					scl_out <= '1';
					if ack_flg = '0' then
						next_state <= RECEV;
					else
						next_state <= ACK;
					end if;
			end case;
		end if;
	end process OUTPUT_DECODE;
	
end behavioral;