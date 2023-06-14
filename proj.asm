include structs.inc
.model large
.stack 100h
.data
;IN GAME
p1 paddle<>
u1 player<>
b1 ball<>
bri brick 36 dup(<>) ;as the array is of a struct, the index addition will be of 12
;BOARD
board1 db "ESC (PAUSE)$"
board2 db "HP: $"
board3 db "SCORE: $"
board4 db "LEVEL: $"
board5 db "TIME: $"
board6 db "AYYYYOOO, GOOD JOBB!$"
;BRICKS
bxinbet dw 105
byinbet dw 40
bxcord dw 10
bycord dw 30
bxval dw 0
byval dw 0
btemp dw 0
bnum dw 0 ;stores amount of bricks destroyed
rand db ?
;TIMER
time dw 240 ;total time left
t1 db 70 ;new time
t2 db 0 ;prev time
;INSTRUCTIONS
ins1 db "INSTRUCTIONS$"
ins2 db "DESTROY ALL OF THE BLOCKS IN EACH LEVEL$"
ins3 db "USE <- ARROW KEY AND -> ARROW KEY FOR MOVEMENT.$"
ins4 db "DON'T LET THE BALL HIT THE BOTTOM.$"
ins5 db "ENTER: GO TO MAIN MENU.$"
ins6 db "PURPLE BLOCKS ARE UNKILLABLE.$"
ins7 db "YOU HAVE TO FINISH ALL 3 LEVELS WITHIN TIME.$"
ins8 db "THE BLUE BRICKS DESTROY UPTO 5 OTHER BRICKS.$"
;MAIN MENU
n1 db "BRICK BREAKER$"
n2 db "ENTER: PLAY$"
n3 db "ESC: EXIT$"
n6 db "L: LEADERBOARD.$"
n4 db "ENTER YOUR NAME: $"
n5 db "NAME: $"
n7 db "BACK: GO TO PREVIOUS MENU.$"
n8 db "ENTER: MAIN MENU$"
;LEADERBOARD
leader1 db "LEADERBOARD$"
filename db "Leader.txt",0
handle dw ?
readname db 15 dup(?)
readscore dw 1
readlevel dw 1
lycord db 12
count dw 0
buffer db 120 dup (?)
;PAUSE MENU
pcontrol db ?
pau1 db "P: To return to the game.$"
pau2 db "ESC: Go to main menu.$"
;extra
num dw ?

.code
mov ax, @data
mov ds, ax
mov ax, 0


main proc
mov ah, 00 ;sets video mode
mov al, 12h ;sets the res to 640x480
int 10h 
;used to set previous time to current time
mov ah, 2ch 
int 21h
mov t2, dh
;calling first page and get name
call instructions
call getname

mov p1.psize, 100;setting starting size of paddle

gotomain: ;THE MAIN MENU
call mainmenu
mov u1.level, 1
mov u1.score, 0
mov u1.life, 3

mov p1.psize, 100 ;reseting starting size of paddle
mov p1.speed, 15 ;reseting speed of paddle
mov b1.speed, 1 ; reseting starting speed of ball
mov bnum, 0 ;setting value of destoyed bricks to 0
maincontrol: ;CONTROLS THE INPUTS FOR MAIN MENU
    mov ah, 0h
    int 16h
    push ax
    call playbeep
    pop ax
    .if (al == 13);Check for enter key
    jmp play
    .elseif (al == 27);check for escape key
    jmp EXIT
    .elseif (al == 76 || al == 108);check for L/l
    call leaderboard
    call playbeep
    call mainmenu
    jmp maincontrol
    .elseif (al == 08);check for L/l
    call getname
    call playbeep
    call mainmenu
    jmp maincontrol
    .else
    jmp maincontrol
.endif

play: ;NEW GAME
;INITIALIZING PADDLE VALUES
mov p1.xcord, 260
mov p1.ycord, 460
mov p1.color, 12
;INITIALIZING THE BALL VALUES
mov b1.xcord, 280
mov b1.ycord, 440
mov b1.xspeed, 0 ;x gradient value

push ax
mov ax, u1.level
add ax, 2
mov b1.yspeed, ax ;y gradient value
neg b1.yspeed
pop ax

mov b1.color, 10
;size of ball will be 10x10
call brickinitial

