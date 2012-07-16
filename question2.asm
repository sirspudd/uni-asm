;Donald Carr
;Interupt handling

.include "8535def.inc"
.def	Temp1 = R16
.def	Temp2 = R17
.def	Temp3 = R18
.def	tho = R19
.def	hun = R20
.def	ten = R21
.def	unit = R22

.equ	baud = 207	
	.cseg
	.org $000

Reset : rjmp	Start
	
	.org $011
	
Start : ldi Temp1,LOW(RAMEND)
	out SPL,Temp1
	ldi Temp1,HIGH(RAMEND)
	out SPH,Temp1
	
	;Set baud rate
	ldi 	Temp1,baud
	out	UBRR,Temp1
	;Enable the receiver and transmittor
	ldi 	Temp1,0b00011000
	out	UCR,Temp1
	;A out
	sbi 	DDRA,3
	cbi 	PORTA,3
	

Loop:	rcall	Waitchar
	rcall	Begin
	rcall	Check
	rcall	End
	rjmp	Loop	

Waitchar: 	sbis	USR,RXC
		rjmp	Waitchar
		out	UDR,Temp1
		ret

Begin:	;go high & charge resistor
	;in 	Temp1,TCCR1B;clk/64 takes 8us to inc 1 us
	;sbr 	Temp1,0b00000001
	;out	TCCR1B,Temp1
	
	ldi	Temp1,0b00000101
	out	TCCR1B,Temp1
		
	ldi	Temp1,0
	out	TCNT1H,Temp1
	out	TCNT1L,Temp1	
	
	cbi 	DDRA,3
	
	ret

Check:	sbis	ACSR,ACO
	rjmp	Check
	in	Temp1,ICR1L
	in	Temp2,ICR1H
	rcall 	Convert
	rcall 	OutLoop
	cbi	ACSR,ACO
	ret

End:	;go high & charge resistor
	sbi 	DDRA,3
	cbi 	PORTA, 3
	
	;in 	Temp1,TCCR1B;turn off counter
	;sbr 	Temp1,0x00
	;out	TCCR1B,Temp1
	ldi	Temp1,0xb00
	out	TCCR1B,Temp1
		
	ldi	Temp1,0
	out	TCNT1H,Temp1
	out	TCNT1L,Temp1
	
	ret

;-----Sending

OutLoop:	mov	Temp1,Tho
		subi	Temp1,-48
		rcall	Waitclear
		mov	Temp1,hun
		subi	Temp1,-48
		rcall	Waitclear
		mov	Temp1,ten
		subi	Temp1,-48
		rcall	Waitclear
		mov	Temp1,unit
		subi	Temp1,-48
		rcall	Waitclear
		rcall	LineFeed
		ret	


;This is a generic send method, will be call with each send
Waitclear:	sbis	USR,UDRE
		rjmp	Waitclear
		out	UDR,Temp1
		ret
		
LineFeed:	sbis	USR,UDRE
		rjmp	LineFeed
		ldi	Temp1,$0D
		out	UDR,Temp1
		
Carriage:	sbis	USR,UDRE
		rjmp	Carriage
		ldi	Temp1,$0A
		out	UDR,Temp1
		
		ret

;=====Sending

Convert:	push	Temp1
		push	Temp2
		push	Temp3
		
		clr	tho
		clr	hun
		clr	ten
		clr	unit

DoThou:		subi	Temp1,LOW(1000)
		sbci	Temp2,HIGH(1000)
		brcs	NowHun
		inc	tho
		rjmp	DoThou
		
NowHun:		ldi	Temp3,LOW(1000)
		add	Temp1,Temp3
		ldi	Temp3,HIGH(1000)
		adc	Temp2,Temp3
		

DoHun:		subi	Temp1,100
		sbci	Temp2,0
		brcs	NowTen
		inc	hun
		rjmp	DoHun
		
NowTen:		ldi	Temp3,100
		add	Temp1,Temp3
		
DoTen:		subi	Temp1,10
		brcs	NowUnit
		inc	ten
		rjmp	DoTen
		
NowUnit:	ldi	Temp3,10
		add	Temp1,Temp3
		mov	unit, Temp1
		
		pop	Temp1
		pop	Temp2
		pop	Temp3
		
		ret
	
	.exit	
