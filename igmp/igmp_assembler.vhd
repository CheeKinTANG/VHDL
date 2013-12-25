-------------------------------------------------------------------------------
-- Title        : IGMP Assembler
-- Project      : 
-------------------------------------------------------------------------------
--! @file       : igmp_assembler.vhd
-- Author       : Colin W. Shea
-- Company
-- Last update  : 2010-03-15
-- Platform     : Virtex 4/5/6
-------------------------------------------------------------------------------
--
--* @brief Assemble the IGMP Packet 
--
--! @details: This module creates the IGMP packet for the join, report, and leave.
--!           All values are prestored in constants and used as needed.
--!
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity igmp_assembler is
  generic (
    gen_dataWidth : integer := 8
    );
  port (
    dataClk     : in  std_logic;
    reset       : in  std_logic;
    -- packet constuctor information signals 
    srcMAC      : in  std_logic_vector(47 downto 0);
    destMAC     : in  std_logic_vector(47 downto 0);
    vlanEn      : in  std_logic;
    vlanId      : in  std_logic_vector(11 downto 0);
    srcIP       : in  std_logic_vector(31 downto 0);
    destIP      : in  std_logic_vector(31 downto 0);
    -- control signals
    join        : in  std_logic;
    leave       : in  std_logic;
    tx_ready_n  : in  std_logic;
    messageSent : out std_logic;
    tx_sof      : out std_logic;
    tx_eof      : out std_logic;
    tx_vld      : out std_logic;
    tx_data     : out std_logic_vector(7 downto 0)
    );
end igmp_assembler;

architecture rtl of igmp_assembler is
  type     ipv4Header is array(9 downto 0) of std_logic_vector(7 downto 0);
  constant headerValues                                                        : ipv4Header                    := (X"45", X"00", X"00", X"1C", X"00", X"00", X"40", X"00", X"01", X"02");
  constant c_vlanType                                                          : std_logic_vector(15 downto 0) := X"8100";
  constant c_packetType                                                        : std_logic_vector(15 downto 0) := X"0800";
  signal   assembly_state                                                      : std_logic_vector(3 downto 0)  := (others => '0');
  signal   byteCount                                                           : integer range 0 to 9          := 0;
  signal   done                                                                : std_logic                     := '0';
  signal   ipv4_layer_checksum_join, ipv4_layer_checksum_leave                 : std_logic_vector(15 downto 0) := (others => '0');
  signal   igmp_layer_checksum_join, igmp_layer_checksum_leave                 : std_logic_vector(15 downto 0) := (others => '0');
  signal   join_r, join_r2, leave_r, leave_r2, join_hold, leave_hold, rsp_hold : std_logic                     := '0';
  signal   igmpType                                                            : std_logic_vector(7 downto 0)  := (others => '0');
  signal   ipv4Checksum                                                        : std_logic_vector(15 downto 0) := (others => '0');
  signal   igmpChecksum                                                        : std_logic_vector(15 downto 0) := (others => '0');
  signal   ipv4Address                                                         : std_logic_vector(31 downto 0) := (others => '0');
  signal   groupaddress                                                        : std_logic_vector(31 downto 0) := (others => '0');
  -- 2 1 0 
  signal   currentState                                                        : std_logic_vector(2 downto 0)  := (others => '0');
  signal   startChecksum                                                       : std_logic                     := '0';
  -- bit 2 join
  -- bit 1 leave
  signal   srcMAC_r                                                            : std_logic_vector(47 downto 0);
  signal   destMAC_r                                                           : std_logic_vector(47 downto 0);
  signal   vlanEn_r                                                            : std_logic;
  signal   vlanId_r                                                            : std_logic_vector(11 downto 0);
  signal   srcIP_r                                                             : std_logic_vector(31 downto 0);
  signal   destIP_r                                                            : std_logic_vector(31 downto 0);
  signal   tx_ready_n_r                                                        : std_logic;
