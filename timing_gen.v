`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MNDJ
// 
// Create Date: 2024/05/03 23:18:37
// Design Name: 
// Module Name: timing_gen
// Project Name: hdmi2el
// Target Devices: 
// Tool Versions: 
// Description:  EL display timing generation, has been verified on SHARP LJ64HB34 640*400@120Hz

// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timing_gen#(
            parameter FREQ_IN = 100000000,
		    parameter X_RES = 640,
			parameter Y_RES = 200, //y_res equals to half of the actual resolution due to two halves refresh simutaneously 
			parameter FPS     = 120,//target fps
			parameter H_BLANK = 5,//reserve for hsync
			parameter V_BLANK = 0,// no vsync time needed
			parameter Y_OFFSET = 0//refresh offset

)(
        //reset & clk
        input clk,
        input rst,      
        input en,
        
        //ram port
        input [3 : 0] up_data,                     //upper 4bits
        input [3 : 0] dn_data,                     //lower 4bits
        output  reg [16 : 0] addr,       //80*400 bytes per frame, addressing space is 32000
        //ctrl port
        input frame, //frame indicator, 0 indicates that A buffer is busy, 1 indicates B buffer is busy
        //EL display port
        output reg tr_clk,// EL Xfer clock
        output wire hsync,//horizonal SYNC, indicates the end of each row  (freq = FPS*Y_RES)
        output wire vsync,//vertical SYNC, indicates the end of each frame( freq = FPS)
                         
        output wire [3 : 0] ud,
        output wire [3 : 0] ld,      
        //debug port
        input [3 : 0] key,  //KEY INPUT FOR DEBUG
        output [$clog2(X_RES/4)-1:0] el_x,
        output [$clog2(Y_RES)-1:0]  el_y
        
    );
    
    localparam DIV_CNT = FREQ_IN/(X_RES/4)/Y_RES/FPS/2 - 1;// 计算分频到目标传输频率2倍的计数器值，目标传输频率为640/4 * 200 * 120Hz = 3.84Mhz
    localparam SYNC_CNT = FREQ_IN/(X_RES/4)/Y_RES/FPS - 1;//两倍的翻转时间，即分频一个周期的标志

    reg clk_div;
    wire sync_flag;//像素时钟同步标志
    reg [$clog2(DIV_CNT)-1:0]     div_cntr;//Xfer clk divider counter
    reg [$clog2(SYNC_CNT)-1:0]  sync_cntr;//low frequency sync counter
    reg [$clog2(X_RES/4)-1:0]      row_cntr;//row counter
    reg [$clog2(Y_RES)-1:0]          col_cntr;//column counter
    
    reg frame1;
    
    assign sync_flag = (sync_cntr == SYNC_CNT) ? 1'b1 : 1'b0;//同步计数器清零时发出同步信号
    assign el_x = row_cntr;
    assign el_y = col_cntr;

    //data allocating 
    assign ud[0] = up_data[3];  //reverse data line
    assign ud[1] = up_data[2];
    assign ud[2] = up_data[1];
    assign ud[3] = up_data[0];
    
    assign ld[0] = dn_data[3]; //reverse data line
    assign ld[1] = dn_data[2];
    assign ld[2] = dn_data[1];
    assign ld[3] = dn_data[0];
    
//       assign ud = key;
//       assign ld = ud;
    
    //register xfer clk
    always @(posedge clk) begin
        if(rst) 
            tr_clk<= 0;
        else
            tr_clk<= (row_cntr < X_RES/4 && row_cntr >=0 )? clk_div : 1'b0;
    end


    //Xfer clk generating
    always@(posedge clk) begin
        if(rst) begin
            clk_div <= 0;
            div_cntr <=0;
            end
        else if (div_cntr == DIV_CNT && en) begin        
            div_cntr <= 0;
            clk_div <= !clk_div;
            end       
        else if (en)
            div_cntr <= div_cntr + 1'b1;
        else 
            div_cntr <= div_cntr;   
    end
    
        //sync_div generating
    always@(posedge clk) begin
        if(rst)
            sync_cntr <=0;
        else if (sync_cntr == SYNC_CNT && en)        
            sync_cntr <= 0;      
        else if (en)
            sync_cntr <= sync_cntr + 1'b1;
        else 
            sync_cntr <= sync_cntr;   
    end
    

    //row counter, each row consists of X_RES/4 Xfers
    always@(posedge clk) begin
        if(rst) 
           row_cntr <= 0;
        else if (sync_flag && en && row_cntr == X_RES/4 + H_BLANK - 1)   // counting value of each row equals to data section + blank section 
           row_cntr <= 0;
        else if (sync_flag && en)   
           row_cntr <= row_cntr + 1'b1;
        else
            row_cntr <= row_cntr;   
    end
    
    //column counter, each frame consists of Y_RES rows
    always@(posedge clk) begin
        if(rst) 
           col_cntr <= 0;
        else if (sync_flag && en && col_cntr == Y_RES + V_BLANK -1 && row_cntr == X_RES/4 + H_BLANK - 1)    //col counter reset can only happen at the end of the row scan
           col_cntr <= 0;
        else if (sync_flag && en && row_cntr == X_RES/4 + H_BLANK - 1)   
           col_cntr <= col_cntr + 1'b1;
        else
            col_cntr <= col_cntr;   
    end  
    
  //hsync process
        assign hsync = (row_cntr ==  X_RES/4 + H_BLANK - 3 )? 1'b1 : 1'b0 ; //set the exact position of hsync 
        
    //vsync process    
        assign vsync = (col_cntr == 0) &&((row_cntr ==  X_RES/4 + H_BLANK - 2) || (row_cntr ==  X_RES/4 + H_BLANK - 3) )  ? 1'b1 : 1'b0 ;

    //ram address adding process
    always @(posedge clk) begin
        if(rst)
            addr <= 0;
//       else if (en && row_cntr < X_RES/4 && row_cntr >=0 && frame1 )
       else if (sync_flag && en && row_cntr < X_RES/4 && row_cntr >=0)
         addr <= (col_cntr + Y_OFFSET ) * 160 + row_cntr +1; //calculate exact address  写入地址指向A buffer时，读取地址指向B buffer 地址+1以补偿gram延迟
         
//        else if (en && row_cntr < X_RES/4 && row_cntr >=0 && !frame1 )
//        else if (en && row_cntr < X_RES/4 && row_cntr >=0)
//            addr <= (col_cntr + Y_OFFSET + 240 ) * 160 + row_cntr + 1; //calculate exact address    写入地址指向B buffer时，读取地址指向A buffer内容        
       else
            addr <= addr; 
    end

    //frame indicating process
    always @(posedge clk) begin
        if(rst)
            frame1 <= 0;
        else if (sync_flag && en && (col_cntr == Y_RES + V_BLANK -1) && (row_cntr == X_RES/4 + H_BLANK - 1))
            frame1 <= frame;   //在每帧的末尾确定下一帧地址指向A buffer OR B buffer
        else
            frame1 <= frame1; 
    end


endmodule
