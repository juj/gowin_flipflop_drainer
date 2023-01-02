// display_signal module converts a pixel clock into a hsync+vsync+disp_enable+x+y structure.
module display_signal #(
  H_RESOLUTION    = 1280,
  V_RESOLUTION    = 1024,
  H_FRONT_PORCH   = 48,
  H_SYNC          = 112,
  H_BACK_PORCH    = 248,
  V_FRONT_PORCH   = 1,
  V_SYNC          = 3,
  V_BACK_PORCH    = 38,
  H_SYNC_POLARITY = 1,   // 0: neg, 1: pos
  V_SYNC_POLARITY = 1    // 0: neg, 1: pos
)
(
  input  i_pixel_clk,
  output reg [2:0] o_hve,   // { display_enable, vsync, hsync} . hsync is active at desired H_SYNC_POLARITY and vsync is active at desired V_SYNC_POLARITY, display_enable is active high, low in blanking
  output reg signed [12:0] o_x, // screen x coordinate (negative in blanking, nonneg in visible picture area)
  output reg signed [12:0] o_y  // screen y coordinate (negative in blanking, nonneg in visible picture area)
);
  // A horizontal scanline consists of sequence of regions: front porch -> sync -> back porch -> display visible
  localparam signed H_START       = -H_BACK_PORCH - H_SYNC - H_FRONT_PORCH;
  localparam signed HSYNC_START   = -H_BACK_PORCH - H_SYNC;
  localparam signed HSYNC_END     = -H_BACK_PORCH;
  localparam signed HACTIVE_START = 0;
  localparam signed HACTIVE_END   = H_RESOLUTION - 1;
  // Vertical image frame has the same structure, but counts scanlines instead of pixel clocks.
  localparam signed V_START       = -V_BACK_PORCH - V_SYNC - V_FRONT_PORCH;
  localparam signed VSYNC_START   = -V_BACK_PORCH - V_SYNC;
  localparam signed VSYNC_END     = -V_BACK_PORCH;
  localparam signed VACTIVE_START = 0;
  localparam signed VACTIVE_END   = V_RESOLUTION - 1;

  reg signed [12:0] x, y;
  always @(posedge i_pixel_clk) begin
    x <= (x == HACTIVE_END) ? 13'(H_START) : x + 1'b1;
    if   (x == HACTIVE_END) y <= (y == VACTIVE_END) ? 13'(V_START) : y + 1'b1;
    o_x <= x;
    o_y <= y;
    o_hve <= { x >= 0 && y >= 0, // display enable is high when in visible picture area
               1'(V_SYNC_POLARITY) ^ (y >= VSYNC_START && y < VSYNC_END), // vsync bit
               1'(H_SYNC_POLARITY) ^ (x >= HSYNC_START && x < HSYNC_END) }; // hsync bit
  end
endmodule
