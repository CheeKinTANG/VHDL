-------------------------------------------------------------------------------
-- Title        : IGMP Wrapper
-- Project      : 
-------------------------------------------------------------------------------
--! @file       : igmp_wrapper.vhd
-- Author       : Colin W. Shea
-- Company
-- Last update  : 2010-03-15
-- Platform     : Virtex 4/5/6
-------------------------------------------------------------------------------
--
--* @brief 
--
--! @details: 
--!         
--!
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity igmp_wrapper is
  generic (
    gen_dataWidth : integer := 8;
    simulation : boolean := false
    );
  port (
    dataClk       : in  std_logic;
    reset         : in  std_logic;
    join          : in  std_logic;
    leave         : in  std_logic;
    -- 
    srcMAC        : in  std_logic_vector(47 downto 0);
    srcIP         : in  std_logic_vector(31 downto 0);
    destMAC       : in  std_logic_vector(47 downto 0);
    destIP        : in  std_logic_vector(31 downto 0);
    vlanEn        : in  std_logic;
    vlanId        : in  std_logic_vector(11 downto 0);
    -- 
    tx_ready_n    : in  std_logic;
    tx_data       : out std_logic_vector(7 downto 0);
    tx_vld        : out std_logic;
    tx_sof        : out std_logic;
    tx_eof        : out std_logic;
    -- incoming igmp data
    igmp_data     : in  std_logic_vector(7 downto 0);
    igmp_vld      : in  std_logic;
    igmp_sof      : in  std_logic;
    igmp_eof      : in  std_logic;
    -- enable processing of packets
    out_enProc    : out std_logic;
    -- enable new commands to be accepted
    out_enCommand : out std_logic
    );
end igmp_wrapper;

architecture rtl of igmp_wrapper is
  signal rspTime_i     : std_logic_vector(7 downto 0)  := (others => '0');
  signal respond_i     : std_logic                     := '0';
  signal messageSent_i : std_logic                     := '0';
  signal destMAC_i     : std_logic_vector(47 downto 0) := (others => '0');
  signal destIP_i      : std_logic_vector(31 downto 0) := (others => '0');
  signal join_i        : std_logic                     := '0';
  signal leave_i       : std_logic                     := '0';
begin  -- rtl
  
  igmp_processor_module : entity work.igmp_processor
    generic map (
      gen_dataWidth => gen_dataWidth)
    port map (
      dataClk   => dataClk,
      reset     => reset,
      in_destIP => destIP,
      igmp_data => igmp_data,
      igmp_vld  => igmp_vld,
      igmp_sof  => igmp_sof,
      igmp_eof  => igmp_eof,
      respond   => respond_i,
      rsptime   => rsptime_i
      );

  igmp_controller_module : entity work.igmp_controller
    generic map (
      gen_dataWidth => gen_dataWidth,
      simulation    => simulation)
    port map (
      dataClk       => dataClk,
      reset         => reset,
      join          => join,
      leave         => leave,
      respond       => respond_i,
      rspTime       => rspTime_i,
      destIP        => destIP,
      destMAC       => destMAC,
      messageSent   => messageSent_i,
      out_join      => join_i,
      out_leave     => leave_i,
      out_destMAC_o => destMAC_i,
      out_destIP_o  => destIP_i,
      out_enProc    => out_enProc,
      out_enCommand => out_enCommand
      );

  igmp_assembler_module : entity work.igmp_assembler
    generic map (
      gen_dataWidth => gen_dataWidth)
    port map (
      dataClk     => dataClk,
      reset       => reset,
      srcMAC      => srcMAC,
      destMAC     => destMAC_i,
      vlanEn      => vlanEn,
      vlanId      => vlanId,
      srcIP       => srcIP,
      destIP      => destIP_i,
      join        => join_i,
      leave       => leave_i,
      tx_ready_n  => tx_ready_n,
      messageSent => messageSent_i,
      tx_sof      => tx_sof,
      tx_eof      => tx_eof,
      tx_vld      => tx_vld,
      tx_data     => tx_data
      );

end rtl;
