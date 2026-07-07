'''
This is where all constants and function definitions are contained
'''

DBG_PRINT = 0 # set to 1 to activate debug prints!

# Register addresses ToDo: Make these enums
## FPGA Registers
REG_ADDR_IDENT        = 0x0000
REG_ADDR_DUT_CTRL0    = 0x0001
REG_ADDR_DUT_CTRL1    = 0x0002
REG_ADDR_DUT_STAT0    = 0x0003
REG_ADDR_DUT_STAT1    = 0x0004
REG_ADDR_ABR_INSTR    = 0x0005
REG_ADDR_ABR_DBUFF_LO = 0x0040
REG_ADDR_ABR_DBUFF_HI = 0x2000
## ABR ML-DSA Register Addresses
ABR_ADDR_MLDSA_NAME        = 0x0000           
ABR_ADDR_MLDSA_VERSION     = 0x0008              
ABR_ADDR_MLDSA_CTRL        = 0x0010           
ABR_ADDR_MLDSA_STATUS      = 0x0014             
ABR_ADDR_ENTROPY           = 0x0018        
ABR_ADDR_MLDSA_SEED        = 0x0058           
ABR_ADDR_MLDSA_SIGN_RND    = 0x0078               
ABR_ADDR_MLDSA_MSG         = 0x0098          
ABR_ADDR_MLDSA_VERIFY_RES  = 0x00D8                 
ABR_ADDR_MLDSA_EXTERNAL_MU = 0x0118                  
ABR_ADDR_MLDSA_MSG_STROBE  = 0x0158                 
ABR_ADDR_MLDSA_CTX_CONFIG  = 0x015C                 
ABR_ADDR_MLDSA_CTX         = 0x0160          
ABR_ADDR_MLDSA_PUBKEY      = 0x1000             
ABR_ADDR_MLDSA_SIGNATURE   = 0x2000                
ABR_ADDR_MLDSA_PRIVKEY_OUT = 0x4000                  
ABR_ADDR_MLDSA_PRIVKEY_IN  = 0x6000       
## ABR ML-DSA Register sizes (words)
ABR_WRDS_MLDSA_NAME        = 2
ABR_WRDS_MLDSA_VERSION     = 2
ABR_WRDS_MLDSA_CTRL        = 1
ABR_WRDS_MLDSA_STATUS      = 1
ABR_WRDS_ENTROPY           = 16
ABR_WRDS_MLDSA_SEED        = 8
ABR_WRDS_MLDSA_SIGN_RND    = 8
ABR_WRDS_MLDSA_MSG         = 16
ABR_WRDS_MLDSA_VERIFY_RES  = 16
ABR_WRDS_MLDSA_EXTERNAL_MU = 16
ABR_WRDS_MLDSA_MSG_STROBE  = 1
ABR_WRDS_MLDSA_CTX_CONFIG  = 1
ABR_WRDS_MLDSA_CTX         = 64
ABR_WRDS_MLDSA_PUBKEY      = 648
ABR_WRDS_MLDSA_SIGNATURE   = 1157
ABR_WRDS_MLDSA_PRIVKEY_OUT = 1224
ABR_WRDS_MLDSA_PRIVKEY_IN  = 1224
## ABR ML-KEM Register Addresses
ABR_ADDR_MLKEM_NAME        = 0x9000           
ABR_ADDR_MLKEM_VERSION     = 0x9008              
ABR_ADDR_MLKEM_CTRL        = 0x9010           
ABR_ADDR_MLKEM_STATUS      = 0x9014             
ABR_ADDR_MLKEM_SEED_D      = 0x9018             
ABR_ADDR_MLKEM_SEED_Z      = 0x9038             
ABR_ADDR_MLKEM_SHARED_KEY  = 0x9058                 
ABR_ADDR_MLKEM_MSG         = 0x9080          
ABR_ADDR_MLKEM_DECAPS_KEY  = 0xA000                 
ABR_ADDR_MLKEM_ENCAPS_KEY  = 0xB000                 
ABR_ADDR_MLKEM_CIPHERTEXT  = 0xB800                        
## ABR ML-KEM Register sizes (words)
ABR_WRDS_MLKEM_NAME        = 2
ABR_WRDS_MLKEM_VERSION     = 2
ABR_WRDS_MLKEM_CTRL        = 1
ABR_WRDS_MLKEM_STATUS      = 1
ABR_WRDS_MLKEM_SEED_D      = 8
ABR_WRDS_MLKEM_SEED_Z      = 8
ABR_WRDS_MLKEM_SHARED_KEY  = 8
ABR_WRDS_MLKEM_MSG         = 8
ABR_WRDS_MLKEM_DECAPS_KEY  = 792
ABR_WRDS_MLKEM_ENCAPS_KEY  = 392
ABR_WRDS_MLKEM_CIPHERTEXT  = 392

