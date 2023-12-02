`timescale 1ns/1ns

`define         SMALL2BIG

module test ;

`ifdef SMALL2BIG
   reg          rstn ;
   reg          clk_fast, clk_slow ;
   reg [3:0]    din ;
   reg          din_en ;
   wire [15:0]  dout ;
   wire         dout_en ;

   //reset
   initial begin
      clk_fast  = 0 ;
      clk_slow  = 0 ;
      rstn      = 0 ;
      #50 rstn  = 1 ;
   end

   //clock
   parameter CYCLE_WR = 40 ;
   always #(CYCLE_WR/2/4) clk_slow = ~clk_slow ;
   always #(CYCLE_WR/2-1) clk_fast = ~clk_fast ;

   //data generate
   initial begin
      din       = 16'h4321 ;
      din_en    = 0 ;
      wait (rstn) ;
      //(1) test prog_full and full
      force test.u_data_buf2.u_buf_s2b.rinc = 1'b0 ;
      repeat(32) begin
         @(negedge clk_slow) ;
         din_en = 1'b1 ;
         din    = {$random()} % 16;
      end
      @(negedge clk_slow) din_en = 1'b0 ;

      //(2) test read and write fifo
      #500 ;
      rstn = 0 ;
      #10 rstn = 1 ;
      release test.u_data_buf2.u_buf_s2b.rinc;
      repeat(100) begin
         @(negedge clk_slow) ;
         din_en = 1'b1 ;
         din    = {$random()} % 16;
      end

      //(3) test again: prog_full and full
      force test.u_data_buf2.u_buf_s2b.rinc = 1'b0 ;
      repeat(18) begin
         @(negedge clk_slow) ;
         din_en = 1'b1 ;
         din    = {$random()} % 16;
      end
   end

   //data buffer
   fifo_s2b u_data_buf2(
        .rstn           (rstn),
        .din            (din),
        .din_clk        (clk_slow),
        .din_en         (din_en),

        .dout           (dout),
        .dout_clk       (clk_fast),
        .dout_en        (dout_en));



`else
   reg          rstn ;
   reg          clk_fast, clk_slow ;
   reg [15:0]   din ;
   reg          din_en ;
   wire [3:0]   dout ;
   wire         dout_en ;

   //reset
   initial begin
      clk_fast  = 0 ;
      clk_slow  = 0 ;
      rstn      = 0 ;
      #50 rstn  = 1 ;
   end

   //clock
   parameter CYCLE_WR = 40 ;
   always #(CYCLE_WR/2) clk_slow = ~clk_slow ;
   always #(CYCLE_WR/2/4-1) clk_fast = ~clk_fast ;

   //data generate
   initial begin
      din       = 16'h8888 ;
      din_en    = 0 ;
      //(1) test prog_full and full
      force test.u_data_buf1.u_buf_b2s.rinc = 1'b0 ;
      repeat(18) begin
         @(negedge clk_slow) ;
         din_en = 1'b1 ;
         din    = din + 16'h4321 ;
      end

      //(2) test read and write fifo
      rstn = 0 ;
      #10 rstn = 1 ;
      release test.u_data_buf1.u_buf_b2s.rinc ;
      repeat(48) begin
         @(negedge clk_slow) ;
         din_en = 1'b1 ;
         din    = din + 16'h4321 ;
      end

      //(3) test again: prog_full and full
      force test.u_data_buf1.u_buf_b2s.rinc = 1'b0 ;
      repeat(18) begin
         @(negedge clk_slow) ;
         din_en = 1'b1 ;
         din    = din + 16'h4321 ;
      end
   end

   //data buffer
   fifo_b2s u_data_buf1(
        .rstn           (rstn),
        .din            (din),
        .din_clk        (clk_slow),
        .din_en         (din_en),

        .dout           (dout),
        .dout_clk       (clk_fast),
        .dout_en        (dout_en));

`endif


   //stop sim
   initial begin
      forever begin
         #100;
         if ($time >= 5000)  $finish ;
      end
   end

endmodule // test
