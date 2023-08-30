
module cmp
import rv32i_types::*;
(
    input branch_funct3_t cmpop,
    input [31:0] a, b,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq : br_en = a == b ? 1'b1 : 1'b0;
        bne : br_en = a != b ? 1'b1 : 1'b0;
        bge : begin
            case ({a[31], b[31]})
                2'b00 : br_en = a >= b ? 1'b1 : 1'b0; // Both positive
                2'b01 : br_en = 1'b1;                // A positive, B negative
                2'b10 : br_en = 1'b0;                // A negative, B positive
                2'b11 : br_en = a >= b ? 1'b1 : 1'b0; // Both negative
            endcase
        end
        blt : begin
            case ({a[31], b[31]})
                2'b00 : br_en = a < b ? 1'b1 : 1'b0; // Both positive
                2'b01 : br_en = 1'b0;                // A positive, B negative
                2'b10 : br_en = 1'b1;                // A negative, B positive
                2'b11 : br_en = a < b ? 1'b1 : 1'b0; // Both negative
            endcase
        end
        bltu : br_en = a < b ? 1'b1 : 1'b0;
        bgeu : br_en = a >= b ? 1'b1 : 1'b0;
	default: br_en = '0;
    endcase
end

endmodule : cmp
