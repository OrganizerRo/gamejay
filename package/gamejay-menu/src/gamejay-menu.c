#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <dirent.h>
#include <errno.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define MAX_ROMS 2048
#define MAX_PATH_LEN 1024

typedef struct {
    const char *name;
    const char *directory;
    const char *core;
} System;

typedef struct {
    char name[256];
    char path[MAX_PATH_LEN];
} Rom;

static const System systems[] = {
    {"Super Nintendo", "/mnt/roms/snes", "/usr/lib/libretro/snes9x2010_libretro.so"},
    {"Nintendo", "/mnt/roms/nes", "/usr/lib/libretro/fceumm_libretro.so"},
    {"Sega Genesis / 32X", "/mnt/roms/genesis", "/usr/lib/libretro/picodrive_libretro.so"},
    {"Arcade (MAME 2003-Plus)", "/mnt/roms/arcade", "/usr/lib/libretro/mame2003_plus_libretro.so"},
    {"PlayStation", "/mnt/roms/ps1", "/usr/lib/libretro/pcsx_rearmed_libretro.so"},
};

static int rom_compare(const void *left, const void *right)
{
    const Rom *a = left;
    const Rom *b = right;
    return strcasecmp(a->name, b->name);
}

static int load_roms(const char *directory, Rom *roms, size_t capacity)
{
    DIR *dir = opendir(directory);
    if (!dir)
        return 0;

    size_t count = 0;
    struct dirent *entry;
    while (count < capacity && (entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.')
            continue;
        int written = snprintf(roms[count].path, sizeof(roms[count].path),
                               "%s/%s", directory, entry->d_name);
        if (written < 0 || (size_t)written >= sizeof(roms[count].path))
            continue;
        snprintf(roms[count].name, sizeof(roms[count].name), "%s",
                 entry->d_name);
        count++;
    }
    closedir(dir);
    qsort(roms, count, sizeof(*roms), rom_compare);
    return (int)count;
}

static void draw_text(SDL_Renderer *renderer, TTF_Font *font,
                      const char *text, int x, int y, SDL_Color color)
{
    SDL_Surface *surface = TTF_RenderUTF8_Blended(font, text, color);
    if (!surface)
        return;
    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (texture) {
        SDL_Rect destination = {x, y, surface->w, surface->h};
        SDL_RenderCopy(renderer, texture, NULL, &destination);
        SDL_DestroyTexture(texture);
    }
    SDL_FreeSurface(surface);
}

static void draw_menu(SDL_Renderer *renderer, TTF_Font *font,
                      const char *title, const char *const *items,
                      int count, int selected, const char *footer)
{
    int width;
    int height;
    SDL_GetRendererOutputSize(renderer, &width, &height);
    SDL_SetRenderDrawColor(renderer, 8, 18, 36, 255);
    SDL_RenderClear(renderer);

    SDL_Rect panel = {width / 8, height / 10, width * 3 / 4, height * 4 / 5};
    SDL_SetRenderDrawColor(renderer, 18, 38, 70, 255);
    SDL_RenderFillRect(renderer, &panel);

    const SDL_Color white = {235, 240, 248, 255};
    const SDL_Color accent = {80, 210, 255, 255};
    const SDL_Color muted = {160, 176, 196, 255};
    draw_text(renderer, font, title, panel.x + 36, panel.y + 28, accent);

    int visible = (panel.h - 150) / 34;
    int first = selected >= visible ? selected - visible + 1 : 0;
    for (int i = first; i < count && i < first + visible; i++) {
        char line[300];
        snprintf(line, sizeof(line), "%c %s", i == selected ? '>' : ' ',
                 items[i]);
        draw_text(renderer, font, line, panel.x + 44,
                  panel.y + 88 + (i - first) * 34,
                  i == selected ? accent : white);
    }

    draw_text(renderer, font, footer, panel.x + 36,
              panel.y + panel.h - 44, muted);
    SDL_RenderPresent(renderer);
}

static int choose(SDL_Renderer *renderer, TTF_Font *font, const char *title,
                  const char *const *items, int count, const char *footer)
{
    if (count <= 0)
        return -1;

    int selected = 0;
    for (;;) {
        draw_menu(renderer, font, title, items, count, selected, footer);
        SDL_Event event;
        if (!SDL_WaitEvent(&event))
            continue;
        if (event.type == SDL_QUIT)
            return -2;
        if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_UP)
                selected = (selected + count - 1) % count;
            else if (event.key.keysym.sym == SDLK_DOWN)
                selected = (selected + 1) % count;
            else if (event.key.keysym.sym == SDLK_RETURN ||
                     event.key.keysym.sym == SDLK_SPACE)
                return selected;
            else if (event.key.keysym.sym == SDLK_ESCAPE)
                return -1;
        } else if (event.type == SDL_CONTROLLERBUTTONDOWN) {
            if (event.cbutton.button == SDL_CONTROLLER_BUTTON_DPAD_UP)
                selected = (selected + count - 1) % count;
            else if (event.cbutton.button == SDL_CONTROLLER_BUTTON_DPAD_DOWN)
                selected = (selected + 1) % count;
            else if (event.cbutton.button == SDL_CONTROLLER_BUTTON_A)
                return selected;
            else if (event.cbutton.button == SDL_CONTROLLER_BUTTON_B)
                return -1;
        }
    }
}

