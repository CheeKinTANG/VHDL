-------------------------------------------------------------------------------
-- Title      : Testbench for design "igmp_assembler"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : igmp_assembler_tb.vhd
-- Author     :   <Kelly@APOLLO>
-- Company    : 
-- Created    : 2010-05-21
-- Last update: 2010-06-27
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2010 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2010-05-21  1.0      Kelly	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity igmp_assembler_tb is

end igmp_assembler_tb;

-------------------------------------------------------------------------------

architecture testbench of igmp_assembler_tb is

  -- component generics
  constant gen_dataWidth : integer := 8;

  -- component ports
  signal dataClk    : std_logic;
  signal reset      : std_logic;
  signal srcMAC     : std_logic_vector(47 downto 0):=X"010040506660";
  signal destMAC    : std_logic_vector(47 downto 0):=X"01005E1C1901";
  signal vlanEn     : std_logic;
  signal vlanId     : std_logic_vector(11 downto 0):=X"06A";
  signal srcIP      : std_logic_vector(31 downto 0):=X"C0A80164";
  signal destIP     : std_logic_vector(31 downto 0):=X"EF9C1901";
  signal join       : std_logic;
  signal respond    : std_logic;
  signal leave      : std_logic;
  signal tx_ready_n : std_logic;
  signal tx_sof     : std_logic;
  signal tx_eof     : std_logic;
  signal tx_vld     : std_logic;
  signal tx_data    : std_logic_vector(7 downto 0);

begin  -- testbench

   -- generate the clock
  process
    begin
      dataClk <= '0';
      wait for 4 ns;
      dataClk <= '1';
      wait for 4 ns;
  end process;

  -- component instantiation
  igmp_assembler_entity: entity work.igmp_assembler
    generic map (
      gen_dataWidth => gen_dataWidth)
    port map (
      dataClk    => dataClk,
      reset      => reset,
      srcMAC     => srcMAC,
      destMAC    => destMAC,
      vlanEn     => vlanEn,
      vlanId     => vlanId,
      srcIP      => srcIP,
      destIP     => destIP,
      join       => join,
      messageSent => open,
      leave      => leave,
      tx_ready_n => tx_ready_n,
      tx_sof     => tx_sof,
      tx_eof     => tx_eof,
      tx_vld     => tx_vld,
      tx_data    => tx_data
      );


vlanEn <= '1';
      
  process
    begin
      reset      <= '1';
      
      join       <= '0';
      respond    <= '0';
      leave      <= '0';
      tx_ready_n <= '0';
      wait for 16 ns;
      reset <= '0';
      join <= '1';
      wait for 16 ns;
            join <= '0';
      
      wait for 450 ns;
      leave <= '1';
      wait for 16 ns;
      leave <= '0';
      wait;
    end process;

end testbench;

