## reg map for CW ABR Test Setup

| Base Address | End Address | Field       | Notes                       |
| ---          | ---         | ---         | ---                         |
| `0x0000`     | `0x0004`    | `DUT_CTRL0` | R/W                         |
| `0x0004`     | `0x0008`    | `DUT_CTRL1` | R/W                         |
| `0x0008`     | `0x000C`    | `DUT_STAT0` | Read-only                   |
| `0x000C`     | `0x0010`    | `DUT_STAT1` | Read-only                   |
| `0x0010`     | `0x0014`    | `ABR_INSTR` | R/W                         |
| `0x0100`     | `0x0900`    | `ABR_DBUFF` | R/W - 2048 Byte data buffer |

### Register bitfields 

#### DUT_CTRL0

| Bits     | Identifier  | Access | Reset | Notes                 |
| :------- | :---------- | :----- | :---- | :---                  |
| \[31:1\] | _reserved_  | \-     | \-    | \-                    |
| \[0\]    | DUT_nRST    | R/W    | 0x0   | Controls Reset of ABR |

#### DUT_CTRL1

| Bits     | Identifier  | Access | Reset | Notes                                         |
| :------- | :---------- | :----- | :---- | :---                                          |
| \[31:1\] | _reserved_  | \-     | \-    | \-                                            |
| \[0\]    | INSTR_RUN   | R/W    | 0x0   | Process instruction within ABR_INSTR register |

#### DUT_STAT0

| Bits     | Identifier    | Access | Reset | Notes               |
| :------- | :----------   | :----- | :---- | :---                |
| \[31:2\] | _reserved_    | \-     | \-    | \-                  |
| \[1\]    | DUR_BUSY      | R/W    | 0x0   | Busy status of ABR  |
| \[0\]    | DUT_RST_STAT  | R/W    | 0x0   | Reset status of ABR |

#### DUT_STAT1

| Bits     | Identifier    | Access | Reset | Notes                            |
| :------- | :----------   | :----- | :---- | :---                             |
| \[31:2\] | _reserved_    | \-     | \-    | \-                               |
| \[1\]    | XFER_ERR      | R/W    | 0x0   | Memory transfer error            |
| \[0\]    | INSTR_BUSY    | R/W    | 0x0   | Status of instruction processing |


#### ABR_INSTR

| Bits      | Identifier  | Access | Reset | Notes                                       |
| :-------  | :---------- | :----- | :---- | :---                                        |
| \[31:16\] | ABR_ADDR    | R/W    | 0x0   | AHB Register address for ABR read/write op. |
| \[15: 4\] | LEN_WRDS    | \-     | \-    | Length of access (in 32b/4B words)          |
| \[3 : 0\] | OP_CODE     | R/W    | 0x0   | Operation                                   |

##### Operation Encoding

| Code      | Identifier  | Notes                                                             |
| :-------  | :---------- | :-----                                                            |
| 4b'000    | READ        | Read `SIZE_WRDS`*4 Bytes from `ABR_ADDR` and store in data buffer |
| 4b'001    | WRITE       | Write `SIZE_WRDS`*4 Bytes from data buffer to `ABR_ADDR`          |
| _others_  | \-          | _Reserved_                                                        |
