@ @c
#include <termios.h> /* |TIOCM_RTS| */
#include <fcntl.h> /* |open|, |O_RDWR| */
#include <unistd.h> /* |read|, |write|, |STDOUT_FILENO| */
#include <sys/ioctl.h> /* |ioctl|, |TIOCMBIS| */

int main(int argc, char **argv)
{
  int comfd;
  if ((comfd = open(argv[1], O_RDWR)) == -1) return 1;
  char n;
  while (read(comfd, &n, 1) > 0) { /* FIXME: try `|!= 0|' */
    if (n == '\n') return 0;
    write(STDOUT_FILENO, &n, 1);
  }
}


