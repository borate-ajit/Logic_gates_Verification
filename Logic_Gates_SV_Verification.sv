//====================== RTL design =======================
// LOGIC GATES
module logic_gates(logic_gates_if vif);
  // OPERATIONS
  assign vif.AND_out  = vif.A & vif.B;        // AND
  assign vif.OR_out   = vif.A | vif.B;        // OR
  assign vif.NOT_out  = ~(vif.A);              // NOT
  assign vif.NAND_out = ~(vif.A & vif.B);    // NAND
  assign vif.NOR_out  = ~(vif.A | vif.B);    // NOR
  assign vif.XOR_out  = vif.A ^ vif.B;       // XOR
  assign vif.XNOR_out = ~(vif.A ^ vif.B);    // XNOR
endmodule

//========================================================




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
//==========================================================



//=======================================Transaction=====================================
class transaction;
  
  rand bit A;                      // Random bit A for logical operations
  rand bit B;                      // Random bit B for logical operations
  
  bit AND_out;                     // Output of the AND operation
  bit OR_out;                      // Output of the OR operation
  bit NOT_out;                     // Output of the NOT operation
  bit NAND_out;                    // Output of the NAND operation
  bit NOR_out;                     // Output of the NOR operation
  bit XOR_out;                     // Output of the XOR operation
  bit XNOR_out;                    // Output of the XNOR operation
  
  // Constraint to ensure A and B are either 0 or 1
  constraint valid_range {
    A inside {0, 1};
    B inside {0, 1};
  }
  
  // Copy function to duplicate the transaction object
  function transaction copy();
    copy = new();
    copy.A = this.A;
    copy.B = this.B;
    copy.AND_out = this.AND_out;
    copy.OR_out = this.OR_out;
    copy.NOT_out = this.NOT_out;
    copy.NAND_out = this.NAND_out;
    copy.NOR_out = this.NOR_out;
    copy.XOR_out = this.XOR_out;
    copy.XNOR_out = this.XNOR_out;
  endfunction
  
  // Function to display the transaction details
  function void display(input string tag);
    $display("[%0s] : \tA\tB\tAND\tOR\tNOT\tNAND\tNOR\tXOR\tXNOR", tag);
    $display("[%0s] : \t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d", tag, A, B, AND_out, OR_out, NOT_out, NAND_out, NOR_out, XOR_out, XNOR_out);
  endfunction
  
endclass
//==================================================================================




//===========================Generator==============================================
class generator;
  
  transaction tr;                          // Transaction object to store inputs and outputs
  mailbox #(transaction) mbx;              // Mailbox for communication with other classes
  mailbox #(transaction) mbxref;           // Reference mailbox for comparison with reference model
  
  event sconext;                           // Event for synchronization
  event done;                              // Event to signal completion
  int count;                               // Count of iterations
  
  // Constructor to initialize mailboxes and transaction object
  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx;
    this.mbxref = mbxref;
    tr = new();
  endfunction
  
  // Task to generate random transactions and put them into mailboxes
  task run();
    repeat(count) begin
      assert(tr.randomize) else $error("[GEN] : Randomization failed");
      mbx.put(tr.copy);         	 	// Put a copy of the transaction into the mailbox
      mbxref.put(tr.copy);       		// Put a copy into the reference mailbox
      
      tr.display("[GEN]");       		// Display the generated transaction
      @(sconext);                		// Wait for the next synchronization event
    end
    ->done;                       		// Trigger the done event after all iterations
  endtask
endclass
//==================================================================================




//=========================Driver=======================================
class driver;
  
  transaction tr;                          // Transaction object to receive input values
  mailbox #(transaction) mbx;              // Mailbox to receive transactions
  virtual logic_gates_if vif;              // Interface to the DUT (Device Under Test)
  
  // Constructor to initialize the mailbox
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  // Task to receive transactions and send input to the DUT
  task run();
    forever begin
      mbx.get(tr);                         // Get the transaction from the mailbox
      vif.A = tr.A;                        // Assign A to DUT input A
      vif.B = tr.B;                        // Assign B to DUT input B
      tr.display("DRV");                   // Display the transaction in the driver
    end
  endtask
  
endclass
//==================================================================================





//=========================Monitor=================================================
class monitor;
  
  transaction tr;                          // Transaction object to store monitored outputs
  mailbox #(transaction) mbx;              // Mailbox to send transaction to the scoreboard
  virtual logic_gates_if vif;              // Interface to the DUT
  
  // Constructor to initialize the mailbox
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  // Task to monitor DUT outputs and store them in the transaction object
  task run();
    tr = new();                           // Create a new transaction object
    
    forever begin
      tr.A = vif.A;                        // Capture A from DUT
      tr.B = vif.B;                        // Capture B from DUT
      tr.AND_out = vif.AND_out;            // Capture AND output from DUT
      tr.OR_out = vif.OR_out;              // Capture OR output from DUT
      tr.NOT_out = vif.NOT_out;            // Capture NOT output from DUT
      tr.NAND_out = vif.NAND_out;          // Capture NAND output from DUT
      tr.NOR_out = vif.NOR_out;            // Capture NOR output from DUT
      tr.XOR_out = vif.XOR_out;            // Capture XOR output from DUT
      tr.XNOR_out = vif.XNOR_out;          // Capture XNOR output from DUT
      mbx.put(tr);                         // Put the transaction into the mailbox
      tr.display("MON");                   // Display the monitored transaction
      #10;                                 // Wait for 10 time units
    end
  endtask
  
