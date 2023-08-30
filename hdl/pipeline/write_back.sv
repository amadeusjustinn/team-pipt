`define BAD_MUX_SEL $display("Illegal mux select")

module write_back
import rv32i_types::*;
(
    input clk,
    input rst,
    input rv32i_instr_word MEM_instr_word,
    input rv32i_word MEM_alu_out, Mem_rdata, Mem_rdata_load,
    input logic stall_mem,
    input rv32i_word MEM_rs1_data, MEM_rs2_data,
    input logic[31:0] MEM_mem_address, MEM_Mem_rdata, MEM_Mem_wdata,
    input rv32i_word MEM_pc_rdata, MEM_pc_wdata,
    input logic [3:0] mem_wmask,
    input logic MEM_mispredict,
    output logic WB_regfile_load,
    output rv32i_word WB_regfile_data, 
    output logic [4:0] WB_regfile_rd 
); 
 
rv32i_instr_word WB_instr_word;
rv32i_word WB_alu_out, WB_rdata;
//Monitor
rv32i_word WB_rs1_data, WB_rs2_data;
logic[31:0] WB_mem_address, WB_Mem_rdata, WB_Mem_wdata, WB_Mem_rdata_load;
rv32i_word WB_pc_rdata, WB_pc_wdata;
logic [3:0] WB_wmask;
logic WB_mispredict; 
 
always_ff @(posedge clk)
begin
    if (rst) begin
        WB_instr_word <= '0;
        WB_alu_out <= '0;
        WB_rdata <= '0;
        WB_rs1_data <= '0;
        WB_rs2_data <= '0;
        WB_mem_address <= '0;
	WB_Mem_rdata <= '0;
	WB_Mem_wdata <= '0;
	WB_pc_rdata <= '0;
	WB_pc_wdata <= '0;
	WB_wmask <= '0;
	WB_mispredict <= '0;
	WB_Mem_rdata_load <= '0;
    end else begin
        if (stall_mem) begin
            WB_instr_word <= '0;
	    WB_pc_rdata <= '0;
	    WB_pc_wdata <= '0;
	    WB_wmask <= '0;
	    WB_alu_out <= '0;
            WB_rdata <= '0;
            WB_rs1_data <= '0;
            WB_rs2_data <= '0;
	    WB_mem_address <= '0;
	    WB_Mem_rdata <= '0;
	    WB_Mem_wdata <= '0;
	    WB_mispredict <= '0; 
	    WB_Mem_rdata_load <= '0;
        end else begin
            WB_instr_word <= MEM_instr_word;
	    WB_pc_rdata <= MEM_pc_rdata;
	    WB_pc_wdata <= MEM_pc_wdata;
  	    WB_wmask <= mem_wmask;
	    WB_alu_out <= MEM_alu_out;
            WB_rdata <= Mem_rdata;
            WB_rs1_data <= MEM_rs1_data;
            WB_rs2_data <= MEM_rs2_data;
	    WB_mem_address <= MEM_mem_address;
	    WB_Mem_rdata <= MEM_Mem_rdata;
	    WB_Mem_wdata <= MEM_Mem_wdata;
	    WB_mispredict <= MEM_mispredict;
	    WB_Mem_rdata_load <= Mem_rdata_load;
        end
    end
end

assign WB_regfile_load = WB_instr_word.ctrl.regfile_load;
assign WB_regfile_rd = WB_instr_word.rd;
//logic [31:0] WB_rdata_byte;
//logic [31:0] WB_rdata_half; 
//assign WB_rdata_byte = {(WB_rdata >> (8*(WB_alu_out[1:0])))};
//assign WB_rdata_half = {(WB_rdata >> (8*(WB_alu_out[1:0])))};

logic finish;
logic WB_commit;
assign WB_commit = WB_regfile_load;
always_comb begin
	if ((WB_instr_word.ctrl.opcode == op_br || WB_instr_word.ctrl.opcode == op_jal || WB_instr_word.ctrl.opcode == op_jalr) && WB_alu_out == WB_instr_word.pc) begin
		finish = 1'b1;
	end else begin
		finish = 1'b0;
	end 
end

logic [3:0] WB_rmask;

always_comb begin : MUXES
    unique case (WB_instr_word.ctrl.WB_mux_out_sel)
        WB_mux::lw : begin
		WB_regfile_data = WB_Mem_rdata_load;
		WB_rmask = 4'b1111;
	end
        WB_mux::lb : begin
		WB_regfile_data = WB_Mem_rdata_load;
		WB_rmask = 4'b0001 << WB_alu_out[1:0];
	end
        WB_mux::lbu : begin
		WB_regfile_data = WB_Mem_rdata_load;
		WB_rmask = 4'b0001 << WB_alu_out[1:0];
	end
        WB_mux::lh : begin
		WB_regfile_data = WB_Mem_rdata_load;
		WB_rmask = 4'b0011 << WB_alu_out[1:0];
	end
        WB_mux::lhu : begin
		WB_regfile_data = WB_Mem_rdata_load;
		WB_rmask = 4'b0011 << WB_alu_out[1:0];
	end
        WB_mux::pc_plus4 : begin
		WB_regfile_data = WB_instr_word.pc + 4;
		WB_rmask = 4'b0;
	end
        WB_mux::alu_out : begin
		WB_regfile_data = WB_alu_out;
		WB_rmask = 4'b0;
	end
        default: `BAD_MUX_SEL;
    endcase
end
endmodule : write_back
