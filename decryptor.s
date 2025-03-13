global _start

    ; Group 8 Member
    ; นายณฐีษ์ กีรติธร 663040420-6
    ; นายนิธิโรจน์ นันทวโนทยาน 663040653-3
    ; นายอภิเชษฐ์ ธรรมรักษา 663040671-1

section .bss
    inputFilename resb 100   ; Buffer for input filename
    outputFilename resb 100  ; Buffer for output filename
    keyInput resb 4          ; Buffer for key (3 chars max + null terminator)
    key_length resb 1        ; Store key length
    readbuffer resb buffer_size ; File content buffer (1KB)
    output_length resq 1
    byte_read resq 1

section .data
    LF equ 10
    sys_read equ 0           ; x86-64 syscall
    sys_write equ 1
    sys_open equ 2
    sys_close equ 3
    sys_exit equ 60
    sys_creat equ 85
    stdout equ 1
    stdin equ 0
    O_RDONLY equ 0
    null equ 0
    buffer_size equ 1024
    file equ 100
    key equ 4
    fileDescriptor dq 0     
    linefeed db 10
    success_exit equ 0
    error_exit equ 1

    msgInputFileName db "Enter input filename: ", null
    msg_lenInputFileName equ $ - msgInputFileName
    
    msgOutputFileName db "Enter output filename: ", null
    msg_lenOutputFileName equ $ - msgOutputFileName
    
    msgKeyInput db "Enter key (max. 3 Characters): ", null
    msg_lenKeyInput equ $ - msgKeyInput

    msgReadinginputFile db "Reading input file...OK", LF, null
    msg_lenmsgReadinginputFile equ $ - msgReadinginputFile

    msgGenerateoutputFile db "Generating output file...OK", LF, null
    msg_lenmsgGenerateoutputFile equ $ - msgGenerateoutputFile

    msgGeneratedsuccess db " generated", LF, null
    msg_lenmsgGeneratedsuccess equ $ - msgGeneratedsuccess

    errOpenFile db "Error opening file", LF, null
    errOpenFile_len equ $ - errOpenFile
    
    errReadFile db "Error reading file", LF, null
    errReadFile_len equ $ - errReadFile
    
    errWriteFile db "Error writing file", LF, null
    errWriteFile_len equ $ - errWriteFile

    errEmptyInput db "Error: Empty input", LF, null
    errEmptyInput_len equ $ - errEmptyInput

    errKeytooLong db "Error: Maximum character for key is 3 ", LF, null
    errKeytooLong_len equ $ - errKeytooLong

section .text
_start:
    mov rax, sys_write              ; write
    mov rdi, stdout                 ; output
    mov rsi, msgInputFileName       ; Enter input filename
    mov rdx, msg_lenInputFileName   ; length of input file name message
    syscall                         ; syscall instead of int 80h

    mov rax, sys_read               ; read
    mov rdi, stdin                  ; input
    mov rsi, inputFilename          ; file name
    mov rdx, 99                     ; not 100 leave 1 space for making null terminator
    syscall

    cmp rax, 1                      ; check if byte read
    jl error_empty_input

    dec rax
    mov byte [inputFilename + rax], 0 ; replace last bit to 0 make it null terminated

    ; Get output filename
    mov rax, sys_write              
    mov rdi, stdout                 
    mov rsi, msgOutputFileName      ; enter output file name
    mov rdx, msg_lenOutputFileName  ; length of enter output filename message
    syscall
    
    mov rax, sys_read            
    mov rdi, stdin            
    mov rsi, outputFilename         ; outputfilefromterminal
    mov rdx, 99                     ; not 100 leave 1 space for making null terminator
    syscall

    cmp rax, 1                      ; check if byte read
    jl error_empty_input

    dec rax
    mov byte [outputFilename + rax], 0 ; replace last bit to 0 make it null terminated

    mov rbx, 0
output_length_loop:
    cmp byte [outputFilename + rbx], 0 ; compare byte at outputfilename + ebx to 0 to check null terminated at the end of string
    je output_length_done
    inc rbx
    jmp output_length_loop
