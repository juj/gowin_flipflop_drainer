//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.09 Education
//Created Time: 2023-04-22 18:37:24
create_clock -name clk -period 37 -waveform {0 18} [get_ports {clk}] -add
create_generated_clock -name hdmi_clk_5x -source [get_ports {clk}] -master_clock clk -multiply_by 12 [get_regs {hdmi_out/encode_r/o_tmds_0_s0 hdmi_out/encode_r/o_tmds_1_s0 hdmi_out/encode_r/o_tmds_2_s0 hdmi_out/encode_r/o_tmds_3_s0 hdmi_out/encode_r/o_tmds_4_s0 hdmi_out/encode_r/o_tmds_5_s0 hdmi_out/encode_r/o_tmds_6_s0 hdmi_out/encode_r/o_tmds_7_s0 hdmi_out/encode_r/o_tmds_8_s0 hdmi_out/encode_r/o_tmds_9_s0}]
