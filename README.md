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

## GPIO Verification
### 1. RTL for parity generation and checking

An input PARITYSEL and an output PARITYERR were added. GPIOIN and GPIOOUT were made to be 17 bits, where the MSB is reserved for parity bit.
The internal register gpio_datain and gpio_dataout were also increased to 17 bits, where the MSB is the parity bit.
Parity generation is done directly in always block, where the output value is updated:
```
//Generate parity bit, PARITYSEL = 1 is for odd parity (XNOR), 0 for even parity (XOR)
gpio_dataout <= {PARITYSEL ? ~^HWDATA[15:0] : ^HWDATA[15:0], HWDATA[15:0]};
```

Parity checking is done in the always block that updates the input value:
```
else if (gpio_dir == 16'h0000) begin
    //Check parity bit of GPIOIN, flag PARITYERR if incorrect
    if(GPIOIN[16]!=(PARITYSEL ? ~^GPIOIN[15:0] : ^GPIOIN[15:0])) PARITYERR <= 1'b1;
    else PARITYERR <= 1'b0;
    //Transfer proceeds even if parity bit is wrong
    gpio_datain <= GPIOIN;
end
```

According to specification, parity bit of GPIOOUT is not checked, only generated. 
Moreover, to check parity bit of GPIOOUT in the same module it was created is redundant since generation is formally verified.
The PARITYERR signal goes high when there is incorrect parity in GPIOIN during a direction of 0. Since the use of PARITYERR is not clear, the signal is
not cleared when HRESETn is asserted. It is cleared however, when a new GPIOIN is passed that has correct parity. That is how we interpreted the specification.

### 2. Verification plan for GPIO

### 3. Testbench for GPIO

The testbench architecture is divided into subblocks:
1. A transaction class that contains the constrained stimulus and a generator that generates a specified number of transactions and puts them in a mailbox.
2. A driver that gets transactions from the mailbox and drives the GPIO. The driver has multiple tasks, where each one drives the DUT in a different way
to test its functionality and get 100% functional coverage.
3. A monitor that gets information from GPIO every cycle and puts the relevant information in a mailbox.
4. A scoreboard that gets the information from the monitor's mailbox and flags an error if data is incorrect/unexpected.
5. Interface that connects to the driver, monitor and DUT
6. Environment that connects and instantiates all of the subblocks (except interface, which is instatiated in top-level) and contains higher level tasks
that can be used to create different tests. 
7. Multiple test files that test the functionality of the GPIO. The number of transactions is specified in the test block.
8. Top-level file that creates the clock, instantiates an interface, DUT and test block.

We decided to use this architecture to learn how to write readable and reusable code, which has powerful functionality and flexibility. 
Indeed, most of the code was reused for the VGA verification. 

----

The transaction class randomises the following signals:
1. PARITYSEL 
2. write_cycle -> 1 will drive GPIOOUT, 0 will drive GPIOIN
3. inject_parity_error -> when high, GPIOIN will have an incorrect parity bit (injected in post randomise function)
4. command_signals[2:0] ->    [0]->HREADY, [1]->HSEL, [2]->HTRANS[1]
5. dir_inject -> when high, driver will inject wrong value to direction register
6. HWDATA_dir_inject -> the wrong value injected to direction register
7. HWDATA_data -> data that will be put into GPIOOUT
8. HWDATA_upper_bits -> upper 16 bits are not used in GPIO, so most of the time they are zero, but sometimes they are not zero 
9. GPIOIN -> least significant 16 bits are randomised and in post randomise, the parity bit is calculated
10. inject_wrong_address[1:0] -> LSB for direction phase, MSB for data phase, 
11. HADDR_inject -> value to inject if either bits of inject_wrong_address are high

Moreover, the class has a counter, so that every X cycles, max or min of a signal is applied. To avoid constraint contradiction, min values are soft constraints.
The generator does not create a new class everytime, but randomises the same one in order for the counter inside the class to work.
A copy function was created, so that the copied transaction is put into the mailbox.

----

