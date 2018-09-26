!bulletXSpeed = $7F0D00	;The horizontal speed of the bullets.
!bulletYSpeed = $7F0E00	;The  vertical  speed of the bullets.
!bulletXPos   = $7F0F00	;The distance a bullet is from the left side of the screen.
!bulletYPos   = $7F1000	;The distance a bullet is from the top  side of the screen.
!bulletType   = $7F1100	;The color of the bullet.  0 is used to mean that the bullet is nonexistant.
!bulletInfo   = $7F1200	;Any extra information about the bullet.
!bulletXAccel = $7F1300	;The X acceleration of a bullet
!bulletYAccel = $7F1400	;The Y acceleration of a bullet
!bulletXFrac  = $7F1500	;The X accumulating fraction position of a bullet.
!bulletYFrac  = $7F1600	;The X accumulating fraction position of a bullet.
!bossYOffset  = $0DD9	;Used for a floaty effect with the boss.
!numOfBullets = $140B	;Keeps track of how many bullets exist.
!shotBullets  = $140C	;Used as a misc. counter.
!bulletLocation = $1763	;A two byte wide variable used for hit detection.
!hitBoxOAM    = $0200	;The OAM address for Mario's hitbox.  This really shouldn't be changed.
!state	      = $1DFD	;The current state of the boss. 0 is idle, 1 is display spell card, 2 is fire bullets, 3 is Mario has been hit, 4 is boss is dead.
!stateTimer   = $60	;The amount of time to remain idle, displaying a spell card, or remain in the Mario Is Dead state.
!timeHasRunOut = $61	;This flag is set whenever the timer loopes from 0 to FFFF.  It is your responsibility to reset it at the end of a spellcard.
!currentCard  = $62	;This is the number of the attack that the boss is using.  It is used to determine how bullets should be fired.
!timer	      = $63	;How much time has passed. Is a word.

!angle1       = $0F5E	;These are used for some of the spellcards; the have no global effect.
!angle2       = $0F60
!angle3       = $0F62
!angle4       = $0F64
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT and MAIN JSL targets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		print "INIT ",pc
		JSR INIT
		RTL         

		print "MAIN ",pc
		PHB
		PHK
		PLB
		JSR MAIN
		STZ $0313	;Fixes a bug with Mario's YXPPCCCT OAM slots
		STZ $0317	;Fixes a bug with Mario's YXPPCCCT OAM slots
		PLB
		RTL


KYoffset:	db $0C,$0C,$0C,$0C,$0C,$0C,$0B,$0B,$0B,$0B,$0A,$0A,$0A,$09,$09,$09
		db $08,$08,$08,$07,$07,$07,$06,$06,$06,$05,$05,$04,$04,$03,$03,$03
		db $02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$05
		db $05,$06,$06,$06,$07,$07,$07,$08,$08,$08,$09,$09,$09,$0A,$0A,$0A
		db $0B,$0B,$0B,$0B,$0C,$0C,$0C,$0C,$0C,$0C


Xoffsets:	db $1A,$14,$24,$00,$10,$20,$30,$00,$10,$20,$30,$40,$00,$10,$20,$30
Yoffsets:	db $00,$10,$10,$20,$20,$20,$20,$30,$30,$30,$30,$30,$40,$40,$40,$40
Tiles:		db $00,$20,$22,$40,$42,$44,$46,$60,$62,$64,$66,$68,$02,$04,$06,$08
BXoffsets:	db $00,$08,$10,$18,$20,$28,$30,$38,$40,$48,$50,$58,$60,$68,$70,$78,$80
BYoffsets:	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10
BTiles:		db $0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B
db $0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B
db $0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B
db $0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B
db $0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B,$0C,$0D,$0E,$0A,$0B

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;INITIALIZE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT:
STZ !state
STZ !currentCard
LDA #$80
STA !stateTimer
PHX
REP #$10
LDX #$00F0
STX !timer

LDX #$FFFF
InitLoopPoint:
INX
LDA #$00
STA $7F0D00,x
CPX.w #$1500
BNE InitLoopPoint
SEP #$10
PLX


REP #$20
;LDA #$00FF
;STA $60
;LDA #$00FF
;STA $62

LDA #$0000
STA $64

SEP #$20
RTS


