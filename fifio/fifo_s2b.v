module  fifo_s2b(
        input                   rstn,
        input [4-1: 0]          din,
        input                   din_clk,
        input                   din_en,

        output [16-1 : 0]       dout,
        input                   dout_clk,
        input                   dout_en );


   wire         fifo_empty, fifo_full, prog_full ;
   wire         rd_en_wir ;
   wire [15:0]  dout_wir ;

   //direct read once empty
   assign rd_en_wir     = fifo_empty ? 1'b0 : 1'b1 ;

   fifo  #(.AWI(5), .AWO(3), .DWI(4), .DWO(16), .PROG_DEPTH(16))
     u_buf_s2b(
        .rstn           (rstn),
        .wclk           (din_clk),
        .winc           (din_en),
        .wdata          (din),

        .rclk           (dout_clk),
        .rinc           (rd_en_wir),
        .rdata          (dout_wir),

        .wfull          (fifo_full),
        .rempty         (fifo_empty),
        .prog_full      (prog_full));

   //sync the dout and dout_en
   reg          dout_en_r ;
   always @(posedge dout_clk or negedge rstn) begin
      if (!rstn) begin
         dout_en_r       <= 1'b0 ;
      end
      else begin
         dout_en_r       <= rd_en_wir ;
      end
   end

   assign       dout    = dout_wir ;
   assign       dout_en = dout_en_r ;

endmodule
