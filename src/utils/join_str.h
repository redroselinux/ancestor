#pragma once

#include "../vendor/mostypc123/better_string/string.h"

static char* join_str(char** parts, char* delim, int count) {
  string* result = str_init();
  for (int i = 0; i < count; i++) {
    str_add(result, parts[i]);
    if (i + 1 < count) str_add(result, delim);
  }
  char* cstr = c_str(result);
  str_free(result);
  return cstr;
}
