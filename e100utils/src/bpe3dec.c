/**
 * Simple BPE3 decompressor
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

bool verbose = false;

unsigned char externalByte;
u_int16_t wordTable[256];

void decompress( FILE *in, FILE *out ) {
    externalByte = fgetc( in );
    for( int i=0; i<256; i++ ) {
        wordTable[ i ] = fgetc( in );
        if ( wordTable[ i ] != externalByte ) {
            wordTable[ i ] *= 256;
            wordTable[ i ] += fgetc( in );
        }
    }
    for( unsigned char c = fgetc( in ); c != externalByte; c = fgetc( in ) ) {
        if ( wordTable[ c ] == externalByte ) {
            fputc( c, out );
        } else {
            fputc( wordTable[ c ] / 256, out );
            fputc( wordTable[ c ] % 256, out );
        }
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

    printf( "BPE3 decompressor\n" );
    decompress( in, out );
    printf( "%s decompressed from %s\n", argv[2], argv[1] );

    if (in != stdin) fclose(in);
    if (out != stdout) fclose(out);
    return 0;
}
