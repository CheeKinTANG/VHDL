####################################
# Do file for igmp processing      #
####################################

#name the library
vlib work

#compile the processors
vcom -93 -explicit -work work ../util/function_pkg.vhd
vcom -93 -explicit -work work ../util/simple_galois_lfsr.vhd
vcom -93 -explicit -work work ../util/lfsr_gen.vhd
vcom -93 -explicit -work work ../util/lfsr_delay.vhd

vcom -93 -explicit -work work checksum.vhd
vcom -93 -explicit -work work igmp_assembler.vhd
vcom -93 -explicit -work work igmp_processor.vhd
vcom -93 -explicit -work work igmp_controller.vhd

vcom -93 -explicit -work work igmp_wrapper.vhd
vcom -93 -explicit -work work igmp_wrapper_tb.vhd

#load the file for simulation
vsim igmp_wrapper_tb

#open selected windows for viewing
view structure
view signals
view wave

## signals from Ethernet Testbench 

  -- component ports
add wave -noupdate dataClk    
add wave -noupdate reset      
add wave -noupdate join
add wave -noupdate leave

add wave -h -noupdate srcMAC
add wave -h -noupdate srcIP
add wave -h -noupdate destMAC
add wave -h -noupdate destIP
add wave -noupdate vlanEn
add wave -h -noupdate vlanId

add wave -noupdate tx_ready_n
add wave -h -noupdate tx_data
add wave -noupdate tx_vld
add wave -noupdate tx_sof
add wave -noupdate tx_eof

add wave -noupdate out_enProc
add wave -noupdate out_enCommand

add wave -noupdate igmp_wrapper_1/igmp_assembler_module/assembly_state
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/currentState
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/byteCount

add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/checksum_state

add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/igmp_l
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/igmp_j

add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/ipv4_j
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/ipv4_l
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/ipv4_r1
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/ipv4_r2

add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/source_ip_r
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/chksum_sub_state

add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/ipv4_layer_checksum_j
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/ipv4_layer_checksum_l
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/igmp_layer_checksum_j
add wave -noupdate igmp_wrapper_1/igmp_assembler_module/create_checksum/igmp_layer_checksum_l


#run simulation for 100 ns
run 2 ms 
