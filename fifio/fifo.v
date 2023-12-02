module  fifo
    #(  parameter       AWI        = 7 ,
        parameter       AWO        = 5 ,
        parameter       DWI        = 16 ,
        parameter       DWO        = 64 ,
        parameter       PROG_DEPTH = 64) //programmable full
    (
        input                   rstn,
        input                   wclk,
        input                   winc,
        input [DWI-1: 0]        wdata,

        input                   rclk,
        input                   rinc,
        output [DWO-1 : 0]      rdata,

        output                  wfull,
        output                  rempty,
        output                  prog_full
     );

   parameter       EXTENT       = DWO/DWI ;
   parameter       EXTENT_BIT   = AWI-AWO ;
   parameter       SHRINK       = DWI/DWO ;
   parameter       SHRINK_BIT   = AWO-AWI ;

   //======================= push counter =====================
   wire [AWI-1:0]               waddr ;
   wire                         wover_flag ;  //counter overflow
   ccnt         #(.W(AWI+1))             //128
   u_push_cnt(
              .rstn           (rstn),
              .clk            (wclk),
              .en             (winc && !wfull),
              .count          ({wover_flag, waddr})
              );

   //========================== pop counter ==================================
   wire [AWO-1:0]            raddr ;
   wire                      rover_flag ;   //counter overflow
   ccnt         #(.W(AWO+1))    //128
   u_pop_cnt(
             .rstn           (rstn),
             .clk            (rclk),
             .en             (rinc & !rempty), //read forbidden when empty
             .count          ({rover_flag, raddr})
             );

   //==============================================
   //small in and big out
