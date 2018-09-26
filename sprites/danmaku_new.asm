;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Danmaku Boss (Cleanup/Test)
;	Original WIP by Kipernal
;	Heavily modified by TheGreekBrit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!hitBoxOAM	        = $0200			; The OAM address for Mario's hitbox. This really shouldn't be changed.

!state		        = $1dfd			;\  The current state of the boss
                                    ; | 0 = idle
                                    ; | 1 = display spell card
                                    ; | 2 = fire bullets
                                    ; | 3 = Mario has been hit
                                    ;/  4 = boss is dead

!stateTimer	        = $60			; Boss state timer. Controlling how long to:
                                    ; idle
                                    ; display a spell card
                                    ; remain in the 'Mario Is Dead' state

!timeHasRunOut	    = $61			; This flag is set whenever the timer loops from 0 to FFFF
                                    ; It is your responsibility to reset it at the end of a spellcard

!currentCard	    = $62			; Boss attack number
                                    ; Determines which order bullet patterns are used

!timer		        = $63			; How much time has passed (two bytes)

!bossYOffset	    = $0dd9         ; Used for a floaty effect with the boss
!numOfBullets	    = $140b         ; Number of bullets in existence
!shotBullets	    = $140c         ; Misc counter
!bulletLocation	    = $1763         ; A two byte variable used for hit detection

!angle1 	        = $0f5e			;\
!angle2 	        = $0f60			; | These are used for some of the spellcards
!angle3 	        = $0f62			; | (they have no global effect)
!angle4 	        = $0f64			;/

; BULLET TABLES
; each entry is indexed by the bullet number
!bulletXSpeed	    = $7f0d00		; Horizontal speed of the bullets
!bulletYSpeed	    = $7f0e00		; Vertical speed of the bullets
!bulletXPos	        = $7f0f00       ; Bullet offset from the left side of the screen
!bulletYPos	        = $7f1000       ; Bullet offset from the top of the screen
!bulletXAccel	    = $7f1300       ; X acceleration of a bullet
!bulletYAccel	    = $7f1400       ; Y acceleration of a bullet
!bulletXFrac	    = $7f1500       ; X subpixel of a bullet
!bulletYFrac	    = $7f1600       ; X subpixel of a bullet
!bulletType	        = $7f1100       ; Bullet color. 0 = bullet doesn't exist
!bulletInfo	        = $7f1200       ; Any extra information about the bullet


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT AND MAIN JSL targets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	print "INIT ",pc                ;
	JSR INIT                        ;\ run INIT routine
	RTL                             ;/

	print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR MAIN
	STZ $0313		                ; Fixes a bug with Mario's YXPPCCCT OAM slots
	STZ $0317		                ; Fixes a bug with Mario's YXPPCCCT OAM slots
	;STZ $0d9c
	PLB
	RTL


KYoffset:
        db $0c,$0c,$0c,$0c,$0c,$0c,$0b,$0b,$0b,$0b,$0a,$0a,$0a,$09,$09,$09
		db $08,$08,$08,$07,$07,$07,$06,$06,$06,$05,$05,$04,$04,$03,$03,$03
		db $02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$05
		db $05,$06,$06,$06,$07,$07,$07,$08,$08,$08,$09,$09,$09,$0a,$0a,$0a
		db $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c,$0c,$0c

; Xoffsets:	db $1a,$14,$24,$00,$10,$20,$30,$00,$10,$20,$30,$40,$00,$10,$20,$30
Xoffsets:
        db $00,$10,$20,$30,$00,$10,$20,$30,$00,$10,$20,$30,$00,$10,$20,$30

; Yoffsets:	db $00,$10,$10,$20,$20,$20,$20,$30,$30,$30,$30,$30,$40,$40,$40,$40
Yoffsets:
        db $00,$00,$00,$00,$10,$10,$10,$10,$20,$20,$20,$20,$30,$30,$30,$30

;Tiles:		db $00,$20,$22,$40,$42,$44,$46,$60,$62,$64,$66,$68,$02,$04,$06,$08
Tiles:
        db $00,$02,$04,$06
		db $20,$22,$24,$26
		db $40,$42,$44,$46
		db $60,$62,$64,$66

BXoffsets:
        db $00,$08,$10,$18,$20,$28,$30,$38,$40,$48,$50,$58,$60,$68,$70,$78,$80

BYoffsets:
        db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10

BTiles:
        db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
		db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
		db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
		db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
		db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;INITIALIZE
