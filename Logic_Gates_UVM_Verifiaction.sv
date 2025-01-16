//====================== RTL design =======================
// LOGIC GATES
module logic_gates(
  input logic A,
  input logic B,
  
  output logic AND_out,
  output logic OR_out,
  output logic NOT_out,
  output logic NAND_out,
  output logic NOR_out,
  output logic XOR_out,
  output logic XNOR_out
);
  
  // OPERATIONS
  assign AND_out = A & B;			// AND
  assign OR_out = A | B;			// OR
  assign NOT_out = ~A;				// NOT
  assign NAND_out = ~(A & B);			// NAND
  assign NOR_out = ~(A | B);			// NOT
  assign XOR_out = A ^ B;			// XOR
  assign XNOR_out = ~(A ^ B);			// XNOR
endmodule
//=========================================================



//======================= Interface =======================

// Creating the interface file to connect the design file to tb
interface logic_gates_if();
  logic A;
  logic B;
  logic AND_out;
  logic OR_out;
  logic NOT_out;
  logic NAND_out;
  logic NOR_out;
  logic XOR_out;
  logic XNOR_out;
endinterface
//=========================================================




//==================== Transaction Class ===========================
class lg_transaction extends uvm_sequence_item;
  
  // Declaring the variables for the transaction
  rand bit A;           // Randomized input A
  rand bit B;           // Randomized input B
  bit AND_out;          // Output of the AND operation
  bit OR_out;           // Output of the OR operation
  bit NOT_out;          // Output of the NOT operation
  bit NAND_out;         // Output of the NAND operation
  bit NOR_out;          // Output of the NOR operation
  bit XOR_out;          // Output of the XOR operation
  bit XNOR_out;         // Output of the XNOR operation
  
  // Factory registration and field declaration macros
  `uvm_object_utils_begin(lg_transaction)  
    `uvm_field_int(A, UVM_ALL_ON)   // Register field A for randomization and reporting
    `uvm_field_int(B, UVM_ALL_ON)   // Register field B for randomization and reporting
  `uvm_object_utils_end
  
  // Constructor for the transaction class
  function new(string name = "lg_transaction");
    super.new(name);                // Call parent constructor
  endfunction

endclass
//===================================================================




//==================== Semaphore Shared Class ========================
class semaphore_shared;
  semaphore sem;  // Shared semaphore for synchronization

  // Constructor for the semaphore shared class
  function new();
    sem = new(1);                   // Initialize semaphore with 1 resource
  endfunction
endclass
//===================================================================




//==================== Sequence ============================
class lg_sequence extends uvm_sequence#(lg_transaction);

  `uvm_object_utils(lg_sequence)  // Factory Registration
  
  lg_transaction tr;  // Transaction object
  
  // Constructor
  function new(string name = "lg_sequence");
    super.new(name);
  endfunction
  
  // Task to generate the sequence and pass it to the driver
  task body();
    repeat(20) begin
      // Generate random data and send it to the driver
      tr = lg_transaction::type_id::create("tr");  // Create transaction object
      start_item(tr);  // Notify the driver to prepare for new transaction
      assert(tr.randomize());  // Randomize the transaction data
      `uvm_info("SEQ", 
                $sformatf("\tGenerated seq: \tA = %0d, \tB = %0d", tr.A, tr.B), 
                UVM_MEDIUM)
      finish_item(tr);  // Complete the transaction
    end
  endtask

endclass
//=========================================================




