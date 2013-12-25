-------------------------------------------------------------------------------
-- Title      : Testbench for design "igmp_processor"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : igmp_processor_tb.vhd
-- Author     :   <sheac@DRESDEN>
-- Company    : 
-- Created    : 2010-06-26
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
-- 2010-06-26  1.0      sheac	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity igmp_processor_tb is
end igmp_processor_tb;

architecture testbench of igmp_processor_tb is

  component igmp_processor
    generic (
      gen_dataWidth : integer);
    port (
      dataClk   : in  std_logic;
      reset     : in  std_logic;
      in_destIP : in  std_logic_vector(31 downto 0);
      igmp_data : in  std_logic_vector(gen_dataWidth - 1 downto 0);
      igmp_vld  : in  std_logic;
      igmp_sof  : in  std_logic;
      igmp_eof  : in  std_logic;
      respond   : out std_logic;
      rsptime   : out std_logic_vector(gen_dataWidth - 1 downto 0));
  end component;

  -- component generics
  constant gen_dataWidth : integer := 8;

  -- component ports
  signal dataClk   : std_logic;
  signal reset     : std_logic;
  signal in_destIP : std_logic_vector(31 downto 0);
  signal igmp_data : std_logic_vector(gen_dataWidth - 1 downto 0);
  signal igmp_vld  : std_logic;
  signal igmp_sof  : std_logic;
  signal igmp_eof  : std_logic;
  signal respond   : std_logic;
  signal rsptime   : std_logic_vector(gen_dataWidth - 1 downto 0);

begin  -- testbench
  
  -- component instantiation
  DUT: igmp_processor
    generic map (
      gen_dataWidth => gen_dataWidth)
    port map (
      dataClk   => dataClk,
      reset     => reset,
      in_destIP => in_destIP,
      igmp_data => igmp_data,
      igmp_vld  => igmp_vld,
      igmp_sof  => igmp_sof,
      igmp_eof  => igmp_eof,
      respond   => respond,
      rsptime   => rsptime);

  process
  begin
    dataClk <= '1';
    wait for 4 ns;
    dataClk <= '0';
    wait for 4 ns;
  end process;

  in_destIP <= X"E1234223";

  process
    begin
      reset <= '1';
      igmp_data <= (others => '0');
      igmp_vld <= '0';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 24 ns;
      reset <= '0';
      wait for 16 ns;
      igmp_data <= X"11";
      igmp_vld <= '1';
      igmp_sof <= '1';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"64";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"12";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"56";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"E1";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"23";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"42";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '0';
      wait for 8 ns;
      igmp_data <= X"23";
      igmp_vld <= '1';
      igmp_sof <= '0';
      igmp_eof <= '1';
      wait for 8 ns;
      igmp_eof <= '0';
      wait;
    end process; 
end testbench;

