-------------------------------------------------------------------------------
-- Title        : IGMP Controller
-- Project      : 
-------------------------------------------------------------------------------
--! @file       : igmp_controller.vhd
-- Author       : Colin W. Shea
-- Company
-- Last update  : 2010-03-15
-- Platform     : Virtex 4/5/6
-------------------------------------------------------------------------------
--
--* @brief Control the production of the IGMP Packet 
--
--! @details: This module controls and manages the IGMP packet for the join, report, and leave.
--!         
--!
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity igmp_controller is
  generic (
    gen_dataWidth : integer := 8;
    simulation : boolean := false
    );
  port (
    dataClk     : in std_logic;
    reset       : in std_logic;
    ----------------------------------------------------------
    join        : in std_logic;
    leave       : in std_logic;
    -- comes from igmp processor
    respond     : in std_logic;
    -- tell the controller of gen query typoe by response time
    rspTime     : in std_logic_vector(7 downto 0);
    ---------------------------------------------------------
    destIP      : in std_logic_vector(31 downto 0);
    destMAC     : in std_logic_vector(47 downto 0);
    messageSent : in std_logic;

    out_join      : out std_logic;
    out_leave     : out std_logic;
    out_destMAC_o : out std_logic_vector(47 downto 0);
    out_destIP_o  : out std_logic_vector(31 downto 0);
    -- enable processing of packets
    out_enProc    : out std_logic;
    -- enable new commands to be accepted
    out_enCommand : out std_logic
    );
end igmp_controller;

architecture rtl of igmp_controller is
  signal stateEn       : std_logic_vector(2 downto 0) := (others => '0');
 -- signal start_timer   : std_logic                    := '0';
  signal resetTimer    : std_logic                    := '0';
  signal resetOverride : std_logic                    := '0';

  signal waitTime  : std_logic_vector(7 downto 0) := (others => '0');
  signal timerDone : std_logic                    := '0';
  signal join_r    : std_logic                    := '0';
  signal join_r2   : std_logic                    := '0';
  signal rsp_r     : std_logic                    := '0';
  signal rsp_r2    : std_logic                    := '0';
  signal leave_r   : std_logic                    := '0';
  signal leave_r2  : std_logic                    := '0';
  signal rspToggle : std_logic                    := '0';

  type   igmpController_type is (wait_s, join_s, respond_s, leave_s);
  signal controllerState : igmpController_type := wait_s;

  signal enableProcessing : std_logic := '0';

--  signal joinSignal  : std_logic;
--  signal leaveSignal : std_logic;
  signal destMAC_t : std_logic_vector(47 downto 0) := (others => '0');
  signal destIP_t  : std_logic_vector(31 downto 0) := (others => '0');
  signal grpRQ     : std_logic                     := '0';
  signal brdRQ     : std_logic                     := '0';
  -- signal stateEn_r : std_logic_vector(2 downto 0);
  --signal waitTime_r : std_logic_vector(7 downto 0);
  signal newRsp    : std_logic                     := '0';
