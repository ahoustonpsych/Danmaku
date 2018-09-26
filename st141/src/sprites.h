#include <fstream>
#include <string>

#include <cstring>
#include <cstdlib>

#include "sprites_const.h"

class Location{
 public:
  
 Location() :
    m_bank_number(0),
    m_snes_address(0),
    m_pc_address(0)
  { }
  
  Location(int bank, int offset) :
    m_bank_number(bank),
    m_snes_address(BANK_STARTING_ADDRESS + offset),
    m_pc_address(HEADER_SIZE + BANK_SIZE * m_bank_number + offset)
  { }
  
  inline int pc_address() const { return m_pc_address; }
  inline int bank() const { return m_bank_number|0x80; }
  inline int snes_address() const { return m_snes_address; }
  inline int offset_from_bank_start() const
  { return m_snes_address - BANK_STARTING_ADDRESS; }

private:
  int m_bank_number;
  int m_snes_address;

  int m_pc_address;
};

class Location2{
public:

	Location loc;
	int init;
	int main;

};


class SpriteTool{
public:
	SpriteTool(std::fstream& rom_file, std::ifstream& sprite_list, char *rom_file_name) :
	m_rom_file(rom_file),
	m_sprite_list(sprite_list),
	ROMBuf(NULL)
	{
	}
	void Initialize(void);
	~SpriteTool()
	{
		if(ROMBuf) delete [] ROMBuf;
	};
  
	void clean_rom();
	void LoadROMAndMarkRATS(void);
	void insert_main_routine();
	void insert_sprites();

	Location find_free_space(int space_needed);  
  
private:
	void relocate(char* code_buffer, int reloc_offset,
		Location inserted_location, int code_offset=0);
	void setup_call_to_asm(int offset, int pc_address,
			 int num_bytes = 5, bool is_jump = false);
	void write_to_rom_with_tags(int pc_address, char* buffer, int size);
	void write_to_rom(int pc_address, char* buffer, int size);
  void reload_rom();

private: 
	std::fstream& m_rom_file;
	std::ifstream& m_sprite_list;
	int m_table_start;
	Location m_main_location;

	unsigned char *ROMBuf;

};
