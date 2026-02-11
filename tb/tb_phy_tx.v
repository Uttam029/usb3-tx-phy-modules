`timescale 1ns / 1ps

module tb_phy_tx;

    // Clock and Reset
    reg clk;
    reg rst_n;
    
    // Inputs to DUT
    reg [7:0]  data_in;
    reg        data_valid;
    reg        is_control;
    reg        com;
    
    // Outputs from DUT
    wire [7:0]  scrambled_byte;
    wire        scrambled_valid;
    wire [9:0]  encoded_symbol;
    wire        encoded_valid;
    wire        rd_out;
    
    // ========================================================================
    // Clock Generation - 100MHz (10ns period)
    // ========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle every 5ns = 10ns period
    end
    
    // ========================================================================
    // Instantiate DUT (Design Under Test)
    // ========================================================================
    phy_tx_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .is_control(is_control),
        .com(com),
        .scrambled_byte(scrambled_byte),
        .scrambled_valid(scrambled_valid),
        .encoded_symbol(encoded_symbol),
        .encoded_valid(encoded_valid),
        .rd_out(rd_out)
    );
    
    // ========================================================================
    // Test Stimulus
    // ========================================================================
    initial begin
        // Display header
        $display("========================================");
        $display("USB 3.0 PHY TX Testbench");
        $display("Testing Scrambler + 8b/10b Encoder");
        $display("========================================");
        $display("Time(ns) | Data_In | Valid | Ctrl | COM | Scrambled | Encoded      | RD");
        $display("---------|---------|-------|------|-----|-----------|--------------|---");
        
        // Initialize all inputs
        rst_n = 0;
        data_in = 8'h00;
        data_valid = 0;
        is_control = 0;
        com = 0;
        
        // Apply reset for 20ns
        #20;
        rst_n = 1;
        $display("Reset released at t=%0t", $time);
        
        // Wait a few clocks
        #30;
        
        // ====================================================================
        // TEST 1: Scrambler Test - Input 0x00 repeatedly
        // Expected scrambled outputs: FF, 17, C0, 14, B2, E7 (from paper)
        // ====================================================================
        $display("\n=== TEST 1: Scrambler with 0x00 input ===");
        com = 1;  // Activate LFSR
        data_valid = 1;
        is_control = 0;  // D-code (will be scrambled)
        
        repeat(10) begin
            data_in = 8'h00;
            #10;  // Wait one clock cycle
        end
        
        // ====================================================================
        // TEST 2: Test with 0x3F input (from paper Fig. 7)
        // ====================================================================
        $display("\n=== TEST 2: Input 0x3F ===");
        data_in = 8'h3F;
        #10;
        
        // ====================================================================
        // TEST 3: K-Code Test (K28.5 = 0xBC)
        // K-codes should NOT be scrambled
        // ====================================================================
        $display("\n=== TEST 3: K28.5 Control Character ===");
        is_control = 1;  // K-code
        data_in = 8'hBC;  // K28.5
        #10;
        
        is_control = 0;  // Back to D-codes
        
        // ====================================================================
        // TEST 4: Various data patterns
        // ====================================================================
        $display("\n=== TEST 4: Various patterns ===");
        
        data_in = 8'hAA;  // Alternating pattern
        #10;
        
        data_in = 8'h55;  // Inverted alternating
        #10;
        
        data_in = 8'hFF;  // All ones
        #10;
        
        data_in = 8'h00;  // All zeros
        #10;
        
        data_in = 8'h5A;  // Random pattern
        #10;
        
        // ====================================================================
        // TEST 5: Test without COM signal (LFSR should not update)
        // ====================================================================
        $display("\n=== TEST 5: COM=0 (LFSR frozen) ===");
        com = 0;
        data_in = 8'h12;
        #10;
        data_in = 8'h34;
        #10;
        
        // ====================================================================
        // TEST 6: Test with data_valid = 0 (no processing)
        // ====================================================================
        $display("\n=== TEST 6: data_valid=0 (idle) ===");
        data_valid = 0;
        data_in = 8'hAB;
        #20;
        
        // Re-enable
        data_valid = 1;
        com = 1;
        data_in = 8'hCD;
        #10;
        
        // ====================================================================
        // Run for additional time
        // ====================================================================
        #100;
        
        $display("\n========================================");
        $display("Simulation Complete!");
        $display("========================================");
        $display("\nVerify in waveform:");
        $display("1. Scrambled outputs: FF, 17, C0, 14, B2, E7 for 0x00 inputs");
        $display("2. K28.5 (0xBC) should pass through scrambler unchanged");
        $display("3. Encoded output should be 10 bits");
        $display("4. Running disparity (rd_out) should toggle");
        
        $finish;
    end
    
    // ========================================================================
    // Monitor outputs on every clock edge
    // ========================================================================
    always @(posedge clk) begin
        if (rst_n && data_valid) begin
            $display("%7t | %h      | %b     | %b    | %b   | %h        | %b | %b",
                     $time, data_in, data_valid, is_control, com,
                     scrambled_byte, encoded_symbol, rd_out);
        end
    end
    
    // ========================================================================
    // Generate VCD file for waveform viewing
    // ========================================================================
    initial begin
        $dumpfile("phy_tx_simulation.vcd");
        $dumpvars(0, tb_phy_tx);
        
        // Explicitly dump all signals
        $dumpvars(1, clk);
        $dumpvars(1, rst_n);
        $dumpvars(1, data_in);
        $dumpvars(1, data_valid);
        $dumpvars(1, is_control);
        $dumpvars(1, com);
        $dumpvars(1, scrambled_byte);
        $dumpvars(1, scrambled_valid);
        $dumpvars(1, encoded_symbol);
        $dumpvars(1, encoded_valid);
        $dumpvars(1, rd_out);
        
        // Dump internal LFSR state for debugging
        $dumpvars(1, uut.u_scrambler.lfsr);
        $dumpvars(1, uut.u_encoder.current_rd);
    end
    
    // Optional: Timeout safety
    initial begin
        #10000;  // 10 microseconds timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
