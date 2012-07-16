;Program which increments a counter, debouncing a switch using
;timing loop interrupts
;Oliver King

	.include "8535def.inc"
	
	.def 	Temp1 = R16
	.def	NumC = R17
	.def	Tmp1 = R18
	.def	Tmp2 = R19
	.def	Tmp3 = R20
	.equ	MaxC = 200 	;Number of iterations of our 1ms delay loop
	.def 	SegPattern = R0
	.def 	CountPress = R21
	.equ 	MaxCount = 10
	.def	NumTicks = R22
	.equ	MaxTicks = 25	;equals a debounce of approx 200 ms at fc/256
	.def	IntFlag = R23	;Flagged when interrupts are disallowed
	
	.cseg
	.org 	$000
Reset:	rjmp 	Start

	.org	$001
	rjmp	EXT_INT0	;External interrupt 0 handler

	.org	$009
	rjmp	TIM0_OVF	;Timer 0 overflow interrupt handler
	
	.org	$011		;Place the code after the interrupt vectors
	
Start:	ldi	Temp1,LOW(RAMEND)
	out	SPL,Temp1
	ldi	Temp1,HIGH(RAMEND)
	out	SPH,Temp1

	;Do the configuration necessary for the counter
	clr	CountPress	;begin with a zero count on CountPress
	clr	IntFlag		;Flag is all zero's, interrupts allowed
	;configure port C bits 0 to 7 as outputs
	ser	Temp1		;makes temp1 all 1's
	out	DDRC,Temp1	;set as outputs	
	;point the Z register at the first entry of the lookup table
	ldi	ZL,LOW(Sevenseg*2)
	ldi	ZH,HIGH(Sevenseg*2)	
	;write 0 to the output to begin
	lpm			;loads Z destination into R0
	out	PORTC,SegPattern

	;Configure PORTB, bit 0 to be an output for the square wave
	sbi	DDRB,DDB0	;Sets bit 0 in DDRB to 1, thus output
	cbi	PORTB,0		;Set bit 0 to 0 initially
	;Configure PORTB, bit 1 to be an output, flag for the INT_0 off
	sbi	DDRB,DDB1
	cbi	PORTB,1
	
	;Perform the configuration necessary to make INT0 an input,
	;make the INT0 interrupt work on a falling edge, set the masks
	;to enable the interrupts and enable interrupts globally.

	;Make INT0 an input. INT0 is PORTD line PD2. Enable pullup resistor
	cbi	DDRD,DDD2	;PORTD Bit 2 an input
	sbi	PORTD,2		;Turn on the pullup resistor

	;Configure to interrupt on a falling edge
	in	Temp1,MCUCR	;Get the current config of MCUCR
	sbr	Temp1,0b00000010	;Temp1 = Temp1 OR 0b00000010
	out	MCUCR,Temp1	;Write out the new config

	;Configure the general interrupt mask register and the timing mask
	in	Temp1,GIMSK
	sbr	Temp1,0b01000000
	out	GIMSK,Temp1
	in	Temp1,TIMSK
	sbr	Temp1,0b00000001
	out	TIMSK,Temp1
	
	;Stop the timer and clear any interrupts which may be queued
	in	Temp1,TCCR0	;get the current config of timer 0
	sbr	Temp1,0b00000000	;STOP THE CLOCK!
	out	TCCR0,Temp1	;write out the new timer config
	;Clear the interrupt bit
	in	Temp1,GIFR
	sbr	Temp1,0b01000000
	out	GIFR,Temp1

	;Now enable interrupts globally
	sei

Main:	;Do stuff in main to show that stuff is happening
	;We need to toggle PORT B bit 0 every 200 ms
	;Clear bit, delay, set bit, delay
	cbi	PORTB,0
	rcall	Delaye
	sbi	PORTB,0
	rcall	Delaye
	rjmp	Main


;This code is what is called whenever interrupts occur

;The press button interrupt handler
EXT_INT0:	push Temp1	;Temp1 is our working register, save it
	in	Temp1,SREG	;Load the system register into Temp1
	push	Temp1		;Save the system register
	
	;DO STUFF: Note that only falling edge interrupts will be generated
	;1) Disable INT_0
	in	Temp1,GIMSK
	cbr	Temp1,0b01000000
	out	GIMSK,Temp1
	ldi	IntFlag,0b11111111	;Wasteful flag set. No interupt allowed
	sbi	PORTB,1			;PORTB1 will be high whever interrupts
					;are not allowed

	;2) Update display
	inc 	CountPress
	cpi	CountPress,MaxCount	; Is CountPress < MaxCount?
	brne	Display			; no
	clr	CountPress		; yes

