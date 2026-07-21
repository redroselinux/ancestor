#include "utils/homedir.h"
#include "commands/build.h"
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

int main(int argc, char* argv[]) {
  int build_all = 0;
  int has_package = 0;
  char package[512] = {0};
  char dir[512];
  
  strncpy(dir, expand_home(".local/share/ancestor"), 512);
  mkdir(expand_home(".local"), 0755);
  mkdir(expand_home(".local/share"), 0755);
  mkdir(expand_home(".local/share/ancestor"), 0755);
  
  if (argc == 1) {
    puts("warn: using default options");
  } else {
    for (int i = 1; i < argc; i++) {
      if (!strcmp(argv[i], "--dir") && i+1 < argc) {
        strncpy(dir, argv[i+1], 512);
      } else if (!strcmp(argv[i], "--pkg") && i+1 < argc) {
        strncpy(package, argv[i+1], 512);
        has_package = 1;
      }
    }
  }
  
  if (has_package) {
    auto ret = build(package, dir);
    ancestor_perror(&ret, package);
  }
}
