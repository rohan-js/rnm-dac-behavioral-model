// tb_dac6_ideal.sv - Phase 1 gate testbench for the ideal 6-bit R-string DAC.
//
// Checks (all evidence lands in the simulation log):
//   1. Full-code sweep 0..63, per-code |Vout - expected| <= half LSB (Vref/128)
//   2. SVA monotonicity across code transitions
//   3. SVA output-bounds check (0 <= Vout <= Vref)
//   4. Functional coverage on code corners (0, 1, 32, 63 + ranges)
//
// Run: qrun -sv rnm/rnm_pkg.sv rnm/dac6_ideal_udn.sv tb/tb_dac6_ideal.sv
// Expected: DAC6_IDEAL_PASS codes=64 max_err=... half_lsb=... coverage=100.0%
`timescale 1ns/1ps
import rnm_pkg::*;

module tb_dac6_ideal;
  localparam int NCODES = 64;

  logic [5:0] code;
  real        vref;
  RealNet     vout;

  dac6_ideal_udn dut (.code(code), .vref(vref), .vout(vout));

  // continuous cast of the UDN into a real for checking
  real vout_r;
  assign vout_r = vout;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  // R-string LSB = Vref/64 -> half LSB = Vref/128
  real half_lsb;
  assign half_lsb = vref / 128.0;

  // independently computed expectation
  real exp_v;
  assign exp_v = vref * real'(code) / 64.0;

  // absolute error
  real err;
  assign err = (vout_r > exp_v) ? (vout_r - exp_v) : (exp_v - vout_r);

  // - SVA (real-valued, sampled at posedge; code changes at negedge) -
  real prev_v;
  initial prev_v = -1.0;
  always @(posedge clk) prev_v <= vout_r;

  A_MONO: assert property (@(posedge clk) vout_r >= prev_v - EPS_V)
    else $error("MONOTONICITY violated: vout=%f prev=%f", vout_r, prev_v);

  A_BOUNDS: assert property (@(posedge clk) (vout_r >= -EPS_V && vout_r <= vref + EPS_V))
    else $error("BOUNDS violated: vout=%f vref=%f", vout_r, vref);

  A_HALF_LSB: assert property (@(posedge clk) err <= half_lsb)
    else $error("ACCURACY violated: err=%g > half_lsb=%g", err, half_lsb);

  // - functional coverage on code corners -
  covergroup cg_code @(posedge clk);
    cp_code: coverpoint code {
      bins zero    = {0};
      bins one     = {1};
      bins mid     = {32};
      bins max     = {63};
      bins low     = {[2:15]};
      bins lowmid  = {[16:31]};
      bins highmid = {[33:47]};
      bins high    = {[48:62]};
    }
  endgroup
  cg_code cg = new();

  // - stimulus + per-code procedural accuracy check -
  initial begin
    real max_err;
    int  fails;
    max_err = 0.0;
    fails   = 0;

    vref = 3.3;
    code = 6'd0;
    @(posedge clk);

    for (int c = 0; c < NCODES; c++) begin
      @(negedge clk);
      code = 6'(c);
      @(posedge clk);
      #1; // settle
      if (err > max_err) max_err = err;
      if (err > half_lsb) fails++;
    end

    if (fails == 0 && cg.cp_code.get_coverage() >= 100.0)
      $display("DAC6_IDEAL_PASS codes=%0d max_err=%.3e half_lsb=%.3e coverage=%.1f%%",
               NCODES, max_err, half_lsb, cg.cp_code.get_coverage());
    else
      $fatal(1, "DAC6_IDEAL_FAIL fails=%0d max_err=%.3e coverage=%.1f%%",
             fails, max_err, cg.cp_code.get_coverage());
    $finish;
  end
endmodule