boardplay: ;THE POINT AFTER WHICH GAMEPLAY TAKES PLACE WITHOUT RESETING TO NEW GAME
.if (u1.level > 3);checking if the person has completed all 3 levels
    mov u1.level, 3
    call gameoverwon
    jmp gotomain
.endif
call drawboard
call drawpaddle
call drawball
;DRAWING ALL OF THE BRICKS
mov cx, 0
mov si, offset bri
.while (cx < 36)
push cx
call drawbrick
add si, sizeof brick
pop cx
inc cx
.endw

mov p1.color, 12

looper:;USED AS AN INPUT AND OTHER FUNCTION LOOP
mov ah, 01h
int 16h
jnz gamecontrol
jz notpressed
gamecontrol: ;CONTROLS THE BALL AND OTHER IN GAME FUNCTIONS
.if (time <= 1 || u1.life == 0);checks if time is up
jmp timefinish
.endif
call timer
;BALL MOVEMENT
call ballmovement
;BRICK COLLISION
call brickcol
;PADDLE CONTROL
mov ah, 0h
int 16h
.if (ah == 4bh) ;BALL LEFT
        mov bx, p1.xcord
        sub bx, p1.speed
        cmp bx, -1;checks if the paddle will be within limits if moved
        jng looper
        mov p1.color, 0
        call drawpaddle ;Clears the old paddle
        push bx
        mov bx, p1.speed
        sub p1.xcord, bx
        pop bx
        mov p1.color, 12
        call drawpaddle ;Draws new paddle
        jmp looper
    .elseif (ah == 4dh) ;BALL RIGHT
        mov bx, p1.xcord
        add bx, p1.psize
        add bx, p1.speed
        cmp bx, 640;checks if the paddle will be within limits if moved
        ja looper
        mov p1.color, 0
        call drawpaddle ;Clears the old paddle
        push bx
        mov bx, p1.speed
        add p1.xcord, bx
        pop bx
        mov p1.color, 12
        call drawpaddle ;Draws new paddle
        jmp looper
    .elseif (al == 27) ;PAUSE BUTTON
        call playbeep
        call pausemenu
        ;IMPLEMENTS PAUSE MENU CONTROLS
        .if (pcontrol == 1);RESUME GAME
        jmp boardplay
        .elseif (pcontrol == 2);GO TO MAINMENU
        jmp gotomain
        .endif
    .elseif (al == 64);next level
    call playbeep
    call nextlevel
    mov p1.color, 0
    call drawpaddle ;Clears the old paddle
    mov p1.color, 12
    call drawpaddle ;Clears the old paddle
    jmp play
    .else 
    jmp looper
.endif

notpressed:
.if (time <= 1 || u1.life == 0) ;checks if time is up
jmp timefinish
.endif
.if (bnum >= 36)
call nextlevel
mov bnum, 0
jmp play
.endif

call timer
;MAKING BALL MOVE UNIFORMLY
call ballmovement
    push p1.xcord
    push p1.ycord
    mov p1.xcord, 0
    mov p1.ycord, 0
    mov p1.color, 0
    call drawpaddle
    mov p1.color, 12
    pop p1.ycord
    pop p1.xcord
    call boardtext
    call brickcol
    jmp looper

timefinish:
call gameoverlost
jmp gotomain

main endp
jmp EXIT

;PRINTS THE INSTRUCTIONS
instructions proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 9h ;COLOR
    int 10h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov bx,0
    mov dh, 8 ;ycord
    mov dl, 20 ;xcord
    int 10H ;Sets cursor
    lea dx, ins1
    mov ah, 09h
    int 21h ;Prints the string
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 10 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins2
    mov ah, 09h
    int 21h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 12 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins4
    mov ah, 09h
    int 21h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 14 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins3
    mov ah, 09h
    int 21h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 16 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins6
    mov ah, 09h
    int 21h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 18 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins8
    mov ah, 09h
    int 21h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 20 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins7
    mov ah, 09h
    int 21h
    ;PRINTS INSTRUCTIONS
    mov ah,02H
    mov dh, 22 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, ins5
    mov ah, 09h
    int 21h
    mov ah, 0h
    int 16h
    ret
