`include "CNN_defines.vh"

//(* use_dsp = "yes" *)
module dat2buf
(
	input clk,
	input rst_n,
    input conv_mode,
    input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit    
    
	//from CSR
	input start,
	input [`log2_W-1:0]Win,
	input [`log2_H-1:0]Hin,
    input [(`log2_W+`log2_H-1):0]Hin_x_Win,
	input [`Max_log2Tin_minus_log2Tout:0]CH_in_res_Tin_div_Tout_minus1,		//ceil(CH_in%Tin /Tout)
	input [`log2_CH-`base_log2Tin-1:0]CH_in_div_Tin,				//ceil(CH_in/Tin)

	//to CSR
	output dma_dat_done,

	//rd response from MCIF
	input rd_resp_vld,
	output rd_resp_rdy,
	input [`MAX_DAT_DW *`Tout-1:0]rd_resp_pd,
	output rd_fifo_pop,

	//dat to BUF 
	output reg dma2buf_DAT_wr_en,
	output reg [`log2BUF_DEP-1:0]dma2buf_DAT_wr_addr,
	output reg [`base_Tin*`MAX_DAT_DW-1:0]dma2buf_DAT_wr_data,

	//row information to BUF
	output row_num_updt,
	output [`log2_H-1:0]row_num,
	output chin_num_updt,
	output [`log2_CH-1:0]chin_num
);

    wire [`log2AXI_BURST_LEN-1:0]len_cur;
    reg [`log2AXI_BURST_LEN-1:0]len_cnt;
    wire len_cnt_will_update_now=rd_resp_vld&rd_resp_rdy;
    wire len_cnt_is_max_now=(len_cnt==len_cur);
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        len_cnt<=`log2AXI_BURST_LEN'd0;
    else
        if(len_cnt_will_update_now)
        begin
            if(len_cnt_is_max_now)
                len_cnt<=`log2AXI_BURST_LEN'd0;
            else
                len_cnt<=len_cnt+1;
        end
    
    reg [`MAX_DAT_DW/2-1:0]fill_max_dw_times;
    always @(*)
    begin
        case(Tin_factor)// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit    
            4'b0001:fill_max_dw_times<=1-1;
            4'b0010:fill_max_dw_times<=2-1;
            4'b0100:fill_max_dw_times<=4-1;
            default:fill_max_dw_times<=8-1;
        endcase
    end
    
    wire [`Max_log2Tin_minus_log2Tout:0]Tin_div_Tout;
    reg [`Max_log2Tin_minus_log2Tout:0]kk;    
    reg [`MAX_DAT_DW/2-1:0]dw_times;//if data is 2 bit, it need MAX_DW/2= 4x times; if data is 1 bit, it need 8x times
    wire dw_times_will_update_now=len_cnt_will_update_now&len_cnt_is_max_now;
    wire dw_times_is_max_now=(dw_times==fill_max_dw_times | (kk==Tin_div_Tout));
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        dw_times<=0;
    else
        if(dw_times_will_update_now)
        begin
            if(dw_times_is_max_now)
                dw_times<=0;
            else
                dw_times<=dw_times+1;
        end
    
    
    wire kk_will_update_now=len_cnt_will_update_now&len_cnt_is_max_now;
    wire kk_is_max_now=(kk==Tin_div_Tout);
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
    
    reg [`log2_W-`log2AXI_BURST_LEN-1:0]k;
    reg [`log2_W-1:0] k_bias;
    wire k_will_update_now=kk_will_update_now&kk_is_max_now;
    wire k_is_max_now=(k==((Win-1)>>`log2AXI_BURST_LEN));
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
    begin
        k<=0;
        k_bias<=0;
    end
    else
    begin
        if(k_will_update_now)
        begin
            if(k_is_max_now)
            begin
                k<=0;
                k_bias<=0;
            end
            else
            begin
                k<=k+1;
                k_bias<=k_bias+`AXI_BURST_LEN;
            end
        end
    end
    
    reg [`log2_CH-1:0]chin;
    reg [`log2_CH+`log2_W+`log2_H-1:0]chin_bias;
    wire chin_will_update_now=k_will_update_now&k_is_max_now;
    wire chin_is_max_now=(chin==CH_in_div_Tin-1);
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
    begin
        chin<=0;
        chin_bias<=0;
    end
    else
    begin
        if(chin_will_update_now)
        begin
            if(chin_is_max_now)
            begin
                chin<=0;
                chin_bias<=0;
            end
            else
            begin
                chin<=chin+1;
                chin_bias<=chin_bias+Hin_x_Win;
            end
        end
    end
    
    reg [`log2_H-1:0]hin;
    reg [`log2_H+`log2_W-1:0]hin_bias;
    wire hin_will_update_now=chin_will_update_now&chin_is_max_now;
    wire hin_is_max_now=(hin==Hin-1);
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
    begin
        hin<=0;
        hin_bias<=0;
    end
    else
    begin
        if(hin_will_update_now)
        begin
            if(hin_is_max_now)
            begin
                hin<=0;
                hin_bias<=0;
            end
            else
            begin
                hin<=hin+1;
                hin_bias<=hin_bias+Win;
            end
        end
    end
        
    assign len_cur=(k_is_max_now)?(Win[`log2AXI_BURST_LEN-1:0]-1):(`AXI_BURST_LEN-1);
    assign Tin_div_Tout=chin_is_max_now?(CH_in_res_Tin_div_Tout_minus1):(`base_Tin_div_Tout*Tin_factor-1);
    
    reg [`Max_log2Tin_minus_log2Tout:0]Tin_div_Tout_d;
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        Tin_div_Tout_d<=0;
    else
        Tin_div_Tout_d<=Tin_div_Tout;
    
    reg [`MAX_DAT_DW-1:0]mem_wr_en[`base_Tin_div_Tout-1:0];
    integer i_0; //it means how many clks it takes before filling Tin at Tout each time.  i_max= base_Tin/Tout-1
    integer i_1;//it means how many clks for filling the 8bit width. i_1='b0001 meams 8bit, need 1 clk
                                                                  // i_1='b0010 means 4bit, need 2 clk
                                                                  // i_1='b0100 means 2bit, need 4 clk
                                                                  // i_1='b1000 means 1bit, need 8 clk
    reg [1:0]right_shift_factor,left_shift_factor;
    always @(*)
    begin
        case(Tin_factor)// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit    
            4'b0001:begin right_shift_factor<=3;left_shift_factor<=0;end //8bit
            4'b0010:begin right_shift_factor<=2;left_shift_factor<=1;end //4bit
            4'b0100:begin right_shift_factor<=1;left_shift_factor<=2;end //2bit
            default:begin right_shift_factor<=0;left_shift_factor<=3;end //1bit
        endcase
    end 
                                                               
    always @(*)
    begin
        for(i_0=0;i_0<(`base_Tin_div_Tout);i_0=i_0+1)
        begin
            for(i_1=0;i_1<(`MAX_DAT_DW);i_1=i_1+1)
            begin
                mem_wr_en[i_0][i_1]=((kk>>left_shift_factor)==i_0) & (((i_1>>right_shift_factor)==dw_times)&len_cnt_will_update_now);
            end //for 8bit, i_1 always enable.
                //for 4bit, i_1=0-1 enable/disable simultaneously
                //for 2bit, i_1=0-3 enable/disable simultaneously
                //for 1bit, individually for i_1
        end
    end


    reg [`log2BUF_DEP-1:0] tp_dma2buf_wr_addr,tp_dma2buf_wr_addr_d;
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        tp_dma2buf_wr_addr<='b0;
    else
        tp_dma2buf_wr_addr<=(chin_bias+hin_bias)+(k_bias+len_cnt);   //dma2buf_DAT_wr_addr<=chin*Win*Hin+hin*Win+k*`AXI_BURST_LEN+len_cnt;
    
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        tp_dma2buf_wr_addr_d<='b0;
    else
        tp_dma2buf_wr_addr_d<=tp_dma2buf_wr_addr;   
            
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        dma2buf_DAT_wr_addr<='b0;
    else
        dma2buf_DAT_wr_addr<=tp_dma2buf_wr_addr_d;   
    
    
    //read memory logic start
    reg [`log2AXI_BURST_LEN-1:0]mem_rd_addr,mem_rd_addr_d;
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        mem_rd_addr<='b0;
    else
        mem_rd_addr<=len_cnt;   
        
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        mem_rd_addr_d<='b0;
    else
        mem_rd_addr_d<=mem_rd_addr;  
                
    reg mem_rd_en,mem_rd_en_d;
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        mem_rd_en<='b0;
    else
        mem_rd_en<=kk_is_max_now&len_cnt_will_update_now;
        
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        mem_rd_en_d<='b0;
    else
        mem_rd_en_d<=mem_rd_en;
                
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        dma2buf_DAT_wr_en<='b0;
    else
        dma2buf_DAT_wr_en<=mem_rd_en_d;
    
    
    wire [`Tout*(`MAX_DAT_DW>>3)-1:0]wdata_1bit;    
    wire [`Tout*(`MAX_DAT_DW>>2)-1:0]wdata_2bit;
    wire [`Tout*(`MAX_DAT_DW>>1)-1:0]wdata_4bit;
    wire [`Tout*`MAX_DAT_DW-1:0]wdata_8bit=rd_resp_pd;
    
    genvar i;          
    generate 
        for(i=0;i<`Tout;i=i+1)
        begin:w_4bit
            assign wdata_4bit[i*4+3:i*4]=rd_resp_pd[i*`MAX_DAT_DW+3:i*`MAX_DAT_DW];
        end
    endgenerate
    
    generate 
        for(i=0;i<`Tout;i=i+1)
        begin:w_2bit
            assign wdata_2bit[i*2+1:i*2]=rd_resp_pd[i*`MAX_DAT_DW+1:i*`MAX_DAT_DW];
        end
    endgenerate
 
    generate 
        for(i=0;i<`Tout;i=i+1)
        begin:w_1bit
            assign wdata_1bit[i*1:i*1]=rd_resp_pd[i*`MAX_DAT_DW:i*`MAX_DAT_DW];
        end
    endgenerate
               
    wire [`Tout*`MAX_DAT_DW-1:0]mem_out[`base_Tin_div_Tout-1:0];

    genvar ii;
    generate
        for(ii=0;ii<(`base_Tin_div_Tout);ii=ii+1)
        begin:tp_memory
            tp_dat_mem tp_dat_mem
            (
                .clk(clk),
                .rst_n(rst_n),
                .Tin_factor(Tin_factor),
                
                .wr_en(mem_wr_en[ii]),
                .waddr(len_cnt),
                .wdata_1bit(wdata_1bit),
                .wdata_2bit(wdata_2bit),
                .wdata_4bit(wdata_4bit),
                .wdata_8bit(wdata_8bit),
                
                .rd_en(mem_rd_en_d),
                .raddr(mem_rd_addr_d),
                .rdata(mem_out[ii])
            );
        end
    endgenerate
    
    generate
        for(ii=0;ii<`base_Tin_div_Tout;ii=ii+1)
        begin:DAT_wr_data
            always @(*)
            begin
                dma2buf_DAT_wr_data[ii*(`Tout*`MAX_DAT_DW)+:(`Tout*`MAX_DAT_DW)]=mem_out[ii];
            end 
        end
    endgenerate
    
    reg hin_will_update_now_d,hin_will_update_now_d2,hin_will_update_now_d3,hin_will_update_now_d4;
    reg [`log2_H-1:0]hin_d,hin_d2,hin_d3,hin_d4;
    
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        begin
            {hin_will_update_now_d4,hin_will_update_now_d3,hin_will_update_now_d2,hin_will_update_now_d}<='b0;
            {hin_d4,hin_d3,hin_d2,hin_d}<='b0;
        end
    else
        begin
            {hin_will_update_now_d4,hin_will_update_now_d3,hin_will_update_now_d2,hin_will_update_now_d}
                    <={hin_will_update_now_d3,hin_will_update_now_d2,hin_will_update_now_d,hin_will_update_now};
            {hin_d4,hin_d3,hin_d2,hin_d}<={hin_d3,hin_d2,hin_d,hin};
        end
    
    assign row_num_updt=hin_will_update_now_d4;
    assign row_num=hin_d4;
    
    reg chin_will_update_now_d,chin_will_update_now_d2,chin_will_update_now_d3,chin_will_update_now_d4;
    reg [`log2_CH-1:0]chin_d,chin_d2,chin_d3,chin_d4;
    
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        begin
            {chin_will_update_now_d4,chin_will_update_now_d3,chin_will_update_now_d2,chin_will_update_now_d}<='b0;
            {chin_d4,chin_d3,chin_d2,chin_d}<='b0;
        end
    else
        begin
            {chin_will_update_now_d4,chin_will_update_now_d3,chin_will_update_now_d2,chin_will_update_now_d}
                    <={chin_will_update_now_d3,chin_will_update_now_d2,chin_will_update_now_d,chin_will_update_now};
            {chin_d4,chin_d3,chin_d2,chin_d}<={chin_d3,chin_d2,chin_d,chin};
        end
    
    assign chin_num_updt=chin_will_update_now_d4;
    assign chin_num=chin_d4;
           
    reg working;
    assign dma_dat_done=hin_will_update_now&hin_is_max_now;
    
    always @(posedge clk or negedge rst_n)
    if(~rst_n)
        working<=1'b0;
    else
        if(start)
            working<=1'b1;
        else
            if(dma_dat_done)
                working<=1'b0;
    
    assign rd_resp_rdy=working;
    assign rd_fifo_pop=1'b1;


endmodule

