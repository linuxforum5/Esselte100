/**
 * LZSS3 Absolute compresszor for BASE64 like encoding
 * The compressed file is list of blocks. All block contains 3 bytes.
 * FDB : the first data block structure:
 * - C : next block counter (1 byte)
 * - D1: first data byte (1 byte)
 * - D2: second data byte (1 byte)
 * The first data block follow (C-1) NDB, and 1 BRB
 * NDB : the scond data block structure
 * - D1: first data byte (1 byte)
 * - D2: second data byte (1 byte)
 * - D3: third data byte (1 byte)
 * BRB : the back reference block structure
 * - AH: absolute address of the data source HIGH byte (1 byte)
 * - AL: absolute address of the data source LOW byte (1 byte)
 * - L: byte counter for copying (1 byte) Decrement before use it (1 means no copying data, 0 means 255 bytes for copy)
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#define MAX_LENGTH 255

u_int16_t addressShift = 0;
u_int16_t MIN_MATCH = 5;

/**
 * Az előállított blokklista 3 féle blokkot tartalmazhat: FL, LB, BR
 * - FL: First Literal block. Hossza: 3 bájt. Szerkezete: [ hossz, adat, adat ]
 * - LB: Literl Block. Hossza: 3 bájt. Szerekezete: [ adat, adat, adat ]
 * - BR: Back Reference block. Hossza: 3 bájt. Szerekezete: [ addressHig, addressLow, length ]
 * A tömörített adat formátuma blokkokban a következő: [FL,LB*,BR]+
 */
typedef struct BackReference {
   u_int16_t address;
   u_int8_t length;
} BR;

BR find_BRB( const char* input, const int isize, const int ipos0 ) {
    BR br;
    br.address = 0;
    br.length = 0;
    int match_start = 0; // Innentől van az egyezőség
    for( int i=0; i<ipos0; i++ ) {
        int match_length = 0;
        while( match_length < MAX_LENGTH 
            && i + match_length < ipos0
            && ipos0 + match_length < isize
            && input[ i + match_length ] == input[ ipos0 + match_length ] ) {
            match_length++;
            if ( match_length >= MIN_MATCH ) { // Ez már lehet BR. De jobb, mint az eddigi?
                if ( match_length > br.length ) {
                    br.length = match_length;
                    br.address = i;
                }
            }
        }
    }
    return br;
}

int write_BRB( FILE* out, BR br ) {
    u_int16_t a = br.address + addressShift;
//printf( "Pos.: 0x%04X, Addr.: 0x%04X, Shifted addr.: 0x%04X\n", ftell( out ), br.address, a );
    fputc( a / 256, out );
    fputc( a % 256, out );
    fputc( br.length + 1, out );
    return br.length;
}

int write_FDB( FILE* out, const char* input, const int size, const int ipos ) {
    fputc( 1, out );
    fputc( input[ipos], out );
    fputc( input[ipos+1], out );
    return 2;
}

int write_NDB( FILE* out, const char* input, const int size, const int ipos ) {
    fputc( input[ipos], out );
    fputc( input[ipos+1], out );
    fputc( input[ipos+2], out );
    return 3;
}

void writeBackLiteralBlockCounter( FILE* out, unsigned long pos, u_int8_t counter ) { // Counter = az utána következő NDB és BRB összege
    if ( !counter ) {
        fprintf( stderr, "Write back error\n" );
        exit(1);
    }
    unsigned long current_pos = ftell( out );
    fseek( out, pos, SEEK_SET );
    fputc( counter, out );
    fseek( out, current_pos, SEEK_SET );
}

void compress(FILE *in, FILE *out) {
    unsigned char input[65536];
    size_t input_size = fread(input, 1, sizeof(input), in); // Beolvassuk a tömörítendő fájlt
    // printf( "Uncompressed size: %d\n", input_size );
    unsigned long firstLiteralBlockFirstBytePos = 0;
    int compressed_size = 0; // Az eddig már betömörített adatmennyiség, azaz itt tartunk az input tömb olvasásában
    int literalBlockCounter = 0; // Ha ez nulla, mindenképpen FL jön
    while( compressed_size < input_size ) {
        BR br = find_BRB( input, input_size, compressed_size );
        if ( literalBlockCounter && br.length ) {
            if ( literalBlockCounter > 1 ) writeBackLiteralBlockCounter( out, firstLiteralBlockFirstBytePos, literalBlockCounter );
            compressed_size += write_BRB( out, br );
            literalBlockCounter = 0;
        }
        if ( literalBlockCounter == 255 ) { // 256 literal block van már egymás után, és nem volt közbe BR. Akkor beteszünk egy üreset.
            writeBackLiteralBlockCounter( out, firstLiteralBlockFirstBytePos, literalBlockCounter );
            compressed_size += write_BRB( out, br );
            literalBlockCounter = 0;
        }
        literalBlockCounter++;
        if ( literalBlockCounter == 1 ) { // First data block
            firstLiteralBlockFirstBytePos = ftell( out );
            compressed_size += write_FDB( out, input, input_size, compressed_size );
        } else { // Egy köztes adatblokk
            compressed_size += write_NDB( out, input, input_size, compressed_size );
        }
    }
    if ( literalBlockCounter > 1 ) writeBackLiteralBlockCounter( out, firstLiteralBlockFirstBytePos, literalBlockCounter ); // Több literal blokk is kiírásra került
    printf( "Address shift: 0x%04X, Completed uncompressed size: %d, Compressed size: %d, Min. match=%d\n", addressShift, compressed_size, ftell( out ), MIN_MATCH );
}

int main(int argc, char *argv[]) {
    FILE *in = stdin;
    FILE *out = stdout;

    if (argc >= 2) {
        in = fopen(argv[1], "rb");
        if (!in) {
            perror("Input file");
            return 1;
        }
    }

    if (argc >= 3) {
        out = fopen(argv[2], "wb");
        if (!out) {
            perror("Output file");
            return 1;
        }
    }

    if (argc >= 4) {
        if ( !sscanf( argv[3], "%x", &addressShift ) ) {
            fprintf( stderr, "Error parsing address.\n");
            exit(2);
        }
    }

    if (argc >= 5) {
        if ( !sscanf( argv[4], "%x", &MIN_MATCH ) ) {
            fprintf( stderr, "Error parsing min match.\n");
            exit(2);
        }
    }

    compress(in, out);

    if (in != stdin) fclose(in);
    if (out != stdout) fclose(out);
    return 0;
}
