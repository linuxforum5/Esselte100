/***************************************************
 * e100bas2wav, 2025.04. Princz László
 * Based on audiodump from http://micken.se/esselte.html
 *
 * Convert bas files to Esselte 100 wav file
 * Maximális sorhossz sorszámmal együtt 72 karakter!
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

#define WAV_SAMPLE_RATE 44100
#define PI 3.1415926

bool verbose = false;
bool binmode = false;
bool turbo = false;
int afterLineZeroCounter = 12; // Egy sor kiírása után ennyi 0-át írnuk még. Ez vélhetőlehg a sor betöltésére szánt idő

unsigned int write_bit( FILE* fout, int bit ) {
    unsigned int sample_counter = 0;
    int num = bit ? 8 : 4;
    double freq = bit ? 2400 : 1200;
    int k = bit ? 20 : 40; // 2400=>20, 1200=>40
    if ( turbo ) k = bit ? 18 : 36; // 2400=>20, 1200=>40
    // double freq_radians_per_sample = freq * 2 * PI / WAV_SAMPLE_RATE;
    for ( int i=0; i<num; i++ ) {
        // double phase = 0;
        for ( int j = 0; j < k; j++ ) {
            double phase = 2 * PI / k * j; // freq_radians_per_sample;
            unsigned char out = 127 - ( 127 * sin( phase ) );
            fwrite( &out, 1, 1, fout );
            sample_counter++;
        }
    }
    return sample_counter;
}

/**
 * Format of a byte: 
 * - leading bit 0
 * - 8 data bit
 * - ending bit 1
 */
unsigned int write_byte( FILE* fout, unsigned char byte ) {
    if ( binmode ) {
        fwrite( &byte, 1, 1, fout );
        return 1;
    } else {
        unsigned int sample_counter = 0;
        unsigned char bit;
        sample_counter += write_bit( fout, 0 );
        for ( int j = 0; j < 8; j++ ) {
            bit = ( ( byte & (1 << j) ) != 0 );
            sample_counter += write_bit( fout, bit );
        }
        sample_counter += write_bit( fout, 1 );
        return sample_counter;
    }
}

// Kansas City standard
// 4 x 1200 hz = 0
// 8 x 2400 hz = 1
unsigned long audiodump( FILE *fin, FILE *fout ) {
    unsigned long sample_counter = write_byte( fout, 0x12 );
    unsigned char byte;
    bool skip_EOL = false;
    for( int j=0; j<62; j++ ) sample_counter += write_byte( fout, 0 );
    sample_counter += write_byte( fout, 0x02 );
    while( !feof( fin ) ) {
        fread( &byte, 1, 1, fin );
        if ( (byte == 0x0D) || (byte == 0x0A) ) {
            if ( !skip_EOL ) { // only first EOL character
                skip_EOL = true;
                sample_counter += write_byte( fout, 0x0D );
                sample_counter += write_byte( fout, 0x0A );
                if ( verbose ) fprintf( stdout, "New line\n" );
                for( int j=0; j<afterLineZeroCounter; j++ ) sample_counter += write_byte( fout, 0 );
                sample_counter += write_byte( fout, 0x02 );
            }
        } else {
            skip_EOL = false;
            sample_counter += write_byte( fout, byte );
        }
    }
    sample_counter += write_byte( fout, 0x03 );
    // for( int j=0; j<50; j++ ) sample_counter += write_byte( fout, 0 );
    return sample_counter;
}

/**
 * Wav header size
 */