begin  -- trl

  -- monitor input of a new request
  -- i.e. the only over riding response is a leave during response
  -- joins via joins ignored

  register_command_input : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        join_r    <= '0';
        join_r2   <= '0';
        rsp_r     <= '0';
        rsp_r2    <= '0';
        leave_r   <= '0';
        leave_r2  <= '0';
        waitTime  <= (others => '0');
        --    waitTime_r <= (others => '0');
        rspToggle <= '0';
        stateEn   <= (others => '0');
      else
        join_r   <= join;
        join_r2  <= join_r;
        rsp_r    <= respond;
        rsp_r2   <= rsp_r;
        leave_r  <= leave;
        leave_r2 <= leave_r;
        --catch rising edges
        if(join_r = '1' and join_r2 = '0')then
          stateEn <= "100";
        elsif(rsp_r = '1' and rsp_r2 = '0')then
          stateEn   <= "010";
          waitTime  <= rspTime;
          rspToggle <= not rspToggle;
          --  waitTime_r <= waitTime;
        elsif(leave_r = '1' and leave_r2 = '0')then
          stateEn <= "001";
        elsif(messageSent = '1')then
          stateEn <= "000";
        else
          stateEn <= stateEn;
        end if;
        -- stateEn_r <= stateEn;
      end if;
    end if;
  end process;

  process_input_requests : process(dataClk, reset)
  begin
    if(rising_edge(dataClk))then
      if(reset = '1')then
        resetOverride   <= '0';
        controllerState <= wait_s;
        out_enCommand   <= '0';
        out_enProc      <= '0';
        out_join        <= '0';
        out_leave       <= '0';
       
        grpRQ           <= '0';
        brdRQ           <= '0';
       

        out_destIP_o  <= (others => '0');
        out_destMAC_o <= (others => '0');
        destMAC_t     <= (others => '0');
        destIP_t      <= (others => '0');
      else
        case controllerState is
          when wait_s =>
            
            if(stateEn = "100")then
              controllerState <= join_s;
              --joinSignal      <= '1';
              --leaveSignal     <= '0';
              destMAC_t       <= destMAC;
              destIP_t        <= destIP;
              out_enCommand   <= '1';
              out_join        <= '1';
            elsif(stateEn = "010")then
              
              if(waitTime = X"0A")then
                
                grpRQ <= '1';
              elsif(waitTime = X"64")then
                brdRQ <= '1';
                
              end if;
              controllerState <= respond_s;
              -- if in top level simulation mode, don't wait for the timer.
              -- just send the join immediately.
              if simulation then
                out_join        <= '1';
              end if;
                
              -- joinSignal      <= '1';
             
              out_enCommand   <= '1';

            elsif(stateEn = "001")then
              out_leave       <= '1';
              out_enCommand   <= '0';
              -- joinSignal    <= '0';
              -- leaveSignal     <= '1';
              controllerState <= leave_s;
              destMAC_t       <= X"01005E000002";
              destIP_t        <= destIP;
            else
              out_enCommand <= '1';
            end if;
            
          when join_s =>
            out_destMAC_o <= destMAC_t;
            out_destIP_o  <= destIP_t;
            if(messageSent = '1')then
              out_enProc      <= '1';
              out_enCommand   <= '1';
              controllerState <= wait_s;
              -- out_join        <= '0';
            else
              -- out_join        <= '1';
              out_enProc      <= '0';
              out_enCommand   <= '0';
              controllerState <= join_s;
            end if;
            out_join <= '0';

          when respond_s =>
            
            if(messageSent = '1')then
              grpRQ           <= '0';
              brdRQ           <= '0';
              out_enCommand   <= '1';
              controllerState <= wait_s;
              out_join        <= '0';
            else
              -- while we are waiting for the timer, if we get a leave,
              -- suppress the keep alive and send a leave.
              if(stateEn = "001")then
                resetOverride   <= '1';
                out_leave       <= '1';
                controllerState <= leave_s;
                destMAC_t       <= X"01005E000002";
                destIP_t        <= destIP;
              else
                if (timerDone = '1')then
                  out_join <= '1';
                else
                  out_join <= '0';
                end if;
                out_enCommand   <= '0';
                controllerState <= respond_s;
              end if;
            end if;
            
          when leave_s =>
            grpRQ         <= '0';
            brdRQ         <= '0';
            resetOverride <= '0';
            if(messageSent = '1')then
              out_destMAC_o   <= (others => '0');
              out_destIP_o    <= (others => '0');
              out_enProc      <= '0';
              out_enCommand   <= '1';
              controllerState <= wait_s;
              -- out_leave       <= '0';
            else
              -- out_leave       <= '1';
              
              out_destMAC_o   <= destMAC_t;
              out_destIP_o    <= destIP_t;
              out_enCommand   <= '0';
              controllerState <= leave_s;
              out_destIP_o    <= destIP_t;
              out_destMAC_o   <= destMAC_t;
            end if;
            out_leave <= '0';
--          when others => null;
        end case;
      end if;
    end if;
  end process;

  resetTimer <= reset or resetOverride;

  timer_generation_general : entity work.lfsr_delay
    port map (
      dataClk => dataClk,
      reset   => resetTimer,
    
      grpRQ   => grpRQ,
      brdRQ   => brdRQ,
      done    => timerDone
      );


end rtl;
