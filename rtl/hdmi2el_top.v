`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MNDJ
// 
// Create Date: 2024/05/03 23:18:37
// Design Name: 
// Module Name: hdmi2el_top
// Project Name: hdmi2el
// Target Devices: 
// Tool Versions: 
// Description:  top wrapper 

// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module hdmi_loop(
input               sys_clk,               //50M系统时钟
input               rst_n,                 //系统复位，低有效
//hdmi in
input               hdmi_ddc_scl_io,       //IIC时钟
inout               hdmi_ddc_sda_io,       //IIC数据
output              hdmi_in_hpd,           //热插拔信号
output [0:0]        hdmi_in_oen,           //输入输出切换信号 
input               clk_hdmi_in_n,         //输入差分时钟
input               clk_hdmi_in_p,         //输入差分时钟
input  [2:0]        data_hdmi_in_n,        //输入差分数据
input  [2:0]        data_hdmi_in_p,        //输入差分数据
    
//el panel port
output wire tr_clk,
output wire hsync,
output wire vsync,
output wire [3 : 0] ud,
output wire [3 : 0] ld,
    
//for debug
output pix_clk,
output vid_hs,
output vid_vs,
output vid_de
);
//for debug
assign pix_clk = pixel_clk;
assign vid_hs = video_hs;
assign vid_vs = video_vs;
assign vid_de = video_de;

//wire definition
wire        clk_10m;           //10m时钟
wire        clk_200m;          //200m时钟
wire        clk_100m;          //100m时钟

wire        rx_rst;            //复位信号，高有效
wire        pixel_clk;         //像素时钟
wire        pixel_clk_5x;      //5倍像素时钟
wire        video_hs;          //行信号
wire        video_vs;          //场信号
wire        video_de;          //数据有效使能
wire        hdmi_in_oen;       //输入输出切换信号 
wire        hdmi_in_hpd;       //热插拔信号
wire        hdmi_out_oen;      //输入输出切换信号 
wire [23:0] video_rgb;         //像素数据
//disp ctrl
wire wren1;
wire wren2;
wire frame;
wire [18 : 0] ram_addr;
wire datout;
wire [9 : 0] x_pos;
wire [8 : 0] y_pos;
wire [7 : 0] y_off;
//timing ctrl
wire en;
wire [3 : 0] key;
wire [3 : 0] up_data;
wire [3 : 0] dn_data;
wire [16 : 0] addr;
assign y_off = 8'b00000000;
assign en = 1'b1;
assign key = 4'b0000;

//*****************************************************
//**                    main code
//*****************************************************      
//时钟模块
mmcm u_mmcm(
.clk_out1           (clk_10m),  // output clk_out1
.clk_out2           (clk_200m),  // output clk_out1
.clk_out3           (clk_100m),  // output clk_out1
.locked              (       ),  // output locked
.clk_in1            (sys_clk)   // input clk_in1
);      
    
//读edid模块    
i2c_edid u_i2c_edid (
.clk(clk_10m),
.rst(~rst_n),
.scl(hdmi_ddc_scl_io),
.sda(hdmi_ddc_sda_io)
);    
    
//hdmi解码模块    
hdmi_rx u_hdmi_rx(
.clk_10m       (clk_10m),
.clk_200m      (clk_200m),
//input
.tmdsclk_p     (clk_hdmi_in_p),     
.tmdsclk_n     (clk_hdmi_in_n),      
.blue_p        (data_hdmi_in_p[0]), 
.green_p       (data_hdmi_in_p[1]),  
.red_p         (data_hdmi_in_p[2]),  
.blue_n        (data_hdmi_in_n[0]),  
.green_n       (data_hdmi_in_n[1]), 
.red_n         (data_hdmi_in_n[2]), 
.rst_n         (rst_n),              
//output       
.reset         (rx_rst),             
.pclk          (pixel_clk),         
.pclkx5        (pixel_clk_5x),       
.hsync         (video_hs),          
.vsync         (video_vs),          
.de            (video_de),          
.rgb_data      (video_rgb),         
.hdmi_in_en    (hdmi_in_oen),    
.hdmi_in_hpd   (hdmi_in_hpd)  
);      
   
 
display_ctrl u_display_ctrl(
//rgb port
.pclk(pixel_clk),
.rst(rx_rst),
.rgb_data(video_rgb),
.de(video_de),
.hsync(video_hs),
.vsync(video_vs),
  
//ram port
.wren1(wren1),
.wren2(wren2),
.frame(frame),
.ram_addr(ram_addr),
.datout(datout),
  
//debug port
.x_pos(x_pos),
.y_pos(y_pos),
.y_off(y_off)
);

 
timing_gen u_timing_gen(
//ram port
.clk(clk_100m),
.rst(~rst_n),
.en(en),
.up_data(up_data),
.dn_data(dn_data),
.addr(addr),  
//frame_ctrl
.frame(frame),
//el port
.tr_clk(tr_clk),
.hsync(hsync),
.vsync(vsync),
.ud(ud),
.ld(ld),
//debug port
.key(key),
.el_x(),
.el_y()
);

blk_mem_gen_0 gram_upper (
.clka(pixel_clk),    // input wire clka
.wea(wren1),      // input wire [0 : 0] wea
.addra(ram_addr),  // input wire [18 : 0] addra
.dina(datout),    // input wire [0 : 0] dina
.clkb(tr_clk),    // input wire clkb
.addrb(addr),  // input wire [16 : 0] addrb
.doutb(up_data)  // output wire [3 : 0] doutb
);

blk_mem_gen_0 gram_lower (
.clka(pixel_clk),    // input wire clka
.wea(wren2),      // input wire [0 : 0] wea
.addra(ram_addr),  // input wire [18 : 0] addra
.dina(datout),    // input wire [0 : 0] dina
.clkb(tr_clk),    // input wire clkb
.addrb(addr),  // input wire [16 : 0] addrb
.doutb(dn_data)  // output wire [3 : 0] doutb
);

endmodule