instructions endp
;GETS THE USERS NAME
getname proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 9h ;COLOR
    int 10h
    ;PRINTS THE TITLE OF THE GAME
    mov ah,02H
    mov bx,0
    mov dh, 6 ;ycord
    mov dl, 30 ;xcord
    int 10H ;Sets cursor
    lea dx, n1
    mov ah, 09h
    int 21h ;Prints the string
    ;PRINTS THE ENTER LINE
    mov ah,02H
    mov bx,0
    mov dh, 16 ;ycord
    mov dl, 22 ;xcord
    int 10H ;Sets cursor
    lea dx, n8
    mov ah, 09h
    int 21h ;Prints the string
    ;SETS CURSOR AND PRINTS THE PROMPT
    mov ah,02H
    mov bx,0
    mov dh, 12 ;ycord
    mov dl, 22 ;xcord
    int 10H ;Sets cursor
    mov dx, offset n4
    mov ah, 09h
    int 21h ;Prints the string
    
    mov si, offset u1.pname  
    .while (al != 13)
    mov ah, 0h
    int 16h
    .if (al != 13)
    mov [si], al
    mov dl, [si]
    mov ah, 02h
    int 21h
    inc si
    .endif
    .endw
    mov [si], 36    
    mov dx, 0
    ret
getname endp
;DRAWS THE PADDLE
drawpaddle proc
    mov al, p1.color
    mov ah, 0ch
    .while (p1.yval < 10)
        mov bx, p1.psize
        .while(p1.xval < bx) 
        mov cx, p1.xcord
        add cx, p1.xval
        mov dx, p1.ycord
        add dx, p1.yval
        int 10h
        mov bx, p1.psize
        inc p1.xval
        .endw
    inc p1.yval
    mov p1.xval, 0
    .endw
    mov p1.xval, 0
    mov p1.yval, 0
    ret
drawpaddle endp
;BALL MOVEMENT
ballmovement proc
    mov b1.color, 0;GETTING RID OF OLD BALL
    call drawball

    .if (b1.xspeed < 0 && b1.yspeed < 0);MOVING THE BALL IN DIFFERENT DIRECTIONS
        mov ax, b1.xspeed
        sub b1.xcord, ax
        mov ax, b1.yspeed
        sub b1.ycord, ax
        .elseif (b1.xspeed < 0 && b1.yspeed > 0)
        mov ax, b1.xspeed
        sub b1.xcord, ax
        mov ax, b1.yspeed
        add b1.ycord, ax
        .elseif (b1.xspeed > 0 && b1.yspeed < 0)
        mov ax, b1.xspeed
        add b1.xcord, ax
        mov ax,b1.yspeed
        sub b1.ycord, ax
        .else
        mov ax, b1.xspeed
        add b1.xcord, ax
        mov ax, b1.yspeed
        add b1.ycord, ax
    .endif

    .if (b1.xcord <= 5 || b1.xcord >= 610);EDGE OF BOARD COLLISIONS
    neg b1.xspeed
    .endif
    .if (b1.ycord <= 30)
    neg b1.yspeed
    .endif
    .if (b1.ycord >= 635)
    mov b1.xcord, 280
    mov b1.ycord, 440
    mov b1.xspeed, 0
    push ax
    mov ax, u1.level
    inc ax
    mov b1.yspeed, ax ;y gradient value
    neg b1.yspeed
    pop ax
    dec u1.life
    call clearhp
    call boardtext
    .endif

    ;BALL, PADDLE COLLISION
    push ax
    push bx
    mov ax, p1.psize
    mov bl, 2
    div bl
    mov dx, p1.xcord
    add dx, p1.psize
    mov cx, p1.xcord
    .if (b1.xcord >= cx && b1.xcord <= dx);CONTROLS BALL CONTACT WITH THE PADDLE
        mov ah, 0
        add ax, p1.xcord
        mov dx, p1.ycord
        mov cx, b1.ycord
        add cx, 10
            .if (cx >= dx);checks if there is actual contact
            .if (b1.xcord > ax) ;if on right side of padde
                .if (b1.xspeed >= 0) ;if coming from left side
                    inc b1.xspeed
                .else
                    dec b1.xspeed
                .endif
            .else ;if on left side of padel
                .if (b1.xspeed >= 0) ;if coming from left side
                    dec b1.xspeed
                .else
                    inc b1.xspeed ;if coming from right side
                .endif
            .endif
            neg b1.yspeed
            .endif
        .endif
        add cl, dl
        add dl, bl

    pop bx
    pop ax

    mov b1.color, 10;PRINTING NEW BALL
    call drawball
    ret
