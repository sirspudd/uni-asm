;Donald Carr
;Interupt handling

.include "8535def.inc"
.def 	SegPattern = R0
.def 	Temp1 = R16
.def 	Temp2 = R17
.def	CountPress = R18
.def	TimerCount = R19
.def Tmp1 = R20;
.def Tmp2 = R21;
.def Tmp3 = R22;
.def Tmp4 = R23;

	.cseg
	.org $000

Reset : rjmp	Start
	
	.org $001
	
	rjmp	EXT_INT0
	
	.org $009
	
	rjmp	TIM0_OVF
	
	.org $011
	;init
Start : ldi Temp1,LOW(RAMEND)
	out SPL,Temp1
	ldi Temp1,HIGH(RAMEND)
	out SPH,Temp1
	
	ldi CountPress,9
	
	ser Temp1
	out DDRC,Temp1
	
	ldi ZL,LOW(Sevensegtbl*2)
	ldi ZH,HIGH(Sevensegtbl*2)
	
	push CountPress
	lsl CountPress
	add ZL, CountPress
	pop CountPress
	clr Temp1
	adc ZH,Temp1
	
	lpm
	out PORTC, SegPattern
	
;D in
	cbi	DDRD,DDD2
	sbi	PORTD,2
;B out
	sbi 	DDRB,0

;configuring int0
	in 	Temp1,MCUCR
	sbr 	Temp1,0b00000010;falling edge
	out 	MCUCR, Temp1

;enable int0
;	in	Temp1,GIMSK
;	sbr 	Temp1,0b01000000
;	out 	GIMSK,Temp1

;Setting interupt mask
	in 	Temp1,GIFR
	cbr 	Temp1,0b10111111
	out	GIFR,Temp1
;Enabling timer overfill interupts
	in 	Temp1,TIMSK
	sbr 	Temp1,0b00000001
	out	TIMSK,Temp1
	rcall InteruptGo
	sei

Flash :	cbi PORTB,0
	rcall HSecond
	sbi PORTB,0
	rcall HSecond
	rjmp Flash

InteruptGo : 		in	Temp1,GIMSK
			sbr 	Temp1,0b01000000
			out 	GIMSK,Temp1
			ret

InteruptStop : 		in	Temp1,GIMSK
			cbr 	Temp1,0b01000000
			out 	GIMSK,Temp1
			ret

				

TIM0_OVF :	push	Temp1
		in	Temp1,SREG
		push	Temp1
		push	Temp2
		dec 	TimerCount
		;compare
		cpi 	TimerCount,0
		;If not equal jump else clear
		brne 	CarryOn	
		rcall	InteruptGo
		in 	Temp1,TCCR0
		cbr 	Temp1,0b00000001
		out	TCCR0,Temp1
CarryOn :	pop	Temp2
		pop	Temp1
		out	SREG,Temp1
		pop	Temp1
		reti


;press button interrupt


EXT_INT0 :	push	Temp1
		in	Temp1,SREG
		push	Temp1
		push	Temp2
				
		;ignore button
		rcall	InteruptStop
		dec 	CountPress
		;compare
		cpi 	CountPress,0
		;If not equal jump else clear
		brne 	Display
		ldi 	CountPress,9
Display :	push 	CountPress
		lsl 	CountPress
		add 	ZL, CountPress
		pop 	CountPress
		clr 	Temp1
		adc 	ZH,Temp1
		lpm
		out 	PORTC,SegPattern
		;initialise counter for interupt timer
		ldi	TimerCount,6
		ldi 	ZL,LOW(Sevensegtbl*2)
		ldi 	ZH,HIGH(Sevensegtbl*2)
		
		in 	Temp1,TCCR0;clk/64 takes 8us to inc 1 us
		sbr 	Temp1,0b0000101
		out	TCCR0,Temp1
		in 	Temp1,TCNT0
		sbr 	Temp1,0x00
		out	TCNT0,Temp1
		clr	TimerCount
		
		pop	Temp2
		pop	Temp1
		out	SREG,Temp1
		pop	Temp1
		reti

;press button interrupt


HSecond	:	ldi	Tmp4,200
Inner	:	rcall Delay
		dec	Tmp4
		brne	Inner
		ret

Delay : ldi Tmp1,76
Del1: 	ldi Tmp2,17
Del2: 	ldi Tmp3,1 ; delay
Del3: 	dec Tmp3
	brne Del3
	dec Tmp2
	brne Del2
	dec Tmp1
	brne Del1
	ret

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
