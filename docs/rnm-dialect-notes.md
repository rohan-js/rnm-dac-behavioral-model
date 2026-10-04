# RNM dialect notes - `nettype real` (UDN) vs Verilog-AMS `wreal`

Written from this project's empirical findings, not from marketing pages.
Companion evidence: `docs/tool-support.md`.

## Why two dialects exist

Real Number Modeling puts real-valued analog quantities on an **event-driven
digital kernel** so analog blocks can be represented at RTL speed without an
analog solver. There are two language mechanisms for it:

| | Verilog-AMS `wreal` | SystemVerilog `nettype real` (UDN) |
|-|-|-|
| Standard | Accellera Verilog-AMS LRM (2.4+) | IEEE 1800-2017 §6.6.7 (user-defined nettypes) |
| Net value type | Predefined `wreal` nettype | Any user-defined nettype (`nettype real`, structs = UDT) |
| Resolution of multiple drivers | Predefined variants (`wrealx`, `wrealsum`, `wrealavg`, …) | **Arbitrary user-defined resolution functions (UDR)** - a superset in expressive power |
| Simulator requirement | Verilog-AMS compiler + AMS-licensed environment (typically pulls an analog solver install) | **Digital kernel only** - any IEEE 1800-2017-compliant simulator |
| Tool evidence (this project) | Not executable on Questa 2024.1 base (needs ADMS), EPG Xcelium 25.03 (needs Spectre), EPG Riviera 2025.04 (no AMS subset) | **Executes on Questa 2024.1 base - verified** |

## The port (what changed between our two dialect files)

- `output RealNet vout` (UDN, from `rnm_pkg`) → `output wreal vout` (VAMS)
- `import rnm_pkg::*` disappears - `wreal` is a built-in nettype
- Transfer function is identical: `assign vout = vref * real'(code) / 64.0`
- Everything else (TB structure, real-valued checking, SVA on reals) is
  dialect-independent - assertions live in the digital TB either way

## Practical findings (gotchas we hit)

1. **`expect` is a reserved SystemVerilog keyword** (vlog-13069 / xmvlog
   FNDKWD) - never use it as a signal name.
2. **Uninitialized real nets produce NaN at t=0** (`0.0 * 0.0 / 0.0` in a
   divider, vsim-8604) - initialize model inputs at declaration.
3. **`-ams` on xrun switches to the full mixed-signal flow and hard-requires a
   Spectre installation** at startup (`*F,SPNFDFE`), even for wreal-only
   designs. A "digital" Xcelium cannot be coaxed into `wreal`.
4. Aldec Riviera Pro 2025.04 (as shipped on EDA Playground) does **not**
   include the Verilog-AMS subset despite general RNM marketing.
5. **UDR driver-array ordering is simulator-specific.** A resolution function
   that indexes a "last" driver is non-portable - Questa 2024.1 does not
   preserve source order across two continuous drivers. Portable UDR
   functions must be order-independent (mean/max/min). See
   `tb/tb_udr_multidriver.sv` for the verified demonstration.
6. **`nettype` declarations are legal inside a package** and import cleanly
   (`import rnm_pkg::*;`) on Questa 2024.1 - the tidy way to share UDN/UDR
   across model and TB files.

## Claim discipline (for the résumé and this README)

- **Executed / verified:** `nettype real` UDN + UDR + UDT, real-valued SVA -
  local Questa 2024.1.
- **Documented port only:** `wreal` twin (`epg/dac_wreal.sv`) - reviewed
  syntax equivalence, explicitly not executed.
- Interview phrasing: *"I implemented the model in the IEEE 1800 nettype flow
  because it runs on the digital kernel I already license, and I maintain a
  reviewed wreal port plus this dialect-mapping document for when an AMS-
  licensed environment is available."*
