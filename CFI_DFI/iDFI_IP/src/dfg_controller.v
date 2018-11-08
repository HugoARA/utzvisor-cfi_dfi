`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2017 03:37:16 PM
// Design Name: 
// Module Name: dfg_controller
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

module dfg_controller # (

	parameter integer N_ADDR_WIDTH = 32,
	parameter integer N_DFG_LINES  = 10, // number of available lines in the dfg table ( max index)
	parameter integer N_PTR_WIDTH  = 8, // width of addr_ptr
	parameter integer N_DATA_LINES = 10,    // lines of dfg_data table
	parameter integer N_PTR_LINES = 6   // lines of ptr table
)(
	input rst,
	input clk,
	input clr,
	input i_srch_pulse,    // execute the another find in the dfg table
	input [N_PTR_WIDTH -1 :0] i_addr_srch,  
	output [N_ADDR_WIDTH -1 :0] o_addr_DFG,
	output [N_ADDR_WIDTH -1 :0] o_data_init,
	output [N_ADDR_WIDTH -1 :0] o_data_end,
	output error    // indicate a error
	);

// State machine to initialize counter, initialize write transactions, 
// initialize read transactions and comparison of read data with the 
// written data words.
localparam [0:0]	IDLE	 = 1'b0, // This state waits for the trigger
					SRCH_DFG = 1'b1; // This state is to genarate signal to srch the table DFG
	
reg exec_state;

// variables for indirect dfg table of pointers
wire [15: 0] data_from_table_ptr;
reg  [7 : 0] addr_table_ptr;
wire [7 : 0] ptr_table;
wire [7 : 0] ptr_offset;

iDFG_ptr DFG_ptr (  // table that contains the ptr ( 8bits) + offset (8 bits)
.a(addr_table_ptr),      // input wire [7 : 0] a
.spo(data_from_table_ptr)  // output wire [15 : 0] spo
);

// decode from
assign {ptr_table, ptr_offset } = data_from_table_ptr;

wire [7 : 0] addr_table_data;
wire [95: 0] data_from_table_data;

dfg_data dfg_addr_data (    // table that contains addr (32 bits) + data_init (32 bits) + data_end (32 bits)
.a(addr_table_data),      // input wire [7 : 0] a
.spo(data_from_table_data)  // output wire [95 : 0] spo
);  // the first line of this table contais all zero

// decode from dfg table data ( all contents are exported to out of this module
assign {o_addr_DFG, o_data_init, o_data_end} = data_from_table_data;  

reg  [7 : 0] my_ptr_end, my_ptr_table;
reg valid;
wire [7:0] res;
wire err;

subb_ptrs my_subb (     // subbtract the addr_end of addr_actual, if overflow occurr, indicate that, before are equal
.A(my_ptr_end),          // input wire [7 : 0] A
.B(my_ptr_table),          // input wire [7 : 0] B
.C_OUT(err),  // output wire C_OUT
.S(res)          // output wire [7 : 0] S
);         // it's the same like a comparison ( my_ptr_end < my_ptr_table) that indicate a error

assign error = !err || (i_addr_srch > N_PTR_LINES);
assign addr_table_data = my_ptr_table;   // if the variables not valid or if i in the search for address

always @(posedge clk)
begin
	if(!rst)
	 begin
	// reset condition                                                            
	// All the signals are assigned default values under reset condition
		my_ptr_table <= 0;
		my_ptr_end <= 0;
		addr_table_ptr <= i_addr_srch;  // save the addr to search, addr in the ptr table
		exec_state  <= IDLE;
		valid <= 1;
	 end
	else	
	 begin
		// state transition                                                          
		case (exec_state)
			IDLE:   // this state only execute one time, after reset
			begin
				my_ptr_table <= ptr_table - 1;      // prepare the value to after increment
				my_ptr_end <= ptr_table + ptr_offset - 1;   // calculate the max address
				exec_state  <= SRCH_DFG;
			end
			
			SRCH_DFG: 
			begin
                if(i_srch_pulse & !error) begin // if occur pulse and no detect any error, increment the addr of data_table
                    my_ptr_table <= my_ptr_table + 1;   // increment the address if occur a pulse
                end
                else if (!clr) begin
                    exec_state  <= IDLE;
                    addr_table_ptr <= i_addr_srch;
                end
            end   
								 
		endcase
	end
end

endmodule