;Donald Carr
;Dumb pwm

.include "8535def.inc"

.def	Temp1 = R16
.def	Temp2 = R17

.cseg
.org $000

Reset : rjmp	Start

	.org $011
	
Start :		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1

		sbi	DDRD,PD7
		ldi	Temp1,0b01100001
		out	TCCR2,Temp1
		;Hopefully configure a2d to run wild
		ldi 	Temp1,0b00000000
		out	ADMUX,Temp1
		ldi 	Temp1,0b11100000
		out	ADCSR,Temp1

;repeat ad finitum

pondernavel: 	sbic	ADCSR,ADIF
		rcall	carpe
		rjmp	pondernavel	

updatepwm:	in	Temp1,ADCL
		in	Temp2,ADCH
		ror	Temp2
		ror	Temp1
		ror	Temp2
		ror	Temp1
		out	OCR2,Temp1
		ret

carpe:		cbi	ADCSR,ADIF
		rcall 	updatepwm
		ret

.exit			
		