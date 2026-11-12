; NEON RAID
; A turn-based terminal arena written directly for Linux x86-64.
;
; WASD  move        SPACE  fire in the facing direction
; X    dash         Q      quit
;
; Clear three waves, collect the core, and reach the extraction gate.
; This intentionally uses no libc, runtime, engine, or external assets.

global _start

section .data
    title db 27, '[H', 27, '[2J', 27, '[96mNEON RAID', 27, '[0m', 10
          db 'WASD move  SPACE fire  X dash  Q quit', 10
          db 'Destroy the sentries, steal the core, reach the gate.', 10, 10
    title_len equ $ - title
    map_data db '########################'
             db '#..#......#............#'
             db '#..#......#..#######...#'
             db '#..####...#..#.....#..#'
             db '#.........#..#.....#...#'
             db '#####.#####..#.....#...#'
             db '#.....#......#.....#...#'
             db '#.....#..###########...#'
             db '#.....#................#'
             db '#.....#######.##########'
             db '#...........#..........#'
             db '########################'
    map_w equ 24
    map_h equ 12
    core_x equ 20
    core_y equ 10
    gate_x equ 22
    gate_y equ 1
    wave_total equ 3
    banner db 10, 27, '[93mWAVE ', 27, '[0m'
    banner_len equ $ - banner
    score_text db '  SCORE '
    score_len equ $ - score_text
    hp_text db '  HULL '
    hp_len equ $ - hp_text
    energy_text db '  ENERGY '
    energy_len equ $ - energy_text
    core_text db '  CORE '
    core_len equ $ - core_text
    hint db 10, 27, '[90m@ pilot  > bolt  X sentry  * core  O exit', 27, '[0m', 10
    hint_len equ $ - hint
    win_text db 10, 27, '[92mEXTRACTION COMPLETE', 27, '[0m', 10
              db 'The raid is over. Final score: '
    win_len equ $ - win_text
    lose_text db 10, 27, '[91mHULL BREACHED', 27, '[0m', 10
               db 'The station wins this round. Score: '
    lose_len equ $ - lose_text
    quit_text db 10, 'Raid aborted. Score: '
    quit_len equ $ - quit_text
    ansi_home db 27, '[H'
    ansi_home_len equ $ - ansi_home
    newline db 10
    player_char db '@'
    enemy_char db 'X'
    bolt_char db '>'
    core_char db '*'
    gate_char db 'O'
    floor_char db '.'

section .bss
    old_termios resb 60
    new_termios resb 60
    terminal_ready resb 1
    input resb 1
    one_char resb 1
    number resb 3
    player_x resb 1
    player_y resb 1
    facing resb 1
    hp resb 1
    energy resb 1
    wave resb 1
    score resd 1
    core_found resb 1
    enemy_x resb 3
    enemy_y resb 3
    enemy_alive resb 3
    enemy_dir resb 3
    bullet_x resb 4
    bullet_y resb 4
    bullet_dx resb 4
    bullet_dy resb 4
    bullet_alive resb 4
    tick resb 1

section .text

_start:
    cld
    call setup_terminal
    call new_game

.loop:
    call draw
    call read_key
    cmp byte [input], 'q'
    je .quit
    cmp byte [input], 'Q'
    je .quit
    call player_action
    call advance_bullets
    call move_enemies
    call collect_core
    call check_damage
    call next_wave
    cmp byte [hp], 0
    je .lose
    cmp byte [core_found], 1
    jne .loop
    cmp byte [player_x], gate_x
    jne .loop
    cmp byte [player_y], gate_y
    jne .loop
    jmp .win

.win:
    call restore_terminal
    mov rsi, win_text
    mov rdx, win_len
    call write_stdout
    call print_score
    jmp .pause
.lose:
    call restore_terminal
    mov rsi, lose_text
    mov rdx, lose_len
    call write_stdout
    call print_score
    jmp .pause
.quit:
    call restore_terminal
    mov rsi, quit_text
    mov rdx, quit_len
    call write_stdout
    call print_score
.pause:
    call read_key
    mov rax, 60
    xor rdi, rdi
    syscall

new_game:
    mov byte [player_x], 1
    mov byte [player_y], 1
    mov byte [facing], 1
    mov byte [hp], 5
    mov byte [energy], 8
    mov byte [wave], 1
    mov byte [core_found], 0
    mov byte [tick], 0
    mov dword [score], 0
    mov byte [enemy_x + 0], 8
    mov byte [enemy_y + 0], 1
    mov byte [enemy_dir + 0], 1
    mov byte [enemy_x + 1], 16
    mov byte [enemy_y + 1], 4
    mov byte [enemy_dir + 1], -1
    mov byte [enemy_x + 2], 19
    mov byte [enemy_y + 2], 8
    mov byte [enemy_dir + 2], 1
    mov byte [enemy_alive + 0], 1
    mov byte [enemy_alive + 1], 1
    mov byte [enemy_alive + 2], 1
    xor eax, eax
.clear_bullets:
    mov byte [bullet_alive + rax], 0
    inc eax
    cmp eax, 4
    jb .clear_bullets
    ret

