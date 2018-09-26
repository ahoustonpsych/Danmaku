Sprite Tool by mikeyk730@gmail.com

Sprite Tool is a console application.  It allows you to easily double the amount of sprites into a Super Mario World ROM.  

********************************************************************
* Using the program
********************************************************************

The first thing you should do is put your ROM in the Sprite Tool folder (the same folder that has sprite_tool.exe).  Run sprite_tool.exe.  You will be prompted to type in the filename of your ROM (for example, mario.smc).  After your ROM is loaded, Sprite Tool will ask you for the filename of your sprite list (for example, sprites.txt).  Both the ROM and the sprite list can have spaces in their filenames.

More advanced users can use the command line interface.  the usage is:
sprite_tool <rom_name> <sprite_list>

The sprite list is a text file.  It specifies what you want to put into your ROM.  Each line consists of a sprite number followed by a sprite cfg file.  An example is shown below:

11 birdo.cfg
1A venus.cfg
1B boomerang_bro.cfg
1C boomerang.cfg
20 para_beetle.cfg
C4 diag_bill.cfg
D2 generic.cfg

How do you pick a sprite number for a custom sprite?  Well, it depends on the kind of sprite it is:

00-BF Standard Sprites (sprites included in the 'sprites' subdirectory)
C0-CF Shooters (sprites included in the 'shooters' subdirectory)
D0-DF Generators (sprites included in the 'generators' subdirectory)
E0-FF	Invalid

Say we want to add a Shy Guy to our list.  It is a standard sprite (included in the 'sprites' subdirectory) so we'd have to choose between 00 and BF.

IMPORTANT NOTE: There are a few sprites that require special attention!  Read below if you want to use the poison mushroom, boomerang brother, birdo, donut lift, or directional elevator!!

(1) The *poison mushroom* isn't a true custom sprite.  Unlike the others, it REPLACES regular sprite 85!  It should be put in the sprite list as sprite 85.

(2) If you use the *boomerang brother*, the boomerang must be inserted as the very next sprite.  (ex. in the above example the boomerang bro is sprite 1B, so the boomerang MUST be sprite 1C).  In Lunar Magic just place the boomerang brother, and he will automatically throw boomerangs.

(3) If you use the *birdo* that spits a rideable egg, the egg must be inserted as the very next sprite.  (Very similar to the previous point.)

(4) The *donut lift* is made of both a block and a sprite, so it takes a bit more work to get set up:

	1. Insert the donut block using block tool.  Look at DONUTBLK.txt
	in the 'blocks' subdirectory for more information.

	2. Open donut_lift.asm with notepad.  Specify the map16 number of 
	the block where it says DONUT_MAP16_NUM.  It is set to $0534 by 
	default.  Save the asm file and close it.

	3. Add donut_lift.cfg to the sprite list as sprite 85.  If you
	already have the poison mushroom in your list as sprite 85,	don't
	worry.  The poison mushroom isn't a custom sprite, so it won't
	conflict.

	4. In Lunar Magic, insert the donut blocks and NOT the donut 
	sprites

(5) The *directional elevator* is made up of blocks and a sprite:

	1. Insert the elevator platforms using block tool.  Look at
	ELV_BLKS.txt in the 'blocks' subdirectory for more information.

	2. Add elevator_dir.cfg to the sprite list as sprite 86

	3. In Lunar Magic, insert the platform blocks and NOT the
	elevator sprite.


********************************************************************
* using the sprites
********************************************************************

If everything goes okay when you run the program, you will see a message saying "sprites inserted successfully".  The sprites are now inside your ROM, and now it's time to use them.  The custom sprites can be inserted with Lunar Magic.  To do so, make sure Lunar Magic is in sprite mode.  Hit INS to bring up the "Add Sprite Manual" dialog.  In the "command" field enter the number of the custom sprite (with the example sprites.txt, 11 if we wanted a birdo, 1A if we wanted a Venus Fire Trap, etc).  In the "extra info" field, enter the value 2 or 3 (see below on when to use each value).  Do whatever you'd like with the remaining fields and hit ok.  In Lunar Magic, the custom sprite will not look any different than the regualr sprite of the same number.  For this reason it is useful to view the sprite data, which is easily found in the Lunar Magic menu (View > Sprite Data).  X2 or X3 on the top row will indicate a custom sprite.

So what's the difference between the values 2 and 3 in the "extra info" field?  Open the .asm file of the sprite (this is just a text file).  Near the begining there will be a line reading "Uses first extra bit".  For sprites that say "NO", you should always use the value of 2.  For sprites that say "YES",  there will be a description of a behavior that will be present if the first extra bit is set.  You should use the value of 3 if you want this behavior, and 2 if you don't.

Look in the "tilemaps" subdirectory for some graphics files that may help you see the default tilemaps.


********************************************************************
* Sources of errors
********************************************************************

.cfg and .asm files CANNOT have spaces in their filenames.

********************************************************************
* configuring a sprite 
********************************************************************

Sprites are specified by a .cfg file, which is a simple text file.  Two examples will be gone through below.

There are two types of sprites, type 0 and type 1.  Type 0 means that you simply want to give different properties to an existing sprite.  This is similar to using Tweaker to modify a sprite, but this way you won't overwrite the original.  Type 1 means that the sprite is a true custom sprite.

Type 0 example:

squashable_goomba.cfg:
00
0F
30 00 04 00 00 00

The first line of the .cfg specifies the sprite type.  Here it is 0 because we just want to tweak an existing sprite.  

The next line specifies the "acts like" byte.  This is the value that gets put into $9E.  For type 0 sprites, it should be set to the sprite you wish to use as a base.

The next line specifies the sprite properties (6 bytes separated by spaces) that are put in the main sprite tables (1656, 1662, 166E, 167A, 1686, and 190F).  These are the first 6 bytes of the Tweaker code.


Type 1 example:

venus.cfg:
01
36
81 01 08 00 10 20
00 00
venus.asm

The first line of the .cfg specifies the sprite type.  Here it is 1 becuase we have a true custom sprite.  

The next line specifies the "acts like" byte.  It's the value that gets put into $9E.  For type 1 sprites, it should almost always be set to 36.

The next line specifies the sprite properties (6 bytes separated by spaces) that are put in the main sprite tables (1656, 1662, 166E, 167A, 1686, and 190F).  They are the first 6 bytes of the Tweaker code.

The next line specifies two additional property bytes that can be used by the programmer.  They are put into tables at $7FAB28 and $7FAB34.

The last line is the name of the asm file that contians the sprite code.

********************************************************************
* programming a sprite 
********************************************************************

sprites can be coded in asm compatible with 65816 Tricks Assembler Version 1.11.  There are two simple requirements for each .asm file.

1. The line: dcb "INIT"
followed by a long subroutine

This subroutine will get called once at the sprite's initialization.  A common thing done with original sprites is to have the sprite intially face mario.  This code could also be used to shift the x position for a sprite like the venus fire trap.

2. the line: dcb "MAIN"
followed by a long subroutine

This is the main sprite's code that is called once per frame.

For more details see the documents in the "tutorials" subfolder
