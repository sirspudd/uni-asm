;Donald Carr

.include "8535def.inc"

.def	Mes = R0
.def	Temp1 = R16
.def	Temp2 = R17
.def	Temp3 = R18
.def	TimerCount = R19
.def	PwmStep = R20
.def	PwmValue = R21
.def	DispNum = R22
.def	SegPattern = R23
.def	tho = R24
.def	hun = R25
.def	ten = R26
.def	unit = R27

;See page 64 in Atmel manual to work out all baud rates

.equ	baud2400 = 207
.equ	baud4800 = 103
.equ	baud9600 = 51
.equ	baud14400 = 34		

;Constants

.equ	SPECIAL = 'u'		
.equ	VCHAR = 'V'		
.equ	OCHAR = 'R'		
.equ	BCHAR = 'B'		


		.cseg
		.org $000



Reset : 	rjmp	Start
	
		.org $001
		
		rjmp	EXT_INT0
		
		.org $009
		
		rjmp	TIM0_OVF
	
		.org $011
	
Start :		;initialise stack

		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1
		
		;Set baud rate
		;choose from constants declared above
		ldi 	Temp1,baud9600
		out	UBRR,Temp1
		
		;Enable the receiver and transmittor
		ldi 	Temp1,0b00011000
		out	UCR,Temp1
		
		;-------------------------------------------------------------------------------
		;Question 2 : specific initialisation : Ohm-meter
		
		sbi 	DDRA,3
		cbi 	PORTA,3
		
		;-------------------------------------------------------------------------------
		;Question 3 : specific initialisation : Ohm-meter
		
		;Hopefully configure a2d
		;SELECTS PORT A : PIN _ Change last three digits of ADMUX
		
		ldi 	Temp1,0b00000000
		out	ADMUX,Temp1
		;leave in peace, run freely little one
		ldi 	Temp1,0b11100000
		out	ADCSR,Temp1
				
		;-------------------------------------------------------------------------------
		;Question 4 : pushbutton specific initialisation
		;Push button port
		
		;int specific port
		;When changing : further changes must be made in body of code
		
		;cbi	DDRD,DDD3 ;int1
		;sbi	PORTD,3
		
		cbi	DDRD,DDD2 ;int 0
		sbi	PORTD,2
				
		;configuring int
		;use bits 3,2 for int1 and bit 1,0 for int0 
		
		in 	Temp1,MCUCR
		sbr 	Temp1,0b00000010;falling edge
		;sbr 	Temp1,0b00001000;falling edge ;int1 falling
		out 	MCUCR, Temp1
	
		;Setting interupt mask
		in 	Temp1,GIFR
		cbr 	Temp1,0b10111111 ;int0
		;cbr 	Temp1,0b01111111 ;int1
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
		
		;---------------------------------------------------------------------------------
		;Question 5
		
		;port C all out
		ser Temp1
		out DDRC,Temp1
		;Inputs 
		
		;Untrustworthy relics
			;ldi Temp1,0x00
			;out DDRB,Temp1
			;pullup resistors		
			;ser Temp1
			;out PORTB,Temp1
		
		in 	Temp1,DDRA
		sbr	Temp1,0xF0
		out 	DDRA,Temp1
		
		;pullup resistors		
		in 	Temp1,PORTA
		sbr	Temp1,0xF0
		out 	PORTA,Temp1
				
		;---------------------------------------------------------------------------------
		
		;---------------------------------------------------------------------------------
		;Question 6		
		;Choose your port
		sbi	DDRA,DDA2
		sbi	PORTA,2
				
		;---------------------------------------------------------------------------------
		
		
		;Sits here until char is received
			
Waitchar: 	rcall	Update
		sbis	USR,RXC
		rjmp	Waitchar
		;Load char in Temp reg & compare it to special char
		in	Temp1,UDR
		
		;specialchar
		;cpi	Temp1,117
		cpi	Temp1,SPECIAL
		brne	PostSpec
		rcall	SpecChar
		rjmp	Exit
