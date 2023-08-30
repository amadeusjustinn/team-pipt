module prediction_unit 
import rv32i_types::*;
#(
    parameter s_index  = 8,
    parameter s_index_global = 5,
    parameter global_n = 3
)
(
    input clk,
    input rst,

    input rv32i_word IF_pc, EX_pc,
    input rv32i_word EX_target_pc,
    input rv32i_instr_word EX_instr_word,
    input pcmux_mp4::pcmux_mp4_sel_t EX_pcmux_mp4_sel,
    input logic stall_execute,
    output logic mispredict,
    output rv32i_word IF_target_address_predict,
    output logic IF_predict_taken
);

logic [global_n-1:0] global_history;
logic [(s_index_global+global_n-1):0] IF_global_history_s_index, global_history_s_index;


logic [(29-s_index):0] IF_tag;
logic [(s_index-1):0] IF_index;
assign IF_tag = IF_pc[31:(2+s_index)];
assign IF_index = IF_pc[(2+s_index-1):2];

logic [(29-s_index_global):0] IF_tag_global;
logic [(s_index_global+global_n-1):0] IF_index_global;
assign IF_tag_global = IF_pc[31:(2+s_index_global)];
assign IF_index_global = (global_history_s_index << s_index_global) | IF_pc[(2+s_index_global-1):2];

logic [(29-s_index):0] EX_tag;
logic [(s_index-1):0] EX_index;
assign EX_tag = EX_pc[31:(2+s_index)];
assign EX_index = EX_pc[(2+s_index-1):2];

logic [(29-s_index_global):0] EX_tag_global;
logic [(s_index_global+global_n-1):0] EX_index_global;
assign EX_tag_global = EX_pc[31:(2+s_index_global)];
assign EX_index_global = (IF_global_history_s_index << s_index_global) | EX_pc[(2+s_index_global-1):2];

logic [(29-s_index):0] IF_tag_out, EX_tag_out;
logic IF_valid_out, EX_valid_out;

logic [(29-s_index_global):0] IF_tag_out_global, EX_tag_out_global;
logic IF_valid_out_global, EX_valid_out_global;

logic EX_is_branch_jal;
logic [1:0] IF_prediction, EX_prediction, EX_new_prediction;
logic [1:0] IF_prediction_global, EX_prediction_global, EX_new_prediction_global;
logic IF_hit, EX_hit;
logic IF_hit_global, EX_hit_global;

rv32i_word IF_target_address, EX_target_address;
rv32i_word IF_target_address_global, EX_target_address_global;

assign EX_is_branch_jal = EX_instr_word.ctrl.opcode == op_br
                        || EX_instr_word.ctrl.opcode == op_jal
                        || EX_instr_word.ctrl.opcode == op_jalr;

logic mispredict_local;

assign mispredict_local = EX_is_branch_jal && (!EX_hit || 
    (((EX_prediction == 2'b11 || EX_prediction == 2'b10) && EX_pcmux_mp4_sel == pcmux_mp4::pc_plus4) || // Mispredict taken
    ((EX_prediction == 2'b00 || EX_prediction == 2'b01) && EX_pcmux_mp4_sel != pcmux_mp4::pc_plus4) ||  // Mispredict not taken
    (EX_target_address != EX_target_pc)));                                                               // Predicted target address incorrect

logic mispredict_global;

assign mispredict_global = EX_is_branch_jal && (!EX_hit_global || 
    (((EX_prediction_global == 2'b11 || EX_prediction_global == 2'b10) && EX_pcmux_mp4_sel == pcmux_mp4::pc_plus4) || // Mispredict taken
    ((EX_prediction_global == 2'b00 || EX_prediction_global == 2'b01) && EX_pcmux_mp4_sel != pcmux_mp4::pc_plus4) ||  // Mispredict not taken
    (EX_target_address_global != EX_target_pc)));  

// Check hit in IF to determine if current instruction is a branch
assign IF_hit = IF_valid_out && (IF_tag_out == IF_tag);
assign EX_hit = EX_valid_out && (EX_tag_out == EX_tag);

