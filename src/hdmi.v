// tmds_encoder performs Transition-minimized differential signaling (TMDS) encoding of
// 8-bits of pixel data and 2-bits of control data to a 10-bit TMDS encoded format.
// Requires synthesizing with System Verilog 2017.
// (this module is unit tested with cocotb framework)
module tmds_encoder(
  input i_hdmi_clk,         // HDMI pixel clock
  input i_reset,            // reset (active high)
  input [7:0] i_data,       // Input 8-bit color
  input [1:0] i_ctrl,       // control data (vsync and hsync)
  input i_display_enable,   // high=pixel data active. low=display is in blanking area
  output reg [9:0] o_tmds   // encoded 10-bit TMDS data
);
  // Intermediate pipelined variables: the number after each reg specifies the clock cycle of the pipeline the values are accessed at.

  // Reset
  reg rst0;
  // Unencoded input data
  reg [7:0] dat0, dat1, dat2, dat3, dat4, dat5, dat6, dat7 ;
  // Control signal (hsync and vsync)
  reg [1:0] ctl0, ctl1, ctl2, ctl3, ctl4, ctl5, ctl6, ctl7, ctl8, ctl9, ctl10, ctl11, ctl12, ctl13, ctl14, ctl15, ctl16, ctl17, ctl18;
  // Display enable signal
  reg den0, den1, den2, den3, den4, den5, den6, den7, den8, den9, den10, den11, den12, den13, den14, den15, den16, den17, not_den18;
  // Parity count of input data
  reg [4:0] par1, par2, par3, par4, par5, par6, par7, par8;
  // Parity bit of input data (if set, input had >= 4 bits set).
  reg par9, par10, par11, par12, par13, par14, par15, par16, par17, par18;
  // Intermediate encoded stage of the input vector.
  reg [7:0] enc3, enc4, enc5, enc6, enc7, enc8, enc9, enc10, enc11, enc12, enc13, enc14, enc15, enc16, enc17, enc18;
  // Count the number of ones in the intermediate encoded data
  reg signed [3:0] eon10, eon11, eon13, eon14, eon15, eon16, eon17, eon18;
  // Is Encoded ONes even?
  reg eve18;
  // Temp values for accumulating the count of ones in the encoded vector.
  reg [3:0] tpa10, tpa11, tpb11;
  reg [2:0] tpa12, tpb12;
  // Pipelined values for updating the bias count.
  reg signed [3:0] inv18, shr18, shl18;
  // Pipelined values for the output TMDS data.
  reg [9:0] tmds_blank18, tmds_even18, tmds_pos18, tmds_neg18;
  // 'bias' stores the running TMDS ones vs zeros balance count. If > 0, we've sent more ones to the bus,
  // if < 0, we've sent more zeroes than ones, if == 0, we are at equal balance.
  reg signed [3:0] bias;

  always @(posedge i_hdmi_clk) begin
    // Clock 0: register inputs
    rst0 <= i_reset;
    dat0 <= i_data;
    ctl0 <= i_ctrl;
    den0 <= i_display_enable;

    // Clock 1: handle reset early by folding it into the other fields
    dat1 <= dat0;
    ctl1 <= rst0 ? 2'b0 : ctl0;
    den1 <= rst0 ? 1'b0 : den0;

    // Clock 2: sanitize image data to zero if inside display blank (or reset)
    dat2 <= den1 ? dat1 : 8'b0;
    ctl2 <= ctl1;
    den2 <= den1;

    // Clocks 3-7: Pipeline 'dat' for the duration of the parity encoding below.
    dat3 <= dat2;
    dat4 <= dat3;
    dat5 <= dat4;
    dat6 <= dat5;
    dat7 <= dat6;

    // Clocks 1-8: Calculate parity, i.e. whether the input vector 'dat' has more
    //             ones in it than zeros. If it has 4 zeros and 4 ones, use ~dat[0]
    //             as a tie. To do that, start with constant vector 00001, and for
    //             each bit set in input 'dat', shift 'par' left by one place, filling
    //             in ones. At the end par[4] will specifies whether there were more
    //             ones than zeroes.
    par1 <= 5'b00001;
    par2 <= dat1[1] ? {par1[3:0], 1'b1} : par1; // = 000ab (a,b=unknown, 000=zeroes)
    par3 <= dat2[2] ? {par2[3:0], 1'b1} : par2; // = 00abc
    par4 <= dat3[3] ? {par3[3:0], 1'b1} : par3; // = 0abcd
    par5 <= dat4[4] ? {par4[3:0], 1'b1} : par4; // = abcdx (x=don't care, rely on optimizer to clear these away)
    par6 <= dat5[5] ? {par5[3:0], 1'b1} : par5; // = bcdxx
    par7 <= dat6[6] ? {par6[3:0], 1'b1} : par6; // = cdxxx
    par8 <= dat7[7] ? {par7[3:0], 1'b1} : par7; // = dxxxx

    // Clocks 9-18: No further calculation needed for parity. Keep pipelining it forward
    //              in a single bit vector.
    par9 <= par8[4]; // At the end of computation par[4] records the parity.
    par10 <= par9;
    par11 <= par10;
    par12 <= par11;
    par13 <= par12;
    par14 <= par13;
    par15 <= par14;
    par16 <= par15;
    par17 <= par16;
    par18 <= par17;

    // Clocks 3-18: No more changes needed to the Display Enable signal, flow it through the pipeline
    den3 <= den2;
    den4 <= den3;
    den5 <= den4;
    den6 <= den5;
    den7 <= den6;
    den8 <= den7;
    den9 <= den8;
    den10 <= den9;
    den11 <= den10;
    den12 <= den11;
    den13 <= den12;
    den14 <= den13;
    den15 <= den14;
    den16 <= den15;
    den17 <= den16;
    not_den18 <= ~den17;

    // Clocks 3-18: Pipeline ctrl data (hsync & vsync), no changes needed.
    ctl3 <= ctl2;
    ctl4 <= ctl3;
    ctl5 <= ctl4;
    ctl6 <= ctl5;
    ctl7 <= ctl6;
    ctl8 <= ctl7;
    ctl9 <= ctl8;
    ctl10 <= ctl9;
    ctl11 <= ctl10;
    ctl12 <= ctl11;
    ctl13 <= ctl12;
    ctl14 <= ctl13;
    ctl15 <= ctl14;
    ctl16 <= ctl15;
    ctl17 <= ctl16;
    ctl18 <= ctl17;

    // Clocks 3-9: perform intermediate encoded vector 'enc' of the input 'data' field. At the
    //             end of the encoding, the DVI spec says the encoded vector should look like
    //             follows:
    // enc <= { parity ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7],
    //                   data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6],
    //          parity ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5],
    //                   data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4],
    //          parity ^ data[0] ^ data[1] ^ data[2] ^ data[3],
    //                   data[0] ^ data[1] ^ data[2],
    //          parity ^ data[0] ^ data[1],
    //                   data[0] };
    //
    // Calculate it across a few clock cycles to avoid high complexity per clock. (ignore parity first)
    // Bit lanes after each clock cycle:
    //                [7]     [6]    [5]   [4]  [3] [2] [1] [0]
    // Clock 2:        7       6      5     4    3   2   1   0
    // Clock 3:       76      65     54    43   32  21  10   0
    // Clock 4:     7654    6543   5432  4321 3210 210  10   0
    // Clock 5: 76543210 6543210 543210 43210 3210 210  10   0

    enc3 <= {dat2[7:1]^dat2[6:0], dat2[  0]};
    enc4 <= {enc3[7:2]^enc3[5:0], enc3[1:0]};
    enc5 <= {enc4[7:4]^enc4[3:0], enc4[3:0]};
    enc6 <= enc5;
    enc7 <= enc6;
    enc8 <= enc7;

    // Clock 9: Meanwhile, parity computation has completed, so apply the final parity XOR to the
    //          intermediate encoded vector.
    enc9 <= enc8 ^ {4{par8[4], 1'b0}};
    enc10 <= enc9;
    enc11 <= enc10;
    enc12 <= enc11;
    enc13 <= enc12;
    enc14 <= enc13;
    enc15 <= enc14;
    enc16 <= enc15;
    enc17 <= enc16;
    enc18 <= enc17;

    // Clocks 10-17: calculate 'eon' (Encoded ONes vs zeros): a signed count that specifies whether
    //               vector 'enc' has more ones or zeroes in it.
    tpa10 <= enc9[3:0] ^ enc9[7:4]; // Fold the 8 bit enc vector into two 4-bit halves, and half-
    tpa11 <= tpa10;     // Then calculate the number of ones in them in parallel
    tpb11 <= enc10[3:0] & enc10[7:4];//tpb10;
    tpa12 <= $countones(tpa11);     // Then calculate the number of ones in them in parallel
    tpb12 <= $countones(tpb11);
    eon13 <= tpa12 + {tpb12, 1'b0}; // Then use a 3-bit + 4-bit addition to bring the full count.
    eon14 <= eon13 - 3'd4;          // And make the result signed.
    eon15 <= eon14;
    eon16 <= eon15;
    eon17 <= eon16;
    eon18 <= eon17;

    // 'eon17' is a count of balance of ones vs zeros in input encoded vector 'enc':
    //        #ones: 8 7 6 5 4  3  2  1  0
    // #ones-#zeros: 8 6 4 2 0 -2 -4 -6 -8
    // value of eon: 4 3 2 1 0 -1 -2 -3 -4

    // Pipeline a few finishing touches:
    eve18 <= eon17 == 0;                      // is the balance equal (zero)?
    inv18 <= par17 ? -eon17     : eon17;      // invert balance count based on parity.
    shr18 <= par17 ? eon17      : eon17-1'b1; // right shift balance count based on parity.
    shl18 <= par17 ? eon17-1'b1 : eon17;      // left shift balance count based on parity.
    tmds_blank18 <= {~ctl17[1], 9'b101010100} ^ {10{ctl17[0]}};
    tmds_even18 <= {par17, ~par17, {8{par17}} ^ enc17};
    tmds_pos18 <= {1'b1, ~par17, 8'hff ^ enc17};
    tmds_neg18 <= {1'b0, ~par17,         enc17};

    // Clocks 14-17 above:
    // These are "empty" filler clock stages that contain no computations on any of the variables,
    // but they only perform direct passthrough of the values that have been computed so far.
    // Gowin IDE Analyzer reports that this improves max. timing performance.

    // Clock 18: finally output the TMDS encoded value, and update bias value
    if (not_den18) begin // In display blank?
      o_tmds <= tmds_blank18;              // Output control words for hsync and vsync
      bias <= 0;                           // Bias resets to zero in blank
    end else if (eve18 || bias == 0) begin // If current bias is even, or encoded balance is even..
      o_tmds <= tmds_even18;               // .. use a specific 'even' state TMDS formula.
      bias <= bias + inv18;                // This does not seem to be strictly necessary, you can try removing this else block for tiny bit more performance.
    end else if (bias[3] == eon18[3]) begin // Otherwise, noneven bias and balance, so use the main TMDS encoding formula
      o_tmds <= tmds_pos18;
      bias <= bias - shr18; // and update running bias of ones vs zeros sent.
    end else begin
      o_tmds <= tmds_neg18;
      bias <= bias + shl18;
    end
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
  wire serial_tmds[4];
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c0(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[0]), .D0(tmds_ch0[0]), .D1(tmds_ch0[1]), .D2(tmds_ch0[2]), .D3(tmds_ch0[3]), .D4(tmds_ch0[4]), .D5(tmds_ch0[5]), .D6(tmds_ch0[6]), .D7(tmds_ch0[7]), .D8(tmds_ch0[8]), .D9(tmds_ch0[9]));
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c1(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[1]), .D0(tmds_ch1[0]), .D1(tmds_ch1[1]), .D2(tmds_ch1[2]), .D3(tmds_ch1[3]), .D4(tmds_ch1[4]), .D5(tmds_ch1[5]), .D6(tmds_ch1[6]), .D7(tmds_ch1[7]), .D8(tmds_ch1[8]), .D9(tmds_ch1[9]));
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c2(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[2]), .D0(tmds_ch2[0]), .D1(tmds_ch2[1]), .D2(tmds_ch2[2]), .D3(tmds_ch2[3]), .D4(tmds_ch2[4]), .D5(tmds_ch2[5]), .D6(tmds_ch2[6]), .D7(tmds_ch2[7]), .D8(tmds_ch2[8]), .D9(tmds_ch2[9]));
  OSER10 #(.GSREN("false"), .LSREN("true")) ser_c3(.PCLK(hdmi_clk), .FCLK(hdmi_clk_5x), .RESET(reset), .Q(serial_tmds[3]), .D0(       1'b1), .D1(       1'b1), .D2(       1'b1), .D3(       1'b1), .D4(       1'b1), .D5(       1'b0), .D6(       1'b0), .D7(       1'b0), .D8(       1'b0), .D9(       1'b0));

  // Encode the 1-bit serial TMDS streams to Low-voltage differential signaling (LVDS) HDMI output pins. (Gowin FPGA Designer/Sipeed Tang Nano 4K specific module)
`ifdef GW1N4
  TLVDS_OBUF OBUFDS_clock(.I(serial_tmds[3]), .O(hdmi_tx_p[3]), .OB(hdmi_tx_n[3]));
  TLVDS_OBUF OBUFDS_red  (.I(serial_tmds[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  TLVDS_OBUF OBUFDS_green(.I(serial_tmds[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  TLVDS_OBUF OBUFDS_blue (.I(serial_tmds[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
`else
  ELVDS_OBUF OBUFDS_clock(.I(serial_tmds[3]), .O(hdmi_tx_p[3]), .OB(hdmi_tx_n[3]));
  ELVDS_OBUF OBUFDS_red  (.I(serial_tmds[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  ELVDS_OBUF OBUFDS_green(.I(serial_tmds[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  ELVDS_OBUF OBUFDS_blue (.I(serial_tmds[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
`endif
endmodule
