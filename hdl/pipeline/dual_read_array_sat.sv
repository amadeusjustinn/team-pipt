/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER.
A register array to be used for tag arrays, LRU array, etc. */

module dual_read_array_sat #(
    parameter s_index = 3,
    parameter width = 2
)
(
    clk,
    rst,
    read,
    load,
    IF_rindex,
    EX_rindex,
    windex,
    datain,
    IF_dataout,
    EX_dataout
);

localparam num_sets = 2**s_index;

input clk;
input rst;
input read;
input load;
input [s_index-1:0] IF_rindex;
input [s_index-1:0] EX_rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] IF_dataout;
output logic [width-1:0] EX_dataout;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;
logic [width-1:0] _dataout_IF, _dataout_EX;
assign IF_dataout = _dataout_IF;
assign EX_dataout = _dataout_EX;

always_comb begin
    if(read) begin
	    _dataout_IF = data[IF_rindex];
	    _dataout_EX = data[EX_rindex];
	end
    else begin
        _dataout_IF = '0;
	_dataout_EX = '0;
    end
end

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= 2'b01;
    end
    else begin
        if(load)
            data[windex] <= datain;
    end
end

endmodule : dual_read_array_sat