assign IF_hit_global = IF_valid_out_global && (IF_tag_out_global == IF_tag_global);
assign EX_hit_global = EX_valid_out_global && (EX_tag_out_global == EX_tag_global);

logic [1:0] local_branch_prediction;
assign local_branch_prediction = EX_hit ? EX_prediction : 2'b01; // Reset sat bit on miss

logic [1:0] global_branch_prediction;
assign global_branch_prediction = EX_hit_global ? EX_prediction_global : 2'b01;

logic IF_predict_taken_local;
logic IF_predict_taken_global;

// 00: SL 01: WL 10: WG 11: SG
logic [1:0] tournament_sat_bit, IF_tournament_sat_bit_buffer, ID_tournament_sat_bit_buffer;

logic [global_n-1:0] IF_global_history_buffer, ID_global_history_buffer;
assign IF_global_history_s_index = ID_global_history_buffer;
assign global_history_s_index = global_history;
// 0 for not taken; 1 for taken

// Change when testing local or global
assign IF_predict_taken = (tournament_sat_bit == 2'b00 || tournament_sat_bit == 2'b01) ? IF_predict_taken_local : IF_predict_taken_global;
assign mispredict = (ID_tournament_sat_bit_buffer == 2'b00 || ID_tournament_sat_bit_buffer == 2'b01) ? mispredict_local : mispredict_global;
assign IF_target_address_predict = (tournament_sat_bit == 2'b00 || tournament_sat_bit == 2'b01) ? IF_target_address: IF_target_address_global;

