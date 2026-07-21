#pragma once

#include <stdio.h>
#include <stdlib.h>

static char *rfile(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;

    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return NULL; }
    long size = ftell(f);
    if (size < 0) { fclose(f); return NULL; }
    rewind(f);

    char *buf = malloc((size_t)size + 1);
    if (!buf) { fclose(f); return NULL; }

    size_t read = fread(buf, 1, (size_t)size, f);
    fclose(f);

    if (read != (size_t)size) { free(buf); return NULL; }

    buf[size] = '\0';
    return buf;
}
