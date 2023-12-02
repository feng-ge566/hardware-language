`timescale 1ns / 1ps
//������ģ�飬�յ��׵�ַ�ͳ�����Ϣ���гɶ�ݣ������ͳ���ַ��ÿ��ͻ���ĳ��ȣ�����Ҫ���ֶ��������ݣ�ֱ���͵���д�˿�
module send_rd_cmd #
(
    parameter C_AXI_DATA_WIDTH=32
)
(
    input clk,
    input rst_n,
    //�����úõļĴ�����
    input start,
    input [C_AXI_DATA_WIDTH-1:0]src_addr,   //�����׵�ַ
    input [15:0]size,//real_size - 1  ��Ҫ��������ݵĳ���
    //���ĵ�ַ������Ҫ�������ݣ�����ֱ�ӴӶ��˿��͵���д�˿�
    
    //AR channel
    //�зֺõ�ÿ���Ļ���ַ�ͳ��ȣ�һ�������256���������ʣ�ĳ���
    output [C_AXI_DATA_WIDTH-1 : 0] M_AXI_ARADDR,
    output [7 : 0] M_AXI_ARLEN,  //���һ������ʣ�ĳ���
    output  M_AXI_ARVALID,
    input  M_AXI_ARREADY
);
//
reg state;
reg [15:0]ptr;  //��ʾ���ٸ����ݣ�ͻ������һ�����256����һ��������32λ����  ����������ʲôʱ��last_burst����
reg arvalid;
reg [31:0]raddr;
//���ܳ����з�Ϊ��ݣ�һ�����Ϊ���ͻ�����ȣ����һ��Ϊʣ�µ�
//���һ��ʱ����last_burst
wire last_burst = (ptr[15:8] == size[15:8]);
assign M_AXI_ARLEN = last_burst?size[7:0]:8'hff; //ǰ��������256���������ʣ�ĳ���

assign M_AXI_ARVALID = arvalid;
assign M_AXI_ARADDR = raddr;
//
always @(posedge clk or negedge rst_n)
if(~rst_n)
begin
    ptr<=0;
    state<=0;
    arvalid<=0;
    raddr<=0;
end
else
    case(state)
        0:
            if(start)
            begin
                state <= 1;
                arvalid <= 1;
                raddr <= src_addr;
            end 
        1:
            if(M_AXI_ARVALID & M_AXI_ARREADY)
            begin
                if(last_burst)
                     begin
                         arvalid<=0;
                         raddr<=0;
                         ptr<=0;
                         state<=0;
                     end
                else
                     begin
                         raddr <= raddr+(C_AXI_DATA_WIDTH/8)*256;  //��byteΪ��λ
                         ptr <= ptr+256; //��һ������Ϊ��λ��������32bit,�����128bit
                     end
            end
    endcase

endmodule
