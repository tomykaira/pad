#include <stdio.h>
#include <string.h>

unsigned int randomSeeds[8] = {0x229ac18b, 0xdfb7151b, 0xeb04a9cb, 0x66bf6638,
                               0x0000bd09, 0x00000cab, 0x000069f4, 0x0000e6c3};

unsigned int rnd_lc_get(int seed)
{
  unsigned int r3 = 0x343fd, r9 = 0x269ec3;
  unsigned int r2 = randomSeeds[seed];
  unsigned int result;

  r2 = r2*r3 + r9;
  randomSeeds[seed] = r2;

  result = r2 >> 16;

  return result;
}

unsigned int calc_seed(int node)
{
  return rnd_lc_get(node & 0x3);
}

unsigned int calc_dmy_key(char * params)
{
  int sum = 0;
  unsigned int base, r0, r1, result;

  for (unsigned int i = 0; i < strlen(params); ++i) {
    sum += params[i];
  }

  base = sum ^ 0x8086;

  r0 = rnd_lc_get(0) + base;
  r1 = 0xf00 & (r0 << 4);
  r0 = r0 & 0xf;
  result = (r0 | r1);

  return result;
}

unsigned int calc_pad_key(char * params, unsigned int secret)
{
  unsigned int sum, r0, r1, r2, r3, result;

  sum = 0;

  for (unsigned int i = 0; i < strlen(params); ++i) {
    sum += params[i];
  }

  r1 = sum ^ 0x6502;

  r0 = 0xf0000000 & (secret << 24);
  r2 = (secret << 4) & 0xff;  // 0x0f0
  r3 = secret & 0xff;

  r0 = r0 | r2;
  r2 = (r3 << 5) - r3;
  r1 += r2 + 0x26f5;
  r1 = 0x0ffff000 & (r1 << 12);

  // r0 r1r1r1r1 _ r2 _
  result = (r0 | r1);
  return result;
}

unsigned int generate_key(char * params)
{
  unsigned int seed = calc_seed(rnd_lc_get(0));

  unsigned int d = calc_dmy_key(params);
  unsigned int p = calc_pad_key(params, seed);

  return p | d;
}
