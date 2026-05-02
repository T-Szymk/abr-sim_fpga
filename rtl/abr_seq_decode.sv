//  abr_seq_decode.sv
//  2026-05-01  Markku-Juhani O. Saarinen <mjos@iki.fi>

//  === hooks to print ABR sequencer state ("live address decoder")

module abr_seq_decode
    import abr_ctrl_pkg::*;
    (
        input logic clk,
        input logic en_i,
        input logic [ABR_PROG_ADDR_W-1 : 0] addr_i
    );

    logic [25 : 0] cyc = 0;
    logic [ABR_PROG_ADDR_W-1 : 0] addr_p = '1;

    task automatic show(input string name);
        $display("#%d [seq]  %d: %s", cyc, addr_i, name);
    endtask

    task automatic show_range(input string name, input logic [ABR_PROG_ADDR_W-1 : 0] base);
        $display("#%d [seq]  %d: %s +%d", cyc, addr_i, name, addr_i - base);
    endtask

    always_ff @(posedge clk) begin
        if (en_i) begin
            if (addr_i != addr_p) begin
                unique case (addr_i)
                    ABR_RESET:                  show("ABR_RESET");
                    ABR_ZEROIZE:                show("ABR_ZEROIZE");
                    MLDSA_KG_S:                 show("MLDSA_KG_S");
                    MLDSA_KG_JUMP_SIGN:         show("MLDSA_KG_JUMP_SIGN");
                    MLDSA_KG_E:                 show("MLDSA_KG_E");
                    MLDSA_SIGN_S:               show("MLDSA_SIGN_S");
                    MLDSA_SIGN_CHECK_MODE:      show("MLDSA_SIGN_CHECK_MODE");
                    MLDSA_SIGN_H_MU:            show("MLDSA_SIGN_H_MU");
                    MLDSA_SIGN_H_RHO_P:         show("MLDSA_SIGN_H_RHO_P");
                    MLDSA_SIGN_INIT_S:          show("MLDSA_SIGN_INIT_S");
                    MLDSA_SIGN_LFSR_S:          show("MLDSA_SIGN_LFSR_S");
                    MLDSA_SIGN_MAKE_Y_S:        show("MLDSA_SIGN_MAKE_Y_S");
                    MLDSA_SIGN_MAKE_W_S:        show("MLDSA_SIGN_MAKE_W_S");
                    MLDSA_SIGN_MAKE_W:          show("MLDSA_SIGN_MAKE_W");
                    MLDSA_SIGN_MAKE_C:          show("MLDSA_SIGN_MAKE_C");
                    MLDSA_SIGN_VALID_S:         show("MLDSA_SIGN_VALID_S");
                    MLDSA_SIGN_CHL_E:           show("MLDSA_SIGN_CHL_E");
                    MLDSA_SIGN_E:               show("MLDSA_SIGN_E");
                    MLDSA_VERIFY_S:             show("MLDSA_VERIFY_S");
                    MLDSA_VERIFY_H_TR:          show("MLDSA_VERIFY_H_TR");
                    MLDSA_VERIFY_CHECK_MODE:    show("MLDSA_VERIFY_CHECK_MODE");
                    MLDSA_VERIFY_H_MU:          show("MLDSA_VERIFY_H_MU");
                    MLDSA_VERIFY_MAKE_C:        show("MLDSA_VERIFY_MAKE_C");
                    MLDSA_VERIFY_NTT_C:         show("MLDSA_VERIFY_NTT_C");
                    MLDSA_VERIFY_NTT_T1:        show("MLDSA_VERIFY_NTT_T1");
                    MLDSA_VERIFY_NTT_Z:         show("MLDSA_VERIFY_NTT_Z");
                    MLDSA_VERIFY_EXP_A:         show("MLDSA_VERIFY_EXP_A");
                    MLDSA_VERIFY_RES:           show("MLDSA_VERIFY_RES");
                    MLDSA_VERIFY_E:             show("MLDSA_VERIFY_E");
                    MLKEM_KG_S:                 show("MLKEM_KG_S");
                    MLKEM_KG_E:                 show("MLKEM_KG_E");
                    MLKEM_DECAPS_S:             show("MLKEM_DECAPS_S");
                    MLKEM_ENCAPS_S:             show("MLKEM_ENCAPS_S");
                    MLKEM_ENCAPS_E:             show("MLKEM_ENCAPS_E");
                    MLKEM_DECAPS_CHK:           show("MLKEM_DECAPS_CHK");
                    MLKEM_DECAPS_E:             show("MLKEM_DECAPS_E");
                    default: begin
                        if (addr_i < MLDSA_KG_JUMP_SIGN)        show_range("MLDSA_KG_S", MLDSA_KG_S); else
                        if (addr_i < MLDSA_KG_E)                show_range("MLDSA_KG_JUMP_SIGN", MLDSA_KG_JUMP_SIGN); else
                        if (addr_i < MLDSA_SIGN_S)              show_range("MLDSA_KG_E", MLDSA_KG_E); else
                        if (addr_i < MLDSA_SIGN_CHECK_MODE)     show_range("MLDSA_SIGN_S", MLDSA_SIGN_S); else
                        if (addr_i < MLDSA_SIGN_H_MU)           show_range("MLDSA_SIGN_CHECK_MODE", MLDSA_SIGN_CHECK_MODE); else
                        if (addr_i < MLDSA_SIGN_H_RHO_P)        show_range("MLDSA_SIGN_H_MU", MLDSA_SIGN_H_MU); else
                        if (addr_i < MLDSA_SIGN_INIT_S)         show_range("MLDSA_SIGN_H_RHO_P", MLDSA_SIGN_H_RHO_P); else
                        if (addr_i < MLDSA_SIGN_LFSR_S)         show_range("MLDSA_SIGN_INIT_S", MLDSA_SIGN_INIT_S); else
                        if (addr_i < MLDSA_SIGN_MAKE_Y_S)       show_range("MLDSA_SIGN_LFSR_S", MLDSA_SIGN_LFSR_S); else
                        if (addr_i < MLDSA_SIGN_MAKE_W_S)       show_range("MLDSA_SIGN_MAKE_Y_S", MLDSA_SIGN_MAKE_Y_S); else
                        if (addr_i < MLDSA_SIGN_MAKE_W)         show_range("MLDSA_SIGN_MAKE_W_S", MLDSA_SIGN_MAKE_W_S); else
                        if (addr_i < MLDSA_SIGN_MAKE_C)         show_range("MLDSA_SIGN_MAKE_W", MLDSA_SIGN_MAKE_W); else
                        if (addr_i < MLDSA_SIGN_VALID_S)        show_range("MLDSA_SIGN_MAKE_C", MLDSA_SIGN_MAKE_C); else
                        if (addr_i < MLDSA_SIGN_CHL_E)          show_range("MLDSA_SIGN_VALID_S", MLDSA_SIGN_VALID_S); else
                        if (addr_i < MLDSA_SIGN_E)              show_range("MLDSA_SIGN_CHL_E", MLDSA_SIGN_CHL_E); else
                        if (addr_i < MLDSA_VERIFY_S)            show_range("MLDSA_SIGN_E", MLDSA_SIGN_E); else
                        if (addr_i < MLDSA_VERIFY_H_TR)         show_range("MLDSA_VERIFY_S", MLDSA_VERIFY_S); else
                        if (addr_i < MLDSA_VERIFY_CHECK_MODE)   show_range("MLDSA_VERIFY_H_TR", MLDSA_VERIFY_H_TR); else
                        if (addr_i < MLDSA_VERIFY_H_MU)         show_range("MLDSA_VERIFY_CHECK_MODE", MLDSA_VERIFY_CHECK_MODE); else
                        if (addr_i < MLDSA_VERIFY_MAKE_C)       show_range("MLDSA_VERIFY_H_MU", MLDSA_VERIFY_H_MU); else
                        if (addr_i < MLDSA_VERIFY_NTT_C)        show_range("MLDSA_VERIFY_MAKE_C", MLDSA_VERIFY_MAKE_C); else
                        if (addr_i < MLDSA_VERIFY_NTT_T1)       show_range("MLDSA_VERIFY_NTT_C", MLDSA_VERIFY_NTT_C); else
                        if (addr_i < MLDSA_VERIFY_NTT_Z)        show_range("MLDSA_VERIFY_NTT_T1", MLDSA_VERIFY_NTT_T1); else
                        if (addr_i < MLDSA_VERIFY_EXP_A)        show_range("MLDSA_VERIFY_NTT_Z", MLDSA_VERIFY_NTT_Z); else
                        if (addr_i < MLDSA_VERIFY_RES)          show_range("MLDSA_VERIFY_EXP_A", MLDSA_VERIFY_EXP_A); else
                        if (addr_i < MLDSA_VERIFY_E)            show_range("MLDSA_VERIFY_RES", MLDSA_VERIFY_RES); else
                        if (addr_i < MLKEM_KG_S)                show_range("MLDSA_VERIFY_E", MLDSA_VERIFY_E); else
                        if (addr_i < MLKEM_KG_E)                show_range("MLKEM_KG_S", MLKEM_KG_S); else
                        if (addr_i < MLKEM_DECAPS_S)            show_range("MLKEM_KG_E", MLKEM_KG_E); else
                        if (addr_i < MLKEM_ENCAPS_S)            show_range("MLKEM_DECAPS_S", MLKEM_DECAPS_S); else
                        if (addr_i < MLKEM_ENCAPS_E)            show_range("MLKEM_ENCAPS_S", MLKEM_ENCAPS_S); else
                        if (addr_i < MLKEM_DECAPS_CHK)          show_range("MLKEM_ENCAPS_E", MLKEM_ENCAPS_E); else
                        if (addr_i < MLKEM_DECAPS_E)            show_range("MLKEM_DECAPS_CHK", MLKEM_DECAPS_CHK); else
                        if (addr_i < ABR_ERROR)                 show_range("MLKEM_DECAPS_E", MLKEM_DECAPS_E); else
                                                            show("ABR_ERROR");
                    end
                endcase
                $fflush();
            end
            addr_p  <=  addr_i;
        end
        cyc     <=  cyc + 1;
    end

endmodule
