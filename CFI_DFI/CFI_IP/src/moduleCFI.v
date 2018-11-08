`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.05.2017 00:22:40
// Design Name: 
// Module Name: moduleCFI
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


module moduleCFI #(
   parameter integer N_ADDR_WIDTH = 32,
   parameter integer N_DATA_WIDTH = 32,
   parameter integer N_CFGLINES_WIDTH = 11, // available lines in the cfg
   parameter integer LOGTABLE_ADDRINIT =    32'h1FEFF400,		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
   parameter integer LOGTABLE_ADDREND =     32'h1FEFF800	- 32'h00000004	//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
)(
    input wire clk,
    input wire rst,
    
    input wire i_trigger,
    input wire [N_ADDR_WIDTH-1:0] i_logAddrptr,
    
    input wire i_logDone,
    input wire [N_DATA_WIDTH-1:0] i_logData,
    
    output wire o_invBranch,
    
    output wire o_rqAccess,
    output wire [N_ADDR_WIDTH-1:0] o_logAddr
    );
       
	// State machine to initialize counter, initialize write transactions, 
    // initialize read transactions and comparison of read data with the 
    // written data words.
    localparam [1:0]	IDLE	 = 2'b00, // This state compares the logs addr 
     					READ_LOG = 2'b01, // This state initializes read transaction
						CMP_LOG	 = 2'b10, // This state compares the log with the CFGlog
						SRCH_CFG = 2'b11; // This state is to genarate signal to srch the table CFG
						
	localparam [31:0] LOGTABLE_RANGE = LOGTABLE_ADDREND - LOGTABLE_ADDRINIT;
	
	reg [1:0] exec_state;
/*
    reg [N_ADDR_WIDTH-1:0] i_logAddrptr = 32'h1FEFF410;
    
    reg [N_DATA_WIDTH-1:0] i_logData = 32'ha8aaaaaa;

    wire [N_ADDR_WIDTH-1:0] o_logAddr;
*/


    //CFI signals
    reg [N_ADDR_WIDTH-1 : 0] addrRAM_ptr;
    reg [N_ADDR_WIDTH-1 : 0] log_ptr;
    wire [N_ADDR_WIDTH-1 : 0] n_logs;
    reg [N_DATA_WIDTH-1 : 0] logData;
    
	wire [N_ADDR_WIDTH-1 : 0] result;
	wire [N_DATA_WIDTH-1 : 0]	result_sum;
    wire load_logptr;
    wire load_logdata;
	    
    //CFG signals controller
    wire srch_pulseCFG;
    wire match_vldCFG;
    wire [N_ADDR_WIDTH-1 : 0] initaddrCFG;
    wire [N_ADDR_WIDTH-1 : 0] endaddrCFG;
    wire errorCFG;
    
    // I/O Connections assignments
    assign n_logs = ( overflow ) ? ((result)/4) : (result + LOGTABLE_RANGE/4);
    assign o_logAddr = addrRAM_ptr;
	
    assign match_vldCFG = ((initaddrCFG <= logData) && ( logData <= endaddrCFG ));
    //assign match_vldCFG = (initaddrCFG == logData);
    assign o_invBranch = errorCFG;
    
    assign load_logptr = (i_trigger);
    assign o_rqAccess = (!i_logDone && exec_state == READ_LOG);
    assign load_logdata  = (i_logDone && (exec_state == READ_LOG));
    assign srch_pulseCFG = /*(i_logDone && (exec_state == READ_LOG)) ||*/ (exec_state == SRCH_CFG);
	
	// function called width_addr that returns an integer which has the
    // value of the difference btw the two addr input
	subtract_ptr subb_ptr (
		.A(log_ptr),          // input wire [31 : 0] A
        .B(addrRAM_ptr),          // input wire [31 : 0] B
        .C_OUT(overflow),  // output wire C_OUT
        .S(result)          // output wire [31 : 0] S
    );

   	//CFG_CONTROLLER
   	cfg_controller #( 
   	   .N_CFGLINES_WIDTH (N_CFGLINES_WIDTH)
   	) CFG_CNTLR(
		.clk(clk),
		.rst(rst),
		.i_srch_pulse(srch_pulseCFG),
		.i_match_vld(match_vldCFG),
		.o_addr_init(initaddrCFG),
		.o_addr_end(endaddrCFG),
		.o_nvalid(errorCFG)
   	);
    
    add_ptr_CFI add_pointer_CFI ( // this adder sums 4 because the log is 4 bytes
      .A(addrRAM_ptr),  // input wire [31 : 0] A
      .S(result_sum)  // output wire [31 : 0] S
    );
    
    always @(rst or load_logptr or load_logdata)
	begin
		if(!rst)
		 begin
		// reset condition                                                            
		// All the signals are assigned default values under reset condition                        
			//addrRAM_ptr = 'b0;
			log_ptr 	<= LOGTABLE_ADDRINIT;
			logData 	= 'b0;
		 end
        else 
        begin
        //LOAD the input addrptr (to compare with the log 
            if(load_logptr)
                log_ptr = i_logAddrptr;
        
        //LOAD the log data to be compared with the line CFG
        //increment ptr to access LOG
            if(load_logdata) begin
                logData = i_logData;
            end
		end
	end
    
    always @(posedge clk)
    begin
    	if(!rst)
    	 begin
    	// reset condition
    	// All the signals are assigned default values under reset condition
            addrRAM_ptr <= LOGTABLE_ADDRINIT;          
			exec_state  <= IDLE;
    	 end
    	else begin
    		// state transition                                                          
    		case (exec_state)
				IDLE: begin
					if(!errorCFG && n_logs>0)		//If no error and there is still offset btw the addr readed and addr to read
						exec_state <= READ_LOG;

			    end
				READ_LOG: begin
					if(i_logDone) begin				//if succeful reading
                        addrRAM_ptr = ( addrRAM_ptr >= LOGTABLE_ADDREND)? LOGTABLE_ADDRINIT: result_sum;
						exec_state <= SRCH_CFG;		            
			        end
                end
				CMP_LOG://if there is a match or an error return to IDLE, if not keep srching
					exec_state <= (!(match_vldCFG || errorCFG))? SRCH_CFG : IDLE;	

				SRCH_CFG:
					exec_state <= CMP_LOG;
								 	 
    		endcase
    	end
    end
  
endmodule