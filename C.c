/* see asm.S for analogous assembler code */
#include <avr/io.h>
#include <avr/interrupt.h>

int main(void)
{
  DDRB |= 1 << PB0;
  OCR1A = 31249; // (amount of cycles per second)/half-1 = (16000000/256)/2-1 = 500ms
  TCCR1B |= (1 << WGM12); // CTC OCR1A
  TCCR1B |= (1 << CS12); // 256
  TIMSK1 |= (1 << OCIE1A); // enable timer overflow interrupt
  sei(); // enable all interrupts
  while(1) ;
}

ISR(TIMER1_COMPA_vect)
{
  PORTB ^= (1<<PB0);
}
