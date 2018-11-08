`timescale 1ns / 1ps

module log_accesser_tb;

    reg clk;
    reg rst;
    
    reg cfi_req;
    reg idfi_req;
    reg ddfi_req;
    
    reg [31:0] addr_cfi;
    reg [31:0] addr_idfi;
    reg [31:0] addr_ddfi;
    
    wire done_cfi;
    wire done_idfi;
    wire done_ddfi;
    
    wire [31:0] data_cfi;
    wire [95:0] data_idfi;
    wire [63:0] data_ddfi;
    
    wire [31:0] addr_req;
    wire read_trigger;
    
    reg [31:0] axi_value;
    reg axi_done;
    reg axi_error;
    
    log_accesser uut (
        .clk(clk),
        .rst(rst),
        .i_cfi_req(cfi_req),
        .i_idfi_req(idfi_req),
        .i_ddfi_req(ddfi_req),
        .i_addr_cfi(addr_cfi),
        .i_addr_idfi(addr_idfi),
        .i_addr_ddfi(addr_ddfi),
        .o_done_cfi(done_cfi),
        .o_done_idfi(done_idfi),
        .o_done_ddfi(done_ddfi),
        .o_data_cfi(data_cfi),
        .o_data_idfi(data_idfi),
        .o_data_ddfi(data_ddfi),
        .o_mem_addr(addr_req),
        .o_read_trigger(read_trigger),
        .i_mem_value(axi_value),
        .i_done(axi_done),
        .i_error(axi_error)
    );
    
    initial begin
        cfi_req <= 0;
        idfi_req <= 0;
        ddfi_req <= 0;
        addr_cfi <= 32'h00000004;
        addr_idfi <= 32'h00000008;
        addr_ddfi <= 32'h00000005;
        axi_error <= 0;
        axi_value <= 32'h00000000;
        axi_done <= 0;
    end
    
    initial begin
        clk = 1;
        rst = 0;
        #115
        rst = 1;
        #85
        cfi_req <= 1;
        #40
        cfi_req <= 0;
        #25
        idfi_req <= 1;
        #40
        idfi_req <= 0;
        #40
        ddfi_req <= 1;
        #55
        ddfi_req <= 0;
    end
    
    always @(posedge read_trigger)
    begin
        #20
        axi_value <= 32'h000000FF;
        axi_done <= 1;
        #10
        axi_value <= 32'h00000000;
        axi_done <= 0;
    end
    
    always #5 clk <= ~clk;
    
endmodule
