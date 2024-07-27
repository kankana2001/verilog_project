`timescale 1ns/1ps

module top_tb;
    reg clk;
    reg rst;
    reg signed [31:0] angle;
    wire signed [31:0] sine;
    wire signed [31:0] cosine;

    // Instantiate the DUT (Device Under Test)
    top dut (
        .clk(clk),
        .rst(rst),
        .angle(angle),
        .sine(sine),
        .cosine(cosine)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period, 100MHz clock
    end

    // Task to read input angles from file
    integer input_file;
    integer scan_status;

    // Variables to store floating-point results
    real sine_flt;
    real cosine_flt;
    
    // Function to convert Q16.16 fixed-point to floating-point
    function real fixed_to_float;
        input signed [31:0] fixed;
        fixed_to_float = fixed / 65536.0;
    endfunction
    
    initial begin
        // Open the input file
        input_file = $fopen("D:/vts_vivado/project_7_fileinput/project_7_fileinput.srcs/sim_1/imports/MATLAB/input_values_fixed_point.txt", "r");
        if (input_file == 0) begin
            $display("Error: Failed to open input file.");
            $finish;
        end
        
        // Reset and initialize
        rst = 1;
        angle = 0;
        #20 rst = 0;
        
        // Read and process each angle
        while (!$feof(input_file)) begin
            // Read angle from file
            scan_status = $fscanf(input_file, "%d\n", angle);
            if (scan_status != 1) begin
                $display("Error: Failed to read angle from file.");
                $finish;
            end
            
            // Apply angle and wait for results
            #200; // Wait for a few cycles for the pipeline to settle
            
            // Convert fixed-point results to floating-point
            sine_flt = fixed_to_float(sine);
            cosine_flt = fixed_to_float(cosine);
            
            // Display results
            $display("Angle: %d, Sine: %f, Cosine: %f", angle, sine_flt, cosine_flt);
        end
        
        // Close file
        $fclose(input_file);
        
        // End simulation
        $display("Simulation completed.");
        $finish;
    end
endmodule