begin

  register_and_hold_join_rsp_leave : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        --rsp_r <= '0';
        --rsp_r2 <= '0';
        join_r   <= '0';
        leave_r  <= '0';
        join_r2  <= '0';
        leave_r2 <= '0';
      else
        join_r       <= join;
        leave_r      <= leave;
        join_r2      <= join_r;
        leave_r2     <= leave_r;
        srcMAC_r     <= srcMAC;
        destMAC_r    <= destMAC;
        vlanEn_r     <= vlanEn;
        vlanId_r     <= vlanId;
        srcIP_r      <= srcIP;
        destIP_r     <= destIP;
        tx_ready_n_r <= tx_ready_n;     
      end if;
    end if;
  end process;

  new_one : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        --   tx_ready_n     <= '0';
        tx_data        <= (others => '0');
        tx_eof         <= '0';
        tx_sof         <= '0';
        tx_vld         <= '0';
        assembly_state <= (others => '0');
        igmpType       <= (others => '0');
        byteCount      <= 0;
        ipv4Checksum   <= (others => '0');
        igmpChecksum   <= (others => '0');
        groupAddress   <= (others => '0');
        ipv4Address    <= (others => '0');
        currentState   <= "000";
        messageSent    <= '0';
        startChecksum  <= '0';
      else
        if(tx_ready_n_r = '0')then
          messageSent <= '0';
          case assembly_state is
            when "0001" =>
              startChecksum <= '0';
              if(done = '1')then
                if(currentState = "100" or currentState = "001")then
                  ipv4Checksum <= ipv4_layer_checksum_join;
                  igmpChecksum <= igmp_layer_checksum_join;
                  ipv4Address  <= destIP_r;
                  groupAddress <= destIP_r;

                  assembly_state <= "0010";
                  igmpType       <= X"16";
                  byteCount      <= 6;
                elsif(currentState = "010")then
                  ipv4Checksum <= ipv4_layer_checksum_leave;
                  igmpChecksum <= igmp_layer_checksum_leave;
                  ipv4Address  <= X"E0000002";
                  groupAddress <= destIP_r;

                  assembly_state <= "0010";
                  igmpType       <= X"17";
                  byteCount      <= 6;
                else
                  ipv4Checksum   <= (others => '0');
                  igmpChecksum   <= (others => '0');
                  assembly_state <= (others => '0');
                  igmpType       <= (others => '0');
                  byteCount      <= 0;
                end if;
              end if;
            when "0010" =>
              assembly_state <= "0010";
              if(byteCount = 6)then
                tx_sof    <= '1';
                tx_data   <= destMAC_r(47 downto 40);
                byteCount <= byteCount - 1;
              elsif(byteCount > 1)then
                tx_sof    <= '0';
                tx_data   <= destMAC_r((8*byteCount)-1 downto 8*(byteCount - 1));
                byteCount <= byteCount - 1;
              elsif(byteCount = 1)then
                tx_data        <= destMAC_r(7 downto 0);
                assembly_state <= "0011";
                byteCount      <= 6;
              end if;
              tx_vld <= '1';
              
              
            when "0011" =>
              assembly_state <= "0011";
              if(byteCount = 6)then
                tx_data   <= srcMAC_r(47 downto 40);
                byteCount <= byteCount - 1;
              elsif(byteCount > 1)then
                tx_sof    <= '0';
                tx_data   <= srcMAC_r((8*byteCount)-1 downto 8*(byteCount - 1));
                byteCount <= byteCount - 1;
              elsif(byteCount = 1)then
                tx_data <= srcMAC_r(7 downto 0);
                if(vlanEn_r = '1')then
                  assembly_state <= "0100";
                  byteCount      <= 3;
                else
                  assembly_state <= "0101";
                  byteCount      <= 2;
                end if;
                --   else
                --   assembly_state <= "000000010";
              end if;
              tx_vld <= '1';
              

            when "0100" =>
              assembly_state <= "0100";
              tx_vld         <= '1';

              if(byteCount = 3)then
                tx_data   <= c_vlanType(15 downto 8);
                byteCount <= byteCount - 1;
              elsif(byteCount = 2)then
                tx_data   <= c_vlanType(7 downto 0);
                byteCount <= byteCount - 1;
              elsif(byteCount = 1)then
                tx_data   <= "0000" & vlanId_r(11 downto 8);
                byteCount <= byteCount - 1;
              elsif(byteCount = 0)then
                tx_data        <= vlanId_r(7 downto 0);
                byteCount      <= 2;
                assembly_state <= "0101";
              end if;
              
            when "0101" =>
              assembly_state <= "0101";
              tx_vld         <= '1';
              if(byteCount = 2)then
                tx_data   <= c_packetType(15 downto 8);
                byteCount <= byteCount - 1;
              else
                tx_data        <= c_packetType(7 downto 0);
                assembly_state <= "0110";
                byteCount      <= 9;
              end if;
              
            when "0110" =>
              if(byteCount = 0)then
                assembly_state <= "0111";
                byteCount      <= 1;
              else
                byteCount <= byteCount - 1;
              end if;
              tx_data <= headerValues(byteCount);
              tx_vld  <= '1';
              
            when "0111" =>
              if(byteCount = 0)then
                assembly_state <= "1000";
                byteCount      <= 3;
              else
                byteCount      <= byteCount-1;
                assembly_state <= "0111";
              end if;

              tx_data <= ipv4Checksum(((byteCount+1)*8)-1 downto byteCount*8);
              tx_vld  <= '1';
            when "1000" =>
              if(byteCount = 0)then
                assembly_state <= "1001";
                byteCount      <= 3;
              else
                assembly_state <= "1000";
                byteCount      <= byteCount - 1;
              end if;
              tx_vld  <= '1';
              tx_data <= srcIP_r(((byteCount+1)*8)-1 downto byteCount*8);

            when "1001" =>
              if(byteCount = 0)then
                assembly_state <= "1100";
                byteCount      <= 1;
              else
                assembly_state <= "1001";
                byteCount      <= byteCount - 1;
              end if;

              tx_data <= ipv4Address((byteCount+1)*8-1 downto byteCount*8);
              tx_vld  <= '1';
              
            when "1100" =>
              byteCount      <= 1;
              assembly_state <= "1101";
              tx_data        <= igmpType;
              tx_vld         <= '1';
              
            when "1101" =>
              tx_data        <= X"00";
              tx_vld         <= '1';
              assembly_state <= "1110";
              
            when "1110" =>
              if(byteCount = 0)then
                byteCount      <= 3;
                assembly_state <= "1111";
              else
                byteCount      <= byteCount - 1;
                assembly_state <= "1110";
              end if;
              tx_data <= igmpChecksum(8*(byteCount+1)-1 downto byteCount*8);

              tx_vld <= '1';
              
            when "1111" =>
              if(byteCount = 0)then
                byteCount      <= 0;
                messageSent    <= '1';
                assembly_state <= "0000";  --(others => '0');
                currentState   <= "000";
                tx_eof         <= '1';
              else
                byteCount      <= byteCount - 1;
                assembly_state <= "1111";
              end if;
              tx_data <= groupAddress(8*(byteCount+1)-1 downto byteCount*8);
              tx_vld  <= '1';
              
              
            when "0000" =>
              tx_eof <= '0';
              tx_vld <= '0';
              if((join_r = '1' and join_r2 = '0') or (leave_r = '1' and  leave_r2 = '0'))then
                currentState   <= join_r & leave_r & '0';
                assembly_state <= "0001";
              else
                assembly_state <= "0000";
              end if;
              if(join_r = '1')then
                startChecksum <= '1';
              else
                startChecksum <= '0';
              end if;
            when others =>
              
              
          end case;
          
        else
          tx_vld <= '0';
          tx_sof <= '0';
          tx_eof <= '0';
        end if;

        -- tx_sof <= '0';
        -- tx_eof <= '0';
        -- tx_vld <= '0';
      end if;
    end if;
  end process;

  create_checksum : entity work.checksum
    port map (
      dataClk               => dataClk,
      reset                 => reset,
      start_checksum        => startChecksum,
      multicast_ip          => destIP,
      source_ip             => srcIP,
      checksum_done         => done,
      ipv4_layer_checksum_j => ipv4_layer_checksum_join,
      ipv4_layer_checksum_l => ipv4_layer_checksum_leave,
      igmp_layer_checksum_j => igmp_layer_checksum_join,
      igmp_layer_checksum_l => igmp_layer_checksum_leave
      );

end rtl;

