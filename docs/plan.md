# Plan - RNM DAC Behavioral Model

Target role context: Cadence **Mixed-Signal Systems and Verification Engineer**
(R55855, Bangalore) - JD core: *"Developing accurate and simulation-efficient
analog behavioral models for analog/RF blocks in SystemVerilog … verifying that
the behavior models are accurate representations of analog schematics … coding
test benches, test scenarios, and assertions."*

This project is a miniature of exactly that loop, on one block, end to end.

## Block of record

**6-bit resistor-string DAC** - switch-only (no opamp design), SPICE-friendly,
and its accuracy math (INL/DNL, ½-LSB bounds) is clean.

## Phases and gates

| Phase | Work | Gate |
|-|-|-|
| 0 - Ground truth | Questa `nettype` smoke (local), Xcelium `wreal` smoke (EDA Playground), ngspice install + RC smoke, repo scaffold | Support matrix recorded in `docs/tool-support.md`; ≥1 path runs end-to-end |
| 1 - RNM reps | Resistive divider + R-2R ladder reps; **ideal 6-bit R-string DAC** model (UDN primary, wreal twin); SVA monotonicity + ½-LSB bound checks; code-corner coverage | Ideal DAC passes all assertions on local Questa |
| 2 - SPICE ground truth | Device-level DAC netlist (ngspice + SKY130 primitives: resistor ladder + transmission-gate switches); DC sweep codes 0-63 → Vout, INL/DNL in Python; corners tt/ss/ff mandatory, Monte Carlo optional; calibrate non-ideal model (offset, gain error, INL bow, first-order settling) by least-squares fit | \|V_model − V_spice\| < ½ LSB for all 64 codes post-calibration |
| 3 - Integration + automation | Parallel code-bus + update-strobe wrapper; SVA analog-style assertions (monotonic across updates, bounds, settling); `tools/run_all.ps1` + `tools/summarize.py` → `results/accuracy-summary.{json,md}`; `docs/model-accuracy-report.md` with committed plots | One command regenerates all evidence; stranger reproduces from README alone |
| 4 - Publish + résumé | Push repo (tool versions pinned); swap this project into the Cadence Mixed Signal résumé variant (replacing the CNN-Zynq slot); second Pooja Mokashi DM with the artifact; update Workday application; workspace records | - |

## Honest-claims guardrails

- Claim exactly: "SystemVerilog real-number modeling (`nettype real` UDN/UDT/UDR)
  + Verilog-AMS `wreal` (Xcelium)" - **never** "Verilog-AMS" full-language or
  analog-solver (Spectre/AMS) experience, **never** ADC/DAC design beyond this
  one block.
- Every bolded résumé number (½ LSB, INL/DNL, settling time) must be greppable
  in committed reports in `results/`.
- ngspice + SKY130 is **simulation-only** - no silicon/fabrication claims.
- Interview script for the remaining gap: digital-side modeling + SPICE
  characterization + RNM as the deliberate bridge - no bluffing.

## Risks / mitigations

| Risk | Mitigation |
|-|-|
| Questa `nettype` edge cases | Phase 0 smoke first (passed); EPG Xcelium carries any failing construct |
| sky130 Monte Carlo models fiddly in plain ngspice | Corners (tt/ss/ff) suffice for the report; MC optional |
| Scope creep | One block; switch-only DAC; VCO/PLL explicitly out of scope |
| Parallel router-tapeout project | Zero shared files; sequence heavy runs on the 7.8 GB machine |

## Timeline

~6 weeks part-time → repo done ~mid-Nov → résumé refresh + second DM late Nov
→ ~4 weeks of buffer before the R55855 close date (Dec 25, 2026).
