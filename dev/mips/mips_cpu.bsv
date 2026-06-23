module mips_cpu
(
    input clk,              // Clock input
    input reset,            // Reset input
    input int_ext,          // External interrupt input
    input [7:0] fromhost,   // Value from test rig
    output [7:0] tohost,    // Output to test rig
    output [31:0] addr,     // Data memory address
    output wen,             // Data memory write enable
    output [31:0] write_data, // Data to write to memory
    input [31:0] read_data, // Data read back from memory
    output [31:0] iaddr,    // Instruction address
    input [31:0] inst       // Instruction bits
);