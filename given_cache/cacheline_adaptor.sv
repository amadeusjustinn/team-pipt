module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

// State values
logic [3:0] 
// Default state when reseted or not reading and writing
s_reset  	 = 4'd0,
// Gets read_i but has to wait for resp_i
s_read_wait  = 4'd1,
// Moves the 4 bursts to line_o
s_read_1 	 = 4'd2,
s_read_2 	 = 4'd3,
s_read_3 	 = 4'd4,
// Outputs line_o by setting resp_o
s_read_4 	 = 4'd5,
// Gets write_i but has to wait for resp_i
s_write_wait = 4'd6,
s_write_1 	 = 4'd7,
s_write_2 	 = 4'd8,
s_write_3 	 = 4'd9,
// Outputs resp_o to indicate completion
s_write_4 	 = 4'd10;
// State registers
reg [3:0] state_cur, state_next;
logic resp_output;

assign resp_o = resp_output;

always_ff @(posedge clk, negedge reset_n) begin
	if (~reset_n) begin
        state_cur <= s_reset;
	end
	else begin
		state_cur <= state_next;
	end
end

// State transitions
always_ff @(read_i, write_i, resp_i, state_cur) begin
	state_next = state_cur;
	case (state_cur)
		s_reset : begin
			if (read_i) begin
				state_next = s_read_wait;
			end
			else if (write_i) begin
				state_next = s_write_wait;
			end
			else begin
				state_next = s_reset;
			end
		end
		s_read_wait : begin
			if (resp_i) begin
				state_next = s_read_1;
			end
			else begin
				state_next = s_read_wait;
			end
		end
		s_read_1 : begin
			state_next = s_read_2;
		end
		s_read_2 : begin
			state_next = s_read_3;
		end
		s_read_3 : begin
			state_next = s_read_4;
		end
		s_read_4 : begin
			state_next = s_reset;
		end
		s_write_wait : begin
			if (resp_i) begin
				state_next = s_write_1;
			end
			else begin
				state_next = s_write_wait;
			end
		end
		s_write_1 : begin
			state_next = s_write_2;
		end
		s_write_2 : begin
			state_next = s_write_3;
		end
		s_write_3 : begin
			state_next = s_write_4;
		end
		s_write_4 : begin
			state_next = s_reset;
		end
	endcase
end

// State outputs
always_ff @(read_i, write_i, resp_i, state_cur) begin
	resp_output <= 1'b0;
	address_o <= address_i;
	case (state_cur)
		s_reset : begin
			read_o <= 1'b0;
			write_o <= 1'b0;
		end
		s_read_wait : begin
			read_o <= 1'b1;
		end
		s_read_1 : begin
			read_o <= 1'b1;
			line_o[63:0] <= burst_i;
		end
		s_read_2 : begin
			read_o <= 1'b1;
			line_o[127:64] <= burst_i;
		end
		s_read_3 : begin
			read_o <= 1'b1;
			line_o[191:128] <= burst_i;
		end
		s_read_4 : begin
			read_o <= 1'b1;
			line_o[255:192] <= burst_i;
			resp_output <= 1'b1;
		end
		s_write_wait : begin
			write_o <= 1'b1;
			burst_o[63:0] <= line_i[63:0];
		end
		s_write_1 : begin
			write_o <= 1'b1;
			burst_o[63:0] <= line_i[127:64];
		end
		s_write_2 : begin
			write_o <= 1'b1;
			burst_o[63:0] <= line_i[191:128];
		end
		s_write_3 : begin
			write_o <= 1'b1;
			burst_o[63:0] <= line_i[255:192];
		end
		s_write_4 : begin
			resp_output <= 1'b1;
		end
	endcase
end

endmodule : cacheline_adaptor