MAIN:		DEC !stateTimer
		LDA !stateTimer
		BNE stateTimerIsnt0
		LDA #$02
		STA !state

		stateTimerIsnt0:
		
		LDA !state
		CMP #$03
		BEQ MarioHasDiedMovement
		JSR MariosMovementRoutine
		BRA SkipMarioHasDiedMovement
		MarioHasDiedMovement:
		REP #$20
		DEC $96
		SEP #$20
		DEC !stateTimer
		
		SkipMarioHasDiedMovement:

		INC !bossYOffset
		LDA !bossYOffset
		CMP #$5A
		BNE DontResetBossFloatHeight
		STZ !bossYOffset
		DontResetBossFloatHeight:
		PHX



		LDA !state
		CMP #$02
		BEQ RunSpellCards 
		BRL dontRunSpellCards
		RunSpellCards:

macro ShootBulletXY(Xspeed,YSpeed,XPos,YPos,XAccel,YAccel,Type,Info)
		LDA <Xspeed>
		STA $00
		LDA <YSpeed>
		STA $01
		LDA <XPos>
		STA $02
		LDA <YPos>
		STA $03
		LDA <XAccel>
		STA $04
		LDA <YAccel>
		STA $05
		LDA <Type>
		STA $06
		LDA <Info>
		STA $07
		JSR FindBulletSlotXY
endmacro

macro ShootBulletAngle(Angle,Speed,XPos,YPos,XAccel,YAccel,Type,Info)	;Note that <angle> must be a 16-bit value from 0000 to 01FF!
		REP #$20
		LDA <Angle>
		STA $01
		SEP #$20
		LDA <Speed>
		STA $00
		LDA <XPos>
		STA $03
		LDA <YPos>
		STA $04
		LDA <XAccel>
		STA $05
		LDA <YAccel>
		STA $06
		LDA <Type>
		STA $07
		LDA <Info>
		STA $08
		JSR FindBulletSlotAngle
endmacro

macro ShootBulletToMario(Speed,XPos,YPos,XAccel,YAccel,Type,Info)	;Note that <angle> must be a 16-bit value from 0000 to 01FF!
		LDA <Speed>
		STA $00
		LDA <XPos>
		STA $01
		LDA <YPos>
		STA $02
		LDA <XAccel>
		STA $03
		LDA <YAccel>
		STA $04
		LDA <Type>
		STA $05
		LDA <Info>
		STA $06
		JSR FindBulletSlotAim
endmacro


