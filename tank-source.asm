.model compact
.stack 200h
.586

; Comentando o c�digo - 48%
; 
; Coisas a fazer:
;  - Fazer com que um player possa destruir o outro
;  - Colocar tempo pra cada turno
;  - Melhorar os gr�ficos
;  - Fazer um logotipo pra por no come�o do jogo
;  - Limpar o c�digo


;-------------------------------------------------------------
;SEGMENTO DE DADOS (Buffer, Paleta de Cores e Vari�veis)
;-------------------------------------------------------------
.data
; Buffer do sistema de double buffer pra diminuir o efeito de flicking
buffer          db 64000 DUP (?)

; Paleta de cores, 45 cores definidas, algumas n�o s�o usadas
palette         db 0,0,0, 08,12,25, 20,20,30, 35,35,35, 15,15,15
                db 50,50,12, 15,10,10,  0, 0, 0, 20, 0, 0,  30,47,45
                db 30, 1, 2,  0, 0, 0, 63,63,63,  0, 0, 0,  0, 0, 0
                db 63,30, 0, 63,63,63, 63,63,63,  0, 0, 0, 63,63,63
                db 10,20,00, 10,50, 0, 20,30, 0, 63,63,20, 20,30,00
                db 20,63,00, 30,40,00, 63,63,63, 50,50,12, 52,48,12
                db 48,52,12, 48,48,10, 52,52,10, 52,50,14, 50,50,14
                db  0,40,53,  0,45,55, 10,40,53, 10,45,55,  5,40,55
                db  0,45,50, 50,7,7, 7, 7, 50, 50, 25,7, 30,47,45

; Buffer tempor�rio pro efeito de fade in e fade out
fade_buffer     db 45*3 DUP (?)


; Efeito de Explos�o
particles_x     dw ?            ; Coordenada X inicial das part�culas
particles_y     dw ?            ; Coordenada Y inicial das part�culas


; Uso geral (Vari�veis compartilhadas entre diversas fun��es
draw_address    dw ?            ; Segmento a plotar
draw_x          dw ?            ; Coordenada X
draw_y          dw ?            ; Coordenada Y
x_length        dw ?            ; Largura
y_length        dw ?            ; Altura
draw_color      db ?            ; Cor

; Vari�veis dependentes do jogador em quest�o
flip            db 0            ; SpriteDraw - 0 pinta player1 / 1 pinta player2
turn            db 0            ; Diversas fun��es - informa de quem � a vez

; Plotagem de fontes na tela
font_x          dw ?            ; Coordenada X
font_y          dw ?            ; Coordenada Y
font_initX      dw ?            ; Coordenada X inicial (usada internamente)
font_color      db ?            ; Cor (N�o utilizada)
font_italic     db ?            ; 1 = It�lico  0 = Normal
font_shadow     db ?            ; Cor da sombra (255 = Sem sombra)

char_to_draw    db ?            ; Usada na DrawChar (Caracter a plotar)

; Vari�veis dos jogadores
player1_x       dw ?            ; Coordenada X
player1_y       dw ?            ; Coordenada Y
player1_angle   dw ?            ; �ngulo do canh�o
player1_vel     dd 30           ; Velocidade

player2_x       dw ?            ; Coordenada X
player2_y       dw ?            ; Coordenada Y
player2_angle   dw ?            ; �ngulo do canh�o
player2_vel     dd 45           ; Velocidade

; Mais vari�veis gerais, desta vez as que est�o relacionadas com c�lculos
; em ponto flutuante
velocity        dd ?            ; Velocidade
time_inc        dd 0.11         ; Incremento do tempo
gravity         dd -9.8         ; Gravidade
time            dd ?            ; Tempo
divtwo          dw 2            ; Constante 2
degPi           dd 0.0174532925 ; pi / 180

; Vari�veis espec�ficas
string_mask     dd 100000000    ; Usada na fun��o

rand_range      dw ?            ; Usada como intervalo da fun��o random
Seed            dw ?            ; Semente para fun��o random

radius          dw ?            ; Raio do c�rculo
angle           dd ?            ; Angulo (usado por v�rias fun��es)

p1_pos_done     db ?            ; = 1 quando o player 1 est� posicionado no mapa
p2_pos_done     db ?            ; = 1 quando o player 2 est� posicionado no mapa

putpixel_x      dw ?            ; Coordenada X do pixel a plotar
putpixel_y      dw ?            ; Coordenada Y do pixel a plotar
pixel_color     db ?            ; Cor do pixel a plotar

temp_word       dw ?            ; Word tempor�ria
temp_dword      dd ?            ; Double Word tempor�ria
temp_byte       db ?            ; Byte tempor�rio

; Vari�veis usadas na gera��o do terreno
k1              dw ?            ; Constante 1
k2              dw ?            ; Constante 2
k3              dw ?            ; Constante 3

;-------------------------------------------------------------
;SEGMENTO DE DADOS (Fontes, Strings e Sprites)
;-------------------------------------------------------------
.FARDATA @Data_Segment2

; Fonte usada pra escrever o texto durante todo o jogo
; Formato 1 bit por pixel
; Tem tamanho 5x5, est� codificada em bits 0 = transparente, 1 = opaco
small_font      db 000, 000, 000, 000, 000, 032, 032, 032, 000, 032, 080, 080, 000, 000, 000, 080
                db 248, 080, 248, 080, 032, 112, 096, 048, 112, 200, 208, 032, 088, 152, 096, 104
                db 112, 144, 104, 032, 032, 000, 000, 000, 016, 032, 032, 032, 016, 064, 032, 032
                db 032, 064, 168, 112, 032, 112, 168, 032, 032, 248, 032, 032, 000, 000, 000, 032
                db 064, 000, 000, 248, 000, 000, 000, 000, 000, 000, 032, 008, 016, 032, 064, 128
                db 112, 136, 136, 136, 112, 016, 048, 016, 016, 056, 112, 008, 112, 128, 248, 240
                db 008, 112, 008, 240, 016, 144, 240, 016, 016, 240, 128, 240, 008, 240, 112, 128
                db 240, 136, 112, 120, 008, 016, 032, 032, 112, 136, 112, 136, 112, 112, 136, 120
                db 008, 112, 000, 032, 000, 032, 000, 000, 032, 000, 032, 064, 016, 032, 064, 032
                db 016, 000, 248, 000, 248, 000, 064, 032, 016, 032, 064, 112, 008, 048, 000, 032
                db 112, 184, 184, 128, 112, 112, 136, 248, 136, 136, 240, 136, 240, 136, 240, 112
                db 128, 128, 128, 112, 240, 136, 136, 136, 240, 248, 128, 240, 128, 248, 248, 128
                db 240, 128, 128, 120, 128, 184, 136, 120, 136, 136, 248, 136, 136, 248, 032, 032
                db 032, 248, 120, 016, 016, 144, 096, 136, 144, 224, 144, 136, 128, 128, 128, 128
                db 248, 136, 216, 168, 136, 136, 136, 200, 168, 152, 136, 112, 136, 136, 136, 112
                db 240, 136, 240, 128, 128, 112, 136, 168, 152, 120, 240, 136, 240, 144, 136, 112
                db 128, 112, 008, 112, 248, 032, 032, 032, 032, 136, 136, 136, 136, 112, 136, 136
                db 080, 080, 032, 136, 136, 168, 216, 136, 136, 080, 032, 080, 136, 136, 136, 120
                db 008, 112, 248, 016, 032, 064, 248, 112, 064, 064, 064, 112, 128, 064, 032, 016
                db 008, 112, 016, 016, 016, 112, 032, 080, 000, 000, 000, 000, 000, 000, 000, 252
                db 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000

; Strings utilizadas pelo jogo
; Formato: Cor, "String"
;          0 = Fim da string
;          255 = Quebra de linha

game_title      db 23,"JOGO DO CANHAOZINHO!",0
game_version    db 21,"VER 0.001 (BETA)",0
number_str      db 17,"999999999",0
angle_str       db 23,"ANG: ",0
vel_str         db 23,"VEL: ",0
player1_str     db 17,"PLAYER 1",0
player2_str     db 17,"PLAYER 2",0

instruct_str    db 17,"INSTRUCOES",0
info_str        db 17,"GANHA QUEM ACERTAR O OPONENTE PRIMEIRO (",23,"OHH",17,")",255,255
                db 23," COMANDOS",17,":", 255,255
                db 17," SETA PRA ",23,"CIMA",17,"/",23,"BAIXO",17,": ",255,255,9,"  AUMENTA/DIMINUI A VELOCIDADE DO PROJETIL",255,255,255
                db 17," SETA PRA ",23,"ESQUERDA",17,"/",23,"DIREITA",17,":",255,255,9,"  AUMENTA/DIMINUI O ANGULO DO CANHAO",255,255,255
                db 17," ENTER:",255,255,9,"  ATIRA",255,255,255
                db 23,"       *QUEM PERDER EH MULHER DO PADRE*",255
                db 23,"   PRESSIONE ",17,"QUALQUER TECLA",23," PARA CONTINUAR! =)",0

; Sprite da bola do canh�o, codificado por bytes, de tamanho 8x8...
canon_ball      db 00,00,00,02,02,00,00,00,00,02,02,01,01,02,02,00,00,02,01,01,03,01,00,00,00,01,01,01,03,03,01,00
                db 00,01,01,01,01,01,01,00,00,02,01,01,01,01,02,00,00,02,02,01,01,02,02,00,00,00,00,02,02,00,00,00

; Sprite da parte m�vel do canh�o, 8 sprites de 10x10 codificados por bytes (cada pixel um byte)
shooter         db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,2,2,2,2,2,2,2,2,0,0,3,3,3,3,3,3,3,3,0,0,1,1,1,1,1,1,1,1,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                db 0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,2,2,2,0,0,2,2,2,2,2,3,3,3,2,0,3,3,3,2,2,2,1,1,1,0,2,1,1,1,1,1,1,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,1,1,1,1,2,0,0
                db 1,1,1,1,2,2,2,3,3,0,1,1,2,2,2,3,3,2,1,0,2,2,3,3,2,1,1,1,1,0,3,3,2,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,1,1,2,0,0,0,0,1,1,1,2,2,3,2,0
                db 0,1,1,1,2,3,3,2,1,0,1,1,2,2,3,2,1,1,0,0,1,2,3,3,2,1,1,0,0,0,2,3,2,1,1,0,0,0,0,0,2,2,1,1,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,1,2,3,0,0,0,0,0,1,1,2,3,2,0,0
                db 0,0,1,1,2,3,2,1,0,0,0,1,1,2,3,2,1,1,0,0,1,1,2,3,2,1,1,0,0,0,1,2,3,2,1,1,0,0,0,0,0,3,2,1,1,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,2,3,0,0,0,0,0,1,1,2,3,2,0,0,0,0,1,1,2,3,2,1,0,0
                db 0,0,1,1,2,3,1,1,0,0,0,1,1,2,3,2,1,0,0,0,1,1,2,3,2,1,0,0,0,0,0,1,2,3,1,1,0,0,0,0,0,2,3,2,1,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,0,0,0,0,0,0,1,1,2,3,1,0,0,0,0,0,1,1,2,2,1,0,0,0,0,0,1,2,3,2,1,0,0,0
                db 0,1,1,2,3,1,1,0,0,0,0,1,2,3,2,1,0,0,0,0,1,1,2,3,1,1,0,0,0,0,1,1,2,2,1,0,0,0,0,0,2,2,3,2,1,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0
                db 1,2,3,1,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0,1,2,3,1,0,0,0,0,0,0

PARTICLE_COUNT  EQU 50
particles_angle dw PARTICLE_COUNT DUP(?)    ; Vetor com o �ngulo de cada part�cula
particles_vel   dw PARTICLE_COUNT DUP(?)    ; Vetor com a velocidade da cada part�cula
particles_on    db PARTICLE_COUNT DUP(?)    ; Vetor com o estado de cada part�cula

;-------------------------------------------------------------
;SEGMENTO DE DADOS  (Buffer do Terreno)
;-------------------------------------------------------------
.FARDATA @Data_Segment3

map             db 64000 DUP (?)        ; O Buffer do MAPA \o/
    

;-------------------------------------------------------------
;SEGMENTO DE C�DIGO
;-------------------------------------------------------------
.code

ASSUME  fs:@Data_Segment2               ; Aqui eu declaro um pseudo segmento
ASSUME  gs:@Data_Segment3               ; e aqui eu declaro outro =)

