`timescale 1ns / 1ps

module send_wr_cmd #
(
    parameter C_AXI_DATA_WIDTH=32
)
(
    input clk,
    input rst_n,
    
    input start,
    input [C_AXI_DATA_WIDTH-1:0]dst_addr,//д���׵�ַ
    input [15:0]size,//real_size - 1
    
    //AR channel
    output [32-1 : 0] M_AXI_AWADDR,
    output [7    : 0] M_AXI_AWLEN,
    output  M_AXI_AWVALID,
    input  M_AXI_AWREADY
);

reg state;
reg [15:0]ptr;
reg awvalid;
reg [31:0]waddr;

wire last_burst = (ptr[15:8] == size[15:8]);
assign M_AXI_AWLEN = last_burst?size[7:0]:8'hff;

assign M_AXI_AWVALID = awvalid;
assign M_AXI_AWADDR = waddr;

always @(posedge clk or negedge rst_n)
if(~rst_n)
begin
    ptr<=0;
    state<=0;
    awvalid<=0;
    waddr<=0;
end
else
    case(state)
        0://idle
            if(start)
            begin
                state <= 1;
                awvalid <= 1;
                waddr <= dst_addr;
            end
        1:
            if(M_AXI_AWVALID & M_AXI_AWREADY)//send a wr cmd
            begin
                if(last_burst)
                begin
                    awvalid<=0;
                    waddr<=0;
                    ptr<=0;
                    state<=0;
                end
                else
                begin
                    waddr <= waddr + (C_AXI_DATA_WIDTH/8)*256;//1K, 2k
                    ptr <= ptr + 256;
                end
            end
    endcase

endmodule
