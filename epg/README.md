# EDA Playground wreal smoke test — how to run

`wreal` needs an AMS-capable simulator. The local Questa 2024.1 is base-only
(see `docs/tool-support.md`), so the `wreal` dialect is verified on EDA
Playground's Cadence Xcelium.

1. Go to <https://www.edaplayground.com> (free account required for Xcelium).
2. Simulator: **Cadence Xcelium** (left panel dropdown).
3. Testbench+design language: **SystemVerilog**.
4. Paste the entire contents of `wreal_smoke.sv` into the **testbench.sv** panel.
5. If compilation complains about `wreal`, add `-ams` to the **Compile Options**
   box (Xcelium's mixed-signal entry point) and run again.
6. Expected output line:

   ```
   WREAL_SMOKE_PASS vout=2.200000 expect=2.200000
   ```

7. Copy the full log (and the Xcelium version banner shown at the top of the
   log) back into `docs/tool-support.md`.

Later phases reuse the same procedure for the `wreal` twin of the DAC model
(`epg/dac_wreal.sv`).
