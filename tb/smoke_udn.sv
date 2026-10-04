// smoke_udn.sv - Phase 0 ground-truth smoke test for SystemVerilog Real Number Modeling
// Exercises: UDN (nettype real), UDR (user-defined resolution function),
//            UDT (user-defined struct nettype), real-valued checking, SVA bound assertion.
// Target   : QuestaSim 2024.1 base (digital kernel) - C:\questasim64_2024.1
// Run      : qrun -sv tb/smoke_udn.sv
`timescale 1ns/1ps

// -
// UDR - user-defined resolution function (last-driver-wins)
// -
function automatic real res_last (input real drivers[]);
  if (drivers.size() == 0) return 0.0;
  return drivers[drivers.size()-1];
endfunction

// -
// UDT - user-defined type carried on a net (value + valid flag)
// -
typedef struct {
  real  value;
  logic valid;
} analog_t;

function automatic analog_t res_analog (input analog_t drivers[]);
  analog_t r;
  if (drivers.size() == 0) begin
    r.value = 0.0;
    r.valid = 1'b0;
  end else begin
    r = drivers[drivers.size()-1];
  end
  return r;
endfunction

// -
// UDN declarations
// -
nettype real     RealNet   with res_last;
nettype analog_t AnalogNet with res_analog;

// -
// DUT - resistor divider as a real-number behavioral model
// -
module rdiv (
  input  real    vtop,
  input  real    r1,
  input  real    r2,
  output RealNet vout
);
  assign vout = vtop * r2 / (r1 + r2);
endmodule

// -
// Testbench
// -
module smoke_tb;
  real    vtop = 0.0, r1 = 1.0e3, r2 = 2.0e3;
  RealNet vout;

  rdiv dut (.vtop(vtop), .r1(r1), .r2(r2), .vout(vout));

  // continuous cast of the UDN into a real for checking
  real vout_r;
  assign vout_r = vout;

  // UDT net exercise
  AnalogNet a;
  analog_t  a_drive;
  assign a = a_drive;

  // clocked sampling + SVA bound assertion
  logic clk = 1'b0;
  always #5 clk = ~clk;

  real exp_v;
  real err;
  always @(posedge clk) begin
    err = vout_r - exp_v;
    if (err < 0.0) err = -err;
  end

  A_BOUND: assert property (@(posedge clk) err < 1.0e-9)
    else $error("BOUND violated: |vout-%f| = %g", exp_v, err);

  initial begin
    vtop = 3.3;
    r1   = 1.0e3;
    r2   = 2.0e3;
    exp_v = 3.3 * 2.0e3 / 3.0e3;   // 2.2 V
    a_drive = '{value: 1.25, valid: 1'b1};

    #20;

    if (err < 1.0e-9)
      $display("UDN_SMOKE_PASS vout=%.6f exp_v=%.6f", vout_r, exp_v);
    else
      $fatal(1, "UDN_SMOKE_FAIL vout=%.6f exp_v=%.6f err=%g", vout_r, exp_v, err);

    if (a.valid === 1'b1 && a.value == 1.25)
      $display("UDT_SMOKE_PASS value=%f valid=%b", a.value, a.valid);
    else
      $fatal(1, "UDT_SMOKE_FAIL value=%f valid=%b", a.value, a.valid);

    $finish;
  end
endmodule
