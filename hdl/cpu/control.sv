
module control
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic mem_resp,
    input [1:0] mem_address_shift,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output branch_funct3_t cmpop
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = '0;
    rmask = '0;
    wmask = '0;
 
    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = '1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << mem_address_shift[1:0] /* Modify for MP1 Final */ ;
                lb, lbu: rmask = 4'b0001 << mem_address_shift[1:0] /* Modify for MP1 Final */ ;
                default: trap = '1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << mem_address_shift[1:0] /* Modify for MP1 Final */ ;
                sb: wmask = 4'b0001 << mem_address_shift[1:0] /* Modify for MP1 Final */ ;
                default: trap = '1;
            endcase
        end

        default: trap = '1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
    fetch1          = 0,
    fetch2          = 1,
    fetch3          = 2,
    decode          = 3,
    load_calc_addr  = 4,
    load_ldr1       = 5,
    load_ldr2       = 6,
    store_calc_addr = 7,
    store_str1      = 8,
    store_str2      = 9,
    arith_reg_imm   = 10,
    arith_reg_reg   = 11,
    branch          = 12,
    jal             = 13,
    jalr            = 14,
    lui             = 15,
    auipc           = 16
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    cmpmux_sel = cmpmux::rs2_out;
    marmux_sel = marmux::pc_out;
    aluop = alu_ops'(funct3);
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b0000;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    load_regfile = 1'b1;
    regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    load_mar = 1'b1;
    marmux_sel = sel;
endfunction

function void loadMDR();
    load_mdr = 1'b1;
endfunction

function void loadIR();
    load_ir = 1'b1;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    /* Student code here */
    alumux1_sel = sel1;
    alumux2_sel = sel2;
    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    cmpmux_sel = sel;
    cmpop = op;
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case (state)
        fetch1 : begin
            loadMAR(marmux::pc_out);
        end
        fetch2 : begin
            loadMDR();
            mem_read = 1'b1;
        end
        fetch3 : begin
            loadIR();
        end
        decode : begin
            set_defaults();
        end
        // LW
        load_calc_addr : begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
        end
        load_ldr1 : begin
            loadMDR();
            mem_read = 1'b1;
        end
        load_ldr2 : begin
            case (load_funct3)
                lw : loadRegfile(regfilemux::lw);
                lb : loadRegfile(regfilemux::lb);
                lbu : loadRegfile(regfilemux::lbu);
                lh : loadRegfile(regfilemux::lh);
                lhu : loadRegfile(regfilemux::lhu);
            endcase
            loadPC(pcmux::pc_plus4);
        end
        // SW
        store_calc_addr : begin
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            load_data_out = 1'b1;
            mem_byte_enable = wmask;
        end
        store_str1 : begin
            mem_byte_enable = wmask;
            mem_write = 1'b1;
        end
        store_str2 : begin
            loadPC(pcmux::pc_plus4);
        end
        // Arithmetic register-immediate
        arith_reg_imm : begin
            case (arith_funct3)
                add : begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                    loadRegfile(regfilemux::alu_out);
                end
                sll : begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sll);
                    loadRegfile(regfilemux::alu_out);
                end
                slt : begin
                    setCMP(cmpmux::i_imm, blt);
                    loadRegfile(regfilemux::br_en);
                end
                sltu : begin
                    setCMP(cmpmux::i_imm, bltu);
                    loadRegfile(regfilemux::br_en);
                end
                axor : begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_xor);
                    loadRegfile(regfilemux::alu_out);
                end
                sr : begin
                    case (funct7[5])
                        1'b0 : setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                        1'b1 : setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                    endcase
                    loadRegfile(regfilemux::alu_out);
                end
                aor : begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_or);
                    loadRegfile(regfilemux::alu_out);
                end
                aand : begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_and);
                    loadRegfile(regfilemux::alu_out);
                end
            endcase
            loadPC(pcmux::pc_plus4);
        end
        // Arithmetic register-register
        arith_reg_reg : begin
            case (arith_funct3)
                add : begin
                    case (funct7[5])
                        1'b0 : setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
                        1'b1 : setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                    endcase
                    loadRegfile(regfilemux::alu_out);
                end
                sll : begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sll);
                    loadRegfile(regfilemux::alu_out);
                end
                slt : begin
                    setCMP(cmpmux::rs2_out, blt);
                    loadRegfile(regfilemux::br_en);
                end
                sltu : begin
                    setCMP(cmpmux::rs2_out, bltu);
                    loadRegfile(regfilemux::br_en);
                end
                axor : begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_xor);
                    loadRegfile(regfilemux::alu_out);
                end
                sr : begin
                    case (funct7[5])
                        1'b0 : setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                        1'b1 : setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                    endcase
                    loadRegfile(regfilemux::alu_out);
                end
                aor : begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_or);
                    loadRegfile(regfilemux::alu_out);
                end
                aand : begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_and);
                    loadRegfile(regfilemux::alu_out);
                end
            endcase
			loadPC(pcmux::pc_plus4);
        end
        // Branch
        branch : begin
            setCMP(cmpmux::rs2_out, branch_funct3);
            if (br_en) begin
                setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
                loadPC(pcmux::alu_out);
            end
            else begin
                loadPC(pcmux::pc_plus4);
            end
        end
        // Unconditional Jump
        jal : begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
            loadPC(pcmux::alu_out);
        end
        jalr : begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadPC(pcmux::alu_mod2);
        end
        // LUI
        lui : begin
            loadRegfile(regfilemux::u_imm);
            loadPC(pcmux::pc_plus4);
        end
        // AUIPC
        auipc : begin
            setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
        end
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    case (state)
        fetch1 : next_states = fetch2;
        fetch2 : begin
            if (mem_resp) begin
                next_states = fetch3;
            end
            else begin
                next_states = fetch2;
            end
        end
        fetch3 : next_states = decode;
        decode : begin
            case (opcode)
                op_load : next_states = load_calc_addr;
                op_store : next_states = store_calc_addr;
                op_lui : next_states = lui;
                op_auipc : next_states = auipc;
                op_imm : next_states = arith_reg_imm;
                op_reg : next_states = arith_reg_reg;
                op_br : next_states = branch;
                op_jal : next_states = jal;
                op_jalr : next_states = jalr;
            endcase
        end
        // Load
        load_calc_addr : next_states = load_ldr1;
        load_ldr1 : begin
            if (mem_resp) begin
                next_states = load_ldr2;
            end
            else begin
                next_states = load_ldr1;
            end
        end
        load_ldr2 : next_states = fetch1;
        // Store
        store_calc_addr : next_states = store_str1;
        store_str1 : begin
            if (mem_resp) begin
                next_states = store_str2;
            end
            else begin
                next_states = store_str1;
            end
        end
        store_str2 : next_states = fetch1;
        // Arithmetic register-immediate
        arith_reg_imm : next_states = fetch1;
        // Arithmetic register-register
        arith_reg_reg : next_states = fetch1;
        // Branch
        branch : next_states = fetch1;
        // Unconditional Jump
        jal : next_states = fetch1;
        jalr : next_states = fetch1;
        // LUI
        lui : next_states = fetch1;
        // AUIPC
        auipc : next_states = fetch1;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst) begin
        state <= fetch1;
    end
    else begin
        state <= next_states;
    end
end

endmodule : control
