#pragma once

#include <stdlib.h>
#include "../vendor/mostypc123/better_string/string.h"

static inline char* home() {
  return getenv("HOME");
}

/* Put the home directory's path before 'path'.
 * This function allocates on the heap. */
static char* expand_home(const char* path) {
  string* result = str_init();
  str_add(result, home());
  str_add(result, (char*)path);
  char* cstr = c_str(result);
  str_free(result);
  return cstr;
}
