/********************************************************************
 Sprite Tool
********************************************************************/

#include <iostream>
#include <string>
#include <fstream>
#include <cassert>
#include <map>

#include "sprites.h"

using namespace std;

/********************************************************************
  Helpers
********************************************************************/
namespace{
  struct Error{
    Error(const string & s_){s=s_;}
    string s;
  };

  ostream& operator<<(ostream& os, const Location& location)
  {
    os << hex << "PC: 0x" << location.pc_address() << "  (SNES: "
       << location.bank() << ":" << location.snes_address() << ")" ;
    return os;
  }

  Location operator+(const Location& orig, int offset)
  {
    assert(orig.offset_from_bank_start() + offset < BANK_SIZE);
    return Location(orig.bank(), orig.offset_from_bank_start() + offset);    
  }

  //returns the filesize, doesn't preserve the get pointer
  int get_file_size(fstream & fs)
  {
    fs.seekg (0, ios::end);
    return fs.tellg();
  }
  
  char get_hex_digit(int digit)
  {
    static const char * hex_digits = "0123456789ABCDEF";
    assert(digit >= 0 && digit <= 15);
    return hex_digits[digit];
  }
  
  string get_filename(const string& prompt)
  {
    string filename;
    cout << prompt;
    getline(cin, filename);

	//if filename had double quotations, remove them.
	if(filename[0]=='\"' && filename[filename.length()-1]=='\"'){
		filename.erase(0, 1);
		filename.erase(filename.length()-1, 1);
	}
    //if the user didn't specify a full path, prepend the filename with .<PATH_SEP>
    //this really shouldn't have to be done, but apparently this helped some people
#if defined(WIN32) || defined(_WIN32)
    if (filename.size() <= 1 || !(filename[1]==':' || (filename[0]=='\\' && filename[1]=='\\')))
#else
    if (filename.size() <= 1 || !(filename[0] == '/'))
#endif
      filename = "." PATH_SEP + filename;
    return filename;
  }
}

string rom_filename;

/********************************************************************
   Main
 ********************************************************************/

int main(int argc, char** argv)
{
	setlocale(LC_ALL, "");
	if(argc != 3){
		cout << endl << WELCOME_MESSAGE << endl << endl;
	}

	bool error=false;
	try{
		fstream rom_file;
		ifstream sprite_file;
		do{
			rom_file.clear();
			if(argc==3) argc--, rom_filename =argv[1];
			else rom_filename = get_filename("Enter ROM filename: ");
			rom_file.open(rom_filename.c_str(), ios::in | ios::out | ios::binary);
			if(!rom_file){
				cout << "Error: couldn't open ROM " << rom_filename << endl;
				continue;
			}
		}while(!rom_file);
		do{
			sprite_file.clear();
			string sprite_list_filename;
			if(argc==2) argc--, sprite_list_filename = argv[2];
			else sprite_list_filename = get_filename("Enter sprite list filename: ");
			sprite_file.open(sprite_list_filename.c_str());
			if(!sprite_file){
				cout << "Error: couldn't open sprite list " << sprite_list_filename << endl;
				continue;
			}
		}while(!sprite_file);

		SpriteTool st(rom_file, sprite_file, argv[1]);

		//get rid of anything sprite tool may have inserted in the past
		st.clean_rom();

		//After removed old stuff, read ROM data into buffer
		st.LoadROMAndMarkRATS();

		//insert and hook up the sprite execution code
		st.insert_main_routine();

		//now we can go through in all the sprites listed in sprites.txt
		st.insert_sprites();    

		cout << endl
		 << "Sprites inserted successfully" << endl
		 << endl;
	}
	catch (Error & err){
		cout << endl
		<< "************ERROR************" << endl
		<< err.s << endl
		<< "*****************************" << endl
		<< endl;
		error=true;
	}
	if(!error){
		remove("temp.log");
		remove("tmpasm.asm");
	}
	remove("tmpasm.bin");
	remove("tmpasm.smc");
	remove("tmpasm.err");
    printf("Press enter to continue!\n");
    getchar();
	return 0;
}


/********************************************************************
   SpriteTool
 ********************************************************************/
void SpriteTool::LoadROMAndMarkRATS(void)
{
	unsigned int rom_size = get_file_size(m_rom_file);

	ROMBuf = new unsigned char[rom_size-HEADER_SIZE];

	m_rom_file.seekg(HEADER_SIZE);
	m_rom_file.read((char*)ROMBuf, rom_size-HEADER_SIZE);

	for(unsigned int i=0x80000;i<(rom_size-HEADER_SIZE);){	//•ÛŒì—Ìˆæ–„‚ßs‚­‚µ
		if(*(unsigned int*)&ROMBuf[i++] != 0x52415453) continue;		//STAR
		i+=3;
		int RATSsize = *(unsigned short *)&ROMBuf[i];
		i+=2;
		int RATSsize2= *(unsigned short *)&ROMBuf[i];
		i+=2;
		if(RATSsize != (RATSsize2^0xFFFF)) continue;		//³‚µ‚¢RATSƒ^ƒO‚©
		for(;RATSsize>=0;RATSsize--) ROMBuf[i++]='X';		//”ñ0‚ð‘ã“ü
	}

}


