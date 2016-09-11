# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in file_name.v to working dir;
# could also have multiple verilog files.
vlog *.v

# Load simulation and define the module name as the top level simulation module.
vsim -L altera_mf_ver lab7part3

# Log all signals and add some signals to waveform window.
log {/*}

# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# add everything in data path
# add wave {/D0/*}

# add internal waves
add wave {/C0/current_state}
add wave {/C0/next_state}

add wave {/D0/xCount}
add wave {/D0/yCount}
add wave {/D0/m}
add wave {/D0/n}
add wave {/D0/mcount}
add wave {/D0/ncount}
add wave {/D0/checkEnvironment}
add wave {/D0/environmentCycle}
add wave {/D0/environment}
add wave {/D0/i}
add wave {/D0/checkOnNextTick}


# customize radix
radix signal /cellIndex unsigned
radix signal /y unsigned
radix signal /x unsigned
radix signal /D0/yCount unsigned
radix signal /D0/xCount unsigned
radix signal /cellCountOutput unsigned
radix signal /D0/liveCellCount unsigned
radix signal /D0/m decimal
radix signal /D0/n decimal
radix signal /D0/mcount unsigned
radix signal /D0/ncount unsigned
radix signal /D0/environment unsigned
radix signal /C0/current_state unsigned
radix signal /C0/next_state unsigned
radix signal /lab7part3/reverse_index unsigned
radix signal /lab7part3/reverse_neighbour decimal
radix signal /lab7part3/genCount unsigned
radix signal /D0/i unsigned


# delete signals
delete wave /lab7part3/VGA_CLK
delete wave /lab7part3/VGA_HS
delete wave /lab7part3/VGA_VS
delete wave /lab7part3/VGA_BLANK
delete wave /lab7part3/VGA_SYNC
delete wave /lab7part3/VGA_R
delete wave /lab7part3/VGA_G
delete wave /lab7part3/VGA_B
#delete wave /lab7part3/LEDG
#delete wave /lab7part3/LEDR
delete wave /lab7part3/hertzCount
delete wave /lab7part3/HEX0
delete wave /lab7part3/HEX1
delete wave /lab7part3/HEX2
delete wave /lab7part3/HEX3
delete wave /lab7part3/HEX4
delete wave /lab7part3/HEX5
delete wave /lab7part3/HEX6
delete wave /lab7part3/HEX7
delete wave /lab7part3/x_offset
delete wave /lab7part3/y_offset
delete wave /lab7part3/tickSelectSwitch

delete wave /lab7part3/initial_board_flat1
delete wave /lab7part3/initial_board_flat2
delete wave /lab7part3/initial_board_flat3
delete wave /lab7part3/initial_board_flat4
delete wave /lab7part3/zero_board
delete wave /lab7part3/D0/initial_board_flat1
delete wave /lab7part3/D0/initial_board_flat2
delete wave /lab7part3/D0/initial_board_flat3
delete wave /lab7part3/D0/initial_board_flat4
delete wave /lab7part3/D0/zero_board



###############################################
# Keys:
# color = SW[2:0]
# board select = SW[4:3]
# tick speed = SW[6:5]
# KEY[0] = resetn
###############################################

# simulate the clock with a 2 ns period...
force {CLOCK_50} 0 0, 1 {1 ns} -repeat 2 ns
force {emit_tick} 0 0, 1 {10 ns} -repeat 20 ns

force {SW[2:0]} 3'b010
force {SW[4:3]} 2'b11
force {SW[6:5]} 2'b11

force {KEY[0]} 0
run 5ns
force {KEY[0]} 1

run 150ns


