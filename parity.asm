;Donald Carr parity work
	.include "8535def.inc"
	
.def	Temp1 = R16
.def	Count = R17

	.cseg
	.org $000
Reset :	rjmp	Start

	.org $011
Start :		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1

		ldi Temp1,62
		rcall Genodd
		rjmp	Start
		
		

Geneven :	rcall Parity
		;If odd set first bit 1
		sbrc	Count,0
		;work around no adi
		subi	Temp1,-128
		ret
		
Genodd :	rcall Parity
		;If odd set first bit 1
		sbrs	Count,0
		;work around no adi
		subi	Temp1,-128
		ret

Parity : 	clr	Count
		sbrc	Temp1,7
		subi	Temp1,128
		sbrc	Temp1,6
		inc	Count
		sbrc	Temp1,5
		inc	Count
		sbrc	Temp1,4
		inc	Count
		sbrc	Temp1,3
		inc	Count
		sbrc	Temp1,2
		inc	Count
		sbrc	Temp1,1
		inc	Count
		sbrc	Temp1,0
		inc	Count
		ret		
	
	.exit