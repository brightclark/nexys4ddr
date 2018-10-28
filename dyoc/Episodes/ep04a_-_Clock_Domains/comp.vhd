library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Library xpm;
use xpm.vcomponents.all;

-- This is the top level module. The ports on this entity are mapped directly
-- to pins on the FPGA.
--
-- In this version the design can execute a single instruction (LDA #)
-- from the memory.
-- Additionally, the CPU registers are shown on the VGA display.
-- The registers shown are:
-- * Data read from memory (1 byte)
-- * 'A' register (1 byte)
-- * Program Counter (2 bytes)
-- * Instruction Register (1 byte)
-- * Instruction Cycle Counter (1 byte).
--
-- The speed of the execution is controlled by the slide switches.

entity comp is
   port (
      clk_i     : in  std_logic;                      -- 100 MHz

      sw_i      : in  std_logic_vector(7 downto 0);

      vga_hs_o  : out std_logic;
      vga_vs_o  : out std_logic;
      vga_col_o : out std_logic_vector(7 downto 0)    -- RRRGGGBB
   );
end comp;

architecture Structural of comp is

   -- MAIN Clock domain
   signal main_clk     : std_logic;
   signal main_wait    : std_logic;
   signal main_overlay : std_logic_vector(23 downto 0);

   -- VGA Clock doamin
   signal vga_clk      : std_logic;
   signal vga_overlay  : std_logic_vector(23 downto 0);

begin
   
   --------------------------------------------------
   -- Instantiate Clock generation
   --------------------------------------------------

   clk_inst : entity work.clk_wiz_0_clk_wiz
   port map (
      clk_in1  => clk_i,
      eth_clk  => open, -- Not needed yet.
      vga_clk  => vga_clk,
      main_clk => main_clk
   ); -- clk_inst

   
   --------------------------------------------------
   -- Instantiate Waiter
   --------------------------------------------------

   waiter_inst : entity work.waiter
   port map (
      clk_i  => main_clk,
      sw_i   => sw_i,
      wait_o => main_wait
   ); -- waiter_inst


   --------------------------------------------------
   -- Instantiate main
   --------------------------------------------------

   main_inst : entity work.main
   port map (
      clk_i     => main_clk,
      wait_i    => main_wait,
      overlay_o => main_overlay
   ); -- main_inst


   --------------------------------------------------
   -- Instantiate clock crossing from MAIN to VGA
   --------------------------------------------------

   xpm_cdc_array_single_inst: xpm_cdc_array_single
   generic map (
      DEST_SYNC_FF   => 2,
      SIM_ASSERT_CHK => 1,
      SRC_INPUT_REG  => 1,
      WIDTH          => 24 
   )
   port map (
      src_clk  => main_clk,
      src_in   => main_overlay,
      dest_clk => vga_clk,
      dest_out => vga_overlay
   ); -- xpm_cdc_array_single_inst


   --------------------------------------------------
   -- Instantiate VGA module
   --------------------------------------------------

   vga_inst : entity work.vga
   port map (
      clk_i     => vga_clk,
      digits_i  => vga_overlay,
      vga_hs_o  => vga_hs_o,
      vga_vs_o  => vga_vs_o,
      vga_col_o => vga_col_o
   ); -- vga_inst

end architecture Structural;

