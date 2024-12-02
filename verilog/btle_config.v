// Author: Harald Pretl (harald.pretl@jku.at)
// SPDX-FileCopyrightText: 2024 Harald Pretl
// SPDX-License-Identifier: Apache-2.0 license

`ifndef __BTLE_CONFIG__
`define __BTLE_CONFIG__
`timescale 1ns / 1ps
// BTLE configurations
// if TX_IQ is defined then an IQ TX interface is generated
//`define BTLE_TX_IQ
// if TX_POLAR is defined then a polar TX interface is generated
`define BTLE_TX_POLAR
`endif
