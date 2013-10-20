#include <stdio.h>
#include <string.h>

unsigned int randomSeeds[8] = {0x229ac18b, 0xdfb7151b, 0xeb04a9cb, 0x66bf6638,
                               0x0000bd09, 0x00000cab, 0x000069f4, 0x0000e6c3};

unsigned int RndLcGet(int seed)
{
  unsigned int r3 = 0x343fd, r9 = 0x269ec3;

  unsigned int r2 = randomSeeds[seed];
  r2 = r2*r3 + r9;
  randomSeeds[seed] = r2;

  unsigned int result = r2 >> 16;

  fprintf(stderr, "RndLcGet(%d) = %08x\n", seed, result);

  return result;
}

unsigned int calcSeed(int node)
{
  return RndLcGet(node & 0x3);
}

unsigned int dmyKey(char * params)
{
  int sum = 0;

  for (unsigned int i = 0; i < strlen(params); ++i) {
    sum += params[i];
  }

  unsigned int base = sum ^ 0x8086;

  unsigned int r0 = RndLcGet(0) + base;
  unsigned int r1 = 0xf00 & (r0 << 4);
  r0 = r0 & 0xf;
  unsigned int result = (r0 | r1);

  fprintf(stderr, "dmyKey = %08x\n", result);

  return result;
}

unsigned int padKey(char * params, unsigned int secret)
{
  unsigned int sum = 0;

  for (unsigned int i = 0; i < strlen(params); ++i) {
    sum += params[i];
  }

  unsigned int r1 = sum ^ 0x6502;

  unsigned int r0 = 0xf0000000 & (secret << 24);
  unsigned int r2 = (secret << 4) & 0xff;  // 0x0f0
  unsigned int r3 = secret & 0xff;

  r0 = r0 | r2;
  r2 = (r3 << 5) - r3;
  r1 += r2 + 0x26f5;
  r1 = 0x0ffff000 & (r1 << 12);

  // r0 r1r1r1r1 _ r2 _
  unsigned int result = (r0 | r1);
  fprintf(stderr, "padKey = %08x\n", result);
  return result;
}

unsigned int keyGenerator(char * params)
{
  unsigned int seed = calcSeed(RndLcGet(0));

  unsigned int d = dmyKey(params);
  unsigned int p = padKey(params, seed);

  return p | d;
}

// printf("%08x\n", padKey("action=accept_friend_request&pid=143883671&sid=L09N6LNyJHm0GQmxOUWuJwsh8YMGZ8NkrPa68ezG&msgid=19065018&ack=0", 0xeb04)); // => 06dfb040
int main(int argc, char *argv[])
{
  unsigned int key = keyGenerator(argv[1]);

  printf("%08X\n", key);

  return 0;
}
