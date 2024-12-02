// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// Author: Harald Pretl (harald.pretl@jku.at)
// SPDX-FileCopyrightText: 2024 Harald Pretl
// SPDX-License-Identifier: Apache-2.0 license

`ifndef __SEARCH_UNIQUE_BIT_SEQUENCE__
`define __SEARCH_UNIQUE_BIT_SEQUENCE__
`include "btle_config.v"

module search_unique_bit_sequence #
(
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32
) (
  input wire clk,
  input wire rst,

  input wire phy_bit,
  input wire bit_valid,
  input wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] unique_bit_sequence,
  output wire hit_flag
);

reg bit_valid_delay1;
reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] bit_store;

assign hit_flag = (bit_store == unique_bit_sequence)&bit_valid_delay1;

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    bit_store <= 0;
    bit_valid_delay1 <= 0;
  end else begin
    bit_valid_delay1 <= bit_valid;
    if (bit_valid) begin
      bit_store[LEN_UNIQUE_BIT_SEQUENCE-1] <= phy_bit;
      bit_store[(LEN_UNIQUE_BIT_SEQUENCE-2) : 0] <= bit_store[(LEN_UNIQUE_BIT_SEQUENCE-1) : 1];
    end
  end
end

endmodule // search_unique_bit_sequence
`endif
