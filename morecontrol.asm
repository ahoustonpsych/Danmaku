header
lorom

!Freespace = $108000

org $008650
JSL Control1
NOP

org $008678
JSL Control2
NOP

org !Freespace
Control1:
LDX #$00
BRA Main
Control2:
LDX #$02

Main:
LDA $4219,x
AND #$F0
LSR #4
ORA $4218,x
RTL