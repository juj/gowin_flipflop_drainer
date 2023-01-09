// tmds_encoder performs Transition-minimized differential signaling (TMDS) encoding of
// 8-bits of pixel data and 2-bits of control data to a 10-bit TMDS encoded format.
// Requires synthesizing with System Verilog 2017.
module tmds_encoder(
  input i_hdmi_clk,         // HDMI pixel clock
  input i_reset,            // reset (active high)
  input [7:0] i_data,       // Input 8-bit color
  input [1:0] i_ctrl,       // control data (vsync and hsync)
  input i_display_enable,   // high=pixel data active. low=display is in blanking area
  output reg [9:0] o_tmds   // encoded 10-bit TMDS data
);
 // wire [1:0] ctrl = {2{~i_reset}} & i_ctrl; // clear control data if in reset state
    reg [1:0] ctrl_1, ctrl_2, ctrl_3, ctrl_4, ctrl_5, ctrl_6, ctrl_7, ctrl_8, ctrl_9, ctrl_10, ctrl_11;
  reg blank[10:0]; // 11 clock cycles pipelined version of "i_reset | ~i_display_enable;". If high, send blank data (in reset or in image blank)

//  wire parity = {$countones(i_data), !i_data[0]} > 8;                 // calculate a xor value based on if ones dominate the input, break ties on lowest bit.
  reg parity_1, parity_2, parity_3, parity_4, parity_5, parity_6, parity_7, parity_8, parity_9, parity_10, parity_11;
//  wire [7:0] enc = {{7{parity}} ^ enc[6:0] ^ i_data[7:1], i_data[0]}; // intermediate encode step
  reg [7:0] enc_1, enc_2, enc_3, enc_4, enc_5, enc_6, enc_7, enc_8, enc_9, enc_10, enc_11;

//  wire signed [4:0] balance = {4'($countones(enc)),1'b0} - 5'b01000; // calculate # of ones vs # of zeros bit balance
//  reg signed [4:0] balance, balance_p;
  reg signed [4:0] bias;                                             // keep a record of bit bias of previously sent data
//  wire bias_vs_balance = (bias[4] == balance[4]);                    // track from sign bits if balance is going away or towards bias
  reg bias_vs_balance;
  reg [7:0] data_1, data_2;

  reg signed [4:0] balance_5, balance_6, balance_7, balance_8, balance_9, balance_10, balance_11;

  // encode pixel color data with at most 5 bit 0<->1 transitions, and update bias count.
  always @(posedge i_hdmi_clk) begin
    // clock 0 -> clock 1
    ctrl_1 <= {2{~i_reset}} & i_ctrl;
    blank <= { blank[9:0], i_reset | ~i_display_enable };
    parity_1 <= {4'($countones(i_data)), !i_data[0]} > 8;
    data_1 <= i_data;

    ctrl_2 <= ctrl_1;
    parity_2 <= parity_1;
    data_2 <= data_1;
    // clock 1 -> clock 2
    parity_3 <= parity_2;
    ctrl_3 <= ctrl_2;
    enc_3 <= { parity_2 ^ data_2[0] ^ data_2[1] ^ data_2[2] ^ data_2[3] ^ data_2[4] ^ data_2[5] ^ data_2[6] ^ data_2[7],
                          data_2[0] ^ data_2[1] ^ data_2[2] ^ data_2[3] ^ data_2[4] ^ data_2[5] ^ data_2[6],
               parity_2 ^ data_2[0] ^ data_2[1] ^ data_2[2] ^ data_2[3] ^ data_2[4] ^ data_2[5],
                          data_2[0] ^ data_2[1] ^ data_2[2] ^ data_2[3] ^ data_2[4],
               parity_2 ^ data_2[0] ^ data_2[1] ^ data_2[2] ^ data_2[3],
                          data_2[0] ^ data_2[1] ^ data_2[2],
               parity_2 ^ data_2[0] ^ data_2[1],
                          data_2[0] };
    // clock 2 -> clock 3
    enc_4    <= enc_3;
    ctrl_4 <= ctrl_3;
    parity_4 <= parity_3;

    balance_5 <= $countones(enc_4);
    enc_5    <= enc_4;
    ctrl_5 <= ctrl_4;
    parity_5 <= parity_4;

    balance_6 <= balance_5;
    enc_6    <= enc_5;
    ctrl_6 <= ctrl_5;
    parity_6 <= parity_5;

    balance_7 <= balance_6;
    enc_7    <= enc_6;
    ctrl_7 <= ctrl_6;
    parity_7 <= parity_6;

    balance_8 <= {4'(balance_7),1'b0};
    enc_8    <= enc_7;
    ctrl_8 <= ctrl_7;
    parity_8 <= parity_7;

    // clock 3 -> clock 4
    balance_9 <= balance_8 - 5'b01000;
    enc_9    <= enc_8;
    ctrl_9 <= ctrl_8;
    parity_9 <= parity_8;

    balance_10 <= balance_9;
    enc_10    <= enc_9;
    ctrl_10 <= ctrl_9;
    parity_10 <= parity_9;

    // clock 4 -> clock 5
    bias_vs_balance <= (bias[4] == balance_10[4]);
    balance_11 <= balance_10;
    enc_11    <= enc_10;
    ctrl_11 <= ctrl_10;
    parity_11 <= parity_10;

    // clock 5 -> clock 6
    o_tmds <= blank[10] ? {~ctrl_11[1], 9'b101010100} ^ {10{ctrl_11[0]}} : {bias_vs_balance, ~parity_11, {8{bias_vs_balance}} ^ enc_11};
    bias <= blank[10] ? 0 : 5'(bias + ({5{bias_vs_balance}} ^ balance_11) + {3'b0, bias_vs_balance^parity_11, bias_vs_balance});
  end
