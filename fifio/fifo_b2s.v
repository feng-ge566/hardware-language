module  fifo_b2s(
        input                   rstn,
        input [16-1: 0]         din,
        input                   din_clk,
        input                   din_en,

        output [4-1 : 0]        dout,
        input                   dout_clk,
        input                   dout_en );


   wire         fifo_empty, fifo_full, prog_full ;
   wire         rd_en_wir ;
   wire [3:0]   dout_wir ;

   //direct read once empty
   assign rd_en_wir     = fifo_empty ? 1'b0 : 1'b1 ;

   fifo  #(.AWI(3), .AWO(5), .DWI(16), .DWO(4), .PROG_DEPTH(16))
     u_buf_b2s(
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
