/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
    input logic mem_read, mem_write,
    input logic [255:0] mem_wdata256,
    output logic [255:0] mem_rdata256,
    input logic [31:0] mem_address,
    input logic [31:0] mem_byte_enable256,
    output logic [31:0] pmem_address,
    input logic read_LRU, load_LRU, 
    input logic [2:0] datain_LRU,
    output logic [2:0] dataout_LRU,
    input logic read_valid_1, load_valid_1, datain_valid_1, read_valid_2, load_valid_2, datain_valid_2, read_valid_3, load_valid_3, datain_valid_3, read_valid_4, load_valid_4, datain_valid_4,
    input logic read_dirty_1, load_dirty_1, datain_dirty_1, read_dirty_2, load_dirty_2, datain_dirty_2, read_dirty_3, load_dirty_3, datain_dirty_3, read_dirty_4, load_dirty_4, datain_dirty_4,
    output logic dirtymux_out,
    input logic read_tag_1, load_tag_1, read_tag_2, load_tag_2, read_tag_3, load_tag_3, read_tag_4, load_tag_4,
    input logic read_data_1, read_data_2, read_data_3, read_data_4,
    output logic hit1, hit2, hit3, hit4,
    input logic [255:0] pmem_rdata,
    input logic update, write_back, write_data
);
 
logic [(26-s_index):0] tag;
logic [(s_index-1):0] index;
logic [s_offset-1:0] offset;
assign tag = mem_address[31:(5+s_index)];
assign index = mem_address[(5+s_index-1):5];
assign offset = mem_address[s_offset-1:0];
logic [255:0] mem_rdata256_1, mem_rdata256_2, mem_rdata256_3, mem_rdata256_4, mem_wdata256_in;
logic [31:0] mem_byte_enable256_1, mem_byte_enable256_2, mem_byte_enable256_3, mem_byte_enable256_4;
logic [(26-s_index):0] pmem_address_tag;
logic [(26-s_index):0] dataout_tag_1, dataout_tag_2, dataout_tag_3, dataout_tag_4;
logic dataout_valid_1, dataout_valid_2, dataout_valid_3, dataout_valid_4;
logic dataout_dirty_1, dataout_dirty_2, dataout_dirty_3, dataout_dirty_4;

assign hit1 = (dataout_tag_1 == tag) && (dataout_valid_1) && (mem_read || mem_write);
assign hit2 = (dataout_tag_2 == tag) && (dataout_valid_2) && (mem_read || mem_write);
assign hit3 = (dataout_tag_3 == tag) && (dataout_valid_3) && (mem_read || mem_write);
assign hit4 = (dataout_tag_4 == tag) && (dataout_valid_4) && (mem_read || mem_write);
/*
array LRU_array(
    .clk     (clk),
    .rst     (rst),
    .read    (read_LRU),
    .load    (load_LRU),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_LRU),
    .dataout (dataout_LRU)
);
*/
array #(s_index, 3) LRU_array(
    .clk     (clk),
    .rst     (rst),
    .read    (read_LRU),
    .load    (load_LRU),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_LRU),
    .dataout (dataout_LRU)
);

array #(s_index, 1) valid_array_1(
    .clk     (clk),
    .rst     (rst),
    .read    (read_valid_1),
    .load    (load_valid_1),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_valid_1),
    .dataout (dataout_valid_1)
);

array #(s_index, 1) valid_array_2(
    .clk     (clk),
    .rst     (rst),
    .read    (read_valid_2),
    .load    (load_valid_2),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_valid_2),
    .dataout (dataout_valid_2)
);

array #(s_index, 1) valid_array_3(
    .clk     (clk),
    .rst     (rst),
    .read    (read_valid_3),
    .load    (load_valid_3),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_valid_3),
    .dataout (dataout_valid_3)
);

array #(s_index, 1) valid_array_4(
    .clk     (clk),
    .rst     (rst),
    .read    (read_valid_4),
    .load    (load_valid_4),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_valid_4),
    .dataout (dataout_valid_4)
);

array #(s_index, 1) dirty_array_1(
    .clk     (clk),
    .rst     (rst),
    .read    (read_dirty_1),
    .load    (load_dirty_1),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_dirty_1),
    .dataout (dataout_dirty_1)
);

array #(s_index, 1) dirty_array_2(
    .clk     (clk),
    .rst     (rst),
    .read    (read_dirty_2),
    .load    (load_dirty_2),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_dirty_2),
    .dataout (dataout_dirty_2)
);

array #(s_index, 1) dirty_array_3(
    .clk     (clk),
    .rst     (rst),
    .read    (read_dirty_3),
    .load    (load_dirty_3),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_dirty_3),
    .dataout (dataout_dirty_3)
);

array #(s_index, 1) dirty_array_4(
    .clk     (clk),
    .rst     (rst),
    .read    (read_dirty_4),
    .load    (load_dirty_4),
    .rindex  (index),
    .windex  (index),
    .datain  (datain_dirty_4),
    .dataout (dataout_dirty_4)
);

array #(s_index, (26-s_index+1)) tag_array_1(
    .clk     (clk),
    .rst     (rst),
    .read    (read_tag_1),
    .load    (load_tag_1),
    .rindex  (index),
    .windex  (index),
    .datain  (tag),
    .dataout (dataout_tag_1)
);

array #(s_index, (26-s_index+1)) tag_array_2(
    .clk     (clk),
    .rst     (rst),
    .read    (read_tag_2),
    .load    (load_tag_2),
    .rindex  (index),
    .windex  (index),
    .datain  (tag),
    .dataout (dataout_tag_2)
);

