# SKY130 primitive models - provenance

Pulled from `google/skywater-pdk-libs-sky130_fd_pr` (cells/nfet_01v8,
cells/pfet_01v8, cells/res_high_po), tt/ff/ss corner + mismatch + pm3 files,
Apache-2.0 (copyright headers preserved in each file).

Used subset: tt corner + mismatch corner + pm3 for nfet_01v8/pfet_01v8,
res_high_po model. `parasitic_res_po_stub.sp` is a documented local stub
(see its header) for the RC-extraction shunt cell that is not distributed
in the cells repo.

Working include recipe (empirical, ngspice-47 - see
docs/model-accuracy-report.md): include the tt.corner (params; its internal
pm3 include resolves relative to the including file) + mismatch.corner;
do NOT also include the pm3 directly (double subckt definition breaks
parameter scoping). Instantiate FETs as X-instances of the wrapper subckts.