ballmovement endp
;DRAWS THE BALL
drawball proc
    mov al, b1.color
    mov ah, 0ch
    .while (b1.yval < 10)
        .while(b1.xval < 10) 
        mov cx, b1.xcord
        add cx, b1.xval
        mov dx, b1.ycord
        add dx, b1.yval
        int 10h
        inc b1.xval
        .endw
    inc b1.yval
    mov b1.xval, 0
    .endw
    mov b1.xval, 0
    mov b1.yval, 0
    ret
drawball endp
;INITIALIZES THE BRICKS
brickinitial proc
    mov si, offset bri
    mov al, 0
    mov count, 0
    .while (al < 6)
        mov cx, 0
        .while (cx < 6)
        push cx
            ;initialising block values
            push bx
            mov bx, bxcord
            mov [si].brick.xcord, bx
            pop bx
            push bx
            mov bx, bycord
            mov [si].brick.ycord, bx
            pop bx
            push bx
            mov bx, u1.level
            mov [si].brick.strength, bl
            pop bx
            mov [si].brick.color, 3
            mov [si].brick.fix, 0
            add bxcord, 105
            
            .if (u1.level >= 3);intializing special and fixed bricks
                push ax
                mov ax, 0
                .while (ax < 60000)
                    inc ax
                .endw
                pop ax
                push ax
                call randnum
                pop ax                
                .if (rand == 3 && count < 2)
                    mov [si].brick.fix, 2
                    inc count
                .elseif (rand == 1)
                    mov [si].brick.fix, 1
                .else
                    mov [si].brick.strength, 3
                .endif
            .endif
        pop cx
        add si, sizeof brick
        inc cx
        .endw
        inc al
        mov bxcord, 10
        add bycord, 40
    .endw
    mov bxcord, 10
    mov bycord, 30
    mov count, 0
    ret
brickinitial endp
;BRICK SPECIAL INITIAL
brickinitialspecial proc
    mov si, offset bri
    mov al, 0
    mov count, 0
    .while (al < 6)
        push ax
        mov cx, 0
        .while (cx < 6)
            push cx
            ;initialising block values
            push ax
            mov ax, 0
            .while (ax < 60000)
                inc ax
            .endw
            pop ax
            push ax
            call randnum               
            .if ([si].brick.strength > 0 && [si].brick.fix == 0)
                .if (rand == 3 || rand == 1 && count < 5)
                    mov [si].brick.strength, 0
                    call drawbrick
                    inc count
                .endif
            .endif
            pop ax 
        pop cx
        add si, sizeof brick
        inc cx
        .endw
        pop ax
        inc al
        mov bxcord, 10
        add bycord, 40
    .endw
    mov bxcord, 10
    mov bycord, 30
    mov count, 0
    ret
brickinitialspecial endp
;DRAWS THE BRICKS
drawbrick proc
    .if ([si].brick.strength > 2)
        mov [si].brick.color, 4
    .endif
    .if ([si].brick.strength == 2)
        mov [si].brick.color, 6
    .endif
    .if ([si].brick.strength == 1)
        mov [si].brick.color, 14
    .endif
    .if ([si].brick.strength <= 0)
        mov [si].brick.color, 0
        mov bx, u1.level
        add u1.score, bx
        inc bnum
    .endif
    .if ([si].brick.fix == 1)
        mov [si].brick.color, 5
    .endif
    .if ([si].brick.fix == 2)
        mov [si].brick.color, 9
    .endif

    mov al, [si].brick.color
    mov ah, 0ch
    .while (byval < 35)
        .while(bxval < 100) 
        mov cx, [si].brick.xcord
        add cx, bxval
        mov dx, [si].brick.ycord
        add dx, byval
        int 10h
        inc bxval
        .endw
    inc byval
    mov bxval, 0
    .endw
    mov bxval, 0
    mov byval, 0
    ret
