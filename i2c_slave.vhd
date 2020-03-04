library ieee;
	 use ieee.std_logic_1164.all;
	 use ieee.numeric_std.all;

entity i2c_slave is
	generic(
		i2c_address	:	std_logic_vector(7 downto 0)
	);
	port(	
		rst		:	in std_logic;
		clk		:	in std_logic;
		sda_in	:	in std_logic;
		scl_in	: 	in std_logic;
		scl_out	:	out std_logic;
		sda_out	:	out std_logic;
		
		data_to_fifo 	: out std_logic_vector(7 downto 0);
		data_from_fifo : in std_logic_vector(7 downto 0);
		write_fifo_en 	: out std_logic;
		read_fifo_en 	: out std_logic;
		
		out_fifo_full 	: in std_logic;
		out_fifo_empty : in std_logic;
		in_fifo_empty 	: in std_logic;
		reset_in_fifo 	: out std_logic;
		
		state_led : out std_logic_vector(3 downto 0)
	);
end i2c_slave;

architecture behavioral of i2c_slave is

type slave_state is (IDLE,
							STRT,
							ANSWR,
							ACK,
							RECEV,
							CLR_IN_FIFO,
							SEND,
							WAIT_ACK,
							WRITE_FIFO,
							READ_FIFO,
							STP
							);

signal state : slave_state;
signal next_state : slave_state;

signal scl_ris, scl_fal : std_logic;
signal sda_ris, sda_fal : std_logic;

signal recv_byte : std_logic_vector(7 downto 0);
signal send_byte : std_logic_vector(7 downto 0);
signal recv_bit_cnt : integer range 0 to 8;
signal answ_bit_cnt : integer range 0 to 8;
signal send_bit_cnt : integer range 0 to 8;

signal r_w : std_logic;

signal ack_flg : std_logic;
signal wait_ack_flg : std_logic;
signal master_ack_bit : std_logic;