//remove everything from a previous run of sprite tool
void SpriteTool::clean_rom()
{
  cout << "cleaning up data from previous runs:" << endl;
  int rom_size = get_file_size(m_rom_file);
  int number_of_banks = (rom_size - HEADER_SIZE)/BANK_SIZE;
  if (number_of_banks <= 0x10)
    throw Error("Your ROM must be expanded");

  //revert poison mushroom changes back to the original rom's values
  //TODO: i probably should do some sort of check first.  if someone has manually
  // modified the portion of the powerup routine i'm reverting, it could cause 
  // corruption.
  char mush[4] = {'\xC9', '\x21', '\xD0', '\x69'};
  write_to_rom(0x0C6CB, mush, 4);
  char mush_gfx[4] = {'\xAA', '\xBD', '\x09', '\xC6'};
  write_to_rom(0x0C8D6, mush_gfx, 4);

  char empty_buffer[BANK_SIZE];
  memset(empty_buffer, 0, BANK_SIZE);
  char bank_buffer[BANK_SIZE];
  
  //removes all STAR####MDK tags
  for (int i = 0x10; i < number_of_banks; ++i){ 
    //get whole bank into a string
    m_rom_file.seekg(i*BANK_SIZE + HEADER_SIZE, ios::beg);
    m_rom_file.read(bank_buffer, BANK_SIZE);
    string current_bank_contents(bank_buffer, BANK_SIZE);

    int bank_offset = 0;
    while(1){
        //look for data inserted on previous uses
        size_t offset = current_bank_contents.find(SPRITE_TOOL_LABEL, bank_offset);
        if(offset == string::npos) break;
        
        bank_offset += 3;
        if (offset < 8 || current_bank_contents.substr(offset-8, 4) != RATS_TAG_LABEL)
            continue;
		
        //delete the amount that the RATS tag is protecting
        int size = ((unsigned char)current_bank_contents[offset-3] << 8)
        + (unsigned char)current_bank_contents[offset-4] + 8;
        int inverted = ((unsigned char)current_bank_contents[offset-1] << 8)
        + (unsigned char)current_bank_contents[offset-2];
    
        if ((size - 8 + inverted) == 0x0FFFF){
            cout << "New tag: ";
            size++;
        }
        else if ((size - 8 + inverted) == 0x10000)
            cout << "Old tag: ";
        else
            cout << "Warning: Bad RATS tag (" << (size - 8 + inverted) << ") : ";
    
        int pc_address = HEADER_SIZE + (i * BANK_SIZE) + offset - 8;
        write_to_rom(pc_address, empty_buffer, size);
        cout << hex << "deleted " << size << " bytes from PC 0x" << pc_address << endl;
        --i;		
        break;
    }
  }
}


