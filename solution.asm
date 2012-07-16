.include "8535def.inc"
;***********************************

.def Temp1 = R16
.def Temp2 = R17
.def Temp3 = R18
.def TempChar = R19
	
.def Decimal = R20
.def LeadingZero = R21
.def TimerCount = R22

.def DelayVal = R23

.equ b2400 = 207

.equ SignalChar = 'a'


; Dimmer
.equ _Interrupt = 0

; Voltmeter
.equ _VoltPIN = 0

; Ohm meter
.equ _OhmPort = PORTB
.equ _OhmDDR = DDRB
.equ _OhmPIN = 2


; Beep Stuff
.equ _BeepPrescaler = 2
.equ _BeepPort = PORTA
.equ _BeepDDR = DDRA
.equ _BeepPIN = 6



	.cseg
	.org $000
Reset: 	rjmp Start
	.org INT0addr
	rjmp EXT_INT
	.org INT1addr
	rjmp EXT_INT
	
	.org $009
	rjmp TIM0_OVF

	.org    $00b               ;UART Data Register Empty Interrupt Vector
        rjmp readSerial
	.org $011



Start:  ldi Temp1, LOW(RAMEND)
	out SPL, Temp1
	ldi Temp1, HIGH(RAMEND)
	out SPH, Temp1
	
	; Configure UART
	ldi Temp1, b2400
	out UBRR, Temp1
	;ldi Temp1, 0b00011000
	;out UCR, Temp1


	;**enable UART receiver & transmitter and IRQ on serial in:
        ldi    Temp1, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
        out    UCR,Temp1        

	; ----
	

	; Dip Switch and 7-seg display setup
	; Set port C for output
	ser Temp1
	out DDRC, Temp1
	; -------------------------------------
	
	; Inputs for dip switch tied high
	in Temp1, DDRD
	andi Temp1, 0b10000111
	out DDRD, Temp1

	in Temp1, PORTD
	ori Temp1, 0b01111000
	out PORTD, Temp1
	; -------------------------------------
	
	; Set up voltmeter
	; Enable with no free running mode with prescaler to /1024
	ldi Temp1, (1<<ADEN) | (0<<ADFR) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0) 
	out ADCSR, Temp1
		
	; Set PORTA pin 0 to input, low
	cbi DDRA, 0	
	cbi PORTA, 0	
	
	; -------------------------------------


	; Setup Ohmeter
	; Setup timer counter 0

	; Setup Comparitor
	in Temp1, ACSR
	sbr Temp1, ACIC
	out ACSR, Temp1
	
	; Set AIN0 and AIN1 low and inputs
	cbi DDRB, 2
	;cbi PORTB, 2
	cbi DDRB, 3
	;cbi PORTB, 3
	
	
	; Set PORTA pin 1 output low
	sbi _OhmDDR, _OhmPIN
	cbi _OhmPORT, _OhmPIN
	
	; Start timer counter 1
	; Set the prescaler to 1024
	ldi Temp1, (1<<CS12) | (0<<CS11) | (0<<CS10)
	out TCCR1B, Temp1

	; -------------------------------------
	
	
	; Setup timer counter 1 as a pulse width modulator
	sbi DDRD, PD7
	ldi Temp1, 0b01100101
	out TCCR2, Temp1
	
	;set light to off
	ldi Temp1, 0
	out OCR2, Temp1
	
	; Interrupt for dimmer button
	; Port D for the interrrupt
	cbi DDRD, DDD2
	sbi PORTD, 2
	; ----
	
	; Enable INT0
	rcall EnableInt
	
	; Setup Timer
	; Interrupt
	rcall StopTimer
	in Temp1, TIMSK
	sbr Temp1, 0b00000001
	out TIMSK, Temp1
	;rcall StartTimer
	
	; -------------------------------------
	
	
	; Enable Interrupts
	sei
	
Main:
	;rcall readSerial
	;rcall sendSerial
	
	;rcall sendSerialMessage
	
	rcall readDip
	;rcall Beep
	rjmp Main