static void show_message(SDL_Renderer *renderer, TTF_Font *font,
                         const char *title, const char *message)
{
    const char *items[] = {message};
    draw_menu(renderer, font, title, items, 1, 0,
              "Press A, B, Enter, Space, or Escape");
    SDL_Event event;
    while (SDL_WaitEvent(&event)) {
        if (event.type == SDL_KEYDOWN ||
            event.type == SDL_CONTROLLERBUTTONDOWN ||
            event.type == SDL_QUIT)
            return;
    }
}

static int launch_game(const System *system, const char *rom)
{
    pid_t child = fork();
    if (child < 0)
        return -1;
    if (child == 0) {
        execl("/usr/bin/retroarch", "retroarch", "--config",
              "/etc/retroarch.cfg", "-L", system->core, rom, (char *)NULL);
        _exit(127);
    }

    int status;
    while (waitpid(child, &status, 0) < 0) {
        if (errno != EINTR)
            return -1;
    }
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

int main(void)
{
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_AUDIO) != 0)
        return 1;
    if (TTF_Init() != 0)
        return 1;

    for (int i = 0; i < SDL_NumJoysticks(); i++) {
        if (SDL_IsGameController(i))
            SDL_GameControllerOpen(i);
    }

    SDL_Window *window = SDL_CreateWindow(
        "GameJay", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        1280, 720, SDL_WINDOW_FULLSCREEN_DESKTOP);
    if (!window)
        return 1;
    SDL_Renderer *renderer = SDL_CreateRenderer(
        window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!renderer)
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    if (!renderer)
        return 1;

    TTF_Font *font = TTF_OpenFont(
        "/usr/share/fonts/ttf-dejavu/DejaVuSans.ttf", 24);
    if (!font)
        return 1;

    const int system_count = (int)(sizeof(systems) / sizeof(systems[0]));
    const char *system_names[system_count + 1];
    for (int i = 0; i < system_count; i++)
        system_names[i] = systems[i].name;
    system_names[system_count] = "Power off";

    bool running = true;
    while (running) {
        int selected = choose(renderer, font, "GameJay",
                              system_names, system_count + 1,
                              "D-pad: move   A: select   B: back");
        if (selected == -2)
            break;
        if (selected < 0)
            continue;
        if (selected == system_count) {
            sync();
            execl("/sbin/poweroff", "poweroff", (char *)NULL);
            continue;
        }

        Rom *roms = calloc(MAX_ROMS, sizeof(*roms));
        const char **rom_names = calloc(MAX_ROMS, sizeof(*rom_names));
        if (!roms || !rom_names) {
            free(roms);
            free(rom_names);
            continue;
        }
        int rom_count = load_roms(systems[selected].directory, roms, MAX_ROMS);
        for (int i = 0; i < rom_count; i++)
            rom_names[i] = roms[i].name;
        if (rom_count == 0) {
            show_message(renderer, font, systems[selected].name,
                         "No ROMs found on the ROMDATA partition");
        } else {
            int rom = choose(renderer, font, systems[selected].name,
                             rom_names, rom_count,
                             "D-pad: move   A: play   B: systems");
            if (rom >= 0) {
                SDL_SetWindowFullscreen(window, 0);
                launch_game(&systems[selected], roms[rom].path);
                SDL_SetWindowFullscreen(window, SDL_WINDOW_FULLSCREEN_DESKTOP);
            }
        }
        free(rom_names);
        free(roms);
    }

    TTF_CloseFont(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();
    return 0;
}
