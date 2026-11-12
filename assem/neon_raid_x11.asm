; NEON RAID - X11 GUI edition for Linux x86-64.
; Uses Xlib directly; no game framework or assets.
; Build:
;   nasm -f elf64 neon_raid_x11.asm -o neon_raid_x11.o
;   gcc neon_raid_x11.o -o neon_raid_x11 -lX11

global main
extern XOpenDisplay, XDefaultScreen, XRootWindow, XCreateSimpleWindow
extern XSelectInput, XMapWindow, XCreateGC, XNextEvent, XPending
extern XLookupKeysym, XDrawString, XFillRectangle, XSetForeground
extern XFlush, XCloseDisplay, usleep

section .data
    title db 'NEON RAID // X11',0
    hud db 'WASD MOVE   SPACE FIRE   X DASH   Q QUIT',0
    display dq 0
    window dq 0
    gc dq 0
    event times 24 dq 0
    player_x dd 70
    player_y dd 70
    enemy_x dd 600,760,880
    enemy_y dd 150,350,500
    enemy_alive db 1,1,1
    quit db 0
    black dq 0
    cyan dq 0
    red dq 0
    white dq 0

section .text
main:
    sub rsp, 40
    xor edi, edi
    call XOpenDisplay
    mov [display], rax
    test rax, rax
    jz .exit
    mov rdi, rax
    call XDefaultScreen
    mov ebx, eax
    mov rdi, [display]
    mov esi, ebx
    call XRootWindow
    mov r12, rax
    mov rdi, [display]
    mov rsi, r12
    mov edx, 40
    mov ecx, 40
    mov r8d, 960
    mov r9d, 640
    sub rsp, 32
    mov qword [rsp], 0x101820
    mov qword [rsp+8], 0x19
    mov qword [rsp+16], 0x1a
    call XCreateSimpleWindow
    add rsp, 32
    mov [window], rax
    mov rdi, [display]
    mov rsi, rax
    mov edx, 0x00008001
    call XSelectInput
    mov rdi, [display]
    mov rsi, [window]
    call XMapWindow
    mov rdi, [display]
    mov rsi, [window]
    call XCreateGC
    mov [gc], rax
.loop:
    cmp byte [quit], 1
    je .close
    mov rdi, [display]
    call XPending
    test eax, eax
    jz .draw
    mov rdi, [display]
    lea rsi, [event]
    call XNextEvent
    cmp dword [event], 2
    je .key
    cmp dword [event], 12
    je .expose
    jmp .loop
.key:
    cmp byte [event+28], 'q'
    je .set_quit
    cmp byte [event+28], 'Q'
    je .set_quit
    cmp byte [event+28], 'a'
    jne .key_d
    sub dword [player_x], 8
.key_d:
    cmp byte [event+28], 'd'
    jne .key_w
    add dword [player_x], 8
.key_w:
    cmp byte [event+28], 'w'
    jne .key_s
    sub dword [player_y], 8
.key_s:
    cmp byte [event+28], 's'
    jne .loop
    add dword [player_y], 8
    jmp .loop
.set_quit:
    mov byte [quit], 1
    jmp .loop
.expose:
.draw:
    call draw_scene
    mov edi, 30000
    call usleep
    jmp .loop
.close:
    mov rdi, [display]
    call XCloseDisplay
.exit:
    xor eax, eax
    add rsp, 40
    ret

draw_scene:
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, 0x101820
    call XSetForeground
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    xor ecx, ecx
    xor r8d, r8d
    mov r9d, 960
    sub rsp, 24
    mov dword [rsp], 640
    mov dword [rsp+8], 0
    mov dword [rsp+16], 0
    call XFillRectangle
    add rsp, 24
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, 0x00D7FF
    call XSetForeground
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, [player_x]
    mov r8d, [player_y]
    mov r9d, 28
    sub rsp, 8
    mov dword [rsp], 28
    call XFillRectangle
    add rsp, 8
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    xor ecx, ecx
    mov r8d, 16
    lea r9, [hud]
    sub rsp, 8
    mov dword [rsp], 42
    call XDrawString
    add rsp, 8
    mov rdi, [display]
    call XFlush
    ret
