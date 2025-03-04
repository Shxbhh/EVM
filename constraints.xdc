# Clock Signal Configuration
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

# Switch Inputs (sw[0] to sw[15])
foreach idx {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15} pin {V17 V16 W16 W17 W15 V15 W14 W13 V2 T3 T2 R3 W2 U1 T1 R2} {
    set_property PACKAGE_PIN $pin [get_ports "sw[$idx]"]
    set_property IOSTANDARD LVCMOS33 [get_ports "sw[$idx]"]
}

# LED Outputs (LED[0] to LED[15])
foreach idx {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15} pin {U16 E19 U19 V19 W18 U15 U14 V14 V13 V3 W3 U3 P3 N3 P1 L1} {
    set_property PACKAGE_PIN $pin [get_ports "LED[$idx]"]
    set_property IOSTANDARD LVCMOS33 [get_ports "LED[$idx]"]
}

# 7-Segment Display Mapping (seg[0] to seg[6])
foreach idx {0 1 2 3 4 5 6} pin {W7 W6 U8 V8 U5 V5 U7} {
    set_property PACKAGE_PIN $pin [get_ports "seg[$idx]"]
    set_property IOSTANDARD LVCMOS33 [get_ports "seg[$idx]"]
}

# 7-Segment Anode Control (an[0] to an[3])
foreach idx {0 1 2 3} pin {U2 U4 V4 W4} {
    set_property PACKAGE_PIN $pin [get_ports "an[$idx]"]
    set_property IOSTANDARD LVCMOS33 [get_ports "an[$idx]"]
}

# Button Inputs
set_property PACKAGE_PIN U18 [get_ports btn_2]						
set_property IOSTANDARD LVCMOS33 [get_ports btn_2]

set_property PACKAGE_PIN T18 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property PACKAGE_PIN W19 [get_ports btn_1]						
set_property IOSTANDARD LVCMOS33 [get_ports btn_1]

set_property PACKAGE_PIN T17 [get_ports btn_3]						
set_property IOSTANDARD LVCMOS33 [get_ports btn_3]

set_property PACKAGE_PIN U17 [get_ports btn_ov_cv]						
set_property IOSTANDARD LVCMOS33 [get_ports btn_ov_cv]
