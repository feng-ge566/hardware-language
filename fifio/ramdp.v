module  ramdp
    #(  parameter       AWI     = 5 ,
        parameter       AWO     = 7 ,
        parameter       DWI     = 64 ,
        parameter       DWO     = 16
        )
    (
        input                   CLK_WR ,
        input                   WR_EN ,
        input [AWI-1:0]         ADDR_WR ,
        input [DWI-1:0]         D ,
        input                   CLK_RD ,
        input                   RD_EN ,
        input [AWO-1:0]         ADDR_RD ,
        output reg [DWO-1:0]    Q
     );

   parameter       EXTENT       = DWO/DWI ;
   parameter       EXTENT_BIT   = AWI-AWO > 0 ? AWI-AWO : 'b1 ;
   parameter       SHRINK       = DWI/DWO ;
   parameter       SHRINK_BIT   = AWO-AWI > 0 ? AWO-AWI : 'b1;

   genvar i ;
   generate
      //data expanding: output width > input width
      if (DWO >= DWI) begin
         //wr 1 data every clock
         reg [DWI-1:0]         mem [(1<<AWI)-1 : 0] ;
         always @(posedge CLK_WR) begin
            if (WR_EN) begin
               mem[ADDR_WR]  <= D ;
            end
         end

         //rd 4 data every clock
         for (i=0; i<EXTENT; i=i+1) begin
            always @(posedge CLK_RD) begin
               if (RD_EN) begin
                  Q[(i+1)*DWI-1: i*DWI]  <= mem[(ADDR_RD*EXTENT) + i ] ;
               end
            end
         end
      end


      //=================================================
      //data shrinkign: output width < input width
      else begin
         //wr 4 data every clock
         reg [DWO-1:0]         mem [(1<<AWO)-1 : 0] ;
         for (i=0; i<SHRINK; i=i+1) begin
            always @(posedge CLK_WR) begin
               if (WR_EN) begin
                  mem[(ADDR_WR*SHRINK)+i]  <= D[(i+1)*DWO -1: i*DWO] ;
               end
            end
         end

         //rd 1 data every clock
         always @(posedge CLK_RD) begin
            if (RD_EN) begin
                Q <= mem[ADDR_RD] ;
            end
         end
      end
   endgenerate

endmodule
