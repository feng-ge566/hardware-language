`include "CNN_defines.vh"

module CONV_DMA
(
	input clk,
	input rst_n,

	//from CSR
	input dma_DAT_start,
	input dma_WT_start,
	input conv_mode,
	input Vit_conv0_mode,
	input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit    
    
    input [`log2_K-1:0]Kx,
	input [`log2_W-1:0]Win,
	input [`log2_H-1:0]Hin,
	input [(`log2_W+`log2_H-1):0]Hin_x_Win,
	input [`log2_CH-`log2Tout-1:0]CH_in_div_Tout,			//ceil(CH_in/Tout)
	input [`log2_CH-`base_log2Tin-1:0]CH_in_div_Tin,				//ceil(CH_in/Tin)
	input [`Max_log2Tin_minus_log2Tout:0]CH_in_res_Tin_div_Tout_minus1,
	input [31:0]dat_base_addr,
	input [31:0]surface_stride_in,
	input [15:0]line_stride_in,
	input [`log2BRAM_NUM-1:0]dat_buf_num,
	input [31:0]wt_num_div_Tout,					//weight size in bytes
	input [31:0]wt_base_addr,
	input dma_dat_reuse,
	input dma_wt_reuse,

    input [31:0]wt_num_div_Tin,
	//to CSR
	output dma_dat_done,
	output dma_wt_done,
    
	//rd CMD to MCIF (dat)
	output dma2mcif_dat_rd_req_vld,
	input dma2mcif_dat_rd_req_rdy,
	output [`log2AXI_BURST_LEN+32+32-1:0]dma2mcif_dat_rd_req_pd,

	//rd response from MCIF (dat)
	input mcif2dma_dat_rd_resp_vld,
	output mcif2dma_dat_rd_resp_rdy,
	input [`MAX_DAT_DW *`Tout-1:0]mcif2dma_dat_rd_resp_pd,
	output dma_dat_rd_fifo_pop,

	//rd CMD to MCIF (wt)
	output dma2mcif_wt_rd_req_vld,
	input dma2mcif_wt_rd_req_rdy,
	output [`log2AXI_BURST_LEN+32+32-1:0]dma2mcif_wt_rd_req_pd,

	//rd response from MCIF (wt)
	input mcif2dma_wt_rd_resp_vld,
	output mcif2dma_wt_rd_resp_rdy,
	input [`MAX_WT_DW *`Tout-1:0]mcif2dma_wt_rd_resp_pd,
	output dma_wt_rd_fifo_pop,

	//dat to BUF 
	output dma2buf_DAT_wr_en,
	output [`log2BUF_DEP-1:0]dma2buf_DAT_wr_addr,
	output [`base_Tin*`MAX_DAT_DW-1:0]dma2buf_DAT_wr_data,

	//row information to BUF
	output row_num_updt,
	output [`log2_H-1:0]row_num,
    output chin_num_updt,
    output [`log2_CH-1:0]chin_num,
    
	//wt to BUF
	output dma2buf_WT_wr_en,
	output [`log2BUF_DEP-1:0]dma2buf_WT_wr_addr,
	output [`base_Tin*`MAX_WT_DW-1:0]dma2buf_WT_wr_data,

	//wt information to BUF
	output wt_addr_updt,
	output [`log2BUF_DEP-1:0]wt_addr_dma
);

dma_dat_top dma_dat_top
(
	.clk(clk),
	.rst_n(rst_n),
    .conv_mode(conv_mode),
    .Tin_factor(Tin_factor), // 'b001 meams 8bit, 'b010 means 4bit, 'b100 means 2bit
	.Vit_conv0_mode(Vit_conv0_mode),
	.Kx(Kx),
	
	//from CSR
	.start(dma_DAT_start&(~dma_dat_reuse)),
	.Win(Win),
	.Hin(Hin),
	.Hin_x_Win(Hin_x_Win),
	.CH_in_div_Tin(CH_in_div_Tin),				//ceil(CH_in/Tin)
	.CH_in_res_Tin_div_Tout_minus1(CH_in_res_Tin_div_Tout_minus1),
	.dat_base_addr(dat_base_addr),
	.surface_stride_in(surface_stride_in),
	.line_stride_in(line_stride_in),

	//to CSR
	.dma_dat_done(dma_dat_done),
    
	//rd CMD to MCIF
	.rd_req_vld(dma2mcif_dat_rd_req_vld),
	.rd_req_rdy(dma2mcif_dat_rd_req_rdy),
	.rd_req_pd(dma2mcif_dat_rd_req_pd),

	//rd response from MCIF
	.rd_resp_vld(mcif2dma_dat_rd_resp_vld),
	.rd_resp_rdy(mcif2dma_dat_rd_resp_rdy),
	.rd_resp_pd(mcif2dma_dat_rd_resp_pd),
	.rd_fifo_pop(dma_dat_rd_fifo_pop),

	//dat to BUF 
	.dma2buf_DAT_wr_en(dma2buf_DAT_wr_en),
	.dma2buf_DAT_wr_addr(dma2buf_DAT_wr_addr),
	.dma2buf_DAT_wr_data(dma2buf_DAT_wr_data),

	//row information to BUF
	.row_num_updt(row_num_updt),
	.row_num(row_num),
    .chin_num_updt(chin_num_updt),
    .chin_num(chin_num)
);

dma_wt_top dma_wt_top
(
	.clk(clk),
	.rst_n(rst_n),
    
	//from CSR
	.start(dma_WT_start&(~dma_wt_reuse)),
	.dat_buf_num(dat_buf_num),
	.wt_num_div_Tout(wt_num_div_Tout),					//weight size in bytes
	.wt_base_addr(wt_base_addr),
    .wt_num_div_Tin(wt_num_div_Tin),
	//to CSR
	.done(dma_wt_done),

	//rd CMD to MCIF
	.rd_req_vld(dma2mcif_wt_rd_req_vld),
	.rd_req_rdy(dma2mcif_wt_rd_req_rdy),
	.rd_req_pd(dma2mcif_wt_rd_req_pd),

	//rd response from MCIF
	.rd_resp_vld(mcif2dma_wt_rd_resp_vld),
	.rd_resp_rdy(mcif2dma_wt_rd_resp_rdy),
	.rd_resp_pd(mcif2dma_wt_rd_resp_pd),
	.rd_fifo_pop(dma_wt_rd_fifo_pop),

	//wt to BUF
	.dma2buf_WT_wr_en(dma2buf_WT_wr_en),
	.dma2buf_WT_wr_addr(dma2buf_WT_wr_addr),
	.dma2buf_WT_wr_data(dma2buf_WT_wr_data),

	//wt information to BUF
	.wt_addr_updt(wt_addr_updt),
	.wt_addr_dma(wt_addr_dma)
);

endmodule

