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
    // FPGA configuration params
    // -----------------------------------------------------------------------
    localparam int unsigned LED_COUNT           =  8;

    localparam int unsigned USB_DATA_WIDTH      =  8;
    localparam int unsigned USB_ADDR_WIDTH      = 20;
    localparam int unsigned USB_BCOUNT_SIZE     =  2;
    localparam int unsigned USB_WORD_ADDR_WIDTH = USB_ADDR_WIDTH - USB_BCOUNT_SIZE;

    localparam int unsigned CLK_SETTINGS_WIDTH = 5;

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
    localparam int unsigned RAM_DEPTH      = 8192 / RAM_COUNT;                    // Depth of each byte-lane BRAM (8192-byte buffer in total). Must be large enough to hold the largest ABR register block (MLDSA_PRIVKEY = 4896 Bytes).
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
    localparam int unsigned CW_REG_DATA_WIDTH       = 32;
    localparam int unsigned CW_REG_DATA_WIDTH_BYTES = CW_REG_DATA_WIDTH / 8;

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
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_DUT_CTRL0 = 'h00;
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_DUT_CTRL1 = 'h04;
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_DUT_STAT0 = 'h08;
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_DUT_STAT1 = 'h0C;
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_ABR_INSTR = 'h10;

    // ABR_DBUFF — 8192-byte data buffer, forwarded to an external module.
    // Access within this range is NOT stored here; writes are forwarded as a
    // pulsed strobe and reads are returned from an external input port.
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_ABR_DBUFF_BASE = 'h0100;  // inclusive
    localparam logic [USB_ADDR_WIDTH-1:0] CW310_ADDR_ABR_DBUFF_END  = 'h2100;  // exclusive
    localparam int unsigned CW310_ABR_DBUFF_ADDR_W    =            // = 13
        $clog2(CW310_ADDR_ABR_DBUFF_END - CW310_ADDR_ABR_DBUFF_BASE);

endpackage
