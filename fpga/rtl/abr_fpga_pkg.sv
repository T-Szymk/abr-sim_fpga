// abr_fpga_pkg.sv — compile-time configuration for the abr_top FPGA wrapper.
//
// Contains:
//   - AHB register addresses (mirrors abr_reg.rdl / abr_wrap.cpp)
//   - CTRL command and STATUS bit constants
//   - Operation enum (selects behaviour at elaboration time)
//   - Write-descriptor tables (address + word-count for each input field)
//   - Static input-data ROMs (all zeros by default — replace with real
//     test-vectors to exercise a specific key/message)
//
// Endianness: little-endian per FIPS 204 §3.  Word index 0 of every array
// maps to the lowest byte-address of that register block.

package abr_fpga_pkg;

    // -----------------------------------------------------------------------
    // AHB register base addresses
    // -----------------------------------------------------------------------
    localparam logic [31:0] ADDR_ABR_ENTROPY       = 32'h0018;
    localparam logic [31:0] ADDR_MLDSA_CTRL        = 32'h0010;
    localparam logic [31:0] ADDR_MLDSA_STATUS      = 32'h0014;
    localparam logic [31:0] ADDR_MLDSA_SEED        = 32'h0058;
    localparam logic [31:0] ADDR_MLDSA_SIGN_RND    = 32'h0078;
    localparam logic [31:0] ADDR_MLDSA_MSG         = 32'h0098;
    localparam logic [31:0] ADDR_MLDSA_EXT_MU      = 32'h0118;
    localparam logic [31:0] ADDR_MLDSA_PUBKEY      = 32'h1000;
    localparam logic [31:0] ADDR_MLDSA_SIGNATURE   = 32'h2000;
    localparam logic [31:0] ADDR_MLDSA_SK_IN       = 32'h6000;

    // -----------------------------------------------------------------------
    // Field sizes in 32-bit words
    // -----------------------------------------------------------------------
    localparam int unsigned ENTROPY_WORDS    = 16;    // 64 B
    localparam int unsigned SEED_WORDS       = 8;     // 32 B
    localparam int unsigned SIGN_RND_WORDS   = 8;     // 32 B
    localparam int unsigned MSG_WORDS        = 16;    // 64 B
    localparam int unsigned PUBKEY_WORDS     = 648;   // 2592 B
    localparam int unsigned PRIVKEY_WORDS    = 1224;  // 4896 B
    localparam int unsigned SIGNATURE_WORDS  = 1157;  // ceil(4627 B / 4)

    // -----------------------------------------------------------------------
    // CTRL register command encoding (CTRL[2:0])
    // -----------------------------------------------------------------------
    localparam logic [31:0] CTRL_KEYGEN      = 32'h1;
    localparam logic [31:0] CTRL_SIGN        = 32'h2;
    localparam logic [31:0] CTRL_VERIFY      = 32'h3;
    localparam logic [31:0] CTRL_KGSIGN      = 32'h4;
    localparam logic [31:0] CTRL_EXTERNAL_MU = 32'h20;  // bit [5]
    localparam logic [31:0] CTRL_STREAM_MSG  = 32'h40;  // bit [6]

    // -----------------------------------------------------------------------
    // STATUS register bit masks
    // -----------------------------------------------------------------------
    localparam logic [31:0] STATUS_READY     = 32'h1;
    localparam logic [31:0] STATUS_VALID     = 32'h2;
    localparam logic [31:0] STATUS_ERROR     = 32'h8;

    // -----------------------------------------------------------------------
    // Supported compile-time operations
    // -----------------------------------------------------------------------
    typedef enum logic [1:0] {
        OP_KEYGEN = 2'd0,
        OP_SIGN   = 2'd1,
        OP_VERIFY = 2'd2,
        OP_KGSIGN = 2'd3
    } op_e;

    // -----------------------------------------------------------------------
    // Write-descriptor: one contiguous AHB register block to write.
    //   base_addr  — first 32-bit-aligned address in the block
    //   num_words  — number of consecutive 32-bit writes
    // The FSM writes word[0..num_words-1] at base_addr, base_addr+4, …
    // A descriptor with num_words == 0 is a sentinel (end of list).
    // -----------------------------------------------------------------------
    typedef struct packed {
        logic [31:0] base_addr;
        logic [31:0] num_words;
    } wr_desc_t;

    localparam int unsigned MAX_DESC = 4;  // max descriptors per operation

    // -----------------------------------------------------------------------
    // Per-operation descriptor tables
    // -----------------------------------------------------------------------

    // KEYGEN: entropy, seed
    localparam wr_desc_t KEYGEN_DESC [MAX_DESC] = '{
        '{ADDR_ABR_ENTROPY,    ENTROPY_WORDS  },
        '{ADDR_MLDSA_SEED,     SEED_WORDS     },
        '{32'h0,               32'h0          },
        '{32'h0,               32'h0          }
    };
    localparam int unsigned  KEYGEN_NUM_DESC = 2;
    localparam logic [31:0]  KEYGEN_CTRL     = CTRL_KEYGEN;

    // SIGN: msg/hash, sk_in, sign_rnd, entropy
    localparam wr_desc_t SIGN_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_MSG,      MSG_WORDS      },
        '{ADDR_MLDSA_SK_IN,    PRIVKEY_WORDS  },
        '{ADDR_MLDSA_SIGN_RND, SIGN_RND_WORDS },
        '{ADDR_ABR_ENTROPY,    ENTROPY_WORDS  }
    };
    localparam int unsigned  SIGN_NUM_DESC = 4;
    localparam logic [31:0]  SIGN_CTRL     = CTRL_SIGN;

    // VERIFY: msg/hash, pk, signature
    localparam wr_desc_t VERIFY_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_MSG,       MSG_WORDS       },
        '{ADDR_MLDSA_PUBKEY,    PUBKEY_WORDS    },
        '{ADDR_MLDSA_SIGNATURE, SIGNATURE_WORDS },
        '{32'h0,                32'h0           }
    };
    localparam int unsigned  VERIFY_NUM_DESC = 3;
    localparam logic [31:0]  VERIFY_CTRL     = CTRL_VERIFY;

    // KGSIGN: seed, msg/hash, sign_rnd, entropy
    localparam wr_desc_t KGSIGN_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_SEED,     SEED_WORDS     },
        '{ADDR_MLDSA_MSG,      MSG_WORDS      },
        '{ADDR_MLDSA_SIGN_RND, SIGN_RND_WORDS },
        '{ADDR_ABR_ENTROPY,    ENTROPY_WORDS  }
    };
    localparam int unsigned  KGSIGN_NUM_DESC = 4;
    localparam logic [31:0]  KGSIGN_CTRL     = CTRL_KGSIGN;

    // -----------------------------------------------------------------------
    // Static input data — placeholder zeros.
    //
    // Replace these arrays with real test-vector values to run a meaningful
    // computation.  Each array is indexed [word_index] where index 0 maps
    // to the lowest byte-address of that field (little-endian, per §3 of
    // the FIPS 204 spec and the AdamsBridge register map).
    // -----------------------------------------------------------------------
    localparam logic [31:0] DATA_ENTROPY   [ENTROPY_WORDS]   = '{default: '0};
    localparam logic [31:0] DATA_SEED      [SEED_WORDS]      = '{default: '0};
    localparam logic [31:0] DATA_SIGN_RND  [SIGN_RND_WORDS]  = '{default: '0};
    localparam logic [31:0] DATA_MSG       [MSG_WORDS]        = '{default: '0};
    localparam logic [31:0] DATA_PUBKEY    [PUBKEY_WORDS]    = '{default: '0};
    localparam logic [31:0] DATA_PRIVKEY   [PRIVKEY_WORDS]   = '{default: '0};
    localparam logic [31:0] DATA_SIGNATURE [SIGNATURE_WORDS] = '{default: '0};

    // -----------------------------------------------------------------------
    // Per-operation data-lookup functions.
    //
    // Called from the FSM with (desc_idx, word_idx) — both runtime signals.
    // Synthesises as a case/mux ROM; with all-zero data Vivado folds the
    // entire output to constant 0.
    // -----------------------------------------------------------------------
    function automatic logic [31:0] keygen_data(
        input int unsigned desc_idx,
        input int unsigned word_idx
    );
        unique case (desc_idx)
            0:       return DATA_ENTROPY[word_idx];
            1:       return DATA_SEED[word_idx];
            default: return '0;
        endcase
    endfunction

    function automatic logic [31:0] sign_data(
        input int unsigned desc_idx,
        input int unsigned word_idx
    );
        unique case (desc_idx)
            0:       return DATA_MSG[word_idx];
            1:       return DATA_PRIVKEY[word_idx];
            2:       return DATA_SIGN_RND[word_idx];
            3:       return DATA_ENTROPY[word_idx];
            default: return '0;
        endcase
    endfunction

    function automatic logic [31:0] verify_data(
        input int unsigned desc_idx,
        input int unsigned word_idx
    );
        unique case (desc_idx)
            0:       return DATA_MSG[word_idx];
            1:       return DATA_PUBKEY[word_idx];
            2:       return DATA_SIGNATURE[word_idx];
            default: return '0;
        endcase
    endfunction

    function automatic logic [31:0] kgsign_data(
        input int unsigned desc_idx,
        input int unsigned word_idx
    );
        unique case (desc_idx)
            0:       return DATA_SEED[word_idx];
            1:       return DATA_MSG[word_idx];
            2:       return DATA_SIGN_RND[word_idx];
            3:       return DATA_ENTROPY[word_idx];
            default: return '0;
        endcase
    endfunction

endpackage
