/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic [31:0] mem_byte_enable256;
logic [255:0] mem_rdata256;
assign pmem_wdata = mem_rdata256;
logic read_LRU, load_LRU; 
logic [2:0] datain_LRU, dataout_LRU;
logic read_valid_1, load_valid_1, datain_valid_1, read_valid_2, load_valid_2, datain_valid_2, read_valid_3, load_valid_3, datain_valid_3, read_valid_4, load_valid_4, datain_valid_4;
logic read_dirty_1, load_dirty_1, datain_dirty_1, read_dirty_2, load_dirty_2, datain_dirty_2, read_dirty_3, load_dirty_3, datain_dirty_3, read_dirty_4, load_dirty_4, datain_dirty_4, dirtymux_out;
logic read_tag_1, load_tag_1, read_tag_2, load_tag_2, read_tag_3, load_tag_3, read_tag_4, load_tag_4;
logic read_data_1, read_data_2, read_data_3, read_data_4;
logic hit1, hit2, hit3, hit4;
logic update, write_back, write_data;
logic [255:0] mem_wdata256;

cache_control control
(
    .clk                (clk),
    .rst                (rst),
    .mem_resp           (mem_resp),
    .mem_read           (mem_read),
    .mem_write          (mem_write),
    .pmem_read          (pmem_read),
    .pmem_write         (pmem_write),
    .pmem_resp          (pmem_resp),
    .read_LRU           (read_LRU),
    .load_LRU           (load_LRU),
    .datain_LRU         (datain_LRU),
    .dataout_LRU        (dataout_LRU),
    .read_valid_1       (read_valid_1), 
    .load_valid_1       (load_valid_1), 
    .datain_valid_1     (datain_valid_1), 
    .read_valid_2       (read_valid_2), 
    .load_valid_2       (load_valid_2), 
    .datain_valid_2     (datain_valid_2),  
    .read_valid_3       (read_valid_3), 
    .load_valid_3       (load_valid_3), 
    .datain_valid_3     (datain_valid_3), 
    .read_valid_4       (read_valid_4), 
    .load_valid_4       (load_valid_4), 
    .datain_valid_4     (datain_valid_4), 
    .read_dirty_1       (read_dirty_1), 
    .load_dirty_1       (load_dirty_1), 
    .datain_dirty_1     (datain_dirty_1), 
    .read_dirty_2       (read_dirty_2), 
    .load_dirty_2       (load_dirty_2), 
    .datain_dirty_2     (datain_dirty_2),
    .read_dirty_3       (read_dirty_3), 
    .load_dirty_3       (load_dirty_3), 
    .datain_dirty_3     (datain_dirty_3), 
    .read_dirty_4       (read_dirty_4), 
    .load_dirty_4       (load_dirty_4), 
    .datain_dirty_4     (datain_dirty_4), 
    .dirtymux_out       (dirtymux_out),
    .read_tag_1         (read_tag_1), 
    .load_tag_1         (load_tag_1), 
    .read_tag_2         (read_tag_2), 
    .load_tag_2         (load_tag_2),
    .read_tag_3         (read_tag_3), 
    .load_tag_3         (load_tag_3),
    .read_tag_4         (read_tag_4), 
    .load_tag_4         (load_tag_4),
    .read_data_1        (read_data_1), 
    .read_data_2        (read_data_2),
    .read_data_3        (read_data_3),
    .read_data_4        (read_data_4),
    .hit1               (hit1), 
    .hit2               (hit2),
    .hit3               (hit3), 
    .hit4               (hit4),
    .update             (update),
    .write_back         (write_back),
    .write_data         (write_data)
);

cache_datapath datapath
(
    .clk                (clk),
    .rst                (rst),
    .mem_read           (mem_read),
    .mem_write          (mem_write),
    .mem_wdata256       (mem_wdata256),
    .mem_rdata256       (mem_rdata256),
    .mem_byte_enable256 (mem_byte_enable256),
    .mem_address        (mem_address),
    .pmem_address       (pmem_address),
    .pmem_rdata         (pmem_rdata),
    .read_LRU           (read_LRU),
    .load_LRU           (load_LRU),
    .datain_LRU         (datain_LRU),
    .dataout_LRU        (dataout_LRU),
    .read_valid_1       (read_valid_1), 
    .load_valid_1       (load_valid_1), 
    .datain_valid_1     (datain_valid_1), 
    .read_valid_2       (read_valid_2), 
    .load_valid_2       (load_valid_2), 
    .datain_valid_2     (datain_valid_2), 
    .read_valid_3       (read_valid_3), 
    .load_valid_3       (load_valid_3), 
    .datain_valid_3     (datain_valid_3), 
    .read_valid_4       (read_valid_4), 
    .load_valid_4       (load_valid_4), 
    .datain_valid_4     (datain_valid_4), 
    .read_dirty_1       (read_dirty_1), 
    .load_dirty_1       (load_dirty_1), 
    .datain_dirty_1     (datain_dirty_1), 
    .read_dirty_2       (read_dirty_2), 
    .load_dirty_2       (load_dirty_2), 
    .datain_dirty_2     (datain_dirty_2),
    .read_dirty_3       (read_dirty_3), 
    .load_dirty_3       (load_dirty_3), 
    .datain_dirty_3     (datain_dirty_3),
    .read_dirty_4       (read_dirty_4), 
    .load_dirty_4       (load_dirty_4), 
    .datain_dirty_4     (datain_dirty_4),
    .dirtymux_out       (dirtymux_out),
    .read_tag_1         (read_tag_1), 
    .load_tag_1         (load_tag_1), 
    .read_tag_2         (read_tag_2), 
    .load_tag_2         (load_tag_2),
    .read_tag_3         (read_tag_3), 
    .load_tag_3         (load_tag_3),
    .read_tag_4         (read_tag_4), 
    .load_tag_4         (load_tag_4),
    .read_data_1        (read_data_1), 
    .read_data_2        (read_data_2),
    .read_data_3        (read_data_3), 
    .read_data_4        (read_data_4),
    .hit1               (hit1), 
    .hit2               (hit2),
    .hit3               (hit3),
    .hit4               (hit4),
    .update             (update),
    .write_back         (write_back),
    .write_data         (write_data)
);

bus_adapter bus_adapter
(
    .mem_wdata256       (mem_wdata256),
    .mem_rdata256       (mem_rdata256),
    .mem_wdata          (mem_wdata),
    .mem_rdata          (mem_rdata),
    .mem_byte_enable    (mem_byte_enable),
    .mem_byte_enable256 (mem_byte_enable256),
    .address            (mem_address)
);

endmodule : cache
