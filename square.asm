;Donald Carr
;square wave generator

.include "8535def.inc"

.def Tmp1 = R18;
.def Tmp2 = R19;
.def Tmp3 = R20;
.def Tmp4 = R21;
.def Tmp5 = R22;

.cseg
.org $000

Reset:	rjmp Start
	.org $011

Start:	ldi Tmp1,LOW(RAMEND)
	out SPL,Tmp1
	ldi Tmp1,HIGH(RAMEND)
	out SPH,Tmp1
	
	sbi DDRB,0
		
SquareWave:	sbi PORTB,0
		rcall HalfSecond
		cbi PORTB,0
		rcall HalfSecond
		rjmp SquareWave

HalfSecond : ldi Tmp5, 2
Outside		:	ser Tmp4
Inside		:	rcall Delay
			dec Tmp4
			brne Inside
			dec Tmp5
			brne Outside
			ret	     

Delay : ldi Tmp1, 76
Del1: 	ldi Tmp2, 17
Del2: 	ldi Tmp3,1 ; delay
Del3: 	dec Tmp3
	brne Del3
	dec Tmp2
	brne Del2
	dec Tmp1
	brne Del1
	ret
