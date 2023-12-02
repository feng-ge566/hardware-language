module  ccnt
  #(parameter W = 5 )
   (
    input              rstn ,
    input              clk ,
    input              en ,
    output [W-1:0]     count
    );

   reg [W-1:0]          count_r ;
   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         count_r        <= 'b0 ;
      end
      else if (en) begin
         count_r        <= count_r + 1'b1 ;
      end
   end
   assign count = count_r ;

endmodule