output_length_done:
    mov [output_length], bl ; store length from bl to output_length

    ; Get encryption key
    mov rax, sys_write              ; sys_write
    mov rdi, stdout                 ; stdout
    mov rsi, msgKeyInput            ; message enter key
    mov rdx, msg_lenKeyInput        ; length of message enter key
    syscall
    
    mov rax, sys_read               ; sys_read
    mov rdi, stdin                  ; stdin
    mov rsi, keyInput               ; recieve key input from terminal 
    mov rdx, 100                    ; 100 chars max for key
    syscall

    ; Check if any bytes were read
    cmp rax, 1                      ; At least 1 byte needed (will be newline)
    jl error_empty_input

    cmp rax, 4
    jg error_key_too_long 

    ; Replace newline with null terminator
    dec rax
    mov byte [keyInput + rax], 0

    ; function for finding keylength
    mov rbx, 0
key_length_loop:
    cmp byte [keyInput + rbx], 0    ; compare byte to check null terminator
    je key_length_done
    inc rbx
    jmp key_length_loop
key_length_done:
    mov [key_length], bl ; store key length from bl

    ; Open input file
    mov rax, sys_open               ; sys_open
    mov rdi, inputFilename          ; filename (first argument)
    mov rsi, O_RDONLY               ; O_RDONLY (read-only)
    mov rdx, 0644o                  ; make permission to write file and can read
    syscall
    
    ; Check for errors
    cmp rax, 0
    jl error_open_file              ; Jump if negative (error)
    mov [fileDescriptor], rax       ; Save file descriptor
    
    ; Read file content
    mov rax, sys_read               ; sys_read
    mov rdi, [fileDescriptor]       ; file descriptor
    mov rsi, readbuffer             ; buffer
    mov rdx, buffer_size            ; 1024 bytes
    syscall
    
    ; Check for errors
    cmp rax, 0
    jl error_read_file              ; Jump if negative (error)
    mov [byte_read], rax                    ; Save number of bytes read in byte_read
    
    ; Close input file
    mov rax, sys_close              ; sys_close
    mov rdi, [fileDescriptor]
    syscall

        ; Print success message
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, msgReadinginputFile
    mov rdx, msg_lenmsgReadinginputFile
    syscall

    ; Encrypt with XOR
    mov rsi, 0                      ; Set rsi to 0 (buffer index)
    mov rbx, 0                      ; key index at 0

encrypt_loop:
    cmp rsi, [byte_read]                    ; check if processed all bytes
    je write_file
    
    ; Get character from buffer
    mov al, [readbuffer + rsi]
    
    ; XOR with current key character  
    mov cl, [keyInput + rbx]
    xor al, cl
    
    ; Store encrypted byte back to buffer
    mov [readbuffer + rsi], al
    
    ; Move to next byte in buffer
    inc rsi
    
    ; Move to next key character
    inc rbx
    
    ; Check if we need to reset key index
    cmp bl, [key_length]
    jl continue_encrypt
    xor rbx, rbx                    ; reset key index if reached key length

continue_encrypt:
    jmp encrypt_loop

write_file:
    ; Create output file
    mov rax, sys_creat              ; create file
    mov rdi, outputFilename         ; filename
    mov rsi, 0644o                  ; permission
    syscall

    cmp rax, 0
    jl error_open_file
    mov [fileDescriptor], rax

    ; Write to output file
    mov rax, sys_write
    mov rdi, [fileDescriptor]
    mov rsi, readbuffer
    mov rdx, [byte_read]                ; number of bytes to write
    syscall

    ; Print Generate....OK message
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, msgGenerateoutputFile
    mov rdx, msg_lenmsgGenerateoutputFile
    syscall

    ; Print filename
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, outputFilename
    mov rdx, [output_length]
    syscall

    ; Print generated message
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, msgGeneratedsuccess
    mov rdx, msg_lenmsgGeneratedsuccess
    syscall
    
    ; Close output file
    mov rax, sys_close
    mov rdi, [fileDescriptor]
    syscall
    
    ; Exit program
    mov rax, sys_exit
    mov rdi, success_exit                     ; return 0
    syscall

error_key_too_long:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errKeytooLong
    mov rdx, errKeytooLong_len
    syscall
    jmp exit_error

error_empty_input:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errEmptyInput
    mov rdx, errEmptyInput_len
    syscall
    jmp exit_error

error_open_file:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errOpenFile
    mov rdx, errOpenFile_len
    syscall
    jmp exit_error
    
error_read_file:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errReadFile
    mov rdx, errReadFile_len
    syscall
    jmp exit_error
    
error_write_file:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errWriteFile
    mov rdx, errWriteFile_len
    syscall
    
exit_error:
    mov rax, sys_exit
    mov rdi, error_exit                     ; Error exit code
    syscall