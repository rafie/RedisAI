
ROOT=.
include build/mk/defs

BINDIR=$(BINROOT)/src

#---------------------------------------------------------------------------------------------- 

ifeq ($(CUDA),1)
DEPS_FLAGS=
else
DEPS_FLAGS=cpu
endif

#---------------------------------------------------------------------------------------------- 

.PHONY: all clean deps pack setup

all: build

include $(MK)/rules

#---------------------------------------------------------------------------------------------- 

build: bindirs deps
ifeq ($(wildcard $(BINDIR)/Makefile),)
	cd $(BINDIR); \
	cmake -DDEPS_PATH=../../deps ../../..
endif
	$(MAKE) -C build

clean:
ifeq ($(ALL),1)
	rm -rf $(BINROOT)
else
	$(MAKE) -C $(BINDIR) clean
endif

#---------------------------------------------------------------------------------------------- 

setup:
	./system-setup.py

deps:
	./get_deps.sh $(DEPS_FLAGS)

#---------------------------------------------------------------------------------------------- 

pack: BINDIR
	$(SHOW)./pack.sh $(BINDIR)/redisai.so

BINDIR: bindirs
	echo $(BINDIR)>BINDIR

#---------------------------------------------------------------------------------------------- 
