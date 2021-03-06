% To compile certain section, change "@@(null@@>=" to "@@c".

\let\lheader\rheader
%\datethis

\noinx

\input USB

@* Testing.

@ @c
@<Header files@>@;
@<Type definitions@>@;
@<Global variables@>@;
@<Create ISR for connecting to USB host@>@;

@ This code demonstrates such-and-such.
For testing use only one gnome-terminal window (both for editing this file and for
`./tcnt /dev/ttyACM0 | od -An -tu1').

@(null@>=
void main(void)
{
  @<Connect...@>@;

  DDRD |= 1 << PD7;
  TCCR0B |= 1 << CS02 | 1 << CS01;

  PORTD |= 1 << PD7; PORTD &= ~(1 << PD7); /* one tick */

  __asm__ __volatile__ ("nop"); __asm__ __volatile__ ("nop"); /* before reading counter
    FIXME: why two nop's? */
  uint8_t tcnt = TCNT0;

  int once = 0;
  while (1) {
    @<Ignore setup@>@;
    UENUM = EP1;
    if ((UEINTX & 1 << TXINI) && !once) {
      once = 1;
      UEINTX &= ~(1 << TXINI);
      UEDATX = tcnt; UEDATX = '\n';
      UEINTX &= ~(1 << FIFOCON);
    }
    @<Ignore echo@>@;
  }
}

@ This code demonstrates that counter is not reset after executing interrupt.
For testing use the same (as where you edit this file) terminal with `./tcnt'.

@(null@>=
#include <avr/interrupt.h>
#include <util/delay.h>

volatile uint8_t flag = 0;
ISR(TIMER0_COMPA_vect)
{
  flag = 1;
}
void main(void)
{
  @<Connect...@>@;

  OCR0A = 200; /* interrupt is triggered when counter reaches this */
  TIMSK0 |= 1 << OCIE0A;
  TCCR0B |= 1 << CS02 | 1 << CS00; /* max prescaler (64us per tick) */

  while (1) {
    @<Get |dtr|@>@;
    if (dtr && flag) {
      flag = 0;
      UENUM = EP1;  
      while (!(UEINTX & 1 << TXINI)) ;  
      UEINTX &= ~(1 << TXINI);  
      UEDATX = TCNT0;  
      UEINTX &= ~(1 << FIFOCON);  
    }
  }
}

@ Result: PB0 burns. TODO: re-do without LED, by using usb as above
What this experiment tells us:
Counter is 1 200 ms after starting counter (one tick is 0.001024 sec).
This means that TOP is reached.
And the fact that TOP is reached means that OCR4A is updated.

We need to find out if comparison is done before counter is increased or after.
That is, counter is 0 on start, and TOP is 0, so it did not reach 0. We need
to know if counter will be compared before increase or after.

1022 = 0
2046 = 1
3070 = 2
4094 = 3
5118 = 0
6142 = 1
7166 = 2
8190 = 3

For testing use the same (as where you edit this file) terminal with `./tcnt'.

@(null@>=
#include <avr/io.h>
#include <util/delay.h>

void main(void)
{
  DDRB |= 1 << PB0;

  TCCR4A |= 1 << PWM4A; /* WGM */
  OCR4C = 0; /* TOP */
  TCCR4B |= 1 << CS43 | 1 << CS42 | 1 << CS41 | 1 << CS40; /* max prescaler + start timer */

  _delay_us(8191);
  if (TCNT4 == 3) PORTB |= 1 << PB0;
}

@ What this experiment tells us:
Counter is 1 200 ms after starting counter (one tick is 0.001024 sec).
This means that TOP is reached.
And the fact that TOP is reached means that OCR4A is updated.

We need to find out if comparison is done before counter is increased or after.
That is, counter is 0 on start, and TOP is 0, so it did not reach 0. We need
to know if counter will be compared before increase or after.

1022 = 0
2046 = 1
3070 = 2
4094 = 3
5118 = 0
6142 = 1
7166 = 2
8190 = 3

For testing use the same (as where you edit this file) terminal with `./tcnt'.

@(null@>=
#include <avr/io.h>
#include <util/delay.h>

void main(void)
{
  DDRC |= 1 << PC7;
  TCCR4A |= 1 << PWM4A; /* WGM */
  OCR4C = 3; /* TOP (minimal) */
  TC4H = 0x03; OCR4A = 0x98; TC4H = 0; // 920
  TCCR4B |= 1 << CS43 | 1 << CS42 | 1 << CS41 | 1 << CS40; /* max prescaler + start timer */
  _delay_ms(5); // wait until counter hits TOP when OCR4A will be set
  TCCR4A |= 1 << COM4A1 | 1 << COM4A0;
}

@ Counter always starts from zero

For testing use the same (as where you edit this file) terminal with `./tcnt'.

@(null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

void main(void)
{
  DDRC |= 1 << PC7;
  TCCR4A |= 1 << PWM4A; /* WGM */
  OCR4C = 0x9f; /* TOP */
  OCR4A = 1;
  TIMSK4 |= 1 << TOIE4; /* when counter reaches TOP */
  sei();
  TCCR4B |= 1 << CS43 | 1 << CS42 | 1 << CS41 | 1 << CS40; /* max prescaler + start timer */
  TCCR4A |= 1 << COM4A1 | 1 << COM4A0;

  TCCR4B |= 0x0F;

  while (1) ;
}

ISR(TIMER4_OVF_vect)
{
  TCCR4B &= 0xF0;
}

@ This code shows maximum possible timeout with timer.
HINT: see how PRINT_TIME is done in tcnt.w and print timestamp with milliseconds when new
data arrives in cu.w

For testing use the same (as where you edit this file) terminal with `./cu'.

@(null@>=
#include <avr/interrupt.h>
#include <util/delay.h>

void main(void)
{
  @<Connect...@>@;

  int once = 0;
  while (1) {
    @<Get |dtr|@>@;
    if (dtr && !once) {
      once = 1;
      UENUM = EP1;  
      while (!(UEINTX & 1 << TXINI)) ;  
      UEINTX &= ~(1 << TXINI);  
      UEDATX = 'S'; UEDATX = 't'; UEDATX = 'a'; UEDATX = 'r'; UEDATX = 't'; UEDATX = '\r';
        UEDATX = '\n';
      UEINTX &= ~(1 << FIFOCON);

      TCCR1B |= 1 << CS12 | 1 << CS10; /* start timer */

      while (~TIFR1 & 1 << TOV1) ; /* wait when timer overflows */

      // UENUM = EP1;
      while (!(UEINTX & 1 << TXINI)) ;
      UEINTX &= ~(1 << TXINI);
      UEDATX = 'S'; UEDATX = 't'; UEDATX = 'o'; UEDATX = 'p'; UEDATX = '\r'; UEDATX = '\n';
      UEINTX &= ~(1 << FIFOCON);
    }
  }
}

@ Dummy. Remove when conversion as in first example is done.

@<Get |dtr|@>=

@ @<Ignore setup@>=
UENUM = EP0;
if (UEINTX & 1 << RXSTPI) {
  UEINTX &= ~(1 << RXSTPI);
  UEINTX &= ~(1 << TXINI); /* STATUS stage */
}

@ @<Ignore echo@>=
UENUM = EP2;
if (UEINTX & 1 << RXOUTI) {
  UEINTX &= ~(1 << RXOUTI);
  UEINTX &= ~(1 << FIFOCON);
}

@i ../usb/IN-endpoint-management.w
@i ../usb/USB.w

@ Program headers are in separate section from USB headers.

@<Header files@>=
#include <avr/io.h>
