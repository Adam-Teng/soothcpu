module task3CPU(//端口定义
            CLR,        //CLR
            T3,         //节拍 
            SW,         //控制台信号 3--C 2--B 1--A
            IR,         //高四位指令寄存器 7..4
            W,          //节拍 3..1
            C,  Z,      //运算器
            PULSE,      //中断脉冲

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
input               PULSE;

//输出信号
output              DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP;
output				LIR, LDZ, LDC, CIN, M, ABUS, SBUS, MBUS, SHORT, LONG;
output  [3:0]       S, SEL;

//中间变量
wire                W_REG, R_REG, W_RAM, R_RAM, G_INS; 

//指令
wire                ADD, SUB, AND, INC, LD, ST, JC, JZ, JMP, STP;
wire                OUT, IRET, DI, EI, CMP;

reg                 INT;

reg                 ST0;

wire                INTDI, INTEN;

reg					EN_INT, CR3;

wire 				P4;

wire				RECOVER;

reg		[3:0]		CIR;

reg					CZ,CC;

always @(posedge W[1]) begin
	if(~CC && C) 
		CC <= 1;
	else
		CC <= 0;
end

always @(posedge W[1]) begin
	if(~CZ && Z)
		CZ <= 1;
	else
		CZ <= 0;
end

//操作模式
assign              W_REG = (SW == 3'b100);     //写寄存器
assign              R_REG = (SW == 3'b011);     //读寄存器
assign              W_RAM = (SW == 3'b001);     //写存储器
assign              R_RAM = (SW == 3'b010);     //读存储器
assign              G_INS = (SW == 3'b000);     //取指

always @(*) begin
	if(~CR3 && W[2] && INT)
		CIR <= 4'b0000;
	else
		CIR <= IR;
end

//指令
assign              ADD = (CIR == 4'b0001) && G_INS && ST0;      //加法
assign              SUB = (CIR == 4'b0010) && G_INS && ST0;      //减法
assign              AND = (CIR == 4'b0011) && G_INS && ST0;      //逻辑与
assign              INC = (CIR == 4'b0100) && G_INS && ST0;      //加1
assign              LD  = (CIR == 4'b0101) && G_INS && ST0;      //取数
assign              ST  = (CIR == 4'b0110) && G_INS && ST0;      //存数
assign              JC  = (CIR == 4'b0111) && G_INS && ST0;      //C条件转移
assign              JZ  = (CIR == 4'b1000) && G_INS && ST0;      //Z条件转移
assign              JMP = (CIR == 4'b1001) && G_INS && ST0;      //无条件转移   
//JC JZ JMP格式被限制为只能从运算器的B端口读取寄存器数值(S = 1010)，并且不可以对R3进行操作(8'd100111xx(xx不可以为11))
assign              STP = (CIR == 4'b1110) && G_INS && ST0;      //停机

//额外的添加指令
assign              OUT = (CIR == 4'b1010) && G_INS && ST0;      //输出
assign 				CMP = (CIR == 4'b1111) && G_INS && ST0;      //比较

//中断指令
assign              IRET= (CIR == 4'b1011) && G_INS && ST0;      //中断返回      1011
assign              DI  = (CIR == 4'b1100) && G_INS && ST0;      //关中断        1100
assign              EI  = (CIR == 4'b1101) && G_INS && ST0;      //开中断        1101

always @(negedge CLR or negedge T3) begin
	if(~CLR)
		ST0 <= 0;
    else if(~ST0 && ((W_REG && W[2]) || (R_RAM && W[1]) || (W_RAM && W[1]) || (G_INS && W[1])))
        ST0 <= 1;
    else if(ST0 && (W_REG && W[2])) 
        ST0 <= 0;
end

always @(negedge CLR or negedge T3) begin
    if(~CLR)
        EN_INT <= 0;
    else 
        EN_INT <= INTEN || EN_INT && ~INTDI;
end

assign				RECOVER = IRET && W[2];

always @(posedge PULSE or negedge CLR or posedge W[1] or posedge RECOVER) begin
	if(~CLR)
        CR3 <= 1;
	if(RECOVER)
		CR3 <= 1;
    else if(W[1]) begin
		if(INT)
			CR3 <= 0;
	end
end

always @(posedge P4 or negedge CLR or negedge T3) begin
	if(~CLR)
		INT <= 0;
	else if(P4) begin
		if(EN_INT && PULSE)
			INT <= 1;
	end
	else if(INT && W[2])
		INT <= 0;
end       

//输出信号控制
assign              DRW   = W_REG && (W[1] || W[2]) || (ADD || SUB || INC || AND) && W[2] || LD && W[3] || JMP && CR3 && W[2] || (JC && CC || JZ && CZ) && CR3 && W[2] || G_INS && CR3 && W[1] && ~INT;
assign              PCINC = G_INS && W[1] && ~INT;
assign              LPC   = JMP && W[2] || INT && G_INS && W[2] && ~CR3 || (JC && CC || JZ && CZ) && W[2] || IRET && W[2];
assign              LAR   = (R_RAM || W_RAM) && ~ST0 && W[1] || (LD || ST) && W[2];
assign              PCADD = 0;                 
assign              ARINC = (R_RAM || W_RAM) && ST0 && W[1];
assign              SELCTL= (R_REG || W_REG) && (W[1] || W[2]) || G_INS && CR3 && W[1] && ~INT || IRET && W[2];
assign              MEMW  = ST0 && (W_RAM && W[1] || ST && W[3]);
assign              STOP  = (R_REG || W_REG) && (W[1] || W[2]) || (R_RAM || W_RAM) && W[1] || STP && W[2] || INT && G_INS && W[2] && ~CR3;
assign              LIR   = G_INS && W[1] && ~INT;
assign              LDZ   = (ADD || SUB || AND || CMP) && W[2] || G_INS && CR3 && W[1] && ~INT;
assign              LDC   = (ADD || SUB || CMP) && W[2] || G_INS && CR3 && W[1] && ~INT;
assign              CIN   = ADD && W[2];
assign              S[3]  = (ADD || AND || LD || ST || JMP || OUT || (JC && CC || JZ && CZ)) && W[2] || ST && W[3] || IRET && W[2];
assign              S[2]  = (SUB || ST || CMP) && W[2] || IRET && W[2];
assign              S[1]  = (SUB || AND || LD || ST || JMP || OUT || (JC && CC || JZ && CZ) || CMP) && W[2] || ST && W[3] || IRET && W[2];
assign              S[0]  = (ADD || AND || ST) && W[2] || IRET && W[2];
assign              M     = (AND || LD || ST || JMP || OUT || (JC && CC || JZ && CZ)) && W[2] || ST && W[3] || IRET && W[2];
assign              ABUS  = (ADD || SUB || AND || INC || LD || ST || JMP || OUT || (JC && CC || JZ && CZ)) && W[2] || ST && W[3] || G_INS && CR3 && W[1] && ~INT || IRET && W[2];
assign              SBUS  = R_RAM && ~ST0 && W[1] || W_RAM && W[1] || W_REG || INT && G_INS && W[2] && ~CR3;
assign              MBUS  = R_RAM && ST0 && W[1] || LD && W[3];
assign              SHORT = (R_RAM || W_RAM) && W[1];
assign              LONG  = (LD || ST) && W[2];
assign              SEL[3]= W_REG && ST0 && (W[1] || W[2]) || R_REG && W[2] || G_INS && CR3 && W[1] && ~INT || IRET && W[2];
assign              SEL[2]= W_REG && W[2] || G_INS && CR3 && W[1] && ~INT || IRET && W[2];
assign              SEL[1]= W_REG && (~ST0 && W[1] || ST0 && W[2]) || R_REG && W[2];
assign              SEL[0]= W_REG && W[1] || R_REG && (W[1] || W[2]);

//中断控制信号
assign              INTDI = DI && W[2] || INT && W[1];
assign              INTEN = EI && W[2];

assign              P4    = (ADD || SUB || AND || INC || JMP || OUT || IRET || STP || (JC && ~C || JZ && ~Z) || CMP) && W[2] || (LD || ST || (JC && CC || JZ && CZ)) && W[3];

endmodule
