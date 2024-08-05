BUILDDIR=./build
TARGETS=cputest-snes-full.sfc cputest-snes-basic.sfc cputest-vhdl816-basic.bin cputest-vhdl816-full.bin cputest-sim816-basic.bin cputest-sim816-full.bin
ASFLAGS=--cpu 65816 -g


TARGETS_B=$(foreach t, $(TARGETS), $(addprefix $(BUILDDIR)/, $(addprefix $(basename $(t))/, $(t))))

TARGETS_all=tests.o


X:=$(shell mkdir -p $(dir $(TARGETS_B)))

SIMFILES=$(BUILDDIR)/cputest-sim816-basic/cputest-sim816-basic.hex

all:: $(TARGETS_B) $(SIMFILES)

$(BUILDDIR)/cputest-sim816-basic/%.hex: $(BUILDDIR)/cputest-sim816-basic/%.bin
	hexdump -v -e '/1 "%02x\n"' <$< >$@


#define linker configs
$(BUILDDIR)/cputest-snes-full/cputest-snes-full.sfc: lorom.cfg
$(BUILDDIR)/cputest-snes-basic/cputest-snes-basic.sfc: lorom.cfg
$(BUILDDIR)/cputest-blitter-full/cputest-blitter-full.sfc: lorom.cfg
$(BUILDDIR)/cputest-blitter-basic/cputest-blitter-basic.sfc: lorom.cfg
$(BUILDDIR)/cputest-vhdl816-full/cputest-vhdl816-full.bin: vhdl816.cfg
$(BUILDDIR)/cputest-vhdl816-basic/cputest-vhdl816-basic.bin: vhdl816.cfg
$(BUILDDIR)/cputest-sim816-basic/cputest-sim816-basic.bin: sim816.cfg
$(BUILDDIR)/cputest-sim816-full/cputest-sim816-full.bin: sim816.cfg


define getmach
$(word 2, $(subst ., ,$(subst -, ,$(1))))
endef

define getfull
$(word 3, $(subst ., ,$(subst -, ,$(1))))
endef


define gettestdata
	$(if $(filter vhdl816,$(call getmach, $(1))),--test_data=0x7FA0)
endef


define makemain

$(BUILDDIR)/$(basename $(1))/main-$(call getmach,$(1)).o: main-$(call getmach,$(1)).asm 
	ca65 $(ASFLAGS) -D mach_$(call getmach,$(1)) -D $(call getfull,$(1)) -I $(BUILDDIR)/$(basename $(1)) -l $$(basename $$@).lst -o $$@ $$< 

$(BUILDDIR)/$(basename $(1))/%.o: %.asm 
	ca65 $(ASFLAGS) -D mach_$(call getmach,$(1)) -D $(call getfull,$(1)) -I $(BUILDDIR)/$(basename $(1)) -l $$(basename $$@).lst -o $$@ $$< 

$(BUILDDIR)/$(basename $(1))/%.o: $(BUILDDIR)/$(basename $(1))/%.asm
	ca65 $(ASFLAGS) -D mach_$(call getmach,$(1)) -D $(call getfull,$(1)) -I $(BUILDDIR)/$(basename $(1)) -l $$(basename $$@).lst -o $$@ $$< 

endef

#$(info $(foreach t, $(TARGETS), $(call makemain,$(t))))
$(eval $(foreach t, $(TARGETS), $(call makemain,$(t))))

define maketarget

$(BUILDDIR)/$(basename $(1))/$(1): $(addprefix $(BUILDDIR)/$(basename $(1))/,main-$(call getmach,$(1)).o $(TARGETS_$(basename($(1)))) $(TARGETS_all))
	ld65 -vm -Ln $$(basename $$@).sy2 --dbgfile $$(basename $$@).dbg -C $$(filter %.cfg,$$^) -o $$@ -m $$(basename $$@).map -vm $$(filter %.o,$$^)
	../scripts/ca65lstupdate.pl $$(basename $$@).dbg $(BUILDDIR)/$(basename $(1))
endef

#$(info $(foreach t, $(TARGETS), $(call maketarget,$(t))))
$(eval $(foreach t, $(TARGETS), $(call maketarget,$(t))))


define maketests

$(BUILDDIR)/$(basename $(1))/test-list.txt $(BUILDDIR)/$(basename $(1))/tests.asm: make_cpu_tests.py
	python3 make_cpu_tests.py $(call gettestdata,$(1)) --mach=$(call getmach,$(1)) --$(call getfull,$(1)) $(BUILDDIR)/$(basename $(1))/test-list.txt $(BUILDDIR)/$(basename $(1))/tests.asm
endef

#$(info $(foreach t, $(TARGETS), $(call maketests,$(t))))
$(eval $(foreach t, $(TARGETS), $(call maketests,$(t))))


define cleantarget
	-rm -f $(BUILDDIR)/$(basename $(1))/$(1)
	-rm -f $(BUILDDIR)/$(basename $(1))/$(basename $(1)).map
	-rm -f $(BUILDDIR)/$(basename $(1))/test-list.txt
	-rm -f $(BUILDDIR)/$(basename $(1))/tests.asm
	-rm -f $(BUILDDIR)/$(basename $(1))/tests.lst
	-rm -f $(BUILDDIR)/$(basename $(1))/tests.o
	-rm -f $(BUILDDIR)/$(basename $(1))/main*.o

endef


clean::
	$(foreach t, $(TARGETS), $(call cleantarget,$(t)))


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




