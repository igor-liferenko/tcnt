@ This is like \.{cat}, but it exits after outputting the first line, and it does not output
newline character.

TODO: Revert DTR check in test.w and disable canonical mode here (while we are at it,
disable echo too). And do not use '\n' in test.w - instead send out-of-band signal
on EP3 (you may use DSR, but just as a conventional signal - not in its original sense)
when transmission is finished (see demo/demo.ch).
Use signal handler with SA_RESTART and timer (see git lg in time/) and in signal handler
call ioctl TIOCMGET and exit

@c
#include <fcntl.h> /* |open|, |O_RDONLY| */
#include <unistd.h> /* |read|, |write|, |STDOUT_FILENO| */

int main(int argc, char **argv)
{
  int comfd;
  if ((comfd = open(argv[1], O_RDONLY | O_NOCTTY)) == -1) return 1;
  char n;
  while (read(comfd, &n, 1) > 0) { /* FIXME: check what read will return if device is ejected and
    if -1, use `!= -1' instead of `> 0' */
    if (n == '\n') return 0;
    write(STDOUT_FILENO, &n, 1);
  }
  return 1;
}


