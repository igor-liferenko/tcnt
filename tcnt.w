@ This is like \.{cat}, but it exits after outputting the first line, and it does not output
newline character.

@c
#include <fcntl.h> /* |open|, |O_RDONLY| */
#include <unistd.h> /* |read|, |write|, |STDOUT_FILENO| */

int main(int argc, char **argv)
{
  int comfd;
  if ((comfd = open(argv[1], O_RDONLY)) == -1) return 1;
  char n;
  while (read(comfd, &n, 1) > 0) { /* FIXME: check what read will return if device is ejected and
    if -1, use `!= -1' instead of `> 0' */
    if (n == '\n') return 0;
    write(STDOUT_FILENO, &n, 1);
  }
  return 1;
}


