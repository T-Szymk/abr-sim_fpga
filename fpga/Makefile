

export JOBS ?= 8

build:
	@echo "Building Vivado project..."
	@vivado -mode batch -source create_project.tcl -notrace

clean:
	@echo "Cleaning Vivado project..."
	@rm -rf abr_fpga_synth
	@rm -rf .Xil
	@rm -f ./vivado* ./*.log ./*.jou