# Forrás és célkönyvtárak
BIN_NAME := sokoban
SRCDIR := srcs
BUILDDIR := build
COMPRESSMODE := -B
COMPRESSOR := bpe3
LOADADDR=`e100bin2bas $(COMPRESSMODE) -w`

# Összes asm fájl a lib könyvtárból
# SRCS := $(wildcard $(SRCDIR)/*.asm)
# Összes asm fájl a lib könyvtárból alkönyvtárakkal együtt
SRCS := $(shell find $(SRCDIR) -name '*.asm')

# Ezekből lesznek a rel fájlok a build mappában
RELS := $(patsubst $(SRCDIR)/%.asm,$(BUILDDIR)/%.rel,$(SRCS))

# A végső program fájl
TARGET := $(BUILDDIR)/_main_

# Alapértelmezett cél
all: $(TARGET)

# .rel fájlokat készítünk .asm-ből
$(BUILDDIR)/%.rel: $(SRCDIR)/%.asm
	# @mkdir -p $(dir $(patsubst $(SRCDIR)/%.asm,$(BUILDDIR)/%.rel,$@))
	@mkdir -p $(dir $@)
	@echo "Fordítás: $< → $@"
	@as6800 -o+$@ $<
	#@as6800 -a -g -o+$@ $<

# Linkelés a .rel fájlokból
$(TARGET): $(RELS)
	@echo "Linkelés → $@"
	@aslink -m -w -n -i+$(TARGET) -a MAIN=$(LOADADDR) build/main.rel $(RELS)
	@objcopy -I ihex -O binary $(TARGET).hex bin/$(BIN_NAME).obj
	@$(COMPRESSOR) bin/$(BIN_NAME).obj bin/$(BIN_NAME).obj.$(COMPRESSOR) $(LOADADDR)
	@e100bin2bas $(COMPRESSMODE) -m $(LOADADDR) bin/$(BIN_NAME).obj.$(COMPRESSOR)
	e100bas2wav -t -c 4 bin/$(BIN_NAME).obj.$(COMPRESSOR).bas
	#@e100bas2wav bin/$(BIN_NAME).obj.$(COMPRESSOR).bas

# Takarítás
clean:
	@rm -rf $(BUILDDIR) $(TARGET) bin/*