endclass
//==================================================================================





//============================ Reference Model=====================================
class reference_model;
  
  // Function to compute expected outputs based on inputs A and B
  function void compute(transaction trref);
    trref.AND_out  = trref.A & trref.B;        // AND
    trref.OR_out   = trref.A | trref.B;        // OR
    trref.NOT_out  = ~trref.A;                 // NOT
    trref.NAND_out = ~(trref.A & trref.B);     // NAND
    trref.NOR_out  = ~(trref.A | trref.B);     // NOR
    trref.XOR_out  = trref.A ^ trref.B;        // XOR
    trref.XNOR_out = ~(trref.A ^ trref.B);     // XNOR
  endfunction
  
endclass
//==================================================================================





//============================Scoreboard===========================================
class scoreboard;
  transaction tr;                            // Transaction object for monitored data
  transaction trref;                         // Transaction object for reference data
  
  mailbox #(transaction) mbx;                // Mailbox for received transaction
  mailbox #(transaction) mbxref;             // Mailbox for received reference transaction
  
  reference_model ref_model;                 // Reference model object for expected outputs
  
  event sconext;                              // Event for synchronization
  
  // Constructor to initialize mailboxes and reference model
  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx;
    this.mbxref = mbxref;
    ref_model = new();                       // Initialize reference model
  endfunction
  
  // Task to compare monitored data with reference data and report results
  task run();
    forever begin
      mbx.get(tr);                            // Get the monitored transaction
      mbxref.get(trref);                      // Get the reference transaction
      ref_model.compute(trref);               // Compute the expected outputs
      
      tr.display("SCO");                      // Display the monitored transaction
      trref.display("REF");                   // Display the reference transaction
      
      // Compare outputs and display match or mismatch
      if ((tr.AND_out == trref.AND_out) && 
          (tr.OR_out == trref.OR_out) &&
          (tr.NOT_out == trref.NOT_out) &&
          (tr.NAND_out == trref.NAND_out) &&
          (tr.NOR_out == trref.NOR_out) &&
          (tr.XOR_out == trref.XOR_out) &&
          (tr.XNOR_out == trref.XNOR_out)) 
        $display("[SCO] : \tDATA MATCHED");
      else  
        $display("[SCO] : \tDATA MISMATCHED");
        
      $display("------------------------------------------------------------------------------------------");
       
      ->sconext;                             // Trigger the synchronization event
    end
  endtask
endclass
//==================================================================================





//==============================Environment========================================
class environment;
  
  generator gen;                             // Generator object for transaction creation
  driver drv;                                // Driver object for sending input to the DUT
  monitor mon;                               // Monitor object for observing outputs
  scoreboard sco;                            // Scoreboard object for verifying outputs
  
  event next;                                // Synchronization event
  
  mailbox #(transaction) gdmbx;              // Mailbox for generated transactions
  mailbox #(transaction) msmbx;              // Mailbox for monitored transactions
  mailbox #(transaction) mbxref;             // Mailbox for reference transactions
  
  virtual logic_gates_if vif;                 // Interface to the DUT
  
  // Constructor to initialize all components of the environment
  function new(virtual logic_gates_if vif);
    gdmbx = new();
    mbxref = new();
    gen = new(gdmbx, mbxref);
    drv = new(gdmbx);    
    msmbx = new();
    mon = new(msmbx);
    sco = new(msmbx, mbxref);
    
    this.vif = vif;                         // Assign DUT interface
    
    drv.vif = this.vif;                     // Assign DUT interface to driver
    mon.vif = this.vif;                     // Assign DUT interface to monitor
    
    gen.sconext = next;                     // Synchronize generator with environment
    sco.sconext = next;                     // Synchronize scoreboard with environment
  endfunction
  
  // Task to run all components concurrently
  task run();
    fork 
      gen.run();                             // Run the generator
      drv.run();                             // Run the driver
      mon.run();                             // Run the monitor
      sco.run();                             // Run the scoreboard
    join_any
    
    wait(gen.done.triggered);                // Wait for generator to finish
    $finish;                                 // End the simulation
  endtask
  
endclass
//==================================================================================




//================================Top===============================================
module tb;
  
  logic_gates_if vif();                    // DUT interface
  
  logic_gates DUT(vif);                     // Instantiate DUT
  
  environment env;                          // Instantiate environment
  
  initial begin
    env = new(vif);                         // Initialize the environment
    env.gen.count = 30;                     // Set the count for generator iterations
    env.run();                              // Run the environment
  end
  
endmodule
//==================================================================================

