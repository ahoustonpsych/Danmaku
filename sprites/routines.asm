

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find Bullet OAM Slot                           ;
; TODO: split into three routines                ;
; TODO: they all bleed into each other currently ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.                         ;;;
;;;Essentially, call this whenever a shot is fired.                 ;;;
;;;Use JSR FindBulletSlotXY or the macro below.                     ;;;
;;;                                                                 ;;;
;;;To use, load the initial X speed into $00                        ;;;
;;;        load the initiay Y speed into $01                        ;;;
;;;       load the initial x pos.  into $02                         ;;;
;;;       load the initial y pos.  into $03                         ;;;
;;;       load the initial x accel into $04                         ;;;
;;;       load the initial y accel into $05                         ;;;
;;;       load the initial type    into $06                         ;;;
;;;       load any  extra  info  into   $07                         ;;;
;;;                                                                 ;;;
;;;       This is macro-ified for easier coding.  To use,           ;;;
;;;       type %ShootBulletXY($00,$01,$02,$03,$04,$05,$06,$07)      ;;;
;;;       replacing those values with your actual values.           ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotXY:
    STZ !numOfBullets                       ;\
    LDA !shotBullets                        ; |
    EOR #$01                                ; |
    STA !shotBullets                        ; |
    LDX #$00                                ;/

FindLoopPoint:
    INX                                     ;\ \
    CPX #$44                                ; | |
    BEQ BulletSlotNotAvailable              ; | | Protection against overwriting Mario's sprite slots with bullets
    CPX #$45                                ; | |
    BEQ BulletSlotNotAvailable              ; |/
                                            ; |
    LDA !bulletType,x                       ; | Loop through OAM until a free slot is found
    BEQ FoundSlot                           ; |
    CPX #$7f                                ; |\
    BNE FindLoopPoint                       ; | | Loop until all slots have been checked
    BRA NoSlotsAvailable                    ;/ /

FoundSlot:                                  ; This is where bullets are created
    LDA #$40                                ;\ Play sound effect
    STA $1DF9                               ;/

    LDA $00                                 ;
    STA !bulletXSpeed,x                     ;
    LDA $01                                 ;
    STA !bulletYSpeed,x                     ;
    LDA $02                                 ;
    STA !bulletXPos,x                       ;
    LDA $03                                 ;
    STA !bulletYPos,x                       ;
    LDA $04                                 ;
    STA !bulletXAccel,x                     ;
    LDA $05                                 ;
    STA !bulletYAccel,x                     ;
    LDA $06                                 ;
    STA !bulletType,x                       ;
    LDA $07                                 ;
    STA !bulletInfo,x                       ;
    LDA #$07                                ;
    STA !bulletXFrac,x                      ;
    STA !bulletYFrac,x                      ;

NoSlotsAvailable:
    RTS                                     ;

BulletSlotNotAvailable:
    LDA #$00                                ;
    STA !bulletType,x                       ;
    BRL FindLoopPoint2                      ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.                                 ;;;
;;;Essentially, call this whenever a shot is fired.                         ;;;
;;;Use JSR FindBulletSlotAngle or the macro below.                          ;;;
;;;                                                                         ;;;
;;;To use, load the initial  speed  into $00                                ;;;
;;;        load the initiay  angle  into $01 (00 - 01FF)                    ;;;
;;;       load the initial x pos.  into $03                                 ;;;
;;;       load the initial y pos.  into $04                                 ;;;
;;;       load the initial x accel into $05                                 ;;;
;;;       load the initial y accel into $06                                 ;;;
;;;       load the initial type    into $07                                 ;;;
;;;       load any  extra  info  into   $08                                 ;;;
;;;                                                                         ;;;
;;;       This is macro-ified for easier coding.  To use,                   ;;;
;;;       type %ShootBulletAngle($00,$01,$02,$03,$04,$05,$06,$07)           ;;;
;;;       replacing those values with your actual values.                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotAngle:

    STZ !numOfBullets                       ;\
    LDA !shotBullets                        ; |
    EOR #$01                                ; |
    STA !shotBullets                        ; |
    LDX #$00                                ;/

