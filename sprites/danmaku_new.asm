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

incsrc sprites/macros.asm
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
%CallAttackSubroutine(!currentCard)










;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Graphics Routine for bullets.  It is stuck in here, as opposed to in the boss's graphics routine, to save time.
;Granted, not much time, but still...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;LDA !bulletType,x
	;BEQ NoGraphicsToShow

	;CMP #$44		;Protection against overwriting Mario's sprite slots with bullets
	;BEQ NoGraphicsToShow
	;CMP #$45
	;BEQ NoGraphicsToShow


	REP #$10

	LDA !bulletXPos,x
	STA $0204,y

	LDA !bulletYPos,x
	STA $0205,y

	LDA !bulletType,x
	STA $0206,y

	LDA #$3d
	STA $0207,y
	INY
	INY
	INY
	INY
	SEP #$10

NoGraphicsToShow:
	;PLY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;End graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CPX #$3f
	BEQ BossGraphics
	BRL MainLoopPoint
BossGraphics:

	LDA $0e
	CMP #$01
	BNE DontShowHitbox

	LDA $7e
	CLC
	ADC #$04
	STA !hitBoxOAM

	LDA $80
	CLC
	ADC #$10
	STA !hitBoxOAM+1

	LDA #$1f
	STA !hitBoxOAM+2

	LDA #$3d
	STA !hitBoxOAM+3


DontShowHitbox:


	;LDY #$00
	;TXA
	;JSL $01B7B3
	PLX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GENERIC GRAPHICS ROUTINE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUB_GFX:        JSR GET_DRAW_INFO       ; after: Y = index to sprite OAM ($300)
                                            ;      $00 = sprite x position relative to screen border
                                            ;      $01 = sprite y position relative to screen border

		;BRA Skip
		PHX
                    ; if you wish to draw more than one tile, each step between the lines must be repeated
                    ;*************************************************************************************

		LDX #$FF
		GraphicsLoop:
		INX
		LDA $00		; set x position of the tile
		CLC
		ADC Xoffsets,x
		STA $0300,y

		LDA $01		; set y position of the tile
		CLC
		ADC Yoffsets,x
		PHY
		LDY !bossYOffset
		CLC
		ADC KYoffset,y
		PLY
		STA $0301,y

		LDA Tiles,x	; set tile number
		STA $0302,y

		LDA #$09	; get sprite palette info
		STA $0303,y	; set properties

		INY		; get the index to the next slot of the OAM
		INY		; (this is needed if you wish to draw another tile)
		INY
		INY
		CPX #$0F
		BNE GraphicsLoop
		;*************************************************************************************

		LDY #$02	; #$02 means the tiles are 16x16
		TXA		; This means we drew one tile
		PLX
		JSL $01B7B3


		RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ROUTINES FROM THE LIbraRY ARE PASTED BELOW
; You should never have to modify this code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET_DRAW_INFO
; This is a helper for the graphics routine.  It sets off screen flags, AND sets up
; variables.  It will return with the following:
;
;       Y = index to sprite OAM ($300)
;       $00 = sprite x position relative to screen boarder
;       $01 = sprite y position relative to screen boarder
;
; It is adapted from the subroutine at $03B760
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SPR_T1:		db $0C,$1C
SPR_T2:		db $01,$02

GET_DRAW_INFO:
	STZ $186C,x             ; reset sprite offscreen flag, vertical
	STZ $15A0,x             ; reset sprite offscreen flag, horizontal
	LDA $E4,x               ; \
	CMP $1A                 ;  | set horizontal offscreen if necessary
	LDA $14E0,x             ;  |
	SBC $1B                 ;  |
	BEQ ON_SCREEN_X         ;  |
	INC $15A0,x             ; /