;=============================================================
;Loop Principal
;  - Aqui o programa come�a a ser executado
;=============================================================
Start:
        ; In�cio do c�digo, aqui colocamos todos os segmentos em seus devidos
        ; lugares
        
        ; Segmento de dados em DS
        mov     ax, @data
        mov     ds, ax

        ; Segundo segmento de dados em FS
        mov     ax, @Data_Segment2
        mov     fs, ax
        
        ; Terceiro segmento de dados em GS
        mov     ax, @Data_Segment3
        mov     gs, ax

        ; Inicializo a semente de gerador de n�meros aleat�rios
        call    Randomize
        
        ; E Vou pro modo gr�fico
        call    Mode13h

        finit                           ; Inicializa unidade de ponto flutuante
        mov     player1_angle, 30       ; �ngulo do player1 = 30
        mov     player2_angle, 150      ; �ngulo do player2 = 150

        call    ClearScreen             ; Limpa a tela
        call    DrawMap                 ; Gera o terreno aleat�rio
        call    GameLoop                ; Entra no loop principal do jogo...
Fim:
        call TextMode                   ; Chegando aqui vamos pro modo texto
        mov ax, 4c00h                   ; E Finalizamos com a chamada 4c00
        int 21h                         ; da int 21h do DOS... FIM!

;=============================================================
;Procedures Utilit�rias
;  - Procedimentos gerais como gera��o de n�meros aleat�rios,
;    drawing de strings no buffer e etc.
;=============================================================



;-------------------------------------------------------------
; Randomize: Gera a semente para 'Random'
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Seed -> Semente para o gerador de n�meros aleat�rios
;-------------------------------------------------------------
Randomize               PROC
        mov     ah, 2Ch         ; HoHoHo Subfun��o pra pegar a hora do sistema
        int     21h
        ; Retorna em DL os segundos, em CL os minutos, em CH as horas e em DL
        ; os cent�simos de segundos da hora atual do sistema
        
        mov     seed, dx        ; Da� como queremos n�meros aleat�rios n�s
        add     seed, ax        ; adicionamos aqui
        sub     seed, cx        ; adicionamos ali
        xor     ch, ch
        add     seed, cx
        mul     cx              ; multiplicamos acol�
        add     ax, dx          ; adicionamos dinovo
;        xor     al, cl          ; damo um exclusive or pra bagun�ar tudo
        sub     seed, ax        ; adicionamos dinovo
                                ; e tamram! temos uma nova semente
        ; n�o utilizei nenhum m�todo matem�tico pra esse fun��o...
        ; foi tudo puro improviso, mas serviu pra o q ela foi feita =)
        ret
Randomize               ENDP

;-------------------------------------------------------------
; Random: Gera um n�mero aleat�rio
;   * Par�metros:
;      - rand_range -> faixa de n�meros a gerar
;   * Retorno:
;      - DX -> N�mero gerado
;-------------------------------------------------------------
Random          PROC
        mov     ax, seed                ; Agora sim pegamos a semente
        mov     dx, 0ABCDh              ; movemos pra DX uma constante qualquer
        mul     dx                      ; Multiplicamos AX por DX
        inc     ax                      ; Incrementamos AX
        mov     seed, ax                ; Movemos para a semente o valor nele
        add     seed, dx                ; Adicionamos o valor de dx em seed
        xor     dx, dx                  ; limpamos DX
        mov     cx, rand_range          ; movemos para CX rand_range
        div     cx                      ; dividimos ax por cx, e como o resto
                                        ; vai pra DX � s� pegar o valor nele e
                                        ; pronto =)
        ret
Random          ENDP


;-------------------------------------------------------------
; IntToString: Converte um inteiro numa string e pinta na tela
;   * Par�metros:
;      - ax/eax -> N�mero a converter
;      - font_x -> Coordenada X a pintar
;      - font_y -> Coordenada Y a pintar
;      - font_color -> Cor da fonte
;      - font_italic -> 0=Normal 1=It�lico
;      - font_shadow -> Cor da sombra (255 = Transparente)
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
IntToString             PROC
        mov     si, offset number_str   ; Primeiro movemos pra SI o endere�o
                                        ; de nosso buffer tempor�rio

        mov     cl, font_color          ; movemos pra cl a cor da fonte
        mov     fs:[si], cl             ; movemos pro primeiro byte do nosso
                                        ; buffer o valor da cor

        xor     edx, edx                ; beleza.. limpamos edx
        mov     ecx, string_mask        ; movemos pra ecx a m�scara, que
                                        ; determina quantos caracteres queremos
                                        ; pintar.. (isso facilita colocar zeros
                                        ; a esquerda)
                                        
        mov     bl, 1                   ; iniciamos bl como 1, ele ser� o nosso
                                        ; contador
        inc     si                      ; incrementamos si (por que j� mechemos
                                        ; com o primeiro byte)