PostSpec:			
		;V
		cpi	Temp1,VCHAR
		brne	PostVolt
		rcall	VMeter
		rjmp	Exit
PostVolt:		
		;R
		cpi	Temp1,OCHAR
		brne	PostOhm
		rcall	OhmMeter
		rjmp	Exit
PostOhm:			
		;B
		cpi	Temp1,BCHAR
		brne	PostBeep
		rcall	Beep
		;No output with Beep
		rjmp	Waitchar
PostBeep:		
		rcall	Waitclear
Exit:		rcall	LineFeed		
		rjmp	Waitchar


		
		;-------------------------------------------------------------------------------
		;First question

SpecChar:	mov	Temp2,Temp1
		ldi	Temp1,37
		rcall	Waitclear
		mov	Temp1,Temp2
		rcall	Waitclear
		ldi	Temp1,37
		rcall	Waitclear
		ret	

		;-------------------------------------------------------------------------------
		;Question 2 : Ohm meter : Rest at end of code
		
OhmMeter:	rcall	OhmBeg
		rcall	OhmCheck
		rcall	OhmEnd
		ret	

OhmBeg:		;Start counter
		;ldi	Temp1,0b00000011
		ldi	Temp1,0b00000101
		out	TCCR1B,Temp1
		;Zero value
		ldi	Temp1,0
		out	TCNT1H,Temp1
		out	TCNT1L,Temp1	
		
		;Enable capture
		;cbi	ACSR,0
		;sbi	ACSR,2
		
		;set input & begin to charge capacitor
		cbi 	DDRA,3
		
		ret

OhmCheck:	sbis	ACSR,ACO
		rjmp	OhmCheck
		
		
		;in	Temp1,ICR1L
		;in	Temp2,ICR1H
		
		in	Temp1,TCNT1L
		in	Temp2,TCNT1H
		
		mov 	Temp3, Temp1
		andi 	Temp3, 0b00000111
		
		;Very rough solution for clock/1024
		;divide by 8
		
		lsr	Temp2
		ror	Temp1	
		lsr	Temp2
		ror	Temp1	
		lsr	Temp2
		ror	Temp1	
				
		rcall 	Convert
		rcall 	OutLoop
		
		ldi	Temp1,'.'
		rcall	Waitclear
		
		;Send rough decimal value
		ldi ZH, HIGH(Decimaltbl * 2)
		ldi ZL, LOW(Decimaltbl * 2)
		
		add ZL, Temp3	
		clr Temp3
		adc ZH, Temp3	
		
		lpm
		
		mov Temp1, Mes
		rcall	Waitclear
					
		cbi	ACSR,ACO
		ret

OhmEnd:		;go high & charge resistor
		
		ldi	Temp1,0xb00
		out	TCCR1B,Temp1
			
		ldi	Temp1,0
		out	TCNT1H,Temp1
		out	TCNT1L,Temp1
		
		;Dischare capacitor
		sbi 	DDRA,3
		cbi 	PORTA, 3
		
		;Disable comparator
		;sbi	ACSR,0
		
		ret
				
		;-------------------------------------------------------------------------------
		;Third question : Voltometer

VMeter: 	sbis	ADCSR,ADIF
		rjmp	VMeter	
		rcall	carpe
		ret
		
carpe:		cbi	ADCSR,ADIF
		in	Temp1,ADCL
		in	Temp2,ADCH
		rcall	FourTimes
		rcall 	Convert
		rcall 	OutLoop
		ret

FourTimes:	lsl	Temp1
		rol	Temp2
		lsl	Temp1
		rol	Temp2
		ret

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
		ret	


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
		
		;-------------------------------------------------------------------------------
		
		;Question 4 : Push Button
		
		;-------------------------------------------------------------------------------
		
