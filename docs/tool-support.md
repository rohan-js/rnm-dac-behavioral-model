# Tool support matrix - Phase 0 ground truth

Determined empirically, not from marketing pages. Re-verify whenever a tool
version changes.

| Feature | QuestaSim 2024.1 (local, base - `C:\questasim64_2024.1`) | Cadence Xcelium (EDA Playground) |
|-|-|-|
| `nettype real` UDN (user-defined net) | ✅ verified | n/a (UDN also supported) |
| UDR - user-defined resolution function | ✅ verified | (same mechanism) |
| UDT - user-defined struct nettype | ✅ verified | (same mechanism) |
| Real-valued continuous checking + SVA bound assertions on reals | ✅ verified | expected - confirm during first EPG run |
| Verilog-AMS `wreal` | ❌ requires Questa ADMS (AMS product; not installed) | ❌ not executable on EPG - Xcelium 25.03-s001 (digital) rejects `wreal` (SVNOTY); `-ams` fatals `*F,SPNFDFE` (no Spectre); **Aldec Riviera Pro 2025.04 also rejects `wreal`** (VCP2000 at the `wreal` port declaration - no AMS subset in EPG's build) |
| **wreal resolution** | - | **Dialect twin kept as documented, unexecuted port** (`epg/dac_wreal.sv`); execute on an AMS-licensed install (institute Cadence Xcelium/Spectre or Questa ADMS) when available. Executed RNM claims are carried by the UDN dialect only |
| ngspice (SPICE reference side) | ✅ ngspice-47 (console, `D:\tools\ngspice\Spice64\bin\ngspice_con.exe`) - RC smoke verified, `v(out)` tracks the DC sweep exactly | - |

## Questa 2024.1 results (local)

Command: `qrun -sv tb/smoke_udn.sv`

```
UDN_SMOKE_PASS vout=2.200000 exp_v=2.200000
UDT_SMOKE_PASS value=1.250000 valid=1
Totals: Errors: 0, Warnings: 0
```

Notes:

- UDN + UDR + UDT + real-valued assertion checking all work on the **base
  digital kernel** - no AMS license needed. This makes the IEEE 1800
  `nettype`-based RNM flow the **primary dialect** of the project.
- `expect` is a reserved SystemVerilog keyword (vlog-13069) - signal names must
  avoid it (`exp_v` used instead).
- Uninitialized real nets evaluate the divider to `0/0 = NaN` at t=0
  (vsim-8604); initialize divider inputs at declaration to keep the flow
  warning-clean.
- License env var deprecation notice: MGLS/LM_LICENSE_FILE deprecated starting
  2025.1 (SALT_LICENSE_SERVER is the future variable) - harmless today.

## Consequence for the project design

Dual-dialect deliverable:

1. **Primary:** UDN/UDT/UDR implementation in `rnm/` - developed, regressed,
   and asserted locally on Questa 2024.1.
2. **Secondary:** `wreal` twin in `epg/` - same models expressed in
   Verilog-AMS `wreal`, verified on Xcelium via EDA Playground; the
   portability delta between the two dialects is itself a documented
   deliverable (`docs/rnm-dialect-notes.md`, Phase 1).
