; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XFillArc
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit
extern scanf
extern rand
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1


xCoordinates resd 50  ; Réserve de l'espace pour un pointeur
yCoordinates resd 50  ; Réserve de l'espace pour un pointeur

section .data

event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

fmt_print: db "Valeur : %d",10,0
fmt_scanf_int: db "%d",0
nbPoint equ 50
random_min equ 50  ; constante borne min pour les coordonnées des points
random_max equ 350  ; constante borne max pour les coordonnées des points

section .text

global generateRandomNumber
generateRandomNumber:
    call rand             ; Appelle rand pour obtenir un nombre aléatoire dans eax
    mov rdi, random_max
    sub rdi, random_min
    inc rdi               ; rdi = (random_max - random_min) + 1
    xor rdx, rdx          ; Nettoie rdx avant la division
    div rdi               ; eax / rdi, quotient dans eax, reste dans edx
    add edx, random_min   ; Ajoute random_min au reste pour obtenir un nombre dans la plage [random_min, random_max]
    
    mov rax, rdx          ; Déplace le résultat final dans rax pour le retour
    ret

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:

push rbp

tableauCoordonnees:
; Initialisation de l'index pour la boucle
xor ebx, ebx             ; rcx sera notre compteur/index

fill_Coordinates:
    cmp ebx, nbPoint  ; Vérifie si on a rempli 50 éléments
    jge createWindow

    ; Génération d'une valeur aléatoire dans eax
    call generateRandomNumber
    ; Stocke la valeur générée dans le tableau
    mov [xCoordinates + ebx*DWORD], eax
    
    
    call generateRandomNumber
    ; Stocke la valeur générée dans le tableau Y
    mov [yCoordinates + ebx*DWORD], eax
    
    inc ebx  ; Incrémente l'index pour le prochain élément
    jmp fill_Coordinates
    
createWindow:
        
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:
xor ebx, ebx ;compteur de points

drawPoint:

cmp ebx, nbPoint
jge end_draw

;couleur du point 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000FFF	; Couleur du crayon ; bleu
call XSetForeground

; Dessin d'un point sous forme d'un petit rond : coordonnées
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov rcx,[xCoordinates + ebx*DWORD]		; coordonnée en x du point
sub ecx,3
mov r8,[yCoordinates + ebx*DWORD] 		; coordonnée en y du point
sub r8,3
mov r9,6
mov rax,23040
push rax
push 0
push r9
call XFillArc

inc ebx
jmp drawPoint
end_draw:

;couleur de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000000	; Couleur du crayon ; noir
call XSetForeground
; coordonnées de la ligne 1 (noire)
mov dword[x1],50
mov dword[y1],50
mov dword[x2],200
mov dword[y2],350
; dessin de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine


; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit