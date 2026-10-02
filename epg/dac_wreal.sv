// dac_wreal.sv — Verilog-AMS wreal twin of the ideal 6-bit R-string DAC.
//
// *** NOT EXECUTED — see docs/tool-support.md for the empirical basis ***
// No simulator available to this project executes Verilog-AMS wreal:
//   - QuestaSim 2024.1 base: wreal requires the Questa ADMS product
//   - EDA Playground Xcelium 25.03: -ams requires a Spectre install (absent)
//   - EDA Playground Riviera Pro 2025.04: no AMS subset in EPG's build
// This file is a reviewed syntax port demonstrating dialect equivalence.
// Execute on any AMS-licensed install with:  xrun -ams dac_wreal.sv <tb>
`timescale 1ns/1ps

module dac6_ideal_wreal (
  input  logic [5:0] code,
  input  wreal       vref,   // wreal reference input
  output wreal       vout    // wreal analog output
);
  // identical transfer function to the UDN twin (rnm/dac6_ideal_udn.sv):
  // Vout = Vref * code / 64
  assign vout = vref * real'(code) / 64.0;
endmodule
