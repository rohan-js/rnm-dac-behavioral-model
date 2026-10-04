// tb_dac6_vs_spice.sv — Phase 2 gate: calibrated behavioral model vs the
// SKY130 tt device bench.
//
// The calibrated model (rnm/dac6_cal_udn.sv, parameters fitted to the
// device-level SPICE characterization by tools/extract_and_calibrate.py)
// is swept over all 64 codes and its settled output compared against the
// committed SPICE reference table (VSPICE, from results/model_params.svh).
//
// Gate: |Vmodel - Vspice| <= half LSB (Vref/128) for ALL 64 codes.
// This is the JD's "verifying that the behavior models are accurate
// representations of analog schematics" loop, in miniature.
//
// Run (from repo root):
//   qrun -sv rnm/rnm_pkg.sv rnm/dac6_cal_udn.sv tb/tb_dac6_vs_spice.sv
// Expected: DAC6_VS_SPICE_PASS codes=64 max_res=... half_lsb=...
`timescale 1ns/1ps
import rnm_pkg::*;

module tb_dac6_vs_spice;
  localparam int NCODES = 64;

  `include "results/model_params.svh"

  logic [5:0] code;
  real        vref;
  RealNet     vout;

  dac6_cal_udn #(.OFF(CAL_OFF), .GAIN(CAL_GAIN), .BOW(CAL_BOW), .TAU(CAL_TAU)) dut (
    .code(code), .vref(vref), .vout(vout)
  );

  real vout_r;
  assign vout_r = vout;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  real half_lsb;
  assign half_lsb = vref / 128.0;

  // settled-model expectation for the current code
  real exp_v;
  assign exp_v = CAL_OFF + CAL_GAIN * (vref * real'(code) / 64.0)
               + CAL_BOW * (vref * real'(code) / 64.0) ** 2;

  real err;
  assign err = (vout_r > exp_v) ? (vout_r - exp_v) : (exp_v - vout_r);

  // SVA: model self-consistency + bounds while sweeping
  real prev_v;
  initial prev_v = -1.0;
  always @(posedge clk) prev_v <= vout_r;

  // tolerance = quarter-LSB: catches real code-order breaks (>= 1 LSB drop)
  // while ignoring sub-LSB settling wiggle of the first-order dynamics
  A_MONO: assert property (@(posedge clk) vout_r >= prev_v - half_lsb / 4.0)
    else $error("MONOTONICITY violated: vout=%f prev=%f", vout_r, prev_v);

  A_BOUNDS: assert property (@(posedge clk) (vout_r >= -1.0e-9 && vout_r <= vref + 1.0e-9))
    else $error("BOUNDS violated: vout=%f", vout_r);

  // functional coverage on code corners
  covergroup cg_code @(posedge clk);
    cp_code: coverpoint code {
      bins zero = {0};
      bins one  = {1};
      bins mid  = {32};
      bins max  = {63};
      bins low  = {[2:15]};
      bins lowmid  = {[16:31]};
      bins highmid = {[33:47]};
      bins high = {[48:62]};
    }
  endgroup
  cg_code cg = new();

  initial begin
    real res, max_res_spice;
    int  fails;
    max_res_spice = 0.0;
    fails = 0;

    vref = 3.3;
    code = 6'd0;
    @(posedge clk);

    for (int c = 0; c < NCODES; c++) begin
      @(negedge clk);
      code = 6'(c);
      // let the first-order dynamics settle: 40 time constants is > 5 decades
      #(40 * CAL_TAU * 1e9); // CAL_TAU is seconds -> ns delay units
      @(posedge clk);

      // 1) model vs its own calibrated transfer function (self-consistency)
      if (err > 1.0e-9) begin
        $display("SELF-CHECK FAIL code=%0d err=%g", c, err);
        fails++;
      end
      // 2) model vs the SPICE reference table (the actual gate)
      res = vout_r - VSPICE[c];
      if (res < 0.0) res = -res;
      if (res > max_res_spice) max_res_spice = res;
      if (res > half_lsb) begin
        $display("VS-SPICE FAIL code=%0d |vmodel-vspice|=%g > half_lsb=%g",
                 c, res, half_lsb);
        fails++;
      end
    end

    if (fails == 0 && cg.cp_code.get_coverage() >= 100.0)
      $display("DAC6_VS_SPICE_PASS codes=%0d max_res=%.4e half_lsb=%.4e coverage=%.1f%%",
               NCODES, max_res_spice, half_lsb, cg.cp_code.get_coverage());
    else
      $fatal(1, "DAC6_VS_SPICE_FAIL fails=%0d max_res=%.4e coverage=%.1f%%",
             fails, max_res_spice, cg.cp_code.get_coverage());
    $finish;
  end
endmodule
