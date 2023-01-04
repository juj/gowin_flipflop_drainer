`include "board_config.v"

module pll #(FBDIV_SEL = 0, IDIV_SEL = 0, ODIV_SEL = 0)
(
  input  CLKIN,
  output CLKOUT,
  output LOCK
);
`ifdef GW1N4
  PLLVR #(
`else
  rPLL #(
`endif
    .FCLKIN("27"), .FBDIV_SEL(FBDIV_SEL), .IDIV_SEL(IDIV_SEL), .ODIV_SEL(ODIV_SEL)
  )pll(/*unused pins:*/.CLKOUTP(), .CLKOUTD(), .CLKOUTD3(), .RESET(1'b0), .RESET_P(1'b0), .CLKFB(1'b0), .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0), .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0),
`ifdef GW1N4
    .VREN(1'b1),
`endif
    .CLKIN(CLKIN), .CLKOUT(CLKOUT), .LOCK(LOCK)
  );
endmodule