void SpriteTool::insert_main_routine()
{
	unsigned char main_code[]={
		0x48,0x29,0x0D,0x9F,0x10,0xAB,0x7F,0x29,0x01,0x9D,0xD4,0x14,0xA5,0x05,0x9F,0x9E,
		0xAB,0x7F,0x68,0x6B,0xA9,0x08,0x9D,0xC8,0x14,0xBF,0x10,0xAB,0x7F,0x29,0x08,0xD0,
		0x01,0x6B,0x22,0x5D,0x81,0x00,0xAF,0x1C,0xAB,0x7F,0xF0,0xF5,0x68,0x68,0xF4,0xC1,
		0x85,0xA9,0x01,0xDC,0x00,0x00,0x9C,0x91,0x14,0xBF,0x10,0xAB,0x7F,0x29,0x08,0xD0,
		0x03,0xB5,0x9E,0x6B,0xBF,0x9E,0xAB,0x7F,0x20,0x56,0x80,0x68,0x68,0xF4,0xC1,0x85,
		0xBD,0xC8,0x14,0xDC,0x00,0x00,0x8B,0x4B,0xAB,0x08,0xC2,0x30,0x29,0xFF,0x00,0x0A,
		0x0A,0x0A,0x0A,0xA8,0xB9,0x63,0x82,0x85,0x00,0xB9,0x64,0x82,0x85,0x01,0x28,0xAB,
		0x60,0x9E,0xAC,0x15,0xA9,0x01,0x9D,0xA0,0x15,0x3A,0x9F,0x10,0xAB,0x7F,0x6B,0xA9,
		0xFF,0x9D,0x1A,0x16,0x1A,0x9F,0x10,0xAB,0x7F,0x6B,0x48,0x29,0x0D,0x9F,0x10,0xAB,
		0x7F,0x29,0x01,0x9D,0xE0,0x14,0xA5,0x05,0x9F,0x9E,0xAB,0x7F,0x68,0x6B,0x48,0xA9,
		0x00,0x8F,0x1C,0xAB,0x7F,0x68,0xC9,0xC0,0x90,0x38,0xC9,0xE0,0xB0,0x34,0x88,0xB7,
		0xCE,0x29,0x08,0xF0,0x2A,0xB7,0xCE,0x29,0x0C,0x0A,0x0A,0x0A,0x0A,0x8F,0x1C,0xAB,
		0x7F,0xC8,0xA5,0x05,0xC9,0xD0,0xB0,0x04,0x5C,0xD8,0xA8,0x82,0xAF,0x1C,0xAB,0x7F,
		0x8D,0xB9,0x18,0xA5,0x05,0x38,0xE9,0xCF,0x0D,0xB9,0x18,0x5C,0xB8,0xA8,0x82,0xC8,
		0xA5,0x05,0xC9,0xE7,0x90,0x04,0x5C,0x6A,0xA8,0x82,0x5C,0x8C,0xA8,0x82,0xAF,0x1C,
		0xAB,0x7F,0xD0,0x06,0xA5,0x04,0x38,0xE9,0xC8,0x6B,0x9D,0x83,0x17,0xA5,0x04,0x38,
		0xE9,0xBF,0x1D,0x83,0x17,0x6B,0xBC,0x83,0x17,0x30,0x0D,0xBC,0xAB,0x17,0xF0,0x04,
		0x5C,0x9A,0xB3,0x82,0x5C,0xA4,0xB3,0x82,0xBC,0xAB,0x17,0xF0,0x0A,0x48,0xA5,0x13,
		0x4A,0x90,0x03,0xDE,0xAB,0x17,0x68,0x29,0x3F,0x18,0x69,0xBF,0x20,0x56,0x80,0xA9,
		0x82,0x48,0xF4,0xA6,0xB3,0xDC,0x00,0x00,0xAD,0xB9,0x18,0x30,0x10,0x68,0x68,0x68,
		0xAD,0xB9,0x18,0xF0,0x04,0x5C,0x03,0xB0,0x82,0x5C,0x2A,0xB0,0x82,0x29,0x3F,0x18,
		0x69,0xCF,0x20,0x56,0x80,0x68,0x68,0xF4,0x29,0xB0,0xDC,0x00,0x00,0x5A,0x8B,0x4B,
		0xAB,0x08,0xBF,0x9E,0xAB,0x7F,0xC2,0x30,0x29,0xFF,0x00,0x0A,0x0A,0x0A,0x0A,0xA8,
		0xE2,0x20,0xB9,0x58,0x82,0x8F,0x1C,0xAB,0x7F,0xB9,0x59,0x82,0x95,0x9E,0xB9,0x5A,
		0x82,0x9D,0x56,0x16,0xB9,0x5B,0x82,0x9D,0x62,0x16,0xB9,0x5C,0x82,0x9D,0x6E,0x16,
		0x29,0x0F,0x9D,0xF6,0x15,0xB9,0x5D,0x82,0x9D,0x7A,0x16,0xB9,0x5E,0x82,0x9D,0x86,
		0x16,0xB9,0x5F,0x82,0x9D,0x0F,0x19,0xAF,0x1C,0xAB,0x7F,0xD0,0x0A,0x28,0xAB,0x7A,
		0xA9,0x00,0x9F,0x10,0xAB,0x7F,0x6B,0xC2,0x20,0xB9,0x60,0x82,0x85,0x00,0xE2,0x20,
		0xB9,0x62,0x82,0x85,0x02,0xB9,0x66,0x82,0x9F,0x28,0xAB,0x7F,0xB9,0x67,0x82,0x9F,
		0x34,0xAB,0x7F,0x28,0xAB,0x7A,0x6B,0xBD,0xC8,0x14,0xC9,0x02,0x90,0x12,0xC9,0x08,
		0xD0,0x04,0x5C,0xC3,0x85,0x81,0x48,0xBF,0x10,0xAB,0x7F,0x29,0x08,0xD0,0x05,0x68,
		0x5C,0x33,0x81,0x81,0xBF,0x34,0xAB,0x7F,0x30,0x19,0x48,0xA3,0x02,0x22,0x3E,0xD4,
		0x81,0x68,0x0A,0x30,0x0E,0x68,0xC9,0x09,0xB0,0x08,0xC9,0x03,0xF0,0x04,0x5C,0xC2,
		0x85,0x81,0x48,0xBF,0x9E,0xAB,0x7F,0x20,0x56,0x80,0x68,0xA0,0x81,0x5A,0xF4,0xC1,
		0x85,0xDC,0x00,0x00,0xBF,0x10,0xAB,0x7F,0x48,0x22,0xD2,0xF7,0x87,0x68,0x9F,0x10,
		0xAB,0x7F,0x6B,0x48,0xBF,0x10,0xAB,0x7F,0x29,0x08,0xD0,0x06,0xFA,0xBF,0x59,0xF6,
		0x07,0x6B,0x68,0xBF,0x9E,0xAB,0x7F,0x08,0xC2,0x30,0x29,0xFF,0x00,0x0A,0x0A,0x0A,
		0x0A,0xAA,0xBF,0x5F,0x82,0x00,0x28,0x6B,
	};

	//figure out how much space is needed
	int main_code_size = sizeof(main_code);
	int total_size = main_code_size + SPRITE_TABLE_SIZE;
	//find a free spot in the rom
	m_main_location = find_free_space(total_size);
	cout << m_main_location << endl;
	m_table_start = m_main_location.pc_address() + main_code_size + TAG_SIZE;
	cout << "sprite table start PC 0x" << hex << m_table_start << endl;


	//patch locations that call sprite tool code
	// patch 1 - level loading
	setup_call_to_asm(0x000, 0x12B63);
	// patch 2 - init routine
	setup_call_to_asm(0x014, 0x08372);
	// patch 3 - code routine
	setup_call_to_asm(0x036, 0x087C3);
	// patch 4 - bit reset routine
	setup_call_to_asm(0x071, 0x3F985);
	// patch 5 - bit reset routine 2
	setup_call_to_asm(0x07F, 0x08351);
	// patch 6 - verical level loading
	setup_call_to_asm(0x08A, 0x12B4B);
	// patch 7 - root of sprite loader
	setup_call_to_asm(0x09E, 0x12A66, 4, true);
	// patch 8 - shooter loader
	setup_call_to_asm(0x0EE, 0x12DA0);
	// patch 9 - generator handler
	setup_call_to_asm(0x106, 0x13595, 5, true);
	// patch 10 - shooter handler
	setup_call_to_asm(0x138, 0x131FE);
	// patch 11 - table filler
	setup_call_to_asm(0x15D, 0x089A7, 4, true);
	// patch 12 - status handler
	setup_call_to_asm(0x1D7, 0x08327, 4, true);
	// patch 13 - save extra bits at load time
	setup_call_to_asm(0x224, 0x12BC9, 4);
	// patch 14 - silver coin check
	setup_call_to_asm(0x233, 0x12BA6);

	// change the init pointer of the hammer bro, since it executes a null routine anyway
	char hammer_patch[2] = {'\xC2', '\x85'};
	write_to_rom(0x084B3, hammer_patch, 2);

	// patch goal tape init to get extra bits in $187B
	char goal_patch[11] = {'\xBF', '\x10', '\xAB', '\x7F', '\xEA', '\xEA',
							'\xEA', '\xEA', '\x9D', '\x7B', '\x18'};
	write_to_rom(0x0C289, goal_patch, 11);

	// status routine wrapper
	char status_patch[4] = {'\x20', '\x33', '\x81', '\x6B'};
	write_to_rom(0x0D63E, status_patch, 4);

	//create a buffer containing my custom code and the sprite table.  we will write
	// this directly to the rom
	char * main_buffer = new char[total_size];
	memset(main_buffer, 0xFF, total_size);
	memcpy(main_buffer, main_code, main_code_size);
	//construct a default sprite table
	for(int i = main_code_size; i < total_size; i += 0x10){
		main_buffer[i+0] = 0;
		main_buffer[i+1] = 0;
		//make the asm pointers default to an RTL
		main_buffer[i+8] = '\x21';
		main_buffer[i+9] = '\x80';
		main_buffer[i+10] = '\x01';
		main_buffer[i+11] = '\x21';
		main_buffer[i+12] = '\x80';
		main_buffer[i+13] = '\x01';
	}

	//we are done patching, so the rest of the offsets in the file must be reloc
	// offsets.  we go ahead and apply those.
	//TODO: i could use TRASM and eliminate the need to do this, but then again 
	// nobody else has to deal with this file, and it's not too hard to maintain.
	int relocs[20]={0x065, 0x06A,
					0x173, 0x17A, 0x17F, 0x185, 0x18B, 0x196, 0x19C, 0x1A2, 0x1BA, 0x1C1, 0x1C6, 0x1CD,
					0x049, 0x12D, 0x153, 0x218,
					0x023,
					0x253
	};
	for(int i=0; i<20 ; i++){
		relocate(main_buffer, relocs[i], m_main_location);
	}
	//Long reloc offsets
	main_buffer[0x023+2] = m_main_location.bank();
	main_buffer[0x253+2] = m_main_location.bank();
	cout << endl;

	//write the main code and empty sprite table to rom
	write_to_rom_with_tags(m_main_location.pc_address(), main_buffer, total_size);
	delete [] main_buffer;
}