TIM0_OVF:
	push Temp1
	
	; Disable Timer
	;rcall StopTimer

	dec TimerCount
	cpi TimerCount, 0
	brne NotTime
	
	; Enable INT0 and stop timer
	rcall StopTimer
	rcall EnableInt
	
	NotTime:

	pop Temp1
	reti
	
StartTimer:

	; Set Counter for approx 25ms
	rcall Set25 ; Set for 25ms
	ldi TimerCount, 3
	; Prescaler
	ldi Temp1, 0b00000101 ; Prescaler / 1024
	out TCCR0, Temp1

	ret

StopTimer:
	; Off
	ldi Temp1, 0b00000000 ; Prescaler / 1024
	out TCCR0, Temp1

	ret

Set25:
	ldi Temp1, 55 ; counts from 55 to 255 (200 * 1024 cycles)
	out TCNT0, Temp1	
	ret	

EXT_INT:
	push Temp1
	in Temp1, SREG
	push Temp1
	
	
	; If it was on a falling edge skip increment and display
	in Temp1, MCUCR
	sbrc Temp1, ISC00
	rjmp SetFalling
	
	; Fade Display
	in Temp1, OCR2
	subi Temp1 , -32
	out OCR2, Temp1
	
	; Set for rising edge (button release)
    	ldi    Temp1, (0<<SE)|(0<<SM1)|(0<<SM0)|(1<<ISC01)|(1<<ISC00)|(1<<ISC01)|(1<<ISC00) 
    	out    MCUCR, Temp1

	rjmp EXITINT

	SetFalling:	 
	; Set for falling edge (button press)
    	ldi    Temp1, (0<<SE)|(0<<SM1)|(0<<SM0)|(1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
    	out    MCUCR, Temp1

	
	
	EXITINT:
	; Disable INT0
	rcall DisableInt

	; Enable Timer
	rcall StartTimer

	pop Temp1
	out SREG, Temp1
	pop Temp1
	
	reti

EnableInt:

	; Clear Pending
	in Temp1, GIFR
	sbr Temp1, (1<<(6+_Interrupt))
	out GIFR, Temp1

	; Enable INT0
	in Temp1, GIMSK
	sbr Temp1, (1<<(6+_Interrupt))
	out GIMSK, Temp1
	

	
	ret

DisableInt:
	; Disable INT0
	in Temp1, GIMSK
	cbr Temp1, 1<<(6+_Interrupt)
	out GIMSK, Temp1
	ret


readSerial:
	in tempChar, UDR
	
	
	; Check for special triggers
	
	; Voltmeter
	cpi tempChar, 'V'
	brne skipVoltmeter
	
	rcall VoltMeter
	reti
	
	skipVoltmeter:

	; Ohm meter
	cpi tempChar, 'R'
	brne skipOhmeter
	
	rcall ResistanceMeter
	reti
	
	skipOhmeter:
	
	; Beep
	cpi tempChar, 'B'
	brne skipBeep
	
	rcall Beep
	reti
	
	skipBeep:
	
	; -------------------------------
	
	
	
	cpi tempChar, SignalChar
	brne Noleading
	
	push tempChar
	ldi tempChar, '%'
	rcall sendSerial
	pop tempChar

	Noleading:
	rcall sendSerial

	
	cpi tempChar, SignalChar
	brne NoTrailing
	
	push tempChar
	ldi tempChar, '%'
	rcall sendSerial
	pop tempChar
	
	
	
	NoTrailing:
	reti


; Sends a char to the serial port		
sendSerial:
	WaitClear:
	sbis USR, UDRE
	rjmp WaitClear
	
	out UDR, tempChar
	
	ret

sendSerialMessage:
	moreMessage:
	lpm
	
	mov tempChar, R0
	
	cpi tempChar, $FF
	breq exitSerialMessage
	
	rcall sendSerial	
	
	adiw ZL, 1
	rjmp moreMessage
	exitSerialMessage:
	
	ret


; Sends a number as a digit to the serial port
sendSerialDigit:
	; Offset to make the number a ASCII digit
	sbr tempChar, 0b00110000
	cbr tempChar, 0b11000000
	
	; Send the digit
	rcall SendSerial
	ret

sendSerialDigitDecimal:
	sbr tempChar, 0b00110000
	cbr tempChar, 0b11000000

	; Is it time for a zero?
	cpi tempChar, '0'
	breq skipZero
	clr LeadingZero
	rjmp showZero

	skipZero:
	cpi LeadingZero, 0
	breq showZero
	
	cpi Decimal, 3
	brlt showZero
	
	ldi tempChar, ' '
	
	
	showZero:

	cpi Decimal, 0
	brne NoDecimal
	
	push tempChar
	ldi tempChar, '.'
	rcall SendSerial
	pop tempChar
		
	NoDecimal:
	
	rcall SendSerial
	dec Decimal
	ret
	
Beep:	
	; Write " Beep... " + CR + LF	
	ldi ZH, HIGH(msgBeep * 2)
	ldi ZL, LOW(msgBeep * 2)
	rcall sendSerialMessage
	
	sbi _BeepDDR, _BeepPIN
	
	; Set timer counter 1 to start at 238 
	clr Temp1
	out TCNT1H, Temp1
	ldi Temp1, 238
	out TCNT1L, Temp1
	
	; Loop until timer high byte reaches $7B (1 second later approx)
	moreBeep:
	in Temp1, TCNT1L
	in Temp2, TCNT1H
	
	; Capture Bit off timer counter for beep signal
	sbrs Temp1, _BeepPrescaler
	sbi _BeepPORT, _BeepPIN
	sbrc Temp1, _BeepPrescaler
	cbi _BeepPORT, _BeepPIN

	; Break out of loop at timeout
	cpi Temp2, $7B
	brne moreBeep

	; Set back to an input
	cbi _BeepDDR, _BeepPIN
	
	; Write "done!" + CR + LF	
	ldi ZH, HIGH(msgBeepDone * 2)
	ldi ZL, LOW(msgBeepDone * 2)
	rcall sendSerialMessage
	ret

ResistanceMeter:

	clr Temp1
	out TCNT1H, Temp1
	out TCNT1L, Temp1
	

	;set Pin to input and floating
	cbi _OhmDDR, _OhmPIN
	cbi _OhmPORT, _OhmPIN

	
CheckTC1:
	sbis ACSR, ACO ;check if ACI is set
	rjmp CheckTC1
	
	in Temp1, TCNT1L
	in Temp2, TCNT1H
		
	;set pin to output and low
	sbi _OhmDDR, _OhmPIN
	cbi _OhmPORT, _OhmPIN
	
	lsr Temp2
	ror Temp1

	; Take the 4 least significant bits of the low register for
	; decimal reading
	mov Temp3, Temp1
	andi Temp3, 0b00001111
	
	lsr Temp2
	ror Temp1

	lsr Temp2
	ror Temp1

	lsr Temp2
	ror Temp1

	lsr Temp2
	ror Temp1
	
	ldi Decimal, 5
	rcall ShowBCD

	ldi tempChar, '.'
	rcall SendSerial

	;Point Z to lookup table
	ldi ZH, HIGH(Decimaltbl * 2)
	ldi ZL, LOW(Decimaltbl * 2)

	add ZL, Temp3	
	clr Temp3
	adc ZH, Temp3	
	lpm
	mov tempChar , R0
	rcall SendSerial

	; Write " kiloOhms" + CR + LF	
	ldi ZH, HIGH(msgKiloOhms * 2)
	ldi ZL, LOW(msgKiloOhms * 2)
	rcall sendSerialMessage

	ret


VoltMeter:
	push tempChar
	push Temp1
	push Temp2
	push Temp3

	; Set input to pin 0
	ldi Temp1, _VoltPIN
	out ADMUX, Temp1
	
	; Reset converson complete flag
	in Temp1, ADCSR
	cbr Temp1, 6
	out ADCSR, Temp1
	
	; Start Conversion
	in Temp1, ADCSR		
	sbr Temp1, 0b01000000
	out ADCSR, Temp1
	
	; Wait till conversion is complete
	VoltWait:
	sbic ADCSR, 6			
	rjmp VoltWait
	
	; Read Value
	in Temp1, ADCL
	in Temp2, ADCH

	lsl Temp1
	rol Temp2

	lsl Temp1
	rol Temp2
		
	ldi Decimal, 1
	rcall ShowBCD
		
	; Write " Volts" + CR + LF	
	ldi ZH, HIGH(msgVolts * 2)
	ldi ZL, LOW(msgVolts * 2)
	rcall sendSerialMessage
	
	pop Temp3
	pop Temp2
	pop Temp1
	pop tempChar
	ret
	
readDip:
	in tempChar, PIND
	
	
	; Do some bit reorganising since the inputs are coming
	; from port D: pins 3-6
	lsl tempChar
	swap tempChar
	
	; Not the bits
	ldi Temp1, 0b00001111
	eor tempChar, Temp1

	; Trim off other bits
	andi tempChar, 0b00001111
	
	; Check Range
	cpi tempChar, 10
	brlo Acceptable
	ldi tempChar, $E
	Acceptable:
	
	
	rcall sendSeg

	ret


showBCD:

	push Temp3

	ser LeadingZero
	
		clr tempChar
DoThou:		
		subi Temp1, LOW(1000)
		sbci Temp2,HIGH(1000)
		brcs NowHund
		inc tempChar
		rjmp DoThou
		
		
NowHund:	
		; Send thousand digit
		rcall sendSerialDigitDecimal

		ldi Temp3,LOW(1000)
		add Temp1,Temp3
		ldi Temp3,High(1000)
		adc Temp2, Temp3
		
		clr tempChar
		
DoHunds:	subi Temp1,100
		sbci Temp2, 0
		brcs NowTens
		inc tempChar
		rjmp DoHunds
		
NowTens:	; Send hundreds digit
		rcall sendSerialDigitDecimal
		clr tempChar

		ldi Temp3, 100
		add Temp1, Temp3
		
DoTens:		subi Temp1,10
		brcs NowUnits
		inc tempChar
		rjmp DoTens
		
NowUnits:	; Send tens digit
		rcall sendSerialDigitDecimal
		clr tempChar

		ldi Temp3, 10
		add Temp1, Temp3
		mov tempChar, Temp1
		
		
		; Send units digit
		rcall sendSerialDigitDecimal			
		
	pop Temp3

	ret

sendSeg:
	push ZH
	push ZL
	push R0
	
	;Point Z to lookup table
	ldi ZH, HIGH(SevenSegtbl * 2)
	ldi ZL, LOW(SevenSegtbl * 2)

	lsl tempChar
	add ZL, tempChar	
	clr tempChar
	adc ZH, tempChar
	
	lpm
	out PORTC, R0	

	pop R0
	pop ZL
	pop ZH
	ret


SevenSegtbl:
	.dw $3F
	.dw $06
	.dw $5B
	.dw $4F
	.dw $66
	.dw $6D
	.dw $7D
	.dw $07
	.dw $7F
	.dw $67
	.dw $77 ;A
	.dw $7C	;B	
	.dw $39	;C
	.dw $5E	;D
	.dw $79	;E
	.dw $71	;F
	
Decimaltbl:
	.db "0011233455667889"
	
msgVolts:
	.db " Volts", $0D, $0A, $FF, $FF

msgKiloOhms:
	.db " kiloOhms", $0D, $0A, $FF

msgBeep:
	.db "Beep... ", $FF, $FF
	
msgBeepDone:
	.db "done!", $0D, $0A, $FF
	
	.exit