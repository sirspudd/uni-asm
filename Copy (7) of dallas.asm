	.include "8535def.inc"

	.def	achar	=	r0
	.def	Temp1	=	r16
	.def	Temp2	=	r17
	.def	Count	=	r18
	.def	Count2	=	r19
	
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
	sbr 	Temp1,0b00000010
	out	TCCR0,Temp1
	
	in 	Temp1,TCNT0
	sbr 	Temp1,0x00
	out	TCNT0,Temp1
	;clr	TimerCount
	
	
;detect chip
;sbi 	DDRB,0;output
;cbi 	DDRB,0;input
	
presence:	;make up 600 by multiplying these numbers
		cbi 	DDRB,0
		cbi 	PORTB,0
		
		ldi	Count,5 ;6 hops
high:		ldi	Temp1,90
		rcall 	Delay
		dec	Count
		brmi	low
		rcall	detect
		rjmp	high
		
low:		sbi 	DDRB,0
		cbi 	PORTB,0
		
		ldi	Count,3		
lowloop:	ldi	Temp1,200
		rcall 	Delay
		dec	Count
		brmi	presence
		rjmp	lowloop

detect:		sbis	PINB,0
		rcall	handshake
		ret
;send 0F to chip
handshake:	rcall	zeros
		rcall	ones
		rcall	readchip
		rcall	serial
		ret
		
zeros:	ldi	Count,3;4 loops hopefully
zeroloop:	sbi 	DDRB,0 ;2 commands low
		cbi 	PORTB,0
		ldi	Temp1,100
		rcall	Delay
		cbi 	DDRB,0;high
		cbi	PORTB,0
		ldi	Temp1,10
		rcall	Delay
		dec	Count
		brpl	zeroloop
		ret
		
ones:	ldi	Count,3;4 loops hopefully
onesloop:	sbi 	DDRB,0 ;2 commands low
		cbi 	PORTB,0
		
		ldi	Temp1,5
		rcall	Delay
		
		cbi 	DDRB,0;high
		cbi	PORTB,0
		
		ldi	Temp1,100
		rcall	Delay
		dec	Count
		brpl	zeroloop
		ret

readchip: 	ldi 	XL,LOW(Dallasbits) ;Correction
		ldi 	XH,HIGH(Dallasbits)
		ldi	Count,15;16 will make register negative

readmes:  ldi	Count2,3 ;4 bits
	  clr	Temp2
	  ;Temp2 used to house signal
readloop:	  
	  sbi 	DDRB,0 ;2 commands low
	  cbi 	PORTB,0
	  ldi	Temp1,5
	  rcall	Delay
	  
	  cbi 	DDRB,0
	  cbi	PORTB,0
		
	  ldi	Temp1,5
	  rcall	Delay
	  
	  ;set one by default
	  sbic	PINB,0
	  sbr	Temp2,0b10000000
	  lsr	Temp2		  
	  
	  ldi	Temp1,70
	  rcall	Delay
	  
	  dec	Count2
	  brpl	readloop
	  
	  swap	Temp2
	  st	X+,Temp2
	  
	  dec	Count
	  brpl	readmes	  	  
	  ret



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
	
serial: ldi 	XL,LOW(Dallasbits) ;Correction
	ldi 	XH,HIGH(Dallasbits)
	ldi	Count,15
	;loop with the hex chars
serialloop:		;ldi	Temp1,1
			;add 	XL, Temp1
			;clr 	Temp1
			;adc 	XH,Temp1
			ld	Temp1,X+
			
			ldi 	ZL,LOW(Num2Ascii*2)
			ldi 	ZH,HIGH(Num2Ascii*2)
			
			add 	ZL, Temp1
			clr 	Temp1
			adc 	ZH,Temp1
			lpm	
			mov	Temp1,achar
			rcall	Send
			dec	Count
			brpl	serialloop
			;else exit

LineFeed:	sbis	USR,UDRE
		rjmp	LineFeed
		ldi	Temp1,$0D
		out	UDR,Temp1
		
Carriage:	sbis	USR,UDRE
		rjmp	Carriage
		ldi	Temp1,$0A
		out	UDR,Temp1

			ret
	
Send:		sbis	USR,UDRE
		rjmp	Send
		out	UDR,Temp1
		ret
;ascii codes
Num2Ascii:	.db "0123456789ABCDEF"
	
	.exit
