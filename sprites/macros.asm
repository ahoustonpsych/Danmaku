;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shoot bullet at a specific direction             ;
; loads args, finds a slot for the bullet, returns ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ShootBulletXY(Xspeed,YSpeed,xPos,yPos,xAccel,yAccel,Type,Info)
    LDA <Xspeed>
    STA $00                     ; $00 is the x-speed of the bullet
    LDA <YSpeed>
    STA $01                     ; $01 is the y-speed of the bullet
    LDA <xPos>
    STA $02                     ; $02 is the initial x-position of the bullet
    LDA <yPos>
    STA $03                     ; $03 is the initial y-position of the bullet
    LDA <xAccel>
    STA $04                     ; $04 is the x-acceleration of bullet
    LDA <yAccel>
    STA $05                     ; $05 is the y-acceleration of the bullet
    LDA <Type>
    STA $06                     ; $06 is the type of the bullet
    LDA <Info>
    STA $07                     ; $07 is the extra info for the bullet
    JSR FindBulletSlotXY        ; Find an OAM slot for the bullet
endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shoot bullet at a specific angle                           ;
; Note that <angle> must be a 16-BIT value from 0000 to 01FF ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ShootBulletAngle(Angle,Speed,xPos,yPos,xAccel,yAccel,Type,Info)
    REP #$20
    LDA <Angle>
    STA $01                     ; $01 is the 16-BIT value of the angle of bullet between $0000 AND $01FF
    SEP #$20
    LDA <Speed>
    STA $00                     ; $00 is the speed of the bullet
    LDA <xPos>
    STA $03                     ; $03 is the x-position of the bullet
    LDA <yPos>
    STA $04                     ; $04 is the y-position of the bullet
    LDA <xAccel>
    STA $05                     ; $05 is the x-acceleration of the bullet
    LDA <yAccel>
    STA $06                     ; $06 is the y-acceleration of the bullet
    LDA <Type>
    STA $07                     ; $07 is the type of the bullet
    LDA <Info>
    STA $08                     ; $08 is the extra info for the bullet
    JSR FindBulletSlotAngle     ; Find an OAM slot for the bullet
endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shoot bullet toward mario ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ShootBulletToMario(Speed,xPos,yPos,xAccel,yAccel,Type,Info)
    LDA <Speed>
    STA $00                     ; $00 is the speed of the bullet
    LDA <xPos>
    STA $01                     ; $01 is the x-position of the bullet
    LDA <yPos>
    STA $02                     ; $02 is the y-position of the bullet
    LDA <xAccel>
    STA $03                     ; $03 is the x-acceleration of the bullet
    LDA <yAccel>
    STA $04                     ; $04 is the y-acceleration of the bullet
    LDA <Type>
    STA $05                     ; $05 is the type of the bullet
    LDA <Info>
    STA $06                     ; $06 is the extra info for the bullet
    JSR FindBulletSlotAim       ; Find an OAM slot for the bullet
endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this is so dumb                                            ;
; determines which attack subroutine to call based on 'Card' ;
; NOTE: expand as needed when more spellcards are added      ;
; TODO: this would be way less disgusting with a ptr table   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro CallAttackSubroutine(Card)
        LDA <Card>              ;\  If not attack 0
        BNE NoAttacks         ; | Go to attack 1
        JMP Attack0             ;/  Else, go to attack 0

    .notattack0
        CMP #$01                ;\  If not attack 1
        BNE .notattack1         ; | Go to attack 2
        JMP Attack1             ;/  Else, go to attack 1

    .notattack1
        CMP #$02                ;\  If not attack 2
        BNE .notattack2         ; | Go to attack 3
        JMP Attack2             ;/  Else, go to attack 2

    .notattack2
        CMP #$03                ;\  If not attack 3
        BNE NoAttacks           ; | Restart the routine
        JMP Attack3             ;/  Else, go to attack 3

    NoAttacks:
        JMP MainRoutineStart
endmacro