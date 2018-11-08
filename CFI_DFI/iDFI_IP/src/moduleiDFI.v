`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2017 01:37:00
// Design Name: 
// Module Name: moduleiDFI
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


module moduleiDFI #(
   parameter integer N_ADDR_WIDTH = 32,
   parameter integer N_DATA_WIDTH = 32,

   parameter integer LOGTABLE_ADDRINIT = 32'h1FEFF800,
   parameter integer LOGTABLE_ADDREND =  32'h1FEFFBFC - 32'h0000000C, // the increment is 12 bytes.. so 400 (lenght) / 12 bytes = 55 ( hex) logs
	parameter integer N_PTR_LINES = 6,   // lines of ptr table
    parameter N_IDLOG_TEMP = 32,
    parameter integer N_IDLOG_WIDTH = 8,
    parameter integer N_ADDRLOG_WIDTH = 32,
    parameter integer N_DATALOG_WIDTH = 32  // need to equal to above
)(
    input wire clk,
    input wire rst,
    
    input wire i_trigger,
    input wire [N_ADDR_WIDTH-1:0] i_logAddrptr,
    
    input wire i_logDone,
    input wire [N_IDLOG_TEMP + N_ADDRLOG_WIDTH + N_DATALOG_WIDTH -1:0] i_logData,

    output wire o_invWrite,
    output wire o_invAccess,
    
    output wire o_rqAccess,
    output wire [N_ADDR_WIDTH-1:0] o_logAddr
    );
    
    // function called width_addr that returns an integer which has the
    // value of the difference btw the two addr input
    integer LOGTABLE_RANGE =  LOGTABLE_ADDREND - LOGTABLE_ADDRINIT;

	// State machine to initialize counter, initialize write transactions, 
    // initialize read transactions and comparison of read data with the 
    // written data words.
    localparam [2:0]	IDLE	 = 3'b000, // This state compares the logs addr 
     					READ_LOG = 3'b001, // This state initializes read transaction
     					LD_ID    = 3'b010, // This state give a reset for the dfg controller
						CMP_LOG	 = 3'b011, // This state compares the log with the CFGlog
						SRCH_DFG = 3'b100; // This state is to genarate signal to srch the table CFG
						
	reg [2:0] exec_state;
    reg inv_Write;
    reg inv_Access;
    //DFI signals
    reg  [N_ADDR_WIDTH-1 : 0] addrRAM_ptr;
    reg  [N_ADDR_WIDTH-1 : 0] log_ptr;
    wire [N_ADDR_WIDTH-1 : 0] n_logs;
    reg  [N_IDLOG_TEMP + N_ADDRLOG_WIDTH + N_DATALOG_WIDTH -1 : 0] logreceived;
    
    //Decode Log
    wire [N_IDLOG_WIDTH-1 : 0] logID;
    wire [N_ADDRLOG_WIDTH-1 : 0] logaddrData;
    wire [N_DATALOG_WIDTH-1 : 0] logData;
    
    //DFI control signals
    wire load_logptr; // equals to i_trigger
    wire load_logdata;
    
    //DFG signals controller
    wire clr;
    wire srch_pulseiDFG;

    wire [N_IDLOG_WIDTH-1 : 0] addrID_iDFG;
    
    wire [N_ADDRLOG_WIDTH -1 : 0] addrdata_iDFG;
    wire [N_DATALOG_WIDTH -1 :0] initdata_iDFG;
    wire [N_DATALOG_WIDTH -1 :0] enddata_iDFG;
    wire error_iDFG;
    wire match_vld;
    wire rule_vld;  
    wire overflow;  

    wire [31 : 0] result;
    
    subtract_ptr subb_ptr (
    .A(log_ptr),          // input wire [31 : 0] A
    .B(addrRAM_ptr),          // input wire [31 : 0] B
    .C_OUT(overflow),  // output wire C_OUT
    .S(result)          // output wire [31 : 0] S
    ); 
    
    // I/O Connections assignments
    assign n_logs = ( overflow ) ? ((result)/4) : (result + LOGTABLE_RANGE/4);
    assign o_logAddr = addrRAM_ptr;
    
    //Decode Log
    assign logID = logreceived [N_IDLOG_WIDTH + N_ADDRLOG_WIDTH + N_DATALOG_WIDTH -1 : N_ADDRLOG_WIDTH + N_DATALOG_WIDTH] ;
    assign logaddrData = logreceived [N_ADDRLOG_WIDTH+N_DATALOG_WIDTH-1 : N_DATALOG_WIDTH];
    assign logData = logreceived [N_DATALOG_WIDTH-1 : 0];
    
    
    assign match_vld = (logaddrData == addrdata_iDFG);
    
    assign rule_vld = (initdata_iDFG <= logData) && (logData <= enddata_iDFG);
    assign o_invWrite = inv_Write;
    assign o_invAccess = inv_Access;
        
    assign load_logptr = (i_trigger);
    assign o_rqAccess = (!i_logDone && exec_state == READ_LOG);
    assign load_logdata  = (i_logDone && (exec_state == READ_LOG));

  //  assign clr = (!(i_logDone && (exec_state == LD_ID))) && rst;
    assign clr = !(exec_state == LD_ID) & rst;
    assign srch_pulseiDFG = (exec_state == SRCH_DFG);
    assign addrID_iDFG = logID;
 
   	//DFG_CONTROLLER
   	
   	dfg_controller # ( 
   		.N_PTR_LINES ( N_PTR_LINES)   	
   	) DFG_CNTLR (
		.clk(clk),
		.rst(rst),
		.clr(clr),
		.i_srch_pulse(srch_pulseiDFG),
		.i_addr_srch(addrID_iDFG),
		.o_addr_DFG(addrdata_iDFG),
		.o_data_init(initdata_iDFG),
		.o_data_end(enddata_iDFG),
		.error(error_iDFG)
   	);
   	
    wire [31 : 0]result_sum;
    
    add_ptr add_pointer (
      .A(addrRAM_ptr),  // input wire [31 : 0] A
      .B(12),  // input wire [3 : 0] B
      .S(result_sum)  // output wire [31 : 0] S
    );
   
    always @(*)
	begin
		if(!rst)
		 begin
		// reset condition                                                            
		// All the signals are assigned default values under reset condition 
			log_ptr 	= LOGTABLE_ADDRINIT;
			logreceived 	= 'b0;
		 end
		else begin
			//LOAD the input addrptr (to compare with the log 
			if(load_logptr) begin
				log_ptr = i_logAddrptr;
			end
			//LOAD the log data to be compared with the line CFG
			//increment ptr to access LOG
			if(load_logdata) begin
				logreceived = i_logData;
				//logreceived = 72'h030000002400000050;
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
			inv_Write <= 0;
			inv_Access <= 0;
    	 end
    	else begin
    		// state transition                                                          
    		case (exec_state)
				IDLE:
					if( !((!rule_vld && match_vld) || error_iDFG) && n_logs>0)		//If no error and there is still offset btw the addr readed and addr to read
						exec_state <= READ_LOG;
			     
				READ_LOG:
				begin
					if(i_logDone)
					begin   //if succeful reading
						addrRAM_ptr <= (addrRAM_ptr >= LOGTABLE_ADDREND)? LOGTABLE_ADDRINIT : result_sum;
						exec_state <= LD_ID;
			        end
			        else
			             exec_state <= READ_LOG;
			    end
                LD_ID:
                begin
                    exec_state <= CMP_LOG;
                end 
				CMP_LOG://if there is a match return to IDLE, if not keep srching
				    begin
					exec_state <= (!match_vld && !error_iDFG)? SRCH_DFG : IDLE;
					inv_Write <= ((!rule_vld) && match_vld);
					inv_Access <= error_iDFG;
					end
				SRCH_DFG:
				begin
					exec_state <= CMP_LOG;
			    end
				
				default: ;				 	 
    		endcase
    	end
    end
endmodule