; Loop principal
GetNextNumber:
        cmp     ecx, 0                  ; Comparamos ECX com 0
        je      ConversionFinished      ; Se for igual � por que acabamos de
                                        ; converter o n�mero
        ;sen�o...
        div     ecx                     ; dividimos EAX por ECX
        add     eax, 48                 ; adicionamos a EAX o c�digo ASCII do 0
        mov     fs:[si], al             ; e mandamos pro nosso buffer
        mov     eax, edx                ; movemos EDX (resto) pra EAX
        xor     edx, edx                ; e limpamos EDX

        push    eax                     ; guardamos o valor do EAX na pilha
        mov     eax, ecx                ; movemos o valor de ecx pra eax
        mov     ecx, 10                 ; movemos 10 pra ecx
        div     ecx                     ; EAX = EAX / 10
        mov     ecx, eax                ; movemos pra eax a nova m�scara
        pop     eax                     ; restauramos o valor de EAX da pilha

        inc     si                      ; incrementa SI (�ndice do buffer)
        inc     bl                      ; incrementa BL (o contador)
        cmp     bl, 9                   ; comparamos BL com 9 (n�mero m�ximo de
        jne     GetNextNumber           ; caracteres.. enquanto n�o for igual n�s
                                        ; voltamos pro loop

; Chegando aqui � s� imprimir
ConversionFinished:
        mov     al, 0                   ; Movemos pra fs:[si] (final do buffer)
        mov     fs:[si], al             ; o valor 0, indicando final da string
        
        mov     si, offset number_str   ; movemos seu offset pra si
        call    DrawText                ; e mandamos imprimir na tela =D
        
        ret                             ; FIM!
IntToString             ENDP


;===============================================================================
;Procedures Gr�ficas
;  - Rotinas para altera��o do modo de v�deo, plotagem de pixels, drawing de
;    caracteres, plotagem de primitivos (reta, circulo, janelas e etc)
;===============================================================================


;-------------------------------------------------------------
; Mode13h: Muda para o modo gr�fico vga (320x200x256), setando
;          uma paleta inicial
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
Mode13h                 PROC
        mov     ax, 0013h               ; Subfun��o pro modo VGA (320x200)
        int     10h                     ; chamamos a interrup��o 10h (V�deo)

        mov     cx, 45                  ; movemos pra cx a quantidade de cores
        mov     si, offset palette      ; setamos o offset da paleta de cores
        call    SetPalette              ; e mandamos atualiza nossa paleta �ee!
        ret                             ; FIM!
Mode13h                 ENDP



;-------------------------------------------------------------
; SetPalette: Modifica a paleta de cores
;   * Par�metros:
;      - si -> offset do buffer onde est� a paleta
;      - cx -> quantidade de cores
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
SetPalette              PROC
        shl     cx, 1                   ; Multiplica CX por 2
        add     cx, cx                  ; Soma CX a CX
                                        ; Agora temos CX = CX * 3
                                        ; foi bem mais r�pido que um MUL hein!
        
        mov     dx, 03C8h               ; Porta da paleta de cores em modo VGA
        xor     al, al                  ; limpamos AL
        cli                             ; limpamos flag de interrup��o
        
        out     dx, al                  ; mandamos 0 pra sa�da da porta
        inc     dx                      ; Incrementa DX
        cld                             ; limpa flag de dire��o
        rep     outsb                   ; mandamos os bytes na paleta em ds:[si]
        sti                             ; pra porta especificada l� em cima
                                        ; depois STI restaura as interrup��es
        ret                             ; FIM!
SetPalette              ENDP



;-------------------------------------------------------------
; TextMode: Seta modo Texto
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
TextMode                PROC
        mov     ax, 0003h               ; Subfun��o modo texto
        int     10h                     ; executa

        ret                             ; TA DA!
TextMode                ENDP



;-------------------------------------------------------------
; PuxPixel: Plota um pixel na tela
;   * Par�metros:
;      - es -> segmento do buffer
;      - putpixel_x -> coordenada x do ponto
;      - putpixel_y -> coordenada y do ponto
;      - pixel_color -> cor do ponto
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
PutPixel                PROC
; N�o fosse pelo CLIP essa seria a fun��o mais r�pida que eu j� fiz pra plotar
; pixels no padr�o VGA =(

        cmp     putpixel_y, 1           ; Compara putpixel_y com 1
        jb      ClipPixel               ; Se for menor n�o pinta
        cmp     putpixel_x, 1           ; Mesma coisa pra x
        jb      ClipPixel               ; n�o pinta
        
        cmp     putpixel_y, 199         ; compara se t� saindo da tela
        ja      ClipPixel               ; se tiver n�o pinta
        cmp     putpixel_x, 319
        ja      ClipPixel               ; n�o pinta

        push    ax                      ; chegando aqui tudo beleza, salvaoms ax
        
        mov     ax, putpixel_y          ; mandamos pra ax o valor em putpixel_y
        shl     ax, 6                   ; multiplicamos por 64
        mov     di, ax                  ; movemos o valor pra di
        shl     ax, 2                   ; multiplicamos por 4 (como tinhamos
                                        ; multiplicado por 64 antes d� um total
                                        ; de 256, logo 256+64 = 320
        add     di, ax                  ; Adicionamos a DI

        add     di, putpixel_x          ; adicionamos o offset X

        mov     es:[di], ch             ; plotamos o caractere no buffer

        pop     ax                      ; restauramos AX
ClipPixel:
        ret                             ; Retorna pro ponto onde a foi chamado
PutPixel                ENDP



;-------------------------------------------------------------
; DrawChar: Pinta um caractere na tela
;   * Par�metros:
;      - char_to_draw -> C�digo ASCII do caractere a pintar
;      - font_x -> Coordenada X a pintar
;      - font_y -> Coordenada Y a pintar
;      - font_color -> Cor da fonte
;      - font_italic -> 0=Normal 1=It�lico
;      - font_shadow -> Cor da sombra (255 = Transparente)
;   * Retorno:
;      - nenhum
;-------------------------------------------------------------
DrawChar                PROC
        cmp     font_y, 199-5           ; Aqui o famoso clip pra evitar acesso
                                        ; indevido a mem�ria
        ja      DrawCharClip            ; se font_y ultrapassar a tela, clipa
        
        push    si                      ; salvamos SI, pois geralmente usamos
                                        ; essa fun��o de dentro da DrawText
                                        ; SI na DrawText � o offset da string
                                        
        mov     si, offset small_font   ; movemos para si o offset da fonte
        xor     ah, ah                  ; limpamos ah, pq vamos calcular em ax
                                        ; o deslocamento pro devido caractere

        mov     al, char_to_draw        ; movemos o c�digo ascii do caractere
                                        ; pra al
        sub     al, 32                  ; convertemos pro primeiro caractere de
                                        ; nossa fonte

        mov     cl, 5                   ; multiplicamos por 5
        mul     cl

        add     si, ax                  ; e adicionamos o deslocamento para aquele
                                        ; caractere a SI
        xor     cx, cx                  ; Zeramos CX, (CH � o o contador de colunas)

NextCol:
        xor     dx, dx                  ; Zeramos DX, (DL � o contador de linhas)

NextRow:
        mov     bl, fs:[si]             ; Pegamos o byte atual na fonte

        mov     cl, 7                   ; Aqui invertemos dl em cl
        sub     cl, dl                  ; pra pegar o bit atual que devemos pintar
        shr     bl, cl                  ; deslocamento
        and     bl, 1                   ; esse and retorna pra gente se o bit � 0 ou 1 =)
        jz      MaskBit                 ; se for 0 ent�o n�o pintamos nada
        ; sen�o...
        mov     ax, font_y              ; calculamos o offset a imprimir no buffer
        add     al, ch                  ; di = (font_y*320)+x
        shl     ax, 6                   ; obs: Ver explica��o do calculo em PutPixel
        mov     di, ax
        shl     ax, 2
        add     di, ax

        add     di, font_x
        add     di, dx
        add     di, offset buffer

        mov     al, font_color

        cmp     font_italic, 0          ; Aqui a gente v� se colocamos a fonte it�lica
        je      NoItalic                ; Sen�o pulamos o bloco abaixo

        xor     bx, bx                  ; Aqui simplesmente adicionamos 1 a cada 2 linhas
        mov     bl, ch
        shr     bl, 1                   ; pra inclinar a fonte ^^!
        sub     di, bx
NoItalic:
        mov     es:[di], al             ; E finalmente movemos para o buffer

MaskBit:
        inc     dl                      ; Incrementamos dl at� 5, s�o 5 linhas
        cmp     dl, 5
        jne     NextRow

        inc     si                      ; Incrementamos o SI (ponteiro para o byte
                                        ; cont�m os pixels a serem plotados)
        inc     ch
        cmp     ch, 5                   ; Incrementamos dl at� 5, s�o 5 colunas
        jne     NextCol

        pop si                          ; Restauramos SI
DrawCharClip:

        ret                             ; Fim \o/
DrawChar                ENDP



;-------------------------------------------------------------
; DrawText: Pinta, usando a DrawChar, uma string na tela
;   * Par�metros:
;      - si -> ponteiro para a string
;      - font_x -> Coordenada X a pintar
;      - font_y -> Coordenada Y a pintar
;      - font_color -> Cor da fonte
;      - font_italic -> 0=Normal 1=It�lico
;      - font_shadow -> Cor da sombra (255 = Transparente)
;   * Retorno:
;      - Nenhum
;   * OBS: A String deve estar no segmento apontado por fs
;-------------------------------------------------------------
DrawText                PROC
        mov     ax, font_x              ; aqui salvamos a posi��o X inicial
        mov     font_initx, ax          ; pro caso de uma quebra de linha

DrawNextChar:
        mov     al, fs:[si]             ; Pegamos o caractere a plotar
        cmp     al, 0                   ; Se for 0 ent�o acabou
        je      DrawTextEnd             ; e vamos pro final da rotina
        
        cmp     al, 32                  ; Sen�o comparamos com 32 (abaixo de 32
                                        ; � mudan�a de cor)
                                        
        jnb     NoChangeFontColor       ; se n�o for menor ent�o n�o mudamos a cor
        mov     font_color, al          ; se for menor, mudamos a cor
        jmp     NoDrawChar              ; e vamos pro pr�ximo caractere
        
NoChangeFontColor:                      ; sen�o n�o mudamos a cor, temos q plotar

        cmp     al, 255                 ; mas primeiro testamos se al � igual a 255
        jne     NoWrapLine              ; se for ent�o temos uma quebra de linha
        
        add     font_y, 6               ; pulamos a linha
        mov     bx, font_initx          ; voltamos pro X inicial
        mov     font_x, bx              ; salvamos o novo X em font_x
        jmp     NoDrawChar              ; e vamos pro pr�ximo caractere

NoWrapLine:
        mov     char_to_draw, al        ; ent�o, se n�o for nada daquilo l� de cima
        add     font_x, 6               ; incrementamos o X
        cmp     font_shadow, 255        ; e testamos se vamos pintar uma sombra
        je      NoShadow                ; se font_shadow = 255 ent�o n�o vamos pintar
        
        inc     font_x                  ; sen�o � facil, incrementamos x e y
        inc     font_y
        mov     al, font_color          ; aqui n�s salvamos a cor da fonte
        push    ax
        mov     al, font_shadow         ; mudamos a cor pra cor da sombra
        mov     font_color, al
        call    DrawChar                ; e pintamos a sombra
        dec     font_x                  ; decrementamos x e y
        dec     font_y
        pop     ax                      ; restauramos a cor original da fonte
        mov     font_color, al

NoShadow:
        call    DrawChar                ; e pintamos a fonte por cima da sombra =D

NoDrawChar:
        inc     si                      ; incrementamos pro pr�ximo caractere
        jmp     DrawNextChar

DrawTextEnd:
        add     font_x, 6               ; e no final corremos o X mais uma vez pra direita
        ret                             ; fim =D
DrawText                ENDP



;-------------------------------------------------------------
; ClearScreen: Limpa a Tela
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
ClearScreen             PROC
; Essa fun��o quase n�o tem mais utilidade, por que a FlipMap trata
; de limpar a tela... s� deixei ela aqui por que vai que eu preciso usar ela
; e talz... custa nada, ela � pequena =)

        cld                             ; Limpamos a flag de dire��o
        mov     ax, ds                  ; movemos pra es o segmento do buffer
        mov     es, ax
        mov     cx, 16000               ; vamos gravar 16000 double words
        xor     eax, eax                ; de valor 0 cada uma
        xor     edi, edi

        rep     stosd                   ; rep faz o servi�o
        
        ret                             ; fim
ClearScreen             ENDP



;-------------------------------------------------------------
; WaitRetrace: Aguarda o monitor terminar de atualizar a tela
;              (Usado antes de pintar algo na tela pra evitar
;              Flickering e manter as anima��es suaves)
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
WaitRetrace             PROC
        mov     dx, 03DAh               ; porta que retorna se o monitor est�
                                        ; atualizando a tela

Retrace1:
        in      al, dx                  ; no primeiro bloco esperamos ele terminar
        test    al, 08h                 ; de atualizar a tela caso ele esteja no
        jnz     Retrace1                ; meio de uma atualiza��o

Retrace2:
        in      al, dx                  ; agora sim, pegamos uma atualiza��o desde
        test    al, 08h                 ; o come�o e esperamos ela ser completada
        jz      Retrace2                ; a� temos mais tempo de plotar as paradas
                                        ; na tela, at� a pr�xima atualiza��o =D
        ret
WaitRetrace             ENDP



;-------------------------------------------------------------
; SpriteDraw: Pinta um sprite (figura) na tela
;   * Par�metros:
;      - si -> Offset do Sprite (O Segmento deve ser o que �
;              apontado por FS)
;      - draw_x -> Coordenada x
;      - draw_y -> Coordenada y
;      - x_length -> Largura do Sprite
;      - y_length -> Altura do Sprite
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
SpriteDraw              PROC
        pushaw                          ; salvando todos os registradores =D

        cmp     draw_x, 0               ; Clipamos tudo aqui, pra evitar
        jbe     ClipSprite              ; acesso indevido a certas �reas da
        cmp     draw_y, 0               ; mem�ria...
        jbe     ClipSprite              ; o que esse bloco faz � simples
        cmp     draw_x, 320             ; impede que um sprite seja pintado
        jae     ClipSprite              ; caso ele esteja fora da tela
        cmp     draw_y, 200
        jae     ClipSprite

        mov     ax, ds                  ; vamos pintar no segmento de dados
        mov     es, ax                  ; onde est� o nosso buffer

        xor     cx, cx                  ; cx contador y, como j� eh de praxe
NRow:

        xor     dx, dx                  ; dx contador x
NCol:
        mov     ax, draw_y              ; dinovo aquele c�lculo de offset
        add     ax, cx                  ; di = (draw_y * 320) + draw_x
        shl     ax, 6
        mov     di, ax                  ; num vo comentar isso naum, veja la
        shl     ax, 2                   ; no PutPixel
        add     di, ax
        
        add     di, draw_x
        cmp     flip, 0                 ; Aqui fazemos uma gambiarra pra inverter
        je      DontMirrorSprite        ; o sprite, caso seja o player dois
        sub     di, dx                  ; complemento de 2 =D
        sub     di, dx
DontMirrorSprite:
        add     di, dx

        mov     al, fs:[si]             ; pegamos o byte a pintar
        cmp     al, 0
        je      MaskByte                ; se for 0 n�s n�o pintamos

        mov es:[di], al                 ; ok, mova pra es:[di] (buffer)

MaskByte:
        inc si                          ; vamos pro pr�ximo byte

        inc dx                          ; incrementamos dx
        cmp dx, x_length                ; e enquanto for menor que x_length
        jb NCol                         ; voltamos pra NCol

        inc cx                          ; mesma coisa pra cx
        cmp cx, y_length                ; enquanto for menor que y_length
        jb NRow                         ; voltamos pra NRow
ClipSprite:
        popaw                           ; restauramos os registradores
        ret                             ; e retornamos
SpriteDraw              ENDP


;-------------------------------------------------------------
; FlipBuffer: Manda tudo que t� no buffer principal pra tela =)
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
Flipbuffer              PROC
        push    ax                      ; salvamos ax e cx
        push    cx
        
        cld                             ; limpando flag de dire��o
        mov     ax, 0a000h              ; vamos mandar tudo pro v�deo, e
                                        ; 0xA000h � onde come�a a mem�ria de
                                        ; v�deo no modo 320x200 =)
        mov     es, ax

        xor     edi, edi                ; ok, come�amos do 0 nos dois
        xor     esi, esi

        mov     cx, 16000               ; movemos (na verdade copiamos) 16000 DW
        rep     movsd                   ; rep faz o servi�o
        
        pop     cx                      ; ok, restaurando cx e ax
        pop     ax

        ret                             ; retornando capit�o
