#include <stdio.h>

unsigned int calculate(int r3, int r4)
{
  return (0xffdf & (r3 >> 16));
  unsigned int check_digit = r4 ^ 0x65a9;

  check_digit = (check_digit == (r3 & 0xffff)) ? 0 : 0x20;

  return (check_digit | (0xffdf & (r3 >> 16)));
}

int main(int argc, char *argv[])
{
  int cases = 3;
  unsigned int r3[] = {0xa4ce0003, 0x9fd60003, 0xc5f10005};
  unsigned int r4[] = {0x65aa, 0x65aa, 0x65ac};
  unsigned int answer[] = {0xa4ce, 0x9fd6, 0xc5d1};

  int x = 0x65a9;
  for (int i = 0; i < 100; ++i) {
    int r3 = x & 0xffff;
    int r0 = 0x65a9;
    r3 ^= r0;
    r3 += 1;
    r0 = r3 ^ r0;
    x = (x & 0xffff0000) | (r0 & 0xffff);

    printf("%08x\n", x);
  }


  for (int i = 0; i < cases; ++i) {
    if (calculate(r3[i], r4[i]) == answer[i]) {
      printf("%d OK\n", i);
    } else {
      printf("%d NG: %d %d -> %d : %d\n", i, r3[i], r4[i], calculate(r3[i], r4[i]), answer[i]);
    }
  }

  return 0;
}