FindLoopPoint2:
    INX                                     ;\ \
    CPX #$45                                ; | |
    BEQ BulletSlotNotAvailable2             ; | | Protection against overwriting Mario's sprite slots with bullets
    CPX #$46                                ; | |
    BEQ BulletSlotNotAvailable2             ; |/
                                            ; |
    LDA !bulletType,x                       ; | Loop through OAM until a free slot is found
    BEQ ExitFindLoop2                       ; |
    CPX #$7F                                ; |\
    BNE FindLoopPoint2                      ; | | Loop until all slots have been checked
    BRA NoSlotsAvailable2                   ;/ /

ExitFindLoop2:                              ; This is where bullets are created.
    LDA #$40                                ;\ Play sound effect
    STA $1df9                               ;/
    LDA $03                                 ;
    STA !bulletXPos,x                       ;
    LDA $04                                 ;
    STA !bulletYPos,x                       ;
    LDA $05                                 ;
    STA !bulletXAccel,x                     ;
    LDA $06                                 ;
    STA !bulletYAccel,x                     ;
    ;LDA $07                                ;
    TXA                                     ;
    LSR                                     ;
    LSR                                     ;
    LSR                                     ;
    LSR                                     ;
    CLC                                     ;
    ADC #$0a                                ;
    STA !bulletType,x                       ;
    LDA $08                                 ;
    STA !bulletInfo,x                       ;
    LDA #$07                                ;
    STA !bulletXFrac,x                      ;
    STA !bulletYFrac,x                      ;

    JSL SIN                                 ; These come last since they'll destroy the above values otherwise.
    LDA $03                                 ;
    STA !bulletYSpeed,x                     ;

    JSL COS                                 ;
    LDA $05                                 ;
    STA !bulletXSpeed,x                     ;

NoSlotsAvailable2:
    RTS                                     ;

BulletSlotNotAvailable2:
    LDA #$00                                ;
    STA !bulletType,x                       ;
    BRL FindLoopPoint2                      ;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Used to find an empty slot for a bullet.                                 ;;;
;;;Essentially, call this whenever a shot is fired.                         ;;;
;;;Use JSR FindBulletSlotAim or the macro below.                            ;;;
;;;                                                                         ;;;
;;;To use, load the initial  speed  into $00                                ;;;
;;;        load the initiay  angle  into $01 (00 - 01FF)                    ;;;
;;;       load the initial x pos.  into $03                                 ;;;
;;;       load the initial y pos.  into $04                                 ;;;
;;;       load the initial x accel into $05                                 ;;;
;;;       load the initial y accel into $06                                 ;;;
;;;       load the initial type    into $07                                 ;;;
;;;       load any  extra  info  into   $08                                 ;;;
;;;                                                                         ;;;
;;;       This is macro-ified for easier coding.  To use,                   ;;;
;;;       type %ShootBulletAngle($00,$01,$02,$03,$04,$05,$06,$07)           ;;;
;;;       replacing those values with your actual values.                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindBulletSlotAim:
    ; LDA #$05                              ;\ unused
    ; STA $19                               ;/ messes with powerup state

    STZ !numOfBullets                       ;
    LDA !shotBullets                        ;
    EOR #$01                                ;
    STA !shotBullets                        ;
    LDX #$00                                ;

FindLoopPoint3:
    INX                                     ;\ \
    CPX #$45                                ; | |
    BEQ BulletSlotNotAvailable3             ; | | Protection against overwriting Mario's sprite slots with bullets
    CPX #$46                                ; | |
    BEQ BulletSlotNotAvailable3             ; |/
                                            ;
    LDA !bulletType,x                       ;
    BEQ ExitFindLoop3                       ;
    CPX #$7f                                ;\
    BNE FindLoopPoint3                      ; | Loop through OAM until a free slot is found
    BRA NoSlotsAvailable3                   ;/

