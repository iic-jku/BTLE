// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Input phy_bit rate 1M, output phy_bit rate 8M
// clk speed 16M

`ifndef __BIT_REPEAT_UPSAMPLE__
`define __BIT_REPEAT_UPSAMPLE__

`timescale 1ns / 1ps
module bit_repeat_upsample #
(
  /* verilator lint_off UNUSEDPARAM */
  parameter SAMPLE_PER_SYMBOL = 8
  /* verilator lint_on UNUSEDPARAM */
) (
  input wire clk,
  input wire rst,

  input wire phy_bit,
  input wire bit_valid,
  input wire bit_valid_last,

  output reg  bit_upsample,
  output wire bit_upsample_valid,
  output wire bit_upsample_valid_last
);

reg [14:0] bit_valid_delay;
reg [14:0] bit_valid_last_delay;
wire bit_valid_wide;
wire bit_valid_last_wide;
reg bit_upsample_valid_internal;
reg [2:0] bit_upsample_count;
reg first_bit_valid_encountered;

assign bit_valid_wide = (|bit_valid_delay);
assign bit_valid_last_wide = (|bit_valid_last_delay);

assign bit_upsample_valid = (bit_upsample_valid_internal & bit_valid_wide);
assign bit_upsample_valid_last = ((bit_upsample_count==0) & bit_valid_last_wide);

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    bit_valid_delay <= 0;
    bit_valid_last_delay <= 0;
    bit_upsample <= 0;
    bit_upsample_valid_internal <= 0;
    bit_upsample_count <= 0;

    first_bit_valid_encountered <= 0;
  end else begin
    bit_valid_delay[0]  <= bit_valid;
    bit_valid_delay[14:1]  <= bit_valid_delay[13:0];

    bit_valid_last_delay[0]  <= bit_valid_last;
    bit_valid_last_delay[14:1]  <= bit_valid_last_delay[13:0];

    if (bit_valid) begin
      bit_upsample <= phy_bit;
    end
    bit_upsample_valid_internal <= (~bit_upsample_valid_internal);

    first_bit_valid_encountered <= (bit_valid? 1 : first_bit_valid_encountered);
    if (first_bit_valid_encountered == 0) begin
      bit_upsample_count <= 1;
    end else begin
      bit_upsample_count <= (bit_upsample_valid_internal == 0? (bit_upsample_count + 1) : bit_upsample_count);
    end
  end
end

endmodule // bit_repeat_upsample
`endif 
