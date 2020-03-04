library ieee;
	 use ieee.std_logic_1164.ALL;
	 use ieee.numeric_std.ALL;

entity std_fifo is
	generic(	
		constant data_width : positive;
		constant fifo_depth : positive
	);
	port(	
		clk		: in 	std_logic;
		rst		: in 	std_logic;
		write_en	: in 	std_logic;
		data_in	: in 	std_logic_vector(data_width - 1 downto 0);
		read_en	: in 	std_logic;
		data_out	: out	std_logic_vector(data_width - 1 downto 0);
		empty		: out std_logic;
		full		: out std_logic
	);
end std_fifo;

architecture behavioral of std_fifo is

begin

	fifo_proc:process(clk, rst)
		type fifo_memory is array (0 to fifo_depth -1) of std_logic_vector(data_width - 1 downto 0);
		variable mem : fifo_memory;
		variable head : natural range 0 to fifo_depth - 1;
		variable tail : natural range 0 to fifo_depth - 1;
		
		variable looped : boolean;
	begin
		if rising_edge(clk) then
			if rst = '0' then
				head := 0;
				tail := 0;
				looped := false;
				full <= '0';
				empty <= '1';
			else
				if read_en = '1' then
					if looped = true or head /= tail then
						data_out <= mem(head);
						
						if head = fifo_depth - 1 then
							head := 0;
							looped := false;
						else
							head := head + 1;
						end if;
						
					end if;
				end if;
				
				if write_en = '1' then
					if looped = false or head /= tail then
						mem(tail) := data_in;
						
						if tail = fifo_depth - 1 then
							tail := 0;
							looped := true;
						else
							tail := tail + 1;
						end if;
					end if;
				end if;
				
				if head = tail then
					if looped then
						full <= '1';
						empty <= '0';
					else
						full <= '0';
						empty <= '1';
					end if;
				else
					empty <= '0';
					full <= '0';
				end if;
			end if;
		end if;
	end process fifo_proc;
end behavioral;