# Create and map work library
vlib work
vmap work work

# Compile design files
vlog -sv ../rtl/des_pkg.sv
vlog -sv ../rtl/key_schedule.sv
vlog -sv ../rtl/f_round.sv
vlog -sv ../rtl/controller.sv
vlog -sv ../rtl/data_path.sv
vlog -sv ../rtl/des_top.sv

# Compile testbench
vlog -sv ../rtl/tb_des_top.sv

# Start simulation
vsim -voptargs=+acc work.tb_des_top

# Waveform setup
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/clk
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/arstn
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/start
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/mode
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/busy
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/done
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/key
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/data_in
add wave -noupdate -group "Top Interface" -radix hexadecimal /tb_des_top/data_out

add wave -noupdate -group "Controller" /tb_des_top/DUT/Controller/current_state
add wave -noupdate -group "Controller" -radix unsigned /tb_des_top/DUT/Controller/round_index
add wave -noupdate -group "Controller" /tb_des_top/DUT/Controller/load
add wave -noupdate -group "Controller" /tb_des_top/DUT/Controller/round_en
add wave -noupdate -group "Controller" /tb_des_top/DUT/Controller/finalize

add wave -noupdate -group "Datapath" -radix hexadecimal /tb_des_top/DUT/Data_Path/sub_key
add wave -noupdate -group "Datapath" -radix hexadecimal /tb_des_top/DUT/Data_Path/round_in
add wave -noupdate -group "Datapath" -radix hexadecimal /tb_des_top/DUT/Data_Path/round_out

# Run
run -all