ON_SCREEN_X:
	LDA $14E0,x             ; \
	XBA                     ;  |
	LDA $E4,x               ;  |
	REP #$20                ;  |
	SEC                     ;  |
	SBC $1A                 ;  | mark sprite invalid if far enough off screen
	CLC                     ;  |
	ADC #$0040              ;  |
	CMP #$0180              ;  |
	SEP #$20                ;  |
	ROL A                   ;  |
	AND #$01                ;  |
	STA $15C4,x             ; /
	BNE INVALID             ;

	LDY #$00                ; \ set up loop:
	LDA $1662,x             ;  |
	AND #$20                ;  | if not smushed (1662 & 0x20), go through loop twice
	BEQ ON_SCREEN_LOOP      ;  | else, go through loop once
	INY                     ; /
ON_SCREEN_LOOP:
	LDA $D8,x               ; \
	CLC                     ;  | set vertical offscreen if necessary
	ADC SPR_T1,y            ;  |
	PHP                     ;  |
	CMP $1C                 ;  | (vert screen boundry)
	ROL $00                 ;  |
	PLP                     ;  |
	LDA $14D4,x             ;  |
	ADC #$00                ;  |
	LSR $00                 ;  |
	SBC $1D                 ;  |
	BEQ ON_SCREEN_Y         ;  |
	LDA $186C,x             ;  | (vert offscreen)
	ORA SPR_T2,y            ;  |
	STA $186C,x             ;  |
ON_SCREEN_Y:
	DEY                     ;  |
	BPL ON_SCREEN_LOOP      ; /

	LDY $15EA,x             ; get offset to sprite OAM
	LDA $E4,x               ; \
	SEC                     ;  |
	SBC $1A                 ;  | $00 = sprite x position relative to screen boarder
	STA $00                 ; /
	LDA $D8,x               ; \
	SEC                     ;  |
	SBC $1C                 ;  | $01 = sprite y position relative to screen boarder
	STA $01                 ; /
	RTS                     ; return

INVALID:
	PLA                     ; \ return from *main gfx routine* subroutine...
	PLA                     ;  |    ...(not just this subroutine)
	RTS                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.		  	;;;
;;;Essentially, call this whenever a shot is fired.	  	;;;
;;;Use JSR FindBulletSlotXY or the macro below.		  	;;;
;;;							  	;;;
;;;To use, load the initial X speed into $00		  	;;;
;;;        load the initiay Y speed into $01		  	;;;
;;;	   load the initial x pos.  into $02  		  	;;;
;;;	   load the initial y pos.  into $03		  	;;;
;;;	   load the initial x accel into $04		  	;;;
;;;	   load the initial y accel into $05		  	;;;
;;;	   load the initial type    into $06		  	;;;
;;;	   load any  extra  info  into   $07		  	;;;
;;;							  	;;;
;;;	   This is macro-ified for easier coding.  To use,	;;;
;;;	   type %ShootBulletXY($00,$01,$02,$03,$04,$05,$06,$07)	;;;
;;;	   replacing those values with your actual values.	;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindBulletSlotXY:
	STZ !numOfBullets
	LDA !shotBullets
	EOR #$01
	STA !shotBullets
	LDX #$00

FindLoopPoint:
	INX
	CPX #$44				; Protection against overwriting Mario's sprite slots with bullets
	BEQ BulletSlotNotAvailable
	CPX #$45
	BEQ BulletSlotNotAvailable

	LDA !bulletType,x

	BEQ ExitFindLoop




	CPX #$3f
	BNE FindLoopPoint
	BRA NoSlotsAvailable

ExitFindLoop:
						;This is where bullets are created.
	LDA #$40
	STA $1DF9               		; play sound effect

	LDA $00
	STA !bulletXSpeed,x
	LDA $01
	STA !bulletYSpeed,x
	LDA $02
	STA !bulletXPos,x
	LDA $03
	STA !bulletYPos,x
	LDA $04
	STA !bulletXAccel,x
	LDA $05
	STA !bulletYAccel,x
	LDA $06
	STA !bulletType,x
	LDA $07
	STA !bulletInfo,x
	LDA #$07
	STA !bulletXFrac,x
	STA !bulletYFrac,x