drawbrick endp
;CHECKS FOR COLLISION WITH BRICK
brickcol proc
    mov bx, 0
    mov si, offset bri
    .while (bx < 36)
    push bx
    mov btemp, 0
    mov bx, [si].brick.xcord
    add bx, 100 ;brick right edge
    mov dx, b1.xcord
    add dx, 10 ;ball right edge
    mov ax, [si].brick.xcord
    .if ([si].brick.strength > 0);checking if ball is still alive                      
        .if (b1.xcord <= bx && b1.xcord >= ax || dx >= [si].brick.xcord &&  dx <= bx);checking if there is x overlap
            mov cx, [si].brick.ycord
            add cx, 35 ;brick bottom edge
            mov bx, b1.ycord
            add bx, 10 ;ball bottom edge
            mov ax, [si].brick.ycord
            .if (b1.ycord >= ax && b1.ycord <= cx || bx >= [si].brick.ycord && bx <= cx);checking if there is y overlap
                push ax
                push bx
                push cx
                push dx
                call playbeep
                .if ([si].brick.fix == 0);REDUCING THE BRICK'S HP
                    sub [si].brick.strength, 1
                    call drawbrick
                .elseif ([si].brick.fix == 2)
                    mov [si].brick.strength, 0
                    mov [si].brick.fix, 0
                    call drawbrick
                    call brickinitialspecial
                .endif
                pop dx
                pop cx
                pop bx
                pop ax

                mov bx, [si].brick.xcord
                add bx, 100 ;brick right edge
                mov dx, b1.xcord
                add dx, 10 ;ball right edge
                mov cx, [si].brick.ycord
                add cx, 35 ;brick bottom edge
                mov ax, b1.ycord
                add ax, 10 ;ball bottom edge
                .if (b1.ycord <= cx && ax >= cx && btemp == 0);checking for ball up collision
                    neg b1.yspeed
                    mov btemp, 1
                .endif
                .if (b1.xcord <= bx && dx >= bx);checking for ball left collision
                    neg b1.xspeed
                    mov btemp, 1
                .endif
                mov ax, b1.xcord
                .if (ax <= [si].brick.xcord && dx >= [si].brick.xcord && btemp == 0);checking for ball right collision
                    neg b1.xspeed
                    mov btemp, 1
                .endif
                mov ax, b1.ycord
                add ax, 10 ;ball bottom edge
                mov bx, b1.ycord
                .if (ax >= [si].brick.ycord && bx <= [si].brick.ycord && btemp == 0);checking for ball down collision
                    neg b1.yspeed 
                    mov btemp, 1                 
                .endif
            .endif
        .endif
    .endif
    pop bx
    inc bx
    add si, sizeof brick
    .endw
    ret
brickcol endp
;DRAWS THE BOARD
drawboard proc
    mov AH, 06h
    mov AL, 0
    mov CX, 0
    mov DH, 80
    mov DL, 80
    mov BH, 0h ;COLOR
    int 10h 
    call boardtext
    ret
drawboard endp
;TEXT FOR BOARD
boardtext proc
    ;PRINTS THE PAUSE BUTTON
    mov ah,02H
    mov bx,0
    mov dh, 0 ;ycord
    mov dl, 0 ;xcord
    int 10H
    lea dx, board1
    mov ah, 09h
    int 21h
    ;PRINTS THE LEVEL TEXT
    mov ah,02H
    mov bx,0
    mov dh, 0 ;ycord
    mov dl, 20 ;xcord
    int 10H
    lea dx, board4
    mov ah, 09h
    int 21h
    ;PRINTS THE LEVEL
    mov ax, u1.level
    mov num, ax
    call printscore
    ;PRINTS THE SCORE TEXT
    mov ah,02H
    mov bx,0
    mov dh, 0 ;ycord
    mov dl, 40 ;xcord
    int 10H
    lea dx, board3
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE
    mov ax, u1.score
    mov num, ax
    call printscore
    ;PRINTS THE HP TEXT
    mov ah,02H
    mov bx,0
    mov dh, 0 ;ycord
    mov dl, 70 ;xcord
    int 10H
    lea dx, board2
    mov ah, 09h
    int 21h
    mov bl, 0
    .while (bl < u1.life);PRINTS THE HEARTS
        mov dl, 3
        mov ah, 02h
        int 21h
        inc bx
    .endw
    ret
boardtext endp
;CLEAR HP LINE
clearhp proc
    mov dx, 0
    .while (dx < 15);PRINTS BLACK
        mov al, 0
        mov ah, 0ch
        mov cx, 580
        .while (cx < 620)
        int 10h
        inc cx        
        .endw
        inc dx
    .endw
    ret
