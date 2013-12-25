-------------------------------------------------------------------------------
-- Title      : Testbench for design "checksum"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : checksum_tb.vhd
-- Author     :   <sheac@DRESDEN>
-- Company    : 
-- Created    : 2010-03-16
-- Last update: 2010-03-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2010 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2010-03-16  1.0      sheac	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity checksum_tb is

end checksum_tb;

-------------------------------------------------------------------------------

architecture testbench of checksum_tb is

  component checksum
    port (
      dataClk               : in  std_logic;
      reset                 : in  std_logic;
      start_checksum        : in  std_logic;
      multicast_ip          : in  std_logic_vector(31 downto 0);
      source_ip             : in  std_logic_vector(31 downto 0);
      checksum_done         : out std_logic;
      ipv4_layer_checksum_j : out std_logic_vector(15 downto 0);
      ipv4_layer_checksum_l : out std_logic_vector(15 downto 0);
      igmp_layer_checksum_j : out std_logic_vector(15 downto 0);
      igmp_layer_checksum_l : out std_logic_vector(15 downto 0));
  end component;

  -- component ports
  signal dataClk               : std_logic;
  signal reset                 : std_logic;
  signal start_checksum        : std_logic;
  signal multicast_ip          : std_logic_vector(31 downto 0);
  signal source_ip             : std_logic_vector(31 downto 0);
  signal checksum_done         : std_logic;
  signal ipv4_layer_checksum_j : std_logic_vector(15 downto 0);
  signal ipv4_layer_checksum_l : std_logic_vector(15 downto 0);
  signal igmp_layer_checksum_j : std_logic_vector(15 downto 0);
  signal igmp_layer_checksum_l : std_logic_vector(15 downto 0);

  -- clock
  signal Clk : std_logic := '1';

begin  -- testbench

  -- component instantiation
  DUT: checksum
    port map (
      dataClk               => dataClk,
      reset                 => reset,
      start_checksum        => start_checksum,
      multicast_ip          => multicast_ip,
      source_ip             => source_ip,
      checksum_done         => checksum_done,
      ipv4_layer_checksum_j => ipv4_layer_checksum_j,
      ipv4_layer_checksum_l => ipv4_layer_checksum_l,
      igmp_layer_checksum_j => igmp_layer_checksum_j,
      igmp_layer_checksum_l => igmp_layer_checksum_l);


     gen_data_clk : process
    begin
      dataClk <= '1';
      wait for 4 ns;
      dataClk <= '0';
      wait for 4 ns;
    end process;

 -- set the multicast address we are joining
 multicast_ip <= X"EF9C1901";
 -- provide the devices address
 source_ip    <= X"C0A80164";
 
 control : process
   begin
    reset <= '1';
    start_checksum <= '0';
    wait for 16 ns;
    reset <= '0';
    start_checksum <= '1';
    wait for 8 ns;
    start_checksum <= '0';
    wait;
end process;
end testbench;

-------------------------------------------------------------------------------
