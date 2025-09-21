org 0x0

jmp start

times 33 db 0

nome: 
    db "Acerte a palavra correta: ", 0

palavra_correta:
    db "pikachu", 0

errou:
    db "voce errou", 0
   
msg_final:
    db "Voce acertou a palavra parabens", 0       
    times 80 db  0      

dica:
    db "Uma das letras da palavra: ", 0


buffer:   ; this is defining a block of my memory,
    db 20          ; db is "define byte", so im defining the byte here of the memory the BIOS is currently at as 20 (14h i think) 
    db 0           
    db 20 dup(0)   


; "Many BIOS or DOS interrupts look specifically at AH to determine which function to perform."
; When you interupt the CPU there are different interupts number for different routines to call
; in this code i think the BIOS is checking the ah register and in hte different bloack of memorys and functions i made i put the subservice i want in ah  

datena:
    mov ah, 0x0E    ; sets teletype function
    int 0x10    ; chat "BIOS interrupt runs the function, printing the character in AL at the current cursor position."
    ret ; returns controll to the kernel or BIOS?

fausto_silva:
    lodsb     ; load string, more exactly load byte at address, DS:SI, into AL, then increment SI by 1 moving the register to the next memory location
    cmp al, 0  ; its a subtraction, cmp is compare (i think) so its comapring what is in al to 0, and if its 0 it sets zt to 0. --> chat(cmp X, Y is basically X - Y without storing the result) it updates several flags when you do that, the flag that murilo needed to check was zf, zero flag, and in the next line we check, using jz, if zf = 1 wich means that this cmp resulted in zero and it doesnt have any word that this is reading cool
    jz .done   ; jz is a conditional jump instruction in x86 assembly, so this is teeling jump if zero to .done, since in previous  wow so cool murilo things make sense if you actually try to understand them your a good professor if your still reading this im surprised that you actually decided to look at my code 
    call datena  ; since we loaded the byte into AL (8 bit right?), we call datena in wich he sets the teletype function and tells the BIOS to print the characters in al at the current cursor position
    jmp fausto_silva ; aponta pra começar a funcao dnv ja que esta e a logica de printar os caracteres do usuario
.done:
    ret

letra_da_dica:
    mov si, palavra_correta
    add si, dx ; this might not be proper code conduct since there is some operation out there that uses the dx register but idk what do you expect of me im gonna use the register
    lodsb
    cmp al, 0
    jz .done      
    call datena  ; since we loaded the byte into AL (8 bit right?), we call datena in wich he sets the teletype function and tells the BIOS to print the characters in al at the current cursor position
    inc dx
    ret
.done:
    ret
   


get_input:
    mov si, buffer + 2     ; chat "si is on of the general-purpose registers" source index "The CPU reads or writes memory at the address stored in SI, sometimes automatically incrementing it." i guess sometimes it automatically increments it 
    mov cx, 20             ; cx is a assmebly that defines the max lenght or something like that, chat = "CX is the runtime loop counter", actually its just the BIOS convention for that register, some operations (like cmpsb) use specific register do they become the conventional use for those things, in this case its the counter register 
    mov byte [buffer+1], 0 ; just sets to 0 the second byte of the block of memory i called buffer

                ; mov stands for move but it functionallys copies a value into a register or memory location, so saying mov ax, bx its telling to copy the value in ax and copy it to bx, mov destination, source
.next_char:
    mov ah, 0   ; this makes the BIOS wait for a keypress, chat "tells the BIOS to Use function 0: wait for a keypress and return it"
    int 16h     ; BIOS keyboard interrupt
    cmp al, 0x0D  ; al contains the key the user pressed because thats the BIOS convention in this case i think, 0x0D is carrige return (wich we call enter now)          
    je .done_input ; jump if equal, in this case if cmp is checking if al is equal to 0x0D (enter) so if its zf = 1 in this case it jumps to the done_input
    mov ah, 0x0E  ; this is copying the value of 0x0E (14) into ah, so when i interrupt later it reads ah and sees what teletype function to do          
    mov bh, 0  ; setting the text type
    mov bl, 7  ; setting the color of the text             
    int 0x10   ; interrupt that calls the video service routine

    mov [si], al   ; since si is pointing to the next byte in the text the user is doing, im moving what is in al, the user input, to it        
    inc si  ; increments si for it to go to the next memory
    inc byte [buffer+1]    ; incremetns the byte that is holding he size of the string
    loop .next_char

.done_input:
    mov byte [si], 0     
    ret ; fim do get_input


check_msg_set_up: 
    mov si, nome
    call fausto_silva
    call get_input
    mov si, palavra_correta
    mov di, buffer+2
    jmp .check_msg

.check_msg:  ; checks if the answer the user gave matches with what was shown
    cmpsb  
    jne .done_not_correct
    cmp byte [si-1], 0
    jne .check_msg
    jz .done_correct  

.done_correct:
    mov ah, 0x0E
    mov al, 13   ; carriage return -> commands a printer, or the output system in this case i think, to move the position of the cursor to the first position on the same line
    int 0x10     ; interupts the BIOS and tells him to look at video service, video service function is in ah (something like that)
    mov al, 10   ; faz ir pra proxima linha, um caracter de controle que indica que uma linha deve ser acrescentada
    int 0x10     ; 
    mov si, msg_final
    call fausto_silva
    ret

.done_not_correct:
    mov ah, 0x0E
    mov al, 13   
    int 0x10     
    mov al, 10   
    int 0x10

    mov si, errou
    call fausto_silva

    mov ah, 0x0E
    mov al, 13   
    int 0x10      
    mov al, 10   
    int 0x10

    mov si, dica
    call fausto_silva

    mov ah, 0x0E
    mov al, 13   
    int 0x10     
    mov al, 10   
    int 0x10

    call letra_da_dica

    mov ah, 0x0E
    mov al, 13   
    int 0x10     
    mov al, 10   
    int 0x10

    jmp check_msg_set_up   


          


    

start:
    cli
    mov ax, 0x7c0
    mov ds, ax
    mov es, ax

    mov ax, 0x0000
    mov ss, ax
    mov sp, 0x7c00
    ; set up the segment registers and stack pointers so your program knows where to read/write data and where the stack lives.
    sti

    mov dx, 0
    call check_msg_set_up

    ; Print newline, its moving the curser down so the output is not stuck in the name (BrunoOla Bruno)
    mov ah, 0x0E
    mov al, 13   ; carriage return -> commands a printer, or the output system in this case i think, to move the position of the cursor to the first position on the same line
    int 0x10     ; interupts the BIOS and tells him to look at video service, video service function is in ah (something like that)
    mov al, 10   ; faz ir pra proxima linha, um caracter de controle que indica que uma linha deve ser acrescentada
    int 0x10

    jmp $

times 510 - ($ - $$) db 0
dw 0xAA55
