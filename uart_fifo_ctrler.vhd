library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity uart_fifo_ctrler is
	port(	
		clk				: in std_logic;
		rst				: in std_logic;
		d_to_f2			: out std_logic_vector(7 downto 0);
		d_to_uart		: out std_logic_vector(7 downto 0);
		d_from_f1		: in std_logic_vector(7 downto 0);
		d_from_uart		: in std_logic_vector(7 downto 0);
		d_from_uart_rdy: in std_logic;
		d_to_uart_ack	: in std_logic;
		
		f1_read_en		: out std_logic;
		f2_write_en		: out std_logic;
		f1_empty			: in std_logic;
		write_uart_en	: out std_logic;
		state_led		: out std_logic_vector(1 downto 0)
	);
end uart_fifo_ctrler;

architecture behavioral of uart_fifo_ctrler is

	type rx_ctrl_state is (READ_UART, WRITE_FIFO);
	type tx_ctrl_state is (READ_FIFO, WRITE_UART);
	
	signal rx_state, rx_next_state : rx_ctrl_state;
	signal tx_state, tx_next_state : tx_ctrl_state;
	
	signal write_uart_done : std_logic;
	signal write_f2_done : std_logic;
	signal read_uart_done : std_logic;
	signal read_f1_done 	  : std_logic;
	signal read_f1_reqst   : std_logic;
	
	signal byte_to_f2   : std_logic_vector(7 downto 0);
	signal byte_to_uart : std_logic_vector(7 downto 0);

begin

	SYNC_PROC_RX:process(clk, rst)
	begin
		if rst = '0' then
			rx_state <= READ_UART;
		elsif rising_edge(clk) then
			rx_state <= rx_next_state;
		end if;
	end process;
	
	SYNC_PROC_TX:process(clk, rst)
	begin
		if rst = '0' then
			tx_state <= READ_FIFO;
		elsif rising_edge(clk) then
			tx_state <= tx_next_state;
		end if;
	end process;
	
	WRITE_F2_PROC:process(clk, rst)
	begin
		if rst = '0' then
			write_f2_done <= '0';
			f2_write_en <= '0';
		elsif falling_edge(clk) then
			if rx_state = WRITE_FIFO then
				if write_f2_done = '0' then
					d_to_f2 <= byte_to_f2;
					write_f2_done <= '1';
					f2_write_en <= '1';
				else
					f2_write_en <= '0';
				end if;
			else
				write_f2_done <= '0';
				f2_write_en <= '0';
			end if;
		end if;
	end process;
	
	READ_F1_PROC:process(clk, rst)
	begin
		if rst = '0' then
			read_f1_reqst <= '0';
			read_f1_done <= '0';
			f1_read_en <= '0';
		elsif falling_edge(clk) then
			if tx_state = READ_FIFO then
				if read_f1_reqst = '0' then
					if f1_empty = '0' then
						f1_read_en <= '1';
						read_f1_reqst <= '1';
					end if;
				else
					f1_read_en <= '0';
					byte_to_uart <= d_from_f1;
					read_f1_done <= '1';
				end if;
			else
				f1_read_en <= '0';
				read_f1_done <= '0';
				read_f1_reqst <= '0';
			end if;
		end if;
	end process;
	
	READ_UART_PROC:process(clk, rst)
	begin
		if rst = '0' then
			read_uart_done <= '0';
		elsif falling_edge(clk) then
			if rx_state = READ_UART then
				if d_from_uart_rdy = '1' then
					byte_to_f2 <= d_from_uart;
					read_uart_done <= '1';
				end if;
			else
				read_uart_done <= '0';
			end if;
		end if;
	end process;
	
	WRITE_UART_PROC:process(clk, rst)
	begin
		if rst = '0' then
			write_uart_done <= '0';
			write_uart_en <= '0';
		elsif falling_edge(clk) then
			if tx_state = WRITE_UART then
				write_uart_en <= '1';
				d_to_uart <= byte_to_uart;
				if d_to_uart_ack = '1' then
					write_uart_en <= '0';
					write_uart_done <= '1';
				end if;
			else
				write_uart_done <= '0';
				write_uart_en <= '0';
			end if;
		end if;
	end process;
	
	RX_NEXT_STATE_DECODE:process(rst, rx_state, read_uart_done, write_f2_done)
	begin
		if rst = '0' then
			rx_next_state <= READ_UART;
		else
			case rx_state is
				when READ_UART =>
					state_led(1) <= not '0';
					if read_uart_done = '1' then
						rx_next_state <= WRITE_FIFO;
					else
						rx_next_state <= READ_UART;
					end if;
				when WRITE_FIFO =>
					state_led(1) <= not '1';
					if write_f2_done = '1' then
						rx_next_state <= READ_UART;
					else
						rx_next_state <= WRITE_FIFO;
					end if;
				when others =>
					rx_next_state <= READ_UART;
			end case;
		end if;
	end process;
	
	TX_NEXT_STATE_DECODE:process(rst, tx_state, read_f1_done, write_uart_done)
	begin
		if rst = '0' then
			tx_next_state <= READ_FIFO;
		else
			case tx_state is
				when READ_FIFO =>
					state_led(0) <= not '0';
					if read_f1_done = '1' then
						tx_next_state <= WRITE_UART;
					else
						tx_next_state <= READ_FIFO;
					end if;
				when WRITE_UART =>
					state_led(0) <= not '1';
					if write_uart_done = '1' then
						tx_next_state <= READ_FIFO;
					else
						tx_next_state <= WRITE_UART;
					end if;
				when others =>
					tx_next_state <= READ_FIFO;
			end case;
		end if;
	end process;
	
	
end behavioral;