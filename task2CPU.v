module task2CPU(//端口定义
            CLR,        //CLR
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
//输入信号
input               CLR, C, Z, T3;
input   [3:1]       SW, W;
input   [7:4]       IR;
//输出信号
output              DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP;
output				LIR, LDZ, LDC, CIN, M, ABUS, SBUS, MBUS, SHORT, LONG;
output  [3:0]       S, SEL;

//中间变量
wire                W_REG, R_REG, W_RAM, R_RAM, G_INS; 

//指令中间变量
wire                ADD, SUB, AND, INC, LD, ST, JC, JZ, JMP, STP;
wire                OUT, OR, MOV;

//某些操作模式下可能会用到两个个W1、W2节拍，用ST0来区分
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
assign 				OR  = (IR == 4'b1011) && G_INS && ST0;		//逻辑或
assign 				MOV = (IR == 4'b1101) && G_INS && ST0;      //移数

//ST0的状态
//当按CLR时使ST0置0，保证进行读写存储器时先从读取数据到AR中得到自定义的地址然后循环进行操作。
//在写寄存器的W2、读存储器的W1、写存储器的W1时，进入下一个节拍时进行不同操作，其中写寄存器的操作是循环的
//取指的W1时改变是因为指令中间信号是在ST0为1时生效
always @(negedge CLR or negedge T3) begin
	if(~CLR)
		ST0 <= 0;
    else if(~ST0 && ((W_REG && W[2]) || (R_RAM && W[1]) || (W_RAM && W[1]) || (G_INS && W[2])))
        ST0 <= 1;
    else if(ST0 && (W_REG && W[2])) 
        ST0 <= 0;
end

//流水线的取址操作
assign              LIR   = G_INS && W[2] || (ADD || SUB || AND || OR || INC || MOV || STP || JC && ~C || JZ && ~Z) && W[1];
assign              PCINC = G_INS && W[2] || (ADD || SUB || AND || OR || INC || MOV || STP || JC && ~C || JZ && ~Z) && W[1];

//节拍修改
assign              SHORT = (R_RAM || W_RAM || ADD || SUB || AND || OR || INC || MOV || STP || JC && ~C || JZ && ~Z) && W[1];
assign              LONG  = 0;

assign              DRW   = W_REG && (W[1] || W[2]) || (ADD || SUB || INC || AND || OR || MOV) && W[1] || LD && W[2];
assign              LPC   = JMP && W[1];
assign              LAR   = (R_RAM || W_RAM) && ~ST0 && W[1] || (LD || ST) && W[1];
assign              PCADD = (JC && C || JZ && Z) && W[1];//存疑待修改 可能是ppt上的图片有误
assign              ARINC = (R_RAM || W_RAM) && ST0 && W[1];
assign              SELCTL= (R_REG || W_REG) && (W[1] || W[2]);
assign              MEMW  = ST0 && (W_RAM && W[1] || ST && W[2]);
assign              STOP  = (R_REG || W_REG) && (W[1] || W[2]) || (R_RAM || W_RAM) && W[1] || STP && W[1];
assign              LDZ   = (ADD || SUB || AND || OR) && W[1];
assign              LDC   = (ADD || SUB) && W[1];
assign              CIN   = ADD && W[1];
assign              S[3]  = (ADD || AND || LD || ST || JMP || OUT || OR || MOV) && W[1] || ST && W[2];
assign              S[2]  = (SUB || ST || JMP || OR) && W[1];
assign              S[1]  = (SUB || AND || LD || ST || JMP || OUT || OR) && W[1] || ST && W[2];
assign              S[0]  = (ADD || AND || ST || JMP) && W[1];
assign              M     = (AND || LD || ST || JMP || OUT || OR || MOV) && W[1] || ST && W[2];
assign              ABUS  = (ADD || SUB || AND || INC || LD || ST || JMP || OUT || OR || MOV) && W[1] || ST && W[2];
assign              SBUS  = R_RAM && ~ST0 && W[1] || W_RAM && W[1] || W_REG;
assign              MBUS  = R_RAM && ST0 && W[1] || LD && W[2];
assign              SEL[3]= W_REG && ST0 && (W[1] || W[2]) || R_REG && W[2];
assign              SEL[2]= W_REG && W[2];
assign              SEL[1]= W_REG && (~ST0 && W[1] || ST0 && W[2]) || R_REG && W[2];
assign              SEL[0]= W_REG && W[1] || R_REG && (W[1] || W[2]);

endmodule

