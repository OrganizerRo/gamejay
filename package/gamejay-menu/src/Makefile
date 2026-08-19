PKG_CONFIG ?= pkg-config
CPPFLAGS += $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_ttf)
CFLAGS += -O2 -Wall -Wextra -Werror
LDLIBS += $(shell $(PKG_CONFIG) --libs sdl2 SDL2_ttf)

.PHONY: all clean

all: gamejay-menu

gamejay-menu: gamejay-menu.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $< $(LDFLAGS) $(LDLIBS)

clean:
	rm -f gamejay-menu