logic load;
assign load = EX_is_branch_jal && !stall_execute;
always_ff @(posedge clk) begin
	if (rst) begin
		global_history <= '0;
		IF_global_history_buffer <= '0;
		ID_global_history_buffer <= '0;
		tournament_sat_bit <= '0;
		IF_tournament_sat_bit_buffer <= '0;
		ID_tournament_sat_bit_buffer <= '0;
	end else begin
		if (stall_execute) begin
			global_history <= global_history;
			tournament_sat_bit <= tournament_sat_bit;
		end else if (EX_is_branch_jal) begin
			if (EX_pcmux_mp4_sel == pcmux_mp4::pc_plus4) begin // Not taken
				global_history <= global_history << 1;
			end else begin
				global_history <= (global_history << 1) | 3'b001;
			end
			if (ID_tournament_sat_bit_buffer == 2'b00 || ID_tournament_sat_bit_buffer == 2'b01) begin
			// Guessed local
				if (mispredict_local) begin
				// Incorrect; more likely to be global
					if (tournament_sat_bit != 2'b11) begin
						tournament_sat_bit <= tournament_sat_bit + 2'b01;
					end else begin
						tournament_sat_bit <= 2'b11;
					end
				end else begin
				// Correct; more likely to be local
					if (tournament_sat_bit != 2'b00) begin
						tournament_sat_bit <= tournament_sat_bit - 2'b01;
					end else begin
						tournament_sat_bit <= 2'b00;
					end
				end
			end else begin
			// Guessed global
				if (mispredict_global) begin
					// Incorrect; more likely to be local
					if (tournament_sat_bit != 2'b00) begin
						tournament_sat_bit <= tournament_sat_bit - 2'b01;
					end else begin
						tournament_sat_bit <= 2'b00;
					end
				end else begin
					// Correct; more likely to be global
					if (tournament_sat_bit != 2'b11) begin
						tournament_sat_bit <= tournament_sat_bit + 2'b01;
					end else begin
						tournament_sat_bit <= 2'b11;
					end
				end
			end
		end
		IF_global_history_buffer <= global_history;
		ID_global_history_buffer <= IF_global_history_buffer;
		IF_tournament_sat_bit_buffer <= tournament_sat_bit;
		ID_tournament_sat_bit_buffer <= IF_tournament_sat_bit_buffer;
	end
end

always_comb
begin
    // Predict if taken or not taken based on current saturating bits
    if (IF_hit && (IF_prediction == 2'b11 || IF_prediction == 2'b10)) begin
        IF_predict_taken_local = 1'b1;
    end else begin
        IF_predict_taken_local = 1'b0;
    end

    // Update saturating bits
    if (EX_pcmux_mp4_sel != pcmux_mp4::pc_plus4) begin
        // Taken
        if (EX_prediction != 2'b11) begin
            EX_new_prediction = local_branch_prediction + 2'b01;
        end else begin
            EX_new_prediction = 2'b11;
        end
    end else begin
        // Not taken
        if (EX_prediction != 2'b00) begin
            EX_new_prediction = local_branch_prediction - 2'b01;
        end else begin
            EX_new_prediction = 2'b00;
        end
    end

    // Predict if taken or not taken based on current saturating bits
    if (IF_hit_global && (IF_prediction_global == 2'b11 || IF_prediction_global == 2'b10)) begin
        IF_predict_taken_global = 1'b1;
    end else begin
        IF_predict_taken_global = 1'b0;
    end

    // Update saturating bits
    if (EX_pcmux_mp4_sel != pcmux_mp4::pc_plus4) begin
        // Taken
        if (EX_prediction_global != 2'b11) begin
            EX_new_prediction_global = global_branch_prediction + 2'b01;
        end else begin
            EX_new_prediction_global = 2'b11;
        end
    end else begin
        // Not taken
        if (EX_prediction_global != 2'b00) begin
            EX_new_prediction_global = global_branch_prediction - 2'b01;
        end else begin
            EX_new_prediction_global = 2'b00;
        end
    end
end

dual_read_array #(s_index, 1) valid_array_local (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index),
    .EX_rindex(EX_index),
    .windex(EX_index),
    .datain(1'b1),
    .IF_dataout(IF_valid_out),
    .EX_dataout(EX_valid_out)
);

dual_read_array #(global_n + s_index_global, 1) valid_array_global (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index_global),
    .EX_rindex(EX_index_global),
    .windex(EX_index_global),
    .datain(1'b1),
    .IF_dataout(IF_valid_out_global),
    .EX_dataout(EX_valid_out_global)
);

dual_read_array #(s_index, (29-s_index+1)) tag_array_local (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index),
    .EX_rindex(EX_index),
    .windex(EX_index),
    .datain(EX_tag),
    .IF_dataout(IF_tag_out),
    .EX_dataout(EX_tag_out)
);

dual_read_array #(global_n + s_index_global, (29-s_index_global+1)) tag_array_global (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index_global),
    .EX_rindex(EX_index_global),
    .windex(EX_index_global),
    .datain(EX_tag_global),
    .IF_dataout(IF_tag_out_global),
    .EX_dataout(EX_tag_out_global)
);

dual_read_array #(s_index, 32) target_address_array_local (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index),
    .EX_rindex(EX_index),
    .windex(EX_index),
    .datain(EX_target_pc),
    .IF_dataout(IF_target_address),
    .EX_dataout(EX_target_address)
);

dual_read_array #(global_n + s_index_global, 32) target_address_array_global (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index_global),
    .EX_rindex(EX_index_global),
    .windex(EX_index_global),
    .datain(EX_target_pc),
    .IF_dataout(IF_target_address_global),
    .EX_dataout(EX_target_address_global)
);

// IF_prediction: 00: SNT, 01: WNT, 10: WT, 11: ST
dual_read_array_sat #(s_index, 2) sat_bit_array_local (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index),
    .EX_rindex(EX_index),
    .windex(EX_index),
    .datain(EX_new_prediction),
    .IF_dataout(IF_prediction),
    .EX_dataout(EX_prediction)
);

dual_read_array_sat #(global_n + s_index_global, 2) sat_bit_array_global (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load),
    .IF_rindex(IF_index_global),
    .EX_rindex(EX_index_global),
    .windex(EX_index_global),
    .datain(EX_new_prediction_global),
    .IF_dataout(IF_prediction_global),
    .EX_dataout(EX_prediction_global)
);

endmodule : prediction_unit