; clear state
; set idle timer
; set global timer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT:
	STZ !state			            ; state 0 (doesn't exist)
	STZ !currentCard	            ; Card 0 (INIT, does nothing)
	LDA #$80			            ;
	STA !stateTimer			        ; Countdown before the boss starts shooting
	PHX				                ;
	REP #$10			            ;
	LDX #$00f0			            ;
	STX !timer			            ;
	STZ $0D9C                       ;

; 	LDX #$ffff			            ;
; InitLoopPoint:			        ;
; 	INX				                ;
; 	LDA #$00			            ;
; 	STA !bulletXSpeed,x		        ;
; 	CPX.w #$1500			        ;
; 	BNE InitLoopPoint		        ;
; 	SEP #$10			            ;
; 	PLX				                ;

.spritetableclear
	SEP #$10			            ;\
	REP #$20 			            ; |
	STZ $211B 			            ; |
	LDA #$3480			            ; |
	STA $4300			            ; |
	LDA #$0D00 			            ; |
	STA $4302			            ; |
	LDX #$7F 			            ; | nuke $7F0D00 - $7F21FF (all sprite info)
	STX $4304			            ; |
	LDA #$1500			            ; |
	STA $4305			            ; |
	LDX #$01			            ; |
	STX $420B			            ; |
	SEP #$20 			            ; |
	PLX 				            ;/


	REP #$20
	;LDA #$00FF
	;STA $60
	;LDA #$00FF
	;STA $62

	LDA #$0000
	STA $64

	SEP #$20
	RTS


MAIN:
	DEC !stateTimer			        ;\
	LDA !stateTimer			        ; | kick off main thread if state timer is still counting
	BNE stateTimerIsnt0		        ;/
	LDA #$02			            ;\
	STA !state			            ;/ begin firing bullets

stateTimerIsnt0:
	LDA !state          			;\
	CMP #$03			            ; | If Mario is dying...
	BEQ MarioHasDiedMovement	    ;/ ...don't animate his death
	JSR MariosMovementRoutine      	; Handle Mario movements
	BRA SkipMarioHasDiedMovement	;

MarioHasDiedMovement:
	REP #$20                        ;
	DEC $96				            ; Keep his y-position constant, as to immobilize him
	SEP #$20                        ;
	DEC !stateTimer		        	;

SkipMarioHasDiedMovement:
	INC !bossYOffset	        	;\
	LDA !bossYOffset	        	; |
	CMP #$5a			            ; |
	BNE DontResetBossFloatHeight	; | FLOATY BOSS
	STZ !bossYOffset	        	; |
					                ; |
DontResetBossFloatHeight:	    	; |
	PHX				                ;/


	LDA !state			            ; If it's time to shoot bullets...
	CMP #$02                        ;
	BEQ RunSpellCards 	        	; ...shoot bullets
	BRL dontRunSpellCards		    ;

incsrc macros.asm
;macro ShootBulletXY(Xspeed,YSpeed,xPos,yPos,xAccel,yAccel,Type,Info)
;macro ShootBulletAngle(Angle,Speed,xPos,yPos,xAccel,yAccel,Type,Info)	; Note that <angle> must be a 16-BIT value from 0000 to 01FF
;macro ShootBulletToMario(Speed,xPos,yPos,xAccel,yAccel,Type,Info)

;$00		    ; Radius
;$01 $02 	    ; Angle, from 0-1FF


RunSpellCards:
	;LDA #$0A                       ;
	;STA $00                        ; radius
	;STZ $02                        ;\
	;LDA #$40                       ; | angle
	;STA $01                        ;/
	;JSR CODE_01BF6A                ;
	;JSL SIN                        ;
	;LDA #$01                       ;
	;STA $19                        ;

	LDA $13				            ;\  TODO maybe use $14 due to pause abuse
	AND #$07                        ; |
	;CMP #$07                       ; |
	BEQ BeginAttacks                ; | decrement timer every 8 frames
	REP #$30                        ; |
	DEC !timer                      ; |
	SEP #$30                        ;/


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this is so dumb                                          ;
; determines which attack subroutine to call               ;
; NOTE: expand as needed when more spellcards are added    ;
; TODO: this would be way less disgusting with a ptr table ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BeginAttacks:

print "Main Init finished. Begin Attacks!",pc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; JMPS to current attack subroutine               ;
; or MainRoutineStart, if there's no attacks      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%callAttackSubroutine(currentCard)