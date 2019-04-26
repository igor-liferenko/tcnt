%TODO: use @@<Restore tty settings@@> and simply close(comfd) instead of @@<Close...

@* Intro.
This program is specially to work with avr devices with my USB implementation (also, cdc-acm
driver must be patched).

Differences from `\.cu':
\item{1)} speed is not set (it is not needed in pure USB)
(with the exception that it is sent automatically by driver once it is loaded by OS - maybe
remove auto-setting of speed from cdc-acm.c and then processing of SET LINE CODING request
may be removed from firmware too; TODO: check if \.{USB\_RESET} is sent after
'sudo rmmod cdc-acm; sudo modprobe cdc-acm') - this allows in firmware to consider that only
DTR/RTS signal can come on control endpoint after connection is established.
\item{2)} DTR/RTS is set to `1' - this allows to set tty attributes before device starts
sending (especially useful for disabling echo)

@c
@<Header files@>;
@<Global variables@>;

int main(int argc, char **argv)
{
  @<Set external encoding@>;
  @<Open com-port@>;
  @<Save tty settings@>;
  @<Set tty settings@>;
  if (ioctl(comfd, TIOCMBIS, &dtr_rts) == -1) {
    fwprintf(stderr, L"DTR/RTS: %m\n");
    @<Close com-port@>@;
    exit(EXIT_FAILURE);
  }
  @<Run session@>@;
  @<Close com-port@>@;
  exit(EXIT_SUCCESS);
}

@ |comfd| contains file descriptor for com-port.

@<Global...@>=
int comfd;
int dtr_rts = TIOCM_DTR | TIOCM_RTS; /* out-of-band signal */

@ We open com-port before creating child process, so that both processes will have access to it.

\noindent
|O_RDWR| sets read/write mode.

May be called without arguments, or with arguments `\.{-l /dev/something}'.

@d COM_PORT "/dev/avr"

@<Open com-port@>=
if ((comfd = open(argc == 3 ? argv[2] : COM_PORT, O_RDWR)) == -1) {
  fwprintf(stderr, L"Error opening com-port: %m\n");
  exit(EXIT_FAILURE);
}

@ @<Global...@>=
struct termios com_tty_restore;

@ @<Save tty...@>=
tcgetattr(comfd, &com_tty_restore);

@ @<Set tty...@>=
struct termios com_tty;
tcgetattr(comfd, &com_tty);
cfmakeraw(&com_tty);
tcsetattr(comfd, TCSANOW, &com_tty);

@ @<Run session@>=
uint8_t n;
while (read(comfd, &n, 1) > 0) { /* FIXME: try `|!= 0|' */
      char s[10];
      int i = 0;
      do { /* generate digits in reverse order */
        s[i++] = n % 10 + '0'; /* get next digit */
      } while ((n /= 10) > 0); /* throw it away */
      s[i] = '\0';
      char c;
      int j, k;
      for (j = 0, k = i-1; j < k; j++, k--) {
        c = s[j];
        s[j] = s[k];
        s[k] = c;
      }
      write(STDOUT_FILENO, s, i);
      write(STDOUT_FILENO, "\n", 1);
}

@ @<Close...@>=
tcsetattr(comfd, TCSANOW, &com_tty_restore);
close(comfd);

@ @<Set external...@>=
setlocale(LC_CTYPE, "C.UTF-8");

@ @<Header...@>=
#include <stdint.h>
#include <termios.h> /* |struct termios|, |tcgetattr|, |tcsetattr|, |TCSANOW|,
  |cfmakeraw|, |TIOCM_DTR| */
#include <locale.h> /* |setlocale|, |LC_CTYPE| */
#include <wchar.h> /* |fwprintf| */
#include <fcntl.h> /* |open|, |O_RDWR| */
#include <unistd.h> /* |read|, |pid_t|, |write|, |close|, |fork|, |STDIN_FILENO|,
  |STDOUT_FILENO| */
#include <stdio.h> /* |stderr| */
#include <stdlib.h> /* |exit|, |EXIT_SUCCESS|, |EXIT_FAILURE| */
#include <signal.h> /* |struct sigaction|, |sigaction|, |sa_flags|, |sa_handler|, |sa_mask|,
  |SIGCHLD|, |sigemptyset|, |kill|, |SIGTERM| */
#include <sys/ioctl.h> /* |ioctl|, |TIOCMBIS| */
#include <sys/wait.h> /* |wait| */
