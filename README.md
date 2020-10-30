# SDRAM Tester FPGA

This repository contains a source code of the SDRAM Tester implemented in FPGA. The SDRAM tester generates writes and reads to random or sequential addresses, checks the read data, and measures throughput. The project was created during the [European FPGA Developer Contests 2020](https://www.arrow.com/en/research-and-events/events/fpga-developer-contest-2020).

* Development board [CYC1000](https://shop.trenz-electronic.de/en/Products/Trenz-Electronic/CYC1000-Intel-Cyclone-10/) with [W9864G6JT](https://www.winbond.com/resource-files/w9864g6jt_a03.pdf) SDRAM chip, [documentation](https://www.trenz-electronic.de/fileadmin/docs/Trenz_Electronic/Modules_and_Module_Carriers/2.5x6.15/TEI0003/REV02/Documents/CYC1000%20User%20Guide.pdf), [driver](https://shop.trenz-electronic.de/en/TEI0003-02-CYC1000-with-Cyclone-10-FPGA-8-MByte-SDRAM?path=Trenz_Electronic/Modules_and_Module_Carriers/2.5x6.15/TEI0003/Driver/Arrow_USB_Programmer)
* Languages - VHDL, Python

The project is using the following open-source codes:

- https://github.com/nullobject/sdram-fpga - The simple SDRAM controller by Josh Bassett
- https://github.com/zhelnio/ahb_lite_sdram - The SDRAM controller for MIPSfpga+ system by Stanislav Zhelnio

To clone the repository, run:

```bash
git clone --recursive git@github.com:jakubcabal/sdram-tester-fpga.git
```

## FPGA design

### Parameters (Top level generics)

Name | Type | Default | Generic description
---|:---:|:---:|:---
SDRAM_CTRL_SEL | natural | 0 | SDRAM controller selection: 0 = sdram-fpga by Josh Bassett (nullobject), 1 = ahb_lite_sdram by Stanislav Zhelnio (zhelnio).

### Top level diagram
```
         +----+----+
UART <---| UART2WB |
PORT --->| MASTER  |
         +---------+
              ↕
      +=======+======+ WISHBONE BUS
      ↕              ↕
 +----+----+    +----+----+
 | SDRAM   |    | SYSTEM  |
 | TESTER  |    | MODULE  |
 +---------+    +---------+
      ↕
      + ---> LEDs
      ↕
 +----+----+ 
 | SDRAM   | 
 | CTRL    | 
 +----+----+
      ↕
    SDRAM
```

### Main modules description

* UART2WB MASTER - Transmits the Wishbone requests and responses via UART interface (Wishbone master).
* SYSTEM MODULE - Basic system control and status registers (version, debug space etc.).
* SDRAM TESTER - Read and write request generator for SDRAM controller, checking read data.
* SDRAM CTRL - Selected SDRAM controller.

### Resource usage of the whole design:

SDRAM_CTRL_SEL | LE | FF | BRAM (M9k) | Fmax
:---:|:---:|:---:|:---:|:---:
0 (sdram-fpga) | 902 | 650 | 0 | 111.7 MHz
1 (ahb_lite_sdram) | 1071 | 703 | 0 | 124.6 MHz

*Implementation was performed using Quartus Prime Lite Edition 20.1.0 for FPGA Intel Cyclone 10 LP 10CL025YU256C8G.*

## SDRAM tests:

### How to run tests:

* Connect the CYC1000 board to the PC with a USB cable.
* Upload to FPGA design with SDRAM Tester.
* Run Python script ([PySerial](https://pyserial.readthedocs.io/en/latest/shortintro.html) is required):

```bash
python .\sw\run_tests.py
```

### Measured throughput:

SDRAM_CTRL_SEL | SEQ WR | SEQ RD | RAND WR | RAND RD
:---:|:---:|:---:|:---:|:---:
0 (sdram-fpga)     | 398.46 Mbps | 531.27 Mbps | 398.46 Mbps | 531.27 Mbps
1 (ahb_lite_sdram) | 318.32 Mbps | 265.27 Mbps | 318.32 Mbps | 265.27 Mbps

*Tests was performed using selected SDRAM controller running at 100 MHz with configuration: CAS latency = 2, Burst length = 2.*

## License
The project is available under the MIT license (MIT). Please read [LICENSE file](LICENSE).