NoSlotsAvailable:
	RTS

BulletSlotNotAvailable:
	LDA #$00
	STA !bulletType,x
	BRL FindLoopPoint2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.		 		;;;
;;;Essentially, call this whenever a shot is fired.	  		;;;
;;;Use JSR FindBulletSlotAngle or the macro below.	  		;;;
;;;							  		;;;
;;;To use, load the initial  speed  into $00		  		;;;
;;;        load the initiay  angle  into $01 (00 - 01FF)  		;;;
;;;	   load the initial x pos.  into $03  		  		;;;
;;;	   load the initial y pos.  into $04		  		;;;
;;;	   load the initial x accel into $05		  		;;;
;;;	   load the initial y accel into $06		  		;;;
;;;	   load the initial type    into $07		  		;;;
;;;	   load any  extra  info  into   $08		  		;;;
;;;							  		;;;
;;;	   This is macro-ified for easier coding.  To use,		;;;
;;;	   type %ShootBulletAngle($00,$01,$02,$03,$04,$05,$06,$07)	;;;
;;;	   replacing those values with your actual values.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotAngle:

	STZ !numOfBullets
	LDA !shotBullets
	EOR #$01
	STA !shotBullets
	LDX #$00
FindLoopPoint2:
	INX

	CPX #$45
	BEQ BulletSlotNotAvailable2
	CPX #$46
	BEQ BulletSlotNotAvailable2				;$140B

	LDA !bulletType,x

	BEQ ExitFindLoop2



	CPX #$3F
	BNE FindLoopPoint2
	BRA NoSlotsAvailable2

ExitFindLoop2:
						;This is where bullets are created.
	LDA #$40
	STA $1df9               ; play sound effect
	LDA $03
	STA !bulletXPos,x
	LDA $04
	STA !bulletYPos,x
	LDA $05
	STA !bulletXAccel,x
	LDA $06
	STA !bulletYAccel,x
	;LDA $07
	TXA
	LSR
	LSR
	LSR
	LSR
	CLC
	ADC #$0a
	STA !bulletType,x
	LDA $08
	STA !bulletInfo,x
	LDA #$07
	STA !bulletXFrac,x
	STA !bulletYFrac,x


	JSL SIN				; These come last since they'll destroy the above values otherwise.
	LDA $03
	STA !bulletYSpeed,x

	JSL COS
	LDA $05
	STA !bulletXSpeed,x



NoSlotsAvailable2:
	RTS

BulletSlotNotAvailable2:
	LDA #$00
	STA !bulletType,x
	BRL FindLoopPoint2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.		  		;;;
;;;Essentially, call this whenever a shot is fired.	  		;;;
;;;Use JSR FindBulletSlotAim or the macro below.	  		;;;
;;;							  		;;;
;;;To use, load the initial  speed  into $00		  		;;;
;;;        load the initiay  angle  into $01 (00 - 01FF)  		;;;
;;;	   load the initial x pos.  into $03  		  		;;;
;;;	   load the initial y pos.  into $04		  		;;;
;;;	   load the initial x accel into $05		  		;;;
;;;	   load the initial y accel into $06		  		;;;
;;;	   load the initial type    into $07		  		;;;
;;;	   load any  extra  info  into   $08		  		;;;
;;;							  		;;;
;;;	   This is macro-ified for easier coding.  To use,		;;;
;;;	   type %ShootBulletAngle($00,$01,$02,$03,$04,$05,$06,$07)	;;;
;;;	   replacing those values with your actual values.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindBulletSlotAim:
	; LDA #$05
	; STA $19

	STZ !numOfBullets
	LDA !shotBullets
	EOR #$01
	STA !shotBullets
	LDX #$00
	FindLoopPoint3:
	INX

	CPX #$45
	BEQ BulletSlotNotAvailable3
	CPX #$46
	BEQ BulletSlotNotAvailable3		; $140B

	LDA !bulletType,x

	BEQ ExitFindLoop3



	CPX #$3f
	BNE FindLoopPoint3
	BRA NoSlotsAvailable3

