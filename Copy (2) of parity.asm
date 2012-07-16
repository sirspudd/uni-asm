;Donald Carr parity work
	.include "8535def.inc"
	
.def	Temp1 = R16
.def	Count = R17

	.cseg
	.org $000
Reset :	rjmp	Start
	.org $011
Start :		ldi Temp1,62
		rcall Genodd
		rjmp	Start

Geneven :	clr	Count
;lsr method
;		lsr	Temp1;bit 6
;		brcc	bit5
;		inc	Count
;		
;bit5:		lsr	Temp1
;		brcc	bit4
;		inc	Count
;		
;bit4:		lsr	Temp1
;		brcc	bit3
;		inc	Count
;		
;bit3:		lsr	Temp1
;		brcc	bit2
;		inc	Count
;		
;bit2:		lsr	Temp1
;		brcc	bit1
;		inc	Count
;		
;bit1:		lsr	Temp1
;		brcc	bit0
;		inc	Count
;		
;bit0:		lsr	Temp1
;		brcc
;		inc	Count
		;Clears first byte if occupied
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
		;If odd set first bit 1
		sbrc	Count,0
		;work around no adi
		subi	Temp1,-128
		ret
		
		
		
Genodd :	clr	Count
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
		;If odd set first bit 1
		sbrs	Count,0
		;work around no adi
		subi	Temp1,-128
		ret


	
	.exit