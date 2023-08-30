module mp4_tb;
import rv32i_types::*;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = dut.write_back.WB_instr_word.ctrl.regfile_load || dut.write_back.WB_instr_word.ctrl.opcode == op_jalr || dut.write_back.WB_instr_word.ctrl.opcode == op_jal || dut.write_back.WB_instr_word.ctrl.opcode == op_br || dut.write_back.WB_instr_word.ctrl.opcode == op_store;
//!((dut.write_back.WB_instr_word & 32'b0) == '0);//dut.write_back.WB_pc_commit || dut.write_back.WB_commit; //!dut.write_back.WB_instr_word;
//dut.fetch.fetch_commit || dut.write_back.WB_commit; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.write_back.finish; // Set high when target PC == Current PC for a branch
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

int num_branches;
int num_mispredicts;
always_ff @(posedge itf.clk) begin
	if (dut.rst) begin
		num_branches <= '0;
		num_mispredicts <= '0;
	end else begin
		if (rvfi.commit) begin
			if (dut.write_back.WB_instr_word.ctrl.opcode == op_jalr || dut.write_back.WB_instr_word.ctrl.opcode == op_jal || dut.write_back.WB_instr_word.ctrl.opcode == op_br) begin
				num_branches <= num_branches + 1;
			end
			if (dut.write_back.WB_mispredict) begin
				num_mispredicts <= num_mispredicts + 1;
			end
		end
	end
end

 
/*
Instruction and trap:
*/
    assign rvfi.inst = dut.write_back.WB_instr_word.instr_data;
    assign rvfi.trap = 1'b0;
/*
Regfile:
*/
    assign rvfi.rs1_addr = dut.write_back.WB_instr_word.rs1;
    assign rvfi.rs2_addr = dut.write_back.WB_instr_word.rs2;
    assign rvfi.rs1_rdata = dut.write_back.WB_rs1_data;
    assign rvfi.rs2_rdata = dut.write_back.WB_rs2_data;
    assign rvfi.load_regfile = dut.write_back.WB_regfile_load;
    assign rvfi.rd_addr = dut.write_back.WB_regfile_rd;
    assign rvfi.rd_wdata = (dut.write_back.WB_regfile_rd == 0) ? '0 :  dut.write_back.WB_regfile_data;
/*
PC:
*/
    assign rvfi.pc_rdata = dut.write_back.WB_pc_rdata;
    assign rvfi.pc_wdata = dut.write_back.WB_pc_wdata;
/*
Memory:
*/
    assign rvfi.mem_addr = dut.write_back.WB_mem_address;
    assign rvfi.mem_rmask = dut.write_back.WB_rmask;
    assign rvfi.mem_wmask = dut.write_back.WB_wmask;
    assign rvfi.mem_rdata = dut.write_back.WB_Mem_rdata;
    assign rvfi.mem_wdata = dut.write_back.WB_Mem_wdata;
/*
Please refer to rvfi_itf.sv for more information.
*/

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
*/
    assign itf.inst_read = 1'b1;
    assign itf.inst_addr = dut.fetch.pc;
    assign itf.inst_resp = dut.i_cache.mem_resp;
    assign itf.inst_rdata = dut.fetch.mem_instr_data;
/*
dcache signals:
*/
    assign itf.data_read = dut.mem_access.mem_read;
    assign itf.data_write = dut.mem_access.mem_write;
    assign itf.data_mbe = dut.mem_access.mem_byte_enable;
    assign itf.data_addr = dut.mem_access.mem_address;
    assign itf.data_wdata = dut.mem_access.Mem_wdata;
    assign itf.data_resp = dut.d_cache.mem_resp;
    assign itf.data_rdata = dut.mem_access.Mem_rdata;
/*
Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
*/
/*
    assign itf.mem_read = dut.pmem_read;
    assign itf.mem_write = dut.pmem_write;
    assign itf.mem_wdata = dut.pmem_wdata;
    assign itf.mem_rdata = dut.pmem_rdata;
    assign itf.mem_addr = dut.pmem_address;
    assign itf.mem_resp = dut.pmem_resp;
*/
/*
Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    
     // Remove after CP1
     /*
    .instr_mem_resp(itf.inst_resp),
    .instr_mem_rdata(itf.inst_rdata),
	.data_mem_resp(itf.data_resp),
    .data_mem_rdata(itf.data_rdata),
    .instr_read(itf.inst_read),
	.instr_mem_address(itf.inst_addr),
    .data_read(itf.data_read),
    .data_write(itf.data_write),
    .data_mbe(itf.data_mbe),
    .data_mem_address(itf.data_addr),
    .data_mem_wdata(itf.data_wdata)
    */

    // Use for CP2 onwards
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
);
/***************************** End Instantiation *****************************/

endmodule
