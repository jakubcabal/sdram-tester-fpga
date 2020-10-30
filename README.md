# SDRAM Tester FPGA

WORK IN PROGRESS

This repository contains a source code of the SDRAM Tester implemented in FPGA. The project was created during the [European FPGA Developer Contests 2020](https://www.arrow.com/en/research-and-events/events/fpga-developer-contest-2020).

* Development board [CYC1000](https://shop.trenz-electronic.de/en/Products/Trenz-Electronic/CYC1000-Intel-Cyclone-10/), [documentation](https://www.trenz-electronic.de/fileadmin/docs/Trenz_Electronic/Modules_and_Module_Carriers/2.5x6.15/TEI0003/REV02/Documents/CYC1000%20User%20Guide.pdf), [driver](https://shop.trenz-electronic.de/en/TEI0003-02-CYC1000-with-Cyclone-10-FPGA-8-MByte-SDRAM?path=Trenz_Electronic/Modules_and_Module_Carriers/2.5x6.15/TEI0003/Driver/Arrow_USB_Programmer)
* Languages - VHDL, Python

The project is using the following open-source codes:

- https://github.com/nullobject/sdram-fpga - The simple SDRAM controller by Josh Bassett
- https://github.com/zhelnio/ahb_lite_sdram - The SDRAM controller for MIPSfpga+ system by Stanislav Zhelnio

To clone the repository, run:

```bash
git clone --recursive https://github.com/jakubcabal/sdram-tester-fpga.git
```

## Top level diagram
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

## Main modules description

* UART2WB MASTER - Transmits the Wishbone requests and responses via UART interface (Wishbone bus master module).
* SYSTEM MODULE - Basic system control and status registers (version, debug space etc.) accessible via Wishbone bus.
* SDRAM TESTER - Read and write request generator for SDRAM controller, checking read data.
* SDRAM CTRL - Selected SDRAM controller.
