
module mp4
import rv32i_types::*;
(
    input clk,
    input rst,
	
	//Remove after CP1
    /*
    input 				instr_mem_resp,
    input rv32i_word 	instr_mem_rdata,
	input 				data_mem_resp,
    input rv32i_word 	data_mem_rdata, 
    output logic 		instr_read,
	output rv32i_word 	instr_mem_address,
    output logic 		data_read,
    output logic 		data_write,
    output logic [3:0] 	data_mbe,
    output rv32i_word 	data_mem_address,
    output rv32i_word 	data_mem_wdata
*/
	
	// For CP2
    input pmem_resp,
    input [63:0] pmem_rdata,

	//To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

// Fetch
rv32i_word IF_instr_data;
rv32i_word IF_pc;
rv32i_word IF_target_address;
logic IF_predict_taken;
// Decode
rv32i_instr_word ID_instr_word;
rv32i_word ID_rs1_data, ID_rs2_data;
//Execute
pcmux_mp4::pcmux_mp4_sel_t EX_pcmux_mp4_sel;
rv32i_word EX_alu_out;
rv32i_instr_word EX_instr_word;
rv32i_word EX_rs1_data, EX_rs2_data;
logic [4:0] EX_rd_forwarding;
rv32i_word EX_pc, EX_target_pc;
//Mem access
rv32i_word Mem_rdata;
rv32i_word MEM_alu_out;
rv32i_instr_word MEM_instr_word;
logic [4:0] Mem_rd_forwarding;
logic Mem_regfile_load;
rv32i_word MEM_rd_data;
//Write back
logic WB_regfile_load;
rv32i_word WB_regfile_data;
logic [4:0] WB_regfile_rd;

// Misprediction
logic mispredict;
rv32i_word 	instr_mem_address;
assign instr_mem_address = IF_pc;

// Stalling unit
logic stall_fetch, stall_decode, stall_execute, stall_mem;

// D cache signals
logic pmem_resp_dcache, pmem_read_dcache, pmem_write_dcache, data_read, data_write, data_mem_resp;
logic [31:0] address_i_dcache, data_mem_address, data_mem_wdata, data_mem_rdata;
logic [255:0] line_o_dcache, line_i_dcache;
logic [3:0] mem_byte_enable;
 
// I cache signals
logic pmem_resp_icache, pmem_read_icache, pmem_write_icache, instr_mem_resp;
logic [31:0] address_i_icache, instr_mem_rdata;
logic [255:0] line_o_icache, line_i_icache;

// Arbiter signals
logic pmem_resp_arbiter, pmem_read_arbiter, pmem_write_arbiter;
logic [31:0] pmem_address_arbiter;
logic [255:0] line_o, pmem_rdata_arbiter;

prediction_unit prediction_unit (
    .clk                   (clk),
    .rst                   (rst),
    .IF_pc                 (IF_pc),
    .EX_pc                 (EX_pc),
    .EX_target_pc          (EX_target_pc),
    .EX_instr_word         (EX_instr_word),
    .EX_pcmux_mp4_sel      (EX_pcmux_mp4_sel),
    .mispredict            (mispredict),
    .IF_target_address_predict     (IF_target_address),
    .IF_predict_taken      (IF_predict_taken),
    .stall_execute	   (stall_execute)
);

stalling_unit stalling_unit (
    .rst                   (rst),
    .EX_instr_word         (EX_instr_word),
    .MEM_instr_word        (MEM_instr_word),
    .instr_mem_resp        (instr_mem_resp),
    .data_mem_resp         (data_mem_resp),
    .stall_fetch           (stall_fetch),
    .stall_decode          (stall_decode),
    .stall_execute         (stall_execute),
    .stall_mem             (stall_mem),
    .data_read             (data_read),
    .data_write            (data_write)
);

rv32i_word IF_pc_rdata, ID_pc_rdata, EX_pc_rdata, MEM_pc_rdata, EX_pc_wdata, MEM_pc_wdata;

fetch fetch (
    .clk                   (clk),
    .rst                   (rst),
    .mem_instr_data        (instr_mem_rdata),
    .EX_pcmux_mp4_sel      (EX_pcmux_mp4_sel),
    .EX_target_pc          (EX_target_pc),
    .IF_instr_data         (IF_instr_data),
    .pc                    (IF_pc),
    .mispredict		       (mispredict),
    .stall_fetch           (stall_fetch),
    .IF_pc_rdata 	       (IF_pc_rdata),
    .IF_target_address     (IF_target_address),
    .IF_predict_taken      (IF_predict_taken),
    .pmem_resp_dcache      (pmem_resp_dcache),
    .stall_mem             (stall_mem)
);

decode decode (
    .clk                   (clk),
    .rst                   (rst),
    .IF_instr_data         (IF_instr_data),
    .IF_pc                 (IF_pc),
    .WB_regfile_load       (WB_regfile_load),
    .WB_regfile_data       (WB_regfile_data),
    .WB_regfile_rd         (WB_regfile_rd),
    .instr_word            (ID_instr_word),
    .rs1_data              (ID_rs1_data),
    .rs2_data              (ID_rs2_data),
    .mispredict		       (mispredict),
    .stall_fetch           (stall_fetch),
    .stall_decode          (stall_decode),
    .IF_pc_rdata 	       (IF_pc_rdata),
    .ID_pc_rdata	       (ID_pc_rdata)
);

logic MEM_mispredict;

execute execute (
    .clk                   (clk),
    .rst                   (rst),
    .ID_instr_word         (ID_instr_word),
    .ID_rs1_data           (ID_rs1_data),
    .ID_rs2_data           (ID_rs2_data),
    .Mem_rd_forwarding     (Mem_rd_forwarding),
    .WB_rd_forwarding      (WB_regfile_rd),
    .EX_alu_out            (EX_alu_out),
    .EX_rd_forwarding      (EX_rd_forwarding),
    .EX_pcmux_mp4_sel      (EX_pcmux_mp4_sel),
    .EX_instr_word         (EX_instr_word),
    .EX_rs1_data_fwd       (EX_rs1_data),
    .EX_rs2_data_fwd       (EX_rs2_data),
    .stall_execute         (stall_execute),
    .Mem_rd_data           (MEM_rd_data),
    .WB_rd_data            (WB_regfile_data),
    .WB_regfile_load       (WB_regfile_load),
    .Mem_regfile_load      (Mem_regfile_load),
    .ID_pc_rdata	       (ID_pc_rdata),
    .EX_pc_rdata	       (EX_pc_rdata),
    .EX_pc_wdata	       (EX_pc_wdata),
    .EX_pc                 (EX_pc),
    .EX_target_pc          (EX_target_pc)
);

logic[31:0] MEM_rs1_data, MEM_rs2_data, Mem_rdata_load;
logic [3:0] mem_wmask;
mem_access mem_access (
    .clk                   (clk),
    .rst                   (rst),
    .EX_instr_word         (EX_instr_word),
    .D_cache_mem_rdata     (data_mem_rdata),
    .EX_alu_out            (EX_alu_out),
    .EX_rs1_data           (EX_rs1_data),
    .EX_rs2_data           (EX_rs2_data),
    .mem_read              (data_read),
    .mem_write             (data_write),
    .mem_address           (data_mem_address),
    .Mem_rdata             (Mem_rdata),
    .Mem_rdata_load        (Mem_rdata_load),
    .Mem_wdata             (data_mem_wdata),
    .MEM_alu_out           (MEM_alu_out),
    .MEM_instr_word        (MEM_instr_word),
    .Mem_rd_forwarding     (Mem_rd_forwarding),
    .mem_byte_enable       (mem_byte_enable),
    .stall_mem             (stall_mem),
    .WB_rd_data            (WB_regfile_data),
    .WB_rd_forwarding      (WB_regfile_rd),
    .WB_regfile_load       (WB_regfile_load),
    .Mem_regfile_load      (Mem_regfile_load),
    .MEM_rd_data           (MEM_rd_data),
    .EX_pc_rdata	   (EX_pc_rdata),
    .MEM_pc_rdata	   (MEM_pc_rdata),
    .EX_pc_wdata	   (EX_pc_wdata),
    .MEM_pc_wdata  	   (MEM_pc_wdata),
    .mem_wmask		   (mem_wmask),
    .MEM_rs1_data_fwd      (MEM_rs1_data), 
    .MEM_rs2_data_fwd	   (MEM_rs2_data),
    .EX_mispredict         (mispredict),
    .MEM_mispredict        (MEM_mispredict)
);


logic[31:0] MEM_mem_address;

write_back write_back (
    .clk                   (clk),
    .rst                   (rst),
    .MEM_instr_word        (MEM_instr_word),
    .MEM_alu_out           (MEM_alu_out),
    .Mem_rdata             (Mem_rdata),
    .WB_regfile_load       (WB_regfile_load),
    .WB_regfile_data       (WB_regfile_data),
    .WB_regfile_rd         (WB_regfile_rd),
    .stall_mem             (stall_mem),
    .MEM_mem_address       (data_mem_address),
    .MEM_Mem_rdata         (Mem_rdata),
    .MEM_Mem_wdata         (data_mem_wdata),
    .MEM_pc_rdata	   (MEM_pc_rdata),
    .MEM_pc_wdata  	   (MEM_pc_wdata),
    .mem_wmask		   (mem_wmask),
    .MEM_rs1_data          (MEM_rs1_data), 
    .MEM_rs2_data          (MEM_rs2_data),
    .MEM_mispredict        (MEM_mispredict),
    .Mem_rdata_load        (Mem_rdata_load)
);

/*
cache d_cache (
    .clk                   (clk),
    .rst                   (rst),
    .mem_address           (data_mem_address),
    .mem_rdata             (data_mem_rdata),
    .mem_wdata             (data_mem_wdata),
    .mem_read              (data_read),
    .mem_write             (data_write),
    .mem_byte_enable       (mem_byte_enable),
    .mem_resp              (data_mem_resp),
    .pmem_address          (address_i_dcache),
    .pmem_rdata            (line_o_dcache),
    .pmem_wdata            (line_i_dcache),
    .pmem_read             (pmem_read_dcache),
    .pmem_write            (pmem_write_dcache),
    .pmem_resp             (pmem_resp_dcache)
);
*/

cache d_cache (
    .clk                   (clk),
    .rst                   (rst),
    .pmem_resp             (pmem_resp_dcache),
    .pmem_rdata            (line_o_dcache),
    .pmem_address          (address_i_dcache),
    .pmem_wdata            (line_i_dcache),
    .pmem_read             (pmem_read_dcache),
    .pmem_write            (pmem_write_dcache),
    .mem_read              (data_read),
    .mem_write             (data_write),
    .mem_byte_enable       (mem_byte_enable),
    .mem_address           (data_mem_address),
    .mem_wdata             (data_mem_wdata),
    .mem_resp              (data_mem_resp),
    .mem_rdata             (data_mem_rdata)
);

cache i_cache (
    .clk                   (clk),
    .rst                   (rst),
    .pmem_resp             (pmem_resp_icache),
    .pmem_rdata            (line_o_icache),
    .pmem_address          (address_i_icache),
    .pmem_wdata            (line_i_icache),
    .pmem_read             (pmem_read_icache),
    .pmem_write            (pmem_write_icache),
    .mem_read              (!rst),
    .mem_write             (1'b0),
    .mem_byte_enable       (4'b1111),
    .mem_address           (instr_mem_address),
    .mem_wdata             (32'b0),
    .mem_resp              (instr_mem_resp),
    .mem_rdata             (instr_mem_rdata)
);

/*
cache i_cache (
    .clk                   (clk),
    .rst                   (rst),
    .mem_address           (instr_mem_address),
    .mem_rdata             (instr_mem_rdata),
    .mem_wdata             (32'b0),
    .mem_read              (!rst),
    .mem_write             (1'b0),
    .mem_byte_enable       (4'b1111),
    .mem_resp              (instr_mem_resp),
    .pmem_address          (address_i_icache),
    .pmem_rdata            (line_o_icache),
    .pmem_wdata            (line_i_icache),
    .pmem_read             (pmem_read_icache),
    .pmem_write            (pmem_write_icache),
    .pmem_resp             (pmem_resp_icache)
);
*/
arbiter arbiter (
    .clk                   (clk),
    .rst                   (rst),
    .adaptor_resp          (pmem_resp_arbiter),
    .line_resp             (line_o),
    .pmem_read_dcache      (pmem_read_dcache),
    .pmem_write_dcache     (pmem_write_dcache),
    .address_i_dcache      (address_i_dcache),
    .line_i_dcache         (line_i_dcache),
    .pmem_read_icache      (pmem_read_icache),
    .pmem_write_icache     (pmem_write_icache),
    .address_i_icache      (address_i_icache),
    .line_i_icache         (line_i_icache),
    .pmem_read             (pmem_read_arbiter),
    .pmem_write            (pmem_write_arbiter),
    .address_i             (pmem_address_arbiter),
    .line_i                (pmem_rdata_arbiter),
    .pmem_resp_dcache      (pmem_resp_dcache),
    .line_o_dcache         (line_o_dcache),
    .pmem_resp_icache      (pmem_resp_icache),
    .line_o_icache         (line_o_icache)
);

cacheline_adaptor cacheline_adaptor (
    .clk                   (clk),
    .reset_n               (!rst),
    .line_i                (pmem_rdata_arbiter),
    .line_o                (line_o),
    .address_i             (pmem_address_arbiter),
    .read_i                (pmem_read_arbiter),
    .write_i               (pmem_write_arbiter),
    .resp_o                (pmem_resp_arbiter),
    .burst_i               (pmem_rdata),
    .burst_o               (pmem_wdata),
    .address_o             (pmem_address),
    .read_o                (pmem_read),
    .write_o               (pmem_write),
    .resp_i                (pmem_resp)
);
endmodule : mp4
