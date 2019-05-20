
ROOT=.
include build/mk/defs

BINDIR=$(BINROOT)/src

#---------------------------------------------------------------------------------------------- 

ifeq ($(CUDA),1)
DEPS_FLAGS=
else
DEPS_FLAGS=cpu
endif

TARGET=$(BINDIR)/redisai.so

#---------------------------------------------------------------------------------------------- 

.PHONY: all clean deps pack setup

all: build

include $(MK)/rules

#---------------------------------------------------------------------------------------------- 

#ifeq ($(wildcard $(BINDIR)/Makefile),)
#endif

$(BINDIR)/Makefile : CMakeLists.txt
	$(SHOW)cd $(BINDIR); \
	rel=`python -c "import os; print os.path.relpath('$(PWD)', '$$PWD')"`; \
	cmake -DDEPS_PATH=$$rel/deps $$rel

build: $(TARGET)

$(TARGET): bindirs deps $(BINDIR)/Makefile
	$(SHOW)$(MAKE) -C $(BINDIR)
	$(SHOW)cd bin; ln -sf ../$(TARGET) $(notdir $(TARGET))

clean:
ifeq ($(ALL),1)
	$(SHOW)rm -rf $(BINROOT)
else
	$(SHOW)$(MAKE) -C $(BINDIR) clean
endif

#---------------------------------------------------------------------------------------------- 

setup:
	@echo System setup...
	$(SHOW)./system-setup.py

deps:
	$(SHOW)./get_deps.sh $(DEPS_FLAGS)

#---------------------------------------------------------------------------------------------- 

pack: BINDIR
	$(SHOW)./pack.sh $(TARGET)

BINDIR: bindirs
	$(SHOW)echo $(BINDIR)>BINDIR

#---------------------------------------------------------------------------------------------- 