void SpriteTool::insert_sprites()
{
	int sprite_number;
	map<string,Location2> SprAddresses;
	unsigned char Inserted[0x100];
	memset(Inserted, 0x00, 0x100);

	while (m_sprite_list >> hex >> sprite_number){

		string PATH;
		if (sprite_number >= 0x0E0)
			throw Error(BAD_NUM);
		else if (sprite_number >= 0x0D0)
			PATH = GENERATOR_PATH;
		else if (sprite_number >= 0x0C0)
			PATH = SHOOTER_PATH;
		else
			PATH = SPRITE_PATH;

		cout << "\ninserting sprite: " << sprite_number << endl;

		//open the .cfg file for the sprite
		string sprite_cfg_filename;
		m_sprite_list >> sprite_cfg_filename;
		if (!m_sprite_list) throw Error("sprite list contains invalid data");
		sprite_cfg_filename = PATH + sprite_cfg_filename;
		ifstream sprite_cfg(sprite_cfg_filename.c_str());
		if (!sprite_cfg) throw Error("couldn't open cfg file " + sprite_cfg_filename);
		sprite_cfg.clear();
		cout << sprite_cfg_filename << endl;

		//based on the sprite number, we can get the location of the current sprite's 
		// table entry
		int table_row_start = m_table_start + (0x10 * sprite_number);

		//table layout
		// 00: type {0=tweak,1=custom,3=generator/shooter}
		// 01: "acts like"
		// 02-07: tweaker bytes
		// 08-10: init pointer
		// 11-13: main pointer
		// 14: extra property byte 1
		// 15: extra property byte 2
		char table_row[0x10];
		memset(table_row, 0, 0x10);

		//get type, "acts like", and tweaker values
		int value;
		for (int i=0; i<8; ++i){
			sprite_cfg >> hex >> value;
			if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
			table_row[i] = char(value);
		}

		int type = (unsigned char)table_row[0];
		if(type!=255){
			if(Inserted[sprite_number]) throw Error("This slot is already used!");
			else Inserted[sprite_number]=1;
		}

		//if it's just a tweaked sprite, we just write the table entry to the rom
		if (type == 0) {
			write_to_rom(table_row_start, table_row, 8);
		}
		//real custom sprites are going to be more work
		else if (type == 1 || type == 3){
			//get the extra property bytes
			for (int i=14; i<16; ++i){
				sprite_cfg >> hex >> value;
				if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
				table_row[i] = char(value);
			}

			//get the path to the source file from the cfg file
			string sprite_asm_filename;
			sprite_cfg >> sprite_asm_filename;
			if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
			sprite_asm_filename = PATH + sprite_asm_filename;

			map<string,Location2>::iterator it = SprAddresses.find(sprite_asm_filename);
			if(it != SprAddresses.end()){	//already inserted the same .asm file
				Location loc = SprAddresses[sprite_asm_filename].loc;
				int init_offset = SprAddresses[sprite_asm_filename].init;
				int code_offset = SprAddresses[sprite_asm_filename].main;
				cout << "init offset: " << loc.bank() << ':' << TAG_SIZE + init_offset + loc.snes_address() << endl;
				cout << "main offset: " << loc.bank() << ':' << TAG_SIZE + code_offset + loc.snes_address() << endl;

				table_row[10] = loc.bank();
				table_row[9] = '\x80';
				relocate(table_row, 8, loc, init_offset);

				table_row[13] = loc.bank();
				table_row[12] = '\x80';
				relocate(table_row, 11, loc, code_offset);

				//write the current sprite's table entry to the rom
				write_to_rom(table_row_start, table_row, 16);
				sprite_cfg.close();
				continue;
			}


			//hmmm... we have a problem.  when it's time to assemble the source file, we need
			// to know where the resulting binary file will be inserted.  but we CAN'T know 
			// where the binary will be inserted, because we don't know the filesize of the sucker
			// until after it is assembled.  call up yossarian, it's a classic catch-22!

			//as a workaround we can make two passes.  during the first pass we assemble the 
			// source and get the size of the binary.  we can now find a place in the rom to insert
			// it.  we can't *actually* insert it, because all the subroutine addresses are 
			// incorrect.  we must make a second pass.  knowing where the code will go, we
			// re-assemble the source with this information.

			//The down side of doing this is that it is slooooooow.  The calls to TRASM are the
			// most expensive part of the program, and we're doing it times 2.


			//On the first pass we'll arbitrarily use $008000 as the starting address
			//We do this by injecting the line "org $008000" into the source file before we assemble


			int using_xkas=1, option, using_asar=0;
      option = 0;
			sprite_cfg >> hex >> option;
			if( !sprite_cfg || !(option & 0x03)) using_xkas=0;
			if( option & 0x02 ) using_asar=1;

			if(using_xkas && !using_asar){	//only for xkas, not asar
				fstream st_xkas_smc("tmpasm.bin", ios::out | ios::trunc);
				if( !st_xkas_smc) throw Error("couldn't make temporary .bin file for xkas");
				st_xkas_smc.close();
			}

			char org_line[13] = {'o','r','g',' ','$','0','0','8','0','0','0', 0x0D, 0x0A};
			char xkas_org_line[] = ";@xkas\x0D\x0Alorom\x0D\x0Aorg $008000\x0D\x0A";
			char asar_org_line[] = "freecode cleaned\r\ndb \"MDK\"\x0D\x0Aprint \"_SPRT_STAR_ \",pc\x0D\x0Aprint \"_SPRT_SIZE_ \",freespaceuse\r\n";
      //sprite tool has different RATS than asar, so MDK is needed as plain text

			//load the entire source file into a buffer
			fstream sprite_asm_file(sprite_asm_filename.c_str(), ios::in | ios::binary);
			if (!sprite_asm_file) throw Error("couldn't open asm file " + sprite_asm_filename);
			int sprite_asm_size = get_file_size(sprite_asm_file);
			char * asm_file_contents = new char[sprite_asm_size];
			sprite_asm_file.seekg(0, ios::beg);
			sprite_asm_file.read(asm_file_contents, sprite_asm_size);
			sprite_asm_file.close();
					
			//create tmpasm.asm which is just the original source file with the org line prepended to it
			fstream sprite_asm_tmp("." PATH_SEP "tmpasm.asm", ios::out | ios::binary);
			if (!sprite_asm_tmp) throw Error("couldn't create ." PATH_SEP "tmpasm.asm");

			if(!using_xkas) sprite_asm_tmp.write(org_line, 13);
			else if(!using_asar) sprite_asm_tmp.write(xkas_org_line, sizeof(xkas_org_line)-1);	//if we use xkas, put different lines.
			else sprite_asm_tmp.write(asar_org_line, sizeof(asar_org_line)-1);	//if we use xkas, put different lines.

			sprite_asm_tmp.write(asm_file_contents, sprite_asm_size);
			sprite_asm_tmp.close();

			//run TRASM.  redirect the output, so it doesn't clutter my own output
			if(!using_xkas) system(TRASM_EXECUTABLE " tmpasm.asm -f > temp.log");
			else if(!using_asar) system(XKAS_EXECUTABLE " tmpasm.asm tmpasm.bin > temp.log");	//xkas
			else system((ASAR_EXECUTABLE " tmpasm.asm " + rom_filename + " > temp.log").c_str());	//asar

			//Since xkas inserts asm code ROM directly, we can't compare old .bin file size to actual code size patched to ROM.
			//All we can do is, to check whether or not xkas reported any error.
			//And, sprite_tool knows INIT and MAIN address from this .log file.
			int init_offset, code_offset;
			int asar_offset, asar_size;
			if(using_xkas){
				ifstream log_file("temp.log");
				if(!log_file) throw Error("couldn't open asar log file");
				string word;
				bool main_found=false, init_found=false, asar_found=false, size_found=false;
				while(log_file>>word){
          if (word == "error:") throw Error("asar reported error. Refer to temp.log and tmpasm.asm");
          if (word == "Errors") throw Error("asar reported error. Refer to temp.log and tmpasm.asm");
					if(word=="MAIN"){
						if(main_found) throw Error("MAIN label duplicated");
						main_found=true;
						log_file>>hex>>code_offset;
						if(!log_file) throw Error("MAIN location specified invalidly");
					}else if(word=="INIT"){
						if(init_found) throw Error("INIT label duplicated");
						init_found=true;
						log_file>>hex>>init_offset;
						if(!log_file) throw Error("INIT location specified invalidly");
					}else if(word=="_SPRT_STAR_" && using_asar && !asar_found){
						asar_found=true;
						log_file>>hex>>asar_offset;
						asar_offset-=TAG_SIZE;		//get actual starting position of inserted code.
          }else if (word == "_SPRT_SIZE_" && using_asar && !size_found){
            size_found = true;
            log_file >> dec >> asar_size;
          }
				}
				if(!main_found) throw Error("MAIN label not found");
				if(!init_found) throw Error("INIT label not found");
				if(using_asar && !asar_found) throw Error("asar starting label not found! Caution. If no error has been thrown to this point the code was inseted but will not be cleaned! see INIT and MAIN label");
				if(!using_asar){
					code_offset &= 0x7FFF;
					init_offset &= 0x7FFF;
				}
			}

			Location sprite_location;
			//skip second pass when using asar
			if(!using_asar)
			{

				//get the size of the binary file
				fstream sprite_bin("." PATH_SEP "tmpasm.bin", ios::in | ios::binary);
				if (!sprite_bin) throw Error(NO_BIN_FILE);
				int sprite_bin_size = get_file_size(sprite_bin);
				sprite_bin.close();

				if(!sprite_bin_size) throw Error(".bin file contains nothing");

				//find a location in the rom for the binary file
				sprite_location = find_free_space(sprite_bin_size);
				cout << sprite_location << endl;

				//change the org line to contain the address of where this code is actually going to go
				Location code_start = sprite_location + TAG_SIZE;
				if(!using_xkas){
					org_line[10] = get_hex_digit(code_start.snes_address() % 16);
					org_line[9] = get_hex_digit((code_start.snes_address() >> 4) % 16);
					org_line[8] = get_hex_digit((code_start.snes_address() >> 8) % 16);
					org_line[7] = get_hex_digit((code_start.snes_address() >> 12) % 16);
					org_line[6] = get_hex_digit(code_start.bank() % 16);
					org_line[5] = get_hex_digit((code_start.bank() >> 4) % 16);
				}else{
					xkas_org_line[0x19] = get_hex_digit(code_start.snes_address() % 16);
					xkas_org_line[0x18] = get_hex_digit((code_start.snes_address() >> 4) % 16);
					xkas_org_line[0x17] = get_hex_digit((code_start.snes_address() >> 8) % 16);
					xkas_org_line[0x16] = get_hex_digit((code_start.snes_address() >> 12) % 16);
					xkas_org_line[0x15] = get_hex_digit(code_start.bank() % 16);
					xkas_org_line[0x14] = get_hex_digit((code_start.bank() >> 4) % 16);
				}
				//create tmpasm.asm as before
				sprite_asm_tmp.open("." PATH_SEP "tmpasm.asm", ios::out | ios::binary);
				if (!sprite_asm_tmp) throw Error("couldn't create ." PATH_SEP "tmpasm.asm on second pass");
				if(!using_xkas) sprite_asm_tmp.write(org_line, 13);
				else sprite_asm_tmp.write(xkas_org_line, sizeof(xkas_org_line)-1);
				sprite_asm_tmp.write(asm_file_contents, sprite_asm_size);
				sprite_asm_tmp.close();
				delete [] asm_file_contents;

				if(!using_xkas) system(TRASM_EXECUTABLE " tmpasm.asm -f > temp.log");
                else system(ASAR_EXECUTABLE " tmpasm.asm tmpasm.bin > temp.log");

				sprite_bin.open("." PATH_SEP "tmpasm.bin", ios::in | ios::binary);
				if (!sprite_bin) throw Error("couldn't open ." PATH_SEP "tmpasm.bin on second pass");

				if(!using_xkas){
					//make sure the binaries from the two passes had equal size ...that was our assumption, 
					// and it'd better be true.
					int sprite_bin_size2 = get_file_size(sprite_bin);            
					if (sprite_bin_size2 != sprite_bin_size)
						throw Error("second pass yielded a different file size.  wtf, mate??");

					//HACK ALERT!!  In 3... 2... 1...
					//if there was a problem in TRASM we don't want to try to insert anything into the rom.
					// Since we can really communicate with TRASM, we have to look at the log file it 
					// generates.  we bail if it contains the word "although"... again, huge hack.
					ifstream error_file("." PATH_SEP "TMPASM.ERR");
					string word;
					while (error_file>>word){
						if (word == "Although"){
							// somebody was doing some pretty complicated stuff with asm.  So much that TRASM
							// was reporting an error when there really wasn't.  I added the option to
							// ignore this warning solely for him.
							//TODO: I should make this a command line flag
							// *thank you very much, mikeyk. I appreciate you for all your work!*
						cout << "\n*****************************" << endl
							<< "Error detected in assembling " << sprite_asm_filename << endl
							<< ABORT_MESSAGE << endl;
						string should_i_abort;
						cin >> should_i_abort;
						if (should_i_abort != "no" && should_i_abort != "NO" &&
							should_i_abort != "No" && should_i_abort != "nO")
							throw Error(sprite_asm_filename + " didn't assemble correctly.");
						}
					}

					//it's peanut butter jelly time! we have the binary code to insert and no messy offsets
					// to deal with.  all that's left to do is set up the asm pointers in the table.
				            
					//open binary file into buffer
					char * bin_buffer = new char[sprite_bin_size];
					sprite_bin.seekg(0, ios::beg);
					sprite_bin.read(bin_buffer, sprite_bin_size);

					//determine where the INIT routine and the MAIN routine actually start
					string bin_contents(bin_buffer, sprite_bin_size);
					init_offset = bin_contents.find(INIT_LABEL, 0);
					code_offset = bin_contents.find(MAIN_LABEL, 0);

					if (init_offset == string::npos)
						throw Error("dcb \"INIT\" not found in " + sprite_asm_filename);
					if (code_offset == string::npos)
						throw Error("dcb \"MAIN\" not found in " + sprite_asm_filename);

					//compensate for the INIT and MAIN tags... the actual code starts 4 bytes later
					init_offset += 4;
					code_offset += 4;

					//write the sprite's binary code to the rom
					write_to_rom_with_tags(sprite_location.pc_address(), bin_buffer, sprite_bin_size);
					delete [] bin_buffer;
				}else{
					sprite_bin.clear(); sprite_bin.seekg(-sprite_bin_size, ios::end);
					char *bin_buffer = new char[sprite_bin_size];
					sprite_bin.read(bin_buffer, sprite_bin_size);

					write_to_rom_with_tags(sprite_location.pc_address(), bin_buffer, sprite_bin_size);
				}
				sprite_bin.close();
			}
			else //using_asar=true
			{				
				sprite_location = Location(((asar_offset>>16)&0xFF)-0x80,asar_offset & 0x7FFF);
				cout << sprite_location << endl;

        //asar writes to ROM, so we need to tell the tool that code was inserted there.
        memset(ROMBuf + (sprite_location.pc_address() - HEADER_SIZE), 'X', asar_size); //no TAG_SIZE needed because asar included that in it's count.
        cout << "wrote " << hex << asar_size << " bytes" << endl;

        //fix asar broken RATS tag
        //yes, they are broken in case you didn't know.
        char Tag[8] = { 'S', 'T', 'A', 'R', 0, 0, 0, 0 };
        *(unsigned int*)&Tag[4] = (unsigned int)((asar_size - 9) + (((unsigned short)(~(asar_size - 9))) << 16)); //-9 because: -8 for the RATS size itself and -1 because that's RATS format.
        m_rom_file.seekp(sprite_location.pc_address(), ios::beg);
        m_rom_file.write(Tag, 8);

				//asar labels are already absolute, while the tool from here on expects the offsets to only be the
				//literal offset from the $xx8000, so we subtract the REAL starting position of the code + the RATS tag.
				init_offset-=(asar_offset+TAG_SIZE);
				code_offset-=(asar_offset+TAG_SIZE);
			}

			cout << "init offset: " << sprite_location.bank() << ':' << TAG_SIZE + init_offset + sprite_location.snes_address() << endl;
			cout << "main offset: " << sprite_location.bank() << ':' << TAG_SIZE + code_offset + sprite_location.snes_address() << endl;

			//calculate the asm pointers
			table_row[10] = sprite_location.bank();
			table_row[9] = '\x80';
			relocate(table_row, 8, sprite_location, init_offset);

			table_row[13] = sprite_location.bank();
			table_row[12] = '\x80';
			relocate(table_row, 11, sprite_location, code_offset);

			//write the current sprite's table entry to the rom
			write_to_rom(table_row_start, table_row, 16);


			SprAddresses[sprite_asm_filename].loc = sprite_location;
			SprAddresses[sprite_asm_filename].init= init_offset;
			SprAddresses[sprite_asm_filename].main= code_offset;


		}//End of standard custom sprites insertion code

		//and now for the biggest hack...
		//wow, all this crap just for the poison mushroom?  I should have just made
		// it a custom sprite... apparently this was easier.
		else if (type == 255){
			int poison_num = (unsigned char)table_row[1];
			cout << "poison mushroom to replace sprite " << poison_num << endl;

			//set the tweaker bytes
			write_to_rom(START_1656_TABLE + poison_num, &table_row[2], 1);
			write_to_rom(START_1662_TABLE + poison_num, &table_row[3], 1);
			write_to_rom(START_166E_TABLE + poison_num, &table_row[4], 1);
			write_to_rom(START_167A_TABLE + poison_num, &table_row[5], 1);
			write_to_rom(START_1686_TABLE + poison_num, &table_row[6], 1);
			write_to_rom(START_190F_TABLE + poison_num, &table_row[7], 1);

			//change the asm pointers
			for (int i=8; i<12; ++i){
				sprite_cfg >> hex >> value;
				if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
				table_row[i] = char(value);
			}
			write_to_rom(START_ASM_TABLE + 2*poison_num, &table_row[8], 2);
			write_to_rom(START_INIT_TABLE + 2*poison_num, &table_row[10], 2);

			// now deal with the .bin file
			string mush_bin_file;
			sprite_cfg >> mush_bin_file;
			if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
			mush_bin_file = PATH + mush_bin_file;

			fstream mush_code(mush_bin_file.c_str(), ios::in | ios::binary);
			if (!mush_code) throw Error("couldn't open " + mush_bin_file);
			int code_size = get_file_size(mush_code);
			Location mush_location = find_free_space(code_size);
			cout << mush_location << endl;
			int code_start = mush_location.pc_address() + TAG_SIZE;

			//put the mushroom code in memory
			char * mush_buffer = new char[code_size];
			mush_code.seekg(0, ios::beg);
			mush_code.read(mush_buffer, code_size);

			//change bytes the are sprite number checks
			int num_sprite_refs;
			sprite_cfg >> hex >> num_sprite_refs;
			if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
			for (int i=0; i<num_sprite_refs; ++i){
				int sprite_ref_location;
				sprite_cfg >> hex >> sprite_ref_location;
				if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
				mush_buffer[sprite_ref_location] = char(poison_num);
			}

			//write the bin file to the rom
			write_to_rom_with_tags(mush_location.pc_address(), mush_buffer, code_size);
			delete [] mush_buffer;

			//patch original code
			char mush[4];

			int location, jump_type;
			sprite_cfg >> jump_type >> location;
			if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
			location += (mush_location.snes_address() + TAG_SIZE);

			mush[0] = char(jump_type);
			mush[1] = location & 0x0FF;
			mush[2] = (location >> 8) & 0x0FF;
			mush[3] = mush_location.bank();	
			write_to_rom(0x0C6CB, mush, 4);

			sprite_cfg >> jump_type >> location;
			if (!sprite_cfg) throw Error(sprite_cfg_filename + " contains invalid data");
			location += (mush_location.snes_address() + TAG_SIZE);

			mush[0] = char(jump_type);
			mush[1] = location & 0x0FF;
			mush[2] = (location >> 8) & 0x0FF;
			mush[3] = mush_location.bank();	
			write_to_rom(0x0C8D6, mush, 4);

		}else{
			throw Error("Invalid type number in " + sprite_cfg_filename);
		}
		sprite_cfg.close();
	}

	if (!m_sprite_list.eof()) throw Error("sprite list contains invalid data");
}


