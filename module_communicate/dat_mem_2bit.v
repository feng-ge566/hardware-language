`include "CNN_defines.vh"

module dat_mem_1bit
(
	input clk,
    input rst_n,
    
	input wr_en,
	input [`log2AXI_BURST_LEN-1:0]waddr,
	input [`Tout-1:0]wdata,
	
	input rd_en,
	input [`log2AXI_BURST_LEN-1:0]raddr,
	output reg [`Tout-1:0]rdata
);

reg [`Tout-1:0]mem[`AXI_BURST_LEN-1:0];
always @(posedge clk)
if(wr_en)
    mem[waddr]<=wdata;

always @(posedge clk)
if(rd_en)
    rdata<=mem[raddr];
        
endmodule


//module dat_mem_2bit
//(
//	input clk,
//    input rst_n,
    
//	input wr_en,
//	input [`log2AXI_BURST_LEN-1:0]waddr,
//	input [`Tout*2-1:0]wdata,
	
//	input rd_en,
//	input [`log2AXI_BURST_LEN-1:0]raddr,
//	output reg [`Tout*2-1:0]rdata
//);

//reg [`Tout*2-1:0]mem[`AXI_BURST_LEN-1:0];
//always @(posedge clk)
//if(wr_en)
//    mem[waddr]<=wdata;

//always @(posedge clk or negedge rst_n)
//if(!rst_n)
//    rdata<='b0;
//else
//    if(rd_en)
//	    rdata<=mem[raddr];
        
//endmodule

