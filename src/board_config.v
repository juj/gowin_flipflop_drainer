// Global project-wide configuration defines. Include this in the beginning of each file.

// Uncomment this to target Sipeed Tang Nano 4K (which has the Gowin FPGA model GW1NSR-4C GW1NSR-LV4CQN48PC6/I5)
//`define GW1N4

// Uncomment this to target Sipeed Tang Nano 9K (which has the Gowin FPGA model GW1NR-9C GW1NR-LV9QN88PC6/I5)
`define GW1N9

// Uncomment this to target Sipeed Tang Primer 20K (which has the Gowin FPGA model GW2A GW2A-LV18PG256C8/I7)
//`define GW2A

// Notes:
// The PLLVR module is only supported by the following device families: GW1NS-4-*, GW1NS-4C-*, GW1NSR-4-*, GW1NSER-4C-*, GW1NSR-4C-*
// Other devices use the rPLL module.

// The TLVDS_OBUF module can be used for HDMI output on the Tang Nano 4K, whereas
// the ELVDS_OBUF module must be used for HDMI output on the Tang Nano 9K and Tang Primer 20K.

// If the wrong kind of LVDS module is attempted to be instantiated on the target board, there will be no
// errors issued during synthesis, but Place & Route step will issue the error:
//  "Illegal port attribute value specified 'DRIVE = 3.5' on 'hdmi_tx_p[0]'"
