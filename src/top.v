`include "board_config.v"

module top(
  input clk,
  output led_n,
  output [3:0] hdmi_tx_n,
  output [3:0] hdmi_tx_p
);
  // Fill the FPGA with nonsense additions.
  pll #(.FBDIV_SEL(46), .IDIV_SEL(6), .ODIV_SEL(4)) adder_pll(.CLKOUT(adder_clk), .CLKIN(clk), .LOCK());
  flipflop_drainer flipflop_drainer(.clk(adder_clk), .out(led_n)); // Output the result of additions to a led so it does not get optimized out.

  // Generate a video signal: this part is completely separate from the above nonsense adders.
  pll #(
//.FBDIV_SEL(36), .IDIV_SEL(4), .ODIV_SEL(4) // 199.80 MHz:   800x600@60Hz @  39.96 MHz pixel clock: video sync flickers
//.FBDIV_SEL(36), .IDIV_SEL(3), .ODIV_SEL(4) // 249.75 MHz:   800x600@72Hz @  49.95 MHz pixel clock: video sync flickers
//.FBDIV_SEL(10), .IDIV_SEL(0), .ODIV_SEL(4) // 297.00 MHz:  1024x768@56Hz @  59.40 MHz pixel clock: rare intermittent individual pixel glitches
//.FBDIV_SEL(11), .IDIV_SEL(0), .ODIV_SEL(2) // 324.00 MHz:  1024x768@60Hz @  64.80 MHz pixel clock: individual pixel glitches
  .FBDIV_SEL(60), .IDIV_SEL(4), .ODIV_SEL(2) // 329.40 MHz:  1024x768@70Hz @  65.88 MHz pixel clock: no video sync, or glitchy video
//.FBDIV_SEL(30), .IDIV_SEL(1), .ODIV_SEL(2) // 418.50 MHz:  1280x800@60Hz @  83.70 MHz pixel clock: no video sync on two monitors
//.FBDIV_SEL(19), .IDIV_SEL(0), .ODIV_SEL(2) // 540.00 MHz: 1280x1024@60Hz @ 108.00 MHz pixel clock: no video sync on two monitors
//.FBDIV_SEL(21), .IDIV_SEL(0), .ODIV_SEL(2) // 594.00 MHz: 1600x1200@57Hz @ 118.80 MHz pixel clock: no video sync on two monitors
) hdmi_pll(.CLKIN(clk), .CLKOUT(hdmi_clk_5x), .LOCK(hdmi_clk_lock));
  CLKDIV #(.DIV_MODE("5"), .GSREN("false")) hdmi_clock_div(.CLKOUT(hdmi_clk), .HCLKIN(hdmi_clk_5x), .RESETN(hdmi_clk_lock), .CALIB(1'b1));
  reg [12:0] x, y;
  reg [2:0] hve;
  display_signal #(
/*  800x600@60Hz*/   //.H_RESOLUTION( 800),.V_RESOLUTION( 600),.H_FRONT_PORCH(40),.H_SYNC(128),.H_BACK_PORCH( 88),.V_FRONT_PORCH( 1),.V_SYNC(4),.V_BACK_PORCH(23),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(1)
/*  800x600@72Hz*/   //.H_RESOLUTION( 800),.V_RESOLUTION( 600),.H_FRONT_PORCH(56),.H_SYNC(120),.H_BACK_PORCH( 64),.V_FRONT_PORCH(37),.V_SYNC(6),.V_BACK_PORCH(23),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(1)
/* 1024x768@56Hz*/   //.H_RESOLUTION(1024),.V_RESOLUTION( 768),.H_FRONT_PORCH(48),.H_SYNC(104),.H_BACK_PORCH(152),.V_FRONT_PORCH( 3),.V_SYNC(4),.V_BACK_PORCH(21),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(1)
/* 1024x768@60Hz*/   //.H_RESOLUTION(1024),.V_RESOLUTION( 768),.H_FRONT_PORCH(24),.H_SYNC(136),.H_BACK_PORCH(160),.V_FRONT_PORCH( 3),.V_SYNC(6),.V_BACK_PORCH(29),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(0)
/* 1024x768@70Hz*/     .H_RESOLUTION(1024),.V_RESOLUTION( 768),.H_FRONT_PORCH(48),.H_SYNC( 32),.H_BACK_PORCH( 80),.V_FRONT_PORCH( 3),.V_SYNC(4),.V_BACK_PORCH(19),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(0)
/* 1280x800@60Hz*/   //.H_RESOLUTION(1280),.V_RESOLUTION( 800),.H_FRONT_PORCH(64),.H_SYNC(136),.H_BACK_PORCH(200),.V_FRONT_PORCH( 1),.V_SYNC(3),.V_BACK_PORCH(24),.H_SYNC_POLARITY(0),.V_SYNC_POLARITY(1)
/*1280x1024@60Hz*/   //.H_RESOLUTION(1280),.V_RESOLUTION(1024),.H_FRONT_PORCH(48),.H_SYNC(112),.H_BACK_PORCH(248),.V_FRONT_PORCH( 1),.V_SYNC(3),.V_BACK_PORCH(38),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(1)
/*1600x1200@57.4Hz*/ //.H_RESOLUTION(1600),.V_RESOLUTION(1200),.H_FRONT_PORCH( 8),.H_SYNC( 32),.H_BACK_PORCH( 40),.V_FRONT_PORCH(19),.V_SYNC(8),.V_BACK_PORCH( 6),.H_SYNC_POLARITY(1),.V_SYNC_POLARITY(0)
  )ds(.i_pixel_clk(hdmi_clk), .o_hve(hve), .o_x(x), .o_y(y)); // Produce video sync signal
  hdmi hdmi_out(.reset(~hdmi_clk_lock), .hdmi_clk(hdmi_clk), .hdmi_clk_5x(hdmi_clk_5x), .hve(hve), .rgb({8'(x), 8'(y), 8'(x^y)}), .hdmi_tx_n(hdmi_tx_n), .hdmi_tx_p(hdmi_tx_p));
endmodule