Location SpriteTool::find_free_space(int space_needed)
{
  space_needed += TAG_SIZE;

  if (space_needed > 0x8000)
    throw Error(TOO_LARGE);
  unsigned int rom_size = get_file_size(m_rom_file);
  unsigned int number_of_banks = (rom_size - HEADER_SIZE)/BANK_SIZE;
  if (number_of_banks <= 0x10)
    throw Error("Your ROM must be expanded");

	for(unsigned int i = 0x10; i < number_of_banks; i++){						//‹ó‚«ƒXƒy[ƒX‚ð’T‚·
		string current_bank_contents((char*)&ROMBuf[i*BANK_SIZE], BANK_SIZE);	//Bank”Ô†‚ðŒ³‚ÉAROMBuf‚©‚çstring‚É
		string free_space(space_needed,'\0');									// ‹ó‚«ƒXƒy[ƒX‚ª•K—v‚È‚¾‚¯ 0‚Å–„‚ßs‚­‚µ‚½string
		size_t loc = current_bank_contents.find(free_space, 0);
		if( loc != string::npos )
			return Location(i,loc);
	}

  throw Error("Unable to find free space in your ROM");
}


// Main.bin contains all the routines to handle custom sprites.  It has
// already been inserted into the rom, but it is not linked up with the SMW
// code at this point.  The purpose of this function is to insert an
// instruction that will get a particular sprite tool asm routine called.
//
// We determine where the routine is in the rom, we go to the supplied PC
// address, and overwrite the the supplied number of bytes with a call
// into the routine.
void SpriteTool::setup_call_to_asm(int offset, int pc_address,
				    int num_bytes /*= 5*/, bool is_jump /*= false*/)
{
  //By default the call is a JSL, but it can be specified to be a JMP
  char instruction[5] = {'\x22', '\xEA', '\xEA', '\xEA', '\xEA'};
  if (is_jump) instruction[0] = '\x5C';


  //Since we've kept track of where main.bin was inserted into the rom, we can
  // figure out the SNES address of the routine we want to call.  We put this
  // address into the JSL/JMP instruction.
  int routine_location = (m_main_location.snes_address() + TAG_SIZE) + offset;
  instruction[1] = routine_location & 0x0FF;
  instruction[2] = (routine_location >> 8) & 0x0FF;
  instruction[3] = m_main_location.bank();

  //Lastly, we put the instruction into the rom.  We are now linked up.
  write_to_rom(pc_address, instruction, num_bytes);
}


