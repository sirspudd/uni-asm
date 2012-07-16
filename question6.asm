;Donald Carr
;Interupt handling

.include "8535def.inc"
.def 	Temp1 = R16
.def 	Temp2 = R17
.def	TimerCount = R18
.def	PwmStep = R19
.def	PwmValue = R20
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
	
;B out
	sbi	DDRB,DDB2
	cbi	PORTB,2

;configuring int0
	in 	Temp1,MCUCR
	sbr 	Temp1,0b00000010;falling edge
	out 	MCUCR, Temp1

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
	
;Get Pwm square wave out of PD7	
	sbi	DDRD,PD7
;Start Timer 2
	ldi	Temp1,0b01100001
	out	TCCR2,Temp1
	
	clr	PwmStep
	clr	PwmValue
	out	OCR2,PwmValue

Loop :		rcall	InteruptStop
		
		in 	Temp1,TCCR0;clk/64 takes 8us to inc 1 us
		sbr 	Temp1,0b0000101
		out	TCCR0,Temp1
		
		in 	Temp1,TCNT0
		sbr 	Temp1,0x00
		out	TCNT0,Temp1
		ldi	TimerCount,6
		rjmp Loop

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
		;Stop timer
		in 	Temp1,TCCR0
		cbr 	Temp1,0b00000001
		out	TCCR0,Temp1

		
		
.exit	