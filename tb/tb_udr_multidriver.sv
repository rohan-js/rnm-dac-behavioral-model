// tb_udr_multidriver.sv — UDR rep: two drivers on one UDN, order-independent
// resolution.
//
// Completes the UDR evidence: rnm_pkg's res_avg resolution function must
// resolve the multi-driver case to the MEAN of the driver values — a
// deterministic, order-independent result (driver-array ordering is
// simulator-specific, so avg/max are the portable resolution patterns).
//
// Run: qrun -sv rnm/rnm_pkg.sv tb/tb_udr_multidriver.sv
// Expected: UDR_MULTI_PASS (vbus = mean(1.1, 2.2) = 1.65)
`timescale 1ns/1ps
import rnm_pkg::*;

module tb_udr_multidriver;
  real        v1, v2;
  RealNetAvg  vbus;

  // two continuous drivers on the same user-defined net
  assign vbus = v1;
  assign vbus = v2;

  initial begin
    v1 = 1.1;
    v2 = 2.2;
    #10;
    begin
      real exp_v, err;
      exp_v = (v1 + v2) / 2.0;   // 1.65
      err   = vbus - exp_v;
      if (err < 0.0) err = -err;
      if (err < EPS_V)
        $display("UDR_MULTI_PASS vbus=%f (res_avg of %f, %f)", vbus, v1, v2);
      else
        $fatal(1, "UDR_MULTI_FAIL vbus=%f expected mean=%f", vbus, exp_v);
    end
    $finish;
  end
endmodule
