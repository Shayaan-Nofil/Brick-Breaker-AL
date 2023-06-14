;HOLDS ALL OF THE STRUCTURES
ball struct
xcord dw ?
ycord dw ?
xval dw 0
yval dw 0
xspeed dw 0
yspeed dw 1
color db ?
speed dw ?
ball ends

paddle struct
xcord dw 120
ycord dw 220
xval dw 0
yval dw 0
speed dw 15
psize dw 50
color db ?
paddle ends

player struct
pname db 15 dup(?)
life db 3
score dw 0
level dw 1
player ends

brick struct
xcord dw ?
ycord dw ?
strength db ?
color db ?
fix db 0
brick ends