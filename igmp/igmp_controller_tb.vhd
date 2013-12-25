-------------------------------------------------------------------------------
-- Title      : Testbench for design "igmp_wrapper"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : igmp_wrapper_tb.vhd
-- Author     : Colin Shea  <colinshea@Colin-Sheas-MacBook-Pro.local>
-- Company    : 
-- Created    : 2010-06-27
-- Last update: 2010-08-11
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2010 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2010-06-27  1.0      colinshea	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity igmp_wrapper_tb is

end igmp_wrapper_tb;

-------------------------------------------------------------------------------

architecture testbench of igmp_wrapper_tb is

  -- component generics
  constant gen_dataWidth : integer := 8;

  signal srcMAC     : std_logic_vector(47 downto 0):=X"010040506660";
  signal destMAC    : std_logic_vector(47 downto 0):=X"01005E1C1901";
  signal vlanEn     : std_logic := '1';
  signal vlanId     : std_logic_vector(11 downto 0):=X"06A";
  signal srcIP      : std_logic_vector(31 downto 0):=X"C0A80164";
  signal destIP     : std_logic_vector(31 downto 0):=X"EF9C1901";
  signal tx_ready_n : std_logic;
  signal tx_sof     : std_logic;
  signal tx_eof     : std_logic;
  signal tx_vld     : std_logic;
  signal tx_data    : std_logic_vector(7 downto 0);
  signal igmp_sof     : std_logic;
  signal igmp_eof     : std_logic;
  signal igmp_vld     : std_logic;
  signal igmp_data    : std_logic_vector(7 downto 0);
  -- component ports
  signal dataClk       : std_logic;
  signal reset         : std_logic;
  signal join          : std_logic;
  signal leave         : std_logic;
  signal respond       : std_logic;
  signal rspTime       : std_logic_vector(7 downto 0);
 -- signal destIP        : std_logic_vector(31 downto 0);
 -- signal destMAC       : std_logic_vector(47 downto 0);
--  signal messageSent   : std_logic;
--  signal out_join      : std_logic;
--  signal out_leave     : std_logic;
--  signal out_destMAC_o : std_logic_vector(47 downto 0);
--  signal out_destIP_o  : std_logic_vector(31 downto 0);
  signal out_enProc    : std_logic;
  signal out_enCommand : std_logic;

begin  -- testbench

  igmp_wrapper_1: entity work.igmp_wrapper
    port map (
      dataClk       => dataClk,
      reset         => reset,
      join          => join,
      leave         => leave,
      srcMAC        => srcMAC,
      srcIP         => srcIP,
      destMAC       => destMAC,
      destIP        => destIP,
      vlanEn        => vlanEn,
      vlanId        => vlanId,
      tx_ready_n    => tx_ready_n,
      tx_data       => tx_data,
      tx_vld        => tx_vld,
      tx_sof        => tx_sof,
      tx_eof        => tx_eof,
      igmp_data     => igmp_data,
      igmp_vld      => igmp_vld,
      igmp_sof      => igmp_sof,
      igmp_eof      => igmp_eof,
      out_enProc    => out_enProc,
      out_enCommand => out_enCommand
      );

  process
    begin
      dataClk <= '1';
      wait for 4 ns;
      dataClk <= '0';
      wait for 4 ns;
  end process;
    
  process
    begin
      reset <= '1';
      rspTime  <= (others => '0');
      leave <= '0';
      join <= '0';
      respond <= '0';
      tx_ready_n <= '1';
      wait for 24 ns;
      reset <= '0';
      join <= '1';
      tx_ready_n <= '0';
      wait for 8 ns;
      join <= '0';
      wait for 1 ms;
      respond <= '1';
      rspTime <= X"0A";
      wait for 8 ns;
      respond <= '0';
      wait for 1 sec;

      wait for 750 ns;
      leave <= '1';
      wait for 8 ns;
      leave <= '0';
      wait;
      
  end process;
  
 end testbench;


