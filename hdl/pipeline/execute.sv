// bin/rv_load_memory.sh testcode/mp4-cp1.s
// make sim/simv ASM=testcode/mp4-cp1.s

module execute
import rv32i_types::*;
(
    input clk, 
    input rst,
    input rv32i_instr_word ID_instr_word,
    input rv32i_word ID_rs1_data, ID_rs2_data,
    input logic [4:0] Mem_rd_forwarding, WB_rd_forwarding,
    input rv32i_word Mem_rd_data, WB_rd_data,
    input logic Mem_regfile_load, WB_regfile_load,
    input logic stall_execute,
    input rv32i_word ID_pc_rdata,
    output rv32i_word EX_alu_out,
    output logic [4:0] EX_rd_forwarding,
    output pcmux_mp4::pcmux_mp4_sel_t EX_pcmux_mp4_sel,
    output rv32i_instr_word EX_instr_word,
    output rv32i_word EX_rs1_data_fwd, EX_rs2_data_fwd,
    output rv32i_word EX_pc_rdata, EX_pc_wdata,
    output rv32i_word EX_pc, EX_target_pc
);

rv32i_opcode opcode;
logic [31:0] alu_mux_1_out;
logic [31:0] alu_mux_2_out;
logic [31:0] fwdA_mux_out;
logic [31:0] fwdB_mux_out;

rv32i_word pc;
rv32i_word immediate;
logic br_en; 
logic alu_br_en;
logic [1:0] forwardA;
logic [1:0] forwardB;

logic [4:0] EX_Mem_rd_forwarding;
logic [4:0] EX_WB_rd_forwarding;
logic [31:0] alu_sel_in;

EX_alumux::EX_forwardA_sel_t EX_forwardA_sel;
EX_alumux::EX_forwardB_sel_t EX_forwardB_sel;

assign EX_Mem_rd_forwarding = Mem_rd_forwarding;
assign EX_WB_rd_forwarding = WB_rd_forwarding;

rv32i_word EX_rs1_data, EX_rs2_data;

assign EX_rs1_data_fwd = fwdA_mux_out;
assign EX_rs2_data_fwd = fwdB_mux_out;

always_ff @(posedge clk)
begin
    if (rst) begin
        EX_instr_word <= '0;
        EX_rs1_data <= '0;
        EX_rs2_data <= '0;
	EX_pc_rdata <= '0;
    end
    else if (stall_execute)
    begin
        // For a stall, set EX_rs1_data to forwarded value otherwise if stalled execute and there is a forward from WB, it won't save the updated value; do the same for mem_access forwarding
        EX_instr_word <= EX_instr_word;
        if (EX_forwardA_sel == EX_alumux::wb_rd_fwdA || EX_forwardA_sel == EX_alumux::mem_rd_fwdA) begin
            EX_rs1_data <= fwdA_mux_out;
        end else begin
            EX_rs1_data <= EX_rs1_data;
        end

        if (EX_forwardB_sel == EX_alumux::wb_rd_fwdB || EX_forwardB_sel == EX_alumux::mem_rd_fwdB) begin
            EX_rs2_data <= fwdB_mux_out;
        end else begin
            EX_rs2_data <= EX_rs2_data;
        end
	EX_pc_rdata <= EX_pc_rdata;
    end
    else
    begin
	EX_instr_word <= ID_instr_word;
        EX_rs1_data <= ID_rs1_data;
        EX_rs2_data <= ID_rs2_data;
	EX_pc_rdata <= ID_pc_rdata;
    end
end

alu alu(
    .aluop(EX_instr_word.ctrl.aluop),
    .a(alu_mux_1_out),
    .b(alu_mux_2_out),
    .f(alu_sel_in)
);

cmp alu_cmp(
    .cmpop      (EX_instr_word.ctrl.cmpop),
    .a          (alu_mux_1_out),
    .b          (alu_mux_2_out),
    .br_en      (alu_br_en)
);

cmp branch_cmp (
    .cmpop     (EX_instr_word.ctrl.cmpop),
    .a         (fwdA_mux_out),
    .b         (fwdB_mux_out),
    .br_en     (br_en)
);

assign EX_pc = pc;