ExitFindLoop3:
						; This is where bullets are created.
	LDA #$40
	STA $1DF9               		; play sound effect
	LDA $01
	STA !bulletXPos,x
	LDA $02
	STA !bulletYPos,x
	LDA $03
	STA !bulletXAccel,x
	LDA $04
	STA !bulletYAccel,x
	;LDA $05
	TXA
	LSR
	LSR
	LSR
	LSR
	CLC
	ADC #$0a
	STA !bulletType,x
	LDA $06
	STA !bulletInfo,x
	LDA #$07
	STA !bulletXFrac,x
	STA !bulletYFrac,x

	; LDA #$01
	; STA $19
	TXA
	STA $09

	LDA $00
	JSR CODE_01BF6A
	LDA $00
	STA !bulletYSpeed,x
	LDA $01
	STA !bulletXSpeed,x

NoSlotsAvailable3:
	RTS

BulletSlotNotAvailable3:
	LDA #$00
	STA !bulletType,x
	BRL FindLoopPoint3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; aiming routine
; input: accumulator should be set to total speed (x+y), $09 should be bullet index
; output: $00 = y speed, $01 = x speed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE_01BF6A:
	STA $01
	REP #$20
	LDA $d3
	CLC
	ADC #$0008
	STA $d3
	SEP #$20
	PHX					;\ preserve sprite indexes of Magikoopa AND magic
	PHY					;/
	JSR CODE_01AD42				; $0E = vertical distance to Mario
	STY $02					; $02 = vertical direction to Mario
	LDA $0e					;\ $0C = vertical distance to Mario, positive
	BPL CODE_01BF7C				; |
	EOR #$ff				; |
	CLC					; |
	ADC #$01				; |
CODE_01BF7C:					; |
	STA $0c					;/
	JSR SUB_HORZ_POS			; $0F = horizontal distance to Mario
	STY $03					; $03 = horizontal direction to Mario
	LDA $0f					;\ $0D = horizontal distance to Mario, positive
	BPL CODE_01BF8C				; |
	EOR #$ff				; |
	CLC					; |
	ADC #$01				; |
CODE_01BF8C:					; |
	STA $0d					;/
	LDY #$00
	LDA $0d					;\ if vertical distance less than horizontal distance,
	CMP $0c					; |
	BCS CODE_01BF9F				;/ branch
	INY					; set y register
	PHA					;\ switch $0C AND $0D
	LDA $0c					; |
	STA $0d					; |
	PLA					; |
	STA $0c					;/
CODE_01BF9F:
	LDA #$00				;\ zero out $00 AND $0B
	STA $0b					; | ...what's wrong with STZ?
	STA $00					;/
	LDX $01					;\ divide $0C by $0D?
CODE_01BFA7:
	LDA $0b					; |\ if $0C + loop counter is less than $0D,
	CLC					; | |
	ADC $0c					; | |
	CMP $0d					; | |
	BCC CODE_01BFB4				; |/ branch
	SBC $0d					; | else, subtract $0D
	INC $00					; | AND increase $00
CODE_01BFB4:					; |
	STA $0b					; |
	DEX					; |\ if still cycles left to run,
	BNE CODE_01BFA7				;/ / go to start of loop
	TYA					;\ if $0C AND $0D was not switched,
	BEQ CODE_01BFC6				;/ branch
	LDA $00					;\ else, switch $00 AND $01
	PHA					; |
	LDA $01					; |
	STA $00					; |
	PLA					; |
	STA $01					;/
CODE_01BFC6:
	LDA $00					;\ if horizontal distance was inverted,
	LDY $02					; | invert $00
	BEQ CODE_01BFD3				; |
	EOR #$ff				; |
	CLC					; |
	ADC #$01				; |
	STA $00					;/
CODE_01BFD3:
	LDA $01					;\ if vertical distance was inverted,
	LDY $03					; | invert $01
	BEQ CODE_01BFE0				; |
	EOR #$ff				; |
	CLC					; |
	ADC #$01				; |
	STA $01					;/
