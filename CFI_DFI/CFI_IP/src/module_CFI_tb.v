/*`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2017 18:11:17
// Design Name: 
// Module Name: module_CFI_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module module_CFI_tb;

    reg clk;
    reg rst;
    reg i_trigger;
    reg [31:0] i_logAddrptr;
    reg i_logDone;
    reg [31:0] i_logData;
    
    wire o_invBranch;
    wire o_rqAccess;
    wire [31:0] o_logAddr;
    
moduleCFI #(
    .N_ADDR_WIDTH(32),
    .N_DATA_WIDTH(32),

    .LOGTABLE_ADDRINIT(32'h0),		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
    .LOGTABLE_ADDREND(32'hffffffff),		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
    .LOGTABLE_RANGE(32'hffffffff - 32'h0) 		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
) uut (
    .clk(clk),
    .rst(rst),
   
    .i_trigger(i_trigger),
    .i_logAddrptr(i_logAddrptr),
   
    .i_logDone(i_logDone),
    .i_logData(i_logData),
   
    .o_invBranch(o_invBranch),
   
    .o_rqAccess(o_rqAccess),
    .o_logAddr(o_logAddr)
    );

initial
begin
    i_logData = 32'ha3aaaaab;
end 

initial 
begin
    i_logAddrptr = 32'hff0;
end

initial
begin
    i_logDone = 0;
    #100 i_logDone = 1;
end 

initial
begin
    #5 i_trigger = 0;
    #10 i_trigger = 1;
    #20 i_trigger = 0;
end 

initial
begin
    clk = 0;
    forever #5 clk = !clk;
end

initial
begin
    rst = 1;
    #5 rst = 0;
    #10 rst = 1;
end
    
endmodule
*/

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2017 18:11:17
// Design Name: 
// Module Name: module_CFI_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module module_CFI_tb;

    reg clk = 0;
    reg rst = 0;
    reg i_trigger = 0;
    reg [31:0] i_logAddrptr;
    reg i_logDone = 0;
    reg [31:0] i_logData;
    
    wire o_invBranch;
    wire o_rqAccess;
    wire [31:0] o_logAddr;
    
moduleCFI #(
    .N_ADDR_WIDTH(32),
    .N_DATA_WIDTH(32)

//    .LOGTABLE_ADDRINIT(32'h0),		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
//    .LOGTABLE_ADDREND(32'hffffffff)		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
    //.LOGTABLE_RANGE(32'hffffffff - 32'h0) 		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
) uuto (
    .clk(clk),
    .rst(rst),
   
    .i_trigger(i_trigger),
    .i_logAddrptr(i_logAddrptr),
   
    .i_logDone(i_logDone),
    .i_logData(i_logData),
   
    .o_invBranch(o_invBranch),
   
    .o_rqAccess(o_rqAccess),
    .o_logAddr(o_logAddr)
    );

initial
begin
    i_logData = 32'ha8aaaaab;
   //  i_logData = 32'h0;
end 

initial 
begin
    i_logAddrptr = 32'h0x1FEFF504;
end

initial
begin
    #130;
    #35;
    i_trigger = 1;
    #10
    i_trigger = 0;
//    #95;
 //   i_logData = 32'ha5aaaaab;
   /* i_trigger = 1;
    #10
    i_trigger = 0;*/
end

initial
begin
    #130;
    #85;
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #275;
    i_logData = 32'ha8aaaaab;
    //#10
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #75;
    i_logData = 32'ha4aaaaab;
    //#10
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #75;
    //i_logData = 32'ha9aaaaab;
    //#10
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #80
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #115;
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #80;
   /* i_logData = 32'ha5aaaaab;
    i_logDone = 1;
    #10;
    i_logDone = 0;
*/
end

    always #5 clk = ~clk;
    

initial
begin

    #30
    rst = 1;
end

endmodule
