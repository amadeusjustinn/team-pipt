/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst,
    output logic mem_resp,
    input logic mem_read,
    input logic mem_write,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp,
    output logic read_LRU, load_LRU,
    output logic [2:0] datain_LRU,
    input logic [2:0] dataout_LRU,
    output logic read_valid_1, load_valid_1, datain_valid_1, read_valid_2, load_valid_2, datain_valid_2, read_valid_3, load_valid_3, datain_valid_3, read_valid_4, load_valid_4, datain_valid_4,
    output logic read_dirty_1, load_dirty_1, datain_dirty_1, read_dirty_2, load_dirty_2, datain_dirty_2, read_dirty_3, load_dirty_3, datain_dirty_3, read_dirty_4, load_dirty_4, datain_dirty_4,
    input logic dirtymux_out,
    output logic read_tag_1, load_tag_1, read_tag_2, load_tag_2, read_tag_3, load_tag_3, read_tag_4, load_tag_4,
    output logic read_data_1, read_data_2, read_data_3, read_data_4,
    input logic hit1, hit2, hit3, hit4,
    output logic update, write_back, write_data
);

enum int unsigned {
    /* List of states */
    checkForHit     = 0,
    miss            = 1,
    updateCache     = 2
} state, next_states;
 
function void set_defaults();
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    read_LRU = 1'b0;
    load_LRU = 1'b0;
    datain_LRU = 3'b000;
    read_valid_1 = 1'b0; 
    load_valid_1 = 1'b0; 
    datain_valid_1 = 1'b0; 
    read_valid_2 = 1'b0; 
    load_valid_2 = 1'b0;
    datain_valid_2 = 1'b0;
    read_valid_3 = 1'b0; 
    load_valid_3 = 1'b0;
    datain_valid_3 = 1'b0;
    read_valid_4 = 1'b0; 
    load_valid_4 = 1'b0;
    datain_valid_4 = 1'b0;
    read_dirty_1 = 1'b0; 
    load_dirty_1 = 1'b0; 
    datain_dirty_1 = 1'b0; 
    read_dirty_2 = 1'b0; 
    load_dirty_2 = 1'b0; 
    datain_dirty_2 = 1'b0;
    read_dirty_3 = 1'b0; 
    load_dirty_3 = 1'b0; 
    datain_dirty_3 = 1'b0;
    read_dirty_4 = 1'b0; 
    load_dirty_4 = 1'b0; 
    datain_dirty_4 = 1'b0;
    read_tag_1 = 1'b0; 
    load_tag_1 = 1'b0; 
    read_tag_2 = 1'b0; 
    load_tag_2 = 1'b0;
    read_tag_3 = 1'b0; 
    load_tag_3 = 1'b0;
    read_tag_4 = 1'b0; 
    load_tag_4 = 1'b0;
    read_data_1 = 1'b0; 
    read_data_2 = 1'b0;
    read_data_3 = 1'b0;
    read_data_4 = 1'b0;
    update = 1'b0;
    write_back = 1'b0;
    write_data = 1'b0;
endfunction

