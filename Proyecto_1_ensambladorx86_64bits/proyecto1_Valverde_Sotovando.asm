section .data
    filename db 'input.txt', 0
    buffer   db 128 ; Búfer para leer cada línea del archivo
    lineSize equ 128 ; Tamaño máximo de una línea

section .bss
    dataPointer resd 1 
    fileHandle resd 1 
    noteValue resd 1   

section .text
    global _start

_start:
    ; Abrir el archivo
    mov eax, 5          ; sys_open
    mov ebx, filename   ; Dirección del nombre del archivo
    mov ecx, 0          ; Modo de apertura (O_RDONLY)
    int 80h
    mov dword [fileHandle], eax ; Guardar el descriptor de archivo

read_loop:
    ; Leer una línea del archivo
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
    cmp al, ':' ; Buscar ":" en la línea
    jne find_note

    ; Asegurarse de que los siguientes caracteres sean " nota:"
    mov edi, esi
    mov ecx, 7 ; Longitud de ": nota:"
    repe cmpsb
    jne find_note

    ; Encontrar la posición del valor de la nota
    ; Mover el puntero al inicio del valor de la nota
    mov edi, esi
    add edi, 7 ; Avanzar al final de ": nota:"
    jmp read_note_value

read_note_value:
    ; Lee el valor de la nota y conviértelo a entero
    xor ebx, ebx ; Limpiar ebx para almacenar el valor de la nota
read_digit:
    lodsb
    cmp al, 0x30 ; Comprueba si es un dígito
    jb end_read_note_value ; Sale si no es un dígito
    cmp al, 0x39 ; Comprueba si es un dígito
    ja end_read_note_value ; Sale si no es un dígito
    sub al, 0x30 ; Convierte de ASCII a valor numérico
    imul ebx, ebx, 10 ; Multiplica el valor actual por 10
    add ebx, eax ; Añade el nuevo dígito al valor de la nota
    jmp read_digit

end_read_note_value:
    ; Guarda el valor de la nota
    mov dword [noteValue], ebx

    ; Imprimir la línea en pantalla
    mov eax, 4      ; sys_write
    mov ebx, 1      ; STDOUT
    mov ecx, buffer ; Dirección del búfer que contiene la línea
    int 80h

    ; Mover el puntero de datos al siguiente espacio disponible
    mov eax, dword [dataPointer]
    add eax, lineSize
    mov dword [dataPointer], eax

    jmp read_loop

end_read_loop:
    ; Cerrar el archivo
    mov eax, 6          ; sys_close
    mov ebx, dword [fileHandle]
    int 80h

    ; Finalización del programa
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; Código de salida 0
    int 80h
