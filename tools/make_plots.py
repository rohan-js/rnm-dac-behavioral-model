#!/usr/bin/env python3
"""Generate the two evidence plots into results/.

plot_dc_accuracy.png — SPICE sweep vs calibrated model (top) and the
                       model-vs-SPICE residual against the half-LSB gate (bottom)
plot_settling.png    — transient output for the code 0 -> 63 step (1 pF load)
"""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO = Path(__file__).resolve().parent.parent
RES = REPO / "results"
RAW = REPO / "spice" / "raw"

NCODES, VREF = 64, 3.3
LSB = VREF / NCODES
HALF_LSB = VREF / 128


def main():
    fit = __import__("json").loads((RES / "fit_summary.json").read_text())
    off, gain, bow = fit["off_v"], fit["gain"], fit["bow_v_per_v2"]

    codes, vspice = [], []
    for ln in (RAW / "dac6_dc.csv").read_text().splitlines()[1:]:
        c, v = ln.split(",")
        codes.append(int(c))
        vspice.append(float(v))
    ideal = [VREF * c / NCODES for c in codes]
    vmodel = [off + gain * i + bow * i * i for i in ideal]
    resid = [m - s for m, s in zip(vmodel, vspice)]

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), sharex=True,
                                   gridspec_kw={"height_ratios": [3, 1.4]})
    ax1.plot(codes, vspice, "o", ms=4, label="SKY130 tt device bench (ngspice)")
    ax1.plot(codes, vmodel, "-", lw=1.2, label="calibrated SV model")
    ax1.plot(codes, ideal, "--", lw=0.8, color="gray", label="ideal line")
    ax1.set_ylabel("Vout (V)")
    ax1.legend(loc="upper left", fontsize=8)
    ax1.set_title("6-bit R-string DAC: real-number model vs device-level SPICE")
    ax2.axhspan(-HALF_LSB, HALF_LSB, color="green", alpha=0.15,
                label="half-LSB gate")
    ax2.plot(codes, [r * 1e3 for r in resid], ".-", ms=3, lw=0.8, color="crimson")
    ax2.set_xlabel("DAC code")
    ax2.set_ylabel("residual (mV)")
    ax2.legend(fontsize=8)
    ax2.set_ylim(-2.5, 2.5)
    fig.tight_layout()
    fig.savefig(RES / "plot_dc_accuracy.png", dpi=150)

    tran = []
    for ln in (RAW / "dac6_tran.csv").read_text().splitlines():
        p = ln.split()
        if len(p) >= 2:
            tran.append((float(p[0]) * 1e6, float(p[1])))  # -> µs
    vf = fit["settling"]["vfinal_v"]
    fig2, ax = plt.subplots(figsize=(8, 3.6))
    ax.plot([t for t, _ in tran], [v for _, v in tran], lw=1.0)
    ax.axhline(vf, color="gray", lw=0.8, ls="--", label=f"final = {vf:.4f} V")
    ax.axhspan(vf - HALF_LSB, vf + HALF_LSB, color="green", alpha=0.15,
               label="half-LSB band")
    ax.axvline(10.0, color="orange", lw=0.8, ls=":", label="code step 0 -> 63")
    ax.set_xlabel("time (µs)")
    ax.set_ylabel("Vout (V)")
    ax.set_title(f"Settling: code 0 -> 63, CL = 1 pF, tau = "
                 f"{fit['settling']['tau_s']:.3g} s")
    ax.legend(fontsize=8, loc="lower right")
    fig2.tight_layout()
    fig2.savefig(RES / "plot_settling.png", dpi=150)
    print("wrote results/plot_dc_accuracy.png, results/plot_settling.png")


if __name__ == "__main__":
    main()