# Identity register 32b value
CW_IDENTIFIER = 0x0123_4567

# Metadata for ABR
MLDSA_CORE_NAME    = [0x44534D4C, 0x3837412D]
MLDSA_CORE_VERSION = [0x302e322e, 0x00003300]
MLKEM_CORE_NAME    = [0x4D2D4B45, 0x32343130]
MLKEM_CORE_VERSION = [0x302e322e, 0x00003300]

# MLDSA_CTRL / MLKEM_CTRL ZEROIZE bit (bit 3, above the CTRL[2:0] command
# field). Unlike CTRL, ZEROIZE is not gated by abr_ready, so it is the only
# way to return the core from the post-op VALID state back to READY.
ABR_CTRL_ZEROIZE = 0x8

# MLKEM_CTRL.CTRL command encodings
ABR_MLKEM_CTRL_KEYGEN   = 0x1
ABR_MLKEM_CTRL_ENCAPS   = 0x2
ABR_MLKEM_CTRL_DECAPS   = 0x3
ABR_MLKEM_CTRL_KGDECAPS = 0x4

# MLDSA_STATUS / MLKEM_STATUS bit masks
ABR_STATUS_READY_BIT       = 0x1
ABR_STATUS_VALID_BIT       = 0x2
ABR_MLKEM_STATUS_ERROR_BIT = 0x4
ABR_MLDSA_STATUS_ERROR_BIT = 0x8

def fpga_addr2name(addr):
    match addr:
        case addr if addr == REG_ADDR_IDENT:
            return "REG_ADDR_IDENT"  
        case addr if addr == REG_ADDR_DUT_CTRL0:
            return "REG_ADDR_DUT_CTRL0"      
        case addr if addr == REG_ADDR_DUT_CTRL1:
            return "REG_ADDR_DUT_CTRL1"      
        case addr if addr == REG_ADDR_DUT_STAT0:
            return "REG_ADDR_DUT_STAT0"      
        case addr if addr == REG_ADDR_DUT_STAT1:
            return "REG_ADDR_DUT_STAT1"      
        case addr if addr == REG_ADDR_ABR_INSTR:
            return "REG_ADDR_ABR_INSTR"
        case addr if REG_ADDR_ABR_DBUFF_LO <= addr < REG_ADDR_ABR_DBUFF_HI:
            return "REG_ADDR_DBUFF"
        case _:
            raise ValueError('address not valid')


def fpga_check_addr(addr):
    match addr:
        case addr if 0x0000 <= addr <= 0x0005:
            return 0
        case addr if 0x0040 <= addr <= 0x83F: # DBUFF = 0x40 - 0x840
            return 0
        case _: # error
            raise ValueError('address not valid')
        

def fpga_check_data(data):
    if not (0 <= data <= 0xFFFF_FFFF):
        raise ValueError('data is not a valid 32b value!')


def fpga_read_word(target, addr): 
    fpga_check_addr(addr)
    result_bytes = target.fpga_read(addr, 4)
    # combine Bytes into word
    result_int   = (result_bytes[3] << 24) | (result_bytes[2] << 16) | (result_bytes[1] << 8) | result_bytes[0]
    if DBG_PRINT:
        print(f'[DEBUG] Read Word: \n\tADDR = {fpga_addr2name(addr)} \n\tDATA = 0x{result_int:08x}')
    return result_int


def fpga_read_words(target, start_addr, num_words):
    words     = []
    curr_addr = start_addr
    for word_idx in range(num_words):
        words.append(fpga_read_word(target, curr_addr))
        curr_addr += 1
    return words


