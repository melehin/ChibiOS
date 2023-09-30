##############################################################################
# Build rules for creating a UF2 file out of the .elf
# The UF2 file is used for flashing with the USB bootloader included in the RP2040 
# 
# must be included before rules.mk and after pico-sdk.mk

# elf2uf2 sources are included in the pico-sdk and must be built within the 
# SDK tools directory before it can be used
ifeq ($(ELF2UF2),)
  ELF2UF2 = $(PICOSDKROOT)/tools/elf2uf2/elf2uf2
endif

$(BUILDDIR)/$(PROJECT).uf2: $(BUILDDIR)/$(PROJECT).elf
ifeq ($(USE_VERBOSE_COMPILE),yes)
	$(ELF2UF2) $(BUILDDIR)/$(PROJECT).elf $(BUILDDIR)/$(PROJECT).uf2
else
	@echo Creating $@
	@$(ELF2UF2) $(BUILDDIR)/$(PROJECT).elf $(BUILDDIR)/$(PROJECT).uf2
endif

OUTFILES += $(BUILDDIR)/$(PROJECT).uf2
