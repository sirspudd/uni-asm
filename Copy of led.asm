.include "8535def.inc"

.def Tmp1 = R16;
.def Tmp2 = R17;
.def Tmp3 = R18;

.cseg
.org $000

Reset : rjmp Start

Start : ldi Tmp1,LOW(RAMEND)
	out SPL, Tmp1
	ldi Tmp1,HIGH(RAMEND)
	out SPH, Tmp1

	sbi DDRD,6

Flash :	cbi PORTD,6
	rcall Delay
	sbi PORTD,6
	rcall Delay
	rjmp Flash

Delay : ser Tmp1
Del1: 	ser Tmp2
Del2: 	ldi Tmp3,1
Del3: 	dec Tmp3
	brne Del3
	dec Tmp2
	brne Del2
	dec Tmp1
	brne Del1
ret

.exit