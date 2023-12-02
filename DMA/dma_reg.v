`timescale 1ns / 1ps
//���ò��� ʹ����axi_lite�����ö�д���׵�ַ����ʼ�ͽ����źţ�����
module dma_reg
(
    input clk,
    input rst_n,
     //����ַͨ��
     //AR channel
    input S_AXI_ARVALID,
    output S_AXI_ARREADY,
    input [5:0]S_AXI_ARADDR,
    input [2:0]S_AXI_ARPROT,
    //������ͨ�� ��4���Ĵ�����ֵ ����ֱ���ͳ����׵�ַ�Ȳ��໥Ӱ�죬����
    //Rd channel
    output [32-1:0]S_AXI_RDATA,//���Զ�������źţ������Ƿ�ͣ�? ��reg0��
    output [1:0]S_AXI_RRESP,
    output S_AXI_RVALID,
    input S_AXI_RREADY,
    //������ֻд���ĸ��Ĵ��������Ե�ַֻ��4λ��
    //AW channel
    input S_AXI_AWVALID,
    output S_AXI_AWREADY,
    input [5:0]S_AXI_AWADDR,
    input [2:0]S_AXI_AWPROT,

    //Wr channel
    //S_AXI_WDATA�� �׵�ַ ���� �� ��ʼ�����ź� ͨ���� ����
    input [32-1:0]S_AXI_WDATA,
    input S_AXI_WVALID,
    output S_AXI_WREADY,
    input [5:0]S_AXI_WSTRB,   
    
    //Wr Resp
    output [1:0]S_AXI_BRESP,
    output S_AXI_BVALID,
    input S_AXI_BREADY,
    //S_AXI_WDATA�� �׵�ַ ���� �� ��ʼ�����ź� ͨ���� ����
    //���úú��ͳ�����дģ��
    output start,//reg0
    input done,//reg0  //���룬ֹͣ�ź�  
    output reg [31:0]src_addr,//reg1 ���׵�ַ
    output reg [31:0]dst_addr,//reg2 д�׵�ַ
    output reg [15:0]size ,//reg3  DMA����ĳ��ȣ����ջ��зֳɶ�Σ�ͻ�����һ�ο���?256����һ��������32λ������������128��AXI4��
    //output reg [7:0]out_num,
    output reg      start_test,

    output  reg     dat_en,
    output  reg     wt_en,
    output  reg     cfg_en,
    output  reg     [15:0]cfg,
    output  reg     cmd_vld
);

assign S_AXI_BRESP=2'b0;
//д��Ӧͨ��
reg axi_bvalid;
assign S_AXI_BVALID=axi_bvalid;

always @(posedge clk or negedge rst_n)
    if(~rst_n)
        axi_bvalid<=1'b0;
    else
        if(S_AXI_WVALID & S_AXI_WREADY)
            axi_bvalid<=1'b1;
        else
            if(S_AXI_BREADY)
                axi_bvalid<=1'b0;

reg [3:0]addr_word_w;
wire [3:0]addr_word_w_comb;

always @(posedge clk or negedge rst_n)
    if(~rst_n)
        addr_word_w<=0;
    else
        if(S_AXI_AWVALID & S_AXI_AWREADY)
            addr_word_w <= S_AXI_AWADDR[5:2];
        
//32λ�������ݣ���4��byte����ַ0,1,2,3. ����[1:0]�Ϳ��Ա�ʾ  
//[3:2]��ʾ�ڼ����Ĵ�����addr_word_w_comb��      
assign addr_word_w_comb = (S_AXI_AWVALID & S_AXI_AWREADY)?S_AXI_AWADDR[5:2]:addr_word_w; //���µĵ�ַ��ʱ���͸��£���Ȼ�ͱ���
assign S_AXI_AWREADY=1'b1;//S_AXI_AWVALID&S_AXI_WVALID;
//��ַ�Ƿ�����w_phase�����е�ַ�����ܽ���д���ݲ���
reg w_phase;

always @(posedge clk or negedge rst_n)
    if(~rst_n)
        w_phase=1'b0;
    else
        if(S_AXI_AWVALID & S_AXI_AWREADY) //
            w_phase<=1;
        else
            if(S_AXI_WVALID & S_AXI_WREADY)  //S_AXI_WREADY=w_phase
                w_phase<=0;
                
//S_AXI_WREADY �ź����߻��? S_AXI_AWVALID��һ������
assign S_AXI_WREADY=w_phase;
//reg    en_dat;
//reg    en_wt;
always @(posedge clk or negedge rst_n)
    if(~rst_n)
        begin
            src_addr<=0;
            dst_addr<=0;
            size<=0;
            start_test<=0;
            dat_en <=0;
            wt_en  <= 0;
            cfg_en <=0;
            cfg    <=0;
            cmd_vld <=0;


        end
    else    //assign S_AXI_WREADY=w_phase; ����д���ݲ�����ȵ�ַ������һ�����ڣ�ȷ�����е��?
        if(S_AXI_WVALID & S_AXI_WREADY)
            case(addr_word_w_comb)
                4'd1:begin src_addr <= S_AXI_WDATA;end  //S_AXI_WDATAΪ����
                4'd2:begin dst_addr <= S_AXI_WDATA;end
                4'd3:begin size <= S_AXI_WDATA[15:0];end
                4'd4:begin start_test <= S_AXI_WDATA[0];end //16
                4'd5:begin dat_en <= S_AXI_WDATA[0] ; //20
                           wt_en  <= 0;
                           cfg_en  <= 0;
                        end
                
                4'd6:begin
                            wt_en   <= S_AXI_WDATA[0]; //24
                            dat_en  <= 0;
                            cfg_en  <= 0;
                end
                4'd7:begin
                            cfg_en  <= S_AXI_WDATA[0];  //28
                            dat_en  <= 0;
                            wt_en   <= 0;
                end
                4'd8:begin
                            cfg     <= S_AXI_WDATA[15:0];
                end
                4'd9:begin
                            cmd_vld <= S_AXI_WDATA[0];
                end
            endcase
        
//ARͨ��    
assign S_AXI_ARREADY=1'b1;

assign S_AXI_RRESP=2'b0;
//������
reg [32-1:0]rdata;
assign S_AXI_RDATA = rdata; //���úõ��׵�ַ����Ϣֱ���ͳ���Ҳ���Զ���
reg rvalid;
assign S_AXI_RVALID = rvalid;

reg done_r;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    done_r<=0;
else
    if(start)
        done_r<=0;
    else
        if(done) //done�ź��������ź�
            done_r<=1;
//��ͨ��                        
always @(posedge clk or negedge rst_n)
if(~rst_n)
    begin rvalid<=1'b0;rdata<=32'b0;end
else
    if(S_AXI_ARVALID & S_AXI_ARREADY)
    begin
        rvalid<=1'b1;
        case(S_AXI_ARADDR[5:2])  //done_r���ڵڶ�λ��Ϊ�˺�start�ܿ���start���˵�һλ
            4'd0: rdata <= {30'b0,done_r,1'b0};
            4'd1: rdata <= src_addr;
            4'd2: rdata <= dst_addr;
            4'd3: rdata <= {16'b0,size};
        endcase
    end
    else
        if(S_AXI_RVALID & S_AXI_RREADY)
            rvalid<=1'b0;
//����start�ź�  startΪ����ź�?   
                                     //addr_word_w_comb==0 ��ʾ�Ĵ���reg0
assign start = S_AXI_WVALID & S_AXI_WREADY & (addr_word_w_comb == 0) & S_AXI_WDATA[0];
                
endmodule
