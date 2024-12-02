// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// Author: Harald Pretl (harald.pretl@jku.at)
// SPDX-FileCopyrightText: 2024 Harald Pretl
// SPDX-License-Identifier: Apache-2.0 license

`ifndef __GFSK_DEMODULATION__
`define __GFSK_DEMODULATION__
`include "btle_config.v"

module gfsk_demodulation #
(
  parameter GFSK_DEMODULATION_BIT_WIDTH = 5 // [HP] change from 16 to 4
) (
  input wire clk,
  input wire rst,

  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i,
  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q,
  input wire iq_valid,

  output reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0] signal_for_decision,
  output wire signal_for_decision_valid,

  output reg  phy_bit,
  output wire bit_valid
);

reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i0;
reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i1;
reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q0;
reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q1;

reg iq_valid_delay1;
reg iq_valid_delay2;
reg iq_valid_delay3;

assign signal_for_decision_valid = iq_valid_delay2;
assign bit_valid = iq_valid_delay3;

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    i0 <= 0;
    i1 <= 0;
    q0 <= 0;
    q1 <= 0;

    signal_for_decision <= 0;
    phy_bit <= 0;

    iq_valid_delay1 <= 0;
    iq_valid_delay2 <= 0;
    iq_valid_delay3 <= 0;
  end else begin
    iq_valid_delay1 <= iq_valid;
    iq_valid_delay2 <= iq_valid_delay1;
    iq_valid_delay3 <= iq_valid_delay2;

    if (iq_valid) begin
      i1 <= {{GFSK_DEMODULATION_BIT_WIDTH{i[GFSK_DEMODULATION_BIT_WIDTH-1]}}, i};
      i0 <= i1;
      q1 <= {{GFSK_DEMODULATION_BIT_WIDTH{q[GFSK_DEMODULATION_BIT_WIDTH-1]}}, q};
      q0 <= q1;
    end

    signal_for_decision <= i0*q1 - i1*q0;
    phy_bit <= (signal_for_decision > 0);

  end
end

endmodule // gfsk_demodulation
`endif
