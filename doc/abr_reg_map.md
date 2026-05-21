### ML-DSA Registers

| Base Address | End Address | Field (`decoded_reg_strb.*`) | Notes |
| --- | --- | --- | --- |
| `0x0000` | `0x0004` | `MLDSA_NAME[0..1]` | 2 × 32-bit, stride 0x4 |
| `0x0008` | `0x000C` | `MLDSA_VERSION[0..1]` | 2 × 32-bit, stride 0x4 |
| `0x0010` | `0x0010` | `MLDSA_CTRL` |  |
| `0x0014` | `0x0014` | `MLDSA_STATUS` |  |
| `0x0018` | `0x0054` | `ABR_ENTROPY[0..15]` | 16 × 32-bit, stride 0x4 |
| `0x0058` | `0x0074` | `MLDSA_SEED[0..7]` | 8 × 32-bit, stride 0x4 |
| `0x0078` | `0x0094` | `MLDSA_SIGN_RND[0..7]` | 8 × 32-bit, stride 0x4 |
| `0x0098` | `0x00D4` | `MLDSA_MSG[0..15]` | 16 × 32-bit, stride 0x4 |
| `0x00D8` | `0x0114` | `MLDSA_VERIFY_RES[0..15]` | 16 × 32-bit, stride 0x4 |
| `0x0118` | `0x0154` | `MLDSA_EXTERNAL_MU[0..15]` | 16 × 32-bit, stride 0x4 |
| `0x0158` | `0x0158` | `MLDSA_MSG_STROBE` |  |
| `0x015C` | `0x015C` | `MLDSA_CTX_CONFIG` |  |
| `0x0160` | `0x025C` | `MLDSA_CTX[0..63]` | 64 × 32-bit, stride 0x4 |
| `0x1000` | `0x1A1F` | `MLDSA_PUBKEY` | External, 0xA20 bytes |
| `0x2000` | `0x3213` | `MLDSA_SIGNATURE` | External, 0x1214 bytes |
| `0x4000` | `0x531F` | `MLDSA_PRIVKEY_OUT` | External, 0x1320 bytes |
| `0x6000` | `0x731F` | `MLDSA_PRIVKEY_IN` | External, 0x1320 bytes |

### Key Vault (ML-DSA)

| Base Address | Field (`decoded_reg_strb.*`) |
| --- | --- |
| `0x8000` | `kv_mldsa_seed_rd_ctrl` |
| `0x8004` | `kv_mldsa_seed_rd_status` |

### Interrupt Block

| Base Address | Field (`decoded_reg_strb.intr_block_rf.*`) |
| --- | --- |
| `0x8100` | `global_intr_en_r` |
| `0x8104` | `error_intr_en_r` |
| `0x8108` | `notif_intr_en_r` |
| `0x810C` | `error_global_intr_r` |
| `0x8110` | `notif_global_intr_r` |
| `0x8114` | `error_internal_intr_r` |
| `0x8118` | `notif_internal_intr_r` |
| `0x811C` | `error_intr_trig_r` |
| `0x8120` | `notif_intr_trig_r` |
| `0x8200` | `error_internal_intr_count_r` |
| `0x8280` | `notif_cmd_done_intr_count_r` |
| `0x8300` | `error_internal_intr_count_incr_r` |
| `0x8304` | `notif_cmd_done_intr_count_incr_r` |

### ML-KEM Registers

| Base Address | End Address | Field (`decoded_reg_strb.*`) | Notes |
| --- | --- | --- | --- |
| `0x9000` | `0x9004` | `MLKEM_NAME[0..1]` | 2 × 32-bit, stride 0x4 |
| `0x9008` | `0x900C` | `MLKEM_VERSION[0..1]` | 2 × 32-bit, stride 0x4 |
| `0x9010` | `0x9010` | `MLKEM_CTRL` |  |
| `0x9014` | `0x9014` | `MLKEM_STATUS` |  |
| `0x9018` | `0x9034` | `MLKEM_SEED_D[0..7]` | 8 × 32-bit, stride 0x4 |
| `0x9038` | `0x9054` | `MLKEM_SEED_Z[0..7]` | 8 × 32-bit, stride 0x4; write-external |
| `0x9058` | `0x9074` | `MLKEM_SHARED_KEY[0..7]` | 8 × 32-bit, stride 0x4; read-external |
| `0x9080` | `0x909F` | `MLKEM_MSG` | External, 0x20 bytes |
| `0xA000` | `0xAC5F` | `MLKEM_DECAPS_KEY` | External, 0xC60 bytes |
| `0xB000` | `0xB61F` | `MLKEM_ENCAPS_KEY` | External, 0x620 bytes |
| `0xB800` | `0xBE1F` | `MLKEM_CIPHERTEXT` | External, 0x620 bytes |

### Key Vault (ML-KEM)

| Base Address | Field (`decoded_reg_strb.*`) |
| --- | --- |
| `0xC000` | `kv_mlkem_seed_rd_ctrl` |
| `0xC004` | `kv_mlkem_seed_rd_status` |
| `0xC008` | `kv_mlkem_msg_rd_ctrl` |
| `0xC00C` | `kv_mlkem_msg_rd_status` |
| `0xC010` | `kv_mlkem_sharedkey_wr_ctrl` |
| `0xC014` | `kv_mlkem_sharedkey_wr_status` |
