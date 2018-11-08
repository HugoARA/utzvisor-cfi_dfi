`timescale 1ns / 1ps



module moduledDFI #(
    parameter integer N_ADDR_WIDTH = 32,
    parameter integer N_DATA_WIDTH = 32,
    
    parameter integer N_LOG_DATA_WIDTH = 64,
    parameter integer N_LOGID_WIDTH = 8,
    parameter integer N_DFG_LINES = 10,
    
    parameter integer LOGTABLE_ADDRINIT =  32'h1FEFFC00,		//32'hf0000028;//10(a)*4; (BASE_ADDR + BASE_END + 4 bytes) = 10 positions of 32 bits ( 4 bytes)
    parameter integer LOGTABLE_RANGE =     32'h00000400
    
  )(
    input wire clk,
    input wire rst,
    
    input wire i_trigger,
    input wire [N_ADDR_WIDTH - 1:0] i_logAddrptr,
    
    input wire i_logDone,
    input wire [N_LOG_DATA_WIDTH - 1 : 0] i_logData,
    
    output reg o_invWrite,
    
    output reg o_rqAccess,
    output reg [N_ADDR_WIDTH - 1:0] o_logAddr
    );
    
    localparam [31:0] LOGTABLE_ADDREND =  LOGTABLE_ADDRINIT + LOGTABLE_RANGE -32'h00000008;		//it subbtract 8 because the log occupy 8 bytes

    // State machine to initialize counter, initialize write transactions, 
    // initialize read transactions and comparison of read data with the 
    // written data words.
    localparam [1:0]	IDLE	 = 2'b00, // This state compares the logs addr 
                        READ_LOG = 2'b01, // This state initializes read transaction
                        CMP_DATA = 2'b10; // This state compares the log with the CFGlog
    
    reg [1:0] exec_state;
    
    //DFI signals
    reg  [N_ADDR_WIDTH - 1 : 0]      addrRAM_ptr;
    reg  [N_ADDR_WIDTH - 1 : 0]      log_ptr;
    wire [N_ADDR_WIDTH - 1 : 0]     n_logs;
    reg  [N_DATA_WIDTH + N_LOGID_WIDTH - 1 : 0]  logreceived;
    
    //Decode logreceived
    wire [N_LOGID_WIDTH - 1 : 0]  logId;
    wire [N_DATA_WIDTH - 1 : 0]   logData;
    
    //Control signals
    wire load_logptr;
    wire load_logdata;
    wire cmp_data;
    
    //DFG_CONTROLLER
    reg  [64 - 1 : 0] data_dDFG;
    wire [64 - 1 : 0] spo_dDFG;
    
    //DFG signals controller
    wire [N_LOGID_WIDTH - 1 : 0]    addr_dDFG;
    wire [N_DATA_WIDTH - 1 : 0]     initdata_dDFG;
    wire [N_DATA_WIDTH - 1 : 0]     enddata_dDFG;
    
    wire match_Datavld;
    
    wire [N_ADDR_WIDTH - 1:0] logAddr;
    wire invWrite;
    wire rqAccess;
    
    wire overflow;
    wire [N_ADDR_WIDTH - 1 : 0] result;
    
    // I/O Connections assignments
    assign n_logs = (overflow)? (result) : (result + LOGTABLE_RANGE);
    assign logAddr = addrRAM_ptr;
    
    assign addr_dDFG = logId;
    
    //Decode logreceived
    assign logId =  logreceived [N_DATA_WIDTH + N_LOGID_WIDTH - 1 : N_DATA_WIDTH];
    assign logData = logreceived [N_DATA_WIDTH - 1 : 0] ;
    
    assign {initdata_dDFG, enddata_dDFG} = data_dDFG;
    
    assign match_Datavld = (initdata_dDFG <= logData) && (logData <= enddata_dDFG);
    
    // Control Signals Connections
    assign invWrite = !match_Datavld;
    
    assign load_logptr = (i_trigger);
    assign rqAccess = (!i_logDone && exec_state == READ_LOG);
    //assign load_logdata  = (i_logDone && (exec_state == READ_LOG));
    //assign cmp_data = (exec_state == CMP_DATA);
    
    
    dDFG_table dDFG (
        .a(addr_dDFG),      // input wire [7 : 0] a
        .spo(spo_dDFG)  // output wire [63 : 0] spo
    );
    
    
    wire [N_ADDR_WIDTH - 1 : 0] addrRAM_ptr_incr;
    
    add_ptr_ddfi add_pointer_ddfi (
      .A(addrRAM_ptr),  // input wire [31 : 0] A
      .S(addrRAM_ptr_incr)  // output wire [31 : 0] S
    );
    
     subtract_ptr subb_ptr (
    .A(log_ptr),          // input wire [31 : 0] A
    .B(addrRAM_ptr),          // input wire [31 : 0] B
    .C_OUT(overflow),  // output wire C_OUT
    .S(result)          // output wire [31 : 0] S
    ); 

    always @(negedge clk)
      begin
        if(!rst)
        begin   // reset condition                                                            
                // All the signals are assigned default values under reset condition                        
            log_ptr    <= LOGTABLE_ADDRINIT;
            o_rqAccess <= 'b0;
            o_logAddr  <= 'b0;
            data_dDFG  <= 32'h00000000;
            o_invWrite <= 'b0;
        end
        else begin
            data_dDFG <= spo_dDFG;
            o_rqAccess <= rqAccess;
            o_logAddr <= logAddr;
            
            if (exec_state == IDLE)
                o_invWrite <= invWrite;
            
            //LOAD the input addrptr (to compare with the log 
            if(load_logptr)
                log_ptr <= i_logAddrptr;
        end
      end

   /* always @(negedge clk)
	begin
		if(!rst)
		 begin
		// reset condition                                                            
		// All the signals are assigned default values under reset condition                        
			log_ptr 	= LOGTABLE_ADDRINIT;
			logreceived	= 'b0;
		 end
		else begin
			//LOAD the input addrptr (to compare with the log 
			if(load_logptr)
				log_ptr = i_logAddrptr;
			
		/*	//LOAD the log data to be compared with the line CFG
			//increment ptr to access LOG
			if(load_logdata) begin
				logreceived = i_logData;
			end*/
	//	end
	//end*/
      
      always @(posedge clk)
      begin
      	if(!rst)
      	 begin
      	// reset condition                                                            
      	// All the signals are assigned default values under reset condition
      	    addrRAM_ptr <= LOGTABLE_ADDRINIT;
      	    logreceived	<= 'b0;       
			exec_state  <= IDLE;
			//o_invWrite <= 'b0;
      	 end
      	else begin
      		// state transition                                                          
      		case (exec_state)
				IDLE: begin
					if(match_Datavld && n_logs>0)		//If no error and there is still offset btw the addr readed and addr to read
						exec_state <= READ_LOG;
			     end
				READ_LOG:
					if(i_logDone) begin    			//if succeful reading
					   logreceived <= i_logData;
					   //addrRAM_ptr <= ( addrRAM_ptr > LOGTABLE_ADDREND)? LOGTABLE_ADDRINIT : addrRAM_ptr + 8;
					   addrRAM_ptr <= ( addrRAM_ptr >= LOGTABLE_ADDREND)? LOGTABLE_ADDRINIT : addrRAM_ptr_incr;
					   exec_state <= CMP_DATA;

					end
			    CMP_DATA:
			         begin
			        // o_invWrite <= invWrite;
			         exec_state <= IDLE;
			         end
      		endcase
      	end 
      end
      
endmodule