ExitFindLoop3:                              ; This is where bullets are created.
    LDA #$40                                ;\
    STA $1DF9                               ;/ play sound effect
    LDA $01                                 ;
    STA !bulletXPos,x                       ;
    LDA $02                                 ;
    STA !bulletYPos,x                       ;
    LDA $03                                 ;
    STA !bulletXAccel,x                     ;
    LDA $04                                 ;
    STA !bulletYAccel,x                     ;
    ;LDA $05                                ;
    TXA                                     ;
    LSR                                     ;
    LSR                                     ;
    LSR                                     ;
    LSR                                     ;
    CLC                                     ;
    ADC #$0a                                ;
    STA !bulletType,x                       ;
    LDA $06                                 ;
    STA !bulletInfo,x                       ;
    LDA #$07                                ;
    STA !bulletXFrac,x                      ;
    STA !bulletYFrac,x                      ;

    ; LDA #$01                              ;
    ; STA $19                               ;
    TXA                                     ;
    STA $09                                 ;

    LDA $00                                 ;
    JSR CODE_01BF6A                         ;
    LDA $00                                 ;
    STA !bulletYSpeed,x                     ;
    LDA $01                                 ;
    STA !bulletXSpeed,x                     ;

NoSlotsAvailable3:
    RTS                                     ;

BulletSlotNotAvailable3:
    LDA #$00                                ;
    STA !bulletType,x                       ;
    BRL FindLoopPoint3                      ;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; aiming routine                                                                         ;
; hijack of magikoopa aiming                                                             ;
; input: accumulator should be set to total speed (x+y), $09 should be bullet index      ;
; returns:                                                                               ;
;   $00 = y-speed                                                                        ;
;   $01 = x speed                                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE_01BF6A:
    STA $01                                 ; store x-speed
    REP #$20                                ;
    LDA $d3                                 ;\
    CLC                                     ; | offset mario's vertical position by 9 pixels
    ADC #$0008                              ; |
    STA $d3                                 ;/
    SEP #$20                                ;
    PHX                                     ;\ preserve sprite indexes of Magikoopa AND magic
    PHY                                     ;/
    JSR CODE_01AD42                         ; $0E = vertical distance to Mario
    STY $02                                 ; $02 = vertical direction to Mario
    LDA $0e                                 ;\ $0C = vertical distance to Mario, positive
    BPL CODE_01BF7C                         ; |
    EOR #$ff                                ; |
    CLC                                     ; |
    ADC #$01                                ; |
CODE_01BF7C:                                ; |
    STA $0c                                 ;/
    JSR SUB_HORZ_POS                        ; $0F = horizontal distance to Mario
    STY $03                                 ; $03 = horizontal direction to Mario
    LDA $0f                                 ;\ $0D = horizontal distance to Mario, positive
    BPL CODE_01BF8C                         ; |
    EOR #$ff                                ; |
    CLC                                     ; |
    ADC #$01                                ; |
CODE_01BF8C:                                ; |
    STA $0d                                 ;/
    LDY #$00
    LDA $0d                                 ;\ if vertical distance less than horizontal distance,
    CMP $0c                                 ; |
    BCS CODE_01BF9F                         ;/ branch
    INY                                     ; set y register
    PHA                                     ;\ switch $0C AND $0D
    LDA $0c                                 ; |
    STA $0d                                 ; |
    PLA                                     ; |
    STA $0c                                 ;/
CODE_01BF9F:
    LDA #$00                                ;\ zero out $00 AND $0B
    STA $0b                                 ; | ...what's wrong with STZ?
    STA $00                                 ;/
    LDX $01                                 ;\ divide $0C by $0D?
CODE_01BFA7:                                ; |
    LDA $0b                                 ; |\ if $0C + loop counter is less than $0D,
    CLC                                     ; | |
    ADC $0c                                 ; | |
    CMP $0d                                 ; | |
    BCC CODE_01BFB4                         ; |/ branch
    SBC $0d                                 ; | else, subtract $0D
    INC $00                                 ; | AND increase $00
