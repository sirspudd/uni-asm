;Donald Carr
;Dumb terminal

.include "8535def.inc"

.def	Mes = R0
.def	Temp1 = R16
.def	TransitChar = R17
.def	Count = R18
.def	DispNum = R19
.def	SegPattern = R20
.equ	baud = 207

.cseg
.org $000

Reset : rjmp	Start

	.org $011
	
Start :		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1
		
		ser Temp1
		out DDRC,Temp1
		clr DispNum
		
		;Set baud rate
		ldi 	Temp1,baud
		out	UBRR,Temp1
		;Enable the receiver and transmittor
		ldi 	Temp1,0b00011000
		out	UCR,Temp1

;Sits here until char is received

			
Waitchar: 	sbis	USR,RXC
		rjmp	Waitchar
		;for each input
		clr	Count
		in	Temp1,UDR
		mov	TransitChar,Temp1
		;Segment handler
		
				
		;Beginning of retransmittion
		ldi 	ZL,LOW(Message*2)
		ldi 	ZH,HIGH(Message*2)
	

OutLoop:	;ldi 	ZL,LOW(Message*2)
		;ldi 	ZH,HIGH(Message*2)
		lpm
		ldi	Temp1,1
		add 	ZL, Temp1
		clr 	Temp1
		adc 	ZH,Temp1
		inc	Count
		mov	Temp1,Mes
		cpi	Temp1,$1B
		breq	ExitPoint
		
;				
;This is a generic send method, will be call with each send
Waitclear:	sbis	USR,UDRE
		rjmp	Waitclear
		out	UDR,Temp1
		rjmp	OutLoop
		;rjmp	Waitchar
		
ExitPoint:	sbis	USR,UDRE
		rjmp	ExitPoint
		out	UDR,TransitChar
		
LineFeed:	sbis	USR,UDRE
		rjmp	LineFeed
		ldi	Temp1,$0D
		out	UDR,Temp1
		
Carriage:	sbis	USR,UDRE
		rjmp	Carriage
		ldi	Temp1,$0A
		out	UDR,Temp1
		
		;update 7 segment display
		ldi ZL,LOW(Sevensegtbl*2)
		ldi ZH,HIGH(Sevensegtbl*2)
		
		;ldi	DispNum,2
		
		subi	TransitChar,$30
		;experiment
		cpi	TransitChar,0
		brlt	Reincarnation
		cpi	TransitChar,10
		brge	Reincarnation
		mov	DispNum,TransitChar
						
		push DispNum
		lsl DispNum
		add ZL, DispNum
		pop DispNum
		clr Temp1
		adc ZH,Temp1
		
		lpm
		out PORTC, Mes
		
						
Reincarnation:	rjmp	Waitchar

		
Message: .db "you just typed a :",$1B

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
	
.exit			
		