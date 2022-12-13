#----------------------------------------
# JasperGold Version Info
# tool      : JasperGold 2018.06
# platform  : Linux 3.10.0-957.21.3.el7.x86_64
# version   : 2018.06p002 64 bits
# build date: 2018.08.27 18:04:53 PDT
#----------------------------------------
# started Mon Dec 12 09:06:10 GMT 2022
# hostname  : ee-mill3.ee.ic.ac.uk
# pid       : 111489
# arguments : '-label' 'session_0' '-console' 'ee-mill3.ee.ic.ac.uk:38090' '-style' 'windows' '-data' 'AQAAADx/////AAAAAAAAA3oBAAAAEABMAE0AUgBFAE0ATwBWAEU=' '-proj' '/home/nnm19/nfshome/HVS/Hardware-Verification-Coursework/GPIO-Verf/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/nnm19/nfshome/HVS/Hardware-Verification-Coursework/GPIO-Verf/jgproject/.tmp/.initCmds.tcl' 'AHBGPIO.tcl'
clear -all
analyze -clear
analyze -sv rtl/AHB_GPIO/AHBGPIO.sv
elaborate -top AHBGPIO

clock HCLK
reset -expression !(HRESETn)

task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4

# cover -name test_cover_from_tcl {@(posedge HCLK) disable iff (HRESETn) done }
prove -bg -task {<embedded>}
visualize -violation -property <embedded>::AHBGPIO.parity_checking_true -new_window
visualize -quiet true -window {visualize:0}
visualize -replot -bg -window {visualize:0} -prompt
visualize -violation -property <embedded>::AHBGPIO.parity_checking_false -new_window