def fpga_write_word(target, addr, data):
    fpga_check_addr(addr)
    fpga_check_data(data)
    data_bytes = bytearray(4)
    for byte_idx in range(4):
        data_bytes[byte_idx] = data & 0xFF
        data = data >> 8
    if DBG_PRINT:
        print(f'[DEBUG] Write Word: \n\tADDR = {fpga_addr2name(addr)} \n\tDATA = 0x{data:08x}')
    target.fpga_write(addr, data_bytes)

def fpga_write_words(target, start_addr, num_words, write_words):
    if len(write_words) != num_words:
        raise ValueError('num_words is not equal to the size of write_words array')
    curr_addr = start_addr
    for word in range(num_words):
        fpga_write_word(target, curr_addr, write_words[word])
        curr_addr += 1

# op encoding: 0 = read, 1 = write
def fpga_exec_instr(target, abr_addr, xfer_len_words, op):

    # Validate instruction fields
    if not (0 <= abr_addr <= 0xFFFF):
        raise ValueError('ABR address field of instruction must be within 0x0000 - 0xFFFF')
    if not (0 < xfer_len_words <= 0x800):
        raise ValueError('Len field of instruction must be 0 - 2048 words')
    if op not in [0,1]:
        raise ValueError('Op field of instruction must be 0 (read) or 1 (write)')
    
    # Create instruction with the following fields
    ## 31:16 - abr_addr
    ## 15: 4 - xfer_len_words
    ##  3: 0 - op
    instruction = ((abr_addr & 0xFFFF) << 16) | ((xfer_len_words & 0xFFF) << 4) | (op & 0x1)
    # write instruction
    fpga_write_word(target, REG_ADDR_ABR_INSTR, instruction)
    # initiate instruction rd/mod/wr
    dut_ctrl1_tmp = fpga_read_word(target, REG_ADDR_DUT_CTRL1)
    dut_ctrl1_tmp = dut_ctrl1_tmp | (0x1) # set bit 0 to execute
    fpga_write_word(target, REG_ADDR_DUT_CTRL1, dut_ctrl1_tmp) # write back
    dut_ctrl1_tmp = dut_ctrl1_tmp & ~(0x1) # clear bit 0
    fpga_write_word(target, REG_ADDR_DUT_CTRL1, dut_ctrl1_tmp) # write back

    # wait for busy to be cleared
    busy = 1
    err  = 0
    while busy == 1:
        dut_stat1_tmp = fpga_read_word(target, REG_ADDR_DUT_STAT1)
        busy          = dut_stat1_tmp & 0x1
        err           = dut_stat1_tmp & 0x2
        if err:
            assert err == 0, 'Instruction execution error detected'
    
    return


def dut_assert_reset(target):
    dut_ctrl0_tmp = fpga_read_word(target, REG_ADDR_DUT_CTRL0)
    dut_ctrl0_tmp &= ~(0x1)
    fpga_write_word(target, REG_ADDR_DUT_CTRL0, dut_ctrl0_tmp)

    reset_status = 1

    while reset_status == 1:
        dut_stat0_tmp = fpga_read_word(target, REG_ADDR_DUT_STAT0)
        reset_status  = dut_stat0_tmp & 0x1

    print("[INFO] DUT in reset!") 


def dut_deassert_reset(target):
    dut_ctrl0_tmp = fpga_read_word(target, REG_ADDR_DUT_CTRL0)
    dut_ctrl0_tmp |= 0x1
    fpga_write_word(target, REG_ADDR_DUT_CTRL0, dut_ctrl0_tmp)

    reset_status = 0

    while reset_status == 0:
        dut_stat0_tmp = fpga_read_word(target, REG_ADDR_DUT_STAT0)
        reset_status  = dut_stat0_tmp & 0x1

    print("[INFO] DUT out of reset!") 


def fpga_verify_ident_reg(target):

    ident_tmp = fpga_read_word(target, REG_ADDR_IDENT)
    assert ident_tmp == CW_IDENTIFIER, 'Result from identity register read did not match expected value'

    print("[INFO] CW_IDENTIFIER Register successfully verified!") 


