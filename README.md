# RNM DAC Behavioral Model — SystemVerilog real-number modeling, verified against SPICE

A 6-bit resistor-string DAC modeled as a **real-number behavioral model** in
SystemVerilog — implemented in both RNM dialects:

- **`nettype real` user-defined nets (UDN/UDT/UDR)** — IEEE 1800 portable RNM,
  runs on any modern digital simulator (developed locally on QuestaSim 2024.1)
- **Verilog-AMS `wreal`** — the classic Verilog-AMS RNM nettype (verified on
  Cadence Xcelium via EDA Playground)

The behavioral model is **calibrated against a device-level SPICE
characterization** (ngspice, SKY130 primitives): the SPICE sweep is the golden
reference, the model is fit to it, and SystemVerilog assertions bound the
model-vs-SPICE error. Model accuracy, INL/DNL, and settling are reported in
`results/` and `docs/model-accuracy-report.md`.

**Status: Phase 0 — tool ground truth.** See `docs/tool-support.md` for the
simulator support matrix and `docs/plan.md` for the phase plan.

## Quick start (local, QuestaSim 2024.1)

```powershell
qrun -sv tb\smoke_udn.sv
```

Expected: `UDN_SMOKE_PASS` and `UDT_SMOKE_PASS` lines.

## Repository layout

| Path | Contents |
|---|---|
| `rnm/` | Real-number behavioral models (UDN primary, wreal twin) |
| `tb/` | Testbenches, checkers, SVA assertion packages |
| `spice/` | ngspice netlists (DAC device-level reference, smoke tests) |
| `tools/` | Flow automation (`run_all.ps1`, `summarize.py`) |
| `results/` | Generated evidence: accuracy summaries (json + md), logs |
| `docs/` | Tool-support matrix, plan, model-accuracy report |
| `epg/` | EDA Playground variants (wreal on Xcelium) + run instructions |

## License

MIT — see [LICENSE](LICENSE).
