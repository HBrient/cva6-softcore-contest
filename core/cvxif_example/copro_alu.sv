// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon

module copro_alu
  import cvxif_instr_pkg::*;
#(
    parameter int unsigned NrRgprPorts = 2,
    parameter int unsigned XLEN = 32,
    parameter type hartid_t = logic,
    parameter type id_t = logic,
    parameter type registers_t = logic

) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  registers_t            registers_i,
    input  opcode_t               opcode_i,
    input  hartid_t               hartid_i,
    input  id_t                   id_i,
    input  logic       [     4:0] rd_i,
    output logic       [XLEN-1:0] result_o,
    output hartid_t               hartid_o,
    output id_t                   id_o,
    output logic       [     4:0] rd_o,
    output logic                  valid_o,
    output logic                  we_o,

    // Buffer interface
    /*output logic         buf_push_o,
    output logic signed [15:0]  buf_push_data_r_o,
    output logic signed [15:0]  buf_push_data_i_o,

    output logic         buf_read_o,
    output logic [15:0]  buf_read_index_o,
    output logic [15:0]  buf_write_index_o,
    input  logic signed [15:0]  buf_read_data_r_i,
    input  logic signed [15:0]  buf_read_data_i_i,
    input  logic         buf_busy_i,
    input  logic         buf_done_i,
    
    output logic         bulk_start_o,
    output logic [2:0]   bulk_op_o,

    output logic         elem_start_o,
    output logic [15:0]  elem_index_o,
    output logic signed [15:0]  elem_coeff_r_o,
    output logic signed [15:0]  elem_coeff_i_o,*/
    output logic                radix_cpt_o,
    output logic signed [31:0]  radix_rslt_o,
    input logic signed [31:0]   radix_rd_i,

    output logic                r4_push_3in_o,
    //output logic                r4_push_3co_o,
    output logic                r4_push_mult_o,
    output logic                r4_push_read_1_o,
    output logic                r4_push_read_2_o,
    output logic                r4_push_read_3_o,
    output logic                r4_push_read_4_o,

    output logic signed [63:0]  buf_push_data_o,
    output logic [1:0]          buf_read_index_o,
    input logic signed [15:0]   buf_read_data_r_i,
    input logic signed [15:0]   buf_read_data_i_i

);

  logic [XLEN-1:0] result_n, result_q;
  hartid_t hartid_n, hartid_q;
  id_t id_n, id_q;
  logic valid_n, valid_q;
  logic [4:0] rd_n, rd_q;
  logic we_n, we_q;

  assign result_o = result_q;
  assign hartid_o = hartid_q;
  assign id_o     = id_q;
  assign valid_o  = valid_q;
  assign rd_o     = rd_q;
  assign we_o     = we_q;

  always_comb begin
    /*buf_push_o        = 1'b0;
    buf_push_data_r_o   = '0;
    buf_push_data_i_o   = '0;
    bulk_start_o      = 1'b0;
    elem_start_o      = 1'b0;
    buf_read_o        = 1'b0;
    buf_read_index_o  = '0;
    buf_write_index_o  = '0;
    bulk_op_o         = '0;
    elem_index_o      = '0;
    elem_coeff_r_o      = '0;
    elem_coeff_i_o      = '0;*/
    radix_cpt_o         = 1'b0;
    radix_rslt_o        = '0;

    r4_push_3in_o       = 1'b0;
    //r4_push_3co_o       = 1'b0;
    r4_push_mult_o      = 1'b0;
    r4_push_read_1_o    = 1'b0;
    r4_push_read_2_o    = 1'b0;
    r4_push_read_3_o    = 1'b0;
    r4_push_read_4_o    = 1'b0;

    buf_push_data_o     = '0;
    buf_read_index_o    = '0;

    case (opcode_i)
      cvxif_instr_pkg::NOP: begin
        result_n = '0;
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = '0;
        we_n     = '0;
      end
      cvxif_instr_pkg::BUF_RADIX_C: begin
        radix_cpt_o = 1'b1;
        radix_rslt_o = {shortint'(round(registers_i[0][31:16])-round(registers_i[1][31:16])),shortint'(round(registers_i[0][15:0])-round(registers_i[1][15:0]))};
        result_n = {shortint'(round(registers_i[0][31:16])+round(registers_i[1][31:16])),shortint'(round(registers_i[0][15:0])+round(registers_i[1][15:0]))};
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::BUF_RADIX_R: begin
        result_n = radix_rd_i;
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::R4_PUSH_2IN: begin
        r4_push_3in_o = 1'b1;
        buf_push_data_o[31:0]  = registers_i[0];
        buf_push_data_o[63:32] = registers_i[1];
        //buf_push_data_o[95:64] = registers_i[2];
        result_n = '0;
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b0;
      end
      cvxif_instr_pkg::R4_PUSH_MULT: begin
        r4_push_mult_o = 1'b1;
        buf_push_data_o[31:0] = registers_i[0];
        buf_push_data_o[63:32] = registers_i[1];
        result_n = '0;
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b0;
      end
      cvxif_instr_pkg::R4_PUSH_READ_1: begin
        r4_push_read_1_o = 1'b1;
        buf_read_index_o = 2'b00;
        buf_push_data_o[31:0] = registers_i[0];
        result_n = {buf_read_data_r_i, buf_read_data_i_i};
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::R4_PUSH_READ_2: begin
        r4_push_read_2_o = 1'b1;
        buf_read_index_o = 2'b01;
        buf_push_data_o[31:0]  = registers_i[0];
        buf_push_data_o[63:32] = registers_i[1];
        result_n = {buf_read_data_r_i, buf_read_data_i_i};
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::R4_PUSH_READ_3: begin
        r4_push_read_3_o = 1'b1;
        buf_read_index_o = 2'b10;
        buf_push_data_o[31:0]  = registers_i[0];
        buf_push_data_o[63:32] = registers_i[1];
        result_n = {buf_read_data_r_i, buf_read_data_i_i};
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::R4_PUSH_READ_4: begin
        r4_push_read_4_o = 1'b1;
        buf_read_index_o = 2'b11;
        buf_push_data_o[31:0]  = registers_i[0];
        buf_push_data_o[63:32] = registers_i[1];
        result_n = {buf_read_data_r_i, buf_read_data_i_i};
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      default: begin
        result_n = '0;
        hartid_n = '0;
        id_n     = '0;
        valid_n  = '0;
        rd_n     = '0;
        we_n     = '0;
      end
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      result_q <= '0;
      hartid_q <= '0;
      id_q     <= '0;
      valid_q  <= '0;
      rd_q     <= '0;
      we_q     <= '0;
    end else begin
      result_q <= result_n;
      hartid_q <= hartid_n;
      id_q     <= id_n;
      valid_q  <= valid_n;
      rd_q     <= rd_n;
      we_q     <= we_n;
    end
  end

function automatic shortint round (input shortint a);
    begin
        round=shortint'(((signed'(a) << 14) - signed'(a) + (32'sd1 << 14)) >>> 15);
    end
endfunction

endmodule
