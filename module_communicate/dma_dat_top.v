`include "CNN_defines.vh"

module dma_dat_top
(
	input clk,
	input rst_n,
    input conv_mode,
    input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit    
    
	//from CSR
	input start,
	input Vit_conv0_mode,
	input [`log2_K-1:0]Kx,
	input [`log2_W-1:0]Win,
	input [`log2_H-1:0]Hin,
	input [(`log2_W+`log2_H-1):0]Hin_x_Win,
	input [`Max_log2Tin_minus_log2Tout:0]CH_in_res_Tin_div_Tout_minus1,		//ceil(CH_in%Tin /Tout)
	input [`log2_CH-`base_log2Tin-1:0]CH_in_div_Tin,				//ceil(CH_in/Tin)
	input [31:0]dat_base_addr,
	input [31:0]surface_stride_in,
	input [15:0]line_stride_in,

	//to CSR
	output dma_dat_done,
    
	//rd CMD to MCIF
	output rd_req_vld,
	input rd_req_rdy,
	output [`log2AXI_BURST_LEN+32+32-1:0]rd_req_pd,

	//rd response from MCIF
	input rd_resp_vld,
	output rd_resp_rdy,
	input [`MAX_DAT_DW *`Tout-1:0]rd_resp_pd,
	output rd_fifo_pop,

	//dat to BUF 
	output dma2buf_DAT_wr_en,
	output [`log2BUF_DEP-1:0]dma2buf_DAT_wr_addr,
	output [`base_Tin*`MAX_DAT_DW-1:0]dma2buf_DAT_wr_data,

	//row information to BUF
	output row_num_updt,
	output [`log2_H-1:0]row_num,
    output chin_num_updt,
    output [`log2_CH-1:0]chin_num
);

(* MAX_FANOUT=64 *)reg Vit_conv0_mode_copy;
always@(posedge clk or negedge rst_n)
if(~rst_n)
    Vit_conv0_mode_copy<=0;
else
    Vit_conv0_mode_copy<=Vit_conv0_mode;
    
    
wire Vit_conv0_start=Vit_conv0_mode?start:0;
wire normal_start=Vit_conv0_mode?0:start;

//to CSR
wire Vit_conv0_dma_dat_done,normal_dma_dat_done;
assign dma_dat_done=Vit_conv0_mode_copy?Vit_conv0_dma_dat_done:normal_dma_dat_done;

//rd CMD to MCIF
wire Vit_conv0_rd_req_vld,normal_rd_req_vld;
wire [`log2AXI_BURST_LEN+32+32-1:0]Vit_conv0_rd_req_pd,normal_rd_req_pd;
wire Vit_conv0_rd_resp_rdy,normal_rd_resp_rdy;
wire Vit_conv0_rd_fifo_pop,normal_rd_fifo_pop;

assign rd_req_vld=Vit_conv0_mode_copy?Vit_conv0_rd_req_vld:normal_rd_req_vld;
assign rd_req_pd=Vit_conv0_mode_copy?Vit_conv0_rd_req_pd:normal_rd_req_pd;
assign rd_resp_rdy=Vit_conv0_mode_copy?Vit_conv0_rd_resp_rdy:normal_rd_resp_rdy;
assign rd_fifo_pop=Vit_conv0_mode_copy?Vit_conv0_rd_fifo_pop:normal_rd_fifo_pop;

