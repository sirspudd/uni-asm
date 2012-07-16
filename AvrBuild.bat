@ECHO OFF
"J:\Program Files\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "j:\code\labels.tmp" -fI  -o "j:\code\hand.hex" -d "j:\code\hand.obj" -e "j:\code\hand.eep" -m "j:\code\hand.map" -W+ie   "J:\code\hand.asm"