CODE_01BFB4:                                ; |
    STA $0b                                 ; |
    DEX                                     ; |\ if still cycles left to run,
    BNE CODE_01BFA7                         ;/ / go to start of loop
    TYA                                     ;\ if $0C AND $0D was not switched,
    BEQ CODE_01BFC6                         ;/ branch
    LDA $00                                 ;\ else, switch $00 AND $01
    PHA                                     ; |
    LDA $01                                 ; |
    STA $00                                 ; |
    PLA                                     ; |
    STA $01                                 ;/
CODE_01BFC6:
    LDA $00                                 ;\ if horizontal distance was inverted,
    LDY $02                                 ; | invert $00
    BEQ CODE_01BFD3                         ; |
    EOR #$ff                                ; |
    CLC                                     ; |
    ADC #$01                                ; |
    STA $00                                 ;/
CODE_01BFD3:
    LDA $01                                 ;\ if vertical distance was inverted,
    LDY $03                                 ; | invert $01
    BEQ CODE_01BFE0                         ; |
    EOR #$ff                                ; |
    CLC                                     ; |
    ADC #$01                                ; |
    STA $01                                 ;/
CODE_01BFE0:
    PLY                                     ;\ retrieve Magikoopa AND magic sprite indexes
    PLX                                     ;/
    REP #$20                                ;
    LDA $d3                                 ;
    SEC                                     ;
    SBC #$0010                              ;
    STA $d3                                 ;
    SEP #$20                                ;
    RTS                                     ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE_01AD42:
    LDY #$00                                ;
    PHX                                     ;
    LDX $09                                 ;
    LDA !bulletYPos,x                       ;
    CLC                                     ;
    ADC #$04                                ;
    STA !bulletYPos,x                       ;
    LDA $d3                                 ;
    SEC                                     ;
    SBC !bulletYPos,x                       ;
    ;CLC                                    ;
    ;ADC #$04                               ;

    STA $0e                                 ;
    LDA $d4                                 ;
    SBC #$00                                ;
    BPL Return01AD53                        ;
    INY                                     ;

Return01AD53:
    LDA !bulletYPos,x                       ;
    SEC                                     ;
    SBC #$04                                ;
    STA !bulletYPos,x                       ;
    PLX                                     ;
    RTS                                     ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB_HORZ_POS:
    LDY #$00                                ; A:25D0 X:0006 Y:0001 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1020 VC:097 00 FL:31642
    LDX $09                                 ;
    LDA !bulletXPos,x                       ;
    CLC                                     ;
    ADC #$04                                ;
    STA !bulletXPos,x                       ;
    LDA $94                                 ; A:25D0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:envMXdiZCHC:1036 VC:097 00 FL:31642
    SEC                                     ; A:25F0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1060 VC:097 00 FL:31642
    SBC !bulletXPos,x                       ; A:25F0 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizCHC:1074 VC:097 00 FL:31642
    ;CLC                                    ;
    ;ADC #$04                               ;
    STA $0f                                 ; A:25F4 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1104 VC:097 00 FL:31642
    LDA $95                                 ; A:25F4 X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1128 VC:097 00 FL:31642
    SBC $14e0,x                             ; A:2500 X:0006 Y:0000 D:0000 DB:03 S:01ED P:envMXdiZcHC:1152 VC:097 00 FL:31642
    BPL LABEL16                             ; A:25FF X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1184 VC:097 00 FL:31642
    INY                                     ; A:25FF X:0006 Y:0000 D:0000 DB:03 S:01ED P:eNvMXdizcHC:1200 VC:097 00 FL:31642
