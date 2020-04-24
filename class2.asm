assume cs:code

code segment
start:
    mov ax,code
    mov es,ax
    mov bx,offset data
    mov ah,3
    mov al,18
    mov ch,0
    mov cl,1
    mov dh,0
    mov dl,0

    int 13h

    cmp ah,0
    jne se
    mov ax,0b800h
    mov es,ax
    mov bx,160
    mov byte ptr es:[bx+1],01000000B

    se:
    mov ax,4c00h
    int 21h

data:
    mov ax,2000h
    mov es,ax
    mov bx,7c00h
    mov ah,2
    mov al,18
    mov ch,0
    mov cl,1
    mov dh,0
    mov dl,0

    int 13h   
    mov ax,2000h
    push ax
    mov ax,offset axx-offset data+7c00h
    push ax
    retf
    axx:
    jmp short start_point
data_ends:nop

start_point:
    mov ax,cs
    mov ss,ax
    mov sp,offset stack-offset data+07c00h+128

    mov bx,offset int9-offset data+7c00h+2;;;;;;
    mov ax,0
    mov es,ax
    push es:[9h*4]
    pop cs:[bx];;;;;;
    push es:[9h*4+2]
    pop cs:[bx+2];;;;;;
    ;int9h
    mov word ptr es:[9h*4],07c00h+offset int9-offset data
    mov word ptr es:[9h*4+2],2000h
    ; ;clear screen blue  int74h
    mov word ptr es:[74h*4],07c00h+offset clear_screen_blue-offset data
    mov word ptr es:[74h*4+2],2000h

    sti
main_page:
    int 74h
    jmp short main_page_start
    db '1:reset_pc',0
    db '2:start_system',0
    db '3:clock',0
    db '4:set_clock','$'
    main_page_start:
    mov ax,0b800h
    mov es,ax
    mov bx,0
    mov si,offset main_page-offset data+7c00h+2;;;;;;
    mps_loop:
        mov al,cs:[si]
        cmp al,0
        je bxadd
        cmp al,'$'
        je mp_end
        mov es:[bx],al
        add bx,2
        inc si
        jmp short mps_loop
        bxadd:
            inc si
            mov ax,bx
            mov dx,0
            mov bx,160
            div bx
            mov bx,ax
            mov ax,160
            mov dx,0
            mul bx
            mov bx,ax
            mov ax,0
            add bx,160
        jmp short mps_loop
    mp_end:
    MOV AL,0
    IN AL,60h
    CMP AL,02h
    JE I1
    CMP AL,03H
    JE I2
    CMP AL,04H
    JE I3 
    CMP AL,05H
    JE I4
    JMP SHORT main_page_start
    I1:
    ;INT 70H
    CALL reset_pc
    JMP SHORT main_page_start
    I2:
    ;INT 71h
    CALL start_system
    JMP SHORT main_page_start
    I3:
    ;INT 72h
    CALL clock
    JMP SHORT main_page_start
    I4:
    ;INT 73H
    CALL set_clock
    jmp short main_page_start
int9:
    jmp short int9start
    db 4 dup(0)
    int9start:
        push ax
        push bx
        push cx
        push dx
        push es
        push ds
        push bp
        
        mov ax,0b800h
        mov es,ax
        mov byte ptr es:[161],01000000B
        in al,60h
        pushf
        mov bx,offset int9-offset data+7c00h+2
        call dword ptr cs:[bx]

        cmp al,01h
        je fesc
        cmp al,3Bh
        je fcolor
        jmp short int9iret
        fesc:   
            mov bp,sp
            mov word ptr [bp+14],offset main_page-offset data+7c00h
            mov word ptr [bp+16],2000h
        jmp short int9iret
        fcolor:
            mov cx,2000
            mov ax,0b800h
            mov es,ax
            mov bx,1
            fcloop:
                and byte ptr es:[bx],11110000B
                or byte ptr es:[bx],00000010B
                add bx,2
            loop fcloop
        jmp short int9iret

    int9iret:
        pop bp
        pop ds
        pop es
        pop dx
        pop cx
        pop bx
        pop ax
        iret
reset_pc:
    PUSH BX
    PUSH ES
    MOV BX,cs
    MOV ES,BX
    mov bx,offset jw-offset data+7c00h
    jmp dword ptr Es:[bx]
    POP ES
    POP BX
    iret
    jw:dw 0,0ffffh

clock:
    cli;;;;;;;;;;;;;;;;;;;;;;;;;
    push ax
    push dx
    push cx
    push si

    int 74h
    mov cx,18
    mov bx,0b800h
    mov es,bx
    mov bx,3*160+4*2
    set_font_color:
        mov byte ptr es:[bx+1],01110100B
        add bx,2
    loop set_font_color

    jmp short clock_dynmic_show
    clock_a:db 9,8,7,4,2,0
    clock_b:db 1,1,3,2,2,3
    clock_dynmic_show:
        mov dl,4
        mov dh,3
        mov si,offset clock_a-offset data+7c00h
        mov cx,6
        t:
            push cx
            mov al,cs:[si]
            out 70h,al
            in al,71h
            mov cl,cs:[si+6]
            push ax

            push si
            push cx

            mov ah,al
            mov cl,4
            shr ah,cl
            and al,00001111b

            add ah,30h
            add al,30h

            mov bx,0b800h
            mov es,bx

            push ax
            mov ax,160
            mul dh
            mov bx,ax
            mov ax,2
            mul dl
            mov si,ax
            pop ax

            mov byte ptr es:[bx+si],ah
            mov byte ptr es:[bx+si+2],al
            pop cx
            cmp cx,1
            je clock_date
            cmp cx,2
            je clock_time
            cmp cx,3
            je clock_empty
            clock_date:
                mov byte ptr es:[bx+si+4],'/'
            jmp short clock_e
            clock_empty:
                mov byte ptr es:[bx+si+4],' '
            jmp short clock_e
            clock_time:
                mov byte ptr es:[bx+si+4],':'
            jmp short clock_e
            clock_e:
            add dl,3
            pop si
            pop ax
            
            inc si
            pop cx
        loop t
        in al,60h
        cmp al,01h
        je clock_end
    jmp near ptr clock_dynmic_show
    
    clock_end:
    pop si
    pop cx
    pop dx
    pop ax
    sti;;;;;;;;;;;;;;;;;;;;;;
    int 74h
    ;iret
    RET    
