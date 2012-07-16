;Donald Carr
;Dumb terminal

.include "8535def.inc"

.def	Mes = R0
.def	Temp1 = R16
.def	DispNum = R19
.def	SegPattern = R20

.cseg
.org $000

Reset : rjmp	Start

	.org $011
	
Start :		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1
		
		;port C all out
		ser Temp1
		out DDRC,Temp1
		;Inputs with pullup resistors
		ldi Temp1,0x00
		out DDRB,Temp1
		
		ser Temp1
		out PORTB,Temp1
		
		
Loop:		rcall	Update
		rjmp	Loop

Update:		clr DispNum
		sbis	PINB,0
		subi	DispNum,-1
		sbis	PINB,1
		subi	DispNum,-2
		sbis	PINB,2
		subi	DispNum,-4
		sbis	PINB,3
		subi	DispNum,-8
		cpi	DispNum,10
		brlo	Disp
		ldi	DispNum,10		
Disp:		ldi ZL,LOW(Sevensegtbl*2)
		ldi ZH,HIGH(Sevensegtbl*2)
		push DispNum
		lsl DispNum
		add ZL, DispNum
		pop DispNum
		clr Temp1
		adc ZH,Temp1
		lpm
		out PORTC, Mes
		
Sevensegtbl:
	.dw $7E
	.dw $30
	.dw $6D
	.dw $79
	.dw $33
	.dw $5B
	.dw $5F
	.dw $70
	.dw $7F
	.dw $73
	.dw $4F
.exit			
		