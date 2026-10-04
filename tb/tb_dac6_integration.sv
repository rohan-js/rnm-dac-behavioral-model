// tb_dac6_integration.sv — Phase 3 gate: digital bus TB driving the analog
// model through the RTL wrapper.
//
// Stimulus: all 64 codes in order, then 20 constrained-random codes.
// Protocol: drive code_bus, pulse `upd` for one cycle, wait for `busy` to
// fall, then check the settled output against the committed SPICE table.
//
// Assertions:
//   A_MOVES_ONLY_WHEN_BUSY — the analog output may only change while busy
//   A_BOUNDS               — output stays inside [0, Vref]
//
// Run (from repo root):
//   qrun -sv rnm/rnm_pkg.sv rnm/dac6_cal_udn.sv rnm/dac6_sys_udn.sv tb/tb_dac6_integration.sv +incdir+results
// Expected: DAC6_INTG_PASS codes=84 max_res=... half_lsb=...
`timescale 1ns/1ps
import rnm_pkg::*;

module tb_dac6_integration;
  localparam int NCORNERS = 64;
  localparam int NRAND = 20;

  `include "results/model_params.svh"

  logic       clk = 1'b0;
  logic       rst_n;
  logic [5:0] code_bus;
  logic       upd;
  logic       busy;
  real        vref;
  RealNet     vout;

  always #5 clk = ~clk;

  dac6_sys_udn #(.OFF(CAL_OFF), .GAIN(CAL_GAIN), .BOW(CAL_BOW), .TAU(CAL_TAU)) dut (
    .clk(clk), .rst_n(rst_n), .code_bus(code_bus), .upd(upd),
    .busy(busy), .vref(vref), .vout(vout)
  );

  real vout_r;
  assign vout_r = vout;

  real half_lsb;
  assign half_lsb = vref / 128.0;

  bit started = 1'b0;  // power-on settling (before the first upd) is not a
                       // protocol violation — the model settles from t=0
  A_MOVES_ONLY_WHEN_BUSY: assert property (@(posedge clk) disable iff (!rst_n)
      $changed(vout_r) |-> (busy || !started))
    else $error("OUTPUT moved while not busy: vout=%f", vout_r);

  A_BOUNDS: assert property (@(posedge clk) disable iff (!rst_n)
      (vout_r >= -1.0e-9 && vout_r <= vref + 1.0e-9))
    else $error("BOUNDS violated: vout=%f", vout_r);

  covergroup cg_code @(posedge clk);
    cp_code: coverpoint dut.code_q {
      bins all_codes[] = {[0:63]};
    }
  endgroup
  cg_code cg = new();

  task automatic apply_code(input int c);
    @(negedge clk);
    code_bus = 6'(c);
    upd = 1'b1;
    @(negedge clk);
    upd = 1'b0;
    wait (!busy);
    @(negedge clk);
  endtask

  initial begin
    real res, max_res;
    int  fails, total;
    max_res = 0.0;
    fails = 0;
    total = 0;

    vref = 3.3;
    rst_n = 1'b0;
    code_bus = '0;
    upd = 1'b0;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    @(negedge clk);

    // arm the protocol assertion only after power-on settling (40 tau)
    #(40 * CAL_TAU * 1e9);
    started = 1'b1;

    // corners in order
    for (int c = 0; c < NCORNERS; c++) begin
      apply_code(c);
      res = vout_r - VSPICE[c];
      if (res < 0.0) res = -res;
      if (res > max_res) max_res = res;
      if (res > half_lsb) begin
        $display("INTG FAIL code=%0d |res|=%g", c, res);
        fails++;
      end
      total++;
    end

    // constrained-random follow-up
    for (int i = 0; i < NRAND; i++) begin
      int unsigned c;
      assert (std::randomize(c) with { c < 64; });
      apply_code(c);
      res = vout_r - VSPICE[c];
      if (res < 0.0) res = -res;
      if (res > max_res) max_res = res;
      if (res > half_lsb) begin
        $display("INTG FAIL rand code=%0d |res|=%g", c, res);
        fails++;
      end
      total++;
    end

    if (fails == 0 && cg.cp_code.get_coverage() >= 100.0)
      $display("DAC6_INTG_PASS codes=%0d max_res=%.4e half_lsb=%.4e coverage=%.1f%%",
               total, max_res, half_lsb, cg.cp_code.get_coverage());
    else
      $fatal(1, "DAC6_INTG_FAIL fails=%0d max_res=%.4e coverage=%.1f%%",
             fails, max_res, cg.cp_code.get_coverage());
    $finish;
  end
endmodule
