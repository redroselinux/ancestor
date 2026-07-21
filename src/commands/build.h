#pragma once

typedef struct {
  int type;
  char* info;
}  ancestor_return_t;
#define SUCCESS 0
#define FAIL 1
#define PARTIAL_FAIL 2

void ancestor_perror(ancestor_return_t* t, char* package);
static inline ancestor_return_t mkret(int status, char* msg);
ancestor_return_t build(char* pkg_name, char* dir);
