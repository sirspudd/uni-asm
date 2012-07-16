;Donald Carr
;Dumb terminal

.include "8535def.inc"

.def	Temp1 = R16
.def	Temp2 = R17
.equ	baud = 207

.cseg
.org $000

Reset : rjmp	Start

	.org $011
	
Start :		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1
		
		;Set baud rate
		ldi 	Temp1,baud
		out	UBRR,Temp1
		;Enable the receiver and transmittor
		ldi 	Temp1,0b00011000
		out	UCR,Temp1

;Sits here until char is received
			
Waitchar: 	sbis	USR,RXC
		rjmp	Waitchar
		;Load char in Temp reg & compare it to special char
		in	Temp1,UDR
		;Special char represented by decimal number in cpi statement
		cpi	Temp1,117
		breq	SpecChar
		rcall	Waitclear
Common:		rcall	LineFeed		
		rjmp	Waitchar
;				
;This is a generic send method, will be call with each send
Waitclear:	sbis	USR,UDRE
		rjmp	Waitclear
		out	UDR,Temp1
		ret

SpecChar:	mov	Temp2,Temp1
		ldi	Temp1,37
		rcall	Waitclear
		mov	Temp1,Temp2
		rcall	Waitclear
		ldi	Temp1,37
		rcall	Waitclear
		rjmp	Common
		
		
LineFeed:	sbis	USR,UDRE
		rjmp	LineFeed
		ldi	Temp1,$0D
		out	UDR,Temp1
		
Carriage:	sbis	USR,UDRE
		rjmp	Carriage
		ldi	Temp1,$0A
		out	UDR,Temp1
		ret
		
		.exit			
		