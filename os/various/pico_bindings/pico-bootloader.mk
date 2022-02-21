##############################################################################
# Build rules for including the stage2 bootloader required to start a RP2040 from flash
# 
# must be included before rules.mk and after pico-sdk.mk

PICOBOOTLROOT  := $(PICOSDKROOT)/src/rp2_common/boot_stage2
PICOBOOTLINC    = $(PICOBOOTLROOT)/asminclude
PICOBOOTLD      = $(PICOBOOTLROOT)/boot_stage2.ld

# default stage2 bootloader for W25Q flashes, allow easy override
ifeq ($(PICOBOOTLSRC),)
  PICOBOOTLSRC    = $(PICOBOOTLROOT)/boot2_w25q080.S
endif

# checksum calculation is done with a python script included in the pico-sdk, so we need python to build
ifeq ($(PYTHON),)
  PYTHON = python3
endif

# we have to redefine OBJDIR here because this Makefile must be included before the compiler specific rules.mk
OBJDIR    := $(BUILDDIR)/obj

PICOBOOTLOBJ  := $(addprefix $(OBJDIR)/, $(notdir $(PICOBOOTLSRC:.S=.o)))

$(PICOBOOTLOBJ): $(PICOBOOTLSRC) $(MAKEFILE_LIST) | $(BUILDDIR) $(OBJDIR) $(LSTDIR) $(DEPDIR)
ifeq ($(USE_VERBOSE_COMPILE),yes)
	@echo
	$(CC) -c $(ASXFLAGS) $(TOPT) -I. $(IINCDIR) $(PICOBOOTLSRC) -o $(PICOBOOTLOBJ)
else
	@echo Compiling $(<F)
	@$(CC) -c $(ASXFLAGS) $(TOPT) -I. $(IINCDIR) $(PICOBOOTLSRC) -o $(PICOBOOTLOBJ)
endif

# build the stage2 bootloader with special flags and linker script, add the necessary checksum.
# we must build an object and insert it via ADDITIONALOBJS because a .S file in ASMXOBJS can't be generated with make
$(OBJDIR)/boot_stage2_checksummed.o:  $(PICOBOOTLOBJ) $(MAKEFILE_LIST)
ifeq ($(USE_VERBOSE_COMPILE),yes)
	@echo
	$(LD) $(PICOBOOTLOBJ) --specs=nosys.specs -nostartfiles -Wl,--script=$(PICOBOOTLD) -o $(OBJDIR)/boot_stage2.elf
	$(BIN) $(OBJDIR)/boot_stage2.elf $(OBJDIR)/boot_stage2.bin
	$(PYTHON) $(PICOBOOTLROOT)/pad_checksum -s 0xffffffff $(OBJDIR)/boot_stage2.bin $(OBJDIR)/boot_stage2_checksummed.S
	$(CC) -c $(ASXFLAGS) $(TOPT) -I. $(IINCDIR) $(OBJDIR)/boot_stage2_checksummed.S -o $(OBJDIR)/boot_stage2_checksummed.o
else
	@echo Compiling boot_stage2_checksummed
	@$(LD) $(PICOBOOTLOBJ) --specs=nosys.specs -nostartfiles -Wl,--script=$(PICOBOOTLD) -o $(OBJDIR)/boot_stage2.elf
	@$(BIN) $(OBJDIR)/boot_stage2.elf $(OBJDIR)/boot_stage2.bin
	@$(PYTHON) $(PICOBOOTLROOT)/pad_checksum -s 0xffffffff $(OBJDIR)/boot_stage2.bin $(OBJDIR)/boot_stage2_checksummed.S
	@$(CC) -c $(ASXFLAGS) $(TOPT) -I. $(IINCDIR) $(OBJDIR)/boot_stage2_checksummed.S -o $(OBJDIR)/boot_stage2_checksummed.o
endif

ADDITIONALOBJS += $(OBJDIR)/boot_stage2_checksummed.o

# Shared variables
ALLINC  += $(PICOBOOTLINC)
