// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// Author: Harald Pretl (harald.pretl@jku.at)
// SPDX-FileCopyrightText: 2024 Harald Pretl
// SPDX-License-Identifier: Apache-2.0 license

`ifndef __GFSK_MODULATION__
`define __GFSK_MODULATION__
`include "btle_config.v"
`ifdef BTLE_TX_IQ
`include "vco.v"
`endif
`include "bit_repeat_upsample.v"
`include "gauss_filter.v"

module gfsk_modulation #
(
  parameter SAMPLE_PER_SYMBOL = 8,
`ifdef BTLE_TX_IQ
  parameter VCO_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1,
`endif
  parameter GAUSS_FILTER_BIT_WIDTH = 5, // [HP] change from 16 to 5
  parameter NUM_TAP_GAUSS_FILTER = 17
) (
  input wire clk,
  input wire rst,

  input wire [3:0] gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  input wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap_value,

`ifdef BTLE_TX_IQ 
  input  wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] cos_table_write_address,
  input  wire signed [(IQ_BIT_WIDTH-1) : 0] cos_table_write_data,
  input  wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] sin_table_write_address,
  input  wire signed [(IQ_BIT_WIDTH-1) : 0] sin_table_write_data,
`endif

`ifdef BTLE_TX_IQ
  output wire signed [(IQ_BIT_WIDTH-1) : 0] cos_out,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] sin_out,
  output wire sin_cos_out_valid,
  output wire sin_cos_out_valid_last, 
`endif

`ifdef BTLE_TX_POLAR
  output wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] fmod,
`endif

`ifdef BTLE_BAREMETAL
  // for debug purpose
  output bit_upsample,
  output bit_upsample_valid,
  output bit_upsample_valid_last,

  output [(GAUSS_FILTER_BIT_WIDTH-1) : 0] bit_upsample_gauss_filter,
  output bit_upsample_gauss_filter_valid,
`endif

  output bit_upsample_gauss_filter_valid_last,

  input wire phy_bit,
  input wire bit_valid,
  input wire bit_valid_last
);

`ifndef BTLE_BAREMETAL
wire bit_upsample;
wire bit_upsample_valid;
wire bit_upsample_valid_last;

/* verilator lint_off UNUSEDSIGNAL */
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] bit_upsample_gauss_filter;
/* verilator lint_on UNUSEDSIGNAL */

`ifndef BTLE_TX_IQ
/* verilator lint_off UNUSEDSIGNAL */
`endif
wire bit_upsample_gauss_filter_valid;
`ifndef BTLE_TX_IQ
/* verilator lint_on UNUSEDSIGNAL */
`endif
`endif

// always @ (posedge clk) begin
//   if (bit_upsample_gauss_filter_valid) begin
//     $display("%d", bit_upsample_gauss_filter);
//   end
// end

`ifdef BTLE_TX_POLAR
assign fmod = bit_upsample_gauss_filter; 
`endif

bit_repeat_upsample # (
  .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL)        
) bit_repeat_upsample_i (
  .clk(clk),
  .rst(rst),

  .phy_bit(phy_bit),
  .bit_valid(bit_valid),
  .bit_valid_last(bit_valid_last),

  .bit_upsample(bit_upsample),
  .bit_upsample_valid(bit_upsample_valid),
  .bit_upsample_valid_last(bit_upsample_valid_last)
);

gauss_filter # (
  .GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
  .NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER)
) gauss_filter_i (
  .clk(clk),
  .rst(rst),

  .tap_index(gauss_filter_tap_index),
  .tap_value(gauss_filter_tap_value),

  .bit_upsample(bit_upsample),
  .bit_upsample_valid(bit_upsample_valid),
  .bit_upsample_valid_last(bit_upsample_valid_last),

  .bit_upsample_gauss_filter(bit_upsample_gauss_filter),
  .bit_upsample_gauss_filter_valid(bit_upsample_gauss_filter_valid),
  .bit_upsample_gauss_filter_valid_last(bit_upsample_gauss_filter_valid_last)
);

`ifdef BTLE_TX_IQ
vco # (
  .VCO_BIT_WIDTH(VCO_BIT_WIDTH),
  .SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
  .IQ_BIT_WIDTH(IQ_BIT_WIDTH)
) vco_i (
  .clk(clk),
  .rst(rst),

  .cos_table_write_address(cos_table_write_address),
  .cos_table_write_data(cos_table_write_data),
  .sin_table_write_address(sin_table_write_address),
  .sin_table_write_data(sin_table_write_data),

  .voltage_signal({{GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT{1'b1}}, bit_upsample_gauss_filter[(GAUSS_FILTER_BIT_WIDTH-1) : GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT], {(VCO_BIT_WIDTH-GAUSS_FILTER_BIT_WIDTH){1'b0}}}),
  .voltage_signal_valid(bit_upsample_gauss_filter_valid),
  .voltage_signal_valid_last(bit_upsample_gauss_filter_valid_last),
  
  .cos_out(cos_out),
  .sin_out(sin_out),
  .sin_cos_out_valid(sin_cos_out_valid),
  .sin_cos_out_valid_last(sin_cos_out_valid_last)
);
`endif

endmodule // gfsk_modulation
`endif