//dat to BUF 
wire Vit_conv0_dma2buf_DAT_wr_en,normal_dma2buf_DAT_wr_en;
wire [`log2BUF_DEP-1:0]Vit_conv0_dma2buf_DAT_wr_addr,normal_dma2buf_DAT_wr_addr;
wire [`base_Tin*`MAX_DAT_DW-1:0]Vit_conv0_dma2buf_DAT_wr_data,normal_dma2buf_DAT_wr_data;
assign dma2buf_DAT_wr_en=Vit_conv0_mode_copy?Vit_conv0_dma2buf_DAT_wr_en:normal_dma2buf_DAT_wr_en;
assign dma2buf_DAT_wr_addr=Vit_conv0_mode_copy?Vit_conv0_dma2buf_DAT_wr_addr:normal_dma2buf_DAT_wr_addr;
assign dma2buf_DAT_wr_data=Vit_conv0_mode_copy?Vit_conv0_dma2buf_DAT_wr_data:normal_dma2buf_DAT_wr_data;

//row information to BUF
wire Vit_conv0_row_num_updt,normal_row_num_updt;
wire [`log2_H-1:0]Vit_conv0_row_num,normal_row_num;
wire Vit_conv0_chin_num_updt,normal_chin_num_updt;
wire [`log2_CH-1:0]Vit_conv0_chin_num,normal_chin_num;
assign row_num_updt=Vit_conv0_mode_copy?Vit_conv0_row_num_updt:normal_row_num_updt;
assign row_num=Vit_conv0_mode_copy?Vit_conv0_row_num:normal_row_num;
assign chin_num_updt=Vit_conv0_mode_copy?Vit_conv0_chin_num_updt:normal_chin_num_updt;
assign chin_num=Vit_conv0_mode_copy?Vit_conv0_chin_num:normal_chin_num;
    
Vit_conv0_dma_dat dma_dat_Vit_conv0
(
	.clk(clk),
	.rst_n(rst_n),
    .conv_mode(conv_mode),
    .Tin_factor(Tin_factor), // 'b001 meams 8bit, 'b010 means 4bit, 'b100 means 2bit
    
	//from CSR
	.start(Vit_conv0_start),
	.Kx(Kx),
	.Win(Win),
	.Hin(Hin),
	.CH_in_res_Tin_div_Tout_minus1(CH_in_res_Tin_div_Tout_minus1),
	.CH_in_div_Tin(CH_in_div_Tin),				//ceil(CH_in/Tin)
	.dat_base_addr(dat_base_addr),
	.surface_stride_in(surface_stride_in),
	.line_stride_in(line_stride_in),

	//rd CMD to MCIF
	.rd_req_vld(Vit_conv0_rd_req_vld),
	.rd_req_rdy(rd_req_rdy),
	.rd_req_pd(Vit_conv0_rd_req_pd)
);

Vit_conv0_dat2buf dat2buf_Vit_conv0
(
	.clk(clk),
	.rst_n(rst_n),
    .conv_mode(conv_mode),
    .Tin_factor(Tin_factor), // 'b001 meams 8bit, 'b010 means 4bit, 'b100 means 2bit
    
	//from CSR
	.start(Vit_conv0_start),
	
    .Kx(Kx),
	.Win(Win),
	.Hin(Hin),
    .Hin_x_Win(Hin_x_Win),
	.CH_in_res_Tin_div_Tout_minus1(CH_in_res_Tin_div_Tout_minus1),
	.CH_in_div_Tin(CH_in_div_Tin),				//ceil(CH_in/Tin)

	//to CSR
	.dma_dat_done(Vit_conv0_dma_dat_done),

	//rd response from MCIF
	.rd_resp_vld(rd_resp_vld),
	.rd_resp_rdy(Vit_conv0_rd_resp_rdy),
	.rd_resp_pd(rd_resp_pd),
	.rd_fifo_pop(Vit_conv0_rd_fifo_pop),

	//dat to DMA 
	.dma2buf_DAT_wr_en(Vit_conv0_dma2buf_DAT_wr_en),
	.dma2buf_DAT_wr_addr(Vit_conv0_dma2buf_DAT_wr_addr),
	.dma2buf_DAT_wr_data(Vit_conv0_dma2buf_DAT_wr_data),

	
	//row information to BUF
	.row_num_updt(Vit_conv0_row_num_updt),
	.row_num(Vit_conv0_row_num),
	.chin_num_updt(Vit_conv0_chin_num_updt),
	.chin_num(Vit_conv0_chin_num)
);


dma_dat dma_dat
(
	.clk(clk),
	.rst_n(rst_n),
    .conv_mode(conv_mode),
    .Tin_factor(Tin_factor), // 'b001 meams 8bit, 'b010 means 4bit, 'b100 means 2bit
    
	//from CSR
	.start(normal_start),
	.Win(Win),
	.Hin(Hin),
	.CH_in_res_Tin_div_Tout_minus1(CH_in_res_Tin_div_Tout_minus1),
	.CH_in_div_Tin(CH_in_div_Tin),				//ceil(CH_in/Tin)
	.dat_base_addr(dat_base_addr),
	.surface_stride_in(surface_stride_in),
	.line_stride_in(line_stride_in),

	//rd CMD to MCIF
	.rd_req_vld(normal_rd_req_vld),
	.rd_req_rdy(rd_req_rdy),
	.rd_req_pd(normal_rd_req_pd)
);

dat2buf dat2buf
(
	.clk(clk),
	.rst_n(rst_n),
    .conv_mode(conv_mode),
    .Tin_factor(Tin_factor), // 'b001 meams 8bit, 'b010 means 4bit, 'b100 means 2bit
    
	//from CSR
	.start(normal_start),
	.Win(Win),
	.Hin(Hin),
    .Hin_x_Win(Hin_x_Win),
	.CH_in_res_Tin_div_Tout_minus1(CH_in_res_Tin_div_Tout_minus1),
	.CH_in_div_Tin(CH_in_div_Tin),				//ceil(CH_in/Tin)

	//to CSR
	.dma_dat_done(normal_dma_dat_done),

	//rd response from MCIF
	.rd_resp_vld(rd_resp_vld),
	.rd_resp_rdy(normal_rd_resp_rdy),
	.rd_resp_pd(rd_resp_pd),
	.rd_fifo_pop(normal_rd_fifo_pop),

	//dat to DMA 
	.dma2buf_DAT_wr_en(normal_dma2buf_DAT_wr_en),
	.dma2buf_DAT_wr_addr(normal_dma2buf_DAT_wr_addr),
	.dma2buf_DAT_wr_data(normal_dma2buf_DAT_wr_data),

	
	//row information to BUF
	.row_num_updt(normal_row_num_updt),
	.row_num(normal_row_num),
	.chin_num_updt(normal_chin_num_updt),
	.chin_num(normal_chin_num)
);

endmodule

