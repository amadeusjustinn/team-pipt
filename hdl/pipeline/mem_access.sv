module mem_access
import rv32i_types::*;
(
    input clk,
    input rst,
    input rv32i_instr_word EX_instr_word,
    input rv32i_word D_cache_mem_rdata,
    input rv32i_word EX_alu_out,
    input rv32i_word EX_rs1_data, EX_rs2_data,
    input logic stall_mem,
    input rv32i_word WB_rd_data,
    input [4:0] WB_rd_forwarding,
    input logic WB_regfile_load,
    input rv32i_word EX_pc_rdata, EX_pc_wdata,
    input logic EX_mispredict,
    output logic mem_read,
    output logic mem_write,
    output logic [31:0] mem_address,
    output rv32i_word Mem_rdata, Mem_rdata_load, // Goes to WB
    output rv32i_word Mem_wdata, // Goes to memory
    output rv32i_word MEM_alu_out, // Goes to WB
    output rv32i_instr_word MEM_instr_word,
    output logic [4:0] Mem_rd_forwarding,
    output logic [3:0] mem_byte_enable,
    output logic Mem_regfile_load,
    output rv32i_word MEM_rd_data,
    output rv32i_word MEM_pc_rdata, MEM_pc_wdata,
    output logic [3:0] mem_wmask,
    output rv32i_word MEM_rs1_data_fwd, MEM_rs2_data_fwd,
    output logic MEM_mispredict
);

MEM_mux::MEM_mux_out_sel_t MEM_mux_out_sel;
MEM_mux::MEM_forward_on_load_sel_t MEM_forward_on_load_sel;

logic [31:0] MEM_rdata_byte;
logic [31:0] MEM_rdata_half; 
assign MEM_rdata_byte = {(D_cache_mem_rdata >> (8*(MEM_alu_out[1:0])))};
assign MEM_rdata_half = {(D_cache_mem_rdata >> (8*(MEM_alu_out[1:0])))};

rv32i_word MEM_rs1_data, MEM_rs2_data, MEM_forward_rs2_mux_out;
assign MEM_rs1_data_fwd = MEM_rs1_data;
assign MEM_rs2_data_fwd = MEM_forward_rs2_mux_out;
always_ff @(posedge clk)
begin
    if (rst)
    begin
        MEM_instr_word <= '0;
        MEM_alu_out <= '0;
        MEM_rs1_data <= '0;
        MEM_rs2_data <= '0;
	MEM_pc_rdata <= '0;
	MEM_pc_wdata <= '0;
	MEM_mispredict <= '0;
    end
    else if (stall_mem)
    begin
        MEM_instr_word <= MEM_instr_word;
        MEM_alu_out <= MEM_alu_out;
        MEM_rs1_data <= MEM_rs1_data;
        if (MEM_mux_out_sel == MEM_mux::wb_rd_fwd) begin
            MEM_rs2_data <= MEM_forward_rs2_mux_out;
        end else begin
            MEM_rs2_data <= MEM_rs2_data;
        end
	MEM_pc_rdata <= MEM_pc_rdata;
	MEM_pc_wdata <= MEM_pc_wdata;
	MEM_mispredict <= MEM_mispredict;
    end
    else
    begin
        MEM_instr_word <= EX_instr_word;
        MEM_alu_out <= EX_alu_out;
        MEM_rs1_data <= EX_rs1_data;
        MEM_rs2_data <= EX_rs2_data;
	MEM_pc_rdata <= EX_pc_rdata;
	MEM_pc_wdata <= EX_pc_wdata;
	MEM_mispredict <= EX_mispredict;
    end
end

assign mem_read = MEM_instr_word.ctrl.mem_read;
assign mem_write = MEM_instr_word.ctrl.mem_write;
// Load
assign Mem_rdata = D_cache_mem_rdata;
always_comb begin
    unique case (MEM_instr_word.ctrl.WB_mux_out_sel)
        WB_mux::lw : begin
		Mem_rdata_load = D_cache_mem_rdata;
	end
        WB_mux::lb : begin
		Mem_rdata_load = {{24{MEM_rdata_byte[7]}}, MEM_rdata_byte[7:0]};
	end
        WB_mux::lbu : begin
		Mem_rdata_load = {24'h000000, MEM_rdata_byte[7:0]};
	end
        WB_mux::lh : begin
		Mem_rdata_load = {{16{MEM_rdata_half[15]}}, MEM_rdata_half[15:0]};
	end
        WB_mux::lhu : begin
		Mem_rdata_load = {16'h0000, MEM_rdata_half[15:0]};
	end
        default: Mem_rdata_load = D_cache_mem_rdata;
    endcase
end

// Zero out for stores
assign mem_address = {MEM_alu_out[31:2], 2'b00};
assign Mem_rd_forwarding = MEM_instr_word.rd;

assign Mem_regfile_load = MEM_instr_word.ctrl.regfile_load;

assign Mem_wdata = MEM_forward_rs2_mux_out << (8*(MEM_alu_out[1:0]));;

always_comb
begin : store
    case (MEM_instr_word.ctrl.opcode)
        op_store : begin
             case (MEM_instr_word.ctrl.store_funct3)
                sw: mem_byte_enable = 4'b1111;
                sh: mem_byte_enable = 4'b0011 << MEM_alu_out[1:0];
                sb: mem_byte_enable = 4'b0001 << MEM_alu_out[1:0];
                default: mem_byte_enable = 4'b1111;
            endcase
        end
	default: mem_byte_enable = 4'b0000;
    endcase
end

assign mem_wmask = mem_byte_enable;

always_comb 
begin : MUXES
    unique case (MEM_forward_on_load_sel)
        MEM_mux::mem_rdata : MEM_rd_data = Mem_rdata_load;
        MEM_mux::alu_out : MEM_rd_data = MEM_alu_out;
        default : MEM_rd_data = MEM_alu_out;
    endcase
    unique case (MEM_mux_out_sel)
        MEM_mux::rs2_out : MEM_forward_rs2_mux_out = MEM_rs2_data;
        MEM_mux::wb_rd_fwd : MEM_forward_rs2_mux_out = WB_rd_data;
        default: MEM_forward_rs2_mux_out = MEM_rs2_data;
    endcase
end


always_comb 
begin : FWD_UNIT
    if (MEM_instr_word.ctrl.opcode == op_store) begin
        if (WB_regfile_load == 1'b1 && MEM_instr_word.rs2 == WB_rd_forwarding) begin
            MEM_mux_out_sel = MEM_mux::wb_rd_fwd;
        end else begin
            MEM_mux_out_sel = MEM_mux::rs2_out;
        end
    end else begin
        MEM_mux_out_sel = MEM_mux::rs2_out;
    end

    if (MEM_instr_word.ctrl.opcode == op_load) begin
        MEM_forward_on_load_sel = MEM_mux::mem_rdata;
    end else begin
        MEM_forward_on_load_sel = MEM_mux::alu_out;
    end
end

endmodule: mem_access
