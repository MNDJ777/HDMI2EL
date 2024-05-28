# **HDMI2EL**

## ✨将手中迷人的EL显示屏赋予现代的HDMI接口吧！✨

![P10168072](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/P10168072.JPG)

------

## 0x00  背景介绍

​     电致发光显示器(Electroluminescent Display)，可以看作现代OLED的前身。其结构与OLED也很类似，只是采用无机物而不是有机半导体在电场激发下发光。由于其体积小，工作温度范围和视觉效果都比当时的LCD更优秀，这类显示器常见于80-90年代较高要求的场合，如工业和医疗设备。常见的EL显示器发光颜色一般为黄色或琥珀色，也曾出现过红绿双色的型号，只不过非常罕见，价格很高。(摘自[EE Archeology 电子考古学）](http://7400.me/)

​		值得一提的是，超音速客机协和式客舱中的速度/高度/温度显示屏就使用了这种显示技术。

![P1005067.00_05_26_02.静止001](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/P1005067.00_05_26_02.静止001.jpg)

协和式客机客舱飞行参数显示面板

![GettyImages-828833162](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/GettyImages-828833162.jpg)

协和式客机以2.0马赫（约为2450 km/h）在54000英尺（约16459米）巡航时的显示状态



​		相信这种迷人的显示效果也受到著名漫画家和导演庵野秀明的喜爱，其作品新世纪福音战士 (又称EVA [ EVANGELION](https://lnk.to/EVA-30_111) ) 中NERV指挥中心的UI大量使用了这种橘黄荧光显示字体和图像，因此EL显示技术也成为EVA美学中重要组成部分。

![Neon Genesis Evangelion E18 Ambivalence.mkv_20240528_160758.578](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/Neon%20Genesis%20Evangelion%20E18%20Ambivalence.mkv_20240528_160758.578.jpg)

图为EVA中NERV地下要塞作战指挥部

------

## 0x01 项目介绍



​		作者本人亦十分喜爱EL显示屏，其独特的橘黄荧光以及由于电场分布梯度产生的柔和的高光扩散让人欲罢不能。因此作者在多年前曾收藏了一片来自夏普的EL显示屏LJ64HB34，曾幻想过由STM32来驱动它，但由于驱动这块屏幕需要产生精确的时序，加上当时青涩的编程水平，这个想法也没能实现。近段时间作者开始学习FPGA和Verilog，发现了在阁楼吃灰的这片屏幕，于是这个项目就被重新提上日程了。

​		在项目的构想方面，作者最初的想法是做成一个字符/图像显示器，将EL屏的双4-bit并口转换成通用的MCU接口（比如SPI），毕竟显示内容有限，而且浪费了EL屏的高刷新率，所以不如……做成一个HDMI显示器吧！😜



------

## 0x02 硬件搭建



1. FPGA平台：Zedboard国产版 AMD ZYNQ7020 由于本项目仅使用PL资源编写，可以方便地移植到其他7系纯FPGA上

   ![1598521177-2-750x750](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/1598521177-2-750x750.jpg)

   

2. 自制的Zedboard Video Extension Board。 由于Zedboard没有提供HDMI in，因此通过丐版"FMC"接口引出了两个HDMI,一个40P LCD接口，一个DVP接口。HDMI直连FPGA，使用TMDS_33电平

   

   ![hdmi_ext](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/hdmi_ext.jpg)

3. SHARP LJ64HB34 EL屏幕模组 显示分辨率640*400 刷新率可达120Hz

![a5ccc7b925dc21ed5ce5474637a16a9](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/a5ccc7b925dc21ed5ce5474637a16a9.jpg)

3. 由于EL模组信号电平为5V,所以作者设计了一片PMOD电平转换板，内置了一个5V-12V的DCDC，使用常见的TYPEC接口供电，转接板硬件设计将后续开源

   ![5ad340ff822214e043d06b9671df2da](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/5ad340ff822214e043d06b9671df2da.jpg)

4. 输出能力至少5V3A的电源适配器一个，由于驱动EL面板需要上百伏的高压，屏幕模组内置了复杂的升压电路，因此屏幕功耗不低，经测试全屏点亮功率为13W。

   

------



## 0x03 RTL设计

作者查阅了许多EL模组的资料发现，和大多数EL显示模组类似，LJ64HB34模组分为上下两半同时刷新，驱动信号由两组4bit并口以及传输时钟，行场同步信号组成。这一点和传统的逐行扫描方式有着明显区别，相当于同时驱动两块屏幕。

![func diagram](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/func%20diagram.jpg)

为了顺利地与逐行扫描的HDMI视频信号桥接起来，我们需要两块显存来独立储存上下屏的数据。（当然一块也可以，但是需要别扭地拼接两边像素数据，而且加大编写难度）

![arch](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/arch.jpg)

实际上本项目需要做的工作很简单，只是按照EL的像素排列规律把数据搬运到显存中，然后时序发生模块按照EL屏的时序从显存中读出来。其中HDMI接收模块IP由正点原子提供（为防止侵权，本项目暂不提供这块的代码，请在正点原子达芬奇开发板资料中获取）。经计算，显存需要的空间为640x480x2=614.4kb（纵向480是因为目前HDMI输出的是VGA尺寸画面，理论上可以通过调整EDID直接输出640*400分辨率，目前还没验证，乘以2是预留了乒乓操作的空间同步画面防止画面撕裂）不过经过实际测试结果，输入640x480@60Hz,输出正好是输入帧率的两倍，即使使用单缓存显示也不太看得出撕裂效果。

幸运的是显存空间需求不大，只有614.4kb，能够使用BRAM资源生成双口RAM，而7020提供了4.9Mb的BRAM空间，即使是7010也有2.1Mb的空间。

![bmg](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/bmg.jpg)

设计好了架构图，就可以开始编写代码了，需要自己编写的代码主要是两部分，第一部分是EL屏时序发生器，第二部分是显示数据控制。时序发生器采用行列计数器的方法实现同步和地址生成，显示数据控制则通过Vsync同步画面，对输入行列进行计数并对像素简单二值化后分时写入显存中。由于作者是FPGA初学者，代码水平有限，请读者直接阅读源码，如有改进提升之处还请不吝指出。

![bd](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/bd.png)

以上是项目完整的框图，约束好引脚之后产生比特流便可以上板调试了。

![resource report](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/resource%20report.jpg)

功能比较简单，所以资源用的还是比较少的，主要是时钟布线和BRAM消耗较大，直接通过JTAG下载到板子上



------

## 0x04 测试效果与debug🥵

屏幕尺寸测试

![display](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/display.jpg)

函数显示测试（给我的SuperHub露个脸，下一个项目也许是讲它）

![display1](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/display1.jpg)

![display2](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/display2.jpg)

下面粗略讲下点屏的过程中遇到的问题吧，

第一个当然是硬件问题，当时低估了EL屏的功耗，做转接板的时候电源端口用了2A的PTC保险，结果工作时发热严重，压降巨大，导致dcdc掉压，产生闪屏现象，解决办法是直接短接这个保险。

第二个是有一路数据电平转换芯片内部失效了，输出间歇性地高电平，所以屏幕产生不规则竖线。解决办法是换芯片。

![ic failure](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/ic%20failure.jpg)

第三个是比较坑的问题，由于HDMI_EDID的SDA脚需要三态驱动，源文件内部是直接给SDA分配Z电平来实现的，直接RTL顶层综合出来也确实会出现IOBUF。然而当我用Block Design设计时，直接导入此IP不会综合出三态门，无法实现输入。后来查了一下这个是BD本身的问题，解决办法是在ip源文件里用原语手动例化IOBUF。

![tristate](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/tristate.png)

使用RTL顶层文件自动生成的三态门

![IOBU](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/IOBU.png)

使用Block Design 必须手动例化IOBUF，不然不会综合出三态门，使用三态IO时必须注意这个问题



第四个是我百思不得其解的问题，也是跟Block Design有关，HDMI_RX 导入BD后无法输出HSYNC和VSYNC信号，但是时钟，数据，DE均正常，这也不会影响到系统工作，因为显示控制模块依靠DE来判读数据。但是缺少VSYNC后会导致显示无法锁定每帧的第一行，于是乎会产生错位，比如这样

![misalignment](https://github.com/MNDJ666/HDMI2EL/blob/main/pics/misalignment.jpg)

对比由BD生成的顶层文件和不使用BD而手动例化模块产生的顶层文件，HDMI_RX IP综合出来的内部结构是有差异的，由于IP内部结构过于复杂，以作者目前的水平也没法解释这个现象，解决办法是摒弃blockdesign转为手动编写RTL顶层文件，信号都能正常产生。但是BD是真的太方便了，哭唧唧😥



------



## 0x05 致谢😘

这个项目的开发调试时间在3周以内，包括PCB设计和焊接，能如此快速地构建硬件，当然要感谢嘉立创爸爸的免费打样机会，作为偶尔白嫖党，确实感受到嘉立创工业制造能力的强大。

同时也感谢EE_Archeology在个人博客上记录的珍贵资料，对我理解时序帮助很大[[点屏记录\]用ESP32驱动夏普LJ64H052 EL显示屏 | EE Archeology 电子考古学 (7400.me)](http://7400.me/2021/03/06/Sharp_LJ64H052/)

以及和光大佬的视频[自制一台EL屏幕串口终端机_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1VY411J7xT/?spm_id_from=333.999.0.0)

以及各位群友的热心帮助（@hyc @滚筒洗衣机）

希望这个项目能为EL屏的爱好者们点屏做出一点微小的贡献。

​														by MNDJ 20240529