clearhp endp
;CLEARS THE TIME
cleartime proc
    mov dx, 0
    .while (dx < 15);PRINTS BLACK
        mov al, 0
        mov ah, 0ch
        mov cx, 510
        .while (cx < 520)
        int 10h
        inc cx        
        .endw
        inc dx
    .endw
    ret
cleartime endp
;PRINTS THE TIMER
timer proc
    mov ah, 2ch
    int 21h
    ;mov t1, dh ;putting the second value in t1
    .if (dh != t2);checks if the second has changed
    dec time ;decreasing the amount of time left
    .endif
    mov t2, dh
    ;PRINTS THE TIME TEXT
    mov ah,02H
    mov bx,0
    mov dh, 0 ;ycord
    mov dl, 55 ;xcord
    int 10H
    lea dx, board5
    mov ah, 09h
    int 21h
    ;PRINTS THE TIME REMAINING VALUE
    mov ax, time
    mov bl, 60
    div bl
    mov dl, al
    add dl, 48
    mov bl, ah
    mov ah, 02h
    int 21h
    mov dl, 58
    int 21h
    mov bh, 0
    mov num, bx
    .if (num == 10)
        mov dl, 49
        mov ah, 02h
        int 21h
        mov dl, 48
        int 21h
    .elseif (num < 10)
        push dx
        call cleartime
        pop dx
        mov dx, num
        add dl, 48
        mov ah, 02h
        int 21h
    .else
    call printscore
    .endif
    ret
timer endp
;PRINTS SCORE
printscore proc
    .if (num < 10 || num == 10)
    mov dx, num
    add dx, 48
    mov ah, 02h
    int 21h
    .else
    mov ax, num
    mov bh, 0
    .while(al > 0)
    mov bl, 10
    div bl
    mov cx, 0
    mov cl, ah
    mov ah, 0
    push cx
    inc bh
    .endw
    .while (bh > 0)
    pop dx
    add dx, 48
    mov ah, 02h
    int 21h
    dec bh
    .endw
    .endif
    ret
printscore endp
;PRINTS THE MAIN MENU
mainmenu proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 9h ;COLOR
    int 10h
    call mainmenutext
    mov time, 240
    ret
mainmenu endp
;PRINTS THE TEXT OF THE MAIN MENU
mainmenutext proc
    ;PRINTS THE NAME OF THE PLAYER
    mov ah,02H
    mov bx,0
    mov dh, 1 ;ycord
    mov dl, 1 ;xcord
    int 10H ;Sets cursor
    lea dx, n5
    mov ah, 09h
    int 21h ;Prints the string
    lea dx, u1.pname
    mov ah, 09h
    int 21h
    ;PRINTS THE TITLE OF THE GAME
    mov ah,02H
    mov bx,0
    mov dh, 6 ;ycord
    mov dl, 30 ;xcord
    int 10H ;Sets cursor
    lea dx, n1
    mov ah, 09h
    int 21h ;Prints the string
    ;PRINTS THE ENTER PROMPT
    mov ah,02H
    mov dh, 12 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, n2
    mov ah, 09h
    int 21h
    ;PRINTS THE LEADERBOARD PROMPT
    mov ah,02H
    mov dh, 14 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, n6
    mov ah, 09h
    int 21h
    ;PRINTS THE ESCAPE PROMPT
    mov ah,02H
    mov dh, 16 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, n3
    mov ah, 09h
    int 21h
    ;PRINTS THE BACKSPACE PROMPT
    mov ah,02H
    mov dh, 18 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, n7
    mov ah, 09h
    int 21h
    ret
mainmenutext endp
;PRINTS THE LEADERBOARD
leaderboard proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 1h ;COLOR
    int 10h
    ;Printing ESC
    mov ah,02H
    mov bx,0
    mov dh, 1 ;ycord
    mov dl, 1 ;xcord
    int 10H ;Sets cursor
    lea dx, pau2
    mov ah, 09h
    int 21h ;Prints the string
    ;Printing HEADER
    mov ah,02H
    mov bx,0
    mov dh, 6 ;ycord
    mov dl, 30 ;xcord
    int 10H ;Sets cursor
    lea dx, leader1
    mov ah, 09h
    int 21h ;Prints the string
    
    call Read_File
    mov ah, 0h
    int 16h
    ret
