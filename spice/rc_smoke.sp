* rc_smoke.sp - Phase 0 ngspice smoke test: 1st-order RC step, DC sweep
.title RC smoke test

V1 in 0 DC 1.8
R1 in out 1k
C1 out 0 1p

.control
dc V1 0 1.8 0.1
print v(out)
quit
.endc

.end
