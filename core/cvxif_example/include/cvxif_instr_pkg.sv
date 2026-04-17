// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon (guillaume.chauvon@thalesgroup.com)



package cvxif_instr_pkg;

  typedef enum logic [3:0] {
    ILLEGAL = 4'b0000,
    NOP = 4'b0001,
    BUF_RADIX_C = 4'b0010,
    BUF_RADIX_R = 4'b0011,
    R4_PUSH_2IN = 4'b0100,
    //R4_PUSH_3CO = 4'b0101,
    R4_PUSH_MULT = 4'b0110,
    R4_PUSH_READ_1 = 4'b0111,
    R4_PUSH_READ_2 = 4'b1000,
    R4_PUSH_READ_3 = 4'b1001,
    R4_PUSH_READ_4 = 4'b1010
  } opcode_t;


  typedef struct packed {
    logic accept;
    logic writeback;  // TODO depends on dualwrite
    logic [2:0] register_read;  // TODO Nr read ports
  } issue_resp_t;

  typedef struct packed {
    logic        accept;
    logic [31:0] instr;
  } compressed_resp_t;

  typedef struct packed {
    logic [31:0] instr;
    logic [31:0] mask;
    issue_resp_t resp;
    opcode_t     opcode;
  } copro_issue_resp_t;


  typedef struct packed {
    logic [15:0]      instr;
    logic [15:0]      mask;
    compressed_resp_t resp;
  } copro_compressed_resp_t;

  // 4 Possible RISCV instructions for Coprocessor
  parameter int unsigned NbInstr = 9;
  parameter copro_issue_resp_t CoproInstr[NbInstr] = '{
      '{
          // Custom Nop
          instr:
          32'b00000_00_00000_00000_0_00_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b0, 1'b0, 1'b0}},
          opcode : NOP
      },
      /*'{
          // Custom Add : cus_add rd, rs1, rs2
          instr:
          32'b00000_00_00000_00000_0_01_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : ADD
      },
      '{
          // Custom Add : cus_add rd, rs1, rs2
          instr:
          32'b00000_00_00000_00000_0_10_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : BUF_PUSH
      },
      '{
          // Custom Add : cus_add rd, rs1, rs2
          instr:
          32'b00000_00_00000_00000_0_11_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : BUF_COMPUTE
      },
      '{
          // Custom Add : cus_add rd, rs1, rs2
          instr:
          32'b00000_00_00000_00000_1_00_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : BUF_READ
      },
      '{
          // Custom Add : cus_add rd, rs1, rs2
          instr:
          32'b00000_00_00000_00000_1_01_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b0}},
          opcode : BUF_STATUS
      },
      '{
          // Custom Add : cus_add rd, rs1, rs2
          instr:
          32'b00000_00_00000_00000_1_10_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : BUF_COMPUTE_2
      },*/
      '{
          instr:
          32'b00000_01_00000_00000_0_00_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : BUF_RADIX_C
      },
      '{
          instr:
          32'b00000_01_00000_00000_0_01_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b0}},
          opcode : BUF_RADIX_R
      },
      '{
          instr:
          32'b00000_10_00000_00000_0_00_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : R4_PUSH_2IN
      },
      /*'{
          instr:
          32'b00000_10_00000_00000_0_01_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b1, 1'b1, 1'b1}},
          opcode : R4_PUSH_3CO
      },*/
      '{
          instr:
          32'b00000_10_00000_00000_0_10_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b0, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : R4_PUSH_MULT
      },
      '{
          instr:
          32'b00000_10_00000_00000_0_11_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : R4_PUSH_READ_1
      },
      '{
          instr:
          32'b00000_10_00000_00000_1_00_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : R4_PUSH_READ_2
      },
      '{
          instr:
          32'b00000_10_00000_00000_1_01_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : R4_PUSH_READ_3
      },
      '{
          instr:
          32'b00000_10_00000_00000_1_10_00000_1111011,  // custom3 opcode
          mask: 32'b11111_11_00000_00000_1_11_00000_1111111,
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : R4_PUSH_READ_4
      }
      
  };

  parameter int unsigned NbCompInstr = 2;
  parameter copro_compressed_resp_t CoproCompInstr[NbCompInstr] = '{
      // C_NOP
      '{
          instr : 16'b111_0_00000_00000_00,
          mask : 16'b111_1_00000_00000_11,
          resp : '{accept : 1'b1, instr : 32'b00000_00_00000_00000_0_00_00000_1111011}
      },
      '{
          instr : 16'b111_1_00000_00000_00,
          mask : 16'b111_1_00000_00000_11,
          resp : '{accept : 1'b1, instr : 32'b00000_00_00000_00000_0_01_01010_1111011}
      }
  };

endpackage
