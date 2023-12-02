`include "CNN_defines.vh"

module dma_wt_top
(
	input clk,
	input rst_n,
    
	//from CSR
	input start,
	input [`log2BRAM_NUM-1:0]dat_buf_num,
	input [31:0]wt_num_div_Tout,					//weight size in bytes
	input [31:0]wt_base_addr,
    input [31:0]wt_num_div_Tin,
    
	//to CSR
	output done,

	//rd CMD to MCIF
	output rd_req_vld,
	input rd_req_rdy,
	output [`log2AXI_BURST_LEN+32+32-1:0]rd_req_pd,

	//rd response from MCIF
	input rd_resp_vld,
	output rd_resp_rdy,
	input [`MAX_WT_DW *`Tout-1:0]rd_resp_pd,
	output rd_fifo_pop,

	//wt to BUF
	output dma2buf_WT_wr_en,
	output [`log2BUF_DEP-1:0]dma2buf_WT_wr_addr,
	output [`base_Tin*`MAX_WT_DW-1:0]dma2buf_WT_wr_data,

	//wt information to BUF
	output wt_addr_updt,
	output [`log2BUF_DEP-1:0]wt_addr_dma
);

dma_wt dma_wt
(
	.clk(clk),
	.rst_n(rst_n),

	//from CSR
	.start(start),
	.wt_num_div_Tout(wt_num_div_Tout),					//weight size in bytes
	.wt_base_addr(wt_base_addr),
    
	//rd CMD to MCIF
	.rd_req_vld(rd_req_vld),
	.rd_req_rdy(rd_req_rdy),
	.rd_req_pd(rd_req_pd)
);

wt2buf wt2buf
(
	.clk(clk),
	.rst_n(rst_n),

	//from CSR
	.start(start),
	.dat_buf_num(dat_buf_num),
    .wt_num_div_Tin(wt_num_div_Tin),
	//to CSR
	.done(done),

	//rd response from MCIF
	.rd_resp_vld(rd_resp_vld),
	.rd_resp_rdy(rd_resp_rdy),
	.rd_resp_pd(rd_resp_pd),
	.rd_fifo_pop(rd_fifo_pop),

	//wt to BUF
	.dma2buf_WT_wr_en(dma2buf_WT_wr_en),
	.dma2buf_WT_wr_addr(dma2buf_WT_wr_addr),
	.dma2buf_WT_wr_data(dma2buf_WT_wr_data),

	//wt information to BUF
	.wt_addr_updt(wt_addr_updt),
	.wt_addr_dma(wt_addr_dma)
);

endmodule
