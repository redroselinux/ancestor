#pragma once

#include <stdlib.h>
#include <string.h>

/*
  https://github.com/mostypc123/better_string
  licensed under the MIT license
*/

typedef struct {
  char* data;
  size_t size;
} string;

/* Init a string. Returns NULL on failure. 
 * Strings must be freed by using str_free().*/
static string* str_init() {
  // first allocate initial data
  char* data = malloc(1);
  if (data == NULL) return NULL;
  
  // then allocate the string struct
  string* result = malloc(sizeof(string));
  if (result == NULL) return NULL;
  
  // set values
  result->size = 1;
  result->data = data;
  *(result->data) = '\0';
  
  return result;
}

/* Resize a string and put a character at the end.
 * Returns 0 on success and -1 on failure. */
static int str_addc(string* st, char ch) {
  size_t len = strlen(st->data);
  char* new_data = realloc(st->data, st->size + 1);
  if (new_data == NULL) return -1;
  
  st->data = new_data;
  st->size++;
  st->data[len] = ch;
  st->data[len + 1] = '\0';
  
  return 0;
}

/* str_addc() wrapper that adds a cstring to a string.
 * Same return values as in str_addc. */
static int str_add(string* st, char* cstr) {
  char *p_cstr = cstr;
  while (*p_cstr) {
    if (str_addc(st, *p_cstr) == -1) return -1;
    p_cstr++;
  }
  return 0;
}

/* Turn a string into a cstring. */
static inline char* c_str(const string* st) {
  return strdup(st->data);
}

/* Turns a cstring to a string.
 * As in str_init, caller needs to free(). 
 * Returns NULL on failure. */
static string* c_str_to_str(char* cstr) {
  string* result = str_init();
  if (result == NULL) return NULL;
  str_add(result, cstr);
  return result;
}

/* Turns a char into a string.
 * As in str_init, caller needs to free(). 
 * Returns NULL on failure. */
static inline string* char_to_str(char ch) {
  string* result = str_init();
  if (result == NULL) return NULL;
  str_addc(result, ch);
  return result;
}

/* Return the lenght of a string. */
static inline size_t str_len(string* st) {
  return strlen(st->data);
}

/* Function to free the string in one call. */
static inline void str_free(string* st) {
  free(st->data);
  free(st);
}