generate
   if (DWO >= DWI) begin : EXTENT_WIDTH
   //=====================================

      //gray code
      wire [AWI:0] wptr    = ({wover_flag, waddr}>>1) ^ ({wover_flag, waddr}) ;
      //sync wr ptr
      reg [AWI:0]  rq2_wptr_r0 ;
      reg [AWI:0]  rq2_wptr_r1 ;
      always @(posedge rclk or negedge rstn) begin
         if (!rstn) begin
            rq2_wptr_r0     <= 'b0 ;
            rq2_wptr_r1     <= 'b0 ;
         end
         else begin
            rq2_wptr_r0     <= wptr ;
            rq2_wptr_r1     <= rq2_wptr_r0 ;
         end
      end

      //gray code
      wire [AWI-1:0] raddr_ex = raddr << EXTENT_BIT ;
      wire [AWI:0]   rptr     = ({rover_flag, raddr_ex}>>1) ^ ({rover_flag, raddr_ex}) ;
      //sync rd ptr
      reg [AWI:0]    wq2_rptr_r0 ;
      reg [AWI:0]    wq2_rptr_r1 ;
      always @(posedge wclk or negedge rstn) begin
         if (!rstn) begin
            wq2_rptr_r0     <= 'b0 ;
            wq2_rptr_r1     <= 'b0 ;
         end
         else begin
            wq2_rptr_r0     <= rptr ;
            wq2_rptr_r1     <= wq2_rptr_r0 ;
         end
      end

      //decode
      reg [AWI:0]       wq2_rptr_decode ;
      reg [AWI:0]       rq2_wptr_decode ;
      integer           i ;
      always @(*) begin
         wq2_rptr_decode[AWI] = wq2_rptr_r1[AWI];
         for (i=AWI-1; i>=0; i=i-1) begin
            wq2_rptr_decode[i] = wq2_rptr_decode[i+1] ^ wq2_rptr_r1[i] ;
         end
      end
      always @(*) begin
         rq2_wptr_decode[AWI] = rq2_wptr_r1[AWI];
         for (i=AWI-1; i>=0; i=i-1) begin
            rq2_wptr_decode[i] = rq2_wptr_decode[i+1] ^ rq2_wptr_r1[i] ;
         end
      end


      assign rempty    = (rover_flag == rq2_wptr_decode[AWI]) &&
                         (raddr_ex >= rq2_wptr_decode[AWI-1:0]);
      assign wfull     = (wover_flag != wq2_rptr_decode[AWI]) &&
                         (waddr >= wq2_rptr_decode[AWI-1:0]) ;
      assign prog_full  = (wover_flag == wq2_rptr_decode[AWI]) ?
                          waddr - wq2_rptr_decode[AWI-1:0] >= PROG_DEPTH-1 :
                          waddr + (1<<AWI) - wq2_rptr_decode[AWI-1:0] >= PROG_DEPTH-1;

      ramdp
        #( .AWI     (AWI),
           .AWO     (AWO),
           .DWI     (DWI),
           .DWO     (DWO))
      u_ramdp
        (
         .CLK_WR          (wclk),
         .WR_EN           (winc & !wfull),
         .ADDR_WR         (waddr),
         .D               (wdata[DWI-1:0]),
         .CLK_RD          (rclk),
         .RD_EN           (rinc & !rempty),
         .ADDR_RD         (raddr),
         .Q               (rdata[DWO-1:0])
         );

   end

   //==============================================
   //big in and small out
   else begin: SHRINK_WIDTH
   //=====================================
      //gray code
      wire [AWO-1:0]    waddr_ex = waddr << SHRINK_BIT ;
      wire [AWO:0]      wptr     = ({wover_flag, waddr_ex}>>1) ^ ({wover_flag, waddr_ex}) ;
      //sync rd ptr
      reg [AWO:0]    rq2_wptr_r0 ;
      reg [AWO:0]    rq2_wptr_r1 ;
      always @(posedge rclk or negedge rstn) begin
         if (!rstn) begin
            rq2_wptr_r0     <= 'b0 ;
            rq2_wptr_r1     <= 'b0 ;
         end
         else begin
            rq2_wptr_r0     <= wptr ;
            rq2_wptr_r1     <= rq2_wptr_r0 ;
         end
      end

      //sync rp ptr
      reg [AWO:0]  wq2_rptr_r0 ;
      reg [AWO:0]  wq2_rptr_r1 ;
      wire [AWO:0] rptr    = ({rover_flag, raddr}>>1) ^ ({rover_flag, raddr}) ;
      always @(posedge rclk or negedge rstn) begin
         if (!rstn) begin
            wq2_rptr_r0     <= 'b0 ;
            wq2_rptr_r1     <= 'b0 ;
         end
         else begin
            wq2_rptr_r0     <= rptr ;
            wq2_rptr_r1     <= wq2_rptr_r0 ;
         end
      end


      //decode
      reg [AWO:0]       wq2_rptr_decode ;
      reg [AWO:0]       rq2_wptr_decode ;
      integer           i ;
      always @(*) begin
         wq2_rptr_decode[AWO] = wq2_rptr_r1[AWO];
         for (i=AWO-1; i>=0; i=i-1) begin
            wq2_rptr_decode[i] = wq2_rptr_decode[i+1] ^ wq2_rptr_r1[i] ;
         end
      end
      always @(*) begin
         rq2_wptr_decode[AWO] = rq2_wptr_r1[AWO];
         for (i=AWO-1; i>=0; i=i-1) begin
            rq2_wptr_decode[i] = rq2_wptr_decode[i+1] ^ rq2_wptr_r1[i] ;
         end
      end

      assign rempty    = (rover_flag == rq2_wptr_decode[AWO]) &&
                         (raddr >= rq2_wptr_decode[AWO-1:0]);
      assign wfull     = (wover_flag != wq2_rptr_decode[AWO]) &&
                         (waddr_ex >= wq2_rptr_decode[AWO-1:0]) ;
      assign prog_full  = (wover_flag == wq2_rptr_decode[AWO]) ?
                          waddr_ex - wq2_rptr_decode[AWO-1:0] >= PROG_DEPTH-1 :
                          waddr_ex + (1<<AWO) - wq2_rptr_decode[AWO-1:0] >= PROG_DEPTH-1;

      ramdp
        #( .AWI     (AWI),
           .AWO     (AWO),
           .DWI     (DWI),
           .DWO     (DWO))
      u_ramdp
        (
         .CLK_WR          (wclk),
         .WR_EN           (winc & !wfull),
         .ADDR_WR         (waddr),
         .D               (wdata[DWI-1:0]),
         .CLK_RD          (rclk),
         .RD_EN           (rinc & !rempty),
         .ADDR_RD         (raddr),
         .Q               (rdata[DWO-1:0])
         );

   end

 endgenerate


endmodule
