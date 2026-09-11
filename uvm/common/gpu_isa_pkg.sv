package gpu_isa_pkg;

    localparam int GPU_NUM_CORES         = 2;
    localparam int GPU_THREADS_PER_BLOCK = 4;

    localparam int GPU_DATA_ADDR_BITS    = 8;
    localparam int GPU_DATA_DATA_BITS    = 8;
    localparam int GPU_DATA_CHANNELS     = 4;

    localparam int GPU_PROG_ADDR_BITS    = 8;
    localparam int GPU_PROG_DATA_BITS    = 16;
    localparam int GPU_PROG_CHANNELS     = 1;

    typedef enum logic [3:0] {
        OP_NOP   = 4'h0,
        OP_BRnzp = 4'h1,
        OP_CMP   = 4'h2,
        OP_ADD   = 4'h3,
        OP_SUB   = 4'h4,
        OP_MUL   = 4'h5,
        OP_DIV   = 4'h6,
        OP_LDR   = 4'h7,
        OP_STR   = 4'h8,
        OP_CONST = 4'h9,
        OP_RET   = 4'hF
    } opcode_e;

    typedef enum logic [3:0] {
        REG_R0 = 4'h0, REG_R1 = 4'h1, REG_R2  = 4'h2, REG_R3  = 4'h3,
        REG_R4 = 4'h4, REG_R5 = 4'h5, REG_R6  = 4'h6, REG_R7  = 4'h7,
        REG_R8 = 4'h8, REG_R9 = 4'h9, REG_R10 = 4'hA, REG_R11 = 4'hB,
        REG_R12 = 4'hC, REG_R13 = 4'hD, REG_R14 = 4'hE, REG_R15 = 4'hF
    } reg_addr_e;

    localparam logic [3:0] REG_BLOCK_IDX = REG_R13;
    localparam logic [3:0] REG_BLOCK_DIM = REG_R14;
    localparam logic [3:0] REG_THREAD_ID = REG_R15;

    typedef struct packed {
        opcode_e    op;
        logic [3:0] rd;
        logic [3:0] rs;
        logic [3:0] rt;
        logic [7:0] imm;
    } gpu_instr_t;

    function automatic gpu_instr_t instr_nop();
        return '{op: OP_NOP, rd: '0, rs: '0, rt: '0, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_ret();
        return '{op: OP_RET, rd: '0, rs: '0, rt: '0, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_cmp(logic [3:0] a, logic [3:0] b);
        return '{op: OP_CMP, rd: '0, rs: a, rt: b, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_add(logic [3:0] d, logic [3:0] a, logic [3:0] b);
        return '{op: OP_ADD, rd: d, rs: a, rt: b, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_sub(logic [3:0] d, logic [3:0] a, logic [3:0] b);
        return '{op: OP_SUB, rd: d, rs: a, rt: b, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_mul(logic [3:0] d, logic [3:0] a, logic [3:0] b);
        return '{op: OP_MUL, rd: d, rs: a, rt: b, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_div(logic [3:0] d, logic [3:0] a, logic [3:0] b);
        return '{op: OP_DIV, rd: d, rs: a, rt: b, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_ldr(logic [3:0] d, logic [3:0] a);
        return '{op: OP_LDR, rd: d, rs: a, rt: '0, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_str(logic [3:0] a, logic [3:0] src);
        return '{op: OP_STR, rd: '0, rs: a, rt: src, imm: '0};
    endfunction

    function automatic gpu_instr_t instr_const(logic [3:0] d, logic [7:0] value);
        return '{op: OP_CONST, rd: d, rs: '0, rt: '0, imm: value};
    endfunction

    function automatic gpu_instr_t instr_brnzp(logic [2:0] nzp_mask, logic [7:0] target);
        return '{op: OP_BRnzp, rd: {1'b0, nzp_mask}, rs: '0, rt: '0, imm: target};
    endfunction

    function automatic gpu_instr_t instr_raw(logic [15:0] word);
        return '{op: opcode_e'(word[15:12]), rd: word[11:8], rs: word[7:4], rt: word[3:0], imm: word[7:0]};
    endfunction

    function automatic logic [15:0] encode(gpu_instr_t i);
        return {i.op, i.rd, i.rs, i.rt};
    endfunction

endpackage
