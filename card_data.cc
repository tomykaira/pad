#include <iostream>
#include <cstdio>
#include <stdint.h>

#define DATA_LEN (1024*1024)

typedef union{	uint32_t i; float f;} conv;

int read_int(FILE * fp)
{
  unsigned char d[4];
  fread(d, sizeof(char), 4, fp);
  return (d[0] << 24) + (d[1] << 16) + (d[2] << 8) + (d[3]);
}

int read_float(FILE * fp)
{
  conv c;
  c.i = (uint32_t)read_int(fp);
  return c.f;
}

unsigned int read_hw(FILE * fp)
{
  unsigned char d[2];
  fread(d, sizeof(char), 2, fp);
  return (d[2] << 8) + (d[3]);
}

unsigned int read_byte(FILE * fp)
{
  unsigned char d;
  fread(&d, sizeof(char), 2, fp);
  return d;
}

int main(int argc, char *argv[])
{
  if (argc < 2) {
    std::cerr << "Not enough arguments" << std::endl;
    return 1;
  }

  FILE * fp = fopen("Documents_5.0/data021.bin.dec", "rb");
  if (fp == NULL) {
    std::cerr << "File open error" << std::endl;
    return 1;
  }

  // header
  fseek(fp, 8, SEEK_SET);
  int flag1 = read_int(fp);
  read_int(fp);
  int count = read_int(fp);
  read_int(fp);

  printf("%d cards\n", count);

  for (int i = 0; i < count; ++i) {
    char name[0x61];
    fread(name, 1, 0x61, fp);
    fseek(fp, 0x13c - 0x61, SEEK_CUR);
    printf("%i: %s\n", i, name);
    continue;
    read_byte(fp);
    read_byte(fp);
    read_hw(fp);
    read_hw(fp);
    read_byte(fp);
    read_hw(fp);

    if (flag1 >= 2) {
      read_int(fp);
      read_int(fp);
      read_int(fp);
    } else {
      read_hw(fp);
      read_hw(fp);
      read_hw(fp);
    }

    for (int j = 0; j < 16; ++j) {
      read_float(fp);
    }

    for (int j = 0; j < 7; ++j) {
      read_hw(fp);
    }

    for (int j = 0; j < 12; ++j) {
      read_float(fp);
    }

    if (flag1 >= 2) {
      read_int(fp);
      read_int(fp);
    } else {
      read_hw(fp);
      read_hw(fp);
    }

    for (int j = 0; j < 6; ++j) {
      read_hw(fp);
    }

    if (flag1 >= 2) {
      read_byte(fp);
      read_byte(fp);
      if (flag1 <= 3) {
        // ...
      } else {
        read_hw(fp);
      }

      for (int j = 0; j < 5; ++j) {
        read_hw(fp);
      }
      for (int r10 = 0; r10 < 10; ++r10) {
        read_byte(fp);
        read_byte(fp);
        read_byte(fp);
      }
      if (flag1 > 4) {
        read_byte(fp);
        read_byte(fp);
        read_hw(fp);
        read_hw(fp);
        read_hw(fp);
        read_hw(fp);
        read_hw(fp);
      }

    } else {
      // ...
    }
  }

  fclose(fp);
  return 0;
}
