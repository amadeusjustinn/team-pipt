module instr_rom
import rv32i_types::*;
(
    input rv32i_control_word ctrl,
    input rv32i_word immediate,
    input [4:0] rs1, rs2, rd,
    input rv32i_word pc,
	
	input rv32i_word instr_data,

    output rv32i_instr_word instr_word
);

always_comb
begin
	// Debug
	instr_word.instr_data = instr_data;

    instr_word.ctrl = ctrl;
    instr_word.immediate = immediate;
    instr_word.rs1 = rs1;
    instr_word.rs2 = rs2;
    instr_word.rd = rd;
    instr_word.pc = pc;
end

endmodule : instr_rom
