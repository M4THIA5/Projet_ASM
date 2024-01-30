# Makefile for code_pour_dessiner.asm

# Compiler and linker
NASM = nasm
GCC = gcc

# Flags
NASM_FLAGS = -f elf64
GCC_FLAGS = -no-pie -Wl,-z,execstack
LIBS = -lX11

# Source file
SRC = Jarvis.asm

# Object file
OBJ = $(SRC:.asm=.o)

# Executable name
EXE = Jarvis

all: $(EXE)

$(EXE): $(OBJ)
	$(GCC) $(GCC_FLAGS) $< $(LIBS) -o $@

$(OBJ): $(SRC)
	$(NASM) $(NASM_FLAGS) $< -o $@

clean:
	rm -f $(OBJ) $(EXE)
