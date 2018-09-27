;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Danmaku Boss (Modified Original)
;    Original WIP by Kipernal
;    Heavily modified by TheGreekBrit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;
; IMPORTS ;
;;;;;;;;;;;
incsrc sprites/defines.asm                  ; import variables & data tables
incsrc sprites/macros.asm                   ; import functions
incsrc sprites/routines.asm                 ;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT AND MAIN JSL targets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    print pc," INIT"                        ;
    JSR INIT                                ;\ run INIT routine
    RTL                                     ;/

    print pc," MAIN"                        ;
    PHB                                     ;
    PHK                                     ;
    PLB                                     ;
    JSR MAIN                                ; Main routine
    STZ $0313                               ; Fixes a bug with Mario's YXPPCCCT OAM slots
    STZ $0317                               ; Fixes a bug with Mario's YXPPCCCT OAM slots
    ;STZ $0d9c                              ;
    PLB                                     ;\ return from boss routines
    RTL                                     ;/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;INITIALIZE
; clear state
; set idle timer
; set global timer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT:
    STZ !state                              ; state 0 (doesn't exist)
    STZ !currentCard                        ; Card 0 (INIT, does nothing)
    LDA #$80                                ;
    STA !stateTimer                         ; Countdown before the boss starts shooting
    PHX                                     ;
    REP #$10                                ;
    LDX #$00f0                              ;
    STX !timer                              ;
    ;STZ $0D9C                              ;

    %InitSpriteTables()

    RTS                                     ; finish init

MAIN:
    DEC !stateTimer                         ;\
    LDA !stateTimer                         ; | kick off main thread if state timer is still counting
    BNE stateTimerIsnt0                     ;/
    LDA #$02                                ;\
    STA !state                              ;/ begin firing bullets

stateTimerIsnt0:
    LDA !state                              ;\
    CMP #$03                                ; | Handle death sequence if mario is dying
    BEQ MarioHasDiedMovement                ;/
    JSR MariosMovementRoutine               ; Handle general mario movements
    BRA SkipMarioHasDiedMovement            ;

MarioHasDiedMovement:
    REP #$20                                ;
    DEC $96                                 ; Decrease mario's y-position every frame he's dying
    SEP #$20                                ;
    DEC !stateTimer                         ;

SkipMarioHasDiedMovement:
    %BossFloatingSequence(!bossYOffset)     ; FLOATY BOSS!

    LDA !state                              ;\
    CMP #$02                                ; | Wait until it's time to begin the spellcard
    BEQ RunSpellCards                       ; |
    BRL dontRunSpellCards                   ;/



;macro ShootBulletXY(Xspeed,YSpeed,xPos,yPos,xAccel,yAccel,Type,Info)
;macro ShootBulletAngle(Angle,Speed,xPos,yPos,xAccel,yAccel,Type,Info)    ; Note that <angle> must be a 16-BIT value from 0000 to 01FF
;macro ShootBulletToMario(Speed,xPos,yPos,xAccel,yAccel,Type,Info)

;$00                                        ; Radius
;$01 $02                                    ; Angle, from 0-1FF


    print pc," Begin RunSpellCards"
RunSpellCards:
    ;LDA #$0A                               ;
    ;STA $00                                ; radius
    ;STZ $02                                ;\
    ;LDA #$40                               ; | angle
    ;STA $01                                ;/
    ;JSR CODE_01BF6A                        ;
    ;JSL SIN                                ;
    ;LDA #$01                               ;
    ;STA $19                                ;

    LDA $13                                 ;\  TODO maybe use $14 due to pause abuse
    AND #$07                                ; |
    CMP #$07                                ; |
    BEQ BeginAttacks                        ; | wait 8 frames
    REP #$30                                ; |
    DEC !timer                              ; |
    SEP #$30                                ;/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; JMPs to current attack subroutine               ;
; or MainRoutineStart, if there are no attacks    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BeginAttacks:
    %CallAttackSubroutine(!currentCard)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Bullet Shooting/Spellcard Routine               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    print pc," Begin Attacks ",!currentCard

; all attacks except the second are the same currently
;Spellcard0:
Attack0:
Attack2:
Attack3:
    REP #$20                                ;
    LDA !timer                              ;\
    CMP #$ffff                              ; | End spellcard if master timer over/underflows
    BNE DontEndCard01                       ;/

; cleanup routine
; prepares for next spellcard
CardFinished0:
    STZ !angle1                             ;\
    STZ !angle2                             ; |
    LDA #$00ff                              ; | clear angle data
    STA !angle3                             ; |
    STA !angle4                             ;/
    SEP #$20                                ;

    STZ !state                              ; Stop firing bullets
    REP #$20                                ;
    LDA #$00ff                              ; This is the amount of time the next spellcard will last for.
    STA !timer                              ;
    SEP #$20                                ;
    LDA #$f0                                ; This is the amount of time before the boss starts firing again
    STA !stateTimer                         ;
    INC !currentCard                        ; Next spellcard

DontEndCard01:
    SEP #$20                                ;\ \
    LDA $13                                 ; | |
    AND #$07                                ; | | shoot bullets every 8 frames
    ; CMP #$07                              ; | |
    BEQ Spell01PrematureEnd2                ; |/
                                            ; |   Alternate between horizontal/vertical shots every 8 frames
    LDA $13                                 ; |\
    AND #$0f                                ; | | shoot horizontal shot every 16 frames
    ; CMP #$0f                              ; | |
    BEQ DoHorizontalShot                    ;/ /

    STZ $0D9C
    LDA $7e                                 ;\
    CLC                                     ; | Calculate the player's x-position
    ADC #$02                                ; |
    STA $0f                                 ;/  $0F is the player's current x-position, plus two (hitbox I guess)

    ;ShootBulletXY(Xspeed,YSpeed,xPos,YPos,xAccel,YAccel,Type,Info)
    ; First spellcard; set up all of the initial bullet settings
    ; shoots at the same x-pos as mario (vertical shot)
    %ShootBulletXY(#$00,#$1D,$0f,#$00,#$00,#$00,#$0A,#$00)
    BRA SkipThisThingy01

DoHorizontalShot:
    STZ $0D9C                               ;\
    LDA $80                                 ; |
    CLC                                     ; | Calculate player's y-position
    ADC #$10                                ; |
    STA $0f                                 ;/  $0F is the player's current y-position, plus two (hitbox I guess)

    ;ShootBulletXY(Xspeed,YSpeed,xPos,YPos,xAccel,YAccel,Type,Info)
    ; shoots at the same y-pos as mario (horizontal shot)
    %ShootBulletXY(#$1d,#$00,#$00,$0f,#$00,#$00,#$08,#$00)
    BRA SkipThisThingy01

Spell01PrematureEnd2:
    BRL Spell01PrematureEnd

SkipThisThingy01:
    LDA $13                                 ;\
    AND #$0f                                ; | Shoot once every 16 frames
    CMP #$0f                                ; |
    BNE Spell01PrematureEnd2                ;/

    ;ShootBulletXY(Xspeed,YSpeed,xPos,YPos,xAccel,YAccel,Type,Info)
    ; shoot bullets at various speeds every 16 frames
    %ShootBulletXY(#$00,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)            ;\
    %ShootBulletXY(#$07,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)            ; |
    %ShootBulletXY(#$10,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)            ; | Set up the spellcard
    %ShootBulletXY(#$F8,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)            ; |
    %ShootBulletXY(#$F0,#$E0,#$7F,#$30,#$00,#$01,#$0A,#$00)            ;/

    ;ShootBulletAngle(Angle,Speed,xPos,YPos,xAccel,YAccel,Type,Info)
    ; %ShootBulletAngle(!angle1,$0e,#$7f,#$30,#$00,#$00,#$0a,#$00)
    ; %ShootBulletAngle(!angle2,$0e,#$7f,#$30,#$00,#$00,#$0a,#$00)
    ; %ShootBulletAngle(!angle3,$0e,#$7f,#$30,#$00,#$00,#$0a,#$00)
    ; %ShootBulletAngle(!angle4,$0e,#$7f,#$30,#$00,#$00,#$0a,#$00)

;     REP #$20

;     LDA !angle1                           ;
;     CLC                                   ;
;     ADC #$0005                            ; increase angle by #$0005 every shot
;     STA !angle1                           ;
;     CMP #$0200                            ; Check if angle overflowed
;     BCC DontResetAngle1                   ; If not, let it continue
;     STZ !angle1                           ; Else, reset angle
; DontResetAngle1:

;     LDA !angle2                           ;
;     SEC                                   ;
;     SBC #$0005                            ; decrease angle by #$0005 every shot
;     STA !angle2                           ;
;     BCS DontResetAngle2                   ;
;     LDA #$01FF                            ;
;     STA !angle2                           ;
; DontResetAngle2:


;     LDA !angle3
;     CLC                                   ;
;     ADC #$0005                            ; increase angle by #$0005 every shot
;     STA !angle3
;     CMP #$0200
;     BCC DontResetAngle3
;     STZ !angle3
; DontResetAngle3:

;     LDA !angle4
;     SEC
;     SBC #$0005                            ; decrease angle by #$0005 every shot
;     STA !angle4
;     BCS DontResetAngle4
;     LDA #$01ff
;     STA !angle4
; DontResetAngle4:

;     SEP #$20

    ;%ShootBulletAngle(!angle,#$07,#$7F,#$7F,#$FF,#$FF,#$0A,#$00)
    ;%ShootBulletAngle(!angle2,#$07,#$7F,#$7F,#$03,#$03,#$0A,#$00)

Spell01PrematureEnd:
    JMP DoneFiring                          ; Always call this at the end of a spellcard!!


;Spellcard1:
Attack1:
    REP #$20                                ;\
    LDA !timer                              ; |
    CMP #$ffff                              ; | End spellcard if time has run out
    BNE DontEndCard02                       ; |
    SEP #$20                                ;/
    STZ !state                              ; Set idle
    REP #$20                                ;\
    LDA #$0050                              ; | Next spellcard duration
    STA !timer                              ;/
    SEP #$20                                ;
    LDA #$f0                                ;\ Idle time
    STA !stateTimer                         ;/
    INC !currentCard                        ; Begin next spellcard next frame

DontEndCard02:
    REP #$20                                ;\
    LDA !timer                              ; | Fire slower bullets for the first second or so of this attack
    CMP #$0078                              ; |
    BCS WaitLonger                          ;/

    SEP #$20                                ;
    LDA #$2f                                ;\ Set bullet speed
    STA $0e                                 ;/

    LDA $13                                 ;\
    AND #$07                                ; | Shoot bullets every 8 frames
    ; CMP #$07                              ; |
    BEQ Spell02PrematureEnd2                ;/
                                            ;
    BRA SkipThisThingy02                    ;

WaitLonger:
    SEP #$20                                ;
    LDA #$17                                ;\ Set bullet speed
    STA $0e                                 ;/

    LDA $13                                 ;\
    AND #$0f                                ; | Shoot bullets every 16 frames
    ; CMP #$0f                              ; |
    BEQ Spell02PrematureEnd2                ;/
                                            ;
    BRA SkipThisThingy02                    ;

Spell02PrematureEnd2:
    BRL Spell02PrematureEnd

SkipThisThingy02:
    LDA $80                                 ;\
    CLC                                     ; | Calculate player's y-pos
    ADC #$10                                ; |
    STA $0f                                 ;/  $0F is the player's current y-position, plus two (hitbox I guess)

    ; shoot horizontal bullets toward mario
    %ShootBulletXY(#$1d,#$00,#$00,$0f,#$00,#$00,#$08,#$00)

    ;ShootBulletAngle(Angle,Speed,xPos,YPos,xAccel,YAccel,Type,Info)
    ;%ShootBulletAngle(!angle1,$0e,#$7f,#$30,#$00,#$00,#$08,#$00)
    ;%ShootBulletAngle(!angle2,$0e,#$7f,#$30,#$00,#$00,#$08,#$00)
    ;%ShootBulletAngle(!angle3,$0e,#$7f,#$30,#$00,#$00,#$08,#$00)
    ;%ShootBulletAngle(!angle4,$0e,#$7f,#$30,#$00,#$00,#$08,#$00)

    REP #$20
    LDA !angle1                             ;\
    CLC                                     ; |
    ADC #$0005                              ; |
    STA !angle1                             ; | increase angle by #$0005 every shot
    CMP #$0200                              ; |\
    BCC .DontResetAngle1                    ; | | prevent overflow
    STZ !angle1                             ;/ /

.DontResetAngle1
    LDA !angle2                             ;\
    SEC                                     ; |
    SBC #$0005                              ; |
    STA !angle2                             ; | decrease angle by #$0005 every shot
    BCS .DontResetAngle2                    ; |\
    LDA #$01ff                              ; | | prevent underflow
    STA !angle2                             ;/ /

.DontResetAngle2
    LDA !angle3                             ;\
    CLC                                     ; |
    ADC #$0005                              ; |
    STA !angle3                             ; | increase angle by #$0005 every shot
    CMP #$0200                              ; |\
    BCC .DontResetAngle3                    ; | | prevent overflow
    STZ !angle3                             ;/ /

.DontResetAngle3
    LDA !angle4                             ;\
    SEC                                     ; |
    SBC #$0005                              ; |
    STA !angle4                             ; | decrease angle by #$0005 every shot
    BCS .DontResetAngle4                    ; |\
    LDA #$01ff                              ; | | prevent underflow
    STA !angle4                             ;/ /

.DontResetAngle4
    SEP #$20                                ;

Spell02PrematureEnd:
    JMP DoneFiring                          ;



dontRunSpellCards:

























;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Bullet Shooting/Spellcard Routine               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DoneFiring:
    LDA $71                                 ;\
    BNE DontUseSpeedUpThingy                ; |
    LDA #$01                                ; | Skip all mario animations
    STA $9d                                 ; | Required to speed up the game
    BRA UsedSpeedUpThingy                   ; |
DontUseSpeedUpThingy:                       ; |
    STZ $9d                                 ;/



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Heart of the routine                                                              ;
; Loops through every bullet and decide its movement, proximity to Mario, etc.      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MainRoutineStart:

UsedSpeedUpThingy:
    ;PHY
    REP #$10
    LDX #$0000
    SEP #$10

MainLoopPoint:
    ;STZ $0d9c
    INX
    LDA #$FF                                ;\
    INC                                     ; | Reset carry?
    LDA #$00                                ; |
    DEC                                     ;/

    ;CPX #$3F                               ;\
    ;BNE .continue                          ; | unused. presumably loop through all slots then process graphics.
    ;BRL BossGraphics                       ;/

.continue
    LDA !bulletType,x                       ;\ Only process bullets that actually exist
    BEQ MainLoopPoint                       ;/

    %BulletSpeedPositionUpdate()            ; updates bullets' speed & position based on acceleration & subpixels



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Hit Detection Routine       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    %HitDetection()                         ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End Hit Detection Routine   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Bullet graphics routine     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    %BulletGraphics()                       ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End Bullet Graphics Routine ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Boss Graphics Routine       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    %BossGraphics()                         ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End Boss Graphics Routine   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Generic Graphics Routine    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB_GFX:
    JSR GET_DRAW_INFO                       ; after returning:
                                            ; Y = index to sprite OAM ($300)
                                            ; $00 = sprite x position relative to screen border
                                            ; $01 = sprite y position relative to screen border

    PHX                                     ;
    %GraphicsLoop()                         ;\ draw boss graphics (16x16)
    RTS                                     ;/



GET_DRAW_INFO:
    %GetDrawInfo()                          ;\ graphics helper. either returns to GraphicsLoop above
    RTS                                     ;/ or returns from GFX routine if invalid (offscreen) sprites are detected

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End Generic Graphics Routine ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mario Movement Routine       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    %MarioMovement()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End Mario Movement Routine   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End Boss Main                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    RTS

