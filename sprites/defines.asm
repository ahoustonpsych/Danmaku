


!hitBoxOAM          = $0200             ; The OAM address for Mario's hitbox. This really shouldn't be changed.

!state              = $1dfd             ;\  The current state of the boss
                                        ; | 0 = idle
                                        ; | 1 = display spell card
                                        ; | 2 = fire bullets
                                        ; | 3 = nario has been hit
                                        ;/  4 = boss is dead

!stateTimer         = $60               ; Boss state timer. Controlling how long to:
                                        ; idle
                                        ; display a spell card
                                        ; remain in the 'Mario Is Dead' state

!timeHasRunOut      = $61               ; This flag is set whenever the timer loops from 0 to FFFF
                                        ; It is your responsibility to reset it at the end of a spellcard

!currentCard        = $62               ; Boss attack number
                                        ; Determines which order bullet patterns are used

!timer              = $63               ; How much time has passed (two bytes)

!debug              = $58               ; Debug address
!scratch            = $7c               ; Scratch address

!bossYOffset        = $0dd9             ; Used for a floaty effect with the boss
!numOfBullets       = $140b             ; Number of bullets in existence
!shotBullets        = $140c             ; Misc counter
!bulletLocation     = $1763             ; A two byte variable used for hit detection

!maxSlots           = #$5F              ; Maximum number of OAM slots (bullets) to draw
                                        ; The game can handle up to #$7F, although it may lag

!angle1             = $0f5e             ;\
!angle2             = $0f60             ; | Angle variables for some spell cards
!angle3             = $0f62             ; |
!angle4             = $0f64             ;/


; BULLET TABLES
; each entry is indexed by the bullet number
; $7F0D00 ~ $7F12FF
!bulletXSpeed       = $7f0d00           ; Horizontal speed of the bullets
!bulletYSpeed       = $7f0e00           ; Vertical speed of the bullets
!bulletXPos         = $7f0f00           ; Bullet offset from the left side of the screen
!bulletYPos         = $7f1000           ; Bullet offset from the top of the screen
!bulletXAccel       = $7f1300           ; X acceleration of a bullet
!bulletYAccel       = $7f1400           ; Y acceleration of a bullet
!bulletXFrac        = $7f1500           ; X subpixel of a bullet
!bulletYFrac        = $7f1600           ; X subpixel of a bullet
!bulletType         = $7f1100           ; Bullet color. 0 = bullet doesn't exist
!bulletInfo         = $7f1200           ; Any extra information about the bullet

;;; Boss Tile Position Y-Offsets
KYoffset:
        db $0c,$0c,$0c,$0c,$0c,$0c,$0b,$0b,$0b,$0b,$0a,$0a,$0a,$09,$09,$09
        db $08,$08,$08,$07,$07,$07,$06,$06,$06,$05,$05,$04,$04,$03,$03,$03
        db $02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        db $00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$05
        db $05,$06,$06,$06,$07,$07,$07,$08,$08,$08,$09,$09,$09,$0a,$0a,$0a
        db $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c,$0c,$0c

; Xoffsets:    db $1a,$14,$24,$00,$10,$20,$30,$00,$10,$20,$30,$40,$00,$10,$20,$30
; Boss X-Position Offsets
Xoffsets:
        db $00,$10,$20,$30
        db $00,$10,$20,$30
        db $00,$10,$20,$30
        db $00,$10,$20,$30

; Yoffsets:    db $00,$10,$10,$20,$20,$20,$20,$30,$30,$30,$30,$30,$40,$40,$40,$40
; Boss Y-Position Offsets
Yoffsets:
        db $00,$00,$00,$00
        db $10,$10,$10,$10
        db $20,$20,$20,$20
        db $30,$30,$30,$30

;Tiles:        db $00,$20,$22,$40,$42,$44,$46,$60,$62,$64,$66,$68,$02,$04,$06,$08
; Boss Tiles
Tiles:
        db $00,$02,$04,$06
        db $20,$22,$24,$26
        db $40,$42,$44,$46
        db $60,$62,$64,$66

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; unused bullet(?) tiles & offsets ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;BXoffsets:
;        db $00,$08,$10,$18,$20,$28,$30,$38,$40,$48,$50,$58,$60,$68,$70,$78,$80

;BYoffsets:
;        db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10

;BTiles:
;        db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
;        db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
;        db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
;        db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b
;        db $0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b,$0c,$0d,$0e,$0a,$0b