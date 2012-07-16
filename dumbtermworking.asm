;Donald Carr
;Dumb terminal

.include "8535def.inc"

.def	Mes = R0
.def	Temp1 = R16
.def	TransitChar = R17
.def	Count = R18
.equ	baud = 207

.cseg
.org $000

Reset : rjmp	Start

	.org $011
	
Start :	;Set baud rate
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
						
		rjmp	Waitchar

		
Message: .db "you just typed a :",$1B		
		