Flipbuffer              ENDP


;-------------------------------------------------------------
; DrawLine: Desenha uma linha a partir de um �ngulo, um centro
;           e um raio
;   * Par�metros:
;      - ax -> Coordenada x do centro
;      - bx -> Coordenada y do centro
;      - cl -> Raio
;      - ch -> Cor da linha
;      - angle -> Angulo da linha em float point
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawLine                PROC
        push    angle                    ; salvamos angle e temp_word
        push    temp_dword
        mov     temp_byte, 1             ; mandamos 1 pra temp_byte
                                         ; foi uma gambiara pra ele salvar o
                                         ; a posi��o do primeiro pixel plotado
                                         ; que � o q fica mais afastado do centro
                                         ; mas n�o deu muito certo... de qualquer
                                         ; modo tenho esperan�as que d� um dia
                                         ; a� eu deixei a� pra consertar depois =D
                                         
        mov     es, draw_address         ; vamos pintar no endere�o em draw_address
        xor     dx, dx                   ; limpando dx
DrawLPix:
        mov     dl, cl                   ; pra pode mover o conteudo de cl
        dec     dx                       ; sem que dh atrapalhe na hora de decrementar dx
        mov     temp_word, dx            ; movemos pra temp_word o valor em dx (raio)

        mov     temp_dword, -1           ; invertemos o �ngulo
        fld     degpi                    ; convertemos o �ngulo de graus pra radianos
        fimul   temp_dword               ; multiplicando-o por degpi (pi/180)
        fmul    angle
        fcos                             ; a� a gente tira o coseno do angulo
        fimul   temp_word                ; multiplicamos pelo raio
        fistp   putpixel_x               ; e temos a coordenada X \o/

        add     putpixel_x, ax           ; adicionamos a posi��o inicial

        mov     temp_dword, -1           ; e agora a mesma merda pra y
        fld     degpi
        fimul   temp_dword
        fmul    angle
        fsin                             ; exceto que nesse caso � o seno
        fimul   temp_word
        fistp   putpixel_y

        add     putpixel_y, bx

        call    PutPixel                 ; agora � s� plotar o pixel

        cmp     temp_byte, 1             ; a�, se tempbyte ainda for 1 ele salva
        jne     DontSavePoint            ; a posi��o
        push    putpixel_x
        push    putpixel_y
        mov     temp_byte, 0             ; n�o sei pq ainda nao t� do jeito q quero
