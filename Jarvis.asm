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
extern malloc
extern free
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

nbPoint:        resd 1
xCoordinates: resd 50  ; Tableau pour les coordonnées x
yCoordinates: resd 50  ; Tableau pour les coordonnées y

section .data

event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

question:   db "entrez un nombre : ",0
fmt_print: db "Valeur : %d",10,0
fmt_scanf_int: db "%d",0
message_error_big: db "Error, too big",10,0
message_error_small: db "Error, too small",10,0
random_min equ 100  ; constante borne min pour les coordonnées des points
random_max equ 300  ; constante borne max pour les coordonnées des points

section .text


global createDynamicArray
createDynamicArray:
    ; Paramètre : rdi = nombre d'éléments
    ; Retour : rax = adresse du tableau alloué
    mov rdx, rdi
    imul rdi, 4  ; Chaque élément est un entier (4 octets)
    push rdi
    call malloc
    add rsp, 8
    ret

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
boucle_select_nb_point:
    mov rdi, question
    mov rax, 0
    call printf
    mov rdi, fmt_scanf_int
    mov rsi, nbPoint
    mov rax, 0
    call scanf

    cmp dword [nbPoint], 10
    jb error_small
    cmp dword [nbPoint], 50
    ja error_big
    jmp tableauCoordonnees

error_small:
    mov rdi, message_error_small
    mov rax, 0
    call printf
    jmp boucle_select_nb_point

error_big:
    mov rdi, message_error_big
    mov rax, 0
    call printf
    jmp boucle_select_nb_point

    
tableauCoordonnees:
    ; Appel de createDynamicArray pour allouer le tableau xCoordinates
    mov rdi, [nbPoint]
    call createDynamicArray
    ; Stockage de l'adresse du tableau dans xCoordinates
    mov qword [xCoordinates], rax

    ; Appel de createDynamicArray pour allouer le tableau yCoordinates
    mov rdi, [nbPoint]
    call createDynamicArray
    ; Stockage de l'adresse du tableau dans yCoordinates
    mov qword [yCoordinates], rax
    
;############################ Début du remplissage du tableau xCoordinates

; Initialisation de l'index pour la boucle
xor rcx, rcx             ; rcx sera notre compteur/index

fill_xCoordinates:
    cmp rcx, [nbPoint]      ; Compare l'index avec nbPoint
    jge end_fill_x          ; Si rcx >= nbPoint, la boucle est terminée

    ; Génération d'un nombre aléatoire pour xCoordinates
    call generateRandomNumber
    
    mov rdi, fmt_print
    mov rsi, 123456789   ; Valeur de test
    xor rax, rax
    call printf
    
    mov rdi, [xCoordinates] ; Récupère le pointeur vers xCoordinates
    mov [rdi + rcx*4], eax  ; Stocke la valeur aléatoire à la position actuelle

    inc rcx                 ; Incrémente l'index
    jmp fill_xCoordinates   ; Boucle

end_fill_x:

xor rcx, rcx             ; Réinitialise l'index pour la boucle

fill_yCoordinates:
    cmp rcx, [nbPoint]      ; Compare l'index avec nbPoint
    jge end_fill_y          ; Si rcx >= nbPoint, la boucle est terminée

    ; Génération d'un nombre aléatoire pour yCoordinates
    call generateRandomNumber
    mov rdi, [yCoordinates] ; Récupère le pointeur vers yCoordinates
    mov [rdi + rcx*4], eax  ; Stocke la valeur aléatoire à la position actuelle

    inc rcx                 ; Incrémente l'index
    jmp fill_yCoordinates   ; Boucle

end_fill_y:
    
    

        
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

;couleur du point 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF0000	; Couleur du crayon ; rouge
call XSetForeground

; Dessin d'un point rouge sous forme d'un petit rond : coordonnées (100,200)
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov rcx,100		; coordonnée en x du point
sub ecx,3
mov r8,200 		; coordonnée en y du point
sub r8,3
mov r9,6
mov rax,23040
push rax
push 0
push r9
call XFillArc

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
    
    mov rdi, qword [xCoordinates]
    call free
    mov rdi, qword [yCoordinates]
    call free
    
    xor	    rdi,rdi
    call    exit