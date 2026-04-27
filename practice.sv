class my_packet extends uvm_sequence_item 
    rand bit [31:0] addr; 
    rand bit [7:0] payload; 

    `uvm_object_utils(my_packet) 

    function new(string name = "my_packet"); 
        super.new(name); 
    endfunction 

    constraint c_addr_aligned { 
        addr%4 == 0; 
    }

    constraint c_payload_valid { 
        payload >0; 
    }
endclass 

class my_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(my_scoreboard) // Factory registration

  function new(string name = "my_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction 

  uvm_tlm_analysis_fifo #(my_packet) expected_fifo;
  uvm_tlm_analysis_fifo #(my_packet) actual_fifo; 
  // Because FIFOs are UVM components themselves, you must allocate memory for them during the build phase using new.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Create the FIFOs
    expected_fifo = new("expected_fifo", this);
    actual_fifo   = new("actual_fifo", this);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    my_packet exp_pkt, act_pkt;

    forever begin
      // 1. Block and wait for a packet to arrive in BOTH FIFOs
      expected_fifo.get(exp_pkt);
      actual_fifo.get(act_pkt);

      // 2. Compare them using the built-in uvm_object compare() method
      if (exp_pkt.compare(act_pkt)) begin
        `uvm_info("SCOREBOARD", "PASS: Packets matched!", UVM_LOW)
      end else begin
        // 3. If they fail, throw a UVM_ERROR!
        `uvm_error("SCOREBOARD", "FAIL: Mismatch detected!")
      end
    end
  endtask
endclass 


def fibonacci_iterative(n):
    # Handle base cases
    if n < 0:
        raise ValueError("n must be a non-negative integer.")
    elif n == 0:
        return 0
    elif n == 1:
        return 1
    
    # Keep track of the previous two numbers
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
        
    return b