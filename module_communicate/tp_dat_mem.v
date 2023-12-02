`include "CNN_defines.vh"

module tp_dat_mem
(
	input clk,
	input rst_n,
    input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit 
    
	input [`MAX_DAT_DW-1:0]wr_en,
	input [`log2AXI_BURST_LEN-1:0]waddr,
	input [`Tout*(`MAX_DAT_DW>>3)-1:0]wdata_1bit,
	input [`Tout*(`MAX_DAT_DW>>2)-1:0]wdata_2bit,
    input [`Tout*(`MAX_DAT_DW>>1)-1:0]wdata_4bit,
	input [`Tout*`MAX_DAT_DW-1:0]wdata_8bit,
		
	input rd_en,
	input [`log2AXI_BURST_LEN-1:0]raddr,
	output [`Tout*`MAX_DAT_DW-1:0]rdata
);
reg [`MAX_DAT_DW-1:0]wr_en_d;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    wr_en_d<='d0;
else
    wr_en_d<=wr_en;
    
reg [`log2AXI_BURST_LEN-1:0]waddr_d;
always @(posedge clk)
    waddr_d<=waddr;
    
reg [`Tout*`MAX_DAT_DW-1:0]shift_wdata_1bit;
reg [`Tout*`MAX_DAT_DW-1:0]shift_wdata_2bit;
reg [`Tout*`MAX_DAT_DW-1:0]shift_wdata_4bit;
reg [`Tout*`MAX_DAT_DW-1:0]shift_wdata_8bit;
reg [`Tout*`MAX_DAT_DW-1:0]vaild_wdata;

always @(posedge clk)
begin
    shift_wdata_8bit<=wdata_8bit;
end

always @(posedge clk)
begin
    case(wr_en)
        8'b00001111: shift_wdata_4bit<={{(`Tout*`MAX_DAT_DW/2){1'b0}},wdata_4bit};
        default: shift_wdata_4bit<={wdata_4bit,{(`Tout*`MAX_DAT_DW/2){1'b0}}};
    endcase
end

always @(posedge clk)
begin
    case(wr_en)
        8'b0000_0011: shift_wdata_2bit<={{(`Tout*`MAX_DAT_DW*3/4){1'b0}},wdata_2bit};
        8'b0000_1100: shift_wdata_2bit<={{(`Tout*`MAX_DAT_DW*2/4){1'b0}},wdata_2bit,{(`Tout*`MAX_DAT_DW/4){1'b0}}};
        8'b0011_0000: shift_wdata_2bit<={{(`Tout*`MAX_DAT_DW*1/4){1'b0}},wdata_2bit,{(`Tout*`MAX_DAT_DW*2/4){1'b0}}};
        default: shift_wdata_2bit<={wdata_2bit,{(`Tout*`MAX_DAT_DW*3/4){1'b0}}};
    endcase
end

always @(posedge clk)
begin
    case(wr_en)
        8'b0000_0001: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*7/8){1'b0}},wdata_1bit};
        8'b0000_0010: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*6/8){1'b0}},wdata_1bit,{(`Tout*`MAX_DAT_DW*1/8){1'b0}}};
        8'b0000_0100: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*5/8){1'b0}},wdata_1bit,{(`Tout*`MAX_DAT_DW*2/8){1'b0}}};
        8'b0000_1000: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*4/8){1'b0}},wdata_1bit,{(`Tout*`MAX_DAT_DW*3/8){1'b0}}};
        8'b0001_0000: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*3/8){1'b0}},wdata_1bit,{(`Tout*`MAX_DAT_DW*4/8){1'b0}}};
        8'b0010_0000: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*2/8){1'b0}},wdata_1bit,{(`Tout*`MAX_DAT_DW*5/8){1'b0}}};
        8'b0100_0000: shift_wdata_1bit<={{(`Tout*`MAX_DAT_DW*1/8){1'b0}},wdata_1bit,{(`Tout*`MAX_DAT_DW*6/8){1'b0}}};
        default: shift_wdata_1bit<={wdata_1bit,{(`Tout*`MAX_DAT_DW*7/8){1'b0}}};
    endcase
end
    
/////////////////////
always@(*)
begin
    case(Tin_factor)
        4'b0001: vaild_wdata<=shift_wdata_8bit;
        4'b0010: vaild_wdata<=shift_wdata_4bit;
        4'b0100: vaild_wdata<=shift_wdata_2bit;
        default: vaild_wdata<=shift_wdata_1bit;
    endcase
end

wire [`Tout-1:0]tp_rdata[`MAX_DAT_DW-1:0];

genvar i;
generate
    for(i=0;i<(`MAX_DAT_DW);i=i+1)
    begin:dat_mem_1b
        wire [`Tout-1:0]tp_wdata=vaild_wdata[i*`Tout+:`Tout];
        dat_mem_1bit dat_mem_1bit
        (
            .clk(clk),
            .rst_n(rst_n),
            
            .wr_en(wr_en_d[i]),
            .waddr(waddr_d),
            .wdata(tp_wdata),

            .rd_en(rd_en),
            .raddr(raddr),
            .rdata(tp_rdata[i])
        );
        assign rdata[i*(`Tout)+:(`Tout)]=tp_rdata[i];
    end
endgenerate


endmodule