setup_terminal:
    mov rax, 16
    xor rdi, rdi
    mov rsi, 0x5401
    mov rdx, old_termios
    syscall
    test rax, rax
    js .done
    mov rsi, old_termios
    mov rdi, new_termios
    mov rcx, 60
    rep movsb
    and dword [new_termios + 12], 0xfffffff5
    mov byte [new_termios + 22], 0
    mov byte [new_termios + 23], 1
    mov rax, 16
    xor rdi, rdi
    mov rsi, 0x5402
    mov rdx, new_termios
    syscall
    test rax, rax
    js .done
    mov byte [terminal_ready], 1
.done:
    ret

restore_terminal:
    cmp byte [terminal_ready], 1
    jne .done
    mov rax, 16
    xor rdi, rdi
    mov rsi, 0x5402
    mov rdx, old_termios
    syscall
.done:
    ret

read_key:
    mov byte [input], 0
    xor eax, eax
    xor edi, edi
    mov rsi, input
    mov edx, 1
    syscall
    test rax, rax
    jg .done
    mov byte [input], 0
.done:
    ret

player_action:
    cmp byte [input], ' '
    je .fire
    cmp byte [input], 'x'
    je .dash
    cmp byte [input], 'X'
    je .dash
    call try_move
    ret
.fire:
    call fire_bullet
    ret
.dash:
    cmp byte [energy], 0
    je .done
    dec byte [energy]
    call try_move
    call try_move
.done:
    ret

try_move:
    xor eax, eax
    xor ebx, ebx
    mov al, [player_x]
    mov bl, [player_y]
    cmp byte [input], 'a'
    jne .right
    mov byte [facing], 3
    dec al
    jmp .attempt
.right:
    cmp byte [input], 'd'
    jne .up
    mov byte [facing], 1
    inc al
    jmp .attempt
.up:
    cmp byte [input], 'w'
    jne .down
    mov byte [facing], 0
    dec bl
    jmp .attempt
.down:
    cmp byte [input], 's'
    jne .done
    mov byte [facing], 2
    inc bl
.attempt:
    cmp al, map_w
    jae .done
    cmp bl, map_h
    jae .done
    movzx rcx, bl
    imul rcx, map_w
    movzx rdx, al
    add rcx, rdx
    cmp byte [map_data + rcx], '#'
    je .done
    mov [player_x], al
    mov [player_y], bl
    add dword [score], 1
.done:
    ret

fire_bullet:
    cmp byte [energy], 0
    je .done
    dec byte [energy]
    xor eax, eax
.find:
    cmp byte [bullet_alive + rax], 0
    je .slot
    inc eax
    cmp eax, 4
    jb .find
    ret
.slot:
    mov byte [bullet_alive + rax], 1
    mov bl, [player_x]
    mov [bullet_x + rax], bl
    mov bl, [player_y]
    mov [bullet_y + rax], bl
    mov bl, [facing]
    cmp bl, 0
    jne .not_up
    mov byte [bullet_dx + rax], 0
    mov byte [bullet_dy + rax], -1
    jmp .done
.not_up:
    cmp bl, 1
    jne .not_right
    mov byte [bullet_dx + rax], 1
    mov byte [bullet_dy + rax], 0
    jmp .done
.not_right:
    cmp bl, 2
    jne .left
    mov byte [bullet_dx + rax], 0
    mov byte [bullet_dy + rax], 1
    jmp .done
.left:
    mov byte [bullet_dx + rax], -1
    mov byte [bullet_dy + rax], 0
.done:
    ret

advance_bullets:
    xor r8d, r8d
.bullet_loop:
    cmp r8b, 4
    jae .done
    cmp byte [bullet_alive + r8], 0
    je .next
    mov al, [bullet_x + r8]
    add al, [bullet_dx + r8]
    mov bl, [bullet_y + r8]
    add bl, [bullet_dy + r8]
    cmp al, map_w
    jae .kill
    cmp bl, map_h
    jae .kill
    movzx rcx, bl
    imul rcx, map_w
    movzx rdx, al
    add rcx, rdx
    cmp byte [map_data + rcx], '#'
    je .kill
    mov [bullet_x + r8], al
    mov [bullet_y + r8], bl
    call hit_enemy
    jmp .next
.kill:
    mov byte [bullet_alive + r8], 0
.next:
    inc r8b
    jmp .bullet_loop
.done:
    ret

hit_enemy:
    xor r9d, r9d
.enemy_check:
    cmp r9b, 3
    jae .done
    cmp byte [enemy_alive + r9], 0
    je .next
    cmp al, [enemy_x + r9]
    jne .next
    cmp bl, [enemy_y + r9]
    jne .next
    mov byte [enemy_alive + r9], 0
    mov byte [bullet_alive + r8], 0
    add dword [score], 100
.next:
    inc r9b
    jmp .enemy_check
.done:
    ret

move_enemies:
    inc byte [tick]
    test byte [tick], 1
    jnz .done
    xor r8d, r8d
