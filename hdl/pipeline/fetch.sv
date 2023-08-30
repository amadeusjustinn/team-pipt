`define BAD_MUX_SEL $display("Illegal mux select")

module fetch
import rv32i_types::*;
(
    input clk,
    input rst,
    input rv32i_word mem_instr_data,
    input pcmux_mp4::pcmux_mp4_sel_t EX_pcmux_mp4_sel,
    input rv32i_word EX_target_pc,
    input logic stall_fetch,
    input logic mispredict,
    input rv32i_word IF_target_address,
    input logic IF_predict_taken,
    input logic stall_mem, 
    input logic pmem_resp_dcache,
    output rv32i_word IF_instr_data,
    output rv32i_word pc,
    output rv32i_word IF_pc_rdata
);

rv32i_word pcmux_out;
logic pc_load, pc_stalled_load;
// Flag set when fetch is stalled and there is a mispredict; need to clear the instr_data after it has finished reading since it is invalid
logic mispredict_stall;
rv32i_word pc_stalled;
// If stall only fetch due to i-cache miss and there is a mispredict in execute, it will load the updated pc
assign pc_load = !rst && !stall_fetch; 
assign pc_stalled_load = !rst && ((!stall_fetch) || mispredict) && (!mispredict_stall || (stall_mem && pmem_resp_dcache));
assign IF_pc_rdata = pc;

always_ff @(posedge clk)
begin
    if (rst) begin
        mispredict_stall <= '0;
    end else if (stall_fetch) begin
        if (mispredict) begin
            mispredict_stall <= 1'b1;
        end else begin
            mispredict_stall <= mispredict_stall;
        end
    end else begin
        mispredict_stall <= 1'b0;
    end
end

pc_register_comb PC_stalled(
    .clk  (clk),
    .rst  (rst),
    .load (pc_stalled_load),
    .in   (pcmux_out),
    .out  (pc_stalled)
);

pc_register PC(
    .clk  (clk),
    .rst  (rst),
    .load (pc_load),
    .in   (pc_stalled),
    .out  (pc)
);

always_comb
begin
    if (mispredict || mispredict_stall) 
    begin
        IF_instr_data = '0;
    end
    else
    begin
        IF_instr_data = mem_instr_data;
    end
end

always_comb 
begin
    if (!mispredict) begin
        if (IF_predict_taken) begin
            pcmux_out = IF_target_address;
        end else begin
            pcmux_out = pc + 4;
        end
    end else begin
        pcmux_out = EX_target_pc;
    end
end

/*
logic fetch_commit;
always_comb begin : MUXES
    unique case (EX_pcmux_mp4_sel)
        // On a branch, it will assume not taken and start the next pc+4
        // Once the branch is at execute, it will send the calculated target to be the next instr
        // If the branch is taken, will have to flush the instruction word in ID and EX on the next cycle
        // Otherwise, it correctly does the next instruction
    pcmux_mp4::pc_plus4 : begin 
		//pcmux_out = pc + 4;
		fetch_commit = 1'b0;
	end
    pcmux_mp4::branch_jal : begin 
		//pcmux_out = EX_target_pc;
		fetch_commit = 1'b1;
	end
    pcmux_mp4::jalr : begin 
		//pcmux_out = EX_target_pc;
		fetch_commit = 1'b1;
	end
    // etc.
    default: `BAD_MUX_SEL;
    endcase
end
*/

endmodule : fetch
