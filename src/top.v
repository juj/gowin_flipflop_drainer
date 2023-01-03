`include "board_config.v"

module top(
  input clk,
  output led_n,
  output [3:0] hdmi_tx_n,
  output [3:0] hdmi_tx_p
);
  wire hdmi_clk, hdmi_clk_5x, hdmi_clk_lock;
  wire signed [12:0] x, y;
  reg [2:0]  hve, hve2;
  reg [23:0] rgb, rgb2;

`ifdef GW1N4
  PLLVR #(
`else
  rPLL #(
`endif
    .FCLKIN("27"), .FBDIV_SEL(58), .IDIV_SEL(2), .ODIV_SEL(2)
  )hdmi_pll(/*unused pins:*/.CLKOUTP(), .CLKOUTD(), .CLKOUTD3(), .RESET(1'b0), .RESET_P(1'b0), .CLKFB(1'b0), .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0), .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0),
`ifdef GW1N4
    .VREN(1'b1),
`endif
    .CLKIN(clk), .CLKOUT(hdmi_clk_5x), .LOCK(hdmi_clk_lock)
  );
  CLKDIV #(.DIV_MODE("5"), .GSREN("false")) hdmi_clock_div(.CLKOUT(hdmi_clk), .HCLKIN(hdmi_clk_5x), .RESETN(hdmi_clk_lock), .CALIB(1'b1));

  assign led_n = ~hdmi_clk_lock;

  display_signal ds(
    .i_pixel_clk(hdmi_clk),
    .o_hve(hve),
    .o_x(x),
    .o_y(y)
  );

  flipflop_drainer flipflop_drainer(
    .clk(hdmi_clk),
    .i_hve(hve),
    .i_color({8'(x), 8'(y), 8'(x^y)}),
    .x(x),
    .y(y),
    .o_hve(hve2),
    .o_color(rgb2)
  );

  hdmi hdmi_out(
    .reset(~hdmi_clk_lock),
    .hdmi_clk(hdmi_clk),
    .hdmi_clk_5x(hdmi_clk_5x),
    .hve(hve2),
    .rgb(rgb2),
    .hdmi_tx_n(hdmi_tx_n),
    .hdmi_tx_p(hdmi_tx_p)
  );
endmodule
