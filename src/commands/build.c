#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "../utils/join_str.h"
#include "../utils/readfile.h"
#include "build.h"
#include <stdio.h>
#include <sys/stat.h>

void ancestor_perror(ancestor_return_t* t, char* package) {
  switch (t->type) {
    case 0:
      printf("[%s] ok: built successfully\n", package);
      break;
    case 1:
      printf("[%s] error: build failed (%s)\n", package, t->info);
      break;
    case 2:
      printf("[%s] warning: partial failure (%s)\n", package, t->info);
      break;
    default:
      printf("[%s] warning: no status\n", package);
      break;
  }
}

static inline ancestor_return_t mkret(int status, char* msg) {
  return (ancestor_return_t){status, msg};
}

ancestor_return_t build(char* pkg_name, char* dir) {
  char* path = join_str((char*[]){dir, pkg_name}, "/", 2);
  
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  
  // this whole project is just heap allocs atp
  string* workdir = str_init();
  if (workdir == NULL) return mkret(1, "failed to allocate memory");
  str_add(workdir, dir);
  str_add(workdir, "/workdir_package_");
  str_add(workdir, pkg_name);
  mkdir(c_str(workdir), 0755);
  
  lua_pushstring(L, c_str(workdir));
  lua_setglobal(L, "build_dir");
  
  str_free(workdir);
  
  if (luaL_dofile(L, path) != LUA_OK) {
    string* result = str_init();
    if (result == NULL) return mkret(1, "failed to allocate memory");
    str_add(result, "error: lua: ");
    str_add(result, lua_tostring(L, -1));
    char* cstr = c_str(result);
    str_free(result);
    lua_close(L);
    return mkret(1, cstr);
  }

  lua_close(L);
  
  // if you hate a lot of allocs, close your eyes. thank you.
  string* spath = str_init();
  if (spath == NULL) return mkret(1, "failed to allocate memory");
  str_add(spath, dir);
  str_add(spath, "/status_");
  str_add(spath, pkg_name);
  string* scpath = str_init();
  if (scpath == NULL) return mkret(1, "failed to allocate memory");
  str_add(scpath, spath->data); // c_str() does strdup(), this is faster  
  str_add(scpath, "_code");
  char* cspath = c_str(spath); // status: built package path
  char* cscpath = c_str(scpath); // status: code (0, 1, 2), check the #defines
  str_free(spath);
  str_free(scpath);
  
  // more heap allocs because like why not
  char* out = rfile(cspath);
  if (out == NULL) return mkret(1, "failed to read out file");
  char* statusc = rfile(cscpath);
  if (statusc == NULL) return mkret(1, "failed to read statusc file");
  
  int c;
  switch (*statusc) {
    case '0':
      c = 0; break;
    case '1':
      c = 1; break;
    case '2':
      c = 2; break;
    default:
      printf("[%s] warning: failed to get status code\n", pkg_name);
      c = 0; break;
  }
  
  auto ret = mkret(c, out);
  
  free(statusc);
  free(out);
  
  return ret;
}
