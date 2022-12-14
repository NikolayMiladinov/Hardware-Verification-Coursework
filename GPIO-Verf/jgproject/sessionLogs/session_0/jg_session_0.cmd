#----------------------------------------
# JasperGold Version Info
# tool      : JasperGold 2018.06
# platform  : Linux 3.10.0-957.21.3.el7.x86_64
# version   : 2018.06p002 64 bits
# build date: 2018.08.27 18:04:53 PDT
#----------------------------------------
# started Wed Dec 14 08:35:14 GMT 2022
# hostname  : ee-mill3.ee.ic.ac.uk
# pid       : 155829
# arguments : '-label' 'session_0' '-console' 'ee-mill3.ee.ic.ac.uk:41232' '-style' 'windows' '-data' 'AQAAADx/////AAAAAAAAA3oBAAAAEABMAE0AUgBFAE0ATwBWAEU=' '-proj' '/home/nnm19/nfshome/HVS/Hardware-Verification-Coursework/GPIO-Verf/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/nnm19/nfshome/HVS/Hardware-Verification-Coursework/GPIO-Verf/jgproject/.tmp/.initCmds.tcl' 'AHBGPIO.tcl'
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
