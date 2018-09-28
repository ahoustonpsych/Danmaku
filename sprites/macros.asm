
;;;;;;;;;;;;;;;;;;;
; DEBUG           ;
; !debug = $58    ;
; !scratch = $7C  ;
;;;;;;;;;;;;;;;;;;;
macro Debug(Value)
    PHA : PHX : PHY : NOP #4                ; preserve A/X/Y
    LDA <Value>                            ;
    STA !scratch                            ;
    NOP #4                                  ;
    PLY : PLX : PLA : NOP #4                ; restore Y/X/A
endmacro                                    ;
macro DebugInc()                            ;
    PHA : PHX : PHY : NOP #4                ; preserve A/X/Y
    LDA !debug                              ;
    INC A                                   ;
    STA !debug                              ;
    NOP #4                                  ;
    PLY : PLX : PLA : NOP #4                ; restore Y/X/A
endmacro                                    ;
macro DebugDec()                            ;
    PHA : PHX : PHY : NOP #4                ; preserve A/X/Y
    LDA !debug                              ;
    DEC A                                   ;
    STA !debug                              ;
    NOP #4                                  ;
    PLY : PLX : PLA : NOP #4                ; restore Y/X/A
endmacro                                    ;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialize all sprite tables  ;
; $7F0D00 ~ $7F12FF             ;
; $7E0064                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro InitSpriteTables()
    LDX #$ffff                              ;\
.loop                                       ; |
    INX                                     ; |
    LDA #$00                                ; |
    STA !bulletXSpeed,x                     ; | init sprite tables $7F0D00 ~ $7F21FF
    CPX.w #$1500                            ; |
    BNE .loop                               ; |
    SEP #$10                                ; |
    PLX                                     ;/

    REP #$20                                ;
    LDA #$0000                              ;\ init sprite YXPPCCCT properties byte
    STA $64                                 ;/
    ;LDA #$00FF                             ;\
    ;STA $60                                ; | unused
    ;LDA #$00FF                             ; |
    ;STA $62                                ;/
    SEP #$20                                ;

;    SEP #$10                               ;\
;    REP #$20                               ; |
;    STZ $211B                              ; |
;    LDA #$3480                             ; |
;    STA $4300                              ; |
;    LDA #$0D00                             ; |
;    STA $4302                              ; |
;    LDX #$7F                               ; | init sprite tables $7F0D00 ~ $7F21FF
;    STX $4304                              ; | alt method using DMAs
;    LDA #$1500                             ; |
;    STA $4305                              ; |
;    LDX #$01                               ; |
;    STX $420B                              ; |
;    SEP #$20                               ; |
;    PLX                                    ;/
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; moves the boss sprite up & down to give a 'floating' effect ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro BossFloatingSequence(BossYOffset)
        INC <BossYOffset>                   ;\
        LDA <BossYOffset>                   ; |
        CMP #$5a                            ; |
        BNE DontResetBossFloatHeight        ; | FLOATY BOSS
        STZ <BossYOffset>                   ; |
    DontResetBossFloatHeight:               ; |
        PHX                                 ;/
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shoot bullet at a specific direction and speed   ;
; loads args, finds a slot for the bullet, returns ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ShootBulletXY(Xspeed,YSpeed,xPos,yPos,xAccel,yAccel,Type,Info)
    LDA <Xspeed>
    STA $00                                 ; $00 is the x-speed of the bullet
    LDA <YSpeed>
    STA $01                                 ; $01 is the y-speed of the bullet
    LDA <xPos>
    STA $02                                 ; $02 is the initial x-position of the bullet
    LDA <yPos>
    STA $03                                 ; $03 is the initial y-position of the bullet
    LDA <xAccel>
    STA $04                                 ; $04 is the x-acceleration of bullet
    LDA <yAccel>
    STA $05                                 ; $05 is the y-acceleration of the bullet
    LDA <Type>
    STA $06                                 ; $06 is the type of the bullet
    LDA <Info>
    STA $07                                 ; $07 is the extra info for the bullet
    JSR FindBulletSlotXY                    ; Find an OAM slot for the bullet
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shoot bullet at a specific angle                           ;
; Note that <angle> must be a 16-BIT value from 0000 to 01FF ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ShootBulletAngle(Angle,Speed,xPos,yPos,xAccel,yAccel,Type,Info)
    REP #$20
    LDA <Angle>
    STA $01                                 ; $01 is the 16-BIT value of the angle of bullet between $0000 AND $01FF
    SEP #$20
    LDA <Speed>
    STA $00                                 ; $00 is the speed of the bullet
    LDA <xPos>
    STA $03                                 ; $03 is the x-position of the bullet
    LDA <yPos>
    STA $04                                 ; $04 is the y-position of the bullet
    LDA <xAccel>
    STA $05                                 ; $05 is the x-acceleration of the bullet
    LDA <yAccel>
    STA $06                                 ; $06 is the y-acceleration of the bullet
    LDA <Type>
    STA $07                                 ; $07 is the type of the bullet
    LDA <Info>
    STA $08                                 ; $08 is the extra info for the bullet
    JSR FindBulletSlotAngle                 ; Find an OAM slot for the bullet
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shoot bullet toward mario ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ShootBulletToMario(Speed,xPos,yPos,xAccel,yAccel,Type,Info)
    LDA <Speed>
    STA $00                                 ; $00 is the speed of the bullet
    LDA <xPos>
    STA $01                                 ; $01 is the x-position of the bullet
    LDA <yPos>
    STA $02                                 ; $02 is the y-position of the bullet
    LDA <xAccel>
    STA $03                                 ; $03 is the x-acceleration of the bullet
    LDA <yAccel>
    STA $04                                 ; $04 is the y-acceleration of the bullet
    LDA <Type>
    STA $05                                 ; $05 is the type of the bullet
    LDA <Info>
    STA $06                                 ; $06 is the extra info for the bullet
    JSR FindBulletSlotAim                   ; Find an OAM slot for the bullet
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this is so dumb                                            ;
; determines which attack subroutine to call based on 'Card' ;
; NOTE: expand as needed when more spellcards are added      ;
; TODO: this would be way less disgusting with a ptr table   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro CallAttackSubroutine(Card)
    ;%DebugInc()                            ; debug
    %Debug(<Card>+1)                        ; debug
    LDA <Card>                              ;\  If not attack 0
    BNE .notattack0                         ; | Go to attack 1
    JMP Attack0                             ;/  Else, go to attack 0

