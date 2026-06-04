## reg map for CW ABR Test Setup

| Base Address | End Address | Field | Notes |
| ---      | --- | --- | --- |
| `0x0000` | `0x0004` | `DUT_CTRL0` | R/W |
| `0x0004` | `0x0008` | `DUT_CTRL1` | R/W |
| `0x0008` | `0x000C` | `DUT_STAT0` | Read-only |
| `0x000C` | `0x0010` | `DUT_STAT1` | Read-only |
| `0x0010` | `0x0014` | `ABR_INSTR` | R/W |
| `0x0100` | `0x0900` | `ABR_DBUFF` | R/W - 2048 Byte data buffer |