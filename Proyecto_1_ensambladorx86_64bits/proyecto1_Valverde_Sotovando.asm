section .data
    filename db 'input.txt', 0
    buffer   db 1024 ; Búfer para leer cada línea del archivo
    lineSize equ 256 ; Tamaño máximo de una línea

section .bss
    dataPointer resd 1 ; Puntero para recorrer el área de memoria donde se almacenarán los datos
    fileHandle resd 1 
    noteValue resd 1   

section .text
    global _start

_start:
    ; Abrir el archivo
    mov eax, 5          
    mov ebx, filename   
    mov ecx, 0          
    int 80h
    mov dword [fileHandle], eax 


    mov eax, 3          ; sys_read
    mov ebx, dword [fileHandle]
    mov ecx, buffer
    mov edx, lineSize
    int 80h

    ; Verificar si hemos llegado al final del archivo
    cmp eax, 0
    je end_read_loop

    ; Copiar la línea leída a la memoria
    mov edi, buffer
    mov esi, dataPointer
    mov ecx, eax 
    rep movsb

    ; Encontrar la posición de "nota:" en la línea
    mov esi, buffer
    mov ecx, eax
    mov edi, 0
find_note:
    lodsb
    cmp al, ':' 
    jne find_note
    mov al, byte [esi] 
    inc esi
    mov bl, al
    sub bl, '0' 
    mov dword [noteValue], ebx 

    ; Imprimir la línea en pantalla
    mov eax, 4      
    mov ebx, 1      
    mov ecx, buffer ; Dirección del búfer que contiene la línea
    int 80h

    mov eax, dword [dataPointer]
    add eax, lineSize
    mov dword [dataPointer], eax

    jmp read_loop

end_read_loop:

    mov eax, 6          ; sys_close
    mov ebx, dword [fileHandle]
    int 80h

    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; Código de salida 0
    int 80h