//applies reloc offsets
void SpriteTool::relocate(char* code_buffer, int reloc_offset,
			  Location inserted_location, int code_offset)
{
  int new_value = ((unsigned char)code_buffer[reloc_offset+1] << 8)
    + (unsigned char)code_buffer[reloc_offset];
  new_value += (inserted_location.offset_from_bank_start() + TAG_SIZE + code_offset);
  code_buffer[reloc_offset] = new_value & 0x0FF;
  code_buffer[reloc_offset+1] = (new_value >> 8) & 0x0FF;
}


void SpriteTool::write_to_rom(int pc_address, char* buffer, int size)
{
  m_rom_file.seekp(pc_address, ios::beg);
  m_rom_file.write(buffer, size);
  //After memory allocation, store non-zero value into the buffer
  if(ROMBuf) memset(ROMBuf+(pc_address-HEADER_SIZE), 'X', size);
}


//write some data to the rom with the STAR####MDK tag
void SpriteTool::write_to_rom_with_tags(int pc_address, char* buffer, int size)
{
	m_rom_file.seekp(pc_address, ios::beg);

	char Tag[TAG_SIZE]={'S','T','A','R', 0, 0, 0, 0, 'M','D','K'};
	//calculate and write size/inverse size
	*(unsigned int*)&Tag[4] = (unsigned int)((size + 2) + ( ((unsigned short)(~(size + 2))) <<16));
	m_rom_file.write(Tag, TAG_SIZE);

	//write data
	m_rom_file.write(buffer, size);

	//do the same thing as write_to_rom. Since this routine is always called after malloc, we don't need if()
	memset(ROMBuf+(pc_address-HEADER_SIZE), 'X', size+TAG_SIZE);
	cout << "wrote " << size + TAG_SIZE << " bytes" << endl;
}

//-mikeyk
