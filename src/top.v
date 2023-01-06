`include "board_config.v"

module top(
  input clk,
  output led_n,
  output [3:0] hdmi_tx_n,
  output [3:0] hdmi_tx_p
);
  // Create a clock signal for a "nonsense" adder chain.
  wire adder_clk[9];
  assign adder_clk[0] = clk;
  pll #(.FBDIV_SEL(0), .IDIV_SEL(4), .ODIV_SEL(112)) adder_pll(.CLKOUT(adder_clk[1]), .CLKIN(adder_clk[0]), .LOCK()); // Generate a 27*1/5 = 5.4 MHz clock signal
  // Divide the 5.4 MHz clock signal by 8 multiple times to get a much smaller clock frequency.
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div1(.CLKOUT(adder_clk[2]), .HCLKIN(adder_clk[1]), .RESETN(1'b1), .CALIB(1'b1)); // 675000 Hz, no video signal on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div2(.CLKOUT(adder_clk[3]), .HCLKIN(adder_clk[2]), .RESETN(1'b1), .CALIB(1'b1)); // 84375 Hz, no video signal on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div3(.CLKOUT(adder_clk[4]), .HCLKIN(adder_clk[3]), .RESETN(1'b1), .CALIB(1'b1)); // 10546.875 Hz, no video signal on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div4(.CLKOUT(adder_clk[5]), .HCLKIN(adder_clk[4]), .RESETN(1'b1), .CALIB(1'b1)); // 1318.359375 Hz, video signal barely appears on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div5(.CLKOUT(adder_clk[6]), .HCLKIN(adder_clk[5]), .RESETN(1'b1), .CALIB(1'b1)); // 164.794921875 Hz, unstable video on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div6(.CLKOUT(adder_clk[7]), .HCLKIN(adder_clk[6]), .RESETN(1'b1), .CALIB(1'b1)); // 20.599365234375 Hz, only few glitches on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div7(.CLKOUT(adder_clk[8]), .HCLKIN(adder_clk[7]), .RESETN(1'b1), .CALIB(1'b1)); // 2.574920654296875 Hz, almost stable video on Nano 9K

  // Calculate nonsense additions at low clock frequency.
  // You can change the clock signal here to adder_clk[8] to get more stable video signal, and adder_clk[0] to get more unstable video signal.
  flipflop_drainer flipflop_drainer(.clk(adder_clk[0]), .out(led_n)); // Output the result of additions to a led so it does not get optimized out.

  // Generate a video signal: this part is completely separate from the above nonsense adders.
  pll #(
//.FBDIV_SEL(13), .IDIV_SEL(2), .ODIV_SEL(4) // 126.00 MHz:   640x480@60Hz @  25.20 MHz pixel clock: does not lose video sync, but produces (infrequent) single pixel flickering color glitches
//.FBDIV_SEL(36), .IDIV_SEL(4), .ODIV_SEL(4) // 199.80 MHz:   800x600@60Hz @  39.96 MHz pixel clock: does not lose video sync, but produces (moderate) single pixel flickering color glitches
//.FBDIV_SEL(7),  .IDIV_SEL(0), .ODIV_SEL(2) // 216.00 MHz:   768x576@73Hz @  43.20 MHz pixel clock: does not lose video sync, no(!) observed single pixel flickering
//.FBDIV_SEL(58), .IDIV_SEL(6), .ODIV_SEL(2) // 227.57 MHz:   768x576@75Hz @  45.51 MHz pixel clock: no video sync
//.FBDIV_SEL(36), .IDIV_SEL(3), .ODIV_SEL(2) // 249.75 MHz:   800x600@72Hz @  49.95 MHz pixel clock: no video sync
  .FBDIV_SEL(11), .IDIV_SEL(0), .ODIV_SEL(2) // 324.00 MHz:  1024x768@60Hz @  64.80 MHz pixel clock: no video sync
//.FBDIV_SEL(30), .IDIV_SEL(1), .ODIV_SEL(2) // 418.50 MHz:  1280x800@60Hz @  83.70 MHz pixel clock: no video sync
//.FBDIV_SEL(19), .IDIV_SEL(0), .ODIV_SEL(2) // 540.00 MHz: 1280x1024@60Hz @ 108.00 MHz pixel clock: no video sync
//.FBDIV_SEL(21), .IDIV_SEL(0), .ODIV_SEL(2) // 594.00 MHz: 1600x1200@57Hz @ 118.80 MHz pixel clock: no video sync, not even if using adder_clk[8] above, but must edit src/flipflop_drainer.v
) hdmi_pll(.CLKIN(clk), .CLKOUT(hdmi_clk_5x), .LOCK(hdmi_clk_lock));
  // Divide 5:1 serdes clock by five for HDMI pixel clock signal.
  CLKDIV #(.DIV_MODE("5"), .GSREN("false")) hdmi_clock_div(.CLKOUT(hdmi_clk), .HCLKIN(hdmi_clk_5x), .RESETN(hdmi_clk_lock), .CALIB(1'b1));
  reg [12:0] x, y;
  reg [2:0] hve;
  display_signal #(
/*  640x480@60Hz*/   //.H_RESOLUTION( 640),.V_RESOLUTION( 480),.H_FRONT_PORCH(16),.H_SYNC( 96),.H_BACK_PORCH( 48),.V_FRONT_PORCH(10),.V_SYNC(2),.V_BACK_PORCH(33),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(0)
/*  800x600@60Hz*/   //.H_RESOLUTION( 800),.V_RESOLUTION( 600),.H_FRONT_PORCH(40),.H_SYNC(128),.H_BACK_PORCH( 88),.V_FRONT_PORCH( 1),.V_SYNC(4),.V_BACK_PORCH(23),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(1)
/*  768x576@73Hz*/   //.H_RESOLUTION( 768),.V_RESOLUTION( 576),.H_FRONT_PORCH(32),.H_SYNC( 80),.H_BACK_PORCH(112),.V_FRONT_PORCH( 1),.V_SYNC(3),.V_BACK_PORCH(21),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(1)
/*  768x576@75Hz*/   //.H_RESOLUTION( 768),.V_RESOLUTION( 576),.H_FRONT_PORCH(40),.H_SYNC( 80),.H_BACK_PORCH(120),.V_FRONT_PORCH( 1),.V_SYNC(3),.V_BACK_PORCH(22),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(1)
/*  800x600@72Hz*/   //.H_RESOLUTION( 800),.V_RESOLUTION( 600),.H_FRONT_PORCH(56),.H_SYNC(120),.H_BACK_PORCH( 64),.V_FRONT_PORCH(37),.V_SYNC(6),.V_BACK_PORCH(23),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(1)
/* 1024x768@60Hz*/     .H_RESOLUTION(1024),.V_RESOLUTION( 768),.H_FRONT_PORCH(24),.H_SYNC(136),.H_BACK_PORCH(160),.V_FRONT_PORCH( 3),.V_SYNC(6),.V_BACK_PORCH(29),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(0)
/* 1280x800@60Hz*/   //.H_RESOLUTION(1280),.V_RESOLUTION( 800),.H_FRONT_PORCH(64),.H_SYNC(136),.H_BACK_PORCH(200),.V_FRONT_PORCH( 1),.V_SYNC(3),.V_BACK_PORCH(24),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(1)
/*1280x1024@60Hz*/   //.H_RESOLUTION(1280),.V_RESOLUTION(1024),.H_FRONT_PORCH(48),.H_SYNC(112),.H_BACK_PORCH(248),.V_FRONT_PORCH( 1),.V_SYNC(3),.V_BACK_PORCH(38),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(1)
/*1600x1200@57.4Hz*/ //.H_RESOLUTION(1600),.V_RESOLUTION(1200),.H_FRONT_PORCH( 8),.H_SYNC( 32),.H_BACK_PORCH( 40),.V_FRONT_PORCH(19),.V_SYNC(8),.V_BACK_PORCH( 6),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(0)
  )ds(.i_pixel_clk(hdmi_clk), .o_hve(hve), .o_x(x), .o_y(y)); // Produce video sync signal
  hdmi hdmi_out(.reset(~hdmi_clk_lock), .hdmi_clk(hdmi_clk), .hdmi_clk_5x(hdmi_clk_5x), .hve(hve), .rgb({8'(x), 8'(y), 8'(x^y)}), .hdmi_tx_n(hdmi_tx_n), .hdmi_tx_p(hdmi_tx_p));
endmodule