;$00		;Radius
;$01 $02 	;Angle, from 0-1FF


		;LDA #$0A
		;STA $00
		;STZ $02
		;LDA #$40
		;STA $01
		;JSR CODE_01BF6A
		;JSL SIN
		;LDA #$01
		;STA $19

		LDA $13			;Consider this to be a master timer.
		AND #$07
		CMP #$07
		BNE DontDecreaseTimer
		REP #$30
		DEC !timer
		SEP #$30

		TimerHasNotRunOut:
		DontDecreaseTimer:


		LDA !currentCard
		BNE NotAttack0
		JMP Attack0

		NotAttack0:
		CMP #$01
		BNE NotAttack1
		JMP Attack1

		NotAttack1:
		CMP #$02
		BNE NotAttack2
		JMP Attack2

		NotAttack2:
		CMP #$03
		BNE NoAttacks
		JMP Attack3
		NoAttacks:
		JMP MainRoutineStart:	




		Attack2:
		Attack3:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Spellcard0:
		Attack0:
		;ShootBulletXY(Xspeed,YSpeed,XPos,YPos,XAccel,YAccel,Type,Info)
		REP #$20
		LDA !timer
		CMP #$FFFF
		BNE DontEndCard01

		LDA #$00FF		;From here until the DontEndCard01 is what happens when this card runs out of time.
					;You can consider it the INIT for each card.
		STZ !angle1		;These are variables used for the next spellcard.
		STZ !angle2		;The are not globally important.
		STA !angle3
		STA !angle4

		SEP #$20

		STZ !state
		REP #$20
		LDA #$00FF		;This is the amount of time the next spellcard will last for.
		STA !timer
		SEP #$20
		LDA #$F0
		STA !stateTimer
		INC !currentCard
		

		

		DontEndCard01:
		SEP #$20
		LDA $13
		AND #$07
		CMP #$07
		BNE Spell01PrematureEnd2

		LDA $13
		AND #$0F
		CMP #$0F
		BNE DoHorizontalShot
	
		LDA $7E
		CLC
		ADC #$02
		STA $0F

	
		%ShootBulletXY(#$00,#$1D,$0F,#$00,#$00,#$00,#$0A,#$00)
		BRA SkipThisThingey01
		DoHorizontalShot:

		LDA $80
		CLC
		ADC #$10
		STA $0F

	
		%ShootBulletXY(#$1D,#$00,#$00,$0F,#$00,#$00,#$0A,#$00)



BRA SkipThisThingey01
Spell01PrematureEnd2:
BRL Spell01PrematureEnd
SkipThisThingey01:


		LDA $13
		AND #$0F
		CMP #$0F
		BNE Spell01PrematureEnd2

		%ShootBulletXY(#$00,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)
		%ShootBulletXY(#$07,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)
		%ShootBulletXY(#$10,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)
		%ShootBulletXY(#$F8,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)
		%ShootBulletXY(#$F0,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)

		;%ShootBulletAngle(!angle,#$07,#$7F,#$7F,#$FF,#$FF,#$0A,#$00)
		;%ShootBulletAngle(!angle2,#$07,#$7F,#$7F,#$03,#$03,#$0A,#$00)

Spell01PrematureEnd:
JMP DoneFiring				;Always call this at the end of a spellcard!!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Spellcard1:
		Attack1:
		REP #$20
		LDA !timer
		CMP #$FFFF
		BNE DontEndCard02
		SEP #$20
		STZ !state
		REP #$20
		LDA #$0050		;This is the amount of time the next spellcard will last for.
		STA !timer
		SEP #$20
		LDA #$F0
		STA !stateTimer
		INC !currentCard

		DontEndCard02:
		REP #$20
		LDA !timer
		CMP #$0078
		BCS WaitLonger

		SEP #$20
		LDA #$2F
		STA $0E
		LDA $13
		AND #$07
		CMP #$07
		BNE Spell02PrematureEnd2
		BRA SkipThisThingey02

		WaitLonger:
		SEP #$20
		LDA #$17
		STA $0E

		LDA $13
		AND #$0F
		CMP #$0F
		BNE Spell02PrematureEnd2

BRA SkipThisThingey02
Spell02PrematureEnd2:
BRL Spell02PrematureEnd
SkipThisThingey02:
		LDA $80
		CLC
		ADC #$10
		STA $0F

	
		%ShootBulletXY(#$1D,#$00,#$00,$0F,#$00,#$00,#$0A,#$00)

		%ShootBulletAngle(!angle1,$0E,#$7F,#$30,#$00,#$00,#$0A,#$00)
		%ShootBulletAngle(!angle2,$0E,#$7F,#$30,#$00,#$00,#$0A,#$00)
		%ShootBulletAngle(!angle3,$0E,#$7F,#$30,#$00,#$00,#$0A,#$00)
		%ShootBulletAngle(!angle4,$0E,#$7F,#$30,#$00,#$00,#$0A,#$00)

		REP #$20

		LDA !angle1
		CLC
		ADC #$0005
		STA !angle1
		CMP #$0200
		BCC DontResetAngle1
		STZ !angle1
		DontResetAngle1:

		LDA !angle2
		SEC
		SBC #$0005
		STA !angle2
		BCS DontResetAngle2
		LDA #$01FF
		STA !angle2
		DontResetAngle2:


		LDA !angle3
		CLC
		ADC #$0005
		STA !angle3
		CMP #$0200
		BCC DontResetAngle3
		STZ !angle3
		DontResetAngle3:

		LDA !angle4
		SEC
		SBC #$0005
		STA !angle4
		BCS DontResetAngle4
		LDA #$01FF
		STA !angle4
		DontResetAngle4:

		SEP #$20
Spell02PrematureEnd:
JMP DoneFiring



dontRunSpellCards:

























;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;END OF BULLET SHOOTING/SPELLCARD ROUTINE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DoneFiring:

		LDA $71
		BNE DontUseSpeedUpThingy
		LDA #$01	;Required to speed up the game.  
		STA $9D
		BRA WeveUsedSpeedUpThingy
		DontUseSpeedUpThingy:
		STZ $9D
		WeveUsedSpeedUpThingy:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;The heart of the routine.  We loop through every bullet and decide its movement, its proximity to Mario, etc.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MainRoutineStart:


;PHY


REP #$10
LDX #$0000
SEP #$10
MainLoopPoint:
INX



LDA #$FF
INC
LDA #$00
DEC

LDA !bulletYSpeed,X
BMI YSpeedIsNegative
CLC
ADC !bulletYFrac,X
STA !bulletYFrac,X
LSR
LSR
LSR
LSR
CLC
ADC !bulletYPos,X
BCS DeleteBulletYBranch
STA !bulletYPos,X
LDA !bulletYPos,X
CMP #$F0
BCS DeleteBulletYBranch

LDA !bulletYFrac,X
CMP #$10
BCC DontResetYFrac
LDA !bulletYFrac,X
AND #$0F
STA !bulletYFrac,X

BRA DontResetYFrac

DeleteBulletYBranch:
BRL DeleteBulletXBranch



YSpeedIsNegative:
CLC
ADC !bulletYFrac,X
STA !bulletYFrac,X
CMP #$10
BCC DontUpdateYPos
STA $00
AND #$F0
LSR
LSR
LSR
LSR
EOR #$0F
INC
STA $01
LDA !bulletYPos,x
SEC
SBC $01
BCC DeleteBulletYBranch
STA !bulletYPos,x
LDA $00
AND #$0F
STA !bulletYFrac,X

DontUpdateYPos:
DontResetYFrac:			;I had to recode this section multiple times,
DontResetYFrac2:		;And I was too lazy to swap out the old labels.



LDA !bulletYAccel,x
;BMI YAccelIsNegative
CLC
ADC !bulletYSpeed,x
;BCS DoneWithYAccel
STA !bulletYSpeed,x
;BRA DoneWithYAccel

;YAccelIsNegative:
;CLC
;ADC !bulletYSpeed,x
;BCC DoneWithYAccel
;STA !bulletYSpeed,x

DoneWithYAccel:

				;Now we handle horizontal movement.
LDA !bulletXSpeed,X
BMI XSpeedIsNegative
CLC
ADC !bulletXFrac,X
STA !bulletXFrac,X
LSR
LSR
LSR
LSR
CLC
ADC !bulletXPos,X
BCS DeleteBulletXBranch
STA !bulletXPos,X

LDA !bulletXFrac,X
CMP #$10
BCC DontResetXFrac
LDA !bulletXFrac,X
AND #$0F
STA !bulletXFrac,X
BRA DontResetXFrac





XSpeedIsNegative:
CLC
ADC !bulletXFrac,X
STA !bulletXFrac,X
CMP #$10
BCC DontUpdateXPos
STA $00
AND #$F0
LSR
LSR
LSR
LSR
EOR #$0F
INC
STA $01
LDA !bulletXPos,x
SEC
SBC $01
BCC DeleteBulletXBranch
STA !bulletXPos,x
LDA $00
AND #$0F
STA !bulletXFrac,X
BRA DontUpdateXPos
DeleteBulletXBranch:
LDA #$00
STA !bulletType,X
DontUpdateXPos:









DontResetXFrac:
DontResetXFrac2:
DoneMessingWithXSpeed:


LDA !bulletXAccel,x
CLC
ADC !bulletXSpeed,x
STA !bulletXSpeed,x
;LDA !bulletYPos,X
;CMP #$F0
;BCC IsntOutOfBounds
;LDA #$00
;STA !bulletType,X
IsntOutOfBounds:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Hit Detection Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CPX #$00
BNE IsntZero
LDA !bulletType,X
BEQ IsntZero
STZ $0D9C
IsntZero:

LDA !bulletXPos,X
STA !bulletLocation
STZ !bulletLocation+1
REP #$20
LDA !bulletLocation
CLC
ADC #$0004
STA !bulletLocation

LDA $94
CLC
ADC #$0007
SEC 
SBC !bulletLocation
BMI XResultIsNegative
CMP #$0004
BCS DontHurtMario
BRA MaybeHurtMario

XResultIsNegative:
EOR #$FFFF
INC
CMP #$0007
BCS DontHurtMario

MaybeHurtMario:
LDA !bulletYPos,X
STA !bulletLocation
STZ !bulletLocation+1
REP #$20
LDA !bulletLocation
CLC
ADC #$0004
STA !bulletLocation

LDA $96
CLC
ADC #$0013
SEC 
SBC !bulletLocation
BMI YResultIsNegative
CMP #$0004
BCS DontHurtMario
BRA HurtMario

YResultIsNegative:
EOR #$FFFF
INC
CMP #$0007
BCS DontHurtMario


HurtMario:
SEP #$20
JSL $00F5B7


DontHurtMario:
SEP #$20
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;End Hit Detection Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Graphics Routine for bullets.  It is stuck in here, as opposed to in the boss's graphics routine, to save time.
;Granted, not much time, but still...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LDA !bulletType,X
BEQ NoGraphicsToShow

CMP #$44		;Protection against overwriting Mario's sprite slots with bullets
BEQ NoGraphicsToShow
CMP #$45
BEQ NoGraphicsToShow


REP #$10

LDA !bulletXPos,x
STA $0204,y

LDA !bulletYPos,x
STA $0205,y

LDA !bulletType,x
STA $0206,y

LDA #$3D
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
CPX #$7F			
BEQ BossGraphics
BRL MainLoopPoint
BossGraphics:

LDA $0E
CMP #$01
BNE DontShowHitbox

LDA $7E
CLC
ADC #$04
STA !hitBoxOAM

LDA $80
CLC
ADC #$10
STA !hitBoxOAM+1

LDA #$1F
STA !hitBoxOAM+2

LDA #$3D
STA !hitBoxOAM+3


DontShowHitbox:




;LDY #$00
;TXA
;JSL $01B7B3
PLX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GENERIC GRAPHICS ROUTINE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUB_GFX:             JSR GET_DRAW_INFO       ; after: Y = index to sprite OAM ($300)
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

		LDA Tiles,X	; set tile number
		STA $0302,y

		LDA #$0F	; get sprite palette info
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
; ROUTINES FROM THE LIBRARY ARE PASTED BELOW
; You should never have to modify this code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET_DRAW_INFO
; This is a helper for the graphics routine.  It sets off screen flags, and sets up
; variables.  It will return with the following:
;
;       Y = index to sprite OAM ($300)
;       $00 = sprite x position relative to screen boarder
;       $01 = sprite y position relative to screen boarder  
;
; It is adapted from the subroutine at $03B760
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SPR_T1:              db $0C,$1C
SPR_T2:              db $01,$02

GET_DRAW_INFO:       STZ $186C,x             ; reset sprite offscreen flag, vertical
                    STZ $15A0,x             ; reset sprite offscreen flag, horizontal
                    LDA $E4,x               ; \
                    CMP $1A                 ;  | set horizontal offscreen if necessary
                    LDA $14E0,x             ;  |
                    SBC $1B                 ;  |
                    BEQ ON_SCREEN_X         ;  |
                    INC $15A0,x             ; /

ON_SCREEN_X:         LDA $14E0,x             ; \
                    XBA                     ;  |
                    LDA $E4,x               ;  |
                    REP #$20                ;  |
                    SEC                     ;  |
                    SBC $1A                 ;  | mark sprite invalid if far enough off screen
                    CLC                     ;  |
                    ADC #$0040            ;  |
                    CMP #$0180            ;  |
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
ON_SCREEN_LOOP:      LDA $D8,x               ; \ 
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
ON_SCREEN_Y:         DEY                     ;  |
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

INVALID:             PLA                     ; \ return from *main gfx routine* subroutine...
                    PLA                     ;  |    ...(not just this subroutine)
                    RTS                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.		  ;;;
;;;Essentially, call this whenever a shot is fired.	  ;;;
;;;Use JSR FindBulletSlotXY or the macro below.		  ;;;
;;;							  ;;;
;;;To use, load the initial X speed into $00		  ;;;
;;;        load the initiay Y speed into $01		  ;;;
;;;	   load the initial x pos.  into $02  		  ;;;
;;;	   load the initial y pos.  into $03		  ;;;
;;;	   load the initial x accel into $04		  ;;;
;;;	   load the initial y accel into $05		  ;;;
;;;	   load the initial type    into $06		  ;;;
;;;	   load any  extra  info  into   $07		  ;;;
;;;							  ;;;
;;;	   This is macro-ified for easier coding.  To use,;;;
;;;	   type %ShootBulletXY($00,$01,$02,$03,$04,$05,$06,$07)
;;;	   replacing those values with your actual values.;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotXY:
STZ !numOfBullets
LDA !shotBullets
EOR #$01
STA !shotBullets
LDX #$00

FindLoopPoint:
INX 
CPX #$44		;Protection against overwriting Mario's sprite slots with bullets
BEQ BulletSlotNotAvailable
CPX #$45
BEQ BulletSlotNotAvailable

LDA !bulletType,X

BEQ ExitFindLoop




CPX #$7F
BNE FindLoopPoint
BRA NoSlotsAvailable

ExitFindLoop:
					;This is where bullets are created.
LDA #$40                
STA $1DF9               ; Play sound effect 

LDA $00
STA !bulletXSpeed,X
LDA $01
STA !bulletYSpeed,X
LDA $02
STA !bulletXPos,X
LDA $03
STA !bulletYPos,X
LDA $04
STA !bulletXAccel,X
LDA $05
STA !bulletYAccel,X
LDA $06
STA !bulletType,X
LDA $07
STA !bulletInfo,X
LDA #$07
STA !bulletXFrac,X
STA !bulletYFrac,X
NoSlotsAvailable:
RTS

BulletSlotNotAvailable:
LDA #$00
STA !bulletType,X
BRL FindLoopPoint2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.		  ;;;
;;;Essentially, call this whenever a shot is fired.	  ;;;
;;;Use JSR FindBulletSlotAngle or the macro below.	  ;;;
;;;							  ;;;
;;;To use, load the initial  speed  into $00		  ;;;
;;;        load the initiay  angle  into $01 (00 - 01FF)  ;;;
;;;	   load the initial x pos.  into $03  		  ;;;
;;;	   load the initial y pos.  into $04		  ;;;
;;;	   load the initial x accel into $05		  ;;;
;;;	   load the initial y accel into $06		  ;;;
;;;	   load the initial type    into $07		  ;;;
;;;	   load any  extra  info  into   $08		  ;;;
;;;							  ;;;
;;;	   This is macro-ified for easier coding.  To use,;;;
;;;	   type %ShootBulletAngle($00,$01,$02,$03,$04,$05,$06,$07)
;;;	   replacing those values with your actual values.;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotAngle:


LDA !shotBullets
EOR #$01
STA !shotBullets
LDX #$00
FindLoopPoint2:
INX 
STZ !numOfBullets

CPX #$45
BEQ BulletSlotNotAvailable2
CPX #$46
BEQ BulletSlotNotAvailable2				;$140B

LDA !bulletType,X

BEQ ExitFindLoop2



CPX #$7F
BNE FindLoopPoint2
BRA NoSlotsAvailable2

ExitFindLoop2:
					;This is where bullets are created.
LDA #$40                
STA $1DF9               ; Play sound effect 
LDA $03
STA !bulletXPos,X
LDA $04
STA !bulletYPos,X
LDA $05
STA !bulletXAccel,X
LDA $06
STA !bulletYAccel,X
;LDA $07
TXA
LSR
LSR
LSR
LSR
CLC
ADC #$0A
STA !bulletType,X
LDA $08
STA !bulletInfo,X
LDA #$07
STA !bulletXFrac,X
STA !bulletYFrac,X


JSL SIN				;These come last since they'll destroy the above values otherwise.
LDA $03
STA !bulletYSpeed,X

JSL COS
LDA $05
STA !bulletXSpeed,X



NoSlotsAvailable2:
RTS

BulletSlotNotAvailable2:
LDA #$00
STA !bulletType,X
BRL FindLoopPoint2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.		  ;;;
;;;Essentially, call this whenever a shot is fired.	  ;;;
;;;Use JSR FindBulletSlotAim or the macro below.	  ;;;
;;;							  ;;;
;;;To use, load the initial  speed  into $00		  ;;;
;;;        load the initiay  angle  into $01 (00 - 01FF)  ;;;
;;;	   load the initial x pos.  into $03  		  ;;;
;;;	   load the initial y pos.  into $04		  ;;;
;;;	   load the initial x accel into $05		  ;;;
;;;	   load the initial y accel into $06		  ;;;
;;;	   load the initial type    into $07		  ;;;
;;;	   load any  extra  info  into   $08		  ;;;
;;;							  ;;;
;;;	   This is macro-ified for easier coding.  To use,;;;
;;;	   type %ShootBulletAngle($00,$01,$02,$03,$04,$05,$06,$07)
;;;	   replacing those values with your actual values.;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotAim:
LDA #$05
STA $19

LDA !shotBullets
EOR #$01
STA !shotBullets
LDX #$00
FindLoopPoint3:
INX 
STZ !numOfBullets

CPX #$45
BEQ BulletSlotNotAvailable3
CPX #$46
BEQ BulletSlotNotAvailable3				;$140B

LDA !bulletType,X

BEQ ExitFindLoop3



CPX #$7F
BNE FindLoopPoint3
BRA NoSlotsAvailable3

ExitFindLoop3:
					;This is where bullets are created.
LDA #$40                
STA $1DF9               ; Play sound effect 
LDA $01
STA !bulletXPos,X
LDA $02
STA !bulletYPos,X
LDA $03
STA !bulletXAccel,X
LDA $04
STA !bulletYAccel,X
;LDA $05
TXA
LSR
LSR
LSR
LSR
CLC
ADC #$0A
STA !bulletType,X
LDA $06
STA !bulletInfo,X
LDA #$07
STA !bulletXFrac,X
STA !bulletYFrac,X

LDA #$01
STA $19
TXA
STA $09

LDA $00
JSR CODE_01BF6A
LDA $00
STA !bulletYSpeed,X
LDA $01
STA !bulletXSpeed,X

NoSlotsAvailable3:
RTS

BulletSlotNotAvailable3:
LDA #$00
STA !bulletType,X
BRL FindLoopPoint3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; aiming routine
; input: accumulator should be set to total speed (x+y), $09 should be bullet index
; output: $00 = y speed, $01 = x speed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE_01BF6A:		STA $01
				REP #$20
				LDA $D3
				CLC
				ADC #$0008
				STA $D3
				SEP #$20
			PHX					;\ preserve sprite indexes of Magikoopa and magic
			PHY					;/
			JSR CODE_01AD42				; $0E = vertical distance to Mario
			STY $02					; $02 = vertical direction to Mario
			LDA $0E					;\ $0C = vertical distance to Mario, positive
			BPL CODE_01BF7C				; |
			EOR #$FF				; |
			CLC					; |
			ADC #$01				; |
CODE_01BF7C:		STA $0C					;/
			JSR SUB_HORZ_POS			; $0F = horizontal distance to Mario
			STY $03					; $03 = horizontal direction to Mario
			LDA $0F					;\ $0D = horizontal distance to Mario, positive
			BPL CODE_01BF8C				; |
			EOR #$FF				; |
			CLC					; |
			ADC #$01				; |
CODE_01BF8C:		STA $0D					;/
			LDY #$00
			LDA $0D					;\ if vertical distance less than horizontal distance,
			CMP $0C					; |
			BCS CODE_01BF9F				;/ branch
			INY					; set y register
			PHA					;\ switch $0C and $0D
			LDA $0C					; |
			STA $0D					; |
			PLA					; |
			STA $0C					;/
CODE_01BF9F:		LDA #$00				;\ zero out $00 and $0B
			STA $0B					; | ...what's wrong with STZ?
			STA $00					;/
			LDX $01					;\ divide $0C by $0D?
CODE_01BFA7:		LDA $0B					; |\ if $0C + loop counter is less than $0D,
			CLC					; | |
			ADC $0C					; | |
			CMP $0D					; | |
			BCC CODE_01BFB4				; |/ branch
			SBC $0D					; | else, subtract $0D
			INC $00					; | and increase $00
CODE_01BFB4:		STA $0B					; |
			DEX					; |\ if still cycles left to run,
			BNE CODE_01BFA7				;/ / go to start of loop
			TYA					;\ if $0C and $0D was not switched,
			BEQ CODE_01BFC6				;/ branch
			LDA $00					;\ else, switch $00 and $01
			PHA					; |
			LDA $01					; |
			STA $00					; |
			PLA					; |
			STA $01					;/
CODE_01BFC6:		LDA $00					;\ if horizontal distance was inverted,
			LDY $02					; | invert $00
			BEQ CODE_01BFD3				; |
			EOR #$FF				; |
			CLC					; |
			ADC #$01				; |
			STA $00					;/
CODE_01BFD3:		LDA $01					;\ if vertical distance was inverted,
			LDY $03					; | invert $01
			BEQ CODE_01BFE0				; |
			EOR #$FF				; |
			CLC					; |
			ADC #$01				; |
			STA $01					;/
CODE_01BFE0:		PLY					;\ retrieve Magikoopa and magic sprite indexes
			PLX					;/
			REP #$20
			LDA $D3
			SEC
			SBC #$0010	
			STA $D3
			SEP #$20
			RTS					; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE_01AD42:		LDY #$00
			PHX 
			LDX $09
				LDA !bulletYPos,X
				CLC
				ADC #$04
				STA !bulletYPos,x
			LDA $D3

			SEC
			SBC !bulletYPos,x
			;CLC
			;ADC #$04
			
			STA $0E
			LDA $D4
			SBC #$00
			BPL Return01AD53
			INY
			
Return01AD53:            	LDA !bulletYPos,X
				SEC
				SBC #$04
				STA !bulletYPos,x
			PLX
			RTS					; return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB_HORZ_POS:       LDY #$00                ;A:25D0 X:0006 Y:0001 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1020 VC:097 00 FL:31642
		    LDX $09
			LDA !bulletXPos,X
			CLC
			ADC #$04
			STA !bulletXPos,x
                    LDA $94                 ;A:25D0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:envMXdiZCHC:1036 VC:097 00 FL:31642
                    SEC                     ;A:25F0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1060 VC:097 00 FL:31642
                    SBC !bulletXPos,x       ;A:25F0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1074 VC:097 00 FL:31642
			;CLC			
			;ADC #$04
			STA $0F             ;A:25F4 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1104 VC:097 00 FL:31642
                    LDA $95                 ;A:25F4 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1128 VC:097 00 FL:31642
                    SBC $14E0,x             ;A:2500 X:0006 Y:0000 D:0000 DB:03 S:01ED P:envMXdiZcHC:1152 VC:097 00 FL:31642
                    BPL LABEL16             ;A:25FF X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1184 VC:097 00 FL:31642
                    INY                     ;A:25FF X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1200 VC:097 00 FL:31642
LABEL16:            	LDA !bulletXPos,X
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
	REP #$30		;16-bit AXY
	ASL A			;$00     = Radius
	TAX			;$01/$02 = Angle ($0000-$01FF)
	LDA $07F7DB,x		;SMW's 16-bit CircleCoords table
	STA $03			;
				;
	SEP #$30		;8bit AXY
	LDA $02			;$02を保存
	PHA			;
	LDA $03			;|sin|を
	STA $4202		;「かけられる数」とする。
	LDA $00			;半径を呼ぶ
	LDX $04			;|sin| = 1.00 だったら計算不要（Rsin = 半径）
	 BNE .IF1_SIN		;
	STA $4203		;半径を「かける数」とする。
	ASL $4216		;出た答えの小数点以下を四捨五入
	LDA $4217		;
	ADC #$00		;
.IF1_SIN			;
	LSR $02			;絶対値を外す
	 BCC .IF_SIN_PLUS	;
				;
	EOR #$FF		;XOR
	INC A			;
	STA $03			;
	 BEQ .IF0_SIN		;
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
	STA $02			;$02を復元
	PLX			;
	PLP			;
	RTL			;Return
;-------------------------------;
;-------------------------------;
COS:	PHP			;
	PHX			;
	REP #$31		;16bit AXY + Carry Clear
	LDA $01			;$01 = θ
	ADC #$0080		;
	AND #$01FF		;
	STA $07			;$07 = θ + 90°
	;LDA $07		;Not needed because A will already be what was just stored
	AND #$00FF		;
	ASL A			;
	TAX			;
	LDA $07F7DB,x		;SMW's 16-bit CircleCoords table
	STA $05			;
				;
	SEP #$30		;
	LDA $05			;|cos|を
	STA $4202		;「かけられる数」とする。
	LDA $00			;半径を呼ぶ
	LDX $06			;|cos| = 1.00 だったら計算不要（Rsin = 半径）
	 BNE .IF1_COS		;
	STA $4203		;半径を「かける数」とする。
	ASL $4216		;出た答えの小数点以下を四捨五入
	LDA $4217		;
	ADC #$00		;
.IF1_COS			;
	LSR $08			;絶対値を外す
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
STZ $0F
LDA $17
AND #$08
BNE DontMoveSlowly
LDA #$02
STA $0E
BRA MovementAdditionEnd
DontMoveSlowly:
LDA #$01
STA $0E

MovementAdditionEnd:
LDA $15
AND #$01
CMP #$01
BNE CheckLeft
REP #$20
LDA $0E
CLC
ADC $94
STA $94
SEP #$20
BRA NowForYSpeed
CheckLeft:
LDA $15
AND #$02
CMP #$02
BNE ZeroXSpeed
REP #$20
LDA $94
SEC
SBC $0E
STA $94
SEP #$20
BRA NowForYSpeed
ZeroXSpeed:

NowForYSpeed:
LDA $15
AND #$04
CMP #$04
BNE CheckUp
REP #$20
LDA $0E
CLC
ADC $96
STA $96
SEP #$20
BRA AndWereDone
CheckUp:
LDA $15
AND #$08
CMP #$08
BNE ZeroYSpeed
REP #$20
LDA $96
SEC
SBC $0E
STA $96
SEP #$20
BRA AndWereDone
ZeroYSpeed:
AndWereDone:


RTS

