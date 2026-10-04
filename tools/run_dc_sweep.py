#!/usr/bin/env python3
"""Run the DC characterization sweep: one ngspice run per DAC code.

Fills the @GN<k>@/@GP<k>@ placeholders in spice/dac6_rstring_dc.sp for each
code 0..63, runs ngspice, and collects v(out) into spice/raw/dac6_dc.csv
(columns: code, vout). Run with CWD = repo root (the runner cds into spice/).
"""
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SPICE = REPO / "spice"
NGSPICE = Path(r"D:\tools\ngspice\Spice64\bin\ngspice_con.exe")

NBITS = 6
NCODES = 1 << NBITS
VREF = 3.3


def main():
    template = (SPICE / "dac6_rstring_dc.sp").read_text(encoding="utf-8")
    results = []
    for code in range(NCODES):
        netlist = template
        for k in range(NCODES):
            on = (k == code)
            netlist = netlist.replace(f"@GN{k}@", f"{VREF if on else 0:.6f}")
            netlist = netlist.replace(f"@GP{k}@", f"{0 if on else VREF:.6f}")
        run_file = SPICE / "dac6_dc_run.sp"
        run_file.write_text(netlist, encoding="utf-8", newline="\n")
        proc = subprocess.run(
            [str(NGSPICE), "-b", "dac6_dc_run.sp"],
            cwd=SPICE, capture_output=True, text=True, timeout=300,
        )
        # the bench's control block redirects `print col v(out)` into
        # raw/dac6_last.txt — parse that, not stdout
        last = (SPICE / "raw" / "dac6_last.txt").read_text()
        m = re.search(r"^\d+\t([-+0-9.eE]+)", last, flags=re.M)
        if not m:
            print(f"code {code}: NO v(out) in output\n{proc.stdout[-800:]}",
                  file=sys.stderr)
            sys.exit(1)
        vout = float(m.group(1))
        results.append((code, vout))
        print(f"code {code:2d}: vout = {vout:.6f}")

    out = SPICE / "raw" / "dac6_dc.csv"
    with open(out, "w", newline="\n") as f:
        f.write("code,vout\n")
        for c, v in results:
            f.write(f"{c},{v:.9g}\n")
    print(f"wrote {out} ({len(results)} rows)")


if __name__ == "__main__":
    main()
