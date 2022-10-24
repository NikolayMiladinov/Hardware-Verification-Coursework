connect-nick:
	source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh
	cd nfshome/HSV/
	export DISPLAY=localhost:29.0
#connect to MobaXterm local server

#compile the necessary files
comp-opt:
	vlog -work work +acc=blnr -noincr -timescale 1ns/1ps tbench/multiplier_tb.sv rtl/multiplier.sv
	vopt -work work multiplier_tb -o work_opt
#Apply optimisation if no error

#If no error open QuestaSim
open-sim:
	vsim work_opt -gui

#Setup the simulation
setup-sim:
	do setup.do