DontSavePoint:
        dec     cl                       ; decremento cl (o raio)
        jnz     DrawLPix                 ; enquanto n�o for zero volta e pinta outro pixel
        pop     bx                       ; aqui restauramos as coordenadas que haviamos
        pop     ax                       ; salvo com a gambiarra do tempbyte
        pop     temp_dword               ; restauramos temp_dword
        pop     angle                    ; e o angulo
        
        ret                              ; fim
DrawLine                ENDP


;-------------------------------------------------------------
; DrawCircle: Desenha um c�rculo transparente na tela
;   * Par�metros:
;      - draw_x -> Coordenada x do centro
;      - draw_y -> Coordenada y do centro
;      - radius -> Raio
;      - draw_color -> Cor do c�rculo
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawCircle              PROC
        DCDiv   dw 2

        push    putpixel_x
        push    putpixel_y
        push    angle

        mov     angle, 720
DrawCPix:
        fld     degpi
        fimul   angle
        fidiv   dcdiv
        fcos
        fimul   radius
        fistp   putpixel_x

        mov     bx, draw_x
        add     putpixel_x, bx

        fld     degpi
        fimul   angle
        fidiv   dcdiv
        fsin
        fimul   radius
        fistp   putpixel_y

        mov     bx,     draw_y
        add     putpixel_y,     bx

        mov     ax,     ds
        mov     es,     ax
        call    PutPixel

        dec     angle
        jnz     DrawCPix

        pop     angle
        pop     putpixel_y
        pop     putpixel_x
        
        ret
DrawCircle              ENDP



;-------------------------------------------------------------
; DrawFillCircle: Desenha um c�rculo preenchido na tela
;   * Par�metros:
;      - ax -> Coordenada x do centro
;      - bx -> Coordenada y do centro
;      - cl -> Raio
;      - ch -> Cor do c�rculo
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawFillCircle          PROC
        mov     dx, 360
        mov     draw_address, gs
DrawCPix2:
        pushaw

        mov     temp_word, dx
        fild    temp_word
        fstp    angle

        call    DrawLine

        popaw

        dec     dx
        jnz     DrawCPix2

        ret
DrawFillCircle          ENDP

;-------------------------------------------------------------
; DrawHL: Desenha uma linha horizontal na tela
;   * Par�metros:
;      - draw_x -> Coordenada x
;      - draw_y -> Coordenada y
;      - x_length -> Largura da linha
;      - draw_color -> Cor da linha
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawHL                  PROC
        mov     ax, ds
        mov     es, ax
        cld
        mov     ax, draw_y
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, offset buffer
        add     di, draw_x
        mov     cx, x_length
        mov     al, draw_color
        rep     stosb
        ret
DrawHL                  ENDP



;-------------------------------------------------------------
; DrawVL: Desenha uma linha vertical na tela
;   * Par�metros:
;      - draw_x -> Coordenada x
;      - draw_y -> Coordenada y
;      - y_length -> Altura da linha
;      - draw_color -> Cor da linha
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawVL                  PROC
        mov     ax, ds
        mov     es, ax
        mov     cx, draw_x
        cmp     cx, 319
        ja      ClipVL

        mov     dx, y_length
DrawVLine:
        mov     ax, draw_y
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, offset buffer
        add     di, cx
        add     cx, 320
        mov     bx, di
        cmp     bx, 63999
        ja      ClipVL

        mov     al, draw_color
        mov     es:[di], al
        dec                     dx
        jnz     DrawVLine
ClipVL:
        ret
DrawVL                  ENDP


;-------------------------------------------------------------
; DrawBox: Pinta um ret�ngulo preenchido na tela
;   * Par�metros:
;      - draw_x -> Coordenada x
;      - draw_y -> Coordenada y
;      - x_length -> Largura do ret�ngulo
;      - y_length -> Altura do ret�ngulo
;      - draw_color -> Cor da janela
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawBox                 PROC
        mov     ax, draw_x
        add     ax, x_length
        cmp     ax, 320
        ja      Clip

        mov     ax, draw_y
        add     ax, y_length
        cmp     ax, 200
        ja      Clip

        mov     dx, draw_y
        add     dx, y_length
DrawHLine:
        cld
        mov     ax, dx
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, offset buffer
        add     di, draw_x
        mov     cx, x_length
        mov     al, draw_color
        rep     stosb
        dec     dx
        cmp     dx, draw_y
        ja      DrawHLine
Clip:
        ret
DrawBox                 ENDP



;-------------------------------------------------------------
; DrawWindow: Desenha uma janela formada de um ret�ngulo
;             transparente com uma �rea preenchida para o t�tulo
;   * Par�metros:
;      - draw_x -> Coordenada x
;      - draw_y -> Coordenada y
;      - x_length -> Largura da janela
;      - y_length -> Altura da janela
;      - draw_color -> Cor da janela
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawWindow              PROC
        push    y_length
        mov     y_length, 7
        mov     ax, ds
        mov     es, ax
        call    DrawBox

        pop     y_length
        call    DrawHL
        call    DrawVL

        push    draw_x
        mov     ax, x_length
        add     draw_x, ax
        call    DrawVL

        pop     draw_x
        inc     x_length
        mov     ax, y_length
        add     draw_y, ax
        call    DrawHL

        ret
DrawWindow              ENDP


;=============================================================
;Procedures principais do Jogo
;  - Rotinas espec�ficas do jogo como gera��o do terreno,
;    drawing dos players, c�lculos de colis�o e etc.
;=============================================================


;-------------------------------------------------------------
; DrawMap: Uma das maiores, gera todo o terreno atrav�s de
;          c�lculo matem�ticos guardando o resultado em GS
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - GS -> Terreno (Mapa) gerado, 64000 bytes
;-------------------------------------------------------------
DrawMap                 PROC
        call    Randomize

        cld
        mov     ax, gs
        mov     es, ax
        xor     edi, edi
        mov     di, offset Map

        mov     cx, 16000
        xor     eax, eax

        rep     stosd

        mov     p1_pos_done, 0
        mov     p2_pos_done, 0

        mov     putpixel_x, 1
        mov     ch, 0

CHLoop:
        mov     dh, 0
        pushaw
        mov     rand_range, 4
        call    Random
        mov     k1, dx
        inc     k1

        mov     rand_range, 3
        call    Random
        mov     k2, dx
        inc     k2
        popaw

DHLoop:
        pushaw
        cmp     putpixel_x, 8
        jb      OutOfPos
        cmp     ch, 0
        jne     SetPos2
        cmp     p1_pos_done, 1
        je      OutOfPos
        mov     rand_range, 100
        call    random
        cmp     dx, 5
        ja      OutOfPos
        mov     ax, putpixel_x
        mov     player1_x, ax
        mov     ax, putpixel_y
        mov     player1_y, ax
        mov     p1_pos_done, 1
        jmp     OutOfPos
SetPos2:
        cmp     ch, 4
        jne     OutOfPos
        cmp     p2_pos_done, 1
        je      OutOfPos
        mov     rand_range, 100
        call    random
        cmp     dx, 5
        ja      OutOfPos
        mov     ax, putpixel_x
        mov     player2_x, ax
        mov     ax, putpixel_y
        mov     player2_y, ax
        mov     p2_pos_done, 1
