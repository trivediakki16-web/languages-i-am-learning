# Neon Raid

`neon_vault.asm` is a dependency-free terminal arena game for NASM on
Linux x86-64. It uses direct Linux syscalls and ANSI terminal control:
there is no game engine, runtime, or additional library in this folder.

## Play

Use the NASM and linker commands already available in your VS Code
environment:

```sh
nasm -f elf64 neon_vault.asm -o neon_vault.o
ld neon_vault.o -o neon_vault
./neon_vault
```

Controls:

- `W`, `A`, `S`, `D`: move
- `SPACE`: fire in the current facing direction
- `X`: dash two tiles, consuming energy
- `Q`: quit

Destroy the sentries across three waves, collect the `*` core, and reach
the `O` extraction gate. The `@` is the player, `X` marks enemies, and `>`
marks bolts. The game tracks hull, energy, score, and wave progress, and
restores the terminal settings when it ends.

This source targets Linux x86-64 because it uses Linux syscalls and the
Linux `termios` layout. It does not add or install a compiler; the commands
above only use tools that must already exist.

## GUI editions

The folder also contains native GUI starting points:

### Windows Win32 + GDI

[`neon_raid_win32.asm`](./neon_raid_win32.asm) opens a native Windows
window and draws the player, arena, and HUD through Win32/GDI:

```sh
nasm -f win64 neon_raid_win32.asm -o neon_raid_win32.o
gcc neon_raid_win32.o -o neon_raid_win32.exe -mwindows -lgdi32 -luser32 -lkernel32
```

### Linux X11

[`neon_raid_x11.asm`](./neon_raid_x11.asm) uses Xlib for a native Linux
window:

```sh
nasm -f elf64 neon_raid_x11.asm -o neon_raid_x11.o
gcc neon_raid_x11.o -o neon_raid_x11 -lX11
```

These GUI sources intentionally use the operating system APIs directly.
They require the platform's existing NASM, linker, and development libraries;
nothing is installed by this repository.

## Direct binary experiment

[`hello_direct.exe`](./hello_direct.exe) is a Windows x64 PE executable
created directly as binary bytes, without NASM, a compiler, or a linker. It
prints `Hello from a direct EXE!` and exits through imported `KERNEL32.dll`
functions. This is included as a compact demonstration of the executable
format; the games remain source-based because raw PE authoring becomes
fragile very quickly.

## Why this design

Compared with classic assembly-game examples such as VGA Pong and
boot-sector Snake, Neon Raid keeps the explicit input/update/draw loop but
pushes the simulation further: fixed-size projectile pools, enemy AI,
multiple waves, collision damage, a dash resource, scoring, and a final
extraction condition. It remains readable because every game object is
stored in static memory and every update is explicit.