CODE_01BFE0:
	PLY					;\ retrieve Magikoopa AND magic sprite indexes
	PLX					;/
	REP #$20
	LDA $d3
	SEC
	SBC #$0010
	STA $d3
	SEP #$20
	RTS					; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE_01AD42:
	LDY #$00
	PHX
	LDX $09
	LDA !bulletYPos,x
	CLC
	ADC #$04
	STA !bulletYPos,x
	LDA $d3

	SEC
	SBC !bulletYPos,x
	;CLC
	;ADC #$04

	STA $0e
	LDA $d4
	SBC #$00
	BPL Return01AD53
	INY

Return01AD53:
	LDA !bulletYPos,x
	SEC
	SBC #$04
	STA !bulletYPos,x
	PLX
	RTS					; return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB_HORZ_POS:
	LDY #$00                ;A:25D0 X:0006 Y:0001 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1020 VC:097 00 FL:31642
    	LDX $09
	LDA !bulletXPos,x
	CLC
	ADC #$04
	STA !bulletXPos,x
    	LDA $94                 ;A:25D0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:envMXdiZCHC:1036 VC:097 00 FL:31642
    	SEC                     ;A:25F0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1060 VC:097 00 FL:31642
    	SBC !bulletXPos,x       ;A:25F0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1074 VC:097 00 FL:31642
	;CLC
	;ADC #$04
	STA $0f             	;A:25F4 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1104 VC:097 00 FL:31642
    	LDA $95                 ;A:25F4 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1128 VC:097 00 FL:31642
    	SBC $14e0,x             ;A:2500 X:0006 Y:0000 D:0000 DB:03 S:01ED P:envMXdiZcHC:1152 VC:097 00 FL:31642
    	BPL LABEL16             ;A:25FF X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1184 VC:097 00 FL:31642
    	INY                     ;A:25FF X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1200 VC:097 00 FL:31642
LABEL16:
	LDA !bulletXPos,x
	SEC
	SBC #$04
	STA !bulletXPos,x
    	RTS                     ;A:25FF X:0006 Y:0001 D:0000 DB:03 S:01ED P:envMXdizcHC:1214 VC:097 00 FL:31642
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;






;-------------------------------;SIN JSL
SIN:	PHP			;From: Support.asm's JSL.asm
	PHX			;By:
				;Comment Translation+Addition By: Fakescaper
	TDC			;LDA #$0000
	LDA $01			;This determines the Ypos if you're using it for sprite movement
	REP #$30		;16-BIT AXY
	ASL A			;$00     = Radius
	TAX			;$01/$02 = Angle ($0000-$01FF)
	LDA $07F7DB,x		;SMW's 16-BIT CircleCoords table
	STA $03			;
				;
	SEP #$30		;8bit AXY
	LDA $02			;\ push $02
	PHA			;/
	LDA $03			;|sin|‚ð
	STA $4202		;u‚©‚¯‚ç‚ê‚é”v‚Æ‚·‚éB
	LDA $00			; $00 = radius
	LDX $04			;\ if |sin| = 1 then skip calculation
	BNE .IF1_SIN		;/
	STA $4203		;”¼Œa‚ðu‚©‚¯‚é”v‚Æ‚·‚éB
	ASL $4216		;o‚½“š‚¦‚Ì¬”“_ˆÈ‰º‚ðŽlŽÌŒÜ“ü
	LDA $4217		;
	ADC #$00		;
.IF1_SIN			;
	LSR $02			; remove the sign
	BCC .IF_SIN_PLUS	;
				;
	EOR #$FF		;\
	INC A			; | two's complement negation
	STA $03			;/
	BEQ .IF0_SIN		; branch if angle == 0
	LDA #$FF		;
	STA $04			;
	BRA .END_SIN		;
				;
.IF_SIN_PLUS			;
	STA $03			;
.IF0_SIN			;
	STZ $04			;
