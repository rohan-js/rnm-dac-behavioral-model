// rnm_pkg.sv — shared Real Number Modeling declarations
// Contains: UDR (user-defined resolution function), UDN (nettype real),
//           project-wide tolerances.
`timescale 1ns/1ps

package rnm_pkg;

  // ------------------------------------------------------------------
  // UDR — user-defined resolution functions.
  // res_last: last-element-wins — single-driver nets only! Driver-array
  //           ordering is simulator-specific (verified: Questa does not
  //           preserve source order), so res_last is NOT portable for
  //           multi-driver nets.
  // res_avg : order-independent mean over all drivers — the portable
  //           pattern for genuinely multi-driver nets.
  // ------------------------------------------------------------------
  function automatic real res_last (input real drivers[]);
    if (drivers.size() == 0) return 0.0;
    return drivers[drivers.size()-1];
  endfunction

  function automatic real res_avg (input real drivers[]);
    real sum;
    sum = 0.0;
    if (drivers.size() == 0) return 0.0;
    for (int i = 0; i < drivers.size(); i++) sum += drivers[i];
    return sum / drivers.size();
  endfunction

  // ------------------------------------------------------------------
  // UDN — user-defined nettypes carrying real values on the digital
  // kernel (no analog solver required).
  // ------------------------------------------------------------------
  nettype real RealNet    with res_last;   // single-driver models (DAC)
  nettype real RealNetAvg with res_avg;    // multi-driver demonstration

  // Absolute voltage tolerance for ideal-model checks (volts)
  real EPS_V = 1.0e-9;

endpackage
