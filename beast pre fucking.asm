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

.equ	baud = 207

	.cseg
	.org $000

Reset : rjmp	Start

	.org $001
	
	rjmp	EXT_INT0
	
	.org $009
	
	rjmp	TIM0_OVF

	.org $011
	
Start :		;initialise 
		ldi Temp1,LOW(RAMEND)
		out SPL,Temp1
		ldi Temp1,HIGH(RAMEND)
		out SPH,Temp1
		
		;Set baud rate
		ldi 	Temp1,baud
		out	UBRR,Temp1
		
		;Enable the receiver and transmittor
		ldi 	Temp1,0b00011000
		out	UCR,Temp1
		
		;Hopefully configure a2d
		ldi 	Temp1,0b00000000
		out	ADMUX,Temp1
		ldi 	Temp1,0b11100000
		out	ADCSR,Temp1
		
		
		;-------------------------------------------------------------------------------
		;Question 4 : pushbutton specific initialisation
		;Push button port
		cbi	DDRD,DDD2
		sbi	PORTD,2
				
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
		
		;---------------------------------------------------------------------------------
		;Question 5
		
		;port C all out
		ser Temp1
		out DDRC,Temp1
		;Inputs with pullup resistors
		ldi Temp1,0x00
		out DDRB,Temp1
		
		ser Temp1
		out PORTB,Temp1
		
		;---------------------------------------------------------------------------------
		
		;---------------------------------------------------------------------------------
		;Question 6		
		
		sbi	DDRA,DDA2
		sbi	PORTA,2
		
		
		;---------------------------------------------------------------------------------
		
		
		;Sits here until char is received
			
Waitchar: 	rcall	Update
		sbis	USR,RXC
		rjmp	Waitchar
		;Load char in Temp reg & compare it to special char
		in	Temp1,UDR
		;Special char represented by decimal number in cpi statement
		mov	Temp2,Temp1
		
		cpi	Temp1,117
		breq	SpecChar
		
		cpi	Temp1,86
		breq	pondernavel
		
		;breq is not get capable of doing jumps
		
		subi	Temp2,66
		sbrc	SREG,1
		rcall	Beep
		
		rcall	Waitclear
Common:		rcall	LineFeed		
Universal:	rjmp	Waitchar

;This is a generic send method, will be call with each send

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
		;-------------------------------------------------------------------------------
		
		;First question

SpecChar:	mov	Temp2,Temp1
		ldi	Temp1,37
		rcall	Waitclear
		mov	Temp1,Temp2
		rcall	Waitclear
		ldi	Temp1,37
		rcall	Waitclear
		rjmp	Common
		
		;-------------------------------------------------------------------------------
		
		;Second question
		
		;-------------------------------------------------------------------------------
		
		;Third question : Voltometer

pondernavel: 	sbis	ADCSR,ADIF
		rjmp	pondernavel	
		rcall	carpe
		rjmp	Common
		
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
		
		;Question 4
		
		;-------------------------------------------------------------------------------
		
InteruptGo : 		in	Temp1,GIMSK
			sbr 	Temp1,0b01000000
			out 	GIMSK,Temp1
			ret

InteruptStop : 		in	Temp1,GIMSK
			cbr 	Temp1,0b01000000
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
					
Skip:			ldi	TimerCount,6
			out 	MCUCR, Temp2
			
			pop	Temp2
			pop	Temp1
			out	SREG,Temp1
			pop	Temp1
			reti

		;-------------------------------------------------------------------------------
		
		;Question 5
		
		;-------------------------------------------------------------------------------
		
Update:		clr DispNum
		sbis	PINB,0
		subi	DispNum,-1
		sbis	PINB,1
		subi	DispNum,-2
		sbis	PINB,2
		subi	DispNum,-4
		sbis	PINB,3
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
		out PORTC, Mes
		ret
		
		;-------------------------------------------------------------------------------
		
		;Question 6
		
		;-------------------------------------------------------------------------------
		
Beep:		rcall	InteruptStop
		ldi	TimerCount,200
InnerBeep:	sbi	PORTA,2
		rcall	Delay
		cbi	PORTA,2
		rcall	Delay
		dec	TimerCount
		cpi	TimerCount,0
		brne	InnerBeep
		rcall	InteruptGo
		ret		

;1 micro second?
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
				
		.exit			
