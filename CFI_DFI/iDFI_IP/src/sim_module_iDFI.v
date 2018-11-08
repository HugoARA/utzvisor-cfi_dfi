`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/02/2017 06:00:21 PM
// Design Name: 
// Module Name: sim_module_iDFI
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


module sim_module_iDFI(

    );
    parameter integer N_ADDR_WIDTH = 32;
    parameter integer N_DATA_WIDTH = 32;
 
    parameter integer LOGTABLE_ADDRINIT = 32'h1FEFF800;
    parameter integer LOGTABLE_ADDREND =  32'h1FEFFBFC - 32'h0000000C;
    
    parameter N_IDLOG_TEMP = 32;
    parameter integer N_IDLOG_WIDTH = 8;
    parameter integer N_ADDRLOG_WIDTH = 32;
    parameter integer N_DATALOG_WIDTH = 32;
    
    reg clk = 0;
    reg rst = 0;
    reg i_trigger = 0;    
    reg [N_ADDR_WIDTH-1:0] i_logAddrptr;
    reg i_logDone;
    reg [N_IDLOG_TEMP + N_ADDRLOG_WIDTH + N_DATALOG_WIDTH -1 :0] i_logData;
    wire o_invWrite;
    wire o_invAccess;
    wire o_rqAccess;
    wire [N_ADDR_WIDTH-1:0] o_logAddr;
    
    moduleiDFI # (
        .N_ADDR_WIDTH ( N_ADDR_WIDTH),
        .N_DATA_WIDTH ( N_DATA_WIDTH),
     
        .LOGTABLE_ADDRINIT (LOGTABLE_ADDRINIT),
        .LOGTABLE_ADDREND (LOGTABLE_ADDREND),
        
        .N_IDLOG_WIDTH (N_IDLOG_WIDTH),
        .N_ADDRLOG_WIDTH (N_ADDRLOG_WIDTH), 
        .N_DATALOG_WIDTH (N_DATALOG_WIDTH)
    ) iDFI (
        .clk(clk),
        .rst(rst),
        .i_trigger(i_trigger),
        .i_logAddrptr(i_logAddrptr),
        .i_logDone(i_logDone),
        .i_logData(i_logData),
        .o_invWrite(o_invWrite),
        .o_invAccess(o_invAccess),
        .o_rqAccess(o_rqAccess),
        .o_logAddr(o_logAddr)
    );
        
    initial
    begin
    i_logAddrptr = 32'h1FEFF830; 
    i_logDone = 0;
    i_logData = 72'h0;
    //i_logData = 72'h020000001800000050;
            // 8 log_ID = 02;
            // 32 log_addr_Data = 00000014;;
            // 32 log_Data = 00000050;
    end
    
    initial
    begin
    #200;
    #55;
    i_trigger = 1;
    #10
    i_trigger = 0;
    end
    
    initial
    begin
    #285;
   // i_logData = 72'h030000001800000020;
    i_logData = 96'h000000020000001400000020;
    //  i_logData = 96'h0000000050000000c00000007;
    i_logDone = 1;
    #10;
    i_logDone = 0;
    #200;
   // i_logData = 96'h000000200000000C00000007;
   // i_logData = 96'h000000060000001400000020;
   // i_logData = 96'h000000040000000800000006;
  //  #10
 //   i_logData = 72'h030000001800000081;
     i_logData = 96'h000000070000001400000090;
    i_logDone = 1;
    #10;
    i_logDone = 0;/*
    #190
    i_logData = 96'h000000030000001800000030;
    i_logDone = 1;
    #10;
    i_logDone = 0;*/
    end
    
    initial
    begin
    
    #200
    rst = 1;
    end
    
    always #5 clk = ~clk;
    
    
endmodule