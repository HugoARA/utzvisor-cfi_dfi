`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2017 02:02:09 AM
// Design Name: 
// Module Name: sim_module_dDFG
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


module sim_module_dDFG(

    );
    
    parameter integer N_ADDR_WIDTH = 32;
    parameter integer N_DATA_WIDTH = 32;
 
    parameter integer LOGTABLE_ADDRINIT = 32'h1FEFFC00;
    parameter integer LOGTABLE_ADDREND =  32'h1FF00000 -32'h00000008;
    
    parameter integer N_LOGID_WIDTH = 8;
    parameter integer N_DFG_LINES = 10;

    reg clk = 0;
    reg rst = 0;
    reg i_trigger = 0;
    reg [N_ADDR_WIDTH-1:0] i_logAddrptr;
    reg i_logDone;
    reg [N_DATA_WIDTH + N_LOGID_WIDTH -1 : 0] i_logData;
    wire o_invWrite;
    wire o_rqAccess;
    wire [N_ADDR_WIDTH-1:0] o_logAddr;
    
    
     moduledDFI # (
        .N_ADDR_WIDTH ( N_ADDR_WIDTH),
        .N_DATA_WIDTH ( N_DATA_WIDTH),
     
        //.LOGTABLE_ADDRINIT (LOGTABLE_ADDRINIT),
        //.LOGTABLE_ADDREND (LOGTABLE_ADDREND),
        
        .N_LOGID_WIDTH (N_LOGID_WIDTH),
        .N_DFG_LINES (N_DFG_LINES)
    ) dDFI (
        .clk(clk),
        .rst(rst),
        .i_trigger(i_trigger),
        .i_logAddrptr(i_logAddrptr),
        .i_logDone(i_logDone),
        .i_logData(i_logData),
        .o_invWrite(o_invWrite),
        .o_rqAccess(o_rqAccess),
        .o_logAddr(o_logAddr)
    );


    initial
    begin
    i_logAddrptr = 32'h1FEFFc18; 
    i_logDone = 0;
    i_logData = 40'h0300000005;
            // 8 log_ID = 03;
            // 32 log_Data = 00000005;
    end
    
    
    initial
    begin
    #130;
    #115;
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #50;
    i_logData = 40'h0400000040;
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #100;
 //   i_logAddrptr = 32'h0x1FEFFc20;
    #30
     i_logData = 40'h0900000015;
    i_logDone = 1;
    #10;
    i_logDone = 0;
   /* #50;
    i_logDone = 1;
    #10;
    i_logDone = 0;*/
    end
    
    initial
    begin
    #130;
    rst = 1;
    #10;
    i_trigger = 1;
    #10
    i_trigger = 0;
    end
    
    always #5 clk = ~clk;

endmodule
