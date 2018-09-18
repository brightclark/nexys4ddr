library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

-- This module is a wrapper for the Xilinx-specific FIFO.
-- The error signals are latches, i.e. are only cleared on reset.

entity fifo is
   generic (
      G_WIDTH : natural    -- Possible values: 8, 16, 32, and 64.
   );
   port (
      wr_clk_i   : in  std_logic;
      wr_rst_i   : in  std_logic;
      wr_en_i    : in  std_logic;
      wr_data_i  : in  std_logic_vector(G_WIDTH-1 downto 0);
      wr_afull_o : out std_logic;
      wr_error_o : out std_logic;
      --
      rd_clk_i   : in  std_logic;
      rd_rst_i   : in  std_logic;
      rd_en_i    : in  std_logic;
      rd_data_o  : out std_logic_vector(G_WIDTH-1 downto 0);
      rd_empty_o : out std_logic;
      rd_error_o : out std_logic
      );
end entity fifo;

architecture behavioral of fifo is

   -- Asynchronous signal
   signal async_rst  : std_logic;

   -- Signals valid @ wr_clk_i
   signal wr_fifo    : std_logic_vector(63 downto 0);
   signal wr_afull   : std_logic;
   signal wr_error   : std_logic;
   signal wr_error_l : std_logic;

   -- Signals valid @ rd_clk_i
   signal rd_fifo    : std_logic_vector(63 downto 0);
   signal rd_empty   : std_logic;
   signal rd_error   : std_logic;
   signal rd_error_l : std_logic;

begin  -- architecture behavioral

   -- Global asynchronous reset. Common for read and write port.
   async_rst <= wr_rst_i or rd_rst_i;

   -- Prepare input data
   wr_fifo(G_WIDTH-1 downto 0) <= wr_data_i;
   wr_fifo(63 downto G_WIDTH)  <= (others => '0');

   -- Instantiate the Xilinx fifo
   inst_FIFO18E1 : FIFO36E1
      GENERIC MAP (
         FIRST_WORD_FALL_THROUGH => true,
         DATA_WIDTH              => (G_WIDTH*9)/8,
         EN_SYN                  => false)
      PORT MAP (
         DI            => wr_fifo,
         DIP           => (others => '0'),
         WREN          => wr_en_i,
         WRCLK         => wr_clk_i,
         RDEN          => rd_en_i,
         RDCLK         => rd_clk_i,
         RST           => async_rst,
         RSTREG        => '0',
         REGCE         => '0',
         DO            => rd_fifo,
         DOP           => open,
         FULL          => open,
         ALMOSTFULL    => wr_afull,
         EMPTY         => rd_empty,
         ALMOSTEMPTY   => open,
         RDCOUNT       => open,
         WRCOUNT       => open,
         WRERR         => wr_error,
         RDERR         => rd_error,
         INJECTDBITERR => '0',
         INJECTSBITERR => '0');

   -- Latch read error
   proc_rd_error : process (rd_clk_i)
   begin
      if rising_edge(rd_clk_i) then
         if rd_error = '1' then
            rd_error_l <= '1';
         end if;
         if rd_rst_i = '1' then
            rd_error_l <= '0';
         end if;
      end if;
   end process proc_rd_error;

   -- Latch write error
   proc_wr_error : process (wr_clk_i)
   begin
      if rising_edge(wr_clk_i) then
         if wr_error = '1' then
            wr_error_l <= '1';
         end if;
         if wr_rst_i = '1' then
            wr_error_l <= '0';
         end if;
      end if;
   end process proc_wr_error;

   -- Drive output siganls
   wr_afull_o <= wr_afull;
   wr_error_o <= wr_error_l;
   rd_data_o  <= rd_fifo(G_WIDTH-1 downto 0);
   rd_empty_o <= rd_empty;
   rd_error_o <= rd_error_l;

end architecture behavioral;
