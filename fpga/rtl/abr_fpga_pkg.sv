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
    // Size Parameter encodings
    // -----------------------------------------------------------------------
    typedef enum logic [2:0] {
        SIZE_8B  = 3'b000,
        SIZE_16B = 3'b001,
        SIZE_32B = 3'b010,
        SIZE_64B = 3'b011
    } size_e;

    // -----------------------------------------------------------------------
    // BRAM Memory Sizing Parameters
    // -----------------------------------------------------------------------
    localparam int unsigned COL_WIDTH      =    8;                                // Number of bits in a byte
    localparam int unsigned NB_COL         =    1;                                // Number of byte-columns in each RAM word. Must divide 32 (the AHB data width) for byte-write support.
    localparam int unsigned RAM_WIDTH      = NB_COL * COL_WIDTH;                  // Number of byte-columns in
    localparam int unsigned A_DATA_WIDTH   = RAM_WIDTH;                           // Width of data to/from BRAM (e.g. 8 bits for a single byte)
    localparam int unsigned B_DATA_WIDTH   =   32;                                // Width of data to/from AHB    
    localparam int unsigned RAM_COUNT      = B_DATA_WIDTH / (NB_COL * COL_WIDTH); // Number of parallel RAMs needed to achieve DATA_WIDTH                    // Width of each individual RAM (e.g. 8 bits for a single byte)
    localparam int unsigned RAM_DEPTH      = 2048 / RAM_COUNT;                    // Number of 32-bit words in the BRAM. Must be >= the largest base_addr + num_words in any descriptor table. With 2048 words, we can cover up to address 0x1FFF with 32-bit words.
    localparam int unsigned RAM_ADDR_WIDTH = $clog2(RAM_DEPTH);
    localparam int unsigned A_ADDR_WIDTH   = 20;                                   // Address width matches USB address width, which is independent of RAM_DEPTH since the BRAMs are accessed with a word-aligned address and the RAM array module handles the internal byte addressing.
    localparam int unsigned B_ADDR_WIDTH   = RAM_ADDR_WIDTH; 
    localparam int unsigned B_WE_WIDTH     = B_DATA_WIDTH / 8;             

    // -----------------------------------------------------------------------
    // AHB Sizing Parameters
    // -----------------------------------------------------------------------
    localparam int unsigned AHB_ADDR_WIDTH = 32;
    localparam int unsigned AHB_DATA_WIDTH = 64;
    localparam int unsigned AHB_SIZE_WIDTH =  3;

    // -----------------------------------------------------------------------
    // CW Register sizing parameters
    // -----------------------------------------------------------------------
    localparam int unsigned CW_REG_DATA_WIDTH = 32;

    // -----------------------------------------------------------------------
    // ABR Instruction Parameters
    // -----------------------------------------------------------------------
    localparam int unsigned INSTR_ADDR_WIDTH = 16;
    localparam int unsigned INSTR_LEN_WIDTH  = 12;
    localparam int unsigned INSTR_OP_WIDTH   =  4;

    // -----------------------------------------------------------------------
    // Memory Transfer Controller Parameters
    // -----------------------------------------------------------------------
    localparam int unsigned M_XFER_BLEN_WIDTH = 16; // Length of 'Bytes to transfer' field

    // -----------------------------------------------------------------------
    // CW310 USB register map
    // Byte addresses within the first 128-byte page (reg_address == 0).
    // reg_bytecnt[6:2] selects the register; reg_bytecnt[1:0] selects the
    // byte within the 32-bit register.
    // -----------------------------------------------------------------------
    localparam logic [6:0] CW310_ADDR_DUT_CTRL0 = 7'h00;
    localparam logic [6:0] CW310_ADDR_DUT_CTRL1 = 7'h04;
    localparam logic [6:0] CW310_ADDR_DUT_STAT0 = 7'h08;
    localparam logic [6:0] CW310_ADDR_DUT_STAT1 = 7'h0C;
    localparam logic [6:0] CW310_ADDR_ABR_INSTR = 7'h10;

    // ABR_DBUFF — 2048-byte data buffer, forwarded to an external module.
    // Access within this range is NOT stored here; writes are forwarded as a
    // pulsed strobe and reads are returned from an external input port.
    localparam logic [19:0] CW310_ADDR_ABR_DBUFF_BASE = 20'h0100;  // inclusive
    localparam logic [19:0] CW310_ADDR_ABR_DBUFF_END  = 20'h0900;  // exclusive
    localparam int unsigned CW310_ABR_DBUFF_ADDR_W    =            // = 11
        $clog2(CW310_ADDR_ABR_DBUFF_END - CW310_ADDR_ABR_DBUFF_BASE);

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
    localparam logic [31:0] ADDR_MLDSA_SK_OUT       = 32'h4000;
    localparam logic [31:0] ADDR_MLDSA_SK_IN        = 32'h6000;
    localparam logic [31:0] ADDR_MLDSA_VERIFY_RES   = 32'h00D8;

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
    localparam int unsigned VERIFY_RES_WORDS = 16;    // 64 B (recomputed c̃)

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
    localparam logic [31:0] DATA_MSG       [MSG_WORDS]       = '{default: '0};
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

    // -----------------------------------------------------------------------
    // Per-operation read-descriptor tables.
    //
    // Same wr_desc_t struct reused for reads — base_addr + num_words.
    // The FSM reads word[0..num_words-1] from base_addr, base_addr+4, …
    // and stores them into the per-operation result registers in abr_fpga_top.
    // -----------------------------------------------------------------------

    // KEYGEN outputs: public key, then private key
    localparam wr_desc_t KEYGEN_RD_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_PUBKEY,      PUBKEY_WORDS    },
        '{ADDR_MLDSA_SK_OUT,      PRIVKEY_WORDS   },
        '{32'h0,                  32'h0           },
        '{32'h0,                  32'h0           }
    };
    localparam int unsigned KEYGEN_RD_NUM_DESC = 2;

    // SIGN outputs: signature
    localparam wr_desc_t SIGN_RD_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_SIGNATURE,   SIGNATURE_WORDS },
        '{32'h0,                  32'h0           },
        '{32'h0,                  32'h0           },
        '{32'h0,                  32'h0           }
    };
    localparam int unsigned SIGN_RD_NUM_DESC = 1;

    // VERIFY outputs: recomputed c̃ (16 words)
    localparam wr_desc_t VERIFY_RD_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_VERIFY_RES,  VERIFY_RES_WORDS },
        '{32'h0,                  32'h0            },
        '{32'h0,                  32'h0            },
        '{32'h0,                  32'h0            }
    };
    localparam int unsigned VERIFY_RD_NUM_DESC = 1;

    // KGSIGN outputs: public key, private key, signature
    localparam wr_desc_t KGSIGN_RD_DESC [MAX_DESC] = '{
        '{ADDR_MLDSA_PUBKEY,      PUBKEY_WORDS    },
        '{ADDR_MLDSA_SK_OUT,      PRIVKEY_WORDS   },
        '{ADDR_MLDSA_SIGNATURE,   SIGNATURE_WORDS },
        '{32'h0,                  32'h0           }
    };
    localparam int unsigned KGSIGN_RD_NUM_DESC = 3;

endpackage
