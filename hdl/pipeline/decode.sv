module decode
import rv32i_types::*;
(
    input clk,
    input rst,
    input rv32i_word IF_instr_data,
    input rv32i_word IF_pc,
    input logic WB_regfile_load,
    input rv32i_word WB_regfile_data,
    input logic [4:0] WB_regfile_rd,
    input logic stall_fetch, stall_decode,
    input logic mispredict,
    input rv32i_word IF_pc_rdata,
    output rv32i_instr_word instr_word,
    output rv32i_word rs1_data, rs2_data,
    output rv32i_word ID_pc_rdata
);

logic [2:0] funct3;
logic [6:0] funct7;
rv32i_opcode opcode;
rv32i_word immediate;
rv32i_word ID_instr_data;
rv32i_word ID_pc;
logic ID_regfile_load;
rv32i_word ID_regfile_data;
logic [4:0] ID_regfile_rd;
rv32i_word i_imm, s_imm, b_imm, u_imm, j_imm;
rv32i_reg rd, rs1, rs2;
rv32i_control_word ctrl;
rv32i_instr_word cur_instr_word;
logic mispredict_stall;

always_comb 
begin
    if (mispredict || mispredict_stall)
    begin
        instr_word = '0;
    end
    else
    begin
        instr_word = cur_instr_word;
    end
end

always_ff @(posedge clk)
begin
    if (rst)
    begin
        ID_instr_data <= '0;
        ID_pc <= '0;
	ID_pc_rdata <= '0;
	mispredict_stall <= '0;
    end
    else if (stall_fetch && !stall_decode)
    begin
        ID_instr_data <= '0;
        ID_pc <= '0;
	ID_pc_rdata <= '0;
	mispredict_stall <= '0;
    end
    else if (stall_fetch && stall_decode)
    begin
        ID_instr_data <= ID_instr_data;
        ID_pc <= ID_pc;
	ID_pc_rdata <= ID_pc_rdata;
	if (mispredict) begin
		mispredict_stall <= 1'b1;
	end else begin
		mispredict_stall <= mispredict_stall;
	end
    end
    else
    begin
	ID_instr_data <= IF_instr_data;
        ID_pc <= IF_pc;
	ID_pc_rdata <= IF_pc_rdata;
	mispredict_stall <= '0;
    end
end

ir_comb ir (
    .in         (ID_instr_data),
    .funct3     (funct3),
    .funct7     (funct7),
    .opcode     (opcode),
    .i_imm      (i_imm),
    .s_imm      (s_imm),
    .b_imm      (b_imm),
    .u_imm      (u_imm),
    .j_imm      (j_imm),
    .rs1        (rs1),
    .rs2        (rs2),
    .rd         (rd) 
);

control_rom control_rom (
    .opcode     (opcode),
    .funct7     (funct7),
    .funct3     (funct3),
    .ctrl       (ctrl)
);

regfile_trans regfile_trans (
    .clk        (clk),
    .rst        (rst),
    .load       (WB_regfile_load),
    .in         (WB_regfile_data),
    .src_a      (rs1),
    .src_b      (rs2),
    .dest       (WB_regfile_rd),
    .reg_a      (rs1_data),
    .reg_b      (rs2_data)
);

instr_rom instr_rom (
    .ctrl       (ctrl),
    .immediate  (immediate),
    .rs1        (rs1),
    .rs2        (rs2),
    .rd         (rd),
    .pc         (ID_pc),
	.instr_word (cur_instr_word),
	.instr_data (ID_instr_data)
);

always_comb begin : MUXES
    unique case (opcode)
        op_load : immediate = i_imm;
        op_store : immediate = s_imm;
        op_lui : immediate = u_imm;
        op_auipc : immediate = u_imm;
        op_imm : immediate = i_imm;
        op_reg : immediate = 32'd0;
        op_br : immediate = b_imm;
        op_jal : immediate = j_imm;
        op_jalr : immediate = i_imm;
		default: immediate = '0;
    endcase
end
endmodule : decode
