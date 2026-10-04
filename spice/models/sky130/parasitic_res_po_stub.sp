* parasitic_res_po_stub.sp - documented stub for sky130_fd_pr__model__parasitic__res_po
*
* The official cell (libs.tech/ngspice/parasitics/ in a full sky130A install)
* is the RC-extraction shunt network of the poly resistor body to substrate
* (ports: plus, minus, bulk). It is NOT distributed in the
* google/skywater-pdk-libs-sky130_fd_pr cells repo this project pulls from.
*
* Stubbing it as an open circuit is:
*   - DC-exact (a shunt-only network carries no DC current)
*   - negligible for the settling bench: the omitted poly RC parasitics are
*     fF-scale against the explicit 1 pF load capacitor in the transient bench
* The decision (and its limitation) is recorded in docs/model-accuracy-report.md.
.subckt sky130_fd_pr__model__parasitic__res_po plus minus b w=1 l=1
* intentionally open
.ends
