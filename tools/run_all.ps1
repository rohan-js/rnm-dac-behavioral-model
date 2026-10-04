# run_all.ps1 — one-command regeneration of ALL evidence.
#
# Regenerates benches -> runs the SPICE characterization (DC sweep + settling)
# -> calibrates the behavioral model -> runs the three Questa testbenches ->
# writes results/accuracy-summary.{json,md}.
#
# Usage: powershell -File tools\run_all.ps1 [-QuestaHome C:\questasim64_2024.1] [-SkipSpice]
# (SkipSpice: reuse committed spice/raw results, only re-run simulations+summary)
param(
  [string]$QuestaHome = "C:\questasim64_2024.1",
  [string]$NgspiceExe = "D:\tools\ngspice\Spice64\bin\ngspice_con.exe",
  [switch]$SkipSpice
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

function Expect-Pass($logfile, $pattern) {
  $txt = Get-Content $logfile -Raw
  if ($txt -notmatch $pattern) { Write-Host "FAILED: $pattern not in $logfile"; exit 1 }
  Write-Host "OK: $logfile"
}

# 1. SPICE characterization (regenerate benches + measure)
if (-not $SkipSpice) {
  python tools/gen_dac_netlist.py
  Push-Location spice
  & $NgspiceExe -b dac6_rstring_tran.sp | Out-Null
  if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "tran bench failed"; exit 1 }
  Pop-Location
  python tools/run_dc_sweep.py
  if ($LASTEXITCODE -ne 0) { Write-Host "dc sweep failed"; exit 1 }
  python tools/extract_and_calibrate.py
  if ($LASTEXITCODE -ne 0) { Write-Host "calibration failed"; exit 1 }
}

# 2. Questa testbenches (PASS lines captured per TB)
$qrun = Join-Path $QuestaHome "win64\qrun"
& $qrun -sv rnm/rnm_pkg.sv tb/smoke_udn.sv | Tee-Object results\sim-smoke_udn.txt | Out-Null
Expect-Pass results\sim-smoke_udn.txt "UDN_SMOKE_PASS"
& $qrun -sv rnm/rnm_pkg.sv tb/tb_udr_multidriver.sv | Tee-Object results\sim-udr_multidriver.txt | Out-Null
Expect-Pass results\sim-udr_multidriver.txt "UDR_MULTI_PASS"
& $qrun -sv rnm/rnm_pkg.sv rnm/dac6_ideal_udn.sv tb/tb_dac6_ideal.sv | Tee-Object results\sim-dac6_ideal.txt | Out-Null
Expect-Pass results\sim-dac6_ideal.txt "DAC6_IDEAL_PASS"
& $qrun -sv rnm/rnm_pkg.sv rnm/dac6_cal_udn.sv tb/tb_dac6_vs_spice.sv +incdir+results | Tee-Object results\sim-dac6_vs_spice.txt | Out-Null
Expect-Pass results\sim-dac6_vs_spice.txt "DAC6_VS_SPICE_PASS"
& $qrun -sv rnm/rnm_pkg.sv rnm/dac6_cal_udn.sv rnm/dac6_sys_udn.sv tb/tb_dac6_integration.sv +incdir+results | Tee-Object results\sim-dac6_integration.txt | Out-Null
Expect-Pass results\sim-dac6_integration.txt "DAC6_INTG_PASS"

# 3. Summary
python tools/summarize.py
Write-Host "RUN_ALL_PASS"
