;Presscnt3 using interrupts to decrement coounter

.include "8535def.inc"

 

;delay vars

.def SegPattern = R0

.def tmp1 = R21

.def tmp2 = R20

.def tmp3 = R19

 

.def Tmp1 = R16

.def Tmp2 = R17

.def count = R18

.def CountPress = R22

.def timCount =R23

.def timCount1 =R24

.cseg

.org $000

 

Reset:   rjmp Start          

            

            .org $001

            rjmp EXT_INT0 ;external interrupt 0 handler

            

            .org $009

            rjmp TIM0_OVF ;timer 0 overflow interrupt handler

            

            ;.org $00E

            ;rjmp A2D ;hanle an a2d interrupt

            

            .org $011

            

Start:    ldi Tmp1, LOW(RAMEND)

            out SPL, Tmp1

            ldi Tmp1, HIGH(RAMEND)

            out SPH, Tmp1 ;set stack pointer to point at end of ram

 

            sbi DDRB, 0 ;set output portb pin0

            

            ser Tmp1 ;configure portc bits 0 to 7 as outputs

            out DDRC, Tmp1            

            ldi ZL,LOW(Sevensegtbl*2) ;point z register at first entry of table

            ldi ZH,HIGH(Sevensegtbl*2)

            lpm ;get first entry into r0

            out PORTC, SegPattern ;write to display

            clr Tmp1

            

            ldi CountPress, 9 ;set counter

            

;configure INT0 -portd line bit2 to be input with pullup 

;resistor enabled and interrupt on a falling edge

            

            cbi DDRD, 2 ;portd bit2 input

            sbi PORTD,2 ;turn on pullup resitor

            in  Tmp1, MCUCR

            sbr Tmp1, 0b00000010 ;interrupt on falling edge

            out MCUCR, Tmp1 

            

;now enable the int0 and timer0 interrupts

            

            in  Tmp1, GIMSK

            sbr Tmp1, 0b01000000

            out GIMSK, Tmp1 ; enable into interrupt

            in  Tmp1, TIMSK

            sbr Tmp1, 0b00000001

            out TIMSK, Tmp1 ;enable timer 0 interrupt

 

;now globally enable interrupts

            

            sei

            

;now nothing. let interrups handle the action

            

MAIN:   sbi PORTB, 0                

Loop:    ldi count, 200

            rcall MsDelay

            dec count

            brne Loop

            cbi PORTB, 0

Loop1:  ldi count, 200

            rcall MsDelay

            dec count

            brne Loop1        

            rjmp MAIN

 

;interrupt handlers:

 

;press button interrupt handler

EXT_INT0:

            push Tmp1

            in Tmp1, SREG

            push Tmp1

            push Tmp2

;handle:

            ;disable int 0

            in  Tmp1, GIMSK

            sbr Tmp1, 0b00000000

            out GIMSK, Tmp1 ; disable int0 interrupt

            

            ;raise start of delay flag

            ;in  Tmp1, TIFR

            ;sbr Tmp1, 0b00000001

            ;out TIFR, Tmp1 ;enable timer 0 interrupt

            

            ;was interrupt falling edge

            sbis PORTD,2 ;dont update display if portd bit2 is set = not falling edge

            rcall Decrement;update display

            

            ;toggle falling edge detection bit

            sbi PORTD,2 ;turn on pullup resitor

 

            ;set presacaler -> clock source 8mhz/1024 

            in  Tmp1, TCCR0

            sbr Tmp1, 0b00000001

            out TCCR0, Tmp1 ;enable timer 0 interrupt

            

            ;initialise counter and timer

            ldi timCount, 0;setup timer interrupt counter

            ldi timCount1, 0;setup timer interrupt counter

            ;starting clock timer

            in  Tmp1, TCNT0

            sbr Tmp1, 0b00000000 ;starts counting from 0

            out TCNT0, Tmp1 ;enable timer 0 interrupt

 

            pop Tmp2

            pop Tmp1

            out SREG, Tmp1

            pop Tmp1

            reti

 

;timero overflow interrupt handler

TIM0_OVF:

            push Tmp1

            in Tmp1, SREG

            push Tmp1

            

            ;stop counter/timer irritating bastard thingy

            in  Tmp1, TCCR0

            sbr Tmp1, 0b00000000

            out TCCR0, Tmp1 ;enable timer 0 interrupt

            

            ;counting interrupts        

            cpi timCount, 200

            brne Cont

            inc timCount


Cont:    cpi timCount1, 200         

 ;           brne Cont1

;            inc timCount1

 ;           pop Tmp1

  ;          out SREG, Tmp1

   ;         pop Tmp1

            reti

            

 

 

;other code

Decrement:

            dec CountPress ;bump up count

            brne Update ;check if should rollover

            ldi CountPress, 9 ;set to nine

            

Update: push CountPress ;write new number to display-> save countpress (push) before doubling

            lsl CountPress ;program memory is arranged as words

            add ZL, CountPress ; first adjust pointer into lookup table

            pop CountPress ;restore

            clr tmp1

            adc ZH, tmp1

            lpm

            out PORTC, SegPattern

 

            ldi ZL,LOW(Sevensegtbl*2) ;point z register at first entry of table

            ldi ZH,HIGH(Sevensegtbl*2)

 

            ret

 

;1 millisecond delay loop

MsDelay:

            ldi tmp1,86 ;Tmp1 

 Del1:    ldi tmp2,10 ;Tmp2 

 Del2:  ldi tmp3,2 ;Tmp3 

 Del3:  dec tmp3

            brne Del3

            dec tmp2

            brne Del2

            dec tmp1

            brne Del1

            ret

 

;look up table for 9...0

Sevensegtbl:

            .dw $30

            .dw $6D

            .dw $79

            .dw $33

            .dw $5B

            .dw $5F

            .dw $70

            .dw $7F

            .dw $73

            .dw $7E
