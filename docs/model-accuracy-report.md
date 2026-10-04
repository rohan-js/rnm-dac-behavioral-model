# Model Accuracy Report — 6-bit R-string DAC real-number behavioral model

**Status: Phase 3 complete — all gates PASSED.** Generated evidence:
`results/accuracy-summary.{json,md}` (by `tools/summarize.py`), plots
`results/plot_dc_accuracy.png`, `results/plot_settling.png`.

## 1. What is verified

A SystemVerilog **real-number behavioral model** (`rnm/dac6_cal_udn.sv`,
IEEE 1800 `nettype real` UDN) of a 6-bit resistor-string DAC is **calibrated
against a device-level SPICE characterization** (ngspice-47, SKY130 tt open
models: 64 × `sky130_fd_pr__res_high_po` ladder units with committed
per-instance ±0.5 % body-sheet mismatch, 64 transmission-gate switches from
the PDK wrapper subckts), and the calibrated model is then verified against
the committed SPICE reference table:

| Metric | Value | Gate |
|---|---|---|
| Max abs residual, model vs SPICE (64 codes) | **519.4 µV = 0.020 × half-LSB** | ≤ half-LSB (25.78 mV) — **PASS, 50× margin** |
| INL (max, vs ideal line) | 0.0104 LSB | — |
| DNL (max) | 0.0030 LSB | — |
| Fitted offset | 129.3 µV | — |
| Fitted gain | 1.0000758 | — |
| Fitted 2nd-order bow | −1.653e-5 V/V² | — |
| Settling τ (1 pF load) | 3.23 ns | — |
| Integration TB (bus + handshake + busy) | 84 codes, 100 % coverage, 0 assertion errors | **PASS** |

Simulation evidence (QuestaSim 2024.1 base, **0 errors / 0 warnings**):
`UDN_SMOKE_PASS`, `UDR_MULTI_PASS`, `DAC6_IDEAL_PASS`,
`DAC6_VS_SPICE_PASS codes=64 max_res=5.1943e-04 half_lsb=2.5781e-02`,
`DAC6_INTG_PASS codes=84 max_res=5.1943e-04`.

## 2. Methodology

1. **Bench generation** (`tools/gen_dac_netlist.py`, deterministic `rng(42)`):
   ladder of 64 poly-resistor subckts (per-instance `rsheet` override =
   committed mismatch draws) + 64 TG switches (`X`-instances of the PDK
   wrapper subckts, W=1.1 µm / L=0.16 µm); gate drives are plain V sources.
2. **Characterization** (`tools/run_dc_sweep.py`): one ngspice run per code
   (static OP) → `spice/raw/dac6_dc.csv`; settling bench: code 0→63 step
   into 1 pF → `spice/raw/dac6_tran.csv`.
3. **Calibration** (`tools/extract_and_calibrate.py`, stdlib least-squares):
   model form `Vout = OFF + GAIN·x + BOW·x²`, x = Vref·code/64; INL/DNL vs
   the ideal line; τ from the log-linear decay of the transient.
4. **Verification** (`tb/tb_dac6_vs_spice.sv`): the calibrated UDN model is
   swept over all codes with SVA monotonicity/bounds assertions, code-corner
   functional coverage, and the committed SPICE table as the golden
   reference; then `tb/tb_dac6_integration.sv` drives it through the RTL
   bus wrapper (`rnm/dac6_sys_udn.sv`: code bus + `upd` strobe + `busy`
   settling handshake) with 64 corners + 20 random codes.

## 3. Model-vs-SPICE residual — where it comes from

The residual (max 519 µV) is dominated by the per-resistor mismatch random
walk, which the 3-parameter model (offset/gain/bow) intentionally does not
absorb: the model captures systematic error; the committed reference table
carries the rest. This is the honest split — a table-lookup model would
residual to ~0 while carrying zero insight; the 3-parameter form documents
the DAC's actual systematic behavior and still sits 50× inside the
verification gate.

## 4. Limitations (stated, not hidden)

- **Parasitic stub**: the PDK's `sky130_fd_pr__model__parasitic__res_po`
  RC-extraction shunt cell is not distributed in the cells repo this project
  pulls from; `parasitic_res_po_stub.sp` replaces it with an open circuit —
  DC-exact, and the omitted fF-scale poly RC is negligible against the
  explicit 1 pF settling load.
- **tt corner only, deterministic mismatch** (±0.5 % body sheet, seeded):
  Monte-Carlo corner runs are future work; the assertion framework and
  runner accept any regenerated reference table unchanged.
- **One block**: this project deliberately does not claim ADC/VCO/PLL/
  SerDes modeling experience (see honest-claims guardrails in `docs/plan.md`).
- **No AMS simulator**: the `wreal` twin (`epg/dac_wreal.sv`) is a reviewed,
  unexecuted dialect port — see `docs/tool-support.md` for the empirical
  simulator findings and `docs/rnm-dialect-notes.md` for the dialect mapping.

## 5. Engineering findings worth an interview (all reproduced in-repo)

1. **B-source gate logic breaks OP convergence** in ngspice-47 — boolean
   (`==`), `floor()`, and even smooth Gaussian forms of `v(cs)` all abort
   the operating point, while the identical network with fixed V-source
   gates converges. Resolution: one-run-per-code with plain V gates.
2. **`.include` inside included files resolves relative to the including
   file**, but double-including the pm3 (via corner + explicit) duplicates
   the wrapper subckt and breaks parameter scoping (`Undefined [l]`).
3. **The binned BSIM cards live inside a wrapper subckt** — direct
   `.model.N` or base-name instances at top level fail ("can't find
   model"); the correct usage is an X-instance of
   `sky130_fd_pr__nfet_01v8` (internal M auto-bins).
4. **`expect` is a reserved SystemVerilog keyword**; uninitialized real
   nets evaluate `0/0` to NaN at t=0.
5. **UDR driver-array ordering is simulator-specific** — resolution
   functions must be order-independent (mean/max), not "last wins".
6. `nettype` declarations are legal package items on Questa 2024.1.

## 6. Evidence index

| Claim | Evidence |
|---|---|
| Device-level SPICE sweep (64 codes) | `spice/raw/dac6_dc.csv`, `tools/run_dc_sweep.py` |
| Settling transient | `spice/raw/dac6_tran.csv`, `results/plot_settling.png` |
| Calibration fit + INL/DNL | `results/fit_summary.json`, `results/inl_dnl.json`, `results/spice_ref.csv` |
| Model parameters consumed by SV | `results/model_params.svh` (generated) |
| Model-vs-SPICE gate | `results/sim-dac6_vs_spice.txt` (DAC6_VS_SPICE_PASS) |
| RTL integration gate | `results/sim-dac6_integration.txt` (DAC6_INTG_PASS) |
| One-command reproduction | `tools/run_all.ps1` |
