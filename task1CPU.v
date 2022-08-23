/* ****************************************************************************
-                                   小组成员
-                               2020211651菅宇琛                
-                               2020211650黄峰
-                               2020211654孟飞洋                
-                               2020211659滕宇航
******************************************************************************/

/******************************************************************************
- 	第一个任务：必选题目
-	基础功能：
-		按照给定数据格式、指令系统和数据通路，根据所提供的器件要求，
- 		自行设计一个基于硬布线控制器的顺序模型处理机。
-	附加功能：
- 		在原指令基础上扩指至少三条。
- 		允许用户在程序开始时指定PC指针的值。
******************************************************************************/

module task1CPU(//端口定义
            CLR,        //#CLR
            T3,         //节拍 
            SW,         //控制台信号 3--C 2--B 1--A
            IR,         //高四位指令寄存器 7..4
            W,          //节拍 3..1
            C,  Z,      //运算器

            DRW,        //写入寄存器
            PCINC,      //程序计数器+1信号
            LPC,        //程序计数器控制信号
            LAR,        //地址寄存器控制信号
            PCADD,      //偏移量，重新给pc指针赋值
            ARINC,      //地址寄存器+1信号
            SELCTL,     //控制台方式时为1
            MEMW,       //从左端口写入信号
            STOP,       //停机
            LIR,        //指令寄存器的锁存信号
            LDZ,        //运算器进位相关
            LDC,        //运算器
            CIN,        //进位
            S,          //运算器控制信号 3..0
            M,          //算术运算
            ABUS,       //运算器读出数据
            SBUS,       //数据输入开关信号
            MBUS,       //从左端口读出数据
            SHORT,      //一个CPU周期的指令
            LONG,       //三个CPU周期的指令
            SEL         //选择寄存器 3..0
            );
input               CLR, C, Z, T3;
input   [3:1]       SW, W;
input   [7:4]       IR;

output              DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP;
output				LIR, LDZ, LDC, CIN, M, ABUS, SBUS, MBUS, SHORT, LONG;
output  [3:0]       S, SEL;

//中间变量
wire                W_REG, R_REG, W_RAM, R_RAM, G_INS; 
wire                ADD, SUB, AND, INC, LD, ST, JC, JZ, JMP, STP;
wire                OUT;
reg                 ST0;

//操作模式
assign              W_REG = (SW == 3'b100);     //写寄存器
assign              R_REG = (SW == 3'b011);     //读寄存器
assign              W_RAM = (SW == 3'b001);     //写存储器
assign              R_RAM = (SW == 3'b010);     //读存储器
assign              G_INS = (SW == 3'b000);     //取指

//指令
assign              ADD = (IR == 4'b0001) && G_INS && ST0;      //加法
assign              SUB = (IR == 4'b0010) && G_INS && ST0;      //减法
assign              AND = (IR == 4'b0011) && G_INS && ST0;      //逻辑与
assign              INC = (IR == 4'b0100) && G_INS && ST0;      //加1
assign              LD  = (IR == 4'b0101) && G_INS && ST0;      //取数
assign              ST  = (IR == 4'b0110) && G_INS && ST0;      //存数
assign              JC  = (IR == 4'b0111) && G_INS && ST0;      //C条件转移
assign              JZ  = (IR == 4'b1000) && G_INS && ST0;      //Z条件转移
assign              JMP = (IR == 4'b1001) && G_INS && ST0;      //无条件转移
assign              STP = (IR == 4'b1110) && G_INS && ST0;      //停机

//额外的添加指令
assign              OUT = (IR == 4'b1010) && G_INS && ST0;      //输出



//ST0的状态
//当按CLR时
always @(negedge CLR or negedge T3) begin
    if(CLR == 0) begin
        ST0 <= 0;
    end
    else if(~ST0 && ((W_REG && W[2]) || (R_RAM && W[1]) || (W_RAM && W[1]) || (G_INS && W[1]))) begin
        ST0 <= 1;
    end
    else if(ST0 && (W_REG && W[2])) begin
        ST0 <= 0;
    end
end

assign              DRW   = W_REG && (W[1] || W[2]) || (ADD || SUB || INC) && W[2] || LD && W[3];
assign              PCINC = G_INS && W[1];
assign              LPC   = JMP && W[2];
assign              LAR   = (R_RAM || W_RAM) && ~ST0 && W[1] || (LD || ST) && W[2];
assign              PCADD = (JC || JZ) && W[2];
assign              ARINC = (R_RAM || W_RAM) && ST0 && W[1];
assign              SELCTL= (R_REG || W_REG) && (W[1] || W[2]);
assign              MEMW  = ST0 && W_RAM && W[1] || ST && W[3];
assign              STOP  = (R_REG || W_REG) && (W[1] || W[2]) || (R_RAM || W_RAM) && W[1] || STP && W[2];
assign              LIR   = G_INS && W[1];
assign              LDZ   = (ADD || SUB || AND) && W[2];
assign              LDC   = (ADD || SUB) && W[2];
assign              CIN   = ADD && W[2];
assign              S[3]  = (ADD || AND || LD || ST || JMP || OUT) && W[2] || ST && W[3];
assign              S[2]  = (SUB || ST || JMP) && W[2];
assign              S[1]  = (SUB || AND || LD || ST || JMP || OUT) && W[2] || ST && W[3];
assign              S[0]  = (ADD || AND || ST || JMP) && W[2];
assign              M     = (AND || LD || ST || JMP || OUT) && W[2] || ST && W[3];
assign              ABUS  = (ADD || SUB || AND || INC || LD || ST || JMP || OUT) && W[2] || ST && W[3];
assign              SBUS  = R_RAM && ~ST0 && W[1] || W_RAM && W[1];
assign              MBUS  = R_RAM && ST0 && W[1];
assign              SHORT = (R_RAM || W_RAM) && W[1];
assign              LONG  = (LD || ST) && W[2];
assign              SEL[3]= W_REG && ST0 && (W[1] || W[2]) || R_REG && W[2];
assign              SEL[2]= W_REG && W[2];
assign              SEL[1]= W_REG && (~ST0 && W[1] || ST0 && W[2]) || R_REG && W[2];
assign              SEL[0]= W_REG && W[1] || R_REG && (W[1] || W[2]);

endmodule

