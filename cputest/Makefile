BUILDDIR=./build
TARGETS=cputest-snes-full.sfc cputest-snes-basic.sfc cputest-blitter-basic.bin
ASFLAGS=--cpu 65816


TARGETS_B=$(foreach t, $(TARGETS), $(addprefix $(BUILDDIR)/, $(addprefix $(basename $(t))/, $(t))))

TARGETS_all=main.o tests.o


X:=$(shell mkdir -p $(dir $(TARGETS_B)))



all:: $(TARGETS_B)


#define linker configs
$(BUILDDIR)/cputest-snes-full/cputest-snes-full.sfc: lorom.cfg
$(BUILDDIR)/cputest-snes-basic/cputest-snes-basic.sfc: lorom.cfg
$(BUILDDIR)/cputest-blitter-full/cputest-blitter-full.sfc: lorom.cfg
$(BUILDDIR)/cputest-blitter-basic/cputest-blitter-basic.sfc: lorom.cfg

define maketarget

$(BUILDDIR)/$(basename $(1))/$(1): $(addprefix $(BUILDDIR)/$(basename $(1))/,$(TARGETS_$(basename($(1)))) $(TARGETS_all))
	ld65 -C $$(filter %.cfg,$$^) -o $$@ -m $$(basename $$@).map -vm $$(filter %.o,$$^)
endef

$(info $(foreach t, $(TARGETS), $(call maketarget,$(t))))
$(eval $(foreach t, $(TARGETS), $(call maketarget,$(t))))


define getmach
$(word 2, $(subst ., ,$(subst -, ,$(1))))
endef

define getfull
$(word 3, $(subst ., ,$(subst -, ,$(1))))
endef


define makemain

$(BUILDDIR)/$(basename $(1))/main.o: main-$(call getmach,$(1)).asm 
	ca65 $(ASFLAGS) -D mach_$(call getmach,$(1)) -D $(call getfull,$(1)) -I $(BUILDDIR)/$(basename $(1)) -o $$@ $$< 

$(BUILDDIR)/$(basename $(1))/%.o: %.asm 
	ca65 $(ASFLAGS) -D mach_$(call getmach,$(1)) -D $(call getfull,$(1)) -I $(BUILDDIR)/$(basename $(1)) -o $$@ $$< 

$(BUILDDIR)/$(basename $(1))/%.o: $(BUILDDIR)/$(basename $(1))/%.asm
	ca65 $(ASFLAGS) -D mach_$(call getmach,$(1)) -D $(call getfull,$(1)) -I $(BUILDDIR)/$(basename $(1)) -o $$@ $$< 

endef

$(info $(foreach t, $(TARGETS), $(call makemain,$(t))))
$(eval $(foreach t, $(TARGETS), $(call makemain,$(t))))

define maketests

$(BUILDDIR)/$(basename $(1))/test-list.txt $(BUILDDIR)/$(basename $(1))/tests.asm: make_cpu_tests.py
	python3 make_cpu_tests.py --$(call getfull,$(1)) $(BUILDDIR)/$(basename $(1))/test-list.txt $(BUILDDIR)/$(basename $(1))/tests.asm
endef

$(info $(foreach t, $(TARGETS), $(call maketests,$(t))))
$(eval $(foreach t, $(TARGETS), $(call maketests,$(t))))


clean::
	-rm -f $(TARGETS_B)

#cputest-full.sfc: cputest-full.o lorom.cfg
#	ld65 -C lorom.cfg -o cputest-full.sfc cputest-full.o -m tests-full.map -vm
#cputest-basic.sfc: cputest-basic.o lorom.cfg
#	ld65 -C lorom.cfg -o cputest-basic.sfc cputest-basic.o -m tests-basic.map -vm


#full: cputest-full.sfc
#
#basic: cputest-basic.sfc
#
#
#tests-full.inc tests-full.txt: make_cpu_tests.py
#	python3 make_cpu_tests.py
#
#tests-basic.inc tests-basic.txt: make_cpu_tests.py
#	python3 make_cpu_tests.py --basic
#
#cputest-full.o: main.asm tests-full.inc font.bin
#	ca65 main.asm -o cputest-full.o
#
#cputest-basic.o: main.asm tests-basic.inc font.bin
#	ca65 -D basic main.asm -o cputest-basic.o
#




