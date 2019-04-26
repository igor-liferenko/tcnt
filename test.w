% To compile certain section, change "@@(/dev/null@@>=" to "@@c".

@ @c
@<Header files@>@;
@<Type definitions@>@;
@<Global variables@>@;
@<Create ISR for connecting to USB host@>@;

@ This code demonstrates such-and-such.

@(/dev/null@>=
void main(void)
{
  @<Connect...@>@;

  DDRD |= 1 << PD7;
  TCCR0B |= 1 << CS02 | 1 << CS01;

  PORTD |= 1 << PD7; PORTD &= ~(1 << PD7); /* one tick */

  __asm__ __volatile__ ("nop"); __asm__ __volatile__ ("nop"); /* before reading counter
    FIXME: why to nop's? */

  while (1) {
    @<Get |...@>@;
    if (dtr_rts) break;
  }

  UENUM = EP1;
  while (!(UEINTX & 1 << TXINI)) ;
  UEINTX &= ~(1 << TXINI);
  UEDATX = TCNT0;
  UEINTX &= ~(1 << FIFOCON);

  int once = 0;
  while (1) {
    @<Get |...@>@;
    if (dtr_rts && !once) {
      once++;
      UENUM = EP1;
      while (!(UEINTX & 1 << TXINI)) ;
      UEINTX &= ~(1 << TXINI);
      UEDATX = TCNT0;
      UEINTX &= ~(1 << FIFOCON);
    }
  }
}

@ This code demonstrates that counter is not reset after executing interrupt.

@c
#include <avr/interrupt.h>
#include <util/delay.h>
volatile uint8_t flag = 0;
ISR(TIMER0_COMPA_vect)
{
  flag = 1;
//  TCNT0 = 0;
}
void main(void)
{
  @<Connect...@>@;
  PORTB |= 1 << PB0;
  DDRB |= 1 << PB0;
  OCR0A = 200; /* interrupt is triggered when counter reaches this */
  TIMSK0 |= 1 << OCIE0A;
  TCCR0B |= 1 << CS02 | 1 << CS00; /* max prescaler (64us per tick) */

  while (1) {
    @<Get |...@>@;
    if (dtr_rts && flag) {
      flag = 0;
      UENUM = EP1;  
      while (!(UEINTX & 1 << TXINI)) ;  
      UEINTX &= ~(1 << TXINI);  
      UEDATX = TCNT0;  
      UEINTX &= ~(1 << FIFOCON);  
    }
  }
}

@ No other requests except {\caps set control line state} come
after connection is established.
It is used by host to say the device not to send when DTR/RTS is not on.

@<Global variables@>=
U16 dtr_rts = 0;

@ @<Get |dtr_rts|@>=
UENUM = EP0;
if (UEINTX & 1 << RXSTPI) {
  (void) UEDATX; @+ (void) UEDATX;
  wValue = UEDATX | UEDATX << 8;
  UEINTX &= ~(1 << RXSTPI);
  UEINTX &= ~(1 << TXINI); /* STATUS stage */
  dtr_rts = wValue;
}

@i ../usb/IN-endpoint-management.w
@i ../usb/USB.w

@ Program headers are in separate section from USB headers.

@<Header files@>=
#include <avr/io.h>

@* Index.
