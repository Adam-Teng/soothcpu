/* ****************************************************************************
-                                   С���Ա
-                               2020211651�����                
-                               2020211650�Ʒ�
-                               2020211654�Ϸ���                
-                               2020211659���
******************************************************************************/

/******************************************************************************
- 	��һ�����񣺱�ѡ��Ŀ
-	�������ܣ�
-		���ո������ݸ�ʽ��ָ��ϵͳ������ͨ·���������ṩ������Ҫ��
- 		�������һ������Ӳ���߿�������˳��ģ�ʹ������
-	���ӹ��ܣ�
- 		��ԭָ���������ָ����������
- 		�����û��ڳ���ʼʱָ��PCָ���ֵ��
******************************************************************************/

module task1CPU(//�˿ڶ���
            CLR,        //#CLR
            T3,         //���� 
            SW,         //����̨�ź� 3--C 2--B 1--A
            IR,         //����λָ��Ĵ��� 7..4
            W,          //���� 3..1
            C,  Z,      //������

            DRW,        //д��Ĵ���
            PCINC,      //���������+1�ź�
            LPC,        //��������������ź�
            LAR,        //��ַ�Ĵ��������ź�
            PCADD,      //ƫ���������¸�pcָ�븳ֵ
            ARINC,      //��ַ�Ĵ���+1�ź�
            SELCTL,     //����̨��ʽʱΪ1
            MEMW,       //����˿�д���ź�
            STOP,       //ͣ��
            LIR,        //ָ��Ĵ����������ź�
            LDZ,        //��������λ���
            LDC,        //������
            CIN,        //��λ
            S,          //�����������ź� 3..0
            M,          //��������
            ABUS,       //��������������
            SBUS,       //�������뿪���ź�
            MBUS,       //����˿ڶ�������
            SHORT,      //һ��CPU���ڵ�ָ��
            LONG,       //����CPU���ڵ�ָ��
            SEL         //ѡ��Ĵ��� 3..0
            );
input               CLR, C, Z, T3;
input   [3:1]       SW, W;
input   [7:4]       IR;

output              DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP;
output				LIR, LDZ, LDC, CIN, M, ABUS, SBUS, MBUS, SHORT, LONG;
output  [3:0]       S, SEL;

//�м����
wire                W_REG, R_REG, W_RAM, R_RAM, G_INS; 
wire                ADD, SUB, AND, INC, LD, ST, JC, JZ, JMP, STP;
wire                OUT;
reg                 ST0;

//����ģʽ
assign              W_REG = (SW == 3'b100);     //д�Ĵ���
assign              R_REG = (SW == 3'b011);     //���Ĵ���
assign              W_RAM = (SW == 3'b001);     //д�洢��
assign              R_RAM = (SW == 3'b010);     //���洢��
assign              G_INS = (SW == 3'b000);     //ȡָ

//ָ��
assign              ADD = (IR == 4'b0001) && G_INS && ST0;      //�ӷ�
assign              SUB = (IR == 4'b0010) && G_INS && ST0;      //����
assign              AND = (IR == 4'b0011) && G_INS && ST0;      //�߼���
assign              INC = (IR == 4'b0100) && G_INS && ST0;      //��1
assign              LD  = (IR == 4'b0101) && G_INS && ST0;      //ȡ��
assign              ST  = (IR == 4'b0110) && G_INS && ST0;      //����
assign              JC  = (IR == 4'b0111) && G_INS && ST0;      //C����ת��
assign              JZ  = (IR == 4'b1000) && G_INS && ST0;      //Z����ת��
assign              JMP = (IR == 4'b1001) && G_INS && ST0;      //������ת��
assign              STP = (IR == 4'b1110) && G_INS && ST0;      //ͣ��

//��������ָ��
assign              OUT = (IR == 4'b1010) && G_INS && ST0;      //���



//ST0��״̬
//����CLRʱ
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

