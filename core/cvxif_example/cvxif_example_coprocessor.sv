// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon

module cvxif_example_coprocessor
  import cvxif_instr_pkg::*;
#(
    // CVXIF Types
    parameter  int unsigned NrRgprPorts         = 2,
    parameter  int unsigned XLEN                = 32,
    parameter  type         readregflags_t      = logic,
    parameter  type         writeregflags_t     = logic,
    parameter  type         id_t                = logic,
    parameter  type         hartid_t            = logic,
    parameter  type         x_compressed_req_t  = logic,
    parameter  type         x_compressed_resp_t = logic,
    parameter  type         x_issue_req_t       = logic,
    parameter  type         x_issue_resp_t      = logic,
    parameter  type         x_register_t        = logic,
    parameter  type         x_commit_t          = logic,
    parameter  type         x_result_t          = logic,
    parameter  type         cvxif_req_t         = logic,
    parameter  type         cvxif_resp_t        = logic,
    localparam type         registers_t         = logic [NrRgprPorts-1:0][XLEN-1:0]
) (
    input  logic        clk_i,        // Clock
    input  logic        rst_ni,       // Asynchronous reset active low
    input  cvxif_req_t  cvxif_req_i,
    output cvxif_resp_t cvxif_resp_o
);

  // Compressed interface signals
  x_compressed_req_t  compressed_req;
  x_compressed_resp_t compressed_resp;
  logic compressed_valid, compressed_ready;
  // Issue interface signals
  x_issue_req_t  issue_req;
  x_issue_resp_t issue_resp;
  logic issue_valid, issue_ready;

  // Register interface signals
  x_register_t register;
  logic register_valid;

  // Decoder and alu signals
  registers_t registers;
  opcode_t opcode;
  hartid_t issue_hartid, hartid;
  id_t issue_id, id;
  logic [4:0] issue_rd, rd;
  logic [XLEN-1:0] result;
  logic            we;

  // Issue and Register interface
  // Mandatory when X_ISSUE_REGISTER_SPLIT = 0
  assign cvxif_resp_o.compressed_ready = compressed_ready;
  assign cvxif_resp_o.compressed_resp  = compressed_resp;
  assign cvxif_resp_o.issue_ready      = issue_ready;
  assign cvxif_resp_o.issue_resp       = issue_resp;
  assign cvxif_resp_o.register_ready   = cvxif_resp_o.issue_ready;

  assign compressed_req                = cvxif_req_i.compressed_req;
  assign compressed_valid              = cvxif_req_i.compressed_valid;
  assign issue_req                     = cvxif_req_i.issue_req;
  assign issue_valid                   = cvxif_req_i.issue_valid;
  assign register                      = cvxif_req_i.register;
  assign register_valid                = cvxif_req_i.register_valid;

  compressed_instr_decoder #(
      .copro_compressed_resp_t(cvxif_instr_pkg::copro_compressed_resp_t),
      .NbInstr(cvxif_instr_pkg::NbCompInstr),
      .CoproInstr(cvxif_instr_pkg::CoproCompInstr),
      .x_compressed_req_t(x_compressed_req_t),
      .x_compressed_resp_t(x_compressed_resp_t)
  ) compressed_instr_decoder_i (
      .clk_i             (clk_i),
      .rst_ni            (rst_ni),
      .compressed_valid_i(compressed_valid),
      .compressed_req_i  (compressed_req),
      .compressed_ready_o(compressed_ready),
      .compressed_resp_o (compressed_resp)
  );

  instr_decoder #(
      .copro_issue_resp_t (cvxif_instr_pkg::copro_issue_resp_t),
      .opcode_t (cvxif_instr_pkg::opcode_t),
      .NbInstr   (cvxif_instr_pkg::NbInstr),
      .CoproInstr(cvxif_instr_pkg::CoproInstr),
      .NrRgprPorts(NrRgprPorts),
      .hartid_t (hartid_t),
      .id_t (id_t),
      .x_issue_req_t (x_issue_req_t),
      .x_issue_resp_t (x_issue_resp_t),
      .x_register_t (x_register_t),
      .registers_t (registers_t)
  ) instr_decoder_i (
      .clk_i           (clk_i),
      .rst_ni          (rst_ni),
      .issue_valid_i   (issue_valid),
      .issue_req_i     (issue_req),
      .issue_ready_o   (issue_ready),
      .issue_resp_o    (issue_resp),
      .register_valid_i(register_valid),
      .register_i      (register),
      .registers_o     (registers),
      .opcode_o        (opcode),
      .hartid_o        (issue_hartid),
      .id_o            (issue_id),
      .rd_o            (issue_rd)
  );

  // Buffer definition
  parameter DATALEN = 16;
  logic signed [DATALEN-1:0] buffer_r [0:3];
  logic signed [DATALEN-1:0] buffer_i [0:3];
  logic signed [DATALEN-1:0] buffer_coeff_r [0:2];
  logic signed [DATALEN-1:0] buffer_coeff_i [0:2];
  /*logic [$clog2(BUF_DEPTH):0] buf_wr_ptr;
  logic [$clog2(BUF_DEPTH):0] buffer_index_coeff;
  logic buf_busy, buf_done;
  logic elem_busy;

  logic [2:0]  bulk_op;

  logic [DATALEN-1:0] elem_index;
  logic signed [DATALEN-1:0] elem_coeff_r;
  logic signed [DATALEN-1:0] elem_coeff_i;


  // ALU <-> Buffer wires
  logic        buf_push;
  logic signed [DATALEN-1:0] buf_push_data_r;
  logic signed [DATALEN-1:0] buf_push_data_i;

  logic        buf_read;
  logic [DATALEN-1:0] buf_read_index;
  logic [DATALEN-1:0] buf_write_index;
  logic signed [DATALEN-1:0] buf_read_data_r;
  logic signed [DATALEN-1:0] buf_read_data_i;
  logic        bulk_start;
  logic        elem_start;*/

  logic radix_cpt;
  logic signed [31:0] radix_rslt;
  logic signed [31:0] radix_mem;
  logic signed [31:0] radix_rd;
  
  logic r4_push_3in;
  //logic r4_push_3co;
  logic r4_push_mult;
  logic r4_push_read_1;
  logic r4_push_read_2;
  logic r4_push_read_3;
  logic r4_push_read_4;
  
  logic signed [63:0] buf_push_data;
  logic [1:0] buf_read_index;
  logic signed [DATALEN-1:0] buf_read_data_r;
  logic signed [DATALEN-1:0] buf_read_data_i;


  logic alu_valid;
  // Result interface
  copro_alu #(
      .NrRgprPorts(NrRgprPorts),
      .XLEN(XLEN),
      .hartid_t(hartid_t),
      .id_t(id_t),
      .registers_t(registers_t)
  ) i_copro_alu (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .registers_i(registers),
      .opcode_i   (opcode),
      .hartid_i   (issue_hartid),
      .id_i       (issue_id),
      .rd_i       (issue_rd),
      .hartid_o   (hartid),
      .id_o       (id),
      .result_o   (result),
      .valid_o    (alu_valid),
      .rd_o       (rd),
      .we_o       (we),
      /*.buf_push_o        (buf_push),
      .buf_push_data_r_o   (buf_push_data_r),
      .buf_push_data_i_o   (buf_push_data_i),

      .buf_read_o        (buf_read),
      .buf_read_index_o  (buf_read_index),
      .buf_write_index_o  (buf_write_index),
      .buf_read_data_r_i   (buf_read_data_r),
      .buf_read_data_i_i   (buf_read_data_i),
      .buf_busy_i        (buf_busy),
      .buf_done_i        (buf_done),
      .bulk_start_o      (bulk_start),
      .bulk_op_o         (bulk_op),
      .elem_start_o      (elem_start),
      .elem_index_o      (elem_index),
      .elem_coeff_r_o      (elem_coeff_r),
      .elem_coeff_i_o      (elem_coeff_i),*/
      .radix_cpt_o         (radix_cpt),
      .radix_rslt_o        (radix_rslt),
      .radix_rd_i          (radix_rd),

      .r4_push_3in_o       (r4_push_3in),
      //.r4_push_3co_o       (r4_push_3co),
      .r4_push_mult_o      (r4_push_mult),
      .r4_push_read_1_o    (r4_push_read_1),
      .r4_push_read_2_o    (r4_push_read_2),
      .r4_push_read_3_o    (r4_push_read_3),
      .r4_push_read_4_o    (r4_push_read_4),

      .buf_push_data_o     (buf_push_data),
      .buf_read_index_o    (buf_read_index),
      .buf_read_data_r_i   (buf_read_data_r),
      .buf_read_data_i_i   (buf_read_data_i)
  );

  // Buffer write
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      /*buf_wr_ptr <= 0;
      buf_busy <= 1'b0;
      elem_busy <= 1'b0;*/
      radix_mem <= '0;
      buffer_i <= '{default: 0};
      buffer_r <= '{default: 0};
      buffer_i <= '{default: 0};
      buffer_r <= '{default: 0};
      buffer_coeff_i <= '{default: 0};
      buffer_coeff_r <= '{default: 0};
    end else begin
      /*if (buf_push && !buf_busy && !elem_busy) begin
        buf_busy <= 1'b1;
        buffer_r[buf_wr_ptr] <= buf_push_data_r;
        buffer_i[buf_wr_ptr] <= buf_push_data_i;
        buf_wr_ptr <= (buf_wr_ptr == BUF_DEPTH-1) ? 0 : buf_wr_ptr + 1;*/
      if (issue_ready) begin
	      if (radix_cpt) begin
		radix_mem <= radix_rslt;
	      end else if (r4_push_3in) begin
		buffer_i[0] <= round4(buf_push_data[15:0]);
		buffer_r[0] <= round4(buf_push_data[31:16]);
		buffer_i[1] <= round4(buf_push_data[47:32]);
		buffer_r[1] <= round4(buf_push_data[63:48]);
	      /*end else if (r4_push_3co) begin
		buffer_coeff_i[0] <= round4(buf_push_data[15:0]);
		buffer_coeff_r[0] <= round4(buf_push_data[31:16]);
		buffer_coeff_i[1] <= round4(buf_push_data[47:32]);
		buffer_coeff_r[1] <= round4(buf_push_data[63:48]);
		buffer_coeff_i[2] <= round4(buf_push_data[79:64]);
		buffer_coeff_r[2] <= round4(buf_push_data[95:80]);*/
	      end else if (r4_push_mult) begin
		logic signed [DATALEN-1:0] t0_r, t1_r, t2_r, t3_r, t0_i, t1_i, t2_i, t3_i;
		        t0_r = buffer_r[0];
		        t1_r = buffer_r[1];
		        t2_r = round4(buf_push_data[31:16]);
		        t3_r = round4(buf_push_data[63:48]);
		        t0_i = buffer_i[0];
		        t1_i = buffer_i[1];
		        t2_i = round4(buf_push_data[15:0]);
		        t3_i = round4(buf_push_data[47:32]);
		
		        buffer_r[0]   <= t0_r + t1_r + t2_r + t3_r;
		        buffer_r[1]   <= t0_r + t1_i - t2_r - t3_i;
		        buffer_r[2]   <= t0_r - t1_r + t2_r - t3_r;
		        buffer_r[3]   <= t0_r - t1_i - t2_r + t3_i;
		        buffer_i[0]   <= t0_i + t1_i + t2_i + t3_i;
		        buffer_i[1]   <= t0_i - t1_r - t2_i + t3_r;
		        buffer_i[2]   <= t0_i - t1_i + t2_i - t3_i;
		        buffer_i[3]   <= t0_i + t1_r - t2_i - t3_r;
	      end else if (r4_push_read_1) begin
		logic signed [DATALEN-1:0] t0_r, t1_r, t2_r, t3_r, t0_i, t1_i, t2_i, t3_i;
		        t0_r = round4(buf_push_data[31:16]);;
		        t1_r = q15_mul_r(buffer_r[1], buffer_i[1], buffer_coeff_r[0], buffer_coeff_i[0]);
		        t2_r = q15_mul_r(buffer_r[2], buffer_i[2], buffer_coeff_r[1], buffer_coeff_i[1]);
		        t3_r = q15_mul_r(buffer_r[3], buffer_i[3], buffer_coeff_r[2], buffer_coeff_i[2]);
		        t0_i = round4(buf_push_data[15:0]);;
		        t1_i = q15_mul_i(buffer_r[1], buffer_i[1], buffer_coeff_r[0], buffer_coeff_i[0]);
		        t2_i = q15_mul_i(buffer_r[2], buffer_i[2], buffer_coeff_r[1], buffer_coeff_i[1]);
		        t3_i = q15_mul_i(buffer_r[3], buffer_i[3], buffer_coeff_r[2], buffer_coeff_i[2]);
		
		        buffer_r[0]   <= t0_r + t1_r + t2_r + t3_r;
		        buffer_r[1]   <= t0_r + t1_i - t2_r - t3_i;
		        buffer_r[2]   <= t0_r - t1_r + t2_r - t3_r;
		        buffer_r[3]   <= t0_r - t1_i - t2_r + t3_i;
		        buffer_i[0]   <= t0_i + t1_i + t2_i + t3_i;
		        buffer_i[1]   <= t0_i - t1_r - t2_i + t3_r;
		        buffer_i[2]   <= t0_i - t1_i + t2_i - t3_i;
		        buffer_i[3]   <= t0_i + t1_r - t2_i - t3_r;
	      end else if (r4_push_read_2) begin
		buffer_i[1]       <= round4(buf_push_data[15:0]);
		buffer_r[1]       <= round4(buf_push_data[31:16]);
		buffer_coeff_i[0] <= buf_push_data[47:32];
		buffer_coeff_r[0] <= buf_push_data[63:48];
	      end else if (r4_push_read_3) begin
		buffer_i[2]       <= round4(buf_push_data[15:0]);
		buffer_r[2]       <= round4(buf_push_data[31:16]);
		buffer_coeff_i[1] <= buf_push_data[47:32];
		buffer_coeff_r[1] <= buf_push_data[63:48];
	      end else if (r4_push_read_4) begin
		buffer_i[3]       <= round4(buf_push_data[15:0]);
		buffer_r[3]       <= round4(buf_push_data[31:16]);
		buffer_coeff_i[2] <= buf_push_data[47:32];
		buffer_coeff_r[2] <= buf_push_data[63:48];
	      end
      end  	
    end
  end


  // Buffer read
  assign buf_read_data_r = buffer_r[buf_read_index];
  assign buf_read_data_i = buffer_i[buf_read_index];
  assign radix_rd = radix_mem;

  // Status reporting
  // assign buf_done = ~buf_busy;


  always_comb begin
    cvxif_resp_o.result_valid  = alu_valid;  //TODO Should wait for ready from CPU
    cvxif_resp_o.result.hartid = hartid;
    cvxif_resp_o.result.id     = id;
    cvxif_resp_o.result.data   = result;
    cvxif_resp_o.result.rd     = rd;
    cvxif_resp_o.result.we     = we;
  end

  function automatic shortint q15_mul_r (
    input shortint a,
    input shortint b,
    input shortint c,
    input shortint d
);
    // 32-bit signed intermediate
    integer prod;
    integer rounded;

    begin
        // Multiply (Q1.15 × Q1.15 = Q2.30)
        prod = a * c - b * d;

        // Rounding: add/subtract 0.5 LSB before shifting
        rounded = (prod + (1 << 14)) >>> 15;

        // Saturation to valid range
        if (rounded > 32767)
            q15_mul_r = 32767;
        else if (rounded < -32767)
            q15_mul_r = -32767;
        else
            q15_mul_r = shortint'(rounded);
    end
endfunction

  function automatic shortint q15_mul_i (
    input shortint a,
    input shortint b,
    input shortint c,
    input shortint d
);
    // 32-bit signed intermediate
    integer prod;
    integer rounded;

    begin
        // Multiply (Q1.15 × Q1.15 = Q2.30)
        prod = a * d + b * c;

        // Rounding: add/subtract 0.5 LSB before shifting
        rounded = (prod + (1 << 14)) >>> 15;
        
        // Saturation to valid range
        if (rounded > 32767)
            q15_mul_i = 32767;
        else if (rounded < -32767)
            q15_mul_i = -32767;
        else
            q15_mul_i = shortint'(rounded);
    end
endfunction

function automatic shortint round4 (input shortint a);
    begin
        round4=shortint'(((signed'(a) << 13) - signed'(a) + (32'sd1 << 14)) >>> 15);
    end
endfunction

  

  



endmodule
