#This file will do...

#source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh
#cd filepath

#compile the necessary files
#vlog -work work +acc=blnr -noincr -timescale 1ns/1ps tbench/multiplier_tb.sv rtl/multiplier.sv

#Apply optimisation if no error
#vopt -work work multiplier_tb -o work_opt

#If no error open QuestaSim
#vsim work_opt -gui

#Setup the simulation