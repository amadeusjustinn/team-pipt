`define BAD_MUX_SEL $display("Illegal mux select")


module datapath
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_pc,
    input load_mar,
    input load_mdr,
    input load_ir,
    input load_regfile,
    input load_data_out,
    input pcmux::pcmux_sel_t pcmux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input rv32i_word mem_rdata,
    input alu_ops aluop,
    input branch_funct3_t cmpop,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    output rv32i_word mem_address,
    output [2:0] funct3,
    output [6:0] funct7,
    output rv32i_opcode opcode,
    output rv32i_reg rs1,
    output rv32i_reg rs2,
    output logic br_en,
	output [1:0] mem_address_shift
    /* You will need to connect more signals to your datapath module*/
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word marmux_out;
rv32i_word mdrreg_out;
rv32i_word regfilemux_out;
rv32i_word i_imm, s_imm, b_imm, u_imm, j_imm;
rv32i_reg rd;
rv32i_word rs1_out, rs2_out;
rv32i_word alumux1_out, alumux2_out;
rv32i_word alu_out;
rv32i_word cmp_mux_out;
rv32i_word mar_out;
logic [31:0] mdrreg_out_byte;
logic [31:0] mdrreg_out_half; 
rv32i_word mem_wdata_shift;
assign mdrreg_out_byte = {(mdrreg_out >> (8*(mar_out[1:0])))};
assign mdrreg_out_half = {(mdrreg_out >> (8*(mar_out[1:0])))};
assign mem_address = {mar_out[31:2], 2'b0};
assign mem_address_shift = mar_out[1:0];
assign mem_wdata = mem_wdata_shift << (8*(mar_out[1:0]));
/*****************************************************************************/

/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk    (clk),
    .rst    (rst),
    .load   (load_ir),
    .in     (mdrreg_out),
    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .i_imm  (i_imm),
    .s_imm  (s_imm),
    .b_imm  (b_imm),
    .u_imm  (u_imm),
    .j_imm  (j_imm),
    .rs1    (rs1),
    .rs2    (rs2),
    .rd     (rd)
);

register MDR(
    .clk  (clk),
    .rst  (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .clk  (clk),
    .rst  (rst),
    .load (load_mar),
    .in   (marmux_out),
    .out  (mar_out)
);

pc_register PC(
    .clk  (clk),
    .rst  (rst),
    .load (load_pc),
    .in   (pcmux_out),
    .out  (pc_out)
);

regfile regfile(
    .clk   (clk),
    .rst   (rst),
    .load  (load_regfile),
    .in    (regfilemux_out),
    .src_a (rs1),
    .src_b (rs2),
    .dest  (rd),
    .reg_a (rs1_out),
    .reg_b (rs2_out)
);

register mem_data_out(
    .clk  (clk),
    .rst  (rst),
    .load (load_data_out),
    .in   (rs2_out),
    .out  (mem_wdata_shift)
);
/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu alu(
    .aluop (aluop),
    .a     (alumux1_out),
    .b     (alumux2_out),
    .f     (alu_out)
);

cmp CMP(
    .cmpop (cmpop),
    .a     (rs1_out),
    .b     (cmp_mux_out),
    .br_en (br_en)
);
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    unique case (pcmux_sel)
        pcmux::pc_plus4 : pcmux_out = pc_out + 4;
        pcmux::alu_out : pcmux_out = alu_out;
        pcmux::alu_mod2 : pcmux_out = {alu_out[31:1], 1'b0};
        // etc.
        default: `BAD_MUX_SEL;
    endcase

    unique case (marmux_sel)
        marmux::pc_out : marmux_out = pc_out;
        marmux::alu_out : marmux_out = alu_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (regfilemux_sel)
        regfilemux::alu_out : regfilemux_out = alu_out;
        regfilemux::br_en : regfilemux_out = {31'd0, br_en};
        regfilemux::u_imm : regfilemux_out = u_imm;
        regfilemux::lw : regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4 : regfilemux_out = pc_out + 4;
        regfilemux::lb : regfilemux_out = {{24{mdrreg_out_byte[7]}}, mdrreg_out_byte[7:0]};
        regfilemux::lbu : regfilemux_out = {24'h000000, mdrreg_out_byte[7:0]};
        regfilemux::lh : regfilemux_out = {{16{mdrreg_out_half[15]}}, mdrreg_out_half[15:0]};
        regfilemux::lhu : regfilemux_out = {16'h0000, mdrreg_out_half[15:0]};
        default: `BAD_MUX_SEL;
    endcase

    unique case (alumux1_sel)
        alumux::rs1_out : alumux1_out = rs1_out;
        alumux::pc_out : alumux1_out = pc_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (alumux2_sel)
        alumux::i_imm : alumux2_out = i_imm;
        alumux::u_imm : alumux2_out = u_imm;
        alumux::b_imm : alumux2_out = b_imm;
        alumux::s_imm : alumux2_out = s_imm;
        alumux::j_imm : alumux2_out = j_imm;
        alumux::rs2_out : alumux2_out = rs2_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (cmpmux_sel)
        cmpmux::rs2_out : cmp_mux_out = rs2_out;
        cmpmux::i_imm : cmp_mux_out = i_imm;
    endcase
end
/*****************************************************************************/
endmodule : datapath
