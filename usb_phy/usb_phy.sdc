###################################################################

# Created by write_sdc on Wed Feb 10 14:58:29 2016

###################################################################
set sdc_version 2.0

set_units -time ps -resistance kOhm -capacitance fF -voltage V -current mA
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_0_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_1_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_2_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_3_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_4_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_5_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_6_]
set_driving_cell -lib_cell in01f80 [get_ports DataOut_i_7_]
set_driving_cell -lib_cell in01f80 [get_ports TxValid_i]
set_driving_cell -lib_cell in01f80 [get_ports phy_tx_mode]
set_driving_cell -lib_cell in01f80 [get_ports rst]
set_driving_cell -lib_cell in01f80 [get_ports rxd]
set_driving_cell -lib_cell in01f80 [get_ports rxdn]
set_driving_cell -lib_cell in01f80 [get_ports rxdp]
set_load -pin_load 4 [get_ports DataIn_o_0_]
set_load -pin_load 4 [get_ports DataIn_o_1_]
set_load -pin_load 4 [get_ports DataIn_o_2_]
set_load -pin_load 4 [get_ports DataIn_o_3_]
set_load -pin_load 4 [get_ports DataIn_o_4_]
set_load -pin_load 4 [get_ports DataIn_o_5_]
set_load -pin_load 4 [get_ports DataIn_o_6_]
set_load -pin_load 4 [get_ports DataIn_o_7_]
set_load -pin_load 4 [get_ports LineState_o_0_]
set_load -pin_load 4 [get_ports LineState_o_1_]
set_load -pin_load 4 [get_ports RxActive_o]
set_load -pin_load 4 [get_ports RxError_o]
set_load -pin_load 4 [get_ports RxValid_o]
set_load -pin_load 4 [get_ports TxReady_o]
set_load -pin_load 4 [get_ports g1897_u0_o]
set_load -pin_load 4 [get_ports txdn]
set_load -pin_load 4 [get_ports txdp]
set_load -pin_load 4 [get_ports txoe]
set_load -pin_load 4 [get_ports usb_rst]
create_clock [get_ports clk]  -period 300  -waveform {0 150}
