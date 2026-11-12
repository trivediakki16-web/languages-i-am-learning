; NEON RAID - native Win32 GUI edition
; Build with NASM and a MinGW linker already present in the environment:
;   nasm -f win64 neon_raid_win32.asm -o neon_raid_win32.o
;   gcc neon_raid_win32.o -o neon_raid_win32.exe -mwindows -lgdi32 -luser32 -lkernel32

default rel
global main
extern GetModuleHandleA, RegisterClassExA, CreateWindowExA, ShowWindow
extern UpdateWindow, GetMessageA, TranslateMessage, DispatchMessageA
extern DefWindowProcA, PostQuitMessage, BeginPaint, EndPaint
extern FillRect, CreateSolidBrush, DeleteObject, TextOutA, GetStockObject
extern GetClientRect, SetTimer, KillTimer, GetAsyncKeyState, InvalidateRect

section .data
    class_name db 'NeonRaidWindow',0
    title db 'NEON RAID // WIN32',0
    hud db 'WASD MOVE   SPACE FIRE   X DASH   Q QUIT',0
    font_name db 'Consolas',0
    msg dq 0,0,0,0,0,0,0
    player_x dd 60
    player_y dd 60
    hp dd 5
    score dd 0
    energy dd 8
    enemy_x dd 500,700,850,0,0,0
    enemy_y dd 130,330,500,0,0,0
    enemy_alive db 1,1,1,0,0,0
    bullet_x dd 0,0,0,0,0,0,0,0
    bullet_y dd 0,0,0,0,0,0,0,0
    bullet_dx dd 0,0,0,0,0,0,0,0
    bullet_dy dd 0,0,0,0,0,0,0,0
    bullet_alive db 0,0,0,0,0,0,0,0
    player_brush dq 0
    enemy_brush dq 0
    bullet_brush dq 0
    wall_brush dq 0

section .bss
    wc resb 80
    ps resb 72
    rect resd 4
    psn resd 1
    hwnd resq 1
    hinst resq 1
    paint resb 72

section .text
main:
    sub rsp, 40
    xor ecx, ecx
    call GetModuleHandleA
    mov [hinst], rax
    lea rcx, [wc]
    mov dword [rcx], 80
    mov dword [rcx+8], 0x0003
    lea rax, [WndProc]
    mov [rcx+16], rax
    mov dword [rcx+24], 0
    mov dword [rcx+28], 0
    mov rax, [hinst]
    mov [rcx+32], rax
    mov qword [rcx+40], 0
    mov qword [rcx+48], 0
    mov qword [rcx+56], 0
    lea rax, [class_name]
    mov [rcx+64], rax
    mov qword [rcx+72], 0
    call RegisterClassExA
    xor ecx, ecx
    lea rdx, [class_name]
    lea r8, [title]
    mov r9d, 0x10CF0000
    mov qword [rsp+32], 100
    mov qword [rsp+40], 100
    mov qword [rsp+48], 960
    mov qword [rsp+56], 640
    mov qword [rsp+64], 0
    mov qword [rsp+72], 0
    mov qword [rsp+80], 0
    mov qword [rsp+88], 0
    call CreateWindowExA
    mov [hwnd], rax
    mov rcx, rax
    mov edx, 1
    call ShowWindow
    mov rcx, [hwnd]
    call UpdateWindow
.messages:
    lea rcx, [msg]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageA
    test eax, eax
    jz .exit
    lea rcx, [msg]
    call TranslateMessage
    lea rcx, [msg]
    call DispatchMessageA
    jmp .messages
.exit:
    xor eax, eax
    add rsp, 40
    ret

WndProc:
    cmp edx, 1
    je .create
    cmp edx, 2
    je .destroy
    cmp edx, 0x000F
    je .paint
    cmp edx, 0x0113
    je .timer
    jmp DefWindowProcA
.create:
    mov rcx, rdi
    mov edx, 1
    mov r8d, 16
    xor r9d, r9d
    call SetTimer
    xor eax, eax
    ret
.timer:
    call game_tick
    mov rcx, [hwnd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call InvalidateRect
    xor eax, eax
    ret
.paint:
    sub rsp, 40
    mov rcx, rdi
    lea rdx, [paint]
    call BeginPaint
    mov r12, rax
    mov rcx, r12
    lea rdx, [rect]
    call GetClientRect
    call paint_scene
    mov rcx, [hwnd]
    lea rdx, [paint]
    call EndPaint
    add rsp, 40
    xor eax, eax
    ret
.destroy:
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax
    ret

game_tick:
    mov ecx, 'Q'
    call GetAsyncKeyState
    test ax, ax
    jnz .quit
    mov ecx, 'A'
    call GetAsyncKeyState
    test ax, ax
    jz .right
    sub dword [player_x], 5
.right:
    mov ecx, 'D'
    call GetAsyncKeyState
    test ax, ax
    jz .up
    add dword [player_x], 5
.up:
    mov ecx, 'W'
    call GetAsyncKeyState
    test ax, ax
    jz .down
    sub dword [player_y], 5
.down:
    mov ecx, 'S'
    call GetAsyncKeyState
    test ax, ax
    jz .fire
    add dword [player_y], 5
.fire:
    mov ecx, 0x20
    call GetAsyncKeyState
    test ax, ax
    jz .done
    call spawn_bullet
.done:
    ret
.quit:
    xor ecx, ecx
    call PostQuitMessage
    ret

spawn_bullet:
    xor ecx, ecx
.find:
    cmp byte [bullet_alive + rcx], 0
    je .slot
    inc ecx
    cmp ecx, 8
    jb .find
    ret
.slot:
    mov byte [bullet_alive + rcx], 1
    mov eax, [player_x]
    mov [bullet_x + rcx*4], eax
    mov eax, [player_y]
    mov [bullet_y + rcx*4], eax
    mov dword [bullet_dx + rcx*4], 9
    ret

paint_scene:
    mov rcx, r12
    mov edx, 0x00101828
    call CreateSolidBrush
    mov r13, rax
    mov rcx, r12
    lea rdx, [rect]
    mov r8, r13
    call FillRect
    mov rcx, r13
    call DeleteObject
    mov rcx, r12
    mov edx, 0x0000D7FF
    call CreateSolidBrush
    mov r13, rax
    mov eax, [player_x]
    mov [rect], eax
    mov eax, [player_y]
    mov [rect+4], eax
    mov eax, [player_x]
    add eax, 26
    mov [rect+8], eax
    mov eax, [player_y]
    add eax, 26
    mov [rect+12], eax
    mov rcx, r12
    lea rdx, [rect]
    mov r8, r13
    call FillRect
    mov rcx, r13
    call DeleteObject
    mov rcx, r12
    lea rdx, [hud]
    mov r8d, -1
    mov r9d, 16
    call TextOutA
    ret
