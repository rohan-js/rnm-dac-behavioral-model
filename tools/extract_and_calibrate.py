#!/usr/bin/env python3
"""Extract SPICE characterization and calibrate the behavioral model.

Inputs  (spice/raw/): dac6_dc.csv (code,vout), dac6_tran.csv (time,vout)
Outputs (results/):   spice_ref.csv, inl_dnl.json, fit_summary.json,
                      model_params.svh  (consumed by tb_dac6_vs_spice.sv)

Model form:  Vout = OFF + GAIN*x + BOW*x^2,  x = Vref*code/64
Fit: ordinary least squares on the 64 SPICE points (3x3 normal equations,
pure stdlib — no numpy needed on this machine).

Settling: threshold = half LSB (Vref/128) against the final value; tau from
a log-linear fit of |v - vfinal| between 20 ns and 60% of the decay.
"""
import json
import math
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
RAW = REPO / "spice" / "raw"
RES = REPO / "results"

NBITS = 6
NCODES = 1 << NBITS
VREF = 3.3
LSB = VREF / NCODES
HALF_LSB = VREF / (2 * NCODES)


def read_dc():
    pts = []
    for ln in (RAW / "dac6_dc.csv").read_text().splitlines()[1:]:
        c, v = ln.split(",")
        pts.append((int(c), float(v)))
    return pts


def read_tran():
    pts = []
    for ln in (RAW / "dac6_tran.csv").read_text().splitlines():
        parts = ln.split()
        if len(parts) >= 2:
            pts.append((float(parts[0]), float(parts[1])))
    return pts


def lstsq3(rows, ys):
    """Solve normal equations for [a,b,c] minimizing |y - (a + b*x1 + c*x2)|^2.

    Pure-stdlib least squares: build the 3x3 normal matrix and rhs in one
    pass, then Gaussian elimination with partial pivoting.
    """
    M = [[0.0] * 3 for _ in range(3)]
    rhs = [0.0, 0.0, 0.0]
    for (x1, x2), y in zip(rows, ys):
        f = (1.0, x1, x2)
        for i in range(3):
            for j in range(3):
                M[i][j] += f[i] * f[j]
            rhs[i] += f[i] * y
    aug = [row[:] + [rhs[i]] for i, row in enumerate(M)]
    for col in range(3):
        piv = max(range(col, 3), key=lambda r: abs(aug[r][col]))
        aug[col], aug[piv] = aug[piv], aug[col]
        for r in range(3):
            if r != col and abs(aug[r][col]) > 1e-300:
                fac = aug[r][col] / aug[col][col]
                for cc in range(col, 4):
                    aug[r][cc] -= fac * aug[col][cc]
    return [aug[i][3] / aug[i][i] for i in range(3)]


def main():
    RES.mkdir(exist_ok=True)
    dc = read_dc()
    assert len(dc) == NCODES, f"expected {NCODES} dc points, got {len(dc)}"

    ideal = [VREF * c / NCODES for c, _ in dc]
    vspice = [v for _, v in dc]

    # INL / DNL against the ideal straight line
    inl = [(v - i) / LSB for v, i in zip(vspice, ideal)]
    dnl = [0.0] + [(vspice[k] - vspice[k - 1] - LSB) / LSB for k in range(1, NCODES)]

    # least-squares fit of the behavioral model form
    rows = [(i, i * i) for i in ideal]
    off, gain, bow = lstsq3(rows, vspice)
    vmodel = [off + gain * i + bow * i * i for i in ideal]
    resid = [vm - vs for vm, vs in zip(vmodel, vspice)]
    max_resid = max(abs(r) for r in resid)

    # settling from the transient bench
    tran = read_tran()
    vf = sum(v for t, v in tran[-10:]) / 10.0
    t_settle = None
    for t, v in tran:
        if t >= 10.2e-9 and abs(v - vf) <= HALF_LSB:
            t_settle = t
            break
    # tau from log-linear fit over the MEANINGFUL decay region only
    # (|v-vf| between 90% and 1% of the initial step) — fitting the noise
    # tail produces garbage slopes
    step0 = abs(tran[0][1] - vf)
    pts = [(t, abs(v - vf)) for t, v in tran
           if 0.01 * step0 <= abs(v - vf) <= 0.90 * step0]
    if len(pts) >= 2:
        import statistics
        xs = [t for t, _ in pts]
        ys = [math.log(d) for _, d in pts]
        mx, my = statistics.fmean(xs), statistics.fmean(ys)
        slope = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / \
                sum((x - mx) ** 2 for x in xs)
        tau = -1.0 / slope
    else:
        tau = float("nan")

    # ---- outputs ----
    with open(RES / "spice_ref.csv", "w", newline="\n") as f:
        f.write("code,vspice,vmodel_fit\n")
        for c, vs, vm in zip(range(NCODES), vspice, vmodel):
            f.write(f"{c},{vs:.9g},{vm:.9g}\n")

    inl_dnl = {
        "inl_max_lsb": max(max(inl), -min(inl)),
        "inl_min_lsb": min(inl),
        "dnl_max_lsb": max(max(dnl), -min(dnl)),
        "lsb_v": LSB,
        "half_lsb_v": HALF_LSB,
    }
    (RES / "inl_dnl.json").write_text(json.dumps(inl_dnl, indent=2) + "\n")

    fit = {
        "model": "Vout = OFF + GAIN*x + BOW*x^2, x = Vref*code/64",
        "off_v": off,
        "gain": gain,
        "bow_v_per_v2": bow,
        "max_abs_residual_v": max_resid,
        "max_abs_residual_in_half_lsb": max_resid / HALF_LSB,
        "pass_half_lsb": bool(max_resid <= HALF_LSB),
        "settling": {
            "vfinal_v": vf,
            "t_settle_half_lsb_s": t_settle,
            "tau_s": tau,
            "threshold_v": HALF_LSB,
        },
        "bench": {
            "vref": VREF, "codes": NCODES, "pdk": "SKY130 tt (open models)",
            "mismatch": "+/-0.5% body sheet, rng(42), see spice/dac6_mismatch.csv",
        },
    }
    (RES / "fit_summary.json").write_text(json.dumps(fit, indent=2) + "\n")

    svh = [
        "// model_params.svh — GENERATED by tools/extract_and_calibrate.py — do not edit",
        "// Values come from spice/raw/dac6_dc.csv (SKY130 tt device bench).",
        f"localparam real CAL_OFF  = {off:.9g};",
        f"localparam real CAL_GAIN = {gain:.9g};",
        f"localparam real CAL_BOW  = {bow:.9g};",
        f"localparam real CAL_TAU  = {tau:.9g};",
        f"real VSPICE [0:{NCODES-1}] = '{{",
        "  " + ",\n  ".join(f"{v:.9g}" for v in vspice),
        "};",
        "",
    ]
    (RES / "model_params.svh").write_text("\n".join(svh), encoding="utf-8", newline="\n")

    print(f"fit: off={off:.3e} gain={gain:.9f} bow={bow:.3e}")
    print(f"max |residual| = {max_resid:.3e} V = {max_resid/HALF_LSB:.4f} x half-LSB "
          f"-> {'PASS' if max_resid <= HALF_LSB else 'FAIL'}")
    print(f"INL max = {inl_dnl['inl_max_lsb']:.4f} LSB, DNL max = {inl_dnl['dnl_max_lsb']:.4f} LSB")
    print(f"settling: vf={vf:.6f} V, tau={tau:.3e} s, t_settle={t_settle}")


if __name__ == "__main__":
    main()
