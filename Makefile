.PHONY: all clean

LUA_CLIB_PATH ?= common/luaclib
CFLAGS = -g -O2 -Wall -std=gnu99
SHARED := -fPIC --shared
LUA_INC_PATH ?= 3rd/skynet/3rd/lua

all : $(LUA_CLIB_PATH)/clientcore.so

$(LUA_CLIB_PATH) :
	mkdir -p $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/clientcore.so : common/luaclib_src/lua-client.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(LUA_INC_PATH) $^ -o $@ -lpthread -lrt

clean:
	rm -f $(LUA_CLIB_PATH)/*.so
	rm -rf $(LUA_CLIB_PATH)