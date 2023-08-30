// Mp4 ----------------------------------
package pcmux_mp4;
typedef enum bit [1:0] {
    pc_plus4     = 2'b00
    ,branch_jal  = 2'b01
    ,jalr        = 2'b10
} pcmux_mp4_sel_t;
endpackage

package WB_mux;
typedef enum bit [2:0] {
    lw        = 3'b000
    ,lb       = 3'b001
    ,lbu      = 3'b010
    ,lh       = 3'b011
    ,lhu      = 3'b100
    ,pc_plus4 = 3'b101
    ,alu_out  = 3'b110
} WB_mux_out_sel_t;
endpackage

package EX_alumux;
typedef enum bit [1:0] {
    rs1_out = 2'b00
    ,pc_out = 2'b01
    ,zero   = 2'b10
} EX_alumux1_sel_t;

typedef enum bit {
    immediate = 1'b0
    ,rs2_out  = 1'b1
} EX_alumux2_sel_t;

typedef enum bit {
    alu_out = 1'b0
    ,cmp_out = 1'b1
} EX_alu_out_mux_sel_t;

typedef enum bit [1:0] {
    rs1 = 2'b00
    ,mem_rd_fwdA_br = 2'b01
    ,wb_rd_fwdA_br = 2'b10
} EX_forwardA_br_sel_t;

typedef enum bit [1:0] {
    rs2 = 2'b00
    ,mem_rd_fwdB_br = 2'b01
    ,wb_rd_fwdB_br = 2'b10
} EX_forwardB_br_sel_t;

typedef enum bit [1:0] {
    alu_mux_1 = 2'b00
    ,mem_rd_fwdA = 2'b01
    ,wb_rd_fwdA = 2'b10
} EX_forwardA_sel_t;

typedef enum bit [1:0] {
    alu_mux_2 = 2'b00
    ,mem_rd_fwdB = 2'b01
    ,wb_rd_fwdB = 2'b10
} EX_forwardB_sel_t;

endpackage

package MEM_mux;
typedef enum bit {
    rs2_out = 1'b0
    ,wb_rd_fwd = 1'b1
} MEM_mux_out_sel_t;
typedef enum bit {
    mem_rdata = 1'b0
    ,alu_out = 1'b1
} MEM_forward_on_load_sel_t;
endpackage

// Mp4 ----------------------------------

package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,alu_mod2 = 2'b10
} pcmux_sel_t;
endpackage

package marmux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage

