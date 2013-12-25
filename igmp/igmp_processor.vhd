-------------------------------------------------------------------------------
-- Title        : IGMP processor
-- Project      : 
-------------------------------------------------------------------------------
--! @file       : igmp_processor.vhd
-- Author       : Colin W. Shea
-- Company
-- Last update  : 2010-06-01
-- Platform     : Virtex 4/5/6
-------------------------------------------------------------------------------
--
--* @brief parsing incoming data stream for igmp requests 
--
--! @details: This module parses the incoming stream of igmp data and signals
--the igmp controller for the packet type ie which response needs to be generated.
--!         
--!
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity igmp_processor is
  generic (
    gen_dataWidth : integer := 8
    );
  port (
    dataClk   : in  std_logic;
    reset     : in  std_logic;
    in_destIP : in  std_logic_vector(31 downto 0);
    igmp_data : in  std_logic_vector(gen_dataWidth - 1 downto 0);
    igmp_vld  : in  std_logic;
    igmp_sof  : in  std_logic;
    igmp_eof  : in  std_logic;
    respond   : out std_logic;
    rsptime   : out std_logic_vector(gen_dataWidth - 1 downto 0)
    );
end igmp_processor;

architecture rtl of igmp_processor is
  signal igmp_data_r : std_logic_vector(gen_dataWidth - 1 downto 0) := (others => '0');
  signal igmp_vld_r  : std_logic                                    := '0';
  signal igmp_sof_r  : std_logic                                    := '0';
--  signal igmp_eof_r  : std_logic;

  signal igmp_data_r2 : std_logic_vector(gen_dataWidth - 1 downto 0) := (others => '0');
  signal igmp_vld_r2  : std_logic                                    := '0';
  signal igmp_sof_r2  : std_logic                                    := '0';
--  signal igmp_eof_r2  : std_logic;

  signal destIP       : std_logic_vector(31 downto 0) := (others => '0');
  signal igmpState    : std_logic_vector(2 downto 0) := (others => '0');
  signal responseTime : std_logic_vector(7 downto 0) := (others => '0');
  signal byteCount    : integer range 0 to 2         := 0;

begin  -- trl
  
  register_in_coming_data : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        igmp_data_r  <= (others => '0');
        igmp_vld_r   <= '0';
        igmp_sof_r   <= '0';
        --    igmp_eof_r   <= '0';
        igmp_data_r2 <= (others => '0');
        igmp_vld_r2  <= '0';
        igmp_sof_r2  <= '0';
        --  igmp_eof_r2  <= '0';
      else
        igmp_data_r  <= igmp_data;
        igmp_vld_r   <= igmp_vld;
        igmp_sof_r   <= igmp_sof;
        --  igmp_eof_r   <= igmp_eof;
        igmp_data_r2 <= igmp_data_r;
        igmp_vld_r2  <= igmp_vld_r;
        igmp_sof_r2  <= igmp_sof_r;
        --  igmp_eof_r2  <= igmp_eof_r;
      end if;
    end if;
  end process;

  process_imcoming_stream : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        igmpState    <= (others => '0');
        byteCount    <= 0;
        respond      <= '0';
        rsptime      <= (others => '0');
        responseTime <= (others => '0');
        destIP       <= (others => '0');
      else
        if(igmp_vld_r2 = '1')then
          case igmpState is
            when "000" =>
              respond <= '0';
              if(igmp_sof_r2 = '1' and igmp_data_r2 = X"11")then
                igmpState <= "001";
              else
                igmpState <= "000";
              end if;
            when "001" =>
              responseTime <= igmp_data_r2;
              igmpState    <= "010";
              byteCount    <= 2;
            when "010" =>
              if(byteCount = 1)then
                igmpState <= "011";
              else
                igmpState <= "010";
                byteCount <= byteCount -1;
              end if;
            when "011" =>
              destIP(31 downto 24) <= igmp_data_r2;
              igmpState            <= "100";
            when "100" =>
              destIP(23 downto 16) <= igmp_data_r2;
              igmpState            <= "101";
            when "101" =>
              destIP(15 downto 8) <= igmp_data_r2;
              igmpState           <= "110";
            when "110" =>
              destIP(7 downto 0) <= igmp_data_r2;
              igmpState          <= "111";
            when "111" =>
              if((destIP = in_destIP) or (destIP = X"00000000"))then
                respond <= '1';
                rsptime <= responseTime;
              else
                respond <= '0';
              end if;
              igmpState <= "000";
            when others =>
              igmpState <= "000";
          end case;
        else
          respond <= '0';
        end if;
      end if;
    end if;
  end process;
end rtl;