LABEL16:
    LDA !bulletXPos,x                       ;
    SEC                                     ;
    SBC #$04                                ;
    STA !bulletXPos,x                       ;
    RTS                                     ; A:25FF X:0006 Y:0001 D:0000 DB:03 S:01ED P:envMXdizcHC:1214 VC:097 00 FL:31642
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
; SIN / COS Routines    ;
;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
;-------------------------------------------;SIN JSL
SIN:                                        ;
    PHP                                     ; From: Support.asm's JSL.asm
    PHX                                     ; By:
                                            ; Comment Translation+Addition By: Fakescaper
    TDC                                     ; LDA #$0000
    LDA $01                                 ; This determines the Ypos if you're using it for sprite movement
    REP #$30                                ; 16-BIT AXY
    ASL A                                   ; $00     = Radius
    TAX                                     ; $01/$02 = Angle ($0000-$01FF)
    LDA $07F7DB,x                           ; SMW's 16-BIT CircleCoords table
    STA $03                                 ;
                                            ;
    SEP #$30                                ; 8bit AXY
    LDA $02                                 ;\ push $02
    PHA                                     ;/
    LDA $03                                 ; |sin|‚ð
    STA $4202                               ;u‚©‚¯‚ç‚ê‚é”v‚Æ‚·‚éB
    LDA $00                                 ; $00 = radius
    LDX $04                                 ;\ if |sin| = 1 then skip calculation
    BNE .IF1_SIN                            ;/
    STA $4203                               ;”¼Œa‚ðu‚©‚¯‚é”v‚Æ‚·‚éB
    ASL $4216                               ;o‚½“š‚¦‚Ì¬”“_ˆÈ‰º‚ðŽlŽÌŒÜ“ü
    LDA $4217                               ;
    ADC #$00                                ;
.IF1_SIN                                    ;
    LSR $02                                 ; remove the sign
    BCC .IF_SIN_PLUS                        ;
                                            ;
    EOR #$FF                                ;\
    INC A                                   ; | two's complement negation
    STA $03                                 ;/
    BEQ .IF0_SIN                            ; branch if angle == 0
    LDA #$FF                                ;
    STA $04                                 ;
    BRA .END_SIN                            ;
                                            ;
.IF_SIN_PLUS                                ;
    STA $03                                 ;
.IF0_SIN                                    ;
    STZ $04                                 ;
.END_SIN                                    ;
    PLA                                     ;
    STA $02                                 ; $02‚ð•œŒ³
    PLX                                     ;
    PLP                                     ;
    RTL                                     ; Return
;-------------------------------------------;

;-------------------------------------------;COS JSL
COS:                                        ;
    PHP                                     ;
    PHX                                     ;
    REP #$31                                ; 16bit AXY + Carry Clear
    LDA $01                                 ; $01 = ƒÆ
    ADC #$0080                              ;
    AND #$01FF                              ;
    STA $07                                 ; $07 = ƒÆ + 90‹
    ;LDA $07                                ; Not needed because A will already be what was just stored
    AND #$00FF                              ;
    ASL A                                   ;
    TAX                                     ;
    LDA $07F7DB,x                           ; SMW's 16-BIT CircleCoords table
    STA $05                                 ;
                                            ;
    SEP #$30                                ;
    LDA $05                                 ; |cos|‚ð
    STA $4202                               ;u‚©‚¯‚ç‚ê‚é”v‚Æ‚·‚éB
    LDA $00                                 ; ”¼Œa‚ðŒÄ‚Ô
    LDX $06                                 ; |cos| = 1.00 ‚¾‚Á‚½‚çŒvŽZ•s—viRsin = ”¼Œaj
    BNE .IF1_COS                            ;
    STA $4203                               ; ”¼Œa‚ðu‚©‚¯‚é”v‚Æ‚·‚éB
    ASL $4216                               ;o‚½“š‚¦‚Ì¬”“_ˆÈ‰º‚ðŽlŽÌŒÜ“ü
    LDA $4217                               ;
    ADC #$00                                ;
.IF1_COS                                    ;
    LSR $08                                 ;â‘Î’l‚ðŠO‚·
    BCC .IF_COS_PLUS                        ;
    EOR #$FF                                ; XOR
    INC A                                   ;
    STA $05                                 ;
    BEQ .IF0_COS                            ;
    LDA #$FF                                ;
    STA $06                                 ;
    BRA .END_COS                            ;
                                            ;
.IF_COS_PLUS                                ;
    STA $05                                 ;
.IF0_COS                                    ;
    STZ $06                                 ;
.END_COS                                    ;
    PLX                                     ;
    PLP                                     ;
    RTL                                     ; Return
;-------------------------------------------;