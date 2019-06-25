library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the Math module.

entity tb_math is
end tb_math;

architecture simulation of tb_math is

   constant C_NUM_FACTS : integer := 10;
   constant C_PRIMES    : integer := 6;
   constant C_SIZE      : integer := 72;
   constant C_ZERO      : std_logic_vector(C_SIZE-1 downto 0) := (others => '0');

   type t_sim is record
      valid : std_logic;
      data  : std_logic_vector(60*8-1 downto 0);
      last  : std_logic;
      bytes : std_logic_vector(5 downto 0);
   end record t_sim;

   signal clk           : std_logic;
   signal rst           : std_logic;

   -- Signals conected to DUT
   signal cmd           : t_sim;
   signal resp          : t_sim;
   signal debug         : std_logic_vector(255 downto 0);

   signal cfg_primes    : std_logic_vector(3 downto 0);    -- Number of primes.
   signal cfg_factors   : std_logic_vector(7 downto 0);    -- Number of factors.
   signal mon_cf        : std_logic_vector(31 downto 0);   -- Number of generated CF.
   signal mon_miss_cf   : std_logic_vector(31 downto 0);   -- Number of missed CF.
   signal mon_miss_fact : std_logic_vector(31 downto 0);   -- Number of missed FACT.
   signal mon_factored  : std_logic_vector(31 downto 0);   -- Number of completely factored.

   -- Signal to control execution of the testbench.
   signal test_running : std_logic := '1';

begin

   --------------------------------------------------
   -- Generate clock and reset
   --------------------------------------------------

   proc_clk : process
   begin
      clk <= '1', '0' after 1 ns;
      wait for 2 ns; -- 50 MHz
      if test_running = '0' then
         wait;
      end if;
   end process proc_clk;

   proc_rst : process
   begin
      rst <= '1', '0' after 20 ns;
      wait;
   end process proc_rst;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   i_math : entity work.math
   generic map (
      G_NUM_FACTS => C_NUM_FACTS,
      G_SIZE      => C_SIZE
   )
   port map (
      clk_i       => clk,
      rst_i       => rst,
      debug_o     => debug,
      rx_valid_i  => cmd.valid,
      rx_data_i   => cmd.data,
      rx_last_i   => cmd.last,
      rx_bytes_i  => cmd.bytes,
      tx_valid_o  => resp.valid,
      tx_data_o   => resp.data,
      tx_last_o   => resp.last,
      tx_bytes_o  => resp.bytes
   ); -- i_math


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
   begin
      -- Wait until reset is complete
      cmd.valid <= '0';
      wait until clk = '1' and rst = '0';

      cfg_factors <= to_stdlogicvector(10, 8);
      cfg_primes  <= to_stdlogicvector(6, 4);

      wait until clk = '0';
      cmd.valid <= '1';
      cmd.data  <= (others => '0');
      cmd.data(60*8-1 downto 60*8-2*C_SIZE-12) <=
         to_stdlogicvector(1879048199, 2*C_SIZE) & cfg_factors & cfg_primes;
      cmd.last  <= '1';
      cmd.bytes <= to_stdlogicvector(2*C_SIZE/8, 6);
      wait until clk = '1';
      cmd.valid <= '0';
      wait until clk = '1';

      wait for 80 us;

      -- Wait for the next response
      wait until clk = '1' and resp.valid = '1';
      wait until clk = '0';

      mon_cf        <= resp.data(60*8-3*C_SIZE-0*32-1 downto 60*8-3*C_SIZE-1*32);
      mon_miss_cf   <= resp.data(60*8-3*C_SIZE-1*32-1 downto 60*8-3*C_SIZE-2*32);
      mon_miss_fact <= resp.data(60*8-3*C_SIZE-2*32-1 downto 60*8-3*C_SIZE-3*32);
      mon_factored  <= resp.data(60*8-3*C_SIZE-3*32-1 downto 60*8-3*C_SIZE-4*32);

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      report "Num_Facts     = " & integer'image(to_integer(cfg_factors));
      report "Primes        = " & integer'image(to_integer(cfg_primes));
      report "Mon_CF        = " & integer'image(to_integer(mon_cf));
      report "Mon_Miss_CF   = " & integer'image(to_integer(mon_miss_cf));
      report "Mon_Miss_Fact = " & integer'image(to_integer(mon_miss_fact));
      report "Mon_Factored  = " & integer'image(to_integer(mon_factored));
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

