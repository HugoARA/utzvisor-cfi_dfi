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


module cfg_controller #(
parameter integer N_ADDR_WIDTH = 32,
parameter integer N_DATA_WIDTH = 32,

parameter integer N_CFGADDR_WIDTH = 8,
parameter integer N_CFGLINES_WIDTH = 11, // number of available lines in the cfg table
parameter integer N_CFGDATA_WIDTH = 80,
parameter integer N_SUCCRADDR_WIDTH = 8,    // number of bits of successor and width
parameter integer N_SUCCRDATA_WIDTH = N_CFGADDR_WIDTH    // number of bits of successor and width 
)(
input wire clk,
input wire rst,

input wire i_srch_pulse,
input wire i_match_vld,

output [N_ADDR_WIDTH -1 :0] o_addr_init,
output [N_ADDR_WIDTH -1 :0] o_addr_end,
output o_nvalid    // indicate a error
);

// State machine to initialize counter, initialize write transactions, 
// initialize read transactions and comparison of read data with the 
// written data words.
localparam [1:0]	IDLE	 = 2'b00, // This state waits for the trigger
					SRCH_CFG = 2'b01, // This state is to genarate signal to srch the table CFG
	                MEM_LAT  = 2'b10; // Ths state waits for the valid data from tables because memory latency
	               
reg [1:0] exec_state;


reg [N_CFGADDR_WIDTH-1 : 0] addr_cfgTable;    // addr in the cfg table
reg [N_CFGDATA_WIDTH-1:0] data_cfgTable;                       // data from cfg that will be decode

wire [N_CFGDATA_WIDTH-1:0] spo_cfgTable;   

//Decode of CFG DATA
wire [N_SUCCRADDR_WIDTH-1 : 0] succrtable_ptr;      // variables to decode for CFG_table
wire [N_SUCCRADDR_WIDTH-1 : 0] succrtable_width;    // variable direct from CFG table

reg [N_SUCCRADDR_WIDTH-1 : 0] addr_succrTable; 
reg [N_SUCCRDATA_WIDTH-1 : 0] data_succrTable; 

wire [N_SUCCRDATA_WIDTH-1 : 0] spo_succrTable; 

//Decode of Sucessor_Table
wire [N_CFGADDR_WIDTH-1 : 0] cfgtable_ptr;    // addr in the cfg table

reg [N_CFGADDR_WIDTH-1 : 0] cfg_width;
reg ncross_cfgTable;

//Control Signals
wire inc_addrCFG;
wire load_succr;

reg [N_SUCCRADDR_WIDTH-1 : 0] addrforsuccrTb;
reg [N_CFGADDR_WIDTH-1 : 0] addrforcfgTb;
reg [N_CFGADDR_WIDTH-1 : 0] n_cfglines;

// I/O Connections assignments
// Decode the CFG Table 
assign {o_addr_init, o_addr_end, succrtable_ptr, succrtable_width} = data_cfgTable;
assign cfgtable_ptr = data_succrTable;

//assign load_cfgptr = (i_match_vld && exec_state == SRCH_CFG);
assign o_nvalid = (cfg_width == 0);
assign inc_addrCFG = (i_srch_pulse && exec_state == IDLE);
assign load_succr = (i_match_vld && exec_state == SRCH_CFG);
//	assign addr_succrTable = succrtable_ptr;

//ROMs
CFG_Table cfg_tb (
  .a(addr_cfgTable),   // input wire [7 : 0] a
  .spo(spo_cfgTable)  // output wire [79 : 0] spo
);

Sucessor_Table successor_tb (
  .a(addr_succrTable),    // input wire [7 : 0] a
  .spo(spo_succrTable)         // output wire [7 : 0] spo
);

always @(rst or inc_addrCFG or load_succr)
begin
	if(!rst)
	 begin
	// reset condition                                                            
	// All the signals are assigned default values under reset condition
	  addrforcfgTb = 0;
	  addrforsuccrTb = 0;
	  
	 end
	else begin
	  if (inc_addrCFG) begin 
			  addrforcfgTb = (ncross_cfgTable)? cfgtable_ptr : addr_cfgTable + 1;
			  addrforsuccrTb = addr_succrTable + 1;
			  n_cfglines = cfg_width - 1;
	  end
	  else 
		  if (load_succr) begin
				addrforsuccrTb = succrtable_ptr;
				n_cfglines = succrtable_width + 1;
	  end
	  
	end
end

always @ (negedge clk)
begin
    if(!rst)
    begin
        data_cfgTable <= 0;
        data_succrTable <= 0;
    end
    else
    begin
        data_cfgTable <= spo_cfgTable;
        data_succrTable <= spo_succrTable;
    end
end

always @(posedge clk)
begin
	if(!rst)
	 begin
	// reset condition                                                            
	// All the signals are assigned default values under reset condition
		addr_cfgTable <= 0;
		addr_succrTable <= 0;
		cfg_width <= N_CFGLINES_WIDTH;
		exec_state  <= IDLE;
		ncross_cfgTable <= 0;
	 end
	else begin
		// state transition                                                          
		case (exec_state)
			IDLE:
				if(i_srch_pulse && cfg_width > 0) begin
				   addr_cfgTable <= addrforcfgTb;
				   addr_succrTable <= addrforsuccrTb;
				   cfg_width <= n_cfglines;
					  
				   exec_state <= SRCH_CFG;
				end
				
			SRCH_CFG:begin
				if(i_match_vld && cfg_width > 0) begin
				    ncross_cfgTable <= 1;
					cfg_width <= n_cfglines;
					addr_succrTable <= addrforsuccrTb;
				end
				exec_state <= IDLE;
			end
		endcase
	end
end
endmodule