OutOfPos:
        inc     putpixel_x
        cmp     k1, 1
        jne     @MapFunction1

        fild    putpixel_x
        mov     temp_word, 10
        fidiv   temp_word
        fsin
        add     k2, 3
        fimul   k2
        sub     k2, 3
        mov     temp_word, 5
        fimul   temp_word
        fistp   putpixel_y
        jmp     @MapFunction4

@MapFunction1:
        cmp     k1, 2
        jne     @MapFunction2

        fild    putpixel_x
        mov     temp_word, 10
        fidiv   temp_word
        fcos
        fimul   k2
        mov     temp_word, 30
        fimul   temp_word
        fidiv   k1
        fistp   putpixel_y
        add     putpixel_y, 2
        jmp     @MapFunction4

@MapFunction2:
        cmp     k1, 3
        jne     @MapFunction3

        fild    putpixel_x
        mov     temp_word, 8
        fidiv   temp_word
        fcos
        fimul   k2
        fidiv   putpixel_y
        mov     temp_word, 10
        fimul   temp_word
        mov     ax, putpixel_y
        mov     temp_word, ax
        fistp   putpixel_y
        inc     putpixel_y
        jmp     @MapFunction4

@MapFunction3:
        cmp     k1, 4
        jne     @MapFunction4

        fild    putpixel_x
        mov     temp_word, 140
        fidiv   temp_word
        fcos
        add     k2, 4
        fimul   k2
        sub     k2, 4
        mov     temp_word, 10
        fimul   temp_word
        fistp   putpixel_y
        sub     putpixel_y,3

@MapFunction4:
        mov     ax, 200
        sub     ax, putpixel_y
        sub     ax, 50
        mov     putpixel_y, ax

        mov     draw_y, ax

        mov     y_length, 200
        sub     y_length, ax

        mov     ax, putpixel_x
        mov     draw_x, ax

        mov     ax, gs
        mov     es, ax
        mov     cx, draw_x
        cmp     cx, 319
        ja      CVL

        mov     dx, y_length
VL:
        mov     ax, draw_y
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, offset Map
        add     di, cx
        add     cx, 320
        mov     bx, di
        cmp     bx, 63999
        ja      CVL

        mov     draw_color, 29
        pushaw
        mov     rand_range, 6
        call    random
        add     draw_color, dl
        popaw

        mov     al, draw_color
        mov     gs:[di], al
        dec     dx
        jnz     VL
CVL:

        popaw
        cmp     ch, 0
        jne     OutOfPos3
        cmp     p1_pos_done, 1
        je      OutOfPos2
        mov     ax, putpixel_x
        mov     player1_x, ax
        mov     ax, putpixel_y
        mov     player1_y, ax
        jmp     OutOfPos2
OutOfPos3:
        cmp     ch, 4
        jne     OutOfPos2
        cmp     p2_pos_done, 1
        je      OutOfPos2
        mov     ax, putpixel_x
        mov     player2_x, ax
        mov     ax, putpixel_y
        mov     player2_y, ax
        cmp     putpixel_x, 314
        jb      OutOfPos2
        mov     p2_pos_done, 1
OutOfPos2:
        inc     dh
        cmp     dh, 64
        jne     DHLoop

        inc     ch
        cmp     ch, 5
        jne     CHLoop

        mov     x_length, 20
        mov     draw_y, 0
        mov     draw_color, 0
        mov     ax, gs
        mov     es, ax

        mov     ax, player1_x
        sub     ax, 10
        mov     draw_x, ax
        mov     ax, player1_y
        mov     y_length, ax
        call    DrawBox

        mov     ax, player2_x
        sub     ax, 10
        mov     draw_x, ax
        mov     ax, player2_y
        mov     y_length, ax
        call    DrawBox
        ret
DrawMap          ENDP



;-------------------------------------------------------------
; FlipMap: Pinta o mapa na tela baseando-se no buffer em GS:[0]
;   * Par�metros:
;      - nenhum
;   * Retorno:
;      - nenhum
;-------------------------------------------------------------
FlipMap       PROC
        push    putpixel_x
        push    putpixel_y

        mov     bx, 319
BXL:
        mov     dx, 199
DXL:
        mov     putpixel_x, bx
        mov     putpixel_y, dx
        
        mov     ax, dx
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, bx
        mov     ch, gs:[di]
        mov     cl, gs:[di-320]

        mov     ax, ds
        mov     es, ax
        
        cmp     ch, 0
        je      NoDrawMapPix

        cmp     cl, 0
        je      DrawBluePix

        cmp     dx, 199
        jae     NoBottomBluePix
        
        mov     cl, gs:[di+320]
        cmp     cl, 0
        je      DrawBluePix

NoBottomBluePix:
        call    PutPixel
        jmp     DrawMapPixDone
NoDrawMapPix:
        mov     ch, 35
        call    PutPixel
        jmp     DrawMapPixDone
DrawBluePix:
        mov     ch, 44
        call    PutPixel
DrawMapPixDone:
        dec     dx
        jnz     DXL

        dec     bx
        jnz     BXL
        
        pop     putpixel_y
        pop     putpixel_x
        
        ret
FlipMap         ENDP


;-------------------------------------------------------------
; FadeIn: Faz uma anima��o na palheta de cores de forma que a
;         tela vai aparecendo gradativamente
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
FadeIn                  PROC
        cld
        mov     ax, ds
        mov     es, ax
        mov     di, offset fade_buffer
        mov     cx, 45*3
        xor     al,al
        rep     stosb

FadeInLoop:
        call    WaitRetrace
        mov     cx, 45*3
        mov     si, offset fade_buffer
        mov     di, offset palette
        mov     dx, 0
IncPalette:
        mov     al, es:[si]
        cmp     al, es:[di]
        jae     JumpUpColor
        inc     al
        mov     es:[si], al
        mov     dx, 1
JumpUpColor:
        inc     si
        inc     di
        dec     cx
        cmp     cx, 0
        jne     IncPalette
        push    dx

        mov     si, offset fade_buffer
        mov     cx, 45*3
        mov     dx, 03C8h
        xor     al, al
        cli

        out     dx, al
        inc     dx
        cld
        rep     outsb
        sti

        pop     dx
        cmp     dx, 0
        jne     FadeInLoop

        ret
FadeIn                  ENDP


;-------------------------------------------------------------
; FadeOut: Faz uma anima��o na palheta de cores de forma que a
;         tela vai aparecendo gradativamente
;   * Par�metros:
;      - Nenhum
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
FadeOut                 PROC
        cld
        mov     ax, ds
        mov     es, ax
        xor     di, di
        xor     si, si
        mov     si, offset palette
        mov     di, offset fade_buffer
        mov     cx, 45*3
        rep     movsb

FadeOutLoop:
        call    WaitRetrace
        mov     cx, 45*3
        mov     si, offset fade_buffer
        mov     dx, 0
DecPalette:
        mov     al, es:[si]
        cmp     al, 0
        je      JumpSetColor
        dec     al
        mov     es:[si], al
        mov     dx, 1
JumpSetColor:
        inc     si
        dec     cx
        cmp     cx, 0
        jne     DecPalette
        push    dx

        mov     si, offset fade_buffer
        mov     cx, 45*3
        mov     dx, 03C8h
        xor     al, al
        cli

        out     dx, al
        inc     dx
        cld
        rep     outsb
        sti

        pop     dx
        cmp     dx, 0
        jne     FadeOutLoop

        ret
FadeOut   ENDP

;-------------------------------------------------------------
; DrawPlayer: Calcula a posi��o e exibe a bala do canh�o
;   * Par�metros:
;      - ax -> Coordenada X
;      - bx -> Coordenada Y
;      - angle -> Angulo do canh�o
;   * Retorno:
;      Nenhum
;-------------------------------------------------------------
DrawPlayer             PROC
        push temp_word
        mov     x_length, 8
        mov     y_length, 5

        mov     draw_color, 41
        mov     cl, flip
        add     draw_color, cl
        
        mov     draw_x, ax
        mov     draw_y, bx
        sub     draw_y, 3
        sub     draw_x, 8
        call    drawbox
        add     draw_x, 2
        sub     draw_y, 8
        cmp     flip, 0
        je      Player1
        add     draw_x, 3
Player1:

        mov     x_length, 10
        mov     y_length, 10

        cmp     flip, 1
        jne     DontFlipAngle
        mov     eax, 180
        sub     eax, angle
        mov     angle, eax
DontFlipAngle:
        mov     temp_word, 11
        fild    angle
        fidiv   temp_word
        fistp   temp_word
        fild    temp_word
        mov     temp_word, 100
        fimul   temp_word
        fistp   temp_word
        mov     ax, temp_word
        
        cmp     ax, 800
        jb      DontClipSprite
        mov     ax, 700