.END_SIN			;
	PLA			;
	STA $02			;$02‚ð•œŒ³
	PLX			;
	PLP			;
	RTL			;Return
;-------------------------------;
;-------------------------------;
COS:	PHP			;
	PHX			;
	REP #$31		;16bit AXY + Carry Clear
	LDA $01			;$01 = ƒÆ
	ADC #$0080		;
	AND #$01FF		;
	STA $07			;$07 = ƒÆ + 90‹
	;LDA $07		;Not needed because A will already be what was just stored
	AND #$00FF		;
	ASL A			;
	TAX			;
	LDA $07F7DB,x		;SMW's 16-BIT CircleCoords table
	STA $05			;
				;
	SEP #$30		;
	LDA $05			;|cos|‚ð
	STA $4202		;u‚©‚¯‚ç‚ê‚é”v‚Æ‚·‚éB
	LDA $00			;”¼Œa‚ðŒÄ‚Ô
	LDX $06			;|cos| = 1.00 ‚¾‚Á‚½‚çŒvŽZ•s—viRsin = ”¼Œaj
	BNE .IF1_COS		;
	STA $4203		;”¼Œa‚ðu‚©‚¯‚é”v‚Æ‚·‚éB
	ASL $4216		;o‚½“š‚¦‚Ì¬”“_ˆÈ‰º‚ðŽlŽÌŒÜ“ü
	LDA $4217		;
	ADC #$00		;
.IF1_COS			;
	LSR $08			;â‘Î’l‚ðŠO‚·
	BCC .IF_COS_PLUS	;
	EOR #$FF		;XOR
	INC A			;
	STA $05			;
	BEQ .IF0_COS		;
	LDA #$FF		;
	STA $06			;
	BRA .END_COS		;
				;
.IF_COS_PLUS			;
	STA $05			;
.IF0_COS			;
	STZ $06			;
.END_COS			;
	PLX			;
	PLP			;
	RTL			;Return
;-------------------------------;


MariosMovementRoutine:
	STZ $0f
	LDA $17 			;\
	AND #$08 			; | if holding B...
	BNE MoveSlowly 			; | ...enable "focus"
	LDA #$02 			; | $0E = pixels to move each frame
	STA $0e 			;/
	BRA MovementAdditionEnd
MoveSlowly:
	LDA #$01 			;\ focus on
	STA $0e 			;/

MovementAdditionEnd:
	LDA $15 			;\
	AND #$01 			; | check if pressing right
	;CMP #$01 			; |
	BEQ CheckLeft 			;/
	REP #$20
	LDA $0e 			;\
	CLC 				; | add 'focus value' to x-position
	ADC $94 			; |
	STA $94 			;/
	SEP #$20
	BRA NowForYSpeed
CheckLeft:
	LDA $15 			;\
	AND #$02 			; | check if pressing left
	;CMP #$02 			; |
	BEQ ZeroXSpeed 			;/
	REP #$20
	LDA $94 			;\
	SEC 				; | subtract 'focus value' from x-position
	SBC $0e 			; |
	STA $94 			;/
	SEP #$20
	BRA NowForYSpeed

ZeroXSpeed:

NowForYSpeed:
	LDA $15 			;\
	AND #$04 			; | check if pressing down
	;CMP #$04 			; |
	BEQ CheckUp 			;/
	REP #$20
	LDA $0e 			;\
	CLC 				; | add 'focus value' to y-position
	ADC $96 			; |
	STA $96 			;/
	SEP #$20
	BRA andWereDone
CheckUp:
	LDA $15 			;\
	AND #$08 			; | check if pressing down
	;CMP #$08 			; |
	BEQ ZeroYSpeed 			;/

	REP #$20
	LDA $96 			;\
	SEC 				; | subtract 'focus value' from y-position
	SBC $0e 			; |
	STA $96 			;/
	SEP #$20
	BRA andWereDone

ZeroYSpeed:
andWereDone:
	RTS 				; return
