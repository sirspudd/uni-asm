		.nolist
		.include "8535def.inc"
		.list
		.org $000
Start :	rjmp	Label

		.org 	$020
Label:	push	R16
		clr		R16
		ldi		R16,175
		add		R16,R17
		cpi		R16,$FB
		breq	subroutine
		pop		R18
		rjmp	Label
subroutine:	nop
			in R18, PINB
			sbr R18,0b10101010
			out	PORTC,R18
			sbi	PORTB,PB3

			ret
