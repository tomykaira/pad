#include "ruby.h"

void initialize_table();

unsigned int rnd_lc_get(unsigned int seed);
unsigned int calc_seed(unsigned int node);
unsigned int calc_dmy_key(char * params);
unsigned int calc_pad_key(char * params, unsigned int secret);
unsigned int generate_key(char * params);

VALUE wrap_rnd_lc_get(self, a_seed)
     VALUE self, a_seed;
{
  unsigned int seed, result;

  seed = NUM2UINT(a_seed);
  result = rnd_lc_get(a_seed);
  return UINT2NUM(result);
}

VALUE wrap_generate_key(self, a_params)
     VALUE self, a_params;
{
  unsigned int result;

  result = generate_key(StringValuePtr(a_params));
  return UINT2NUM(result);
}

void Init_pad_random()
{
  VALUE module;

  module = rb_define_module("PadRandom");
  rb_define_module_function(module, "rnd_lc_get", wrap_rnd_lc_get, 1);
  rb_define_module_function(module, "generate_key", wrap_generate_key, 1);
}