.notattack0
    CMP #$01                                ;\  If not attack 1
    BNE .notattack1                         ; | Go to attack 2
    JMP Attack1                             ;/  Else, go to attack 1

.notattack1
    CMP #$02                                ;\  If not attack 2
    BNE .notattack2                         ; | Go to attack 3
    JMP Attack2                             ;/  Else, go to attack 2

.notattack2
    CMP #$03                                ;\  If not attack 3
    BNE NoAttacks                           ; | Restart the routine
    JMP Attack3                             ;/  Else, go to attack 3

NoAttacks:
    JMP MainRoutineStart                    ; Skip attack sequence if out of cards
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; updates bullet X/Y speeds and positions  ;
; based on XY acceleration & subpixels     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro BulletSpeedPositionUpdate()
    %Debug(#$BA)                            ;
    LDA !bulletYSpeed,x                     ;
    BMI YSpeedIsNegative                    ;
    CLC                                     ;\
    ADC !bulletYFrac,x                      ; | Add y-speed to y-subpixel
    STA !bulletYFrac,x                      ;/
    LSR                                     ;\
    LSR                                     ; |
    LSR                                     ; |
    LSR                                     ; | Add y-subpixel to y-position if subpixel >16
    CLC                                     ; |
    ADC !bulletYPos,x                       ; |
    BCS DeleteBulletYbranch                 ; |
    STA !bulletYPos,x                       ;/
    CMP #$f0                                ;
    BCS DeleteBulletYbranch                 ;

    LDA !bulletYFrac,x                      ;\
    CMP #$10                                ; |
    BCC DontResetYFrac                      ; | Reset y-subpixel if >16
    LDA !bulletYFrac,x                      ; |
    AND #$0f                                ; |
    STA !bulletYFrac,x                      ; |
    BRA DontResetYFrac                      ;/

DeleteBulletYbranch:
    BRL DeleteBulletXbranch

YSpeedIsNegative:
    CLC                                     ;\
    ADC !bulletYFrac,x                      ; | Add y-speed to y-subpixel
    STA !bulletYFrac,x                      ;/
    CMP #$10                                ;\
    BCC DontUpdateYPos                      ; |
    STA $00                                 ;/
    ;AND #$f0                               ;
    LSR                                     ;\
    LSR                                     ; |
    LSR                                     ; |
    LSR                                     ; |
    EOR #$0f                                ; |
    INC                                     ; | Subtract y-subpixel from y-position if >16
    STA $01                                 ; |
    LDA !bulletYPos,x                       ; |
    SEC                                     ; |
    SBC $01                                 ; |
    BCC DeleteBulletYbranch                 ; |
    STA !bulletYPos,x                       ;/
    LDA $00                                 ;\
    AND #$0f                                ; | Reset y-subpixel
    STA !bulletYFrac,x                      ;/

DontUpdateYPos:
DontResetYFrac:                             ; I had to recode this section multiple times,
DontResetYFrac2:                            ; AND I was too lazy to swap out the old labels.
    LDA !bulletYAccel,x                     ;\
    ;BMI YAccelIsNegative                   ; |
    CLC                                     ; | Add bullet y-acceleration to y-speed
    ADC !bulletYSpeed,x                     ; |
    ;BCS DoneWithYAccel                     ; |
    STA !bulletYSpeed,x                     ;/
    ;BRA DoneWithYAccel                     ;
                                            ;
    ;YAccelIsNegative:                      ;
    ;CLC                                    ;
    ;ADC !bulletYSpeed,x                    ;
    ;BCC DoneWithYAccel                     ;
    ;STA !bulletYSpeed,x                    ;

DoneWithYAccel:                             ; Now we handle horizontal movement
    LDA !bulletXSpeed,x                     ;\
    BMI XSpeedIsNegative                    ; |
    CLC                                     ; | Add x-speed to x-subpixel
    ADC !bulletXFrac,x                      ; |
    STA !bulletXFrac,x                      ;/
    LSR                                     ;\
    LSR                                     ; |
    LSR                                     ; |
    LSR                                     ; | Add x-subpixel to x-position if subpixel >16
    CLC                                     ; |
    ADC !bulletXPos,x                       ; |
    BCS DeleteBulletXbranch                 ; |
    STA !bulletXPos,x                       ;/

    LDA !bulletXFrac,x                      ;\
    CMP #$10                                ; |
    BCC DontResetXFrac                      ; |
    LDA !bulletXFrac,x                      ; | Reset x-subpixel
    AND #$0f                                ; |
    STA !bulletXFrac,x                      ; |
    BRA DontResetXFrac                      ;/

XSpeedIsNegative:
    CLC                                     ;\
    ADC !bulletXFrac,x                      ; | Add x-speed to x-subpixel
    STA !bulletXFrac,x                      ;/
    CMP #$10                                ;\
    BCC DontUpdateXPos                      ; |
    STA $00                                 ;/
    ;AND #$f0                               ;
    LSR                                     ;\
    LSR                                     ; |
    LSR                                     ; |
    LSR                                     ; |
    EOR #$0f                                ; |
    INC                                     ; | Subtract x-subpixel from x-position
    STA $01                                 ; |
    LDA !bulletXPos,x                       ; |
    SEC                                     ; |
    SBC $01                                 ; |
    BCC DeleteBulletXbranch                 ; |
    STA !bulletXPos,x                       ;/
    LDA $00                                 ;\
    AND #$0f                                ; | Reset x-subpixel
    STA !bulletXFrac,x                      ; |
    BRA DontUpdateXPos                      ;/

DeleteBulletXbranch:
    LDA #$00                                ;\ Delete bullet (type #$00)
    STA !bulletType,x                       ;/

DontUpdateXPos:
DontResetXFrac:
DoneMessingWithXSpeed:
    LDA !bulletXAccel,x                     ;\
    CLC                                     ; | Add bullet x-acceleration to x-speed
    ADC !bulletXSpeed,x                     ; |
    STA !bulletXSpeed,x                     ;/

    ;LDA !bulletYPos,x                      ;\
    ;CMP #$F0                               ; |
    ;BCC IsntOutOfBounds                    ; | unused. delete bullet if out of bounds vertically
    ;LDA #$00                               ; |
    ;STA !bulletType,x                      ;/

IsntOutOfBounds:
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;
; hit detection handler ;
; does not return       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
macro HitDetection()
    CPX #$00                                ;\
    BNE IsntZero                            ; | Process hit detection for all bullets
    LDA !bulletType,x                       ; |
    BEQ IsntZero                            ;/
    STZ $0d9c                               ;

    ;LDA $0d9c                              ;\
    ;BNE FirstHalf                          ; |
SecondHalf:                                 ; |
    ;INC $0d9c                              ; | unused
    ;BRA IsntZero                           ; | tries to process half of the bullets' hit detection every other frame
FirstHalf:                                  ; |
    ;STZ $0d9c                              ; |
    ;BRA EndHitDetection                    ;/

IsntZero:
    TXA                                     ;\
    EOR $13                                 ; | Process hit detection every other frame
    AND #$01                                ; |
    BNE EndHitDetection                     ;/
    LDA !bulletXPos,x                       ;\
    STA !bulletLocation                     ; |
    STZ !bulletLocation+1                   ; |
    REP #$21                                ; | Update bulletLocation x-position
    LDA !bulletLocation                     ; |
    ;CLC                                    ; |
    ADC #$0004                              ; |
    STA !bulletLocation                     ;/

    LDA $94                                 ;\
    CLC                                     ; |
    ADC #$0007                              ; |
    SEC                                     ; |
    SBC !bulletLocation                     ; | Detect if bullet will be within 2 pixels of mario (next frame)
    BMI XResultIsNegative                   ; |
    CMP #$0004                              ; |
    BCS DontHurtMario                       ; |
    BRA MaybeHurtMario                      ; |
                                            ; |
XResultIsNegative:                          ; |
    EOR #$ffff                              ; |\
    INC                                     ; | | Negative x-speed handler (bullet to left of mario)
    CMP #$0007                              ; | |
    BCS DontHurtMario                       ;/ /

MaybeHurtMario:
    LDA !bulletYPos,x                       ;\
    STA !bulletLocation                     ; |
    STZ !bulletLocation+1                   ; |
    REP #$21                                ; | Update !bulletLocation y-position
    LDA !bulletLocation                     ; |
    ;CLC                                    ; |
    ADC #$0004                              ; |
    STA !bulletLocation                     ;/

    LDA $96                                 ;\
    CLC                                     ; |
    ADC #$0013                              ; |
    SEC                                     ; |
    SBC !bulletLocation                     ; | Detect if bullet y-position will be within 2 pixels of mario (next frame)
    BMI YResultIsNegative                   ; |
    CMP #$0004                              ; |
    BCS DontHurtMario                       ; |
    BRA HurtMario                           ; |
                                            ; |
YResultIsNegative:                          ; |
    EOR #$ffff                              ; |\
    INC                                     ; | | Negative y-speed handler (bullet above mario)
    CMP #$0007                              ; | |
    BCS DontHurtMario                       ;/ /

HurtMario:
    SEP #$20                                ;\ Damage mario if touching bullet
    JSL $00f5b7                             ;/

DontHurtMario:
    SEP #$20                                ;

EndHitDetection:
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Write bullet data to OAM        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro BulletGraphics()
    %Debug(#$50)                            ; debug
    LDA !bulletType,x                       ;\ Only process bullets that exist
    BEQ NoGraphicsToShow                    ;/

    CMP #$44                                ;\
    BEQ NoGraphicsToShow                    ; | Protection against overwriting mario's sprite slots with bullets
    CMP #$45                                ; |
    BEQ NoGraphicsToShow                    ;/

    REP #$10                                ;

    LDA !bulletXPos,x                       ;\ Update sprite x-pos
    STA $0204,y                             ;/

    LDA !bulletYPos,x                       ;\ Update bullet y-pos
    STA $0205,y                             ;/

DrawBulletTile:
    LDA !bulletType,x                       ;\ Update bullet type (tile number)
    STA $0206,y                             ;/

    LDA #$3d                                ;\ Palette 0x0E (0b0011101)
    STA $0207,y                             ;/
    INY                                     ;\
    INY                                     ; | Prepare OAM pointer for next bullet (+4 bytes)
    INY                                     ; |
    INY                                     ;/
    SEP #$10                                ;

NoGraphicsToShow:
    ;PLY                                    ;
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Write boss data to OAM  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro BossGraphics()
    LDA $0e                                 ;\
    CMP #$01                                ; | Show mario's hitbox if pressing B
    BNE DontShowHitbox                      ;/  TODO: remove if too OP. sort of cheating imo

    LDA $7e                                 ;\
    CLC                                     ; | Set boss x-position = mario's x-position + 4
    ADC #$04                                ; |
    STA !hitBoxOAM                          ;/

    LDA $80                                 ;\
    CLC                                     ; | Set boss y-position = mario's y-position + 16
    ADC #$10                                ; |
    STA !hitBoxOAM+1                        ;/

    LDA #$1f                                ;\ Set boss tile number
    STA !hitBoxOAM+2                        ;/

    ;LDA #$3d                                ;\ Palette 0x0E?
    LDA #$38                                ;\ Palette 0x0C
    STA !hitBoxOAM+3                        ;/

DontShowHitbox:
    LDY #$02                                ;\
    TXA                                     ; | finish OAM write
    PLX                                     ; | #$02 = 16x16 tiles
    JSL $01B7B3                             ;/
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET_DRAW_INFO                                                                         ;
; This is a helper for the graphics routine.  It sets off screen flags, AND sets up     ;
; variables.  It will return with the following:                                        ;
;                                                                                       ;
;       Y = index to sprite OAM ($300)                                                  ;
;       $00 = sprite x position relative to screen boarder                              ;
;       $01 = sprite y position relative to screen boarder                              ;
;                                                                                       ;
; It is adapted from the subroutine at $03B760                                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro GetDrawInfo()
SPR_T1:     db $0C,$1C                      ;
SPR_T2:     db $01,$02                      ;

    %Debug(#$64)                            ; debug

    STZ $186C,x                             ; reset sprite offscreen flag, vertical
    STZ $15A0,x                             ; reset sprite offscreen flag, horizontal
    LDA $E4,x                               ;\
    CMP $1A                                 ; | set horizontal offscreen if necessary
    LDA $14E0,x                             ; |
    SBC $1B                                 ; |
    BEQ ON_SCREEN_X                         ; |
    INC $15A0,x                             ;/

ON_SCREEN_X:
    %Debug(#$65)                            ; debug
    LDA $14E0,x                             ;\
    XBA                                     ; |
    LDA $E4,x                               ; |
    REP #$20                                ; |
    SEC                                     ; |
    SBC $1A                                 ; |
    CLC                                     ; | mark sprite invalid if far enough off screen
    ADC #$0040                              ; |
    CMP #$0180                              ; |
    SEP #$20                                ; |
    ROL A                                   ; |
    AND #$01                                ; |
    STA $15C4,x                             ; |
    BEQ VALID                               ; |
    BRL INVALID                             ;/

VALID:
    LDY #$00                                ;\ set up loop:
    LDA $1662,x                             ; |
    AND #$20                                ; | if not smushed (1662 & 0x20), go through loop twice
    BEQ ON_SCREEN_LOOP                      ; | else, go through loop once
    INY                                     ;/
ON_SCREEN_LOOP:
    %Debug(#$66)                            ; debug
    LDA $D8,x                               ;\
    CLC                                     ; | set vertical offscreen if necessary
    ADC SPR_T1,y                            ; |
    PHP                                     ; |
    CMP $1C                                 ; | (vert screen boundry)
    ROL $00                                 ; |
    PLP                                     ; |
    LDA $14D4,x                             ; |
    ADC #$00                                ; |
    LSR $00                                 ; |
    SBC $1D                                 ; |
    BEQ ON_SCREEN_Y                         ; |
    LDA $186C,x                             ; | (vert offscreen)
    ORA SPR_T2,y                            ; |
    STA $186C,x                             ; |
ON_SCREEN_Y:                                ; |
    %Debug(#$67)                            ; debug
    DEY                                     ; |
    BPL ON_SCREEN_LOOP                      ;/

    LDY $15EA,x                             ; get offset to sprite OAM
    LDA $E4,x                               ;\
    SEC                                     ; |
    SBC $1A                                 ; | $00 = sprite x position relative to screen boarder
    STA $00                                 ;/
    LDA $D8,x                               ;\
    SEC                                     ; |
    SBC $1C                                 ; | $01 = sprite y position relative to screen boarder
    STA $01                                 ;/
    %Debug(#$68)                            ; debug
    ;RTS                                     ; return normally. use RTS if not in a macro
    BRA END                                 ;

INVALID:
    %Debug(#$69)                            ; debug
    PLA                                     ;\  if invalid sreturn from *main gfx routine* subroutine
    PLA                                     ; | (not just this subroutine)
    RTS                                     ;/  use RTS if not in a macro
END:
endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Draw Boss Tiles                      ;
; Stores tile data to OAM slots        ;
; bullets & boss                       ;
; OAM Slot Format:                     ;
; xxxxxxxx yyyyyyyy tttttttt yxppccct  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro GraphicsLoop()
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; if you wish to draw more than one tile
    ; each step between the lines must be repeated
    ;*************************************************************************************
    LDX #$FF                                ;
GraphicsLoop:
    INX                                     ; move to next tile
    %Debug(#$75)                            ; debug
    LDA $00                                 ;\
    CLC                                     ; | offset x-position by Xoffsets
    ADC Xoffsets,x                          ; | set tile x-position
    STA $0300,y                             ;/

    LDA $01                                 ;\
    CLC                                     ; |
    ADC Yoffsets,x                          ; | offset y-position by Yoffsets
    PHY                                     ; | set tile y-position
    LDY !bossYOffset                        ; |\
    CLC                                     ; | |
    ADC KYoffset,y                          ; | | offset y-position by KYoffset
    PLY                                     ; | |
    STA $0301,y                             ;/ /

DrawBossTile:
    %Debug(#$58)                            ; debug
    LDA Tiles,x                             ;\ set tile numbers
    STA $0302,y                             ;/

    LDA #$09                                ; Palette #$0C
    STA $0303,y                             ; (0b00011111)

    INY                                     ;\
    INY                                     ; |
    INY                                     ; | move to the next sprite slot index (necessary to draw another tile)
    INY                                     ; |
    CPX #$0F                                ; |\ loop until all tiles are set up
    BNE GraphicsLoop                        ;/ / (currently one 16x16 tile)
    ;*************************************************************************************

    %Debug(#$71)                            ; debug
    LDY #$02                                ;\
    TXA                                     ; | #$02 = drew one tile
    PLX                                     ;/

    JSL $01B7B3                             ; jump to OAM write finish routine
endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mario Movement Handler                        ;
; Handles movements and 'focus'                 ;
; focus = finer movement control if holding B   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro MarioMovement()
MariosMovementRoutine:
    STZ $0f                                 ;
    LDA $17                                 ;\
    AND #$08                                ; | if holding B...
    BNE SetFocus                            ; | ...enable "focus"
    LDA #$02                                ; | $0e = pixels to move each frame
    STA $0e                                 ;/  Default: 2 pixels per frame
    BRA MovementAdditionEnd                 ;
SetFocus:
    LDA #$01                                ;\ focus on
    STA $0e                                 ;/ mario speed = 1 pixel per frame

MovementAdditionEnd:
CheckRight:
    LDA $15                                 ;\
    AND #$01                                ; | check if pressing right
    BEQ CheckLeft                           ;/
    REP #$20                                ;
    LDA $0e                                 ;\
    CLC                                     ; | add 'focus value' to x-position
    ADC $94                                 ; |
    STA $94                                 ;/
    SEP #$20                                ;
    BRA NowForYSpeed                        ;

CheckLeft:
    LDA $15                                 ;\
    AND #$02                                ; | check if pressing left
    BEQ ZeroXSpeed                          ;/
    REP #$20                                ;
    LDA $94                                 ;\
    SEC                                     ; | subtract 'focus value' from x-position
    SBC $0e                                 ; |
    STA $94                                 ;/
    SEP #$20                                ;
    BRA NowForYSpeed                        ;

ZeroXSpeed:
NowForYSpeed:
CheckDown:
    LDA $15                                 ;\
    AND #$04                                ; | check if pressing down
    BEQ CheckUp                             ;/
    REP #$20                                ;
    LDA $0e                                 ;\
    CLC                                     ; | add 'focus value' to y-position
    ADC $96                                 ; |
    STA $96                                 ;/
    SEP #$20                                ;
    BRA andWereDone                         ;

CheckUp:
    LDA $15                                 ;\
    AND #$08                                ; | check if pressing down
    BEQ ZeroYSpeed                          ;/
    REP #$20
    LDA $96                                 ;\
    SEC                                     ; | subtract 'focus value' from y-position
    SBC $0e                                 ; |
    STA $96                                 ;/
    SEP #$20                                ;
    BRA andWereDone                         ; return

ZeroYSpeed:
andWereDone:
endmacro