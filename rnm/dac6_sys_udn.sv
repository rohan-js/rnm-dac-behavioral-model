// dac6_sys_udn.sv — RTL integration wrapper for the calibrated DAC model.
//
// Digital side: 6-bit parallel code bus + 1-cycle `upd` strobe, code register,
// and a `busy` flag held high for the model's settling window (10 time
// constants, computed from TAU at elaboration). Analog side: the calibrated
// real-number behavioral model (rnm/dac6_cal_udn.sv) on a UDN output net.
//
// This is the JD's "integrating the models with RTL" — the RNM model hangs
// off real register-transfer logic with a handshake, so a digital TB can
// treat the analog block as just another bus-mapped peripheral.
`timescale 1ns/1ps
import rnm_pkg::*;

module dac6_sys_udn #(
  parameter real OFF  = 0.0,
  parameter real GAIN = 1.0,
  parameter real BOW  = 0.0,
  parameter real TAU  = 1.0e-6
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [5:0]  code_bus,  // new DAC code
  input  logic        upd,       // 1-cycle strobe: latch code_bus
  output logic        busy,      // high while the analog output settles
  input  real         vref,
  output RealNet      vout
);
  // settling window: 10 time constants, in 1 ns model ticks
  localparam int SETTLE_TICKS = int'(10.0 * TAU * 1.0e9) + 1;

  logic [5:0] code_q;
  logic [31:0] cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      code_q <= '0;
      cnt    <= '0;
    end else begin
      if (upd) code_q <= code_bus;
      if (upd) cnt <= SETTLE_TICKS;
      else if (cnt != '0) cnt <= cnt - 1'b1;
    end
  end

  assign busy = (cnt != '0);

  dac6_cal_udn #(.OFF(OFF), .GAIN(GAIN), .BOW(BOW), .TAU(TAU)) u_dac (
    .code(code_q), .vref(vref), .vout(vout)
  );
endmodule
