module mp3
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);
logic [255:0] pmem_rdata256, pmem_wdata256;
logic [31:0] pmem_address_in, mem_address;
logic pmem_read_i, pmem_write_i, pmem_resp_o, mem_resp, mem_read, mem_write;
logic [31:0] mem_rdata, mem_wdata;
logic [3:0] mem_byte_enable;
// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(.*);

// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk             (clk),
    .rst             (rst),
    .mem_address     (mem_address),
    .mem_rdata       (mem_rdata),
    .mem_wdata       (mem_wdata),
    .mem_read        (mem_read),
    .mem_write       (mem_write),
    .mem_byte_enable (mem_byte_enable),
    .mem_resp        (mem_resp),
    .pmem_address    (pmem_address_in),
    .pmem_rdata      (pmem_rdata256),
    .pmem_wdata      (pmem_wdata256),
    .pmem_read       (pmem_read_i),
    .pmem_write      (pmem_write_i),
    .pmem_resp       (pmem_resp_o)
);

// Hint: What do you need to interface between cache and main memory?
cacheline_adaptor cacheline_adaptor(
    .clk       (clk),
    .reset_n   (~rst),
    .line_i    (pmem_wdata256),
    .line_o    (pmem_rdata256),
    .address_i (pmem_address_in),
    .read_i    (pmem_read_i),
    .write_i   (pmem_write_i),
    .resp_o    (pmem_resp_o),        // 1 When cacheline is done reading or writing
    .burst_i   (pmem_rdata),
    .burst_o   (pmem_wdata),
    .address_o (pmem_address),
    .read_o    (pmem_read),
    .write_o   (pmem_write),
    .resp_i    (pmem_resp)
);
endmodule : mp3
