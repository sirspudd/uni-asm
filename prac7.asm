;Donald Carr
;Half Second delay on original led flasher

.include "8535def.inc"

.def Tmp1 = R16;
.def Tmp2 = R17;
.def Tmp3 = R18;
.def Tmp4 = R19;
.def Tmp5 = R20;

.cseg
.org $000

Reset : rjmp Start

Start : ldi Tmp1,LOW(RAMEND)
	out SPL, Tmp1
	ldi Tmp1,HIGH(RAMEND)
	out SPH, Tmp1

	sbi DDRB,0

Flash :	cbi PORTB,0
	rcall HSecond
	sbi PORTB,0
	rcall HSecond
	rjmp Flash

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

.exit