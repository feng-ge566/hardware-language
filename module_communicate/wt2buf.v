`include "CNN_defines.vh"

//(* use_dsp = "yes" *)
module wt2buf
(
	input clk,
	input rst_n,

	//from CSR
	input start,
	input [`log2BRAM_NUM-1:0]dat_buf_num,
    input [31:0]wt_num_div_Tin,
	//to CSR
	output done,

	//rd response from MCIF
	input rd_resp_vld,
	output rd_resp_rdy,
	input [`MAX_WT_DW *`Tout-1:0]rd_resp_pd,
	output rd_fifo_pop,

	//wt to BUF
	output reg dma2buf_WT_wr_en,
	output [`log2BUF_DEP-1:0]dma2buf_WT_wr_addr,
	output [`base_Tin*`MAX_WT_DW-1:0]dma2buf_WT_wr_data,

	//wt information to BUF
	output wt_addr_updt,
	output reg [`log2BUF_DEP-1:0]wt_addr_dma
);


reg [`Max_log2Tin_minus_log2Tout:0]kk;
wire kk_is_max_now=(kk==(`base_Tin/`Tout-1));
wire kk_will_update_now=rd_resp_vld&rd_resp_rdy;

always @(posedge clk or negedge rst_n)
if(~rst_n)
    kk<=0;
else
    if(kk_will_update_now)
    begin
        if(kk_is_max_now)
            kk<=0;
        else
            kk<=kk+1;
    end
    
reg [`base_Tin*`MAX_WT_DW-1:0]dff_line;
always @(posedge clk)
if(kk_will_update_now)
    dff_line[`Tout*`MAX_WT_DW*kk+:`Tout*`MAX_WT_DW]<=rd_resp_pd;


reg [32-1:0]c;
wire c_is_max_now=( c == (wt_num_div_Tin-1) );
wire c_will_update_now=kk_will_update_now&kk_is_max_now;
always @(posedge clk or negedge rst_n)
if(~rst_n)
	c<=0;
else
	if(c_will_update_now)
	begin
		if(c_is_max_now)
			c<=0;
		else
			c<=c+1;
	end

reg working;
assign done=c_will_update_now&c_is_max_now;
always @(posedge clk or negedge rst_n)
if(~rst_n)
	working<=1'b0;
else
	if(start)
		working<=1'b1;
	else
		if(done)
			working<=1'b0;

always @(posedge clk or negedge rst_n)
if(~rst_n)
	dma2buf_WT_wr_en<=1'b0;
else
	dma2buf_WT_wr_en<=c_will_update_now;

always @(posedge clk or negedge rst_n)
if(~rst_n)
	wt_addr_dma<=0;
else
	wt_addr_dma<=c;

assign dma2buf_WT_wr_data=dff_line;
assign dma2buf_WT_wr_addr=wt_addr_dma+{dat_buf_num,{`log2BRAM_DEPTH{1'b0}}};

assign rd_resp_rdy=working;
assign rd_fifo_pop=1'b1;

assign wt_addr_updt=dma2buf_WT_wr_en;

endmodule

