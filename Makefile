#! /usr/bin/make -f

# configuration for GCC
CC  := gcc
CXX := g++

# configuration for Boost
WITH_BOOST := 0
BOOST_INCDIR :=
BOOST_LIBDIR :=

# configuration for TBB
WITH_TBB := 0
TBB_INCDIR :=
TBB_LIBDIR :=

ARCH=$(shell uname -m)
OS=$(shell uname -s)

INCLUDE=.

LIB_SRC=$(wildcard src/*.cc src/native/*.cc)
LIB_OBJ=$(LIB_SRC:%.cc=%.o)

BIN_SRC=test/chrono.cc
BIN_OBJ=$(BIN_SRC:%.cc=%.o)
BIN=$(BIN_SRC:%.cc=%)

SRC=$(LIB_SRC) $(BIN_SRC)
OBJ=$(SRC:%.cc=%.o)
DEP=$(SRC:%.cc=%.d)

# default compiler and linker flags
CXXFLAGS := -std=c++11 -O3 -flto -g -Wall -MMD -fopenmp -I${INCLUDE}
LDFLAGS  := 

# link with Boost, if available
ifeq "$(WITH_BOOST)" "1"
  ifneq "$(BOOST_INCDIR)" ""
    CXXFLAGS := $(CXXFLAGS) -I"$(BOOST_INCDIR)"
  endif
  CXXFLAGS := $(CXXFLAGS) -DHAVE_BOOST_TIMER -DHAVE_BOOST_CHRONO
  ifneq "$(BOOST_LIBDIR)" ""
    LDFLAGS := $(LDFLAGS) -L"$(BOOST_LIBDIR)"
  endif
  LDFLAGS := $(LDFLAGS) -lboost_timer -lboost_chrono -lboost_system
endif

# link with TBB, if available
ifeq "$(WITH_TBB)" "1"
  ifneq "$(TBB_INCDIR)" ""
    CXXFLAGS := $(CXXFLAGS) -I"$(TBB_INCDIR)"
  endif
  CXXFLAGS := $(CXXFLAGS) -DHAVE_TBB
  ifneq "$(TBB_LIBDIR)" ""
    LDFLAGS := $(LDFLAGS) -L"$(TBB_LIBDIR)"
  endif
  LDFLAGS := $(LDFLAGS) -ltbb
endif

# link with -lrt on linux
ifeq "$(OS)" "Linux"
  LDFLAGS := $(LDFLAGS) -lrt
endif


.PHONY: all clean distclean dump


all: $(BIN)


clean:
	rm -f src/*.o src/*.d src/*.asm src/native/*.o src/native/*.d src/native/*.asm test/*.o test/*.d test/*.asm

distclean: clean
	rm -f $(BIN)

dump: $(OBJ:%.o=%.asm)


$(BIN): % : %.o $(LIB_OBJ) Makefile
	$(CXX) $(CXXFLAGS) $(OBJ) $(LDFLAGS) -o $@

%.o: %.cc Makefile
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.asm: %.o
	objdump --demangle --disassemble --disassembler-options=intel-mnemonic,x86-64 --no-show-raw-insn --reloc $< > $@
	#objdump --demangle --disassemble --disassembler-options=intel-mnemonic,x86-64 --no-show-raw-insn --source --reloc $< > $@

-include $(DEP)
