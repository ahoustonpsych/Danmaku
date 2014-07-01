;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; No More Sprite Tile Limits v1.0.1
;; coded by Edit1754, macro'd by MathOnNapkins
;;
;; To enable this in a level, select sprite header setting 10. It has no effect otherwise.
;;
;; It appears to be incompatible with these: (only when using SP header 10)
;; - Lakitu
;; - Group of 5 eeries
;; - Amazing Flying Hammer Brother (the flying block platform is fine, though)
;; - Boo Buddies Ceiling
;; - Re-Appearing Boo Buddies
;; - Swooper Death Bat Ceiling
;; - Koopa Kid bosses (except for Lemmy and Wendy - the non-mode7 bosses)
;;
;; **IMPORTANT NOTE**
;;   you must go to levels 19B & 1C7 (Bowser Battles)
;;   and change the sprite header setting to 00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		!FREESPACE = $168000

header
lorom

!foundSlot = PickOAMSlot_foundSlot

macro speedup(offset)
		LDA.w $02FD+<offset>	; get Y position of PREVIOUS tile in OAM
		CMP.b #$F0		; F0 means it's free (Y=F0 means it can't be seen)
		BEQ ?notFound		; \  if last isn't free
		LDA.b #<offset>		;  | (and this is), then
		JMP !foundSlot		; /  this is the index
?notFound:
endmacro

macro bulkSpeedup(arg)
		%speedup(<arg>+12)
		%speedup(<arg>+8)
		%speedup(<arg>+4)
		%speedup(<arg>)
endmacro

org $0180D2

SpriteOAMHook:            
		BRA .cutToTheChase	; skip the NOP's
		NOP			; \
		NOP			;  | use NOP
		NOP			;  | to take
		NOP			;  | up space
		NOP			;  | to overwrite
		NOP			;  | old code
		NOP			;  |
		NOP			;  |
		NOP			;  |
		NOP			;  |
		NOP			;  |
		NOP			;  |
		NOP			; /
.cutToTheChase	JSL PickOAMSlot		; JSL to new code

org !FREESPACE	; POINT THIS TO SOME FREE SPACE!!!!!!!!!!!!! OR YOU MAY GET GLITCHES THAT CAUSE YOUR HACK TO SCREW UP AND LEVELS WILL NOT WORK AND YOU CAN'T EVEN GET TO THE TITLE SCREEN!!!!!!!!!

reset bytes
db "STAR"
dw CodeEnd-CodeStart
dw CodeEnd-CodeStart^#$FFFF

CodeStart:

PickOAMSlot:
		LDA.w $1692		; \  if sprite header
		CMP.b #$10		;  | setting is not 10,
		BNE .default		; /  use the old code
.notLastSpr	LDA.w $14C8,x		; \ it's not necessary to get an index
		BEQ .return		; / if this sprite doesn't exist
		LDA.b $9E,x		; \  give yoshi
		CMP.b #$35		;  | the first
		BEQ .yoshi		; /  two tiles
		JMP SearchAlgorithm	; search for a slot
.foundSlot	STA.w $15EA,x		; set the index
.return		RTL			

.yoshi		LDA.b #$28		; \ Yoshi always gets
		STA.w $15EA,x		; / first 2 tiles (28,2C)
		RTL

.default	PHX			; \
		TXA			;  | for when not using
		LDX.w $1692		;  | custom OAM pointer
		CLC			;  | routine, this is
		ADC.l $07F0B4,x		;  | the original SMW
		TAX			;  | code.
		LDA.l $07F000,x		;  |
		PLX			;  |
		STA.w $15EA,x		; /
		RTL
    
SearchAlgorithm:
		%bulkSpeedup($F0)	; \
		%bulkSpeedup($E0)	;  | pre-defined
		%bulkSpeedup($D0)	;  | macros with
		%bulkSpeedup($B0)	;  | code for each
		%bulkSpeedup($A0)	;  | individual
		%bulkSpeedup($90)	;  | slot check
		%bulkSpeedup($80)	;  |
		%bulkSpeedup($70)	;  |
		%bulkSpeedup($60)	;  |
		%bulkSpeedup($50)	;  |
		%bulkSpeedup($40)	;  |
		%speedup($3C)		;  |
		%speedup($38)		;  |
		%speedup($34)		; /
		LDA.w $18E2		; \ Yoshi?
		BNE .yoshiExists	; /
		%speedup($30)		; \ More slot
		%speedup($2C)		; / checks
		LDA.b #$28		; \ if none of the above yield which slot
		JMP !foundSlot		; / then use the slot at the beginning
		
.yoshiExists	LDA.b #$30		; \ if none of the above yield which slot,
		JMP !foundSlot		; / then use the slot at the beginning (after Yoshi)

CodeEnd:
print bytes