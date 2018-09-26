#include <string>

/********************************************************************
  Constants
********************************************************************/
#if defined(WIN32) || defined(_WIN32)
#define PATH_SEP "\\"
#define TRASM_EXECUTABLE "trasm.exe"
#define XKAS_EXECUTABLE "asar.exe"
#define ASAR_EXECUTABLE "asar.exe"
#else
#define PATH_SEP "/"
#define TRASM_EXECUTABLE "./trasm"
#define XKAS_EXECUTABLE "./asar"
#define ASAR_EXECUTABLE "./asar"
#endif

const int START_ASM_TABLE = 0x87CC;
const int START_INIT_TABLE = 0x837D;
const int START_1656_TABLE = 0x3F46C;
const int START_1662_TABLE = 0x3F535;
const int START_166E_TABLE = 0x3F5FE;
const int START_167A_TABLE = 0x3F6C7;
const int START_1686_TABLE = 0x3F790;
const int START_190F_TABLE = 0x3F859;

const int BANK_SIZE = 0x8000;
const int BANK_STARTING_ADDRESS = 0x8000;
const int HEADER_SIZE = 0x200;
const int TAG_SIZE = 0xB;		//S T A R # # # # M D K
const int SPRITE_TABLE_SIZE = 0x1000;

const std::string GENERATOR_PATH = "." PATH_SEP "generators" PATH_SEP;
const std::string SHOOTER_PATH = "." PATH_SEP "shooters" PATH_SEP;
const std::string SPRITE_PATH = "." PATH_SEP "sprites" PATH_SEP;

const std::string INIT_LABEL = "INIT";
const std::string MAIN_LABEL = "MAIN";

const char * RATS_TAG_LABEL = "STAR";
const char * SPRITE_TOOL_LABEL = "MDK";


const char * WELCOME_MESSAGE = 
	"Sprite Tool v1.41, by mikeyk, asar support.\n"
	"If you get an error when running the program, read the readme for tips.\n"
	"Keep in mind that sprites will not appear correctly in Lunar Magic.\n"
	"usage : SMW.smc list.txt";

const char * ABORT_MESSAGE =
  "It is recommended that you abort Sprite Tool at this time.\n"
  "Do not continue unless you are absolutely sure of what you are doing.\n"
  "Trying to continue will probably corrupt you ROM!\n"
  "Do you want to take my advice and quit? (Type yes or no)";

const char * BAD_NUM =
  "Custom sprite numbers E0-FF are undefined.  Please check your sprite list.\n"
  "See the readme for more information";

const char * TOO_LARGE =
  "Your file won't fit in a bank.  Be sure you do not have an org statement\n"
  "in the .asm file";

const char * NO_BIN_FILE =
  "Couldn't open ." PATH_SEP "tmpasm.bin.  Make sure TRASM.EXE is in the same directory\n"
  "and that it can run on your system.";

