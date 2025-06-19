/**
 * BPE3 Absolute compresszor for BASE64 like encoding
 * The compressed file format:
 * - First byte is an external byte code. The uncompressed file doesn't contanins this byte.
 * - The table of byte pairs = 256*byte pair data ( for ecah byte value)
 *    - If there is no pair for the byte, then the stored value is one external byte value.
 *    - If there is a pair for the byte, the stored value the two bytes.
 * - The compressed bytes
 * - External byte value (EOF)
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

bool verbose = true;

unsigned int byte_counter = 0;
unsigned int byteCounters[256] = {0};
unsigned char externalByte;
unsigned int unusedBytesCounter = 0;
unsigned char unusedBytes[256] = {0};
u_int16_t usedWords[65536] = {0};
u_int16_t byte2word[256] = {0};

void countBytes( FILE *in ) {
    for( unsigned char c = fgetc( in ); !feof( in ); c = fgetc( in ) ) {
        byteCounters[ c ]++;
        byte_counter++;
    }
}

void searchUnusedBytes() {
    unsigned char min = 255;
    unsigned char max = 0;
    for( int i=0; i<256; i++ ) {
        if ( byteCounters[ i ] == 0 ) {
            // if ( verbose ) fprintf( stdout, "%d. unsued byte: %02X\n", unusedBytesCounter, i );
            unusedBytes[ unusedBytesCounter++ ] = i;
            if ( i < min ) min = i;
            if ( i > max ) max = i;
        }
    }
    if ( verbose ) fprintf( stdout, "Free bytes: %d [ %d - %d ]\n", unusedBytesCounter, min, max );
}

void countUsedWords( FILE *in ) {
    // for( my $i=0; $i<$#bytes; $i+=2 ) {
    fseek( in, 0, SEEK_SET );
    unsigned char c1 = fgetc( in );
    for( int i=1; i<byte_counter; i++ ) {
        unsigned char c2 = fgetc( in );
        u_int16_t word = c1 * 256 + c2;
        c1 = c2;
        usedWords[ word ]++;
    }
    if ( verbose ) fprintf( stdout, "Words counted\n" );
}

u_int16_t searchMostUsedWord() {
    unsigned long maxCounter = 0;
    u_int16_t maxWord = externalByte;
    for( u_int32_t i=0; i<65536; i++ ) {
        if ( usedWords[ i ] > maxCounter ) {
            maxCounter = usedWords[ i ];
            maxWord = i;
        }
    }
    // usedWords[ maxWord ] = 0;
    // printf( "** %d.=%d\n", maxWord, maxCounter );
    return maxWord;
}

void createWordsTable() {
    for( int i=0; i<256; i++ ) {
        byte2word[ i ] = externalByte;
    }
    int cnt = 0;
    long sum = 0;
    unsigned int unusedBytesIndex0 = 0;
    for( u_int16_t mostUsedWord = searchMostUsedWord()
       ; ( mostUsedWord != externalByte ) && ( unusedBytesIndex0 < unusedBytesCounter )
       ; mostUsedWord = searchMostUsedWord() ) {
        unsigned char unusedByte = unusedBytes[ unusedBytesIndex0++ ];
        byte2word[ unusedByte ] = mostUsedWord;
        cnt++;
        sum += usedWords[ mostUsedWord ];
        usedWords[ mostUsedWord ] = 0;
    }
    if ( verbose ) fprintf( stdout, "Table created from %d pairs. Sum=%d\n", cnt, sum );
}

int getPairIndex( u_int16_t word ) {
    int foundIndex = -1;
    if ( word != externalByte ) {
        for( int i=0; i<256; i++ ) {
            if ( byte2word[ i ] == word ) foundIndex = i;
        }
    }
    return foundIndex;
}

void writeWord( FILE* out, u_int16_t word ) {
    fputc( word / 256, out );
    fputc( word % 256, out );
}

void writeData( FILE *in, FILE *out ) {
    fputc( externalByte, out );
    for( int i=0; i<256; i++ ) {
        if ( byte2word[ i ] == externalByte ) {
            fputc( externalByte, out );
        } else {
            writeWord( out, byte2word[ i ] );
        }
    }
    unsigned long cnt = 0;
    unsigned char lastByte = 0;
    fseek( in, 0, SEEK_SET );
    u_int16_t c1 = fgetc( in );
    if ( verbose ) fprintf( stdout, "Bytes: %d\n", byte_counter );
    for( u_int16_t i=1; i<byte_counter; i++ ) {
        u_int16_t c2 = fgetc( in );
        u_int16_t word = c1 * 256 + c2;
        int representatorByte = -1;
        representatorByte = getPairIndex( word );
        if ( representatorByte == -1 ) { // not found
            fputc( c1, out );
            lastByte = 1;
        } else { // found
            lastByte = 0;
            i++;
            fputc( representatorByte, out );
            c2 = fgetc( in );
            cnt++;
        }
        c1 = c2;
    }
    if ( lastByte ) fputc( c1, out ); // Az utolsó bájtot is kiírjuk
    fputc( externalByte, out );
    if ( verbose ) fprintf( stdout, "%d bytes replaced\n", cnt );
}

void compress( FILE *in, FILE *out ) {
    // my @bytes = readBytes( $src );
    countBytes( in );     // my @byteCounters = countBytes( @bytes ); # Melyik bájtból mennyit használunk
    searchUnusedBytes();  // my @unusedBytes = searchUnusedBytes( @byteCounters );
    if ( !unusedBytesCounter ) {
        fprintf( stderr, "There is no unside bytes!\n" );
        exit(1);
    }
    externalByte = unusedBytes[ --unusedBytesCounter ];
    countUsedWords( in ); // my %usedWords = countUsedWords( @bytes ); # $word=>$counter
    createWordsTable(); // my @byte2word = createWordsTable( $freeCnt, $externalByte ); # create byte2word feltöltése, a nemhasznált bájtok helyén
    writeData( in, out );
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

    compress( in, out );

    if (in != stdin) fclose(in);
    if (out != stdout) fclose(out);
    return 0;
}
