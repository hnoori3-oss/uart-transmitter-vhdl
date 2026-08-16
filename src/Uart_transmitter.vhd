library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Uart_transmitter is 
port (
	clk, rst : in std_logic;
	data_in : in std_logic_vector (7 downto 0);
	start : in std_logic;
	tx : out std_logic;
	busy : out std_logic
	);
end Uart_transmitter;

architecture behavioral of Uart_transmitter is 
constant clk_freq : integer := 100000000;
constant baud_rate : integer := 9600;
constant baud_count : integer := clk_freq/baud_rate;

signal baud_counter : unsigned(13 downto 0):= (others => '0');
signal baud_tick : std_logic:= '0';
signal bit_count : unsigned(2 downto 0):= (others => '0');

signal data_reg : std_logic_vector(7 downto 0);

signal start_prev : std_logic:= '0';
signal start_pulse : std_logic:= '0';


type state_type is (IDLE, START_BIT, DATA_BIT, STOP);
signal present_state, nxt_state : state_type;


begin 
process(clk,rst)
begin
	if (rst = '1') then
		start_prev <= '0';
		start_pulse <= '0';
	elsif (rising_edge(clk)) then
		start_prev <= start;
		if start = '1' and start_prev = '0' then
			start_pulse <= '1';
		else 
			start_pulse <= '0';
		end if;
	end if;
end process;
		
			

counter:process(clk,rst)
begin 
if (rst = '1') then
	baud_counter <= (others => '0');
	baud_tick <= '0';
elsif rising_edge(clk) then 
	if present_state = IDLE then
		baud_counter <= (others => '0');
		baud_tick <='0';
	elsif baud_counter = to_unsigned(baud_count - 1, baud_counter'length) then
		baud_counter <= (others => '0');
		baud_tick <= '1';
	else 
	baud_counter <= baud_counter + 1;
	baud_tick <= '0';
	end if;
end if;
end process;

state_reg:process(clk, rst) 
begin 
if (rst = '1') then
	present_state <= IDLE;
elsif (rising_edge(clk)) then 
	present_state <= nxt_state;
	
end if;
end process;

next_state:process(present_state,start_pulse,baud_tick,bit_count)
begin 
nxt_state <= present_state;
	case present_state is
		when IDLE =>
			if start_pulse ='1' then
				nxt_state <= START_BIT;
			end if;
		when START_BIT =>
			if baud_tick = '1' then 
				nxt_state <= DATA_BIT;
			end if;
		when DATA_BIT =>
			if baud_tick = '1' and bit_count = "111" then
				nxt_state <= STOP;
		end if; 
		when STOP =>
			if baud_tick = '1' then
				nxt_state <= IDLE;
			end if;
end case;
end process;

datapath : process(clk,rst)
begin
if rst = '1' then
bit_count <= (others => '0');
data_reg <= (others => '0');
elsif rising_edge(clk) then
	if start_pulse = '1' and present_state = IDLE then
		data_reg <= data_in;
	end if;
	if (present_state = DATA_BIT and baud_tick = '1') then 
		if bit_count = "111" then 
			bit_count <= (others => '0');
		else
			bit_count <= bit_count+1;
		end if;
	end if;
end if;
end process;

output:process(present_state,bit_count, data_reg)
begin
case present_state is
	when IDLE =>
		tx <= '1';
		busy <= '0';
	when START_BIT =>
		tx <= '0';
		busy <= '1';
	when DATA_BIT =>
		tx <= data_reg(to_integer(bit_count));
		busy <= '1';
	when STOP =>
		tx<='1';
		busy <='1';
	end case;
end process;
end behavioral;
		
	
	
		
	


	