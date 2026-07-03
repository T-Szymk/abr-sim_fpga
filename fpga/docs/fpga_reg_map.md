## reg map for CW ABR Test Setup

| Base Address | Field       | Notes                       |
| ---          | ---         | ---                         |
| `0x0000`     | `IDENT`     | Read-only                   |
| `0x0001`     | `DUT_CTRL0` | R/W                         |
| `0x0002`     | `DUT_CTRL1` | R/W                         |
| `0x0003`     | `DUT_STAT0` | Read-only                   |
| `0x0004`     | `DUT_STAT1` | Read-only                   |
| `0x0005`     | `ABR_INSTR` | R/W                         |
| `0x0040`     | `ABR_DBUFF` | R/W - 8192 Byte data buffer |

### Register bitfields 

#### IDENT 

_FPGA identifier_

| Bits     | Identifier  | Access | Reset | Notes       |
| :------- | :---------- | :----- | :---- | :---        |
| \[31:0\] | ID_STRING   | R/W    | 0x0   | 0x0123_4567 |

#### DUT_CTRL0 

_Controls for DUT (ABR Instance)_

| Bits     | Identifier  | Access | Reset | Notes                                |
| :------- | :---------- | :----- | :---- | :---                                 |
| \[31:1\] | _reserved_  | \-     | \-    | \-                                   |
| \[0\]    | DUT_nRST    | R/W    | 0x0   | Controls Reset of ABR DUT (not FPGA) |

#### DUT_CTRL1 

_Controls for platform (FPGA components surrounding DUT)_

| Bits     | Identifier  | Access | Reset | Notes                                                  |
| :------- | :---------- | :----- | :---- | :---                                                   |
| \[31\]   | USRLED5     | \-     | \-    | Programmable LED for debug                             |
| \[30:1\] | _reserved_  | \-     | \-    | \-                                                     |
| \[0\]    | INSTR_RUN   | R/W    | 0x0   | Commit instruction contained within ABR_INSTR register |

#### DUT_STAT0 

_Status of DUT (ABR Instance)_

| Bits     | Identifier    | Access | Reset | Notes                   |
| :------- | :----------   | :----- | :---- | :---                    |
| \[31:2\] | _reserved_    | \-     | \-    | \-                      |
| \[1\]    | DUT_BUSY      | R/W    | 0x0   | Busy status of ABR DUT  |
| \[0\]    | DUT_RST_STAT  | R/W    | 0x0   | Reset status of ABR DUT |

#### DUT_STAT1 

_Status of platform (FPGA components surrounding DUT)_

| Bits     | Identifier    | Access | Reset | Notes                            |
| :------- | :----------   | :----- | :---- | :---                             |
| \[31:2\] | _reserved_    | \-     | \-    | \-                               |
| \[1\]    | XFER_ERR      | R/W    | 0x0   | Memory transfer error            |
| \[0\]    | INSTR_BUSY    | R/W    | 0x0   | Status of instruction processing |


#### ABR_INSTR 

_Instruction register to send read/write commands to DUT_  

| Bits      | Identifier  | Access | Reset | Notes                                       |
| :-------  | :---------- | :----- | :---- | :---                                        |
| \[31:16\] | ABR_ADDR    | R/W    | 0x0   | AHB Register address for ABR read/write op. |
| \[15: 4\] | LEN_WRDS    | \-     | \-    | Length of access (in 32b/4B words)          |
| \[3 : 0\] | OP_CODE     | R/W    | 0x0   | Operation                                   |

Data buffer is a 8kB scratchpad memory and therefore does not use any encoding.

##### Operation Encoding

| Code      | Identifier  | Notes                                                             |
| :-------  | :---------- | :-----                                                            |
| 4b'000    | READ        | Read `SIZE_WRDS`*4 Bytes from `ABR_ADDR` and store in data buffer |
| 4b'001    | WRITE       | Write `SIZE_WRDS`*4 Bytes from data buffer to `ABR_ADDR`          |
| _others_  | \-          | _Reserved_                                                        |
