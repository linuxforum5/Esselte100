/***************************************************
 * e100wav2bas, 2025.04. Princz László
 * Based on audiodump from http://micken.se/esselte.html
 *
 * Convert Esselte 100 wav file into BASIC text source
 * Currently only 44100khz, 8 bit mono PCM
 ****************************************************/
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "getopt.h"
#include "math.h"
#include "lib/WavReader.h"

#define VM 0
#define VS 1
#define VB 'b'

#define WAV_SAMPLE_RATE 44100
#define PI 3.1415926
#define D 3

bool verbose = false;
bool binmode = false;

unsigned char get_sign( unsigned char sample ) { return sample > 128 ? 1 : 0; }

bool sample_sign_changed( unsigned char sample, unsigned char last_sample ) {
    if ( abs( sample - last_sample ) > 5 ) {
        if ( sample <= 127 && last_sample > 127 ) {
            return true;
        } else if ( sample > 127 && last_sample <= 127 ) {
            return true;
        }
    }
    return false;
}

unsigned char read_bit( WavReader* fin, int bit_pos ) {
    // unsigned long last_start_pos = ftell( fin );
    int last_sign_length = 0;
    unsigned char current_sign = get_sign( fin->readNextSample8( fin, 0 ) );
    long sample_counter = 1;
    int current_sign_length = 1;

    int transition_counter = 0; // +/- change sign counter
    bool bit_found = 0;
    unsigned char bit = 0;
    if ( verbose ) fprintf( stdout, "Searching %d. bit ...\n", bit_pos );
    while( (!fin->eof( fin )) && (!bit_found) ) {
        unsigned long pos = fin->ftell( fin );
        unsigned char sample = fin->readNextSample8( fin, 0 );
        unsigned char sign = get_sign( sample ); // 0/1
        sample_counter++;
        if ( sign == current_sign ) {
            current_sign_length++;
        } else { // transition
            if ( verbose ) fprintf( stdout, "Transition after %d samples. Last sample: %d\n", current_sign_length, sample );
            current_sign = sign;
            if ( last_sign_length > D ) {
                int full_length = last_sign_length + current_sign_length;
                int half_length = full_length / 2;
                if ( ( abs( half_length - last_sign_length ) <= D ) && ( abs( half_length - current_sign_length ) <= D ) ) { // In bit
                    // if ( verbose ) fprintf( stdout, "Found zero point\n" );
                    transition_counter++;
                } else {
                    // if ( verbose ) fprintf( stdout, "Restart searching ...\n" );
                    transition_counter = 0;
                }
            } else { // Else skip
                // if ( verbose ) fprintf( stdout, "Skip prefix ... %d\n", current_sign_length );
            }
            last_sign_length = current_sign_length;
            current_sign_length = 0;
        }
        if ( ( last_sign_length < 15 ) && ( transition_counter == 14 ) ) { // Bit 1
            bit_found = true;
            bit = 1;
        } else if ( ( last_sign_length > 15 ) && ( transition_counter == 7 ) ) { // Bit 0
            bit_found = true;
            bit = 0;
        }
    }
    if ( !bit_found ) {
        bit = ( transition_counter > 10 ) ? 1 : 0;
    }
    if ( verbose ) fprintf( stdout, "Found bit %d in %d sample\n", bit, sample_counter );
    return bit;
}

/**
 * Format of a byte: 
 * - leading bit 0
 * - 8 data bit
 * - ending bit 1
 */
unsigned char read_byte( WavReader* fin ) {
    unsigned char byte = 0;
    unsigned char bit;
    while( read_bit( fin, 04 ) ); // search leading zero bit
    for ( int j = 0; j < 8; j++ ) {
        byte += read_bit( fin, j+1 ) * (1<<j);
    }
    if ( !read_bit( fin, 9 ) ) {
        fprintf( stderr, "Byte (0x%02X) stop bit error at pos: %d\n", byte, fin->ftell( fin ) );
        exit(1);
    }
    if ( verbose ) fprintf( stdout, "Found byte %d (%c)\n", byte, byte );
    return byte;
}

// Kansas City standard
// 4 x 1200 hz = 0
// 8 x 2400 hz = 1
void audioread( WavReader *fin, FILE *fout ) {
    while( !fin->eof( fin ) ) {
        unsigned char byte = read_byte( fin );
        if ( binmode ) {
            fputc( byte, fout );
        } else if ( byte == 13 ) {
            fputc( 10, fout );
        } else if ( byte >= 32 ) {
            fputc( byte, fout );
        }
    }
}

void print_usage() {
    printf( "e100wav2bas v%d.%d%c (build: %s)\n", VM, VS, VB, __DATE__ );
    printf( "Create bas or bin file from Esselte 100 loadable wav file.\n");
    printf( "Copyright 2025 by László Princz\n");
    printf( "Usage:\n");
    printf( "e100wav2bas <input_filename> [<output_filename_without_wav_extension>]\n" );
    printf( "Convert input file to %d sampled 8 bit mono wav format.\n", WAV_SAMPLE_RATE );
    printf( "Command line option:\n");
    printf( "-v          : set verbose mode\n" );
    printf( "-b          : save binary output instead of txt file\n" );
    printf( "-h          : prints this text\n");
    exit(1);
}

WavReader* fopen_wav_rd( const char* inname ) {
    WavReader *f = WavReader_open( inname );
    f->checkSampleRate( f, 44100 );
    f->showInfo( f, stdout );
    return f;
}

int main(int argc, char *argv[]) {
    int finished = 0;
    int argd = argc;

    while ( !finished ) {
        switch ( getopt ( argc, argv, "?hvtbn:e:" ) ) {
            case -1:
            case ':':
                finished = 1;
                break;
            case '?':
            case 'h':
                print_usage();
                break;
            case 'v':
                verbose = true;
                break;
            case 'b':
                binmode = true;
                break;
            default:
                break;
        }
    }

    if ( argc - optind > 0 ) {
        char inname[ 80 ]; // Input filename
        char outname[ 80 ]; // Output filename
        WavReader *fin;
        FILE *fout;
        strcpy( inname, argv[ optind ] );
        strcpy( outname, inname ); // The default output name is input filename + .txt
        if ( argc - optind > 1 ) strcpy( outname, argv[ optind + 1 ] );
        if ( argc - optind > 2 ) print_usage();
        strcat( outname, binmode ? ".bin" : ".bas" );
        if ( fin = fopen_wav_rd( inname ) ) {
            if ( fout = fopen( outname, "wb" ) ) {
                fprintf( stdout, "Start conversion from '%s' to '%s'\n", inname, outname );
                audioread( fin, fout );
                fclose( fout );
                WavReader_close( fin );
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