array #(s_index, (26-s_index+1)) tag_array_3(
    .clk     (clk),
    .rst     (rst),
    .read    (read_tag_3),
    .load    (load_tag_3),
    .rindex  (index),
    .windex  (index),
    .datain  (tag),
    .dataout (dataout_tag_3)
);

array #(s_index, (26-s_index+1)) tag_array_4(
    .clk     (clk),
    .rst     (rst),
    .read    (read_tag_4),
    .load    (load_tag_4),
    .rindex  (index),
    .windex  (index),
    .datain  (tag),
    .dataout (dataout_tag_4)
);

data_array #(s_offset, s_index) data_array_1(
    .clk      (clk),
    .read     (read_data_1),
    .write_en (mem_byte_enable256_1),
    .rindex   (index),
    .windex   (index),
    .datain   (mem_wdata256_in),
    .dataout  (mem_rdata256_1)
);

data_array #(s_offset, s_index) data_array_2(
    .clk      (clk),
    .read     (read_data_2),
    .write_en (mem_byte_enable256_2),
    .rindex   (index),
    .windex   (index),
    .datain   (mem_wdata256_in),
    .dataout  (mem_rdata256_2)
);

data_array #(s_offset, s_index) data_array_3(
    .clk      (clk),
    .read     (read_data_3),
    .write_en (mem_byte_enable256_3),
    .rindex   (index),
    .windex   (index),
    .datain   (mem_wdata256_in),
    .dataout  (mem_rdata256_3)
);

data_array #(s_offset, s_index) data_array_4(
    .clk      (clk),
    .read     (read_data_4),
    .write_en (mem_byte_enable256_4),
    .rindex   (index),
    .windex   (index),
    .datain   (mem_wdata256_in),
    .dataout  (mem_rdata256_4)
);

always_comb begin : dirty_mux
	if (dataout_LRU[2]) begin
		if (dataout_LRU[0]) begin
			dirtymux_out = dataout_dirty_4;
		end else begin
			dirtymux_out = dataout_dirty_3;
		end
	end else begin
		if (dataout_LRU[1]) begin
			dirtymux_out = dataout_dirty_2;
		end else begin
			dirtymux_out = dataout_dirty_1;
		end
	end
end

always_comb begin : MUXES
    unique case ({hit1, hit2, hit3, hit4})
        4'b0001: mem_rdata256 = mem_rdata256_4;
        4'b0010: mem_rdata256 = mem_rdata256_3;
	4'b0100: mem_rdata256 = mem_rdata256_2;
	4'b1000: mem_rdata256 = mem_rdata256_1;
	default: begin
		if (dataout_LRU[2]) begin
			if (dataout_LRU[0]) begin
				mem_rdata256 = mem_rdata256_4;
			end else begin
				mem_rdata256 = mem_rdata256_3;
			end
		end else begin
			if (dataout_LRU[1]) begin
				mem_rdata256 = mem_rdata256_2;
			end else begin
				mem_rdata256 = mem_rdata256_1;
			end
		end
	end
    endcase

    unique case (write_back)
        1'b0: begin
            pmem_address = {mem_address[31:5], 5'b0};
        end
        1'b1: begin
            pmem_address = {pmem_address_tag, index, 5'b0};
        end
    default: pmem_address = {mem_address[31:5], 5'b0};
    endcase

	
	unique case({update, write_data})
        2'b01: begin 
            mem_wdata256_in = mem_wdata256;
		case ({hit1, hit2, hit3, hit4})
			4'b0001: begin
				mem_byte_enable256_1 = 32'b0;
				mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = mem_byte_enable256;
			end
			4'b0010: begin
				mem_byte_enable256_1 = 32'b0;
				mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = mem_byte_enable256;
				mem_byte_enable256_4 = 32'b0;
			end
			4'b0100: begin
				mem_byte_enable256_1 = 32'b0;
				mem_byte_enable256_2 = mem_byte_enable256;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = 32'b0;
			end
			4'b1000: begin
				mem_byte_enable256_1 = mem_byte_enable256;
				mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = 32'b0;
			end
			default: begin
				mem_byte_enable256_1 = 32'b0;
        			mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = 32'b0;
			end
		endcase
		end
	2'b10: begin
		mem_wdata256_in = pmem_rdata;
		if (dataout_LRU[2]) begin
			if (dataout_LRU[0]) begin
				mem_byte_enable256_1 = 32'b0;
        			mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = 32'hFFFFFFFF;
			end else begin
				mem_byte_enable256_1 = 32'b0;
        			mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = 32'hFFFFFFFF;
				mem_byte_enable256_4 = 32'b0;
			end
		end else begin
			if (dataout_LRU[1]) begin
				mem_byte_enable256_1 = 32'b0;
        			mem_byte_enable256_2 = 32'hFFFFFFFF;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = 32'b0;
			end else begin
				mem_byte_enable256_1 = 32'hFFFFFFFF;
        			mem_byte_enable256_2 = 32'b0;
				mem_byte_enable256_3 = 32'b0;
				mem_byte_enable256_4 = 32'b0;
			end
		end
		
		end
	default: begin
		mem_wdata256_in = mem_wdata256;
		mem_byte_enable256_1 = 32'b0;
        	mem_byte_enable256_2 = 32'b0;
		mem_byte_enable256_3 = 32'b0;
		mem_byte_enable256_4 = 32'b0;
	end
	endcase

end

always_comb begin : pmem_address_tag_mux
	if (dataout_LRU[2]) begin
		if (dataout_LRU[0]) begin
			pmem_address_tag = dataout_tag_4;
		end else begin
			pmem_address_tag = dataout_tag_3;
		end
	end else begin
		if (dataout_LRU[1]) begin
			pmem_address_tag = dataout_tag_2;
		end else begin
			pmem_address_tag = dataout_tag_1;
		end
	end
end

endmodule : cache_datapath