Display: push	CountPress	;push value onto stack
	lsl	CountPress	;Logical Shift Left (x2)
	add	ZL,CountPress	;Adjust pointer to point to lookup table
	pop	CountPress	;restore value from stack
	clr	Temp1
	adc	ZH,Temp1	;Add the carry bits to ZH
	lpm			;Puts value of Z into R0
	out	PORTC,SegPattern
		
	;now reset pointer Z to first spot in stack
	ldi	ZL,LOW(Sevenseg*2)
	ldi	ZH,HIGH(Sevenseg*2)

	;3) Initialise and start TIMER 0
	;Set the initial count to zero
	ldi	Temp1,0b00000000
	out	TCNT0,Temp1
	clr	NumTicks	;set the number of overflows to zero
	;We need to select a clock speed
	in	Temp1,TCCR0	;get the current config of timer 0
	sbr	Temp1,0b00000100	;select CK/256 as the clock speed
	out	TCCR0,Temp1	;write out the new timer config (starts timer)

	;4) Return from interrupt
	pop	Temp1		;Pop the system register into Temp1
	out	SREG,Temp1	;Load it back into memory
	pop	Temp1		;restore the working register
	reti

TIM0_OVF:	push Temp1	;yada, same as before
	in	Temp1,SREG
	push	Temp1

	;Increment the number of clock overflow interrupts
	inc	NumTicks

	;Stop the timer
	in	Temp1,TCCR0	;get the current config of timer 0
	sbr	Temp1,0b00000000	;STOP THE CLOCK!
	out	TCCR0,Temp1	;write out the new timer config
	;see whether we have reached the correct number of overflows
	cpi	NumTicks,MaxTicks	;Is NumTicks < MaxTicks?
	brne	Endero			;yes => restart timer
	;no => clear INT_0, enable INT_0, reset NumTicks, restart timer
	;Here we need to clear any pending INT_0 interrupts
	;and re-enable INT_0, also reset NumTicks
	;Clear the interrupt bit
	in	Temp1,GIFR
	sbr	Temp1,0b01000000
	out	GIFR,Temp1
	;enable the INT0 interrupt
	in	Temp1,GIMSK
	sbr	Temp1,0b01000000
	out	GIMSK,Temp1
	ldi	IntFlag,0b00000000	;clear the flag
	cbi	PORTB,1
	;Reset NumTicks
	clr	NumTicks
Endero:
	;clear the timer overflow interrupt
	in	Temp1,TIFR
	cbr	Temp1,0b00000001
	out	TIFR,Temp1
	;Clear the timer
	ldi	Temp1,0b00000000
	out	TCNT0,Temp1
	;restart the timer
	in	Temp1,TCCR0	;get the current config of timer 0
	sbr	Temp1,0b00000100	;select CK/256 as the clock speed
	out	TCCR0,Temp1	;write out the new timer config (starts timer)
	
	pop 	Temp1
	out 	SREG,Temp1
	pop	Temp1
	reti

;This loops for MaxC milliseconds	
Delaye:	clr	NumC		;NumC = 0
Step1:	rcall 	Delay		;Delay for 1ms
	inc	NumC		;NumC = NumC + 1
	cpi	NumC,MaxC	;Is NumC == MaxC?
	brne	Step1		;No
	ret			;yes
	

Delay:	ldi 	Tmp1,$0D
Del1:	ldi	Tmp2,$66
Del2:	ldi	Tmp3,1		
Del3:	dec	Tmp3
	brne	Del3
	dec	Tmp2
	brne	Del2
	dec	Tmp1
	brne	Del1
	ret		

	;Values for Tmp1,Tmp2 and Tmp3 with the resulting cycle time
	;$FF,$FF,6 => 1366294 cycles => 170 ms
	;$FF,$FF,5 => 1171222 cycles => 146 ms
	;$FF,$FF,1 => 390922 cycles => 48.8 ms
	;$0F,$FF,1 => 23002 cycles => 2.88 ms
	;$0F,$0F,1 => 1402 cycles => 0.175 ms
	;$0F,$59,1 => 8071 cycles
	;$0E,$5F,1 => 8038 cycles
	;$0D,$66,1 => 8002 cycles => 1.00 ms. Hurrah!

;Lookup table
Sevenseg:
	.dw	$73	; 9
	.dw	$7F	; 8
	.dw	$70	; 7
	.dw	$5F	; 6
	.dw	$5B	; 5
	.dw	$33	; 4
	.dw	$79	; 3
	.dw	$6D	; 2
	.dw	$30	; 1
	.dw	$7E	; 0