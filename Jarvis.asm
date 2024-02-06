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
point_L: resd 1
point_P: resd 1
point_Q: resd 1
point_I: resd 1
enveloppeIndices resd 50 ; Tableau pour stocker jusqu'à 50 indices de points de l'enveloppe
indexEnveloppe: resd 1

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
nbPointsEnveloppe: dd 0

section .text

global generateRandomNumber
generateRandomNumber:
    rdrand eax          ; Appelle rand pour obtenir un nombre aléatoire dans eax
    jnc generateRandomNumber
    mov rdi, random_max
    sub rdi, random_min
    inc rdi               ; rdi = (random_max - random_min) + 1
    xor rdx, rdx          ; Nettoie rdx avant la division
    div rdi               ; eax / rdi, quotient dans eax, reste dans edx
    add edx, random_min   ; Ajoute random_min au reste pour obtenir un nombre dans la plage [random_min, random_max]
    
    mov rax, rdx          ; Déplace le résultat final dans rax pour le retour
    ret
    
global minInTab
minInTab:
    ;edi xCoordinates
    xor ebx, ebx
    mov ecx, edi
    mov eax, edx ; Initialise eax au premier indice du tableau [0]
    mov edx, [ecx]
    
    boucleTableau:
        cmp ebx, nbPoint
        jge fin_boucleTableau
        cmp edx, [ecx + ebx*DWORD]
        jle suite_boucle
        mov eax, ebx
        mov edx, [ecx + ebx*DWORD]
        suite_boucle:
        inc ebx
        jmp boucleTableau
    fin_boucleTableau:
    ret

global calculeProduitVectoriel
calculeProduitVectoriel:

    ; Calculer les coordonnées des vecteurs PI et IQ
    ; Vecteur PI: (xI - xP, yI - yP)
    mov edx, r8d           ; Charger point_I dans rdx pour le calcul
    mov ecx, edx           ; Copier point_P dans ecx pour le calcul

    ; xI - xP
    mov edx, [edi + edx*DWORD] ; xI
    sub edx, [edi + ecx*DWORD] ; xP
    ; Stocker le résultat de xI - xP dans r10 pour une utilisation ultérieure
    mov r10d, edx

    ; yI - yP
    mov edx, [esi + r8d*DWORD] ; yI
    sub edx, [esi + ecx*DWORD] ; yP
    ; Stocker le résultat de yI - yP dans r11 pour une utilisation ultérieure
    mov r11d, edx

    ; Vecteur IQ: (xQ - xI, yQ - yI)
    ; xQ - xI
    mov edx, [edi + ecx*DWORD] ; xQ
    sub edx, [edi + r8d*DWORD] ; xI

    ; yQ - yI
    mov ecx, [esi + ecx*DWORD] ; yQ
    sub ecx, [esi + r8d*DWORD] ; yI

    ; Calculer le produit vectoriel (xI - xP) * (yQ - yI) - (yI - yP) * (xQ - xI)
    imul edx, ecx          ; (xQ - xI) * (yQ - yI)
    imul r10d, r11d        ; (xI - xP) * (yI - yP)
    sub edx, r10d          ; Soustraire les produits pour obtenir le produit vectoriel

    ; Déplacer le résultat dans eax pour le retour
    mov eax, edx

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
    jge selectPIQ

    ; Génération d'une valeur aléatoire dans eax
    call generateRandomNumber
    ; Stocke la valeur générée dans le tableau
    mov [xCoordinates + ebx*DWORD], eax
    
    
    call generateRandomNumber
    ; Stocke la valeur générée dans le tableau Y
    mov [yCoordinates + ebx*DWORD], eax
    
    inc ebx  ; Incrémente l'index pour le prochain élément
    jmp fill_Coordinates

selectPIQ:
    ; Préparation des paramètres pour minInTab
    mov rdi, xCoordinates
    mov rsi, yCoordinates
    call minInTab
    mov [point_L], eax    ; Indice du point le plus à gauche
    mov [point_P], eax    ; Initialiser P avec L
    mov dword [enveloppeIndices], eax ; Ajouter L à enveloppeIndices
    mov r9d, 1            ; Initialiser l'index pour enveloppeIndices

    ; Initialiser point_Q à un autre point que L pour démarrer la boucle
    mov eax, [point_L]
    add eax, 1
    mov [point_Q], eax

boucle_enveloppe:
    mov eax, [point_P]    ; Charger point_P dans eax pour l'utiliser dans la boucle
    cmp eax, [point_L]    ; Vérifier si on est revenu au point de départ
    je fin_enveloppe      ; Si oui, on a terminé l'enveloppe

    mov r9d, eax          ; Utiliser r9d pour stocker le point actuel de l'enveloppe
    mov ecx, 0            ; Réinitialiser point_I pour chaque nouvelle itération de point_P

boucle_point_I:
    cmp ecx, [nbPoint]    ; Vérifier si tous les points ont été examinés
    je ajoute_enveloppe   ; Si oui, ajouter point_P à enveloppeIndices et passer au suivant

    ; Préparation des paramètres pour calculeProduitVectoriel
    mov edx, [point_P]
    mov r8d, ecx          ; Utiliser ecx comme point_I
    call calculeProduitVectoriel

    ; Vérifier si le produit vectoriel est positif ou nul
    test eax, eax
    jge point_Trouve      ; Si oui, on a trouvé un meilleur candidat

    inc ecx               ; Passer au point suivant
    jmp boucle_point_I

point_Trouve:
    mov [point_P], ecx    ; Mettre à jour point_P avec point_I trouvé
    jmp ajoute_enveloppe  ; Sortir de la boucle_point_I et ajouter point_P à l'enveloppe

ajoute_enveloppe:
    mov eax, [point_P]    ; Charger le point actuel de l'enveloppe
    mov [enveloppeIndices + r9d*DWORD], eax ; Ajouter point_P à enveloppeIndices
    inc r9d               ; Incrémenter l'index pour enveloppeIndices
    jmp boucle_enveloppe

fin_enveloppe:
    ; Mise à jour du nombre de points dans l'enveloppe convexe
    mov [nbPointsEnveloppe], r9d

    jmp createWindow


    
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
jge end_drawPoint

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
end_drawPoint:

;couleur de la ligne 1
;mov rdi,qword[display_name]
;mov rsi,qword[gc]
;mov edx,0x000000	; Couleur du crayon ; noir
;call XSetForeground

;mov rdi,qword[display_name]
;mov rsi,qword[window]
;mov rdx,qword[gc]
; coordonnées de la ligne 1 (noire)
;mov ecx, [xCoordinates + 0*DWORD]
;mov r8d, [yCoordinates + 0*DWORD]
;mov r9d, [xCoordinates + 1*DWORD]
;push qword[yCoordinates + 1*DWORD]
;call XDrawLine





;couleur de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000000	; Couleur du crayon ; noir
call XSetForeground


xor ebx, ebx                  ; ebx sert de compteur pour les indices dans le tableau enveloppeIndices

drawLine:
cmp ebx, [nbPointsEnveloppe]
jge end_drawLine



; coordonnées de la ligne 1 (noire)
mov eax, [enveloppeIndices + ebx*DWORD]
mov r10d, [xCoordinates + eax*DWORD]
mov dword[x1],r10d
mov r10d, [yCoordinates + eax*DWORD]
mov dword[y1],r10d
inc eax
mov r10d, [xCoordinates + edx*DWORD]
mov dword[x2],r10d
mov r10d, [yCoordinates + eax*DWORD]
mov dword[y2],r10d
; dessin de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine

inc ebx
jmp drawLine

end_drawLine:


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
