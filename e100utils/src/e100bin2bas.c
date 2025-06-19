/***************************************************
 * e100nin2bas, 2025.05. Princz László
 *
 * Convert Esselte 100 binary file to bas source code
 * Esselte 100 memory map
 *   0000 - 0036 : Felhasználható
 *   023E - 0286 : 72 bájtos puffer a BASIC értelmező számára
 *   0287 - ...  : BASIC program
 * Memory map after RUN with default parameters
 *   0287 - 02E9 : BASE 64 decoder
 *   02EA - 02EB : Safe area
 *   02EC - ...  : Decodec data. Ide kerül a kikódolt program
 *   046D - ...  : Encoded data. Itt kezdődik az elkódolt adat
 * 0F12 - 0C27 (3111) + 1 = 02EC
 * dekóder program vége
 * 02EC LDX 0437
 * 02E5 LDS #$0286
 * 02E8 JMP (X) :   X: 02F5????
 *
 * 02EC LDX #0304   ; MUSIC_DATA    0304 , 0327 ,  
 * ...
 * 02F6 JSR 055C    ; PRINT_AT_X
 * 02F9 INX
 * 02FA JSR 05FA    ; PLAY_MUSIC_X   X=0327 -> X=03E3
 * 02FD INX         ; after: X=03E4
 ****************************************************/
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "getopt.h"
#include "math.h"

#define VM 0
#define VS 1
#define VB 'b'

const int SHIFT = 33; // A 6 bites elkódolt adatok eltolása. 33-96
const int RANGE = 64; // 64 különböző értéket vehet fel az elkódolt adat. Ez még tárolható a REM sorban [32-127]
const int DEC_BLOCK_LEN = 3; // Egy elkodolás nélküli blokk hossza bájtokban
const int ENC_BLOCK_LEN = 4; // Egy elkódolt blokk hossza bájtokban
const int ENC_LINE_LEN = 64; // Egy DATA sorban található elkódolt string hossza
const int DEC_LINE_LEN = 48; // Egy sorban található elkódolás nélküli bájtok száma = ENC_LINE_LEN/ENC_BLOCK_LEN*DEC_BLOCK_LEN

#define compression_type_uncompressed 0
#define compression_type_lzss3 1
#define compression_type_bpe3 2
unsigned char binaryCompressionType = compression_type_uncompressed;

bool verbose = false;
bool smallLoaderMode = false; // If true, the full binary code encoded in standard BASIC DATA line as decimal numbers
u_int16_t loaderStartAddress = 0x0287; //=(647d) 0x023E=(574d)
u_int16_t mainStartAddress = 0; // loaderStartAddress + loaderSizeWithSafeArea; // 0x02FA; // Default value = the first free byte after loader

u_int16_t getLoaderSize() {
    switch( binaryCompressionType ) {
        case compression_type_uncompressed : return 113; break;
        case compression_type_lzss3 : return 176; break;
        case compression_type_bpe3 : return 217; break;
        default : fprintf( stderr, "Invalid compression type: %d\n", binaryCompressionType ); exit(1);
    }
}
u_int16_t getLoaderSizeWithSafeArea() { return getLoaderSize() + DEC_BLOCK_LEN - 1; } // A BASE64 kódolás kikódolásakor a blokkméret miatt még maximum ennyi bájttal a betöltési cím elé csúszhatunk!

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Base64 functions begin
//////////////////////////////////////////////////////////////////////////////////////////////////////////
u_int32_t getBase64BigInt( unsigned char* DATA, u_int16_t from0, u_int16_t counter ) { // 32 bites szám kiszámítása:
    u_int32_t NUM = 0;
    for( u_int16_t i = 0; i < counter; i++ ) NUM = NUM * 256 + DATA[ from0 + i ];
    return NUM;
}

char* getBase64Block( unsigned char* DATA, u_int16_t from0, char* chars ) { // DEC_BLOCK_LEN -> ENC_BLOCK_LEN bytes, encoding
    u_int32_t num = getBase64BigInt( DATA, from0, DEC_BLOCK_LEN );
    for( u_int16_t i = 0; i <= ENC_BLOCK_LEN; i++ ) chars[i] = 0;
    for( u_int16_t i = 0; i < ENC_BLOCK_LEN; i++ ) {
        chars[ ENC_BLOCK_LEN - i - 1 ] = ( num % RANGE ) + SHIFT;
        num = num / RANGE;
    }
    return chars;
}

