# SoomRV

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)



## Description
SoomRV is a simple superscalar Out-of-Order RISC-V microprocessor. It can execute up to 4 Instructions per cycle completely out of order,
and also supports speculative execution and precise exceptions.

## Features
- RV32IMCZfinxZbaZbbZicbom Instruction Set (other instructions can be emulated via traps)
- 4-wide, Ports: 2 Integer/FP, 1 Load, 1 Store
- Fully Out-of-Order Load/Store
- TAGE-Predictor with 64-entry 8-way associative BTB.
- Tag-based OoO execution, 64 registers
- 64 entry Reorder Buffer
- 4KiB ICache + 4KiB DCache
- 32-bit bus (on GPIOs) for memory expansion

## Repo
The Verilog source files can be found in `verilog/rtl`. These are converted from SystemVerilog via zachjs' [sv2v](https://github.com/zachjs/sv2v),
the original SystemVerilog source code is available [here](https://github.com/git-mathis/SoomRV).
