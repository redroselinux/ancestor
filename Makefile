CC := gcc
CFLAGS := -std=c23 -Wall -Wextra -O2 -Isrc/vendor/lua/lua-5.5.0/src
LDFLAGS := -lm

SOURCES = $(wildcard src/*.c src/*/*.c)
OBJECTS = $(SOURCES:src/%.c=obj/%.o)
TARGET = ancestor

all: $(TARGET)

LUA_LIB := src/vendor/lua/liblua.a

$(TARGET): $(OBJECTS) $(LUA_LIB)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS) $(LUA_LIB) $(LDFLAGS)

$(LUA_LIB):
	cd src/vendor/lua/lua-5.5.0 && $(MAKE) -j $(shell nproc)
	cp src/vendor/lua/lua-5.5.0/src/liblua.a $(LUA_LIB)

obj/%.o: src/%.c | obj
	$(CC) $(CFLAGS) -c -o $@ $<
	
obj:
	mkdir -p $@ $@/commands $@/utils

clean:
	rm -rf obj $(TARGET)

distclean: clean
	rm -rf $(LUA_LIB)

rebuild: clean all

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean rebuild run
