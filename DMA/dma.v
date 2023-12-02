`timescale 1ns / 1ps

module dma #
(
    parameter C_AXI_DATA_WIDTH=32,
    parameter C_M_AXI_ID_WIDTH=4
)
(
    input clk,
    input rst_n,
    //���üĴ��� ����axi_lite
    //AR channel
    input S_AXI_ARVALID,
    output S_AXI_ARREADY,
    input [5:0]S_AXI_ARADDR,
    input [2:0]S_AXI_ARPROT,
    //������
    //Rd channel
    output [C_AXI_DATA_WIDTH-1:0]S_AXI_RDATA,
    output [1:0]S_AXI_RRESP,
    output S_AXI_RVALID,
    input S_AXI_RREADY,
    //������
    //AW channel
    input S_AXI_AWVALID,
    output S_AXI_AWREADY,
    input [5:0]S_AXI_AWADDR,
    input [2:0]S_AXI_AWPROT,
    //������  �����źŶ�ͨ��S_AXI_WDATA�ʹ�
    //Wr channel
    input [C_AXI_DATA_WIDTH-1:0]S_AXI_WDATA,
    input S_AXI_WVALID,
    output S_AXI_WREADY,
    input [5:0]S_AXI_WSTRB,   
    //������
    //Wr Resp
    output [1:0]S_AXI_BRESP,
    output S_AXI_BVALID,
    input S_AXI_BREADY,
    //HP ���� ���������ã� ȥ��Ŀ�ĵ�ַ�����ݣ�Ȼ��д��дĿ�ĵ�ַ
    //AR channel
    output [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output [C_AXI_DATA_WIDTH-1 : 0] M_AXI_ARADDR,
    output [7 : 0] M_AXI_ARLEN,
    output [2 : 0] M_AXI_ARSIZE,//=clogb2((`AXI_DATA_WIDTH/8)-1);
    output [1 : 0] M_AXI_ARBURST,//=2'b01;
    output  M_AXI_ARLOCK,//=1'b0;              //��Ϊ����
    output [3 : 0] M_AXI_ARCACHE,//=4'b0010;
    output [2 : 0] M_AXI_ARPROT,//=3'h0;
    output [3 : 0] M_AXI_ARQOS,//=4'h0;
    output  M_AXI_ARVALID,
    input  M_AXI_ARREADY,
    //������������
    //Rd channel
    input [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input [C_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input [1 : 0] M_AXI_RRESP,//ignore
    input  M_AXI_RLAST,
    input  M_AXI_RVALID,
    output  M_AXI_RREADY,
    //���ݵ�д��ַͨ��
    //AW channel
    output [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output [C_AXI_DATA_WIDTH-1 : 0] M_AXI_AWADDR,
    output [7 : 0] M_AXI_AWLEN,
    output [2 : 0] M_AXI_AWSIZE,//=clogb2((`AXI_DATA_WIDTH/8)-1);
    output [1 : 0] M_AXI_AWBURST,//=2'b01;
    output  M_AXI_AWLOCK,//1'b0;
    output [3 : 0] M_AXI_AWCACHE,//=4'b0010
    output [2 : 0] M_AXI_AWPROT,//=3'h0;
    output [3 : 0] M_AXI_AWQOS,//=4'h0;
    output  M_AXI_AWVALID,
    input  M_AXI_AWREADY,
    //����ͨ����д����
    //Wr channel
    output  [C_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA, //M_AXI_WDATA = M_AXI_RDATA
    output  [C_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    output  M_AXI_WLAST,
    output  M_AXI_WVALID,
    input   M_AXI_WREADY,
    //����ͨ������Ӧ
    //Resp channel
    input [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,//ignore
    input [1 : 0] M_AXI_BRESP,//ignore
    input  M_AXI_BVALID,//Bvalid and Bread means a a write response.
    output  M_AXI_BREADY, //Bvalid and Bread means a a write response.
   // output  [7:0]out_num,
    output       start_test,
    //dat to vsc
    output  [15:0]dat_pd,
    output        dat_vld_r,
    output        wt_vld_r,
    output        cfg_vld,
    output        cmd_vld 


);

function integer clogb2 (input integer bit_depth);              
    begin                                                           
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
          bit_depth = bit_depth >> 1;                                 
    end                                                           
endfunction

assign M_AXI_AWSIZE     =   clogb2((C_AXI_DATA_WIDTH/8)-1);
//��Ϊ����
assign M_AXI_AWBURST    =   2'b01;
assign M_AXI_AWLOCK     =   1'b0;
assign M_AXI_AWCACHE    =   4'b0010;
assign M_AXI_AWPROT     =   3'h0;
assign M_AXI_AWQOS      =   4'h0;

assign M_AXI_ARSIZE     =   clogb2((C_AXI_DATA_WIDTH/8)-1);
//��Ϊ����
assign M_AXI_ARBURST    =   2'b01; 
assign M_AXI_ARLOCK     =   1'b0;
assign M_AXI_ARCACHE    =   4'b0010;
assign M_AXI_ARPROT     =   3'h0;
assign M_AXI_ARQOS      =   4'h0;

assign M_AXI_ARID       =   0;
assign M_AXI_AWID       =   0;
assign M_AXI_BREADY     =   1'b1;
//���úõ���Ϣ
wire start,done;
wire [31:0]src_addr;
wire [31:0]dst_addr;
wire [15:0]size;
//wire en_dat;
//����������ֱ��д��ȥ
//assign M_AXI_WDATA  =   M_AXI_RDATA;
//32λ��������ÿһ��byte��д
assign M_AXI_WSTRB  =   {(C_AXI_DATA_WIDTH/8){1'b1}};
//����������ֱ��д��


wire    dat_en;
wire    wt_en;
wire    cfg_en;
wire    [15:0]cfg;
//assign M_AXI_WLAST  =   M_AXI_RLAST;
//assign M_AXI_WVALID =   M_AXI_RVALID & dat_en;
//assign M_AXI_RREADY =   M_AXI_WREADY;
reg     m_axi_rready;
always@(posedge clk or rst_n)
    if(rst_n == 0)
        m_axi_rready <= 0;
    else
        begin
            if(M_AXI_RVALID & !m_axi_rready)
                m_axi_rready <= 1;
            else    
                m_axi_rready <= 0;
        end

assign   M_AXI_RREADY =  m_axi_rready;

assign   dat_vld_r = M_AXI_RREADY & M_AXI_RVALID & dat_en;
assign   wt_vld_r  = M_AXI_RREADY & M_AXI_RVALID & wt_en;
assign   cfg_vld   = M_AXI_RREADY & M_AXI_RVALID & cfg_en;

assign   dat_pd    = cfg_vld?cfg:M_AXI_RDATA[15:0];
//ʹ��axi_lite���ò���
dma_reg u_dma_reg
(
    .clk(clk),
    .rst_n(rst_n),
    //������ź�ֱ�ӽӵ�����??
    //AR channel
    .S_AXI_ARVALID(S_AXI_ARVALID),//
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    
    //Rd channel
    .S_AXI_RDATA(S_AXI_RDATA),//���Զ����׵�ַ����Ϣ
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    //д��ַͨ�� ��������4��reg
    //AW channel
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    //S_AXI_WDATA ������
    //Wr channel
    .S_AXI_WDATA(S_AXI_WDATA),//S_AXI_WDATA
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),//
    .S_AXI_WSTRB(S_AXI_WSTRB),   
    
    //Wr Resp
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    //���úõ�����
    .start(start),
    .done(done),
    //
    //����д���׵�ַ
    .src_addr(src_addr),
    .dst_addr(dst_addr),
    .size(size) ,
  //  .out_num(out_num),
    .start_test(start_test),
    .dat_en(dat_en),
    .wt_en(wt_en),
    .cfg_en(cfg_en),
    .cfg(cfg),
    .cmd_vld(cmd_vld)
);

send_rd_cmd #
(
    .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH)
)u_send_rd_cmd
(
    .clk(clk),
    .rst_n(rst_n),
    
    .start(start),
    .src_addr(src_addr),
    .size(size),//real_size - 1
    
    //AR channel
    .M_AXI_ARADDR(M_AXI_ARADDR),
    .M_AXI_ARLEN(M_AXI_ARLEN),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY)//����
);

// send_wr_cmd #
// (
//     .C_AXI_DATA_WIDTH(32)
// )u_send_wr_cmd
// (
//     .clk(clk),
//     .rst_n(rst_n),
    
//     .start(start),
//     .dst_addr(dst_addr),
//     .size(size),//real_size - 1
    
//     //AW channel
//     .M_AXI_AWADDR(M_AXI_AWADDR),
//     .M_AXI_AWLEN(M_AXI_AWLEN),
//     .M_AXI_AWVALID(M_AXI_AWVALID),
//     .M_AXI_AWREADY(M_AXI_AWREADY) //����
// );

reg [15:0]cnt;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    cnt <= 0;
else
    if(start)
        cnt <= 0;
    else
        if(M_AXI_RREADY & M_AXI_RVALID)
            cnt <= cnt + 1;

assign done = (M_AXI_RREADY & M_AXI_RVALID) & (cnt == size);
    
endmodule
