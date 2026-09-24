section .data
    msg db "Hello, World!", 10      ; The string to print (10 is the newline character)
    msg_len equ $ - msg             ; Calculate the length of the string

section .text
    global _start                   ; Linker entry point

_start:
    ; Write the string to stdout
    mov rax, 1                      ; system call number for sys_write
    mov rdi, 1                      ; file descriptor 1 is stdout
    mov rsi, msg                    ; pointer to the string
    mov rdx, msg_len                ; length of the string
    syscall                         ; call the kernel

    ; Exit the program
    mov rax, 60                     ; system call number for sys_exit
    mov rdi, 0                      ; exit code 0 (success)
    syscall        