def dut_reg_read(target, abr_reg_addr, abr_reg_wrds):

    # create instruction to read ML-DSA name
    instr_addr     = abr_reg_addr
    instr_len_wrds = abr_reg_wrds
    instr_op       = 0 # read

    fpga_exec_instr(target, instr_addr, instr_len_wrds, instr_op)

    reg_words = fpga_read_words(target, REG_ADDR_ABR_DBUFF_LO, abr_reg_wrds)

    return reg_words


def dut_reg_write(target, abr_reg_addr, abr_reg_wrds, write_data):

    if len(write_data) != abr_reg_wrds:
        raise ValueError('Number of write data elements must match abr_reg_wrds!')

    # create instruction to read ML-DSA name
    instr_addr     = abr_reg_addr
    instr_len_wrds = abr_reg_wrds
    instr_op       = 1 # write

    fpga_write_words(target, REG_ADDR_ABR_DBUFF_LO, abr_reg_wrds, write_data)

    fpga_exec_instr(target, instr_addr, instr_len_wrds, instr_op)

    return 


def dut_mldsa_verify_meta(target):

    mldsa_name_words = dut_reg_read(target, ABR_ADDR_MLDSA_NAME, ABR_WRDS_MLDSA_NAME)
    assert mldsa_name_words == MLDSA_CORE_NAME, 'ML-DSA Core Name does not match expected value'
    mldsa_vers_words = dut_reg_read(target, ABR_ADDR_MLDSA_VERSION, ABR_WRDS_MLDSA_VERSION)
    assert mldsa_vers_words == MLDSA_CORE_VERSION, 'ML-DSA Core Version does not match expected value'

    print("[INFO] ML-DSA NAME/VERSION Registers successfully verified!") 


def dut_mlkem_verify_meta(target):

    mlkem_name_words = dut_reg_read(target, ABR_ADDR_MLKEM_NAME, ABR_WRDS_MLKEM_NAME)
    assert mlkem_name_words == MLKEM_CORE_NAME, 'ML-KEM Core Name does not match expected value'
    mlkem_vers_words = dut_reg_read(target, ABR_ADDR_MLKEM_VERSION, ABR_WRDS_MLKEM_VERSION)
    assert mlkem_vers_words == MLKEM_CORE_VERSION, 'ML-KEM Core Version does not match expected value'

    print("[INFO] ML-KEM NAME/VERSION Registers successfully verified!")


def dut_mlkem_wait_for_ready(target):
    
    while True:
        mlkem_status = dut_reg_read(target, ABR_ADDR_MLKEM_STATUS, ABR_WRDS_MLKEM_STATUS)
        # check ready bit
        if (mlkem_status[0] & ABR_STATUS_READY_BIT):
            break
        # check valid bit, if set, zeroise must be triggered before core can be used again
        if (mlkem_status[0] & ABR_STATUS_VALID_BIT):
            print("[INFO] ML-KEM is parked in VALID... issuing a ZEROIZE operation...")
            abr_ctrl_data = [0] * ABR_WRDS_MLKEM_CTRL
            abr_ctrl_data[0] = ABR_CTRL_ZEROIZE
            dut_reg_write(target, ABR_ADDR_MLKEM_CTRL, ABR_WRDS_MLKEM_CTRL, abr_ctrl_data)
    
    print("[INFO] ML-KEM is ready!")


def dut_mlkem_wait_for_valid(target):
    
    while True:
        mlkem_status = dut_reg_read(target, ABR_ADDR_MLKEM_STATUS, ABR_WRDS_MLKEM_STATUS)
        
        # check error bit
        assert (mlkem_status[0] & ABR_MLDSA_STATUS_ERROR_BIT) == 0, 'ML-KEM error bit detected!'

        # check valid bit
        if (mlkem_status[0] & ABR_STATUS_VALID_BIT):
            break
    
    print("[INFO] ML-KEM valid is set!")


