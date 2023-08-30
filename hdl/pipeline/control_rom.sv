module control_rom
import rv32i_types::*;
(
    input rv32i_opcode opcode,
    input [6:0] funct7,
    input [2:0] funct3,
    output rv32i_control_word ctrl
);

arith_funct3_t arith_funct3;
branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);

always_comb
begin
    /* Default assignments */
    ctrl.opcode = opcode;
    ctrl.store_funct3 = store_funct3;
    ctrl.aluop = alu_add;
    ctrl.regfile_load = '0;
    ctrl.WB_mux_out_sel = WB_mux::pc_plus4;
    ctrl.mem_read = '0;
    ctrl.mem_write = '0;
    ctrl.EX_alumux1_sel = EX_alumux::rs1_out;
    ctrl.EX_alumux2_sel = EX_alumux::rs2_out;
    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
    ctrl.cmpop = branch_funct3;
    /* ... other defaults ... */

    /* Assign control signals based on opcode */
    case (opcode)
        op_lui: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.EX_alumux1_sel = EX_alumux::zero;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
            // Write Back
            ctrl.regfile_load = 1'b1;
            ctrl.WB_mux_out_sel = WB_mux::alu_out;
        end
        op_auipc: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.EX_alumux1_sel = EX_alumux::pc_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
            // Write Back
            ctrl.regfile_load = 1'b1;
            ctrl.WB_mux_out_sel = WB_mux::alu_out;
        end
        op_jal: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.EX_alumux1_sel = EX_alumux::pc_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
            // Write Back
            ctrl.regfile_load = 1'b1;
            ctrl.WB_mux_out_sel = WB_mux::pc_plus4;
        end
        op_jalr: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.EX_alumux1_sel = EX_alumux::rs1_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
            // Write Back
            ctrl.regfile_load = 1'b1;
            ctrl.WB_mux_out_sel = WB_mux::pc_plus4;
        end
        op_br: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.cmpop = branch_funct3;
            ctrl.EX_alumux1_sel = EX_alumux::pc_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
        end
        op_load: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.EX_alumux1_sel = EX_alumux::rs1_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
            // Memory Access
            ctrl.mem_read = 1'b1;
            // Write Back
            ctrl.regfile_load = 1'b1;
            case (load_funct3)
                lw : ctrl.WB_mux_out_sel = WB_mux::lw;
                lb : ctrl.WB_mux_out_sel = WB_mux::lb;
                lbu : ctrl.WB_mux_out_sel = WB_mux::lbu;
                lh : ctrl.WB_mux_out_sel = WB_mux::lh;
                lhu : ctrl.WB_mux_out_sel = WB_mux::lhu;
            endcase
        end
        op_store: begin
            // Execute
            ctrl.aluop = alu_add;
            ctrl.EX_alumux1_sel = EX_alumux::rs1_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
            // Memory Access
            ctrl.mem_write = 1'b1;
        end
        op_imm: begin
            // Execute
            case (arith_funct3)
                add : begin
                    ctrl.aluop = alu_add;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                sll : begin
                    ctrl.aluop = alu_sll;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                slt : begin
                    ctrl.cmpop = blt;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::cmp_out;
                end
                sltu : begin
                    ctrl.cmpop = bltu;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::cmp_out;
                end
                axor : begin
                    ctrl.aluop = alu_xor;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                sr : begin
                    case (funct7[5])
                        1'b0 : ctrl.aluop = alu_srl;
                        1'b1 : ctrl.aluop = alu_sra;
                    endcase
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                aor : begin
                    ctrl.aluop = alu_or;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                aand : begin
                    ctrl.aluop = alu_and;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
            endcase
            ctrl.EX_alumux1_sel = EX_alumux::rs1_out;
            ctrl.EX_alumux2_sel = EX_alumux::immediate;
            // Write Back
            ctrl.regfile_load = 1'b1;
            ctrl.WB_mux_out_sel = WB_mux::alu_out;
        end
        op_reg: begin
            // Execute
            case (arith_funct3)
                add : begin
                    case (funct7[5])
                        1'b0 : ctrl.aluop = alu_add;
                        1'b1 : ctrl.aluop = alu_sub;
                    endcase
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                sll : begin
                    ctrl.aluop = alu_sll;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                slt : begin
                    ctrl.cmpop = blt;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::cmp_out;
                end
                sltu : begin
                    ctrl.cmpop = bltu;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::cmp_out;
                end
                axor : begin
                    ctrl.aluop = alu_xor;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                sr : begin
                    case (funct7[5])
                        1'b0 : ctrl.aluop = alu_srl;
                        1'b1 : ctrl.aluop = alu_sra;
                    endcase
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                aor : begin
                    ctrl.aluop = alu_or;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
                aand : begin
                    ctrl.aluop = alu_and;
                    ctrl.EX_alu_out_mux_sel = EX_alumux::alu_out;
                end
            endcase
            ctrl.EX_alumux1_sel = EX_alumux::rs1_out;
            ctrl.EX_alumux2_sel = EX_alumux::rs2_out;
            // Write Back
            ctrl.regfile_load = 1'b1;
            ctrl.WB_mux_out_sel = WB_mux::alu_out;
        end

        default: begin
            ctrl = '0;   /* Unknown opcode, set control word to zero */
        end
    endcase
end
endmodule : control_rom
