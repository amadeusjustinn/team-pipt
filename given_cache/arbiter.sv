module arbiter
import rv32i_types::*;
(
    input clk,
    input rst,

    // From cacheline adaptor
    input adaptor_resp,
    input [255:0] line_resp,

    // From data cache
    input pmem_read_dcache,
    input pmem_write_dcache,
    input [31:0] address_i_dcache,
    input [255:0] line_i_dcache,

    // From instruction cache
    input pmem_read_icache,
    input pmem_write_icache,
    input [31:0] address_i_icache,
    input [255:0] line_i_icache,

    // To cacheline adaptor
    output logic pmem_read,
    output logic pmem_write,
    output logic [31:0] address_i,
    output logic [255:0] line_i,

    // To data cache
    output logic pmem_resp_dcache,
    output logic [255:0] line_o_dcache,

    // To instruction cache
    output logic pmem_resp_icache,
    output logic [255:0] line_o_icache
);
    logic dcache_or, icache_or;
    assign dcache_or = pmem_read_dcache || pmem_write_dcache;
    assign icache_or = pmem_read_icache || pmem_write_icache;

    enum int unsigned {
        idle = 0,
        dcache = 1,
        icache = 2
    } state, next_states;

    function set_defaults();
        pmem_read = 1'b0;
        pmem_write = 1'b0;
        address_i = 32'b0;
        line_i = 256'b0;

        pmem_resp_dcache = 1'b0;
        line_o_dcache = 256'b0;
        pmem_resp_icache = 1'b0;
        line_o_icache = 256'b0;
    endfunction

    always_comb begin: state_actions
        set_defaults();

        unique case (state)
            idle:;
            dcache: begin
                pmem_read = pmem_read_dcache;
                pmem_write = pmem_write_dcache;
                address_i = address_i_dcache;
                line_i = line_i_dcache;

                pmem_resp_dcache = adaptor_resp;
                line_o_dcache = line_resp;
            end
            icache: begin
                pmem_read = pmem_read_icache;
                pmem_write = pmem_write_icache;
                address_i = address_i_icache;
                line_i = line_i_icache;

                pmem_resp_icache = adaptor_resp;
                line_o_icache = line_resp;
            end
        endcase
    end

    always_comb begin: next_state_logic
        unique case (state)
            idle: begin
				if (dcache_or) begin
					 next_states = dcache;
				end else if (icache_or) begin
					next_states = icache;
                end else begin
					next_states = idle;
				end
            end
            dcache: begin
                if (adaptor_resp && icache_or) begin
                    next_states = icache;
                end else if (adaptor_resp) begin
					next_states = idle;
                end else begin
					next_states = dcache;
				end
            end
            icache: begin
                if (adaptor_resp && dcache_or) begin
                    next_states = dcache;
                end else if (adaptor_resp) begin
					next_states = idle;
                end else begin
					next_states = icache;
				end
            end
        endcase
    end

    always_ff @(posedge clk) begin: next_state_asssignment
        if (~rst) state <= next_states;
        else state <= state;
    end

endmodule: arbiter
