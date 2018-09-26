Sprite Tool v1.40


0.About
-------
This is the almost same as mikeyk's sprite tool v1.35 (which calls itself 1.34 )
So, I included mikeyk's readme. Read his file to know about the tool.

------------------------
0.credit
------------------------
mikeyk	- the author of sprite tool.
byuu	- the author of xkas.


------------------------
1.updates
------------------------

-can use both TRASM and xkas
-fixed some problems in the older Sprite Tool.
-you no longer need to put main.bin and main.off in the folder

-------------------------------------------------------
2.how to use xkas.exe for assembly
-------------------------------------------------------
Open .cfg file

01
36
81 01 08 00 10 20
00 00
piranha_plant.asm

You'll see something like this.
If you want to use xkas, add 1 in the last line, like :

01
36
81 01 08 00 10 20
00 00
piranha_plant.asm
01


Of course, put xkas.exe in the same folder.



Even after you put 01 in order to use xkas, if you save the .cfg file with the "mikeyk's .cfg editor",
this setting will be disabled. (.cfg editor will erase the line, because xkas option didn't exist at that time)

So, I made a new .cfg editor.
Please use this instead, if you liked.

-------------------------------------------------------
3.Note
-------------------------------------------------------

If you failed to assemble an .asm file using xkas, you should refer to temp.log.
And, see tmpasm.asm instead of original .asm file to know what was wrong.

-------------------------------------------------------
About MAIN and INIT label.
-------------------------------------------------------

If you use xkas, we use neiher dcb "MAIN" nor dcb "INIT"
Instead, use
print "MAIN ",pc
and
print "INIT ",pc

This is a feature of xkas which outputs the current location.
Put those lines right before where your main code or init. code starts.
Do NOT forget the space after INIT or MAIN: "INIT " "MAIN ".


Example:

print "INIT ",pc
			LDA $E4,x
			ORA #$08
			STA $E4,x
			RTL
print "MAIN ",pc
			PHB
			PHK
			PLB
			JSR SpriteMain
			PLB
			RTL

If you don't have an INIT routine, put the print "INIT ",pc behind the RTL in the MAIN code:

print "MAIN ",pc
			PHB
			PHK
			PLB
			JSR SpriteMain
			PLB
print "INIT ",pc
			RTL

-------------------------------------------------------
Definitions:
-------------------------------------------------------


Normally, you would define stuff in Sprite Tool like this:

Definition = $01

LDA #Definition
STA $blah

In xkas you need to put a ! behind the definition, so the code will look like this:

!Definition = $01

LDA #!Definition
STA $blah

-------------------------------------------------------
Labels
-------------------------------------------------------

In the earlier version of Sprite Tool, you didn't need the colon in labels.
But when using xkas, you need to use it to correctly use labels.

Example:

Loop	INC A
	BRA Loop

This WON'T work, since xkas will see "Loop INC A" as opcode or command.
The correct method is this:

Loop:	INC A
	BRA Loop