leaderboard endp
;PRINT THE TEXT OF LEADERBOARD
leaderboardtext proc
    ;PRINTS THE LEVEL
    mov ah, 02H
    mov dh, lycord ;ycord
    mov dl, 25 ;xcord
    int 10H
    mov dx, readlevel
    add dx, 48
    mov ah, 02h
    int 21h
    ;PRINTS THE NAME
    mov ah, 02H
    mov dh, lycord ;ycord
    mov dl, 30 ;xcord
    int 10H
    lea dx, readname
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE
    mov ah, 02H
    mov dh, lycord ;ycord
    mov dl, 47 ;xcord
    int 10H
    mov dx, readscore
    mov num, dx
    call printscore
    ret
leaderboardtext endp
;PRINTS THE PAUSE MENU
pausemenu proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 1h ;COLOR
    int 10h
    call pausemenutext
    ;CONTROLS
    mov al, 0
    .while (al != 27)
    mov ah, 0h
    int 16h
    .if (al == 80 || al == 112)
    mov pcontrol, 1
    jmp endofpause
    .elseif (al == 27)
    mov pcontrol, 2
    .else
    mov al, 0
    .endif
    .endw
    endofpause:
    ret
pausemenu endp
;TEXT FOR PAUSE MENU
pausemenutext proc
    ;PRINTS THE RETURN TO GAME LINE
    mov ah,02H
    mov bx,0
    mov dh, 10 ;ycord
    mov dl, 25 ;xcord
    int 10H ;Sets cursor
    lea dx, pau1
    mov ah, 09h
    int 21h ;Prints the string
    ;PRINTS THE EXIT TO MAIN LINE
    mov ah,02H
    mov dh, 13 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, pau2
    mov ah, 09h
    int 21h
    ret
pausemenutext endp
;GAME OVER SCREEN
gameoverlost proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 1h ;COLOR
    int 10h
    call gameoverlosttext
    mov al, 0
    .while (al != 27)
    mov ah, 0h
    int 16h
    .if (al == 27)
    mov al, 27
    .else
    mov al, 0
    .endif
    .endw
    ret
gameoverlost endp
;GAME OVER SCREEN
gameoverwon proc
    mov ah, 06h
    mov al, 0
    mov cx, 0
    mov dh, 80
    mov dl, 80
    mov bh, 14 ;COLOR
    int 10h
    call gameoverwontext
    mov al, 0
    .while (al != 27)
    mov ah, 0h
    int 16h
    .if (al == 27)
    mov al, 27
    .else
    mov al, 0
    .endif
    .endw
    call Write_File
    ret
gameoverwon endp
;TEXT FOR GAME OVER
gameoverlosttext proc
    ;PRINTS THE NAME OF THE PLAYER
    mov ah,02H
    mov bx,0
    mov dh, 10 ;ycord
    mov dl, 25 ;xcord
    int 10H ;Sets cursor
    lea dx, n5
    mov ah, 09h
    int 21h ;Prints the string
    lea dx, u1.pname
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE TEXT
    mov ah,02H
    mov bx,0
    mov dh, 12 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, board3
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE
    mov ax, u1.score
    mov num, ax
    call printscore
    ;PRINTS THE EXIT TO MAIN LINe
    mov ah,02H
    mov dh, 14 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, pau2
    mov ah, 09h
    int 21h
    ret
gameoverlosttext endp
;TEXT FOR GAME OVER
gameoverwontext proc
    ;PRINTS THE NAME OF THE PLAYER
    mov ah,02H
    mov bx,0
    mov dh, 8 ;ycord
    mov dl, 25 ;xcord
    int 10H ;Sets cursor
    lea dx, n5
    mov ah, 09h
    int 21h ;Prints the string
    lea dx, board6
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE TEXT
    mov ah,02H
    mov bx,0
    mov dh, 10 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, u1.pname
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE TEXT
    mov ah,02H
    mov bx,0
    mov dh, 12 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, board3
    mov ah, 09h
    int 21h
    ;PRINTS THE SCORE
    mov ax, u1.score
    mov num, ax
    call printscore
    ;PRINTS THE EXIT TO MAIN LINe
    mov ah,02H
    mov dh, 14 ;ycord
    mov dl, 25 ;xcord
    int 10H
    lea dx, pau2
    mov ah, 09h
    int 21h
    ret