always_comb
begin : state_actions
    set_defaults();
    case (state)
        checkForHit : begin
            read_valid_1 = 1'b1;
            read_valid_2 = 1'b1;
	    read_valid_3 = 1'b1;
	    read_valid_4 = 1'b1;
            read_tag_1 = 1'b1;
            read_tag_2 = 1'b1;
            read_tag_3 = 1'b1;
            read_tag_4 = 1'b1;
            read_dirty_1 = 1'b1;
            read_dirty_2 = 1'b1;
            read_dirty_3 = 1'b1;
            read_dirty_4 = 1'b1;
            read_LRU = 1'b1;
            if (mem_read || mem_write) begin
                if (hit1) begin
                    load_LRU = 1'b1;
                    datain_LRU = (dataout_LRU | 3'b100) | 3'b010;
                    mem_resp = 1'b1;
                    if (mem_read) begin
                        read_data_1 = 1'b1;
                        read_data_2 = 1'b1;
			read_data_3 = 1'b1;
			read_data_4 = 1'b1;
                    end else begin
                        load_dirty_1 = 1'b1;
                        datain_dirty_1 = 1'b1;
                        write_data = 1'b1;
                    end
                end else if (hit2) begin
                    load_LRU = 1'b1;
                    datain_LRU = (dataout_LRU | 3'b100) & 3'b101;
                    mem_resp = 1'b1;
                    if (mem_read) begin
                        read_data_1 = 1'b1;
                        read_data_2 = 1'b1;
			read_data_3 = 1'b1;
			read_data_4 = 1'b1;
                    end else begin
                        load_dirty_2 = 1'b1;
                        datain_dirty_2 = 1'b1;
                        write_data = 1'b1;
                    end
                end else if (hit3) begin
                    load_LRU = 1'b1;
                    datain_LRU = (dataout_LRU & 3'b011) | 3'b001;
                    mem_resp = 1'b1;
                    if (mem_read) begin
                        read_data_1 = 1'b1;
                        read_data_2 = 1'b1;
			read_data_3 = 1'b1;
			read_data_4 = 1'b1;
                    end else begin
                        load_dirty_3 = 1'b1;
                        datain_dirty_3 = 1'b1;
                        write_data = 1'b1;
                    end
                end else if (hit4) begin
                    load_LRU = 1'b1;
                    datain_LRU = (dataout_LRU & 3'b011) & 3'b110;
                    mem_resp = 1'b1;
                    if (mem_read) begin
                        read_data_1 = 1'b1;
                        read_data_2 = 1'b1;
			read_data_3 = 1'b1;
			read_data_4 = 1'b1;
                    end else begin
                        load_dirty_4 = 1'b1;
                        datain_dirty_4 = 1'b1;
                        write_data = 1'b1;
                    end
                end else begin
		    load_LRU = 1'b0;
		    mem_resp = 1'b0;
		end
            end
        end
        miss : begin
            read_valid_1 = 1'b1;
            read_valid_2 = 1'b1;
	    read_valid_3 = 1'b1;
	    read_valid_4 = 1'b1;
            read_tag_1 = 1'b1;
            read_tag_2 = 1'b1;
            read_tag_3 = 1'b1;
            read_tag_4 = 1'b1;
            read_dirty_1 = 1'b1;
            read_dirty_2 = 1'b1;
            read_dirty_3 = 1'b1;
            read_dirty_4 = 1'b1;
            read_LRU = 1'b1;
            read_data_1 = 1'b1;
            read_data_2 = 1'b1;
            read_data_3 = 1'b1;
            read_data_4 = 1'b1;
            if (dirtymux_out) begin
                write_back = 1'b1;
                pmem_write = 1'b1;
            end
        end
        updateCache : begin
            read_valid_1 = 1'b1;
            read_valid_2 = 1'b1;
            read_valid_3 = 1'b1;
            read_valid_4 = 1'b1;
            read_tag_1 = 1'b1;
            read_tag_2 = 1'b1;
            read_tag_3 = 1'b1;
            read_tag_4 = 1'b1;
            read_dirty_1 = 1'b1;
            read_dirty_2 = 1'b1;
            read_dirty_3 = 1'b1;
            read_dirty_4 = 1'b1;
            read_LRU = 1'b1;
            read_data_1 = 1'b1;
            read_data_2 = 1'b1;
            read_data_3 = 1'b1;
            read_data_4 = 1'b1;
            pmem_read = 1'b1;
            update = 1'b1;
	    if (dataout_LRU[2]) begin
			if (dataout_LRU[0]) begin
				load_tag_4 = 1'b1;
                		load_dirty_4 = 1'b1;
                		datain_dirty_4 = 1'b0;
                		load_valid_4 = 1'b1;
                		datain_valid_4 = 1'b1;
			end else begin
				load_tag_3 = 1'b1;
                		load_dirty_3 = 1'b1;
                		datain_dirty_3 = 1'b0;
                		load_valid_3 = 1'b1;
                		datain_valid_3 = 1'b1;
			end
	   end else begin
			if (dataout_LRU[1]) begin
				load_tag_2 = 1'b1;
                		load_dirty_2 = 1'b1;
                		datain_dirty_2 = 1'b0;
                		load_valid_2 = 1'b1;
                		datain_valid_2 = 1'b1;
			end else begin
				load_tag_1 = 1'b1;
                		load_dirty_1 = 1'b1;
                		datain_dirty_1 = 1'b0;
                		load_valid_1 = 1'b1;
                		datain_valid_1 = 1'b1;
			end
	   end
        end
    endcase
end

always_comb
begin : next_state_logic
    case (state)
        checkForHit : begin
            if ((mem_read || mem_write) && (!(hit1 || hit2 || hit3 || hit4))) begin
                next_states = miss;
            end else begin
                next_states = checkForHit;
            end
        end
        miss : begin
            if ((dirtymux_out == 1'b1) && (pmem_resp == 1'b0)) begin
                next_states = miss;
            end else begin
                next_states = updateCache;
            end
        end
        updateCache : begin
            if (pmem_resp == 1'b0) begin
                next_states = updateCache;
            end else begin
                next_states = checkForHit;
            end
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) begin
        state <= checkForHit;
    end
    else begin
        state <= next_states;
    end
end

endmodule : cache_control
