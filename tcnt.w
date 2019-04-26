@ This program is for using with `\.{./test.w}'.
It is like `\.{avrcu}' with the following differences:
\item{-} it only reads data
\item{-} it does not change tty settings for gnome-terminal
\item{-} it converts received digit to text representation
\item{-} tty settings are not restored

@c
@<Header files@>;
@<Global variables@>;

void main(int argc, char **argv)
{
  @<Set external encoding@>;
  @<Open com-port@>;
  @<Configure TTY@>;
  if (ioctl(comfd, TIOCMBIS, &dtr_rts) == -1) {
    fwprintf(stderr, L"DTR/RTS: %m\n");
    close(comfd);
    exit(EXIT_FAILURE);
  }
  @<Read from TTY@>@; /* endlessly */
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

@ @<Configure TTY@>=
struct termios com_tty;
tcgetattr(comfd, &com_tty);
cfmakeraw(&com_tty);
tcsetattr(comfd, TCSANOW, &com_tty);

@ @<Read from TTY@>=
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