gameoverwontext endp
;PROGRESSES TO NEXT LEVEL
nextlevel proc
    .if (p1.psize > 20)
    sub p1.psize, 10
    add p1.speed, 2
    .endif   
    inc u1.level
    add u1.score, 20
    ret
nextlevel endp
;PLAYS A BEEP SOUND
playbeep proc
    mov     al, 182         
    out     43h, al         
    mov     ax, 1500                                  
    out     42h, al         
    mov     al, ah          
    out     42h, al 
    in      al, 61h                                    
    or      al, 3
    out     61h, al         
    mov     bx, 25          
    .pau1:
    mov     cx, 1535
    .pau2:
    dec     cx
    jne     .pau2
    dec     bx
    jne     .pau1
    in      al, 61h         
    and     al, 11111100b   
    out     61h, al         
    ret
playbeep endp
;CREATES THE FILE
Create_File Proc
    mov ah, 3ch
    mov dx, offset filename
    mov cx,0
    int 21h
    mov handle, ax

    mov ah,3eh
    mov bx,handle
    int 21h
    ret 
Create_File endp
;WRITES NEW DATA TO A FILE
Write_File Proc
    mov ah, 3dh 
    mov al, 1 
    lea dx, filename 
    int 21h 
    mov handle,ax

    mov bx, ax
    mov cx, 0
    mov dx, 0
    mov ah, 42h
    mov al, 02h
    int 21h
    ;LEVEL
    mov bx, handle
    mov cx, 2
    lea dx, u1.level
    mov ah, 40h
    mov al, 02h
    int 21h
    ;SCORE
    mov bx, handle
    mov cx, 2
    lea dx, u1.score
    mov ah, 40h
    mov al, 02h
    int 21h
    ;NAME
    mov bx, handle
    mov cx, 15
    lea dx, u1.pname
    mov ah, 40h
    mov al, 02h
    int 21h

    mov ah, 3eh
    mov bx, handle
    int 21h
    ret
Write_File endp
;READS DATA FROM THE FILE
Read_File Proc
    mov count, 0
    mov lycord, 12

    mov ah, 3dh ;OPENING FILE
    mov al, 0 
    lea dx, filename 
    int 21h 
    mov handle, ax
   
    mov ah, 3fh ;ADDING CONTENT TO BUFFER
    mov cx, 144 
    lea dx, buffer
    mov bx, handle 
    int 21h 
        
    mov si, offset buffer
    .while (count < 6) ;RUNNING LOOP TO OUTPUT LEADERBOARD
        mov ah, 02H ;SETTING CURSOR POSITION
        mov dh, lycord ;ycord
        mov dl, 27 ;xcord
        int 10H
        
        mov dx, word ptr [si] ;TYPE CASTING SI INTO DX
        mov readlevel, dx
        add si, 2
        mov dx, word ptr [si] ;TYPE CASTING SI INTO DX
        mov readscore, dx
        add si, 2

        mov cx, 0
        .while (cx < 15) ;USING LOOP TO OUTPUT SCORE
            mov dl, [si]
            .if (dl > 47 && dl < 59)
            mov ah, 02h
            int 21h
        .elseif (dl > 64 && dl < 91)
            mov ah, 02h
            int 21h
        .elseif (dl > 96 && dl < 123)
            mov ah, 02h
            int 21h
        .else 
            mov dl, 32
            mov ah, 02h
            int 21h
        .endif
            inc si
            inc cx
        .endw
        
        ;PRINT LEVEL
        mov dx, readlevel
        add dx, 48
        mov ah, 02h
        int 21h
        ;ADDING SPACES
        mov dl, 32
        mov ah, 02h
        int 21h
        mov dl, 32 
        mov ah, 02h
        int 21h
        ;PRINT SCORE
        mov dx, readscore
        mov num, dx
        call printscore

        add lycord, 2
        inc count
    .endw     
        mov ah, 3eh ;service to close file.
        mov bx, handle
        int 21h
    ret
Read_File endp
;RANDOM NUMBER GENERATOR
randnum proc
    mov ah, 2ch          
    int 21h           
                
    mov ax, 0
    mov al, dl
    mov cl, 10
    div cl

    mov rand, ah
    ret
randnum endp

EXIT: ;to jump to end of the code
mov ah, 4ch
int 21h
end