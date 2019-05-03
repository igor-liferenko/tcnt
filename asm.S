; see C.c for analogous C code

#include <avr/io.h>

.global main
main:
  sbi _SFR_IO_ADDR(DDRB), PB0

  ldi	r24, lo8(31249)
  ldi	r25, hi8(31249)
  sts	OCR1AH, r25
  sts   OCR1AL, r24

  lds r24, TCCR1B
  ori	r24, 1 << WGM12
  ori   r24, 1 << CS12
  sts TCCR1B, r24

  lds r24, TIMSK1
  ori r24, 1 << OCIE1A
  sts TIMSK1, r24

  sei

loop:
rjmp loop

.global TIMER1_COMPA_vect
TIMER1_COMPA_vect:
  ldi r24, 1 << PB0
  in r25, _SFR_IO_ADDR(PORTB)
  eor r25, r24
  out _SFR_IO_ADDR(PORTB), r25
  reti
.end

https://sourceware.org/binutils/docs/as/index.html#SEC_Contents

https://www.avrfreaks.net/forum/org-using-gcc-gas

http://www.nongnu.org/avr-libc/user-manual/assembler.html
https://hackaday.io/project/1475-avr-gcc-assembler-techniques
https://habr.com/post/373677/
https://stackoverflow.com/questions/31381007/
