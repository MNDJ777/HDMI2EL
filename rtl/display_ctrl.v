`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MNDJ
// 
// Create Date: 2024/05/09 01:52:54
// Design Name: 
// Module Name: display_ctrl
// Project Name: hdmi2el
// Target Devices: 
// Tool Versions: 
// Description:  Video stream process according to refreshing characteristic.  
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module display_ctrl#(
             parameter X_RES = 640,
             parameter Y_RES = 480,
             parameter FPS = 60,
             parameter Y_OFFSET = 0
)(  
    //clock and reset
    input pclk,
    input rst,
    //vga timing input port
    input [23:0] rgb_data,
    input de,
    input hsync,
    input vsync,
    //ram control port
    output wire wren1,
    output wire wren2,
    output wire [$clog2(X_RES * Y_RES)-1 : 0] ram_addr,
    output datout,
    //frame indicating 
    output wire frame,
    //debug ports
    output [$clog2(X_RES)-1 : 0] x_pos,
    output [$clog2(Y_RES)-1 : 0] y_pos,
    input [7 : 0] y_off
    );
   
    
    reg [$clog2(X_RES)-1 : 0] row_cntr;
    reg [$clog2(Y_RES)-1 : 0] col_cntr;
    reg [31 : 0] frame_cntr; // frame counter to distinguish even frame from odd frame
    
    assign x_pos = row_cntr;
    assign y_pos = col_cntr;
    
    //frame indicate process
    assign frame = frame_cntr[0];

    //output data process
    assign datout = rgb_data[7]; // output threshould  = red /2  (128)
    
    //address process
//    assign ram_addr =(frame_cntr[0])?  ((col_cntr + wren1 *240)*640 +row_cntr) :  ((col_cntr - wren2 * 240) * 640 + row_cntr);//根据上半部分和下半部分以及奇偶帧动态切换地址
    assign ram_addr =(col_cntr - y_off - wren2 *200)*640 +row_cntr;//根据上半部分和下半部分切换地址,禁用奇偶帧
    
    //ram select process
    assign wren1 = ( (col_cntr - y_off >= 0) && (col_cntr - y_off < 200) && de)? 1'b1 : 1'b0;  //上半幅面写入第一个gram，数据无效时期禁止写入ram
    assign wren2 = ((col_cntr - y_off> 199) && de)? 1'b1 : 1'b0; //下半幅面写入第二个gram，数据无效时期禁止写入ram
    
    //row counter process
    always@(posedge pclk) begin
    if (rst)//复位
        row_cntr <= 0;
    else if(row_cntr ==  X_RES - 1) 
        row_cntr <= 0;
    else if( de )
        row_cntr <= row_cntr + 1'b1;
    else 
         row_cntr <= row_cntr;      
    end
    
     //column counter process
    always@(posedge pclk) begin
    if (rst || !vsync)//复位及帧头同步时重置行计数器(vsync负极性)
        col_cntr <= 0;
    else if(col_cntr ==  Y_RES - 1 && row_cntr ==  X_RES - 1)
        col_cntr <= 0;
    else if(row_cntr ==  X_RES - 1)
        col_cntr <= col_cntr + 1'b1;
    else 
         col_cntr <= col_cntr;      
    end
    
    //frame counter process
    always@(posedge pclk) begin
    if (rst) 
        frame_cntr <= 0;
    else if (col_cntr ==  Y_RES - 1 && row_cntr ==  X_RES - 1)
        frame_cntr <= frame_cntr + 1'b1;
    else 
        frame_cntr <= frame_cntr;
    end
    

endmodule