endmodule

// hdmi module implements HDMI output using the DVI-backwards compatible bitstream.
module hdmi(
  input hdmi_clk,
  input hdmi_clk_5x,
  input [2:0] hve, // Image sync signals: { display_enable, vsync, hsync }
  input [23:0] rgb,
  input reset,
  output [3:0] hdmi_tx_n,
  output [3:0] hdmi_tx_p
);
  // Register input video signal to improve MHz performance
  reg [2:0] hve_p;
  reg [23:0] rgb_p;
  always @(posedge hdmi_clk) begin
    hve_p <= hve;
    rgb_p <= rgb;
  end

  // Encode vsync, hsync, blanking and rgb data to Transition-minimized differential signaling (TMDS) format.
  wire [9:0] tmds_ch0, tmds_ch1, tmds_ch2;
  tmds_encoder encode_b(.i_hdmi_clk(hdmi_clk), .i_reset(reset), .i_data(rgb_p[7:0]),   .i_ctrl(hve_p[1:0]),      .i_display_enable(hve_p[2]), .o_tmds(tmds_ch0));
  tmds_encoder encode_g(.i_hdmi_clk(hdmi_clk), .i_reset(reset), .i_data(rgb_p[15:8]),  .i_ctrl(2'b00),           .i_display_enable(hve_p[2]), .o_tmds(tmds_ch1));
  tmds_encoder encode_r(.i_hdmi_clk(hdmi_clk), .i_reset(reset), .i_data(rgb_p[23:16]), .i_ctrl(2'b00),           .i_display_enable(hve_p[2]), .o_tmds(tmds_ch2));

  // Serialize the three 10-bit TMDS channels to three serial 1-bit TMDS streams. (Gowin FPGA Designer/Sipeed Tang Nano 4K specific module)
  wire serial_tmds[3];
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c0(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[0]), .D0(tmds_ch0[0]), .D1(tmds_ch0[1]), .D2(tmds_ch0[2]), .D3(tmds_ch0[3]), .D4(tmds_ch0[4]), .D5(tmds_ch0[5]), .D6(tmds_ch0[6]), .D7(tmds_ch0[7]), .D8(tmds_ch0[8]), .D9(tmds_ch0[9]));
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c1(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[1]), .D0(tmds_ch1[0]), .D1(tmds_ch1[1]), .D2(tmds_ch1[2]), .D3(tmds_ch1[3]), .D4(tmds_ch1[4]), .D5(tmds_ch1[5]), .D6(tmds_ch1[6]), .D7(tmds_ch1[7]), .D8(tmds_ch1[8]), .D9(tmds_ch1[9]));
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c2(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[2]), .D0(tmds_ch2[0]), .D1(tmds_ch2[1]), .D2(tmds_ch2[2]), .D3(tmds_ch2[3]), .D4(tmds_ch2[4]), .D5(tmds_ch2[5]), .D6(tmds_ch2[6]), .D7(tmds_ch2[7]), .D8(tmds_ch2[8]), .D9(tmds_ch2[9]));

  // Encode the 1-bit serial TMDS streams to Low-voltage differential signaling (LVDS) HDMI output pins. (Gowin FPGA Designer/Sipeed Tang Nano 4K specific module)
`ifdef GW1N4
  TLVDS_OBUF OBUFDS_clock(.I(hdmi_clk),       .O(hdmi_tx_p[3]), .OB(hdmi_tx_n[3]));
  TLVDS_OBUF OBUFDS_red  (.I(serial_tmds[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  TLVDS_OBUF OBUFDS_green(.I(serial_tmds[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  TLVDS_OBUF OBUFDS_blue (.I(serial_tmds[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
`else
  ELVDS_OBUF OBUFDS_clock(.I(hdmi_clk),       .O(hdmi_tx_p[3]), .OB(hdmi_tx_n[3]));
  ELVDS_OBUF OBUFDS_red  (.I(serial_tmds[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  ELVDS_OBUF OBUFDS_green(.I(serial_tmds[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  ELVDS_OBUF OBUFDS_blue (.I(serial_tmds[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
`endif
endmodule
