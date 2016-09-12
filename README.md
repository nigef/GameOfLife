
# 👾 Conway's Game of Life

A visual simulation of Conway's Game of Life, with different options in speed and color, and randomly seeded live cells. The game progresses through "ticks" of the clock, where Conway's 4 rules will determine the alive/dead states of each cell. 


## Features
- 4 Rules of Conway to render the cell states, with the 3 cases: 8 neighbors (middle), 3 neighbors (corner), 5 neighbors (edge).
- Switches choose different speeds “ticks” of game (slow, medium, fast), from different clock speeds, selected by a switch and displayed on a 7-segment LED.
- Shows the generation number of the game on a 7-segment LED.
- “Clear board” using asynchronous reset with a KEY.
- Select different colors for live/dead cells with combinations from 3 switches for RGB.
- Shows the decimal number of living cells on LED `HEX4 ... HEX0` at each ‘tick’.
- 320 x 240px = 160 x 120 cell game board on VGA, with 2x2 pixels blocks = 19,200 registers
- (Optional: user-defined starting cells… determine a way to ‘pick’ live cells before start with external hardware or something on the board…)
- (Optional: extra seeder bot that traverses the cells randomly and plants live cells around the board to keep the game going…)



## Project Motivations

#### How does this project relate to academic material?

Cell state is stored as 1 = living, 0 = dead in registers (D Flipflops). The visualization of the simulation is accomplished through VGA. The speed of the game is determined by the machine CLOCK, and the speed of the game is adjusted through a counter. The simulation can be adjusted with Switches on the board.



#### What's cool about this project?

Conway's Game of Life is a simulation of cellular Automaton based on cellular interactions between neighboring cells. It is interesting to scale the game at a large size using efficient hardware designs to visualize a chaotic ecosystem behaving under a precise set of rules, through a combination of FPGA and VGA technologies.



# To run on a Mac

## Tools used:
- Windows 7 (32 bit) on VirtualBox
- Altera DE2 board, Family: Cyclone II, Name: `EP2C35F672CGN` (33216 LEs, 475 User I/Os, 483840 Memory Bits, ..)
- Quartus II 13.0 (32 bit version)
- ModelSim 10.1d, Altera starter edition.



## Instructions
- Run the virtual machine, and launch the `QSF` file in Quartus.
- Click "Start Compilation", which looks like the little play arrow. Wait a few minutes while it compiles.
- Start with step 3 below..


## How to Load Quartus II Project

1. Open Quartus II and go to File > New... and select New Quartus II Project.

2. Click Next and under Directory, Name, Top-Level Entity select your working directory and type the name of your project. The top-level design will automatically fill out to be the same name as your project.

3. Click Next until you reach Family & Device Settings and select the chip EP2C35F672CGN under Available Devices and then click Finish.

8. Obtain a copy of the `DE2.qsf` file and place it in your design directory. This file associates signal names to pins on the chip. If you use these exact signal names for the inputs and outputs in your design, the tool will connect those signals to the appropriate pins. You can examine the file in an editor to see the names and pin numbers.

9. Click on Assignments > Import Assignments... and import the `DE2.qsf` file.

10. If you open Assignments > Pin Planner, you can see all the assignments of signal names to pin numbers
    (e.g., SW[0] to pin number PIN_N25).

12. Once you have completed your design, click Processing > Start Compilation.

13. When compilation is done, click Tools > Programmer and a window will appear.

14. Go to Hardware Setup and ensure Currently Selected Hardware is DE2 and close the window.

15. Click Auto Detect and select EP2C35F672.. and click OK.

16. Double click <none> for device EP2C35F672.. and load SOF file (usually under folder ”output files”) and device will change to EP2C35F672...

17. Ensure Program/Configure for device EP2C35F672.. is checked and click Start.

18. [optional] to test on ModelSim, launch it, and `cd` into the directory in the terminal there, and run the `WAVE.do` file..




## TODO:
- use something like "Inferred RAM" instead of the 50x50 bit board `initial_board_flat`, which takes an insane amount of time to compile.
- Fix bug in the code.

Note: github replaced many of the CLRF chars in `lab7part3/*` with LF.. incase something doesn't work this could be it..
