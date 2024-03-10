; Joshua Ariel Valverde Sotovando
; Carne 2017107741
; Curso Ariquitectura de Computadoras

section .data
    filename db 'ruta_datos.txt', 0   ; ESTA LINEA SE DEBE CAMBIAR POR Ruta_datos
    buffer   db 128 ; Búfer para leer cada línea del archivo
    lineSize equ 128 ; Tamaño máximo de una línea

section .bss
    dataPointer resd 1 ; Puntero para recorrer el área de memoria donde se almacenarán los datos
    fileHandle resd 1 ; Descriptor de archivo
    noteValue resd 1   ; Valor entero de la nota

    noteArray resd 128 ; Arreglo para almacenar las notas
    textArray resd 128 ; Arreglo para almacenar las direcciones de las líneas de texto

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

    ; Guardar la nota convertida en memoria y la dirección de la línea de texto
    mov dword [noteArray + eax * 4], eax  ; Guardar la nota en el arreglo
    mov dword [textArray + eax * 4], edi  ; Guardar la dirección de la línea de texto en el arreglo

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

buffer_overflow:
    jmp end_read_loop

end_read_loop:
    ; Cerrar el archivo
    mov eax, 6          ; sys_close
    mov ebx, dword [fileHandle]
    int 80h

    ; Comparación de burbuja para ordenar las notas y las líneas de texto asociadas
    mov ecx, eax  
    dec ecx  
    jz end_bubblesort  
bubblesort_loop:
    mov ecx, eax  
    dec ecx  

inner_loop:
    mov eax, dword [noteArray + ecx * 4]  
    mov ebx, dword [noteArray + ecx - 1 * 4]  
    cmp eax, ebx  ; Comparar las notas
    jg swap_elements  ; Si la nota actual es mayor, intercambiar elementos

    ; No hay intercambio, continuar con el siguiente par de elementos
    dec ecx
    jnz inner_loop

    jmp bubblesort_loop  

swap_elements:
    ; Intercambiar notas en el arreglo
    mov eax, dword [ecx * 4 + noteArray]        
    mov ebx, dword [ecx * 4 - 4 + noteArray]    
    mov dword [ecx * 4 + noteArray], ebx        
    mov dword [ecx * 4 - 4 + noteArray], eax

    ; Intercambiar direcciones de líneas de texto en el arreglo
    mov eax, dword [ecx * 4 + textArray]        
    mov ebx, dword [ecx * 4 - 4 + textArray]    
    mov dword [ecx * 4 + textArray], ebx        
    mov dword [ecx * 4 - 4 + textArray], eax

    ; Repetir la comparación de burbuja interna con el nuevo elemento
    dec ecx
    jnz inner_loop

    jmp bubblesort_loop  

end_bubblesort:
    ; Imprimir las líneas ordenadas por notas en orden descendente
    mov ecx, 0  
print_loop:
    mov eax, dword [textArray + ecx * 4]  
    mov ebx, 1  ; STDOUT
    mov ecx, eax  
    call print_string  

    inc ecx  
    cmp ecx, lineSize  
    jne print_loop

    ; Finalización del programa
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; Código de salida 0
    int 80h

print_string:
    ; Función para imprimir una cadena
    mov eax, 4      ; sys_write
    int 80h
    ret
