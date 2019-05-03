MCU=atmega32u4

test:
	@grep -q '^@c$$' $@.w || ( echo 'NO SECTION ENABLED'; false )
	@grep '^@c$$' $@.w | wc -l | grep -q '^1$$' || ( echo 'MORE THAN ONE SECTION ENABLED'; false )
	@avr-gcc -mmcu=$(MCU) -DF_CPU=16000000UL -g -Os -o fw.elf $@.c
	@avr-objcopy -O ihex fw.elf fw.hex

flash:
	@avrdude -qq -c usbasp -p $(MCU) -U efuse:v:0xcb:m -U hfuse:v:0xd9:m -U lfuse:v:0xff:m -U flash:w:fw.hex

asm:
        avr-gcc -mmcu=atmega32u4 -DF_CPU=16000000UL -g -o asm.elf asm.S
        avr-objcopy -O ihex asm.elf asm.hex
        avrdude -c usbasp -p atmega32u4 -U efuse:v:0xcb:m -U hfuse:v:0xd9:m -U lfuse:v:0xff:m -U flash:w:asm.hex

C:
        avr-gcc -mmcu=atmega32u4 -DF_CPU=16000000UL -g -Os -o C.elf C.c
        avr-objcopy -O ihex C.elf C.hex
        avrdude -c usbasp -p atmega32u4 -U efuse:v:0xcb:m -U hfuse:v:0xd9:m -U lfuse:v:0xff:m -U flash:w:C.hex