The driver has the following main tasks:
1. Reset task that resets the driving signals for one cycle and asserts the HRESETn signal for a specified number of cycles.
2. Random reset task that forever asserts the reset signal for a random number of cycles with a random delay between reset assertions
3. Main drive task, which has inputs to choose whether random reset is active and what type of drive procedure to use
4. Simple drive procedure, which needs two cycles (except in cases where HREADY needs to change) -> 1 cycle to change direction, 1 cycle to drive the data
5. Same task as 4. but with random delay between each drive transaction
6. Drive task, which tries to drive a transaction every cycle without loss of information. To elaborate, if next transaction has the same direction, 
there is no need of address phase to change gpio_dir.
7. Same task as 4. but drives both HWDATA and GPIOIN -> tests that only one of them can be seen on the output depending on direction reg

----

The checker consists of both the monitor and the scoreboard. Monitor tracks the direction register and tells the scoreboard.
Scoreboard then checks whether GPIOIN appears on HRDATA one cycle later if direction was 0 or HWDATA appears on GPIOOUT 1 cycle later.
Scoreboard also uses PARITYSEL of previous cycle to check whether PARITYERR has the correct value (only checked when direction is 0).

### 4. Functional and code coverage

Coverage report can be inspected by opening the html file covsummary.html in folder GPIO-Verf/covhtmlreport: [Coverage Report link](https://github.com/NikolayMiladinov/Hardware-Verification-Coursework/tree/master/GPIO-Verf/covhtmlreport)

Functional coverage was done in the interface to simplify sampling and access to signals.
The covergroups are:
1. parity_injection -> checks the cross coverage of PARITYERR and PARITYSEL, but also has a coverpoint that checks whether PARITYERR has the correct value.
If PARITYERR is incorrectly flagged, then an illegal bin will be hit, which would show up in the coverage report.
2. Same as 1. but checks that a parity_error was injected during a reset. This checks that the error will not be recognised if HRESETn is low
3. parity_gen_and_check -> cross coverage between PARITYSEL and GPIOIN; and between PARITYSEL and GPIOOUT
4. Separate coverpoints (no cross coverage) for GPIOIN, HWDATA, HRDATA, GPIOOUT, HADDR, gpio_dir

Sampling of HWDATA and HADDR (has illegal bin for invalid GPIO addresses) is done only when HSEL is high because that is when the peripheral is selected.
Sampling of gpio_dir happens on the next cycle after a value is written to it.
Sampling of GPIOIN, GPIOOUT and HRDATA happens every cycle if HRESETn is high.
Sampling of parity injection is done on next cycle after gpio_dir is 0 (keeps sampling if gpio_dir stays 0).
Sampling of parity injection during reset happens every cycle.
Sampling of parity_gen_and_check happens every cycle if HRESETn is high.

Code coverage was done automatically by questasim using the command *vlog +cover +fcover* and *vsim -coverage -voptargs="+cover=bcefst"*
Toggle coverage was diabled for HREADYOUT, HRDATA[31:16], HTRANS[0], HADDR[31:24].

### 5. Assertions

The following assertions were embedded in the GPIO rtl, all sampled on positive edge of HCLK and disabled if HRESETn is low:
[Link to GPIO rtl](https://github.com/NikolayMiladinov/Hardware-Verification-Coursework/blob/master/GPIO-Verf/rtl/AHB_GPIO/AHBGPIO.sv)
1. If gpio_dir==0, on the next cycle HRDATA[15:0]==$past(GPIOIN[15:0])
2. If conditions for write to GPIOOUT were satisfied, on the next cycle GPIOOUT[15:0]==$past(HWDATA[15:0])
3. GPIOOUT changes only when writing conditions are met on previous cycle (similar to 2.)
4. If conditions for write to gpio_dir were satisfied, on the next cycle gpio_dir[15:0]==$past(HWDATA[15:0])
5. gpio_dir changes only when writing conditions are met on previous cycle (similar to 4.)
6. If GPIOOUT changes, it's parity is correct depending on PARITYSEL in previous cycle
7. If gpio_dir==0, on next cycle checks whether PARITYERR is correct using previous cycle values of GPIOIN and PARITYSEL
8. PARITYERR changes only if on previous cycle gpio_dir==0


![GPIO Formal Verification](https://github.com/NikolayMiladinov/Hardware-Verification-Coursework/blob/master/Formal%20Verification%20of%20GPIO%20assertions.jpg)



