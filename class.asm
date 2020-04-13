assume cs:code

data segment
    db '1975','1976','1977','1978','1979','1980','1981','1982','1983'
    db '1984','1985','1986','1987','1988','1989','1990','1991','1992'
    db '1993','1994','1995'
    dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514
    dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000
    dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5653,8226
    dw 11542,14430,15257,17800
data ends

table segment
    db 21 dup ('year summ ne ?? ')
table ends

stack segment
    db 64 dup (0)
stack ends

string segment
    db 'year',0,'income',0,'num of emp',0,'average'
    db 48 dup (0)
string ends

code segment
start:
    mov ax,string
    mov ax,string
    mov ax,data
    mov ds,ax
    mov ax,table
    mov es,ax
    
    mov ax,stack
    mov ss,ax
    mov sp,32

    mov cx,21
    mov bx,0
    mov si,0
    mov di,0
    s:
        push cx
        mov dx,0h
        mov bx,2
        mov ax,si
        div bx
        push ax
        mov bx,0

        mov ax,ds:[bx][si]
        mov es:[di],ax
        add di,2
        mov dx,ds:[bx][si+2]
        mov es:[di],dx
        add di,2

        mov byte ptr es:[di],0
        inc di

        add bx,84

        mov ax,ds:[bx][si]
        mov es:[di],ax
        add di,2
        mov dx,ds:[bx][si+2]
        mov es:[di],dx
        add di,2

        mov byte ptr es:[di],' '
        inc di

        add bx,84
        
        mov cx,si
        pop si
        push cx
        mov cx,ds:[bx][si]
        mov es:[di],cx
        pop cx
        add di,2

        mov byte ptr es:[di],' '
        inc di

        div word ptr ds:[bx][si]

        mov es:[di],ax
        add di,2

        mov byte ptr es:[di],' '
        inc di

        mov si,cx

        pop cx
        add si,4
    loop s


   
    mov ax,0B800H
    mov ds,ax
    mov cx,1920
    mov bx,0
    mov ah,00000000B
    mov al,0
    clear_screen_loop_1:
        mov [bx],ax
        add bx,2
    loop clear_screen_loop_1
    

;输出至屏幕
    mov ax,string
    mov ds,ax
    mov ax,table
    mov es,ax
    mov dh,2h
    mov dl,4h
    mov di,0
    mov si,0
    mov cx,0
    mov cl,00000110B
    call show_str
    inc si
    add dl,16
    call show_str
    inc si
    add dl,16
    call show_str
    inc si
    add dl,16
    call show_str
    inc dh

    mov cx,21
    
    y:
        mov dl,4h
        mov si,0
        mov di,0
        push dx
        mov ax,es:[di]
        mov [si],ax
        add di,2
        add si,2
        mov ax,es:[di]
        mov [si],ax
        add di,2
        add si,2
        mov al,es:[di]
        mov [si],al
        inc di
        inc si

        mov ax,es:[di]
        mov dx,es:[di+2]
        call dtoc

        add di,5
        mov dx,0
        mov ax,es:[di]
        call dtoc

        add di,3
        mov ax,es:[di]
        call dtoc

        mov ax,es
        inc ax
        mov es,ax

        pop dx
        mov si,0
        mov di,0
        push cx
        mov cx,0
        mov cl,00000111B
        call show_str
        add dl,16
        inc si
        call show_str
        add dl,16
        inc si
        call show_str
        add dl,16
        inc si
        call show_str
        pop cx

        inc dh
        
    loop y

    jmp end_of_program

show_str:;参数 dx,ds string位置,si string偏移,cx 为参数
    push ax;
    push es;显存位置
    push bx;显存偏移地址

    mov ax,0B800H
    mov es,ax
    mov ah,0
    mov al,160
    mul dh
    mov bx,ax;行
    mov ah,0h
    mov al,2h
    mul dl
    add bx,ax;列
    sub bx,2h

    mov ah,cl
    push cx
    mov cx,0

    show_str_loop_1:;打印字符。
        mov al,ds:[si]
        mov es:[bx],ax
        inc bx
        inc bx
        inc si
        mov cl,ds:[si]
    jcxz show_str_end_1
        jmp short show_str_loop_1

    show_str_end_1:
    pop cx
    pop bx
    pop es
    pop ax

ret

divdw:;需要提前提供ax=L，dx=H（被除数）以及除数的值N,bx
    push cx

    ;phase 1 int(H/N)
    push ax
    mov ax,dx
    mov dx,0
    div bx;除数
    mov cx,ax
    ;phase 2 (rem(H/N)*65546+L)/N
    pop ax
    div bx
    ;phase 3 p1*65536
    mov bx,dx;保存余数。
    mov dx,cx;
    
    pop cx
ret

dtoc:;ax，dx,ds,si做参数。
    push cx
    push bx
    push bp

    mov bp,64
    dec bp
    mov byte ptr [bp],0
        
    dtoc_loop_1:
        dec bp
        mov bx,10
        call divdw
        add bx,30h
        mov [bp],bl
        mov cx,ax
    jcxz temp
        jmp short dtoc_loop_1
    temp:   
        mov cx,dx
    jcxz dtoc_reverse_1
        jmp short dtoc_loop_1
    
    dtoc_reverse_1:
        mov al,[bp]
        mov [si],al
        inc bp
        inc si
        mov cx,bp
        sub cx,64
    jcxz dtoc_end_1
        jmp short dtoc_reverse_1

    dtoc_end_1:
    pop bp
    pop bx
    pop cx
ret

end_of_program:
    mov ax,4c00h
    int 21h

code ends
end start