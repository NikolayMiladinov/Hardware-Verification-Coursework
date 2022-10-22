# Hardware Verification Coursework

Module: ELEC70056 - Hardware and Software Verification

## Task: Adding Error-Detection to and Fully Verifying AHB GPIO and VGA Peripherals

### Objectives:
1. Modify GPIO RTL and add parity generation/checking
2. Instantiate a redundant VGA peripheral block plus add RTL for a comparator
3. Create unit-level constrained random testbenches written in SystemVerilog
4. Add appropriate SystemVerilog assertions (SVA) to cover design intent and describe the behaviour of the interfaces
5. Prove some properties using Formal verification
6. Develop checkers for the GPIO and VGA peripheral behaviour
7. Write functional coverage and demonstrate it has been achieved
8. Demonstrate integration and verification at the Cortex-M0 SOC level


##GPIO Architecture
![GPIO Architecture](https://github.com/NikolayMiladinov/Hardware-Verification-Coursework/GPIO-Architecture.jpg)


##VGA Architecture
![VGA Architecture](https://github.com/NikolayMiladinov/Hardware-Verification-Coursework/VGA-Architecture.jpg)