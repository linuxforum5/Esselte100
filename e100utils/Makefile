# Simple makefile for utils

CC=gcc
SRC=src
BIN=bin
INSTALL_DIR=~/.local/bin

all: e100bas2wav e100wav2bas e100bin2bas lzss3 lzss3dec bpe3 bpe3dec

e100bas2wav: $(SRC)/e100bas2wav.c
	$(CC) -o $(BIN)/e100bas2wav $(SRC)/e100bas2wav.c -lm

lzss3: $(SRC)/lzss3.c
	$(CC) -o $(BIN)/lzss3 $(SRC)/lzss3.c -lm

lzss3dec: $(SRC)/lzss3dec.c
	$(CC) -o $(BIN)/lzss3dec $(SRC)/lzss3dec.c -lm

bpe3: $(SRC)/bpe3.c
	$(CC) -o $(BIN)/bpe3 $(SRC)/bpe3.c -lm

bpe3dec: $(SRC)/bpe3dec.c
	$(CC) -o $(BIN)/bpe3dec $(SRC)/bpe3dec.c -lm

e100bin2bas: $(SRC)/e100bin2bas.c
	$(CC) -o $(BIN)/e100bin2bas $(SRC)/e100bin2bas.c -lm

e100wav2bas: $(SRC)/e100wav2bas.c
	$(CC) -o $(BIN)/e100wav2bas $(SRC)/e100wav2bas.c $(SRC)/lib/WavReader.c -lm

clean:
	rm -f $(BIN)/* *~ $(SRC)/*~ 

install:
	cp $(BIN)/* $(INSTALL_DIR)/
