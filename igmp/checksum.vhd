library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.util.all;

entity checksum is
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
    igmp_layer_checksum_l : out std_logic_vector(15 downto 0)
    );
end checksum;

architecture rtl of checksum is

  type   checkSumStateMachine is (init_s, calc_s, done_s);
  signal checksum_state : checkSumStateMachine := init_s;

  signal igmp_l, igmp_j, igmp_r1, igmp_r2, ipv4_j, ipv4_l, ipv4_r1, ipv4_r2 : unsigned(16 downto 0) := (others => '0');

  signal start_checksum_r            : std_logic                     := '0';
  signal multicast_ip_r, source_ip_r : std_logic_vector(31 downto 0) := (others => '0');

  signal chksum_sub_state : std_logic_vector(2 downto 0) := (others => '0');

 -- constant c_ipv4header   : std_logic_vector(15 downto 0) := "1000011000011110";
 -- constant c_igmpheader_j : std_logic_vector(15 downto 0) := "0001011000000000";
 -- constant c_igmpheader_l : std_logic_vector(15 downto 0) := "0001011100000000";
  constant c_leaveIP      : std_logic_vector(31 downto 0) := X"E0000002";
  --signal ipv4_r : std_logic_vector(16 downto 0);
begin  -- rtl
  
  register_incoming : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        start_checksum_r <= '0';
        multicast_ip_r   <= (others => '0');
        source_ip_r      <= (others => '0');
      else
        start_checksum_r <= start_checksum;
        multicast_ip_r   <= multicast_ip;
        source_ip_r      <= source_ip;
      end if;
    end if;
  end process;

  checksum_state_machine : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        igmp_l  <= (others => '0');
        igmp_j  <= (others => '0');
        igmp_r1 <= (others => '0');
        igmp_r2 <= (others => '0');

        ipv4_j                <= (others => '0');
        ipv4_l                <= (others => '0');
        ipv4_r1               <= (others => '0');
        ipv4_r2               <= (others => '0');
        ipv4_layer_checksum_j <= (others => '0');
        ipv4_layer_checksum_l <= (others => '0');
        igmp_layer_checksum_j <= (others => '0');
        igmp_layer_checksum_l <= (others => '0');
        checksum_done         <= '0';
        chksum_sub_state      <= (others => '0');
        checksum_done         <= '0';
      else
        case checksum_state is
          when init_s =>
            if(start_checksum_r = '1')then
              checksum_state <= calc_s;
              checksum_done  <= '0';
              igmp_l         <= ('0' & X"1700");  --(others => '0');
              igmp_j         <= ('0' & X"1600");  --(others => '0');
              ipv4_j         <= ('0' & X"861E");  --(others => '0');
              ipv4_l         <= ('0' & X"861E");  --(others => '0');
            else
              -- checksum_done  <= '0';
              checksum_state <= init_s;
            end if;
          when calc_s =>
            case chksum_sub_state is
              when "000" =>
                igmp_r1          <= igmp_j + ('0' & unsigned(multicast_ip_r(31 downto 16)));
                igmp_r2          <= igmp_l + ('0' & unsigned(multicast_ip_r(31 downto 16)));
                ipv4_r1          <= ipv4_j + ('0' & unsigned(source_ip_r(31 downto 16)));
                ipv4_r2          <= ipv4_l + ('0' & unsigned(source_ip_r(31 downto 16)));
                chksum_sub_state <= "001";
              when "001" =>
                igmp_j           <= ('0' & igmp_r1(15 downto 0)) + igmp_r1(16);
                igmp_l           <= ('0' & igmp_r2(15 downto 0)) + igmp_r2(16);
                ipv4_j           <= ('0' & ipv4_r1(15 downto 0)) + ipv4_r1(16);
                ipv4_l           <= ('0' & ipv4_r2(15 downto 0)) + ipv4_r2(16);
                chksum_sub_state <= "010";
              when "010" =>
                -- Addition for the carry bit
                igmp_r1          <= ('0' & igmp_j(15 downto 0)) + ('0' & unsigned(multicast_ip_r(15 downto 0)));
                igmp_r2          <= ('0' & igmp_l(15 downto 0)) + ('0' & unsigned(multicast_ip_r(15 downto 0)));
                ipv4_r1          <= ('0' & ipv4_j(15 downto 0)) + ('0' & unsigned(source_ip_r(15 downto 0)));
                ipv4_r2          <= ('0' & ipv4_l(15 downto 0)) + ('0' & unsigned(source_ip_r(15 downto 0)));
                chksum_sub_state <= "011";
              when "011" =>
                igmp_j           <= ('0' & igmp_r1(15 downto 0))+ igmp_r1(16);
                igmp_l           <= ('0' & igmp_r2(15 downto 0))+ igmp_r2(16);
                ipv4_j           <= ('0' & ipv4_r1(15 downto 0)) + ipv4_r1(16);
                ipv4_l           <= ('0' & ipv4_r2(15 downto 0)) + ipv4_r2(16);
                chksum_sub_state <= "100";
              when "100" =>
                ipv4_r1          <= ('0' & ipv4_j(15 downto 0)) + unsigned(multicast_ip_r(31 downto 16));
                ipv4_r2          <= ('0' & ipv4_l(15 downto 0)) + unsigned(c_leaveIP(31 downto 16));
                chksum_sub_state <= "101";
              when "101" =>
                ipv4_j           <= ('0' & ipv4_r1(15 downto 0)) + ipv4_r1(16);
                ipv4_l           <= ('0' & ipv4_r2(15 downto 0)) + ipv4_r2(16);
                chksum_sub_state <= "110";
              when "110" =>
                ipv4_r1          <= ('0' & ipv4_j(15 downto 0)) + unsigned(multicast_ip_r(15 downto 0));
                ipv4_r2          <= ('0' & ipv4_l(15 downto 0)) + unsigned(c_leaveIP(15 downto 0));
                chksum_sub_state <= "111";
              when "111" =>
                ipv4_j           <= ('0' & ipv4_r1(15 downto 0)) + ipv4_r1(16);
                ipv4_l           <= ('0' & ipv4_r2(15 downto 0)) + ipv4_r2(16);
                chksum_sub_state <= "000";
                checksum_state   <= done_s;
                --when "111" =>
                --  ipv4_layer_checksum_j <= std_logic_vector(ipv4);
                --  ipv4_layer_checksum_l <= std_logic_vector(ipv4_t);
                --  igmp_layer_checksum_j <= std_logic_vector(igmp_j);
                --  igmp_layer_checksum_l <= std_logic_vector(igmp_l);
                --  checksum_done         <= '1';
              when others =>
                ipv4_layer_checksum_j <= (others => '0');
                ipv4_layer_checksum_l <= (others => '0');
                igmp_layer_checksum_j <= (others => '0');
                igmp_layer_checksum_l <= (others => '0');
                checksum_done         <= '0';
            end case;
          when done_s =>
            ipv4_layer_checksum_j <= vecInvert(std_logic_vector(ipv4_j(15 downto 0)));
            ipv4_layer_checksum_l <= vecInvert(std_logic_vector(ipv4_l(15 downto 0)));
            igmp_layer_checksum_j <= vecInvert(std_logic_vector(igmp_j(15 downto 0)));
            igmp_layer_checksum_l <= vecInvert(std_logic_vector(igmp_l(15 downto 0)));
            checksum_done         <= '1';
            checksum_state        <= init_s;
        end case;
      end if;
    end if;
  end process;
  
end rtl;