.enemy_loop:
    cmp r8b, 3
    jae .done
    cmp byte [enemy_alive + r8], 0
    je .next
    mov al, [enemy_x + r8]
    mov bl, [enemy_dir + r8]
    add al, bl
    cmp al, 1
    jbe .reverse
    cmp al, 21
    jae .reverse
    mov [enemy_x + r8], al
    jmp .next
.reverse:
    neg byte [enemy_dir + r8]
.next:
    inc r8b
    jmp .enemy_loop
.done:
    ret

collect_core:
    cmp byte [player_x], core_x
    jne .done
    cmp byte [player_y], core_y
    jne .done
    mov byte [core_found], 1
    add dword [score], 500
.done:
    ret

check_damage:
    xor r8d, r8d
.check:
    cmp r8b, 3
    jae .done
    cmp byte [enemy_alive + r8], 0
    je .next
    mov al, [player_x]
    cmp al, [enemy_x + r8]
    jne .next
    mov al, [player_y]
    cmp al, [enemy_y + r8]
    jne .next
    dec byte [hp]
    mov byte [player_x], 1
    mov byte [player_y], 1
    sub dword [score], 50
    jns .next
    mov dword [score], 0
.next:
    inc r8b
    jmp .check
.done:
    ret

next_wave:
    cmp byte [wave], wave_total
    jae .done
    xor eax, eax
    cmp byte [enemy_alive + 0], 1
    je .done
    cmp byte [enemy_alive + 1], 1
    je .done
    cmp byte [enemy_alive + 2], 1
    je .done
    inc byte [wave]
    add byte [energy], 4
    mov byte [enemy_alive + 0], 1
    mov byte [enemy_alive + 1], 1
    mov byte [enemy_alive + 2], 1
    add dword [score], 250
.done:
    ret

draw:
    mov rsi, ansi_home
    mov rdx, ansi_home_len
    call write_stdout
    mov rsi, title
    mov rdx, title_len
    call write_stdout
    xor r8d, r8d
.row:
    cmp r8b, map_h
    jae .hud
    xor r9d, r9d
.cell:
    cmp r9b, map_w
    jae .row_end
    movzx rcx, r8b
    imul rcx, map_w
    add cl, r9b
    mov al, [map_data + rcx]
    cmp r9b, [player_x]
    jne .not_player
    cmp r8b, [player_y]
    jne .not_player
    mov al, [player_char]
    jmp .paint
.not_player:
    cmp r9b, gate_x
    jne .not_gate
    cmp r8b, gate_y
    jne .not_gate
    mov al, [gate_char]
.not_gate:
    cmp r9b, core_x
    jne .not_core
    cmp r8b, core_y
    jne .not_core
    cmp byte [core_found], 1
    je .not_core
    mov al, [core_char]
.not_core:
    xor r10d, r10d
.enemy_draw:
    cmp r10b, 3
    jae .bullet_draw
    cmp byte [enemy_alive + r10], 0
    je .enemy_next
    cmp r9b, [enemy_x + r10]
    jne .enemy_next
    cmp r8b, [enemy_y + r10]
    jne .enemy_next
    mov al, [enemy_char]
.enemy_next:
    inc r10b
    jmp .enemy_draw
.bullet_draw:
    xor r10d, r10d
.bullet_scan:
    cmp r10b, 4
    jae .paint
    cmp byte [bullet_alive + r10], 0
    je .bullet_next
    cmp r9b, [bullet_x + r10]
    jne .bullet_next
    cmp r8b, [bullet_y + r10]
    jne .bullet_next
    mov al, [bolt_char]
.bullet_next:
    inc r10b
    jmp .bullet_scan
.paint:
    mov [one_char], al
    mov rsi, one_char
    mov edx, 1
    call write_stdout
    inc r9b
    jmp .cell
.row_end:
    mov rsi, newline
    mov edx, 1
    call write_stdout
    inc r8b
    jmp .row
.hud:
    mov rsi, banner
    mov rdx, banner_len
    call write_stdout
    movzx eax, byte [wave]
    call print_digit
    mov rsi, score_text
    mov rdx, score_len
    call write_stdout
    mov eax, [score]
    call print_number
    mov rsi, hp_text
    mov rdx, hp_len
    call write_stdout
    movzx eax, byte [hp]
    call print_digit
    mov rsi, energy_text
    mov rdx, energy_len
    call write_stdout
    movzx eax, byte [energy]
    call print_digit
    mov rsi, core_text
    mov rdx, core_len
    call write_stdout
    movzx eax, byte [core_found]
    call print_digit
    mov rsi, hint
    mov rdx, hint_len
    jmp write_stdout

print_score:
    mov eax, [score]
    jmp print_number

print_digit:
    add al, '0'
    mov [one_char], al
    mov rsi, one_char
    mov edx, 1
    jmp write_stdout

print_number:
    xor ecx, ecx
    mov ebx, 10
.digits:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [number + rcx], dl
    inc ecx
    test eax, eax
    jnz .digits
.emit:
    dec ecx
    mov al, [number + rcx]
    mov [one_char], al
    mov rsi, one_char
    mov edx, 1
    push rcx
    call write_stdout
    pop rcx
    test ecx, ecx
    jnz .emit
    ret

write_stdout:
    mov eax, 1
    mov edi, 1
    syscall
    ret
