`timescale 1ns / 1ps

module log_accesser # (
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32,
    parameter integer CFI_LOG_WIDTH = 32,
    parameter integer IDFI_LOG_WIDTH = 96,
    parameter integer DDFI_LOG_WIDTH = 64
    )(
    input clk,
    input rst,
    input i_cfi_req,
    input i_idfi_req,
    input i_ddfi_req,
    input [ADDR_WIDTH - 1:0] i_addr_cfi,
    input [ADDR_WIDTH - 1:0] i_addr_idfi,
    input [ADDR_WIDTH - 1:0] i_addr_ddfi,
    output o_done_cfi,
    output o_done_idfi,
    output o_done_ddfi,
    output [CFI_LOG_WIDTH - 1:0] o_data_cfi,
    output [IDFI_LOG_WIDTH - 1:0] o_data_idfi,
    output [DDFI_LOG_WIDTH - 1:0] o_data_ddfi,
    // I/Os to AXI Memory Reader
    output [ADDR_WIDTH - 1:0] o_mem_addr,
    output o_read_trigger,
    input [DATA_WIDTH - 1:0] i_mem_value,
    input i_done,
    input i_error
    );
    
    localparam CFI_MAX_INC = CFI_LOG_WIDTH / DATA_WIDTH;
    localparam IDFI_MAX_INC = IDFI_LOG_WIDTH / DATA_WIDTH;
    localparam DDFI_MAX_INC = DDFI_LOG_WIDTH / DATA_WIDTH;
    
    // the four different states
    localparam [3:0] IDLE1      = 4'b0000, //0
                     IDLE2       = 4'b0001, //1
                     IDLE3       = 4'b0010, //2
                     CFI_REQ     = 4'b0011, //3
                     IDFI_REQ    = 4'b0100, //4
                     DDFI_REQ    = 4'b0101, //5
                     WAIT_CFI    = 4'b0110,
                     WAIT_IDFI   = 4'b0111,
                     WAIT_DDFI   = 4'b1000;
                   // WAIT_REQ    = 3'b110; //6
    
    reg [3:0] exec_state;
    
    reg [3:0] n_request;
    reg [ADDR_WIDTH - 1:0] req_addr;
    assign o_mem_addr = req_addr;
    
    wire ld_mem_addr;
    
    wire ld__cfi_data;
    wire ld__idfi_data;
    wire ld__ddfi_data;
    
    assign o_read_trigger = (n_request != 0) &  ((exec_state == CFI_REQ) |
                                                (exec_state == IDFI_REQ) |
                                                (exec_state == DDFI_REQ));
                                                
    assign ld_mem_addr = o_read_trigger;
   
    assign o_done_cfi = (n_request == 0) &  (exec_state == CFI_REQ);
    assign o_done_idfi = (n_request == 0) &  (exec_state == IDFI_REQ);
    assign o_done_ddfi = (n_request == 0) &  (exec_state == DDFI_REQ);
   
    assign ld__cfi_data = (exec_state == WAIT_CFI) & i_done;
    assign ld__idfi_data = (exec_state == WAIT_IDFI) & i_done;
    assign ld__ddfi_data = (exec_state == WAIT_DDFI) & i_done;
    
    reg [CFI_LOG_WIDTH - 1:0] data_cfi;
    reg [IDFI_LOG_WIDTH - 1:0] data_idfi;
    reg [DDFI_LOG_WIDTH - 1:0] data_ddfi;
    
    assign o_data_cfi = data_cfi;
    assign o_data_idfi = data_idfi;
    assign o_data_ddfi = data_ddfi;
   
    /*always @(rst or ld_mem_addr or ld__cfi_data or ld__idfi_data or ld__ddfi_data) 
    begin
        if (rst == 0) begin
            data_cfi = 0;
            data_idfi = 0;
            data_ddfi = 0;
            mem_addr = 0;
        end
        else begin
            if (ld_mem_addr)
                mem_addr = req_addr;
            else
                mem_addr = mem_addr;
        
            if (ld__cfi_data)
                data_cfi[(CFI_MAX_INC - n_request) * DATA_WIDTH +: DATA_WIDTH] = i_mem_value;
            else
                data_cfi = data_cfi;
                
            if (ld__idfi_data) 
                data_idfi[(IDFI_MAX_INC - n_request) * DATA_WIDTH +: DATA_WIDTH] = i_mem_value;
            else
                data_idfi = data_idfi;
            
            if (ld__ddfi_data) 
                data_ddfi[(DDFI_MAX_INC - n_request) * DATA_WIDTH +: DATA_WIDTH] = i_mem_value;     
            else
                data_ddfi = data_ddfi;
        end
    end*/
    
    
    // choose the next state block
    always @(posedge clk)
    begin
        if (rst == 0)
        begin
            n_request <= 0;
            exec_state <= IDLE1;
            data_cfi <= 0;
            data_idfi <= 0;
            data_ddfi <= 0;
        end
        else
        begin
            case (exec_state)
                //IDLES
                IDLE1: begin
                    n_request <= CFI_MAX_INC;
                    req_addr <= i_addr_cfi;
                    exec_state <= (i_cfi_req) ? CFI_REQ : IDLE2;
                end
                IDLE2: begin
                    n_request <= IDFI_MAX_INC;
                    req_addr <= i_addr_idfi;
                    exec_state <= (i_idfi_req) ? IDFI_REQ : IDLE3;
                end                
                IDLE3: begin
                    n_request <= DDFI_MAX_INC;
                    req_addr <= i_addr_ddfi;
                    exec_state <= (i_ddfi_req) ? DDFI_REQ : IDLE1;
                end
                //REQUESTS
                CFI_REQ: begin
                    exec_state <= (n_request != 0) ? WAIT_CFI : IDLE2;
                end
                IDFI_REQ: begin
                    exec_state <= (n_request != 0) ? WAIT_IDFI : IDLE3;
                end
                DDFI_REQ: begin
                    exec_state <= (n_request != 0) ? WAIT_DDFI : IDLE1;
                end
                // WAITS
                WAIT_CFI: begin
                    if (i_done) begin
                        data_cfi[(CFI_MAX_INC - n_request) * DATA_WIDTH +: DATA_WIDTH] <= i_mem_value;
                        n_request <= n_request - 1;
                        req_addr <= req_addr + 4;
                        exec_state <= CFI_REQ;
                    end
                end
                WAIT_IDFI: begin
                    if (i_done) begin 
                        data_idfi[(IDFI_MAX_INC - n_request) * DATA_WIDTH +: DATA_WIDTH] = i_mem_value;
                        n_request <= n_request - 1;
                        req_addr <= req_addr + 4;
                        exec_state <= IDFI_REQ;
                    end
                end
                WAIT_DDFI: begin
                    if (i_done) begin
                        data_ddfi[(DDFI_MAX_INC - n_request) * DATA_WIDTH +: DATA_WIDTH] = i_mem_value;
                        n_request <= n_request - 1;
                        req_addr <= req_addr + 4;
                        exec_state <= DDFI_REQ;
                    end
                end
            endcase
       end
    end
    
endmodule