void wavheaderout( FILE *f, int numsamp ) {
    fprintf( f, "%s", "RIFF" );         //     Chunk ID - konstans, 4 byte hosszú, értéke 0x52494646, ASCII kódban "RIFF"
    int totlen = 44 + numsamp;
    fputc( (totlen & 0xff), f );  //     Chunk Size - 4 byte hosszú, a fájlméretet tartalmazza bájtokban a fejléccel együtt, értéke 0x01D61A72 (decimálisan 30808690, vag
    fputc( (totlen >> 8) & 0xff, f );
    fputc( (totlen >> 16) & 0xff, f );
    fputc( (totlen >> 24) & 0xff, f );
    int srate = WAV_SAMPLE_RATE;
    fprintf( f, "%s", "WAVE" );         //     Format - konstans, 4 byte hosszú,értéke 0x57415645, ASCII kódban "WAVE"
    fprintf( f, "%s", "fmt " );         //     SubChunk1 ID - konstans, 4 byte hosszú, értéke 0x666D7420, ASCII kódban "fmt "
    fprintf( f, "%c%c%c%c", 0x10, 0, 0, 0 );  //     SubChunk1 Size - 4 byte hosszú, a fejléc méretét tartalmazza, esetünkben 0x00000010
    fprintf( f, "%c%c", 0x1, 0x0 );     //     Audio Format - 2 byte hosszú, PCM esetében 0x0001
    fprintf( f, "%c%c", 0x1, 0x0 );     //     Num Channels - 2 byte hosszú, csatornák számát tartalmazza, esetünkben 0x0002
    fprintf( f, "%c%c%c%c",srate&255, srate>>8, 0, 0 ); //     Sample Rate - 4 byte hosszú, mintavételezési frekvenciát tartalmazza, esetünkben 0x00007D00 (decimálisan 32000)
    fprintf( f, "%c%c%c%c",srate&255, srate>>8, 0, 0 ); //     Byte Rate - 4 byte hosszú, értéke 0x0000FA00 (decmálisan 64000)
    fprintf( f, "%c%c", 0x01, 0 ); //	Bytes Per Sample: 1=8 bit Mono, 2=8 bit Stereo or 16 bit Mono, 4=16 bit Stereo
    fprintf( f, "%c%c", 0x08, 0 ); //	//     Bits Per Sample - 2 byte hosszú, felbontást tartalmazza bitekben, értéke 0x0008
    fprintf( f, "%s", "data");     //     Sub Chunk2 ID - konstans, 4 byte hosszú, értéke 0x64617461, ASCII kódban "data"
    fprintf( f, "%c%c%c%c", numsamp &0xff, (numsamp >>8)&0xff, (numsamp >>16)&0xff, (numsamp >>24)&0xff ); //	Length Of Data To Follow : Sub Chunk2 Size - 4 byte hosszú, az adatblokk méretét tartalmazza bájtokban, értéke 0x01D61A1E
}

void print_usage() {
    printf( "e100bas2wav v%d.%d%c (build: %s)\n", VM, VS, VB, __DATE__ );
    printf( "Create Esselte 100 loadable wav file from bas file.\n");
    printf( "Copyright 2025 by László Princz\n");
    printf( "Usage:\n");
    printf( "e100bas2wav <input_filename> [<output_filename_without_wav_extension>]\n" );
    printf( "Convert input file to %d sampled 8 bit mono wav format.\n", WAV_SAMPLE_RATE );
    printf( "Command line option:\n");
    printf( "-v          : set verbose mode\n" );
    printf( "-b          : create bin output file instead of wav\n" );
    printf( "-t          : small faster speed\n" );
    printf( "-c n        : zero byte counter after line. Default value is %d\n", afterLineZeroCounter );
    printf( "-h          : prints this text\n");
    exit(1);
}

int main(int argc, char *argv[]) {
    bool finished = false;
    int argd = argc;

    while ( !finished ) {
        switch ( getopt ( argc, argv, "?hvtbc:" ) ) {
            case -1:
            case ':':
                finished = true;
                break;
            case '?':
            case 'h':
                print_usage();
                break;
            case 'b':
                binmode = true;
                break;
            case 't':
                turbo = true;
                break;
            case 'c' :
                if ( !sscanf( optarg, "%i", &afterLineZeroCounter ) ) {
                    fprintf( stderr, "Error parsing argument for '-c'.\n");
                    exit(2);
                }
                break;
            case 'v':
                verbose = true;
                break;
            default:
                break;
        }
    }

    if ( argc - optind > 0 ) {
        char inname[ 80 ]; // Input filename
        char outname[ 80 ]; // Output filename
        FILE *fin,*fout;
        strcpy( inname, argv[ optind ] );
        strcpy( outname, inname ); // The default output name is input filename + .wav
        if ( argc - optind > 1 ) strcpy( outname, argv[ optind + 1 ] );
        if ( argc - optind > 2 ) print_usage();
        strcat( outname, binmode ? ".bin" : ".wav" );
        if ( fin = fopen( inname, "rb" ) ) {
            if ( fout = fopen( outname, "wb" ) ) {
                fprintf( stdout, "Start conversion from '%s' to '%s'\n", inname, outname );
                if ( !binmode ) wavheaderout( fout, 0 );
                unsigned long sample_counter = audiodump( fin, fout );
                if ( !binmode ) fseek( fout, 0, SEEK_SET );
                if ( !binmode ) wavheaderout( fout, sample_counter );
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
