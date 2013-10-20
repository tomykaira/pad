#include <iostream>
#include <cstdio>

#define DATA_LEN (1024*1024)

#define WORD(x) ((x)[0] + ((x)[1] << 8) + ((x)[2] << 16) + ((x)[3] << 24));
#define HALFWORD(x) ((x)[0] + ((x)[1] << 8));

unsigned int randomSeeds[8] = {0x229ac18b, 0xdfb7151b, 0xeb04a9cb, 0x66bf6638,
                               0x0000bd09, 0x00000cab, 0x000069f4, 0x0000e6c3};

void RndLcSeed(unsigned int seed, unsigned int value)
{
  randomSeeds[seed] = value;
}

unsigned int RndLcGet(int seed)
{
  unsigned int r3 = 0x343fd, r9 = 0x269ec3;

  unsigned int r2 = randomSeeds[seed];
  r2 = r2*r3 + r9;
  randomSeeds[seed] = r2;

  unsigned int result = r2 >> 16;

  return result;
}

void encdec(char * data, int length)
{
  RndLcSeed(3, data[1]);
  unsigned int rest = length - 2;

  data += 2;
  while (rest--) {
    *data ^= RndLcGet(3);
    data++;
  }
}


int main(int argc, char *argv[])
{
  char filename[1024];
  char data[DATA_LEN];
  int off = 8;

  if (argc < 2) {
    std::cerr << "Not enough arguments" << std::endl;
    return 1;
  }

  FILE * fp = fopen(argv[1], "rb");
  if (fp == NULL) {
    std::cerr << "File open error" << std::endl;
    return 1;
  }
  size_t file_length = fread(data, sizeof(char), DATA_LEN, fp);
  fclose(fp);

  // decode
  encdec(data, file_length);

  // derandomize
  unsigned int key = HALFWORD(data + 2 + off);
  data[4 + off] = data[4 + off] ^ key;
  data[5 + off] = data[5 + off] ^ (key + 0xa6);
  data[6 + off] = data[6 + off] ^ (key + 0x4c);
  data[7 + off] = data[7 + off] ^ (key + 0xf2);

  unsigned int length = WORD(data + 4 + off);

  printf("length: %u\n", length);

  if (length > file_length) {
    std::cerr << "detected length is too big" << std::endl;
    return 1;
  }
  char * start = data + off + 8; // r0
  key = key + 0x298;     // r2
  unsigned int counter = 0;       // r3
  unsigned int step = 0xa6;       // r4

  do {
    start[counter] = start[counter] ^ key;
    key = (key & 0xffff) + step;
    counter ++;
  } while (counter < length);

  sprintf(filename, "%s.dec", argv[1]);
  fp = fopen(filename, "wb");
  fwrite(data + off, sizeof(char), file_length - off, fp);
  fclose(fp);
  return 0;
}
