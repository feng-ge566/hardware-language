`include "CNN_defines.vh"

//(* use_dsp = "yes" *)
module dma_wt
(
	input clk,
	input rst_n,

	//from CSR
	input start,
	input [31:0]wt_num_div_Tout,					//weight size in bytes
	input [31:0]wt_base_addr,

	//rd CMD to MCIF
	output rd_req_vld,
	input rd_req_rdy,
	output [`log2AXI_BURST_LEN+32+32-1:0]rd_req_pd
);

//wire [32-1-`log2Tout-(`MAX_log2WT_DW-3):0]wt_num_div_Tout=wt_size_in_bytes[31:(`MAX_log2WT_DW-3)+`log2Tout];

reg [32-1-`log2Tout-`log2AXI_BURST_LEN-(`MAX_log2WT_DW-3):0]k;
wire k_is_max_now=( k == ((wt_num_div_Tout-1)>>`log2AXI_BURST_LEN) );
wire k_will_update_now=rd_req_vld&rd_req_rdy;
always @(posedge clk or negedge rst_n)
if(~rst_n)
	k<=0;
else
	if(k_will_update_now)
	begin
		if(k_is_max_now)
			k<=0;
		else
			k<=k+1;
	end
        
        
reg working;
wire done=k_will_update_now&k_is_max_now;
always @(posedge clk or negedge rst_n)
if(~rst_n)
	working<=1'b0;
else
	if(start)
		working<=1'b1;
	else
		if(done)
			working<=1'b0;

assign rd_req_vld=working;
wire [31:0]cmd_addr = (k<<(`MAX_log2WT_DW-3+`log2Tout+`log2AXI_BURST_LEN));
wire [`log2AXI_BURST_LEN-1:0]cmd_len=k_is_max_now?(wt_num_div_Tout[`log2AXI_BURST_LEN-1:0]-1):(`AXI_BURST_LEN-1);
assign rd_req_pd={cmd_len,wt_base_addr,cmd_addr};

endmodule
