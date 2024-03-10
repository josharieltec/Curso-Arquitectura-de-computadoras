section .data
    filename db 'ruta_datos.txt', 0   ; ESTA LINEA SE DEBE CAMBIAR POR Ruta_datos
    buffer   db 128 ; Búfer para leer cada línea del archivo
    lineSize equ 128 ; Tamaño máximo de una línea

section .bss
    dataPointer resd 1 ; Puntero para recorrer el área de memoria donde se almacenarán los datos
    fileHandle resd 1 ; Descriptor de archivo
    noteValue resd 1   ; Valor entero de la nota

section .text
    global _start

_start:
    ; Abrir el archivo
    mov eax, 5    ; syscall      
    mov ebx, filename   ; Quiza deba cambiar esto por Ruta_datos
    mov ecx, 0          
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
    mov ecx, eax ; Longitud de la línea leída
    cmp ecx, lineSize  ; Verificar si la línea excede el tamaño del búfer
    jae buffer_overflow
    rep movsb

    ; Asegurar que la línea copiada esté terminada con un byte nulo
    mov byte [edi], 0

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

buffer_overflow:     ;---------------------------------AQUI NO HAY NADA-----------------------
    ; Manejar el desbordamiento del búfer (puedes imprimir un mensaje y salir o tomar la acción apropiada)
    jmp end_read_loop

end_read_loop:
    ; Cerrar el archivo
    mov eax, 6          ; sys_close
    mov ebx, dword [fileHandle]
    int 80h

    ; Finalización del programa
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; Código de salida 0
    int 80h
