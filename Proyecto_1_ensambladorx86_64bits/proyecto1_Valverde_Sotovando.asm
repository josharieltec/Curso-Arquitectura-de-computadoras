section .data
    filename db 'ruta_datos.txt', 0   ; ESTA LINEA SE DEBE CAMBIAR POR Ruta_datos
    buffer   db 128 ; Búfer para leer cada línea del archivo
    lineSize equ 128 ; Tamaño máximo de una línea

section .bss
    dataPointer resd 1 ; Puntero para recorrer el área de memoria donde se almacenarán los datos
    fileHandle resd 1 ; Descriptor de archivo
    noteValue resd 1   ; Valor entero de la nota
    structSize equ 132 ; Tamaño de la estructura de datos (128 para la línea de texto + 4 para la nota)

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

    ; Encontrar el último espacio en la línea (que precede a la nota)
    mov esi, buffer
    add esi, eax  ; Puntero al final de la línea
find_last_space:
    dec esi
    cmp byte [esi], ' '
    je extract_note
    cmp esi, buffer
    jne find_last_space
    jmp read_loop  ; No se encontró un espacio, continuar con la siguiente línea

extract_note:
    ; Incrementar esi para apuntar al primer carácter de la nota
    inc esi
    ; Convertir la nota de cadena a entero
    xor eax, eax  ; Limpiar eax
    xor ebx, ebx  ; Limpiar ebx
convert_loop:
    movzx ecx, byte [esi]  ; Cargar el siguiente carácter de la cadena en ecx
    cmp ecx, 0  ; Verificar si hemos llegado al final de la cadena
    je note_converted
    sub ecx, '0'  ; Convertir el carácter ASCII a su valor numérico
    imul eax, 10  ; Multiplicar eax por 10 (mover los dígitos previos a la izquierda)
    add eax, ecx  ; Agregar el valor numérico del dígito actual a eax
    inc esi  ; Avanzar al siguiente carácter en la cadena
    jmp convert_loop

note_converted:
    ; Guardar la nota convertida en memoria
    mov dword [noteValue], eax

    ; Crear una estructura de datos con la línea de texto y su respectiva nota
    mov edi, dataPointer
    mov esi, buffer
    mov ecx, lineSize
    rep movsb  ; Copiar la línea de texto
    mov edx, dword [noteValue]
    mov [edi + ecx], edx  ; Guardar la nota al final de la línea de texto

    ; Mover el puntero de datos al siguiente espacio disponible
    mov eax, dword [dataPointer]
    add eax, structSize
    mov dword [dataPointer], eax

    jmp read_loop

buffer_overflow:
    ; Manejar el desbordamiento del búfer (puedes imprimir un mensaje y salir o tomar la acción apropiada)
    jmp end_read_loop

end_read_loop:
    ; Cerrar el archivo
    mov eax, 6          ; sys_close
    mov ebx, dword [fileHandle]
    int 80h

    ; Realizar la comparación de burbuja para ordenar las líneas de texto según la nota
    mov esi, dataPointer
    sub esi, structSize  ; Puntero al último elemento del arreglo
bubble_sort:
    mov edi, dataPointer
    sub edi, structSize  ; Puntero al primer elemento del arreglo
inner_loop:
    ; Cargar la nota actual y la siguiente
    mov eax, [edi + lineSize]
    cmp eax, [edi + lineSize + structSize]
    jge skip_swap

    ; Intercambiar las estructuras de datos
    mov edx, lineSize
    mov ebx, edi
    add ebx, structSize
    mov ecx, edx
    rep movsb

skip_swap:
    add edi, structSize
    cmp edi, esi
    jl inner_loop

    ; Imprimir las líneas de texto en orden de la nota más alta a la más baja
    mov esi, dataPointer
    sub esi, structSize
print_loop:
    mov eax, 4      ; sys_write
    mov ebx, 1      ; STDOUT
    mov ecx, esi    ; Dirección del inicio de la línea de texto
    mov edx, lineSize  ; Longitud de la línea de texto
    int 80h

    add esi, structSize
    cmp esi, dataPointer
    jge end_program
    jmp print_loop

end_program:
    ; Finalización del programa
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; Código de salida 0
    int 80h