//==================== Sequencer ===========================
class lg_sequencer extends uvm_sequencer#(lg_transaction);

  `uvm_component_utils(lg_sequencer)  // Factory Registration

  // Constructor
  function new(string name = "lg_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
//=========================================================




//==================== Driver ==============================
class lg_driver extends uvm_driver#(lg_transaction);

  `uvm_component_utils(lg_driver)  // Factory Registration

  lg_transaction tr;             // Transaction object
  virtual logic_gates_if vif;    // Virtual interface for DUT connections
  semaphore sem;                 // Semaphore for synchronization

  // Constructor
  function new(string name = "lg_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Set the semaphore for synchronization
  function void set_semaphore(semaphore s);
    sem = s;
  endfunction

  // Build phase: Retrieve the virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual logic_gates_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV", "Failed to get interface");
    end
  endfunction

  // Run phase: Continuously drive the DUT with transaction data
  task run_phase(uvm_phase phase);
    forever begin
      sem.get(1);  // Acquire semaphore for mutual exclusion
      seq_item_port.get_next_item(tr);  // Get the next transaction from sequencer

      // Drive inputs to the DUT using the virtual interface
      vif.A = tr.A;
      vif.B = tr.B;

      `uvm_info("DRV", 
                $sformatf("\t\tDriving seq: \tA = %0b, \tB = %0b", tr.A, tr.B), 
                UVM_MEDIUM);

      seq_item_port.item_done();  // Notify sequencer that transaction is complete
      sem.put(1);  // Release semaphore
    end
  endtask

endclass
//=========================================================




//==================== Monitor =============================
class lg_monitor extends uvm_monitor;

  `uvm_component_utils(lg_monitor)  // Factory registration

  uvm_analysis_port#(lg_transaction) ap;  // Analysis port to send transactions
  lg_transaction tr;                      // Transaction object
  virtual logic_gates_if vif;             // Virtual interface for monitoring DUT
  semaphore sem;                          // Semaphore for synchronization

  // Constructor
  function new(string name = "lg_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Set the semaphore for synchronization
  function void set_semaphore(semaphore s);
    sem = s;
  endfunction

  // Build phase: Initialize analysis port and transaction object
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual logic_gates_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Failed to get interface");

    ap = new("ap", this);  // Create the analysis port
    tr = lg_transaction::type_id::create("tr");  // Create transaction object
  endfunction

  // Run phase: Monitor DUT signals and send to analysis port
  task run_phase(uvm_phase phase);
    forever begin
      sem.get(1);  // Acquire semaphore
      // Capture DUT signals into the transaction object
      tr.A = vif.A;
      tr.B = vif.B;
      tr.AND_out = vif.AND_out;
      tr.OR_out = vif.OR_out;
      tr.NOT_out = vif.NOT_out;
      tr.NAND_out = vif.NAND_out;
      tr.NOR_out = vif.NOR_out;
      tr.XOR_out = vif.XOR_out;
      tr.XNOR_out = vif.XNOR_out;

      // Log monitored values
      `uvm_info("MON", "\t\tA\tB\tAND\tOR\tNOT\tNAND\tNOR\tXOR\tXNOR", UVM_MEDIUM)
      `uvm_info("MON", 
                $sformatf("\t\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d",
                          tr.A, tr.B, tr.AND_out, tr.OR_out, tr.NOT_out,
                          tr.NAND_out, tr.NOR_out, tr.XOR_out, tr.XNOR_out), 
                UVM_MEDIUM);

      ap.write(tr);  // Send transaction to analysis port
      sem.put(1);    // Release semaphore
    end
  endtask

endclass
//=========================================================




//==================== Scoreboard ==========================
class lg_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(lg_scoreboard)  // Factory registration

  uvm_analysis_imp#(lg_transaction, lg_scoreboard) imp;  // Analysis implementation port

  // Constructor
  function new(string name = "lg_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase: Initialize analysis implementation port
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);  // Create the analysis implementation port
  endfunction

  // Write phase: Compare DUT outputs with reference model
  function void write(lg_transaction tr);
    // Reference model calculations
    bit AND_out_sb = tr.A & tr.B;
    bit OR_out_sb = tr.A | tr.B;
    bit NOT_out_sb = ~tr.A;
    bit NAND_out_sb = ~(tr.A & tr.B);
    bit NOR_out_sb = ~(tr.A | tr.B);
    bit XOR_out_sb = tr.A ^ tr.B;
    bit XNOR_out_sb = ~(tr.A ^ tr.B);

    // Compare DUT outputs with reference model
    if (tr.AND_out !== AND_out_sb || tr.OR_out !== OR_out_sb || tr.NOT_out !== NOT_out_sb ||
        tr.NAND_out !== NAND_out_sb || tr.NOR_out !== NOR_out_sb || tr.XOR_out !== XOR_out_sb || 
        tr.XNOR_out !== XNOR_out_sb) begin
      
      `uvm_info("SCO", "DUT data", UVM_MEDIUM)
      `uvm_info("SCO", "\tA\tB\tAND\tOR\tNOT\tNAND\tNOR\tXOR\tXNOR", UVM_MEDIUM)
      `uvm_info("SCO", 
                $sformatf("\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d", 
                          tr.A, tr.B, tr.AND_out, tr.OR_out, tr.NOT_out, 
                          tr.NAND_out, tr.NOR_out, tr.XOR_out, tr.XNOR_out), 
                UVM_MEDIUM)
      
      `uvm_info("SCO", "Reference data", UVM_MEDIUM)
      `uvm_info("SCO", "\tA\tB\tAND_sb\tOR_sb\tNOT_sb\tNAND_sb\tNOR_sb\tXOR_sb\tXNOR_sb", UVM_MEDIUM)
      `uvm_info("SCO", 
                $sformatf("\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d", 
                          tr.A, tr.B, AND_out_sb, OR_out_sb, NOT_out_sb, 
                          NAND_out_sb, NOR_out_sb, XOR_out_sb, XNOR_out_sb), 
                UVM_MEDIUM)
    end else 
      `uvm_info("SCO", "-------------------------Output Match!----------------------------", UVM_MEDIUM)
  endfunction

endclass
//=========================================================

      
      
      
//==================== Coverage ============================
class lg_coverage extends uvm_subscriber#(lg_transaction);

  `uvm_component_utils(lg_coverage)  // Factory registration

  lg_transaction tr;  // Transaction object for coverage

  covergroup cg;
    coverpoint tr.A;         // Coverpoint for input A
    coverpoint tr.B;         // Coverpoint for input B
    cross tr.A, tr.B;        // Cross coverage for A and B
  endgroup

  // Constructor
  function new(string name = "lg_coverage", uvm_component parent);
    super.new(name, parent);
    cg = new();  // Initialize covergroup
  endfunction

  // Write phase: Capture transaction and sample coverage
  function void write(lg_transaction tr);
    this.tr = tr;  // Capture transaction data
    cg.sample();   // Sample coverage
    `uvm_info("COV", 
              $sformatf("\t\tCoverage seq: \tA = %0b, \tB = %0b", tr.A, tr.B), 
              UVM_MEDIUM)
  endfunction

endclass
//=========================================================

    
    
    
//==================== Agent ===============================
class lg_agent extends uvm_agent;

  `uvm_component_utils(lg_agent)  // Factory registration

  lg_sequencer seqr;          // Sequencer handle
  lg_driver drv;              // Driver handle
  lg_monitor mon;             // Monitor handle
  semaphore_shared shared;    // Shared semaphore

  // Constructor
  function new(string name = "lg_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase to create and configure sub-components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    shared = new(); // Initialize shared semaphore

    seqr = lg_sequencer::type_id::create("seqr", this); // Create sequencer
    drv = lg_driver::type_id::create("drv", this);     // Create driver
    mon = lg_monitor::type_id::create("mon", this);    // Create monitor

    drv.set_semaphore(shared.sem); // Pass shared semaphore to driver
    mon.set_semaphore(shared.sem); // Pass shared semaphore to monitor
  endfunction

  // Connect phase to link components
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export); // Connect driver and sequencer
  endfunction
endclass
//==========================================================


    
    
//==================== Environment =========================
class lg_environment extends uvm_env;

  `uvm_component_utils(lg_environment)  // Factory registration

  lg_agent agt;            // Agent handle
  lg_scoreboard sb;        // Scoreboard handle
  lg_coverage cov;         // Coverage handle

  // Constructor
  function new(string name = "lg_environment", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase to create sub-components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = lg_agent::type_id::create("agt", this); // Create agent
    sb = lg_scoreboard::type_id::create("sb", this); // Create scoreboard
    cov = lg_coverage::type_id::create("cov", this); // Create coverage
  endfunction

  // Connect phase to link components
  function void connect_phase(uvm_phase phase);
    agt.mon.ap.connect(sb.imp);                 // Connect monitor to scoreboard
    agt.mon.ap.connect(cov.analysis_export);   // Connect monitor to coverage
  endfunction
endclass
//==========================================================

    
    
    
//==================== Test ================================
class lg_test extends uvm_test;

  `uvm_component_utils(lg_test)  // Factory registration

  lg_environment env; // Environment handle
  lg_sequence seq;    // Sequence handle

  // Constructor
  function new(string name = "lg_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase to create and configure components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = lg_environment::type_id::create("env", this); // Create environment
    seq = lg_sequence::type_id::create("seq");         // Create sequence
  endfunction

  // End of elaboration phase to display topology
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology;
  endfunction

  // Run phase to execute the sequence
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "Sequence Start", UVM_MEDIUM);
    seq.start(env.agt.seqr); // Start the sequence
    #40;
    `uvm_info("TEST", "Sequence Complete", UVM_MEDIUM);
    phase.drop_objection(this);
  endtask

  // Report phase to display functional coverage
  function void report_phase(uvm_phase phase);
    $display("Functional Coverage: %0.2f%%", env.cov.cg.get_coverage());
  endfunction
endclass
//==========================================================
    
    

    
//==================== Top =================================
module tb;

  import uvm_pkg::*;                // UVM package
  `include "uvm_macros.svh"         // UVM macros

  semaphore key;                    // Semaphore instance
  logic_gates_if intf();            // Interface instance

  // Instantiate DUT and connect to interface
  logic_gates DUT(
    .A(intf.A),
    .B(intf.B),
    .AND_out(intf.AND_out),
    .OR_out(intf.OR_out),
    .NOT_out(intf.NOT_out),
    .NAND_out(intf.NAND_out),
    .NOR_out(intf.NOR_out),
    .XOR_out(intf.XOR_out),
    .XNOR_out(intf.XNOR_out)
  );

  // Initialize and set virtual interface
  initial begin
    key = new(1);
    `uvm_info("TOP", "Passing the virtual interface", UVM_MEDIUM);
    uvm_config_db#(virtual logic_gates_if)::set(null, "*", "vif", intf);
  end

  // Start the test
  initial begin

    `uvm_info("TOP", "Start the test", UVM_MEDIUM);
    run_test("lg_test");

  end

endmodule
//================================================================

 