char* getBase64Line( unsigned char* DATA, u_int16_t counter, char* result ) { // Maximum 64 darab BASE64 kódolással elkódolt bájt-négyes generálása, ami a forrásadatokból maximum 48 bájtot jelent
    for( u_int16_t i = 0; i <= ENC_LINE_LEN; i++ ) result[i] = 0;
    while ( counter % DEC_BLOCK_LEN ) counter++; // teljes elkódolandó blokkoká egészítjük ki
    char chars[ ENC_BLOCK_LEN + 1 ];
    for( u_int16_t i = 0; i < counter; i += DEC_BLOCK_LEN ) {
        strcat( result, getBase64Block( DATA, i, chars ) );
    }
    // checkResult( $result, $startIndex0, @DATA );
    // print "ok\n";
    return result;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Base64 functions end
//////////////////////////////////////////////////////////////////////////////////////////////////////////

u_int16_t printBpe3CompressedBASloaderPrefix( FILE* BAS, u_int16_t LN )  {
    u_int8_t destAddrHigh = mainStartAddress / 256;
    u_int8_t destAddrLow = mainStartAddress % 256;
    u_int8_t loaderAddrHigh = loaderStartAddress / 256;
    u_int8_t loaderAddrLow = loaderStartAddress % 256;
    const u_int16_t sourceAddress = 0x05D4; // A basic forráskódban az első DATA első adatának címe
    u_int8_t sourceAddrHigh = sourceAddress / 256;
    u_int8_t sourceAddrLow = sourceAddress % 256;
    fprintf( BAS, "%d ? \"LOAD %04XH\":POKE(252,%03d):POKE(253,%03d)\n", LN++, mainStartAddress, loaderAddrHigh, loaderAddrLow );
    //                   LDS       LDX
    fprintf( BAS, "%d DATA 206,%03d,%03d,223,10,223,12,206,%03d,%03d,134,0,151,19,166,0,38,4,8,8\n", LN++, destAddrHigh, destAddrLow, sourceAddrHigh, sourceAddrLow );
    fprintf( BAS, "%d DATA 32,80,129,97,39,82,128,33,151,2,166,1,128,33,151,3,166,2,128,33\n", LN++ );
    fprintf( BAS, "%d DATA 151,4,166,3,128,33,151,5,150,2,72,72,151,6,150,3,68,68,68,68,154\n", LN++ );
    fprintf( BAS, "%d DATA 6,151,14,150,3,132,15,72,72,72,72,151,7,150,4,68,68,154,7,151,15\n", LN++ );
    fprintf( BAS, "%d DATA 150,4,132,3,72,72,72,72,72,72,154,5,151,16,223,8,32,12,222,8,8,8\n", LN++ );
    fprintf( BAS, "%d DATA 8,8,32,162,222,12,110,0,206,0,14,223,23,166,0,214,19,38,9,151,18\n", LN++ );
    fprintf( BAS, "%d DATA 206,194,0,223,19,32,32,193,196,39,38,145,18,38,68,222,19,167,0,8\n", LN++ );
    fprintf( BAS, "%d DATA 167,0,8,223,19,32,12,230,1,222,10,167,0,8,231,0,8,223,10,222,23\n", LN++ );
    fprintf( BAS, "%d DATA 8,140,0,17,38,199,32,182,145,18,39,186,198,194,72,201,0,215,21\n", LN++ );
    fprintf( BAS, "%d DATA 151,22,222,21,166,0,145,18,38,213,222,23,166,0,222,10,167,0,8,223\n", LN++ );
    fprintf( BAS, "%d DATA 10,32,212,222,19,167,0,8,223,19,32,203\n", LN++ );
    fprintf( BAS, "%d FOR M=%d TO %d:READ V:POKE(M,V):NEXT M:R=USER(0)\n", LN++, loaderStartAddress, loaderStartAddress + getLoaderSize()-1 );
    return LN;
}

u_int16_t printLzss3CompressedBASloaderPrefix( FILE* BAS, u_int16_t LN )  {
    u_int8_t destAddrHigh = mainStartAddress / 256;
    u_int8_t destAddrLow = mainStartAddress % 256;
    u_int8_t loaderAddrHigh = loaderStartAddress / 256;
    u_int8_t loaderAddrLow = loaderStartAddress % 256;
    const u_int16_t sourceAddress = 0x0543 ; // A basic forráskódban az első DATA első adatának címe
    u_int8_t sourceAddrHigh = sourceAddress / 256;
    u_int8_t sourceAddrLow = sourceAddress % 256;
    fprintf( BAS, "%d ? \"LOAD %04XH\":POKE(252,%03d):POKE(253,%03d)\n", LN++, mainStartAddress, loaderAddrHigh, loaderAddrLow );
    //                   LDS       LDX
    fprintf( BAS, "%d DATA 206,%03d,%03d,223,10,223,12,206,%03d,%03d,134,0,151,17,166,0,38,4,8,8\n", LN++, destAddrHigh, destAddrLow, sourceAddrHigh, sourceAddrLow );
    fprintf( BAS, "%d DATA 32,107,129,97,39,109,128,33,151,2,166,1,128,33,151,3,166,2,128,33\n", LN++ );
    fprintf( BAS, "%d DATA 151,4,166,3,128,33,151,5,150,2,72,72,151,6,150,3,68,68,68,68\n", LN++ );
    fprintf( BAS, "%d DATA 154,6,151,14,150,3,132,15,72,72,72,72,151,7,150,4,68,68,154,7\n", LN++ );
    fprintf( BAS, "%d DATA 151,15,150,4,132,3,72,72,72,72,72,72,154,5,151,16,223,8,222,10\n", LN++ );
    fprintf( BAS, "%d DATA 125,0,17,39,34,122,0,17,39,45,150,14,167,0,8,150,15,167,0,8\n", LN++ );
    fprintf( BAS, "%d DATA 150,16,167,0,8,223,10,222,8,8,8,8,8,32,135,222,12,110,0,150\n", LN++ );
    fprintf( BAS, "%d DATA 15,167,0,8,150,16,167,0,8,150,14,151,17,32,226,122,0,16,39,221\n", LN++ );
    fprintf( BAS, "%d DATA 222,14,166,0,8,223,14,222,10,167,0,8,223,10,32,235\n", LN++ );

    fprintf( BAS, "%d FOR M=%d TO %d:READ V:POKE(M,V):NEXT M:R=USER(0)\n", LN++, loaderStartAddress, loaderStartAddress + getLoaderSize()-1 );
    return LN;
}

u_int16_t printUncompressedBASloaderPrefix( FILE* BAS, u_int16_t LN )  {
    u_int8_t destAddrHigh = mainStartAddress / 256;
    u_int8_t destAddrLow = mainStartAddress % 256;
    u_int8_t loaderAddrHigh = loaderStartAddress / 256;
    u_int8_t loaderAddrLow = loaderStartAddress % 256;
    const u_int16_t sourceAddress = 0x0467; // A basic forráskódban az első DATA első adatának címe
    u_int8_t sourceAddrHigh = sourceAddress / 256;
    u_int8_t sourceAddrLow = sourceAddress % 256;
    fprintf( BAS, "%d ? \"LOAD %04XH\":POKE(252,%03d):POKE(253,%03d)\n", LN++, mainStartAddress, loaderAddrHigh, loaderAddrLow );
    //                   LDS       LDX
    fprintf( BAS, "%d DATA 206,%03d,%03d,223,10,223,12,206,%03d,%03d,166,0,38,4,8,8,32,85\n", LN++, destAddrHigh, destAddrLow, sourceAddrHigh, sourceAddrLow );
    fprintf( BAS, "%d DATA 129,97,39,87,128,33,151,2,166,1,128,33,151,3,166,2,128,33,151,4\n", LN++ );
    fprintf( BAS, "%d DATA 166,3,128,33,151,5,150,2,72,72,151,6,150,3,68,68,68,68,154,6\n", LN++ );
    fprintf( BAS, "%d DATA 223,8,222,10,167,0,8,150,3,132,15,72,72,72,72,151,7,150,4,68\n", LN++ );
    fprintf( BAS, "%d DATA 68,154,7,167,0,8,150,4,132,3,72,72,72,72,72,72,154,5,167,0\n", LN++ );
    fprintf( BAS, "%d DATA 8,223,10,222,8,8,8,8,8,32,157,222,12,110,0\n", LN++ );
    fprintf( BAS, "%d FOR M=%d TO %d:READ V:POKE(M,V):NEXT M:R=USER(0)\n", LN++, loaderStartAddress, loaderStartAddress + getLoaderSize()-1 );
    return LN;
}

void readData( FILE* bin, u_int16_t fromIndex0, u_int16_t toIndex0, char* DATA ) {
    for( u_int16_t i = 0; i <= DEC_LINE_LEN; i++ ) DATA[i] = 0;
    if ( fseek( bin, fromIndex0, SEEK_SET ) != 0 ) {
        perror("fseek error in reverse read");
        exit(1);
    }
    u_int16_t counter = toIndex0 - fromIndex0 + 1;
    u_int16_t max_index = counter - 1;
    for( u_int16_t i = 0; i<=max_index; i++ ) DATA[ i ] = fgetc( bin );
}

const int max_bas_line_length = 66;

void simpleDataLoader( FILE* bin, FILE* BAS, u_int16_t MAX ) {
    u_int16_t LN = 1;
    fprintf( BAS, "%d ? \"LOAD %04XH\":POKE(252,%03d):POKE(253,%03d)\n", LN++, mainStartAddress, mainStartAddress / 256, mainStartAddress % 256 );
    u_int16_t start_pos = ftell( BAS );
    fprintf( BAS, "%d DATA ", LN++ );
    u_int16_t pos = 0;
    for( u_int16_t i0 = 0; i0 <= MAX; i0++ ) {
        fprintf( BAS, "%d", fgetc( bin ) );
        pos = ftell( BAS );
        if ( pos - start_pos < max_bas_line_length && i0 < MAX ) {
            fprintf( BAS, "," );
        } else {
            fprintf( BAS, "\n" );
            if ( i0 < MAX ) fprintf( BAS, "%d DATA ", LN++ );
            start_pos = pos + 1;
        }
    }
    fprintf( BAS, "%d FOR M=%d TO %d:READ V:POKE(M,V):NEXT M:R=USER(0)\n", LN++, mainStartAddress, mainStartAddress + MAX );
}

void base64likeLoader( FILE* bin, FILE* BAS, u_int16_t MAX ) {
    u_int16_t LN = 1;
    char line_result[ ENC_LINE_LEN + 1 ];
    unsigned char DATA[ DEC_LINE_LEN ];
    switch( binaryCompressionType ) {
        case compression_type_uncompressed : LN = printUncompressedBASloaderPrefix( BAS, LN ); break;
        case compression_type_lzss3 : LN = printLzss3CompressedBASloaderPrefix( BAS, LN ); break;
        case compression_type_bpe3 : LN = printBpe3CompressedBASloaderPrefix( BAS, LN ); break;
        default : fprintf( stderr, "Invalid compression type: %d\n", binaryCompressionType ); exit(1);
    }
    for( u_int16_t fromIndex0 = 0; fromIndex0 <= MAX; fromIndex0 += DEC_LINE_LEN ) {
        u_int16_t toIndex0 = fromIndex0 + DEC_LINE_LEN - 1;
        if ( toIndex0 > MAX ) toIndex0 = MAX;
        readData( bin, fromIndex0, toIndex0, DATA );
        u_int16_t block_size = toIndex0 - fromIndex0 + 1; // Hasznos adat mérete
        fprintf( BAS, "%d ! %s\n", LN++, getBase64Line( DATA, block_size, line_result ) );
    }
    fprintf( BAS, "%d ! a\n", LN++ );
    if ( verbose ) fprintf( stdout, "First free address after loader: 0x%04X\n", loaderStartAddress + getLoaderSizeWithSafeArea() );
}

void convert( FILE* bin, FILE* BAS ) {
    if ( verbose ) fprintf( stdin, "Main load address: 0x%04X (%d)\n", mainStartAddress, mainStartAddress );
    if (fseek( bin, 0, SEEK_END) != 0) {    // Álljunk a fájl végére
        perror("fseek error");
        exit(1);
    }
    u_int16_t mainSize = ftell( bin );
    if ( !mainSize ) {
        perror("source file is empty");
        exit(1);
    }
    u_int16_t MAX = mainSize - 1;
    if (fseek( bin, 0, SEEK_SET ) != 0) {    // Álljunk a fájl végére
        perror("fseek 2 error");
        exit(1);
    }
    if ( smallLoaderMode ) {
        simpleDataLoader( bin, BAS, MAX );
    } else {
        base64likeLoader( bin, BAS, MAX );
    }
}

void print_usage() {
    printf( "e100bin2bas v%d.%d%c (build: %s)\n", VM, VS, VB, __DATE__ );
    printf( "Create Esselte 100 BASIC source code from binary assembly file.\n");
    printf( "Copyright 2025 by László Princz\n");
    printf( "Usage:\n");
    printf( "e100bin2bas [options] <input_filename> [<output_filename_without_bas_extension>]\n" );
    printf( "Loader size in with safe area 0x%02X (%d) bytes.\n", getLoaderSizeWithSafeArea(), getLoaderSizeWithSafeArea() );
    printf( "Command line options:\n");
    printf( "-v          : set verbose mode\n" );
    printf( "-l hexAddr  : loader code start address in hex format. Default value is 0x%04X\n", loaderStartAddress );
    printf( "-m hexAddr  : main binary code load/start address in hex format. Default value is 0x%04X\n", mainStartAddress );
    printf( "-s          : for small binary code (<120 bytes) - no special loader required\n" );
    printf( "-L          : for LZSS compressed binary\n" );
    printf( "-B          : for BPE compressed binary\n" );
    printf( "-w          : write only the start address of the binary code to the stdout in hex format and exit\n" );
    printf( "-h          : prints this text\n");
    printf( "Example:\n");
    printf( "e100bin2bas binary.obj 0x%04X\n", mainStartAddress );
    exit(1);
}

int main(int argc, char *argv[]) {
    bool finished = false;
    int argd = argc;

    bool manualStartAddr = false;
    bool writeOutOnlyMainStartAddress = false;
    mainStartAddress = loaderStartAddress + getLoaderSizeWithSafeArea(); // 0x02FC; // Default value = the first free byte after loader

    while ( !finished ) {
        switch ( getopt ( argc, argv, "?hvwsLBm:l:" ) ) {
            case -1:
            case ':':
                finished = true;
                break;
            case '?':
            case 'h':
                print_usage();
                break;
            case 'm' :
                if ( !sscanf( optarg, "%x", &mainStartAddress ) ) {
                    fprintf( stderr, "Error parsing argument for '-m'.\n");
                    exit(2);
                }
                manualStartAddr = true;
                break;
            case 'l' :
                if ( !sscanf( optarg, "%x", &loaderStartAddress ) ) {
                    fprintf( stderr, "Error parsing argument for '-l'.\n");
                    exit(2);
                }
                break;
            case 'w':
                writeOutOnlyMainStartAddress = true;
                break;
            case 's':
                smallLoaderMode = true;
                break;
            case 'L':
                binaryCompressionType = compression_type_lzss3;
                break;
            case 'B':
                binaryCompressionType = compression_type_bpe3;
                break;
            case 'v':
                verbose = true;
                break;
            default:
                break;
        }
    }

    if ( !manualStartAddr ) mainStartAddress = loaderStartAddress + getLoaderSizeWithSafeArea(); // 0x02FC; // Default value = the first free byte after loader
    if ( writeOutOnlyMainStartAddress ) {
        fprintf( stdout, "0x%04X\n", mainStartAddress );
        exit(0);
    }

    if ( smallLoaderMode && binaryCompressionType ) { // Ha nem uncompressed
        fprintf( stderr, "In small loader mode don't use compressed binary source!\n");
        exit(2);
    }

    if ( argc - optind > 0 ) {
        char inname[ 280 ]; // Input filename
        char outname[ 280 ]; // Output filename
        FILE *fin,*fout;
        strcpy( inname, argv[ optind ] );
        strcpy( outname, inname ); // The default output name is input filename + .bas
        if ( argc - optind > 1 ) strcpy( outname, argv[ optind + 1 ] );
        if ( argc - optind > 2 ) print_usage();
        strcat( outname, ".bas" );
        if ( fin = fopen( inname, "rb" ) ) {
            if ( fout = fopen( outname, "wb" ) ) {
                if ( verbose ) fprintf( stdout, "Start conversion from '%s' to '%s'\n", inname, outname );
                convert( fin, fout );
                fclose( fout );
                fclose( fin );
            } else {
                fprintf( stderr, "Error creating %s.\n", outname );
                exit(4);
            }
        } else {
            fprintf( stderr, "Error opening %s.\n", inname );
            exit(4);
        }
    } else {
        print_usage();
    }
}
