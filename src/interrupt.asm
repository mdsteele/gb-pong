INCLUDE "src/hardware.inc"

SECTION "Interrupt-VBlank", ROM0[$0040]
    jp OnVBlankInterrupt

SECTION "Interrupt-STAT", ROM0[$0048]
    reti

SECTION "Interrupt-Timer", ROM0[$0050]
    reti

SECTION "Interrupt-Serial", ROM0[$0058]
    reti

SECTION "Interrupt-Joypad", ROM0[$0060]
    reti
