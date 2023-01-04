`include "board_config.v"

module top(
  input clk,
  output led_n,
  output [3:0] hdmi_tx_n,
  output [3:0] hdmi_tx_p
);
  // Create a clock signal for a "nonsense" adder chain.
  wire adder_clk[8];
  pll #(.FBDIV_SEL(0), .IDIV_SEL(4), .ODIV_SEL(112)) adder_pll(.CLKIN(clk), .CLKOUT(adder_clk[0]), .LOCK()); // Generate a 27*1/5 = 5.4 MHz clock signal
  // Divide the 5.4 MHz clock signal by 8 multiple times to get a much smaller clock frequency.
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div1(.CLKOUT(adder_clk[1]), .HCLKIN(adder_clk[0]), .RESETN(1'b1), .CALIB(1'b1)); // 675000 Hz, no video signal on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div2(.CLKOUT(adder_clk[2]), .HCLKIN(adder_clk[1]), .RESETN(1'b1), .CALIB(1'b1)); // 84375 Hz, no video signal on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div3(.CLKOUT(adder_clk[3]), .HCLKIN(adder_clk[2]), .RESETN(1'b1), .CALIB(1'b1)); // 10546.875 Hz, no video signal on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div4(.CLKOUT(adder_clk[4]), .HCLKIN(adder_clk[3]), .RESETN(1'b1), .CALIB(1'b1)); // 1318.359375 Hz, video signal barely appears on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div5(.CLKOUT(adder_clk[5]), .HCLKIN(adder_clk[4]), .RESETN(1'b1), .CALIB(1'b1)); // 164.794921875 Hz, unstable video on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div6(.CLKOUT(adder_clk[6]), .HCLKIN(adder_clk[5]), .RESETN(1'b1), .CALIB(1'b1)); // 20.599365234375 Hz, only few glitches on Nano 9K
  CLKDIV #(.DIV_MODE("8"), .GSREN("false")) adder_clock_div7(.CLKOUT(adder_clk[7]), .HCLKIN(adder_clk[6]), .RESETN(1'b1), .CALIB(1'b1)); // 2.574920654296875 Hz, almost stable video on Nano 9K

  // Calculate nonsense additions at low clock frequency.
  // You can change the clock signal here to adder_clk[7] to get more stable video signal, and adder_clk[0] to get more unstable video signal.
  flipflop_drainer flipflop_drainer(.clk(adder_clk[0]), .out(led_n)); // Output the result of additions to a led so it does not get optimized out.

  // Generate a video signal: this part is completely separate from the above nonsense adders.
  pll #(.FBDIV_SEL(58), .IDIV_SEL(2), .ODIV_SEL(2)) hdmi_pll(.CLKIN(clk), .CLKOUT(hdmi_clk_5x), .LOCK(hdmi_clk_lock)); // Generate a 27*59/3 = 531 MHz 5:1 HDMI clock signal
  // Divide 531 MHz / 5 = 106.2 MHz for HDMI pixel clock signal.
  CLKDIV #(.DIV_MODE("5"), .GSREN("false")) hdmi_clock_div(.CLKOUT(hdmi_clk), .HCLKIN(hdmi_clk_5x), .RESETN(hdmi_clk_lock), .CALIB(1'b1));
  reg [12:0] x, y;
  reg [2:0] hve;
  display_signal ds(.i_pixel_clk(hdmi_clk), .o_hve(hve), .o_x(x), .o_y(y)); // Produce video sync signal
  hdmi hdmi_out(.reset(~hdmi_clk_lock), .hdmi_clk(hdmi_clk), .hdmi_clk_5x(hdmi_clk_5x), .hve(hve), .rgb({8'(x), 8'(y), 8'(x^y)}), .hdmi_tx_n(hdmi_tx_n), .hdmi_tx_p(hdmi_tx_p));
endmodule