DontClipSprite:
        mov     si, offset shooter
        add     si, ax
        call    SpriteDraw
        pop    temp_word
        ret
DrawPlayer             ENDP


;-------------------------------------------------------------
; DrawGameScreen: Desenha os componentes da tela do jogo
;   * Par�metros:
;       Nenhum
;   * Retorno:
;       Nenhum
;-------------------------------------------------------------
DrawGameScreen   PROC
        push    putpixel_x
        push    putpixel_y
        push    draw_x
        push    draw_y
        push    angle

        call FlipMap

        mov     draw_x, 0
        mov     draw_y, 0
        mov     x_length, 319
        mov     y_length, 199
        mov     draw_color, 43
        call    DrawWindow

        mov     si, offset game_title
        mov     font_x, 110
        mov     font_y, 1
        mov     font_shadow, 0
        call    DrawText
        mov     si, offset game_version
        mov     font_x, 200
        mov     font_y, 193
        mov     font_shadow, 4
        call    DrawText
        mov     font_shadow, 255


        xor     eax, eax
        mov     ax, player1_angle
        mov     angle, eax
        mov     ax, player1_x
        mov     bx, player1_y
        mov     draw_color, 7
        mov     flip, 0
        call    DrawPlayer

        cmp     turn, 0
        jne     DontDrawP1Window
        mov     draw_x, 15
        mov     draw_y, 15
        mov     x_length, 60
        mov     y_length, 30
        mov     draw_color, 41
        call    drawwindow
        mov     font_x, 16
        mov     font_y, 16
        mov     font_shadow, 0
        mov     si, offset player1_str
        call    drawtext
        mov     font_x, 13
        mov     font_y, 25
        mov     si, offset angle_str
        call    drawtext
        mov     font_x, 13
        mov     font_y, 35
        mov     si, offset vel_str
        call    drawtext

        mov     string_mask, 100
        mov     font_x, 40
        mov     font_y, 25
        xor     eax, eax
        mov     ax, player1_angle
        call    IntToString
        
        mov     string_mask, 10
        mov     font_x, 40
        mov     font_y, 35
        mov     eax, player1_vel
        call    IntToString

DontDrawP1Window:
        xor     eax, eax
        mov     ax, player2_angle
        mov     angle, eax
        mov     ax, player2_x
        mov     bx, player2_y
        mov     draw_color, 7
        mov     flip, 1
        call    DrawPlayer
        
        cmp     turn, 1
        jne     DontDrawP2Window
        mov     draw_x, 240
        mov     draw_y, 15
        mov     x_length, 60
        mov     y_length, 30
        mov     draw_color, 42
        call    drawwindow

        mov     font_x, 241
        mov     font_y, 16
        mov     font_shadow, 0
        mov     si, offset player2_str
        call    drawtext
        mov     font_x, 240
        mov     font_y, 25
        mov     si, offset angle_str
        call    drawtext
        mov     font_x, 240
        mov     font_y, 35
        mov     si, offset vel_str
        call    drawtext

        mov     string_mask, 100
        mov     font_x, 270
        mov     font_y, 25
        xor     eax, eax
        mov     ax, player2_angle
        call    IntToString

        mov     string_mask, 10
        mov     font_x, 270
        mov     font_y, 35
        mov     eax, player2_vel
        call    IntToString
DontDrawP2Window:
        pop     angle
        pop     draw_y
        pop     draw_x
        pop     putpixel_y
        pop     putpixel_x
        ret
DrawGameScreen          ENDP




;-------------------------------------------------------------
; CalculatePosition: Calcula a posi��o e exibe a bala do canh�o
;   * Par�metros:
;      - eax -> Angulo em ponto flutuante
;      - ebx -> Velocidade em ponto flutuante
;      - ecx  -> Tempo em ponto flutuante
;   * Retorno:
;      - ax: x
;      - bx: y
;-------------------------------------------------------------
CalculatePosition       PROC
        fld     degpi
        mov     temp_dword, eax
        fmul    temp_dword
        fsin
        mov     temp_dword, ebx
        fmul    temp_dword
        mov     temp_dword, ecx
        fmul    temp_dword
        fstp    temp_dword
        push    temp_dword

        mov     temp_dword, ecx
        fld     temp_dword
        fmul    temp_dword
        fmul    gravity
        fidiv   divtwo
        pop     temp_dword
        fadd    temp_dword

        fistp   temp_word
        push    temp_word
        
        fld     degpi
        mov     temp_dword, eax
        fmul    temp_dword
        fcos
        mov     temp_dword, ebx
        fmul    temp_dword
        mov     temp_dword, ecx
        fmul    temp_dword
        fistp   temp_word
        
        mov     ax, temp_word
        pop     bx
        
        ret
CalculatePosition       ENDP



;-------------------------------------------------------------
; DrawShoot: Calcula a posi��o e exibe a bala do canh�o
;   * Par�metros:
;      - draw_x -> Coordenada X inicial
;      - draw_y -> Coordenada Y inicial
;      - angle  -> �ngulo
;      - velocity -> Velocidade
;   * Retorno:
;      - Nenhum
;-------------------------------------------------------------
DrawShoot               PROC
        pushaw
        
        mov     temp_dword, 0
        fild    temp_dword
        fstp    time

        mov     font_color, 17
        mov     font_italic, 0
        mov     font_shadow, 22
DrawParticle:
        mov     ax, ds
        mov     es, ax
        
        mov     eax, angle
        mov     ebx, velocity
        mov     ecx, time
        
        call    CalculatePosition
        mov     cx, bx
        shl     cx, 5
        
        mov     cx, 200
        sub     cx, bx
        sub     cx, putpixel_y
        mov     draw_y, cx

        add     ax, putpixel_x
        mov     draw_x, ax


        fld     time
        fadd    time_inc
        fstp    time
        
        cmp     draw_y, 199
        ja      EndNoColision

        mov     ax, ds
        mov     es, ax


        call    WaitRetrace
        call    DrawGameScreen

        mov     ch, 7

        sub     draw_y, 8
        mov     x_length, 8
        mov     y_length, 8
        mov     si, offset canon_ball
        call    SpriteDraw

        call    FlipBuffer

        cmp     draw_y, 3
        jb      DrawParticle
        cmp     draw_x, 3
        jb      DrawParticle
        cmp     draw_x, 316
        ja      DrawParticle
        cmp     draw_y, 199
        ja      DrawParticle

        mov     ax, draw_y
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, draw_x
        mov     al, gs:[di]
        cmp     di, 63999-965
        ja      DontMakeThisTest
        add     al, gs:[di+958]
        add     al, gs:[di+963]
        add     al, gs:[di+965]
DontMakeThisTest:
        add     al, gs:[di+3]
        add     al, gs:[di-3]
        cmp     al, 0
        je      DrawParticle

        mov     ax, draw_x
        mov     bx, draw_y
        mov     ch, 0
        mov     cl, 15
        call    DrawFillCircle
        mov     time, 0
        mov     ax, draw_x
        mov     bx, draw_y
        call    MakeExplosion

EndNoColision:
        popaw
        ret
DrawShoot               ENDP

;-------------------------------------------------------------
; MakeExplosion: Cria aquele efeitozinho de terra subindo
;   * Par�metros:
;      - nenhum
;   * Retorno:
;      - nenhum
;-------------------------------------------------------------
MakeExplosion           PROC
        mov     temp_dword, 0
        fild    temp_dword
        fstp    time
        
        mov     particles_x, ax
        mov     particles_y, 200
        sub     particles_y, bx

        xor     bx, bx
InitParticle:
        mov     rand_range, 170
        call    Random
        add     dx, 5
        mov     particles_angle[bx], dx
        mov     dx, bx
        shr     bx, 1
        mov     particles_on[bx], 1
        mov     bx, dx

        mov     rand_range, 18
        call    Random
        add     dx, 3
        
        mov     particles_vel[bx], dx

        add     bx, 2
        cmp     bx, PARTICLE_COUNT*2
        jb      InitParticle

        mov     ax, ds
        mov     es, ax
Explode:
        call    WaitRetrace
        call    DrawGameScreen
        xor     bx, bx
        mov     temp_byte, 0
        
NextExplodeIter:
        push    bx

        shr     bx, 1
        mov     al, particles_on[bx]
        shl     bx, 1
        cmp     al, 0
        je      ParticleStayTheSame

        mov     temp_byte, 1

        fild    particles_angle[bx]
        fstp    temp_dword
        mov     eax, temp_dword
        
        fild    particles_vel[bx]
        fstp    temp_dword
        mov     ebx, temp_dword
        
        mov     ecx, time

        call    CalculatePosition

        mov     putpixel_x, ax
        mov     putpixel_y, 200
        sub     putpixel_y, bx
        
        mov     ax, particles_x
        add     putpixel_x, ax
        mov     ax, particles_y
        sub     putpixel_y, ax
        
        cmp     putpixel_y, 200
        jb      DrawParticleToField
        pop     bx
        shr     bx, 1
        mov     particles_on[bx], 0
        shl     bx, 1
        push    bx
        jmp     ParticleStayTheSame

