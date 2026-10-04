// wreal_smoke.sv - Phase 0 ground-truth smoke test for Verilog-AMS wreal RNM.
// Target: EDA Playground, simulator = Cadence Xcelium (wreal needs an AMS-capable
//         simulator; base Questa does not support it - see docs/tool-support.md).
// Paste this whole file into the "testbench.sv" panel on edaplayground.com.
`timescale 1ns/1ps

// DUT - resistor divider as a wreal behavioral model
module rdiv_wreal (
  input  wreal vtop,
  input  wreal gnd,
  input  real  r1,
  input  real  r2,
  output wreal vout
);
  assign vout = gnd + (vtop - gnd) * r2 / (r1 + r2);
endmodule

module tb;
  real  vt, gg;
  real  r1 = 1.0e3, r2 = 2.0e3;

  wreal vtop, gnd, vout;
  assign vtop = vt;
  assign gnd  = gg;

  rdiv_wreal dut (.vtop(vtop), .gnd(gnd), .r1(r1), .r2(r2), .vout(vout));

  real vout_r;
  assign vout_r = vout;

  initial begin
    gg = 0.0;
    vt = 3.3;
    #10;
    begin
      real exp_v, err;
      exp_v = 3.3 * 2.0e3 / 3.0e3;   // 2.2 V
      err    = vout_r - exp_v;
      if (err < 0.0) err = -err;
      if (err < 1.0e-9)
        $display("WREAL_SMOKE_PASS vout=%.6f exp_v=%.6f", vout_r, exp_v);
      else
        $fatal(1, "WREAL_SMOKE_FAIL vout=%.6f exp_v=%.6f err=%g", vout_r, exp_v, err);
    end
    $finish;
  end
endmodule