set_clock:
    JMP SHORT SC_START
    notice:db 'please input the date:'
    string:db 18 DUP (0)
    sclock_a:db 9,8,7,4,2,0
    SC_START:

    mov bx,0b800h
    mov ds,bx
    mov di,160*7+2*5
    mov bx,offset notice-offset data+7c00h
    mov cx,offset string-offset notice
    show_notice_loop:
    mov al,cs:[bx]
    mov ds:[di],al
    inc bx
    add di,2
    loop show_notice_loop
    
    mov ax,CS
    mov ds,ax
    mov si,offset string-offset data+7c00h
    MOV DL,5
    MOV DH,8
    MOV CX,0
    call getstr
    mov si,offset string-offset data+7c00h
    mov di,offset sclock_a-offset data+7c00h
    mov cx,6
    sc_loop:
    PUSH CX
    mov al,cs:[si]
    add al,0d0h
    mov cl,4
    shL al,cl
    and al,11110000B
    mov ah,cs:[si+1]
    add ah,0d0h
    and ah,00001111b
    or al,ah
    mov ah,al
    mov al,cs:[di]
    out 70h,al
    mov al,ah
    out 71h,al
    inc di
    add si,3
    POP CX
    loop sc_loop

    INT 74H
    ;IRET
    RET


charstack:
    charstart:
        push bx
        push dx
        push di
        push es
        
        cmp ah,2
        ja sret
        cmp ah,0
        je charpush
        cmp ah,1
        je charpop
        cmp ah,2
        je charshow

    charpush:
        mov bx,CX
        mov DS:[si][bx],al
        inc CX
        jmp sret
    charpop:
        cmp CX,0
        je sret
        dec CX
        mov bx,CX
        mov al,DS:[si][bx]
        jmp sret
    
    charshow:
        mov bx,0B800h
        mov es,bx
        mov al,160
        mov ah,0
        mul dh
        mov di,ax
        add dl,dl
        mov dh,0
        add di,dx

        mov bx,0

    charshows:
        cmp bx,CX
        jne noempty
        mov byte ptr es:[di],' '
        jmp sret
        noempty:
            mov al,DS:[si][bx]
            mov es:[di],al
            mov byte ptr es:[di+2],' '
            inc bx
            add di,2
            jmp charshows
        
    sret:
        pop es
        pop di
        pop dx
        pop bx
        ret

getstr:
    push ax
    getstrs:
        mov ah,0
        int 16h
        cmp al,20h
        jb nochar
        mov ah,0
        call charstack
        mov ah,2
        call charstack 
        jmp getstrs

    nochar:
        cmp aH,0eh
        je backspace
        cmp aH,1ch
        je C_ENTER
        jmp getstrs

    backspace: 
        mov ah,1
        call charstack
        mov ah,2
        call charstack
        jmp getstrs

    C_ENTER:
        mov al,0
        mov ah,0
        call charstack
        mov ah,2
        call charstack
        pop ax
        ret

clear_screen_blue:
    push ax
    push bx
    push cx
    push es
    
    mov ax,0B800h
    mov es,ax
    mov cx,2000
    mov bx,0
    l:
        mov byte ptr es:[bx],' '
        mov byte ptr es:[bx+1],00010111B
        add bx,2
    loop l

    pop es
    pop cx
    pop bx
    pop ax
    iret
start_system:
    int 74h
    ; mov si,offset do0-offset data+7c00h
    ; mov di,7c00h
    ; mov ax,0
    ; mov es,ax
    ; mov ax,0
    ; mov ds,ax
    ; mov cx,offset do0end-do0
    ; cld 
    ; rep movsb
    ; mov ax,0
    ; push ax
    ; mov ax,7c00h
    ; push ax
    ; retf
    do0:
        mov bx,offset int9-offset data+7c00h+2;;;;;;
        mov ax,0
        mov es,ax
        push cs:[bx];;;;;;
        pop es:[9h*4]
        push cs:[bx+2];;;;;;
        pop es:[9h*4+2]
        mov ax,0b800h
        mov es,ax
        mov byte ptr es:[161],00100111B
        mov ax,0
        mov es,ax
        mov bx,7c00h
        mov al,1
        mov ch,0
        mov cl,1
        mov dh,0
        mov dl,80h

        mov ah,2
        int 13h
        MOV AX,0
        PUSH AX
        MOV AX,7C00h
        PUSH AX
        ;iret;
        retf
    do0end:nop
    db 128 dup(0)
    stack:
        db 128 dup(0)

prog_end:nop

code ends
end start