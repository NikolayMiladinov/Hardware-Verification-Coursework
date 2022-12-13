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