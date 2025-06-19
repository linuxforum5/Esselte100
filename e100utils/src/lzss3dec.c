#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

bool verbose = false;

unsigned char output[65536] = {0};
u_int16_t outpos = 0;

void _fputc( unsigned char byte, FILE* out ) {
    output[ outpos++ ] = byte;
    fputc( byte, out );
}

int unpack_FDB( FILE *in, FILE *out ) {
    u_int8_t counter = fgetc( in );
    if ( feof( in ) ) {
        return 0;
    } else {
        _fputc( fgetc( in ), out );
        _fputc( fgetc( in ), out );
        return counter;
    }
}

void unpack_NDB( FILE *in, FILE *out ) {
    _fputc( fgetc( in ), out );
    _fputc( fgetc( in ), out );
    _fputc( fgetc( in ), out );
}

void unpack_BRB( FILE *in, FILE *out ) {
    u_int16_t addr = fgetc( in ) * 256 + fgetc( in );
    u_int8_t length = fgetc( in ) - 1;
    if ( !feof(in) && length ) for( int i=0; i<length; i++ ) _fputc( output[ addr + i ], out );
}

void decompress( FILE *in, FILE *out ) {
    while( !feof( in ) ) {
        //printf( "\nStart FDB - Compressed: 0x%04X, Decompressed: 0x%04X\n", ftell( in ), ftell( out ) );
        int counter = unpack_FDB( in, out );
        //printf( "Start NDB - Compressed: 0x%04X, Decompressed: 0x%04X\n", ftell( in ), ftell( out ) );
        for( int i=0; i<counter-1; i++ ) unpack_NDB( in, out );
        //printf( "Start BRB - Compressed: 0x%04X, Decompressed: 0x%04X\n", ftell( in ), ftell( out ) );
        if ( !feof( in ) ) unpack_BRB( in, out );
    }
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

    printf( "LZSS3 decompressor\n" );
    decompress(in, out);
    printf( "%s decompressed from %s\n", argv[2], argv[1] );

    if (in != stdin) fclose(in);
    if (out != stdout) fclose(out);
    return 0;
}
