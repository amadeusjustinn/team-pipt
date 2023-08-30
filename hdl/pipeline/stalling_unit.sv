module stalling_unit
import rv32i_types::*;
(
    input rst,
    input rv32i_instr_word EX_instr_word,
	input rv32i_instr_word MEM_instr_word,
	input instr_mem_resp,
	input data_mem_resp,
	input data_read, data_write,
    output logic stall_fetch, stall_decode, stall_execute, stall_mem
);

logic reset, read_exe_after_load, d_cache_miss, i_cache_miss;
assign reset = rst;
assign read_exe_after_load = (MEM_instr_word.ctrl.opcode == op_load) && (EX_instr_word.ctrl.opcode != op_store) && ((MEM_instr_word.rd == EX_instr_word.rs1) || (MEM_instr_word.rd == EX_instr_word.rs2)) && (!data_mem_resp);
assign i_cache_miss = !instr_mem_resp;
assign d_cache_miss = ((data_read || data_write) && (!data_mem_resp));
assign stall_fetch = reset || read_exe_after_load || d_cache_miss || i_cache_miss;
assign stall_decode = reset || read_exe_after_load || d_cache_miss;
assign stall_execute = reset || read_exe_after_load || d_cache_miss;
assign stall_mem = reset || read_exe_after_load || d_cache_miss;

endmodule : stalling_unit
