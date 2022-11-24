connect-nick:
	source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh
#cd nfshome/HSV/
#Connect to Moba host
	export DISPLAY=19:0

#compile the necessary files
comp-opt:
	vlog -work work +acc=blnr -noincr -timescale 1ns/1ps tbench/tb_top.sv rtl/AHB_GPIO/AHBGPIO.v
	vopt -work work tb_top -o work_opt
#Apply optimisation if no error

#If no error open QuestaSim
open-sim:
	vsim work_opt -gui

#Setup the simulation
setup-sim:
	do setup.do