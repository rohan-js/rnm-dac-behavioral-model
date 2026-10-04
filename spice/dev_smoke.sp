* dev_smoke.sp - SKY130 device smoke: one poly resistor + one TG switch
* Verifies the include chain, binning, and instance syntax before the DAC bench.
*
* Global process constants the cells-repo files expect (values documented):
*   var / slope_spectre / con_slope_spectre - MC machinery, zeroed for the
*     deterministic bench (per-instance mismatch applied via rsheet override)
*   tc1/tc2rpolybody - poly resistor temperature coefficients, zeroed for the
*     isothermal 27 C bench
* MOS instances use EXPLICIT bin cards (nfet .62 / pfet .71 for W=1.1u L=0.16u;
* ranges parsed from the pm3 files) - ngspice does not auto-bin from base name.
.param sky130_fd_pr__res_high_po__var = 0
.param sky130_fd_pr__res_high_po__slope_spectre = 0
.param sky130_fd_pr__res_high_po__con_slope_spectre = 0
.param sky130_fd_pr__pfet_01v8__wlod_diff = 0
.param sky130_fd_pr__pfet_01v8__kvth0_diff = 0
.param sky130_fd_pr__pfet_01v8__lkvth0_diff = 0
.param sky130_fd_pr__pfet_01v8__wkvth0_diff = 0
.param sky130_fd_pr__pfet_01v8__ku0_diff = 0
.param sky130_fd_pr__pfet_01v8__lku0_diff = 0
.param sky130_fd_pr__pfet_01v8__wku0_diff = 0
.param sky130_fd_pr__pfet_01v8__kvsat_diff = 0
.param tc1rpolybody = 0
.param tc2rpolybody = 0

* Include chain note: the corner files' internal `.include` resolves relative
* to CWD, not to the including file - so the tt.pm3 model-card files are
* included directly here (tt.pm3 == nominal corner; corner multiplier params
* are only needed for MC corners, which this deterministic bench does not use).
.include "models/sky130/sky130_fd_pr__nfet_01v8__tt.corner.spice"
.include "models/sky130/sky130_fd_pr__nfet_01v8__mismatch.corner.spice"
.include "models/sky130/sky130_fd_pr__pfet_01v8__tt.corner.spice"
.include "models/sky130/sky130_fd_pr__pfet_01v8__mismatch.corner.spice"
.include "models/sky130/sky130_fd_pr__res_high_po.model.spice"
.include "models/sky130/parasitic_res_po_stub.sp"

Vvref vref 0 DC 3.3

Xr1 vref n1 0 sky130_fd_pr__res_high_po w=1 l=1

* TG switch: n-pass + p-pass
Xd1 out gn n1 0 sky130_fd_pr__nfet_01v8 w=1.1u l=0.16u
Xs1 out gp n1 vref sky130_fd_pr__pfet_01v8 w=1.1u l=0.16u
Vgn gn 0 DC 3.3
Vgp gp 0 DC 0

.control
op
print v(n1) v(out)
print i(Vvref)
quit
.endc
.end
