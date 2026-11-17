# ==============================================================================
# Master QuestaSim / ModelSim script to compile and run all testbenches
# Usage in Questa transcript: do run_all.do
# ==============================================================================

vlib work
vmap work work

# Compile all RTL files
vlog -sv ../rtl/des_pkg.sv
vlog -sv ../rtl/key_schedule.sv
vlog -sv ../rtl/f_round.sv
vlog -sv ../rtl/controller.sv
vlog -sv ../rtl/data_path.sv
vlog -sv ../rtl/des_top.sv

# Compile all Testbenches
vlog -sv ../tb/tb_f_round.sv
vlog -sv ../tb/tb_des_key_schedule.sv
vlog -sv ../tb/tb_controller.sv
vlog -sv ../tb/tb_data_path.sv
vlog -sv ../tb/tb_des_top.sv

puts "\n========================================================"
puts "  RUNNING 1/5: tb_f_round"
puts "========================================================"
vsim -c -voptargs=+acc work.tb_f_round
run -all

puts "\n========================================================"
puts "  RUNNING 2/5: tb_des_key_schedule"
puts "========================================================"
vsim -c -voptargs=+acc work.tb_des_key_schedule
run -all

puts "\n========================================================"
puts "  RUNNING 3/5: tb_controller"
puts "========================================================"
vsim -c -voptargs=+acc work.tb_controller
run -all

puts "\n========================================================"
puts "  RUNNING 4/5: tb_data_path"
puts "========================================================"
vsim -c -voptargs=+acc work.tb_data_path
run -all

puts "\n========================================================"
puts "  RUNNING 5/5: tb_des_top (Top Module with File I/O)"
puts "========================================================"
vsim -c -voptargs=+acc work.tb_des_top
run -all

puts "\n========================================================"
puts "  ALL SIMULATIONS COMPLETED SUCCESSFULLY!"
puts "========================================================\n"