DrawParticleToField:
        mov     rand_range, 6
        call    Random
        mov     ch, 29
        add     ch, dl
        
        call    PutPixel
        
        mov     ax, putpixel_y
        shl     ax, 6
        mov     di, ax
        shl     ax, 2
        add     di, ax
        add     di, putpixel_x
        mov     al, gs:[di]
        
        cmp     al, 0
        je     ParticleStayTheSame

        mov     gs:[di-320], ch
        pop     bx
        shr     bx, 1
        mov     particles_on[bx], 0
        shl     bx, 1
        push    bx

ParticleStayTheSame:
        pop     bx
        add     bx, 2
        cmp     bx, PARTICLE_COUNT*2
        jb      NextExplodeIter

NextParticleFrame:
        call    FlipBuffer
        fld     time
        fadd    time_inc
        fstp    time
        
        cmp     temp_byte, 0
        jne     Explode

        ret
MakeExplosion           ENDP

;-------------------------------------------------------------
; GameLoop: Onde as boas coisas acontecem =)
;   * Par�metros:
;      - nenhum
;   * Retorno:
;      - nenhum
;-------------------------------------------------------------
GameLoop                PROC
        call    FadeOut                 ; Escurecemos tudo
        mov     draw_x, 15              ; e por debaixo dos panos
        mov     draw_y, 30              ; vamos pintando a janela de instrucoes
        mov     x_length, 320-30
        mov     y_length, 200-60
        mov     draw_color, 41
        call    DrawWindow              ; TA DA

        mov     font_x, 120             ; pintamos tamb�m o texto
        mov     font_y, 32
        mov     si, offset instruct_str ; o t�tulo da janela
        call    DrawText
        
        mov     font_x, 18
        mov     font_y, 40
        mov     si, offset info_str      ; as informa��es
        call    DrawText
        
        call    FlipBuffer               ; mandamos tudo pra tela
        call    FadeIn                   ; E clareamos as coisas
Intro:
        mov     ah, 01h                  ; agora com a subfun��o 01h ficamos
        int     16h                      ; esperando o cara digitar alguma coisa
        jz      Intro                    ; se ele nao digitar volta pra Intro

        mov     ah, 00h                  ; pegamos o que ele digitou
        int     16h

        call    FadeOut                  ; escurecemos tudo

        call    DrawGameScreen           ; pintamos a tela do jogo
        call    FlipBuffer               ; mandamos pro video
        call    FadeIn                   ; clareamos tudo
        
MainLoop:                                ; e aqui come�a a partida
        call    WaitRetrace              ; esperamos a atualiza��o do monitor
        call    DrawGameScreen           ; pintamos a tela do jogo
        call    FlipBuffer               ; mandamos pro v�deo

        mov     ah, 01h                  ; testamos se ele digitou algo
        int     16h                      ; int 16h subfun��o 01h
        jz      MainLoop                 ; se n�o digitou voltamos pro come�o

        mov     ah, 00h                  ; se digitou ent�o pegamos o q foi
        int     16h

        cmp     Ah, 72                   ; testamos se ele colocou seta pra cima
        jne     TestDown                 ; sen�o vamos testar a seta pra baixo

        cmp     turn, 1                  ; se sim ent�o vemos de quem � a vez
                                         ; 0 = player1    1 = player2
        je      tu_player2               ; se for igual a 1 entao vamos mexer com
                                         ; o player 2
                                         
        cmp     player1_vel, 60          ; sen�o vemos se a velocidade do player1
                                         ; j� alcan�ou um m�ximo
        jae     TestEnd                  ; se j� ent�o finalizamos
        add     player1_vel, 1           ; sen�o incrementamos a velocidade
        jmp     TestEnd                  ; e finalizamos
tu_player2:
        cmp     player2_vel, 60          ; no player 2 � a mesma coisa
        jae     TestEnd
        add     player2_vel, 1           ; s� que com o player 2 =D

        jmp     TestEnd                  ; finalizandooo

TestDown:
        cmp     ah, 80                   ; aqui testamos se ele apertou a seta
                                         ; pra baixo
        jne     TestLeft                 ; sen�o vamos testar a seta a esquerda

        cmp     turn, 1                  ; se sim vemos de quem foi a vez
        je      td_player2
        cmp     player1_vel, 20          ; testamos se ja ta na vel minima
        jbe     TestEnd
        sub     player1_vel, 1           ; senao decrementamos
        jmp     TestEnd
td_player2:
        cmp     player2_vel, 20          ; mesma merda pro player 2
        jbe     TestEnd
        sub     player2_vel, 1

        jmp     TestEnd                  ; finalizando

TestLeft:
        cmp     ah, 75                   ; seta a esquerda?
        jne     TestRight                ; se n�o entao vamos testar
                                         ; a seta a direita

        cmp     turn, 1                  ; se sim ent�o...
        je      tl_player2
        cmp     player1_angle, 90        ; testamos se ja ta no angulo maximo
        jae     TestEnd
        add     player1_angle, 1         ; incrementamos o angulo
        jmp     TestEnd
tl_player2:
        cmp     player2_angle, 180       ; mesma coisa pro player 2
        jae     TestEnd
        add     player2_angle, 1         ; incrementanso

        jmp     TestEnd

TestRight:
        cmp     ah, 77                   ; seta a direita?
        jne     TestReturn               ; sen�o vamos testar ENTER

        cmp     turn, 1                  ; player 1 ou 2?
        je      tr_player2
        cmp     player1_angle, 0         ; se o angulo n�o j� for m�nimo ent�o
        jbe     TestEnd
        sub     player1_angle, 1         ; decrementamos
        jmp     TestEnd
tr_player2:
        cmp     player2_angle, 90        ; player 2 mesma coisa, angulo minimo?
        jbe     TestEnd
        sub     player2_angle, 1         ; nao entao decrementamos
        jmp     TestEnd                  ; finalizando

TestReturn:
        cmp     al, 13                   ; Enter atira, vc apertou enter?
        jne     TestEnd                  ; nao entao finalizamos os testes
        
        cmp     turn, 1                  ; se apertou ent�o vejamo de quem � a vez
        
        je tret_player2                  ; Oh � do player 2, vamos nessa
        
        mov     ax, player1_x            ; se chegou aqui ent�o � do player 1
        mov     putpixel_x, ax           ; mandamos pra putpixel_x a coordenada x
        mov     bx, 200
        sub     bx, player1_y
        mov     putpixel_y, bx           ; pra putpixel_y a coordenada y
        xor     eax, eax
        mov     ax, player1_angle        ; pra eax o angulo
        mov     turn, 1                  ; mudamos pra vez do player 2
        jmp     GoShoot                  ; e vamos atirar
tret_player2:
        mov     ax, player2_x            ; se chegou aqui � a vez do player 1
        mov     putpixel_x, ax           ; putpixel_x = coordenada x
        mov     bx, 200
        sub     bx, player2_y
        mov     putpixel_y, bx           ; putpixel_y = coordenada y
        xor     eax, eax
        mov     ax, player2_angle        ; eax = angulo
        mov     turn, 0                  ; setamos q a proxima vez � a do player1
GoShoot:
        mov     angle, eax               ; aqui movemos pra angle o valor em eax
        fild    angle                    ; transformamos em float
        fstp    angle                    ; mandamos pra angulo de novo
        cmp     turn, 1                  ; testamos de quem � a vez dinovo
        jne     P2Shoot                  ; se for do 2 entao o player2 atira
        mov     eax, player1_vel         ; senao mandamos a velocidade do player1
        jmp     CallShoot                ; e atiramos finalmente
P2Shoot:
        mov     eax, player2_vel         ; sen�o � a velocidade do player2
CallShoot:
        mov     velocity, eax            ; aqui convertemos o valor de inteiro
        fild    velocity                 ; pra float
        fstp    velocity
        call    DrawShoot                ;e atiramos
        jmp     TestEnd                  ;finalizando testes

TestEnd:
        mov     bl, ah                   ; aqui a gente finaliza os testes
        mov     ah, 0Ch                  ; testando se o cara digitou ESC
        mov     al, 02h
        int     21h
        cmp     bl, 01
        jne     MainLoop                 ; se n�o digitou ent�o voltamos pro
                                         ; loop principal

        ret                              ; se digitou ent�o vamos embora =D
GameLoop                ENDP

End Start
; Fim do c�digo...
