-clean
-uvm
-access +rwc 

// DUT files 
sources/tpu_top.sv
sources/weight_sram.sv
sources/weight_fifo.sv
sources/weight_controller.sv
sources/act_sram.sv
sources/input_fifo.sv
sources/act_skew_buffer.sv
sources/systolic_array.sv
sources/pe.sv 

UVM/env/interfaces/tpu_if.sv 

UVM/env/seq_items/weight_item.sv
UVM/env/seq_items/act_item.sv
UVM/env/seq_items/out_item.sv 

UVM/env/sequences/weight_sequence.sv
UVM/env/sequences/act_sequence.sv

UVM/env/agents/weight_agent/weight_sequencer.sv
UVM/env/agents/weight_agent/weight_driver.sv
UVM/env/agents/weight_agent/weight_monitor.sv
UVM/env/agents/weight_agent/weight_agent.sv 

UVM/env/agents/act_agent/act_sequencer.sv
UVM/env/agents/act_agent/act_driver.sv
UVM/env/agents/act_agent/act_monitor.sv
UVM/env/agents/act_agent/act_agent.sv 

UVM/env/agents/out_agent/out_monitor.sv
UVM/env/agents/out_agent/out_agent.sv

UVM/env/tpu_scoreboard.sv
UVM/env/tpu_env.sv
UVM/tests/tpu_test.sv 
UVM/tests/tpu_reset_test.sv 

tb_top.sv 

