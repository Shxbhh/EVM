The repository contains the details of the project wherein I designed an EVM by leveraging the principles of digital design and Verilog, and implemented the same on a Xilinx Basys 3 FPGA.
The EVM opens iff a secret code entered by the polling agent matches the secret code fed into its database, thereby ensuring a fair electroal process. Currently I am trying to 
implement the provision of biometric authentication by interfacing the FPGA with a R305 fingerprint sensor.
The machine developed moves to the 'Open' state upon entering the secret code. Subsequently, votes are cast by the electorate for the various candidates in fray(in this case, due to
FPGA constraints, I have limited the number of candidates to 4. However, the number can be increased by implementing the Verilog code on a suitable FPGA.) Once the voting is completed,
the polling agent can close the EVM by entering the secret code and further, display the winner and the votes he has polled. The following Verilog modules have been deployed in order
to operate the EVM efficiently:

7seg.v: Manages the seven-segment display, which is vital displaying candidate numbers, vote counts etc.

binbcd.v: Converts binary numbers to Binary-Coded Decimal (BCD) format, facilitating the display of numerical data on the seven-segment display.

button.v: Handles and debounces button inputs, crucial for voter interactions like casting votes or entering the secret code.

clk1Hz.v and clk2Hz.v: Generate clock signals at 1Hz and 2Hz frequencies, respectively, likely used for timing operations within the EVM.

leds.v: Controls LED indicators, which provide status updates throughout the voting process.

statemachine.v: Implements the state machine governing the EVM's operational flow, ensuring proper sequencing of actions during the voting process.

vm.v: Instantiates the various modules and integrates the various components of the design , thereby ensuring a cohesive realisation of the entire EVM.

Also includes
constraints.xdc: An XDC file, programmed in TCL, specifying pin assignments and electrical constraints, ensuring correct interfacing between the FPGA and external components.

_**Key Components and Their Functions**_

Seven-Segment Display (7seg.v)

The seven-segment display provides visual feedback to users, displaying information such as candidate numbers or votes polled. The 7seg.v module likely decodes BCD inputs to control the individual segments of the display, illuminating the appropriate segments to form numerical digits.

Binary to BCD Conversion (binbcd.v)

Digital systems often process data in binary form, but human-readable displays like seven-segment displays require BCD inputs. The binbcd.v module converts binary numbers to BCD format, enabling accurate representation of numerical data on the display.

Button Input Handling (button.v)

User interaction with the EVM is facilitated through buttons, which may be used to select candidates, confirm selections, or enter the secret code. The button.v module debounces and processes these button inputs, ensuring reliable detection of user actions.

Clock Generation (clk1Hz.v and clk2Hz.v)

Timing is crucial in digital systems for coordinating operations and ensuring synchronous behavior. The clk1Hz.v and clk2Hz.v modules generate clock signals at 1Hz and 2Hz frequencies, respectively, providing timing references for various processes within the EVM.

LED Control (leds.v)

The leds.v module manages the LED indicators on the FPGA, enhancing the user experience by providing clear status updates.

State Machine (statemachine.v)

The operation of the EVM follows a defined sequence of states, from initializing the system to accepting votes and confirming selections. The statemachine.v module implements this state machine, ensuring that the EVM transitions correctly between different operational phases, thereby maintaining the integrity and reliability of the voting process.

Main Voting Machine Module (vm.v)

Serving as the central hub, the vm.v module integrates all other components, coordinating their functions to realize the complete voting machine system. It instantiates the other modules.

Constraints File (constraints.xdc).

Programmed in TCL, it specifies pin assignments and electrical constraints, ensuring correct interfacing between the FPGA and external components.
