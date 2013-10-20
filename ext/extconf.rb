require 'mkmf'

$CFLAGS += " --std=c99"
create_makefile('pad_random')