def dut_mlkem_keygen(target, seed_d, seed_z, entropy):
    
    dut_mlkem_wait_for_ready(target)
    
    dut_reg_write(target, ABR_ADDR_MLKEM_SEED_D, ABR_WRDS_MLKEM_SEED_D, seed_d)
    dut_reg_write(target, ABR_ADDR_MLKEM_SEED_Z, ABR_WRDS_MLKEM_SEED_Z, seed_z)
    dut_reg_write(target, ABR_ADDR_ENTROPY, ABR_WRDS_ENTROPY, entropy)

    abr_ctrl_data = [0] * ABR_WRDS_MLKEM_CTRL
    abr_ctrl_data[0] = ABR_MLKEM_CTRL_KEYGEN
    dut_reg_write(target, ABR_ADDR_MLKEM_CTRL, ABR_WRDS_MLKEM_CTRL, abr_ctrl_data)

    # wait for valid
    dut_mlkem_wait_for_valid(target)

    ek = dut_reg_read(target, ABR_ADDR_MLKEM_ENCAPS_KEY, ABR_WRDS_MLKEM_ENCAPS_KEY)
    dk = dut_reg_read(target, ABR_ADDR_MLKEM_DECAPS_KEY, ABR_WRDS_MLKEM_DECAPS_KEY)

    print("[INFO] ML-KEM Keygen Complete!")
    print(f"Encaps Key ({len(ek)} words) first/last : 0x{ek[0]:08X} / 0x{ek[-1]:08X}")
    print(f"Decaps Key ({len(dk)} words) first/last : 0x{dk[0]:08X} / 0x{dk[-1]:08X}")

    return (ek, dk)


def dut_mlkem_encaps(target, msg, ek, entropy):

    dut_mlkem_wait_for_ready(target)

    dut_reg_write(target, ABR_ADDR_MLKEM_MSG, ABR_WRDS_MLKEM_MSG, msg)
    dut_reg_write(target, ABR_ADDR_MLKEM_ENCAPS_KEY, ABR_WRDS_MLKEM_ENCAPS_KEY, ek)
    dut_reg_write(target, ABR_ADDR_ENTROPY, ABR_WRDS_ENTROPY, entropy)

    abr_ctrl_data = [0] * ABR_WRDS_MLKEM_CTRL
    abr_ctrl_data[0] = ABR_MLKEM_CTRL_ENCAPS
    dut_reg_write(target, ABR_ADDR_MLKEM_CTRL, ABR_WRDS_MLKEM_CTRL, abr_ctrl_data)

    # wait for valid
    dut_mlkem_wait_for_valid(target)

    ct = dut_reg_read(target, ABR_ADDR_MLKEM_CIPHERTEXT, ABR_WRDS_MLKEM_CIPHERTEXT)
    ss = dut_reg_read(target, ABR_ADDR_MLKEM_SHARED_KEY, ABR_WRDS_MLKEM_SHARED_KEY)

    print("[INFO] ML-KEM Encaps Complete!")
    print(f"Ciphertext ({len(ct)} words) first/last : 0x{ct[0]:08X} / 0x{ct[-1]:08X}")
    print(f"Shared Key ({len(ss)} words) first/last : 0x{ss[0]:08X} / 0x{ss[-1]:08X}")

    return (ct, ss)


def dut_mlkem_decaps(target, dk, ct, entropy):

    dut_mlkem_wait_for_ready(target)

    dut_reg_write(target, ABR_ADDR_MLKEM_DECAPS_KEY, ABR_WRDS_MLKEM_DECAPS_KEY, dk)
    dut_reg_write(target, ABR_ADDR_MLKEM_CIPHERTEXT, ABR_WRDS_MLKEM_CIPHERTEXT, ct)
    dut_reg_write(target, ABR_ADDR_ENTROPY, ABR_WRDS_ENTROPY, entropy)

    abr_ctrl_data = [0] * ABR_WRDS_MLKEM_CTRL
    abr_ctrl_data[0] = ABR_MLKEM_CTRL_DECAPS
    dut_reg_write(target, ABR_ADDR_MLKEM_CTRL, ABR_WRDS_MLKEM_CTRL, abr_ctrl_data)

    # wait for valid
    dut_mlkem_wait_for_valid(target)

    ss = dut_reg_read(target, ABR_ADDR_MLKEM_SHARED_KEY, ABR_WRDS_MLKEM_SHARED_KEY)

    print("[INFO] ML-KEM Decaps Complete!")
    print(f"Shared Key ({len(ss)} words) first/last : 0x{ss[0]:08X} / 0x{ss[-1]:08X}")

    return ss