signal byte_wrttn : std_logic;
signal byte_ready : std_logic;
signal byte_reqst : std_logic;
signal fifo_clrd : std_logic;

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
			if sda_fal = '1' and scl_p = '1' then
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
			if sda_ris = '1' and scl_p = '1' then
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
	
	RECV_CNT_DEC:process(clk, rst)
	begin
		if rst = '0' then
			recv_bit_cnt <= 8;
			answ_bit_cnt <= 8;
			recv_byte <= "00000000";
		elsif falling_edge(clk) then
			if state = RECEV then
				if scl_ris = '1' then
					recv_byte(recv_bit_cnt - 1) <= sda_p;
					recv_bit_cnt <= recv_bit_cnt - 1;
				end if;
			else
				recv_bit_cnt <= 8;
			end if;
			
			if state = ANSWR then
				if scl_ris = '1' then
					recv_byte(answ_bit_cnt - 1) <= sda_p;
					answ_bit_cnt <= answ_bit_cnt - 1;
				end if;
			else
				answ_bit_cnt <= 8;
			end if;
		end if;
		
	end process RECV_CNT_DEC;
	
	ACK_FLG_PROC:process(clk, rst)
	begin
		if rst = '0' then
			ack_flg <= '0';
		elsif falling_edge(clk) and scl_fal = '1' then
			if recv_bit_cnt = 0 or answ_bit_cnt = 0 then
				ack_flg <= '1';
			else
				ack_flg <= '0';
			end if;
		end if;
	end process ACK_FLG_PROC;
	
	SEND_CNT_DEC:process(clk, rst)
	begin
		if rst = '0' then
			send_bit_cnt <= 8;
		elsif falling_edge(clk) and scl_fal = '1' then
			if state = SEND then
				send_bit_cnt <= send_bit_cnt - 1;
			else
				send_bit_cnt <= 8;
			end if;
		end if;
	end process SEND_CNT_DEC;
	
	MASTER_ACK_BIT_PROC:process(clk, rst)
	begin
		if rst = '0' then
			master_ack_bit <= '1';
		elsif falling_edge(clk) and scl_ris = '1' then
			if state = WAIT_ACK then
				master_ack_bit <= sda_p;
			end if;
		end if;
	end process MASTER_ACK_BIT_PROC;
	
	WAIT_ACK_FLG_PROC:process(clk, rst)
	begin
		if rst = '0' then
			wait_ack_flg <= '0';
		elsif falling_edge(clk) then
			if send_bit_cnt = 0 then
				wait_ack_flg <= '1';
			else
				wait_ack_flg <= '0';
			end if;
		end if;
	end process WAIT_ACK_FLG_PROC;
	
	BYTE_WRITE_PROC:process(clk, rst)
	begin
		if rst = '0' then
			byte_wrttn <= '0';
			write_fifo_en <= '0';
		elsif falling_edge(clk) then
			if state = WRITE_FIFO or state = STRT or state = STP then
				if byte_wrttn = '0' and out_fifo_full = '0' then
					write_fifo_en <= '1';
					if state = STRT then
						data_to_fifo <= "00000000";
					elsif state = STP then
						data_to_fifo <= "11111111";
					else
						data_to_fifo <= recv_byte;
					end if;
					byte_wrttn <= '1';
				else
					write_fifo_en <= '0';
				end if;
			else
				write_fifo_en <= '0';
				byte_wrttn <= '0';
			end if;
		end if;
	end process BYTE_WRITE_PROC;
	
	BYTE_READ_PROC:process(clk, rst)
	begin
		if rst = '0' then
			byte_reqst <= '0';
			byte_ready <= '0';
			read_fifo_en <= '0';
		elsif falling_edge(clk) then
			if state = READ_FIFO then
				if byte_reqst = '0' then
					if in_fifo_empty = '0' then
						read_fifo_en <= '1';
						byte_reqst <= '1';
					end if;
				else
					read_fifo_en <= '0';
					send_byte <= data_from_fifo;
					byte_ready <= '1';
				end if;
			else
				read_fifo_en <= '0';
				byte_ready <= '0';
				byte_reqst <= '0';
			end if;
		end if;
	end process BYTE_READ_PROC;
	
	FIFO_CLRD_PROC:process(clk, rst)
	begin
		if rst = '0' then
			fifo_clrd <= '0';
			reset_in_fifo <= '1';
		elsif falling_edge(clk) then
			if state = CLR_IN_FIFO then
				if fifo_clrd = '0' then
					fifo_clrd <= '1';
					reset_in_fifo <= '0';
				else
					reset_in_fifo <= '1';
				end if;
			else
				fifo_clrd <= '0';
				reset_in_fifo <= '1';
			end if;
		end if;
	end process FIFO_CLRD_PROC;
	
	OUTPUT_DECODE:process(rst, state, start, stop, ack_flg, byte_wrttn, fifo_clrd, wait_ack_flg, byte_ready, send_bit_cnt)
	begin
		if (rst = '0') then
			next_state <= IDLE;
			sda_out <= '1';
			scl_out <= '1';
			r_w <= '0';
		else
			case state is
				when IDLE =>
					state_led <= not "0000";
					scl_out <= '1';
					sda_out <= '1';
					if start = '1' then
						next_state <= STRT;
					else
						next_state <= IDLE;
					end if;
				when STRT =>
					scl_out <= '1';
					sda_out <= '1';
					state_led <= not "0001";
					if byte_wrttn = '1' then
						next_state <= ANSWR;
					else
						next_state <= STRT;
					end if;
				when ANSWR =>
					state_led <= not "0010";
					scl_out <= '1';
					sda_out <= '1';
					if stop = '1' then
						next_state <= STP;
					elsif ack_flg = '1' then
						if recv_byte(7 downto 1) = i2c_address(6 downto 0) then
							r_w <= recv_byte(0);
							if recv_byte(0) = '0' then
								next_state <= WRITE_FIFO;
							else
								next_state <= CLR_IN_FIFO;
							end if;
						else
							next_state <= IDLE;
						end if;
					else
						next_state <= ANSWR;
					end if;
				when ACK =>
					state_led <= not "0011";
					scl_out <= '1';
					sda_out <= '0';
					if ack_flg = '0' then
						if r_w = '0' then
							next_state <= RECEV;
						else
							next_state <= READ_FIFO;
						end if;
					else
						next_state <= ACK;
					end if;
				when RECEV =>
					state_led <= not "0100";
					scl_out <= '1';
					sda_out <= '1';
					if stop = '1' then
						next_state <= STP;
					elsif start = '1' then
						next_state <= STRT;
					elsif ack_flg = '1' then
						next_state <= WRITE_FIFO;
					else
						next_state <= RECEV;
					end if;
				when CLR_IN_FIFO =>
					state_led <= not "0101";
					scl_out <= '0';
					sda_out <= '1';
					if fifo_clrd = '1' then
						next_state <= WRITE_FIFO;
					else
						next_state <= CLR_IN_FIFO;
					end if;
				when SEND =>
					state_led <= not "0110";
					scl_out <= '1';
					if send_bit_cnt > 0 then
						sda_out <= send_byte(send_bit_cnt - 1);
					else
						sda_out <= '1';
					end if;
					if stop = '1' then
						next_state <= STP;
					elsif wait_ack_flg = '1' then
						next_state <= WAIT_ACK;
					else
						next_state <= SEND;
					end if;
				when WAIT_ACK =>
					state_led <= not "0111";
					scl_out <= '1';
					sda_out <= '1';
					if wait_ack_flg = '0' then
						if master_ack_bit = '1' then
							next_state <= STP;
						else
							next_state <= READ_FIFO;
						end if;
					else
						next_state <= WAIT_ACK;
					end if;
				when WRITE_FIFO =>
					state_led <= not "1000";
					scl_out <= '0';
					sda_out <= '0';
					if byte_wrttn = '1' then
						next_state <= ACK;
					else
						next_state <= WRITE_FIFO;
					end if;
				when READ_FIFO =>
					state_led <= not "1001";
					scl_out <= '0';
					sda_out <= '1';
					if byte_ready = '1' then
						next_state <= SEND;
					else
						next_state <= READ_FIFO;
					end if;
				when STP =>
					state_led <= not "1010";
					scl_out <= '1';
					sda_out <= '1';
					if byte_wrttn = '1' then
						next_state <= IDLE;
					else
						next_state <= STP;
					end if;
			end case;
		end if;
	end process OUTPUT_DECODE;
	
end behavioral;