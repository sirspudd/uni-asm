	.include "8535def.inc"

	.def	achar	=	r0
	.def	Temp1	=	r16
	.def	Temp2	=	r17
	.def	Count	=	r18
	
	.equ	baud = 207

	.dseg
	.org $060

Dallasbits:	.byte	16		
	
	
	.cseg
	.org $000
	
Reset : rjmp	Start
	
	.org	$011
Start:	ldi Temp1,LOW(RAMEND)
	out SPL,Temp1
	ldi Temp1,HIGH(RAMEND)
	out SPH,Temp1
	
	
	;Set baud rate
	ldi 	Temp1,baud
	out	UBRR,Temp1
	;Enable the receiver and transmittor
	ldi 	Temp1,0b00011000
	out	UCR,Temp1
	
	;start timer
	in 	Temp1,TCCR0;clk/8
	sbr 	Temp1,0b0000010
	out	TCCR0,Temp1
	
	in 	Temp1,TCNT0
	sbr 	Temp1,0x00
	out	TCNT0,Temp1
	;clr	TimerCount
	
	
	ldi 	ZL,LOW(Num2Ascii*2)
	ldi 	ZH,HIGH(Num2Ascii*2)
	
	clr	Temp1
	
	ldi 	XL,LOW(Dallasbits*2)
	ldi 	XH,HIGH(Dallasbits*2)
;detect chip
;sbi 	DDRB,0;output
;cbi 	DDRB,0;input
	
presence:	;make up 600 by multiplying these numbers
		cbi 	DDRB,0
		ldi	Count,3
high:		ldi	Temp1,2
		rcall Delay
		dec	Count
		brmi	low
		rjmp	high
low:		ldi	Count,3		
		sbi 	DDRB,0
		cbi 	PORTD,0
lowloop:	ldi	Temp1,2
		rcall Delay
		dec	Count
		brmi	presence
		rjmp	lowloop
		
;Use transparent delay	
;Delay:	push	Temp1
;	in	Temp1,SREG
;	push	Temp1
;	push	Temp2
	
;	pop	Temp2
;	pop	Temp1
;	out	SREG,Temp1
;	pop	Temp1
;	ret

Delay:	push	Temp2
	in	Temp2,SREG
	push	Temp2
	push	Temp1

	ldi 	Temp2,0
	sbc	Temp2,Temp1
	out	TCNT0,Temp2
	in	Temp2,TIFR
	sbr	Temp2,0b00000001
	out	TIFR,Temp2

Inner:	in	Temp1,TIFR

	sbrs	Temp1,0
	rjmp	Inner

	pop	Temp1
	pop	Temp2
	out	SREG,Temp2
	pop	Temp2
	ret
	
	;Chip reading method
	
ChipRead: ldi	Temp1,16
	  ldi	Temp2,4
	

	
Send:		sbis	USR,UDRE
		rjmp	Send
		out	UDR,Temp1
		ret
;ascii codes
Num2Ascii:	.db "0123456789ABCDEF"
	
	.exit
