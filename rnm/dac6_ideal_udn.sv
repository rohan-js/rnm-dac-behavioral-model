// dac6_ideal_udn.sv - ideal 6-bit resistor-string DAC as a real-number
// behavioral model (UDN dialect).
//
// Transfer function: Vout = Vref * code / 64  (monotonic by construction;
// LSB = Vref/64, half-LSB = Vref/128).
//
// The SPICE-calibrated, non-ideal variant lands in Phase 2
// (rnm/dac6_cal_udn.sv); this module is the golden behavioral reference.
`timescale 1ns/1ps
import rnm_pkg::*;

module dac6_ideal_udn (
  input  logic [5:0] code,   // DAC input code, 0..63
  input  real        vref,   // reference voltage
  output RealNet     vout    // real-valued output net (UDN)
);
  assign vout = vref * real'(code) / 64.0;
endmodule
