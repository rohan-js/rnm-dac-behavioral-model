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

**Status: Phases 0-3 complete — all gates PASSED.** Full numbers in
`results/accuracy-summary.md`; methodology and limitations in
`docs/model-accuracy-report.md`.

Headline evidence (QuestaSim 2024.1, 0 errors / 0 warnings; ngspice-47):

```
DAC6_VS_SPICE_PASS codes=64  max_res=5.1943e-04 half_lsb=2.5781e-02  (0.020 x half-LSB)
DAC6_INTG_PASS     codes=84  max_res=5.1943e-04 half_lsb=2.5781e-02  coverage=100.0%
DAC6_IDEAL_PASS    codes=64  max_err=0.000e+00 half_lsb=2.5781e-02  coverage=100.0%
UDR_MULTI_PASS     vbus=1.650000 (order-independent UDR over 2 drivers)
UDN_SMOKE_PASS     vout=2.200000 exp_v=2.200000
```

Calibration (fitted to the SKY130 tt device bench): off = 129.3 µV,
gain = 1.0000758, bow = -1.65e-5 V/V², tau = 3.23 ns (1 pF load).
INL 0.0104 LSB, DNL 0.0030 LSB.

## Quick start (local, QuestaSim 2024.1 + ngspice-47)

One command regenerates all evidence (benches -> SPICE characterization ->
calibration -> three testbenches -> summary):

```powershell
powershell -File toolsun_all.ps1
```

Individual steps:

```powershell
python tools\gen_dac_netlist.py          # benches + committed mismatch draws
python toolsun_dc_sweep.py             # 64-code device characterization (ngspice)
python tools\extract_and_calibrate.py    # fit + INL/DNL + model_params.svh
qrun -sv rnmnm_pkg.sv rnm\dac6_cal_udn.sv tb	b_dac6_vs_spice.sv +incdir+results
```

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