assign opcode = EX_instr_word.ctrl.opcode;
assign pc = EX_instr_word.pc;
assign immediate = EX_instr_word.immediate;
assign EX_pcmux_mp4_sel = (((br_en == 1'b1) && (opcode == op_br)) || (opcode == op_jal)) ? pcmux_mp4::branch_jal : (opcode == op_jalr ? pcmux_mp4::jalr : pcmux_mp4::pc_plus4);
assign EX_rd_forwarding = EX_instr_word.rd;

logic [2:0] flag;
assign alu_mux_1_out = (EX_instr_word.ctrl.EX_alumux1_sel == EX_alumux::rs1_out) ? fwdA_mux_out : (EX_instr_word.ctrl.EX_alumux1_sel == EX_alumux::pc_out) ? pc : '0;
assign alu_mux_2_out = (EX_instr_word.ctrl.EX_alumux2_sel == EX_alumux::rs2_out) ? fwdB_mux_out : immediate;
always_comb begin : MUXES
    // ALU1 & ALU2 mux
/*
    unique case (EX_instr_word.ctrl.EX_alumux1_sel)
        EX_alumux::rs1_out : begin
		alu_mux_1_out = fwdA_mux_out;
		flag = 3'b111;
	end
        EX_alumux::pc_out : begin
		alu_mux_1_out = pc;
		flag = 3'b1;
	end
        EX_alumux::zero : begin
		alu_mux_1_out = '0;
		flag = 3'b10;
	end
	default: alu_mux_1_out = fwdA_mux_out;
    endcase
*/
/*
    unique case (EX_instr_word.ctrl.EX_alumux2_sel)
        EX_alumux::rs2_out : alu_mux_2_out = fwdB_mux_out;
        EX_alumux::immediate : alu_mux_2_out = immediate;
	default: alu_mux_2_out = fwdB_mux_out;
    endcase
   */
    // ALU out sel mux
    unique case (EX_instr_word.ctrl.EX_alu_out_mux_sel)
        EX_alumux::alu_out : EX_alu_out = alu_sel_in;
        EX_alumux::cmp_out : EX_alu_out = {31'd0, alu_br_en};
	default: EX_alu_out = alu_sel_in;
    endcase
    // 3 Input muxes feeding into ALU
    unique case (EX_forwardA_sel)
        EX_alumux::alu_mux_1  : fwdA_mux_out = EX_rs1_data;
        EX_alumux::mem_rd_fwdA : fwdA_mux_out = Mem_rd_data;
        EX_alumux::wb_rd_fwdA  : fwdA_mux_out = WB_rd_data;
        default : fwdA_mux_out = alu_mux_1_out;
    endcase

    unique case (EX_forwardB_sel)
        EX_alumux::alu_mux_2  : fwdB_mux_out = EX_rs2_data;
        EX_alumux::mem_rd_fwdB : fwdB_mux_out = Mem_rd_data;
        EX_alumux::wb_rd_fwdB  : fwdB_mux_out = WB_rd_data;
        default : fwdB_mux_out = alu_mux_2_out;
    endcase
end

always_comb begin : FWD_UNIT
    // Uses both registers
        if (EX_instr_word.rs1 == 5'b0) begin
            EX_forwardA_sel = EX_alumux::alu_mux_1;
        end else if ((WB_regfile_load == 1'b1 && EX_WB_rd_forwarding == EX_instr_word.rs1) && (Mem_regfile_load == 1'b1 && EX_Mem_rd_forwarding == EX_instr_word.rs1)) begin
            EX_forwardA_sel = EX_alumux::mem_rd_fwdA;
        end
        else if (WB_regfile_load == 1'b1 && EX_WB_rd_forwarding == EX_instr_word.rs1) begin
            EX_forwardA_sel = EX_alumux::wb_rd_fwdA;
        end
        else if (Mem_regfile_load == 1'b1 && EX_Mem_rd_forwarding == EX_instr_word.rs1) begin
            EX_forwardA_sel = EX_alumux::mem_rd_fwdA;
        end
        else begin
            EX_forwardA_sel = EX_alumux::alu_mux_1;
        end
        if (EX_instr_word.rs2 == 5'b0) begin
            EX_forwardB_sel = EX_alumux::alu_mux_2;
        end else if ((WB_regfile_load == 1'b1 && EX_WB_rd_forwarding == EX_instr_word.rs2) && (Mem_regfile_load == 1'b1 && EX_Mem_rd_forwarding == EX_instr_word.rs2)) begin
            EX_forwardB_sel = EX_alumux::mem_rd_fwdB;
        end
        else if (WB_regfile_load == 1'b1 && EX_WB_rd_forwarding == EX_instr_word.rs2) begin
            EX_forwardB_sel = EX_alumux::wb_rd_fwdB;
        end
        else if (Mem_regfile_load == 1'b1 && EX_Mem_rd_forwarding == EX_instr_word.rs2) begin
            EX_forwardB_sel = EX_alumux::mem_rd_fwdB;
        end
        else begin
            EX_forwardB_sel = EX_alumux::alu_mux_2;
        end
end

always_comb begin : pc_wdata_mux
    unique case (EX_pcmux_mp4_sel)
        pcmux_mp4::pc_plus4 : begin 
		EX_pc_wdata = EX_instr_word.pc + 4;
	end
        pcmux_mp4::branch_jal : begin 
		EX_pc_wdata = EX_alu_out;
	end
        pcmux_mp4::jalr : begin 
		EX_pc_wdata = {EX_alu_out[31:1], 1'b0};
	end
        // etc.
        default: EX_pc_wdata = EX_instr_word.pc + 4;
    endcase
end

always_comb begin
    unique case (EX_pcmux_mp4_sel)
        pcmux_mp4::pc_plus4 : begin 
		    EX_target_pc = EX_pc + 4;
	    end
        pcmux_mp4::branch_jal : begin 
		    EX_target_pc = EX_alu_out;
	    end
        pcmux_mp4::jalr : begin 
		    EX_target_pc = {EX_alu_out[31:1], 1'b0};
	    end
        default: $display("Bad PC MUX select in prediction unit");
    endcase
end

endmodule : execute