InteruptGo : 		in	Temp1,GIMSK
			sbr 	Temp1,0b01000000
			;sbr 	Temp1,0b10000000 ;int1
			out 	GIMSK,Temp1
			ret

InteruptStop : 		in	Temp1,GIMSK
			cbr 	Temp1,0b01000000
			;cbr 	Temp1,0b10000000 ;int1
			out 	GIMSK,Temp1
			ret

TIM0_OVF :		push	Temp1
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
	
CarryOn :		pop	Temp2
			pop	Temp1
			out	SREG,Temp1
			pop	Temp1
			reti


;press button interrupt

ZeroPwm:		clr	PwmStep
			clr	PwmValue
			rjmp	PostCheck
	
KnockUp:		ser	PwmValue
			rjmp	PostCheck
	
EXT_INT0:		push	Temp1
			in	Temp1,SREG
			push	Temp1
			push	Temp2
					
			;ignore button
			rcall	InteruptStop
			
			in 	Temp1,TCCR0;clk/64 takes 8us to inc 1 us
			sbr 	Temp1,0b0000011
			out	TCCR0,Temp1
			
			in 	Temp1,TCNT0
			sbr 	Temp1,0x00
			out	TCNT0,Temp1
			
			;Change duty cycle
			
			clr	TimerCount
			in 	Temp2,MCUCR
			in 	Temp1,MCUCR
			
			;If skips one, skips both	
			;using edgew detection just toggle last bit to change detection
			sbrc	Temp1,0
			cbr 	Temp2,0b00000001;falling edge
			sbrc	Temp1,0
			brne	Skip
			sbr 	Temp2,0b00000001;rising edge
	
			inc	PwmStep
			subi	PwmValue,-36
			cpi	PwmStep,7
			breq	KnockUp
			cpi	PwmStep,8
			breq	ZeroPwm
	
PostCheck:		out	OCR2,PwmValue
					
Skip:			ldi	TimerCount,60
			out 	MCUCR, Temp2
			
			pop	Temp2
			pop	Temp1
			out	SREG,Temp1
			pop	Temp1
			reti

		;-------------------------------------------------------------------------------
		;Question 5
		
Update:		clr DispNum
		sbis	PINA,4
		subi	DispNum,-1
		sbis	PINA,5
		subi	DispNum,-2
		sbis	PINA,6
		subi	DispNum,-4
		sbis	PINA,7
		subi	DispNum,-8
		cpi	DispNum,10
		brlo	Disp
		ldi	DispNum,10	
			
Disp:		ldi ZL,LOW(Sevensegtbl*2)
		ldi ZH,HIGH(Sevensegtbl*2)
		
		push DispNum
		lsl DispNum
		add ZL, DispNum
		pop DispNum
		
		clr Temp1
		adc ZH,Temp1
		
		lpm
		
		out PORTC, R0

		ret
		
		

;1 micro second on the noggin
Delay : ldi Temp1,76
Del1: 	ldi Temp2,17
Del2: 	ldi Temp3,1 ; delay
Del3: 	dec Temp3
	brne Del3
	dec Temp2
	brne Del2
	dec Temp1
	brne Del1
	ret


		;-------------------------------------------------------------------------------
		;Question 6
		
		;using unit in loop because variable are sparse
Beep:		rcall	InteruptStop
		ldi	unit,3
		;using 1 microsec delay, there 250 * 4 should work
		;VIP there is no off by one if you want for use 4, not 3
BeepLoop:	ldi	TimerCount,200
InnerBeep:	sbi	PORTA,2
		rcall	Delay
		cbi	PORTA,2
		rcall	Delay
		
		dec	TimerCount
		cpi	TimerCount,0
		brne	InnerBeep
		
		dec	unit
		cpi	unit,0
		brne	BeepLoop
		
		rcall	InteruptGo
		ret

		;-------------------------------------------------------------------------------
		;Communal methods

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

	


;Table for Question 5		
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
	.dw $4F		

Decimaltbl:
	.db "0011233455667889"
	.exit			
