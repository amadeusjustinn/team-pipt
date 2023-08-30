module pc_register_comb #(parameter width = 32)
(
    input clk,
    input rst,
    input load,
    input [width-1:0] in,
    output logic [width-1:0] out
);

/*
* PC needs to start at 0x60
 */
logic [width-1:0] data;
logic [127:0] counter;
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= 32'h00000060;
	counter <= '0;
    end
    else if (load)
    begin
        data <= in;
	if (in != data) begin
		counter <= counter + 1;
	end
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    if (load) begin
	out = in;
    end else begin
        out = data;
    end
end

endmodule : pc_register_comb
