package gpu_program_lib_pkg;
    import gpu_isa_pkg::*;

    class gpu_program_lib;

        static function void matadd_custom(ref gpu_instr_t prog[$], ref logic [7:0] data[$],
                                           input int size,
                                           input logic [7:0] base_a,
                                           input logic [7:0] data_a[$],
                                           input logic [7:0] data_b[$]);
            logic [7:0] base_b = base_a + size;
            logic [7:0] base_c = base_a + 2 * size;
            prog.delete();
            data.delete();
            prog = '{
                instr_mul(REG_R0, REG_BLOCK_IDX, REG_BLOCK_DIM),
                instr_add(REG_R0, REG_R0, REG_THREAD_ID),
                instr_const(REG_R1, base_a),
                instr_const(REG_R2, base_b),
                instr_const(REG_R3, base_c),
                instr_add(REG_R4, REG_R1, REG_R0),
                instr_ldr(REG_R4, REG_R4),
                instr_add(REG_R5, REG_R2, REG_R0),
                instr_ldr(REG_R5, REG_R5),
                instr_add(REG_R6, REG_R4, REG_R5),
                instr_add(REG_R7, REG_R3, REG_R0),
                instr_str(REG_R7, REG_R6),
                instr_ret()
            };
            foreach (data_a[i]) data.push_back(data_a[i]);
            foreach (data_b[i]) data.push_back(data_b[i]);
        endfunction

        static function void matadd(ref gpu_instr_t prog[$], ref logic [7:0] data[$],
                                    input bit random_data = 0);
            logic [7:0] da[$];
            logic [7:0] db[$];
            for (int i = 0; i < 8; i++) begin
                da.push_back(random_data ? (i + $urandom_range(0, 10)) : i);
                db.push_back(random_data ? (i + $urandom_range(0, 10)) : i);
            end
            matadd_custom(prog, data, 8, 8'h00, da, db);
        endfunction

        static function void scatter(ref gpu_instr_t prog[$], input logic [7:0] base_c = 8'h20);
            prog.delete();
            prog = '{
                instr_mul(REG_R0, REG_BLOCK_IDX, REG_BLOCK_DIM),
                instr_add(REG_R0, REG_R0, REG_THREAD_ID),
                instr_const(REG_R3, base_c),
                instr_add(REG_R7, REG_R3, REG_R0),
                instr_str(REG_R7, REG_R0),
                instr_ret()
            };
        endfunction

        static function void arbiter(ref gpu_instr_t prog[$], input logic [7:0] base = 8'h08);
            prog.delete();
            prog = '{
                instr_mul(REG_R0, REG_BLOCK_IDX, REG_BLOCK_DIM),
                instr_add(REG_R0, REG_R0, REG_THREAD_ID),
                instr_const(REG_R3, base),
                instr_add(REG_R7, REG_R3, REG_R0),
                instr_str(REG_R7, REG_R0),
                instr_const(REG_R3, base + 8'h08),
                instr_add(REG_R7, REG_R3, REG_R0),
                instr_str(REG_R7, REG_R0),
                instr_const(REG_R3, base + 8'h10),
                instr_add(REG_R7, REG_R3, REG_R0),
                instr_str(REG_R7, REG_R0),
                instr_const(REG_R3, base + 8'h18),
                instr_add(REG_R7, REG_R3, REG_R0),
                instr_str(REG_R7, REG_R0),
                instr_ret()
            };
        endfunction

        static function void trivial(ref gpu_instr_t prog[$]);
            prog.delete();
            prog = '{
                instr_const(REG_R1, 8'h2A),
                instr_ret()
            };
        endfunction

    endclass

endpackage
