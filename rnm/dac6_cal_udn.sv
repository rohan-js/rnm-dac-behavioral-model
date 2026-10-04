// dac6_cal_udn.sv — SPICE-calibrated non-ideal 6-bit resistor-string DAC
// as a real-number behavioral model (UDN dialect).
//
// Transfer function (calibrated to the SKY130 tt device bench by
// tools/extract_and_calibrate.py; parameters in results/model_params.svh):
//   Vout = OFF + GAIN*x + BOW*x^2,  x = Vref*code/64
// Output dynamics: first-order exponential with time constant TAU (fitted
// from the transient bench), updated on a free-running 1 ns tick — the
// standard discrete-dynamics emulation for real-number models on a purely
// digital kernel.
`timescale 1ns/1ps
import rnm_pkg::*;

module dac6_cal_udn #(
  parameter real OFF  = 0.0,
  parameter real GAIN = 1.0,
  parameter real BOW  = 0.0,
  parameter real TAU  = 1.0e-6
) (
  input  logic [5:0] code,   // DAC input code, 0..63
  input  real        vref,   // reference voltage
  output RealNet     vout    // real-valued output net (UDN)
);
  real x;          // ideal code voltage (pre-calibration)
  real vtarget;    // settled output for the current code
  real vstate;     // first-order settling state

  assign x       = vref * real'(code) / 64.0;
  assign vtarget = OFF + GAIN * x + BOW * x * x;

  initial vstate = 0.0;
  always #1 begin
    vstate = vstate + (vtarget - vstate) * (1.0 - $exp(-1.0e-9 / TAU));
  end

  assign vout = vstate;
endmodule
