INCLUDE "src/hardware.inc"

SECTION "Main", ROM0[$0150]
Main::
    ;; Store the stack at the back of RAM bank 0.
    ld sp, _RAMBANK

    ;; Turn off the LCD.
    .waitForVBlank
    ldh a, [rLY]
    cp SCRN_Y
    jr nz, .waitForVBlank
    ld a, LCDCF_OFF
    ld [rLCDC], a

    ;; Write a BG tile into VRAM.
    ld hl, VramBgTiles                  ; dest
    ld de, RomBgTiles                   ; src
    ld bc, RomBgTiles.end - RomBgTiles  ; count
    call MemCopy

    ;; Write BG map.
    ld hl, VramBgMap                ; dest
    ld de, RomBgMap                 ; src
    ld bc, RomBgMap.end - RomBgMap  ; count
    call MemCopy

    ;; Initialize background palette.
    ld a, %11100100
    ldh [rBGP], a

    ;; Disable sound.
    ld a, AUDENA_OFF
    ldh [rAUDENA], a

    ;;  Turn screen on and display background.
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_WIN9C00
    ldh [rLCDC], a

    ;; Enable VBlank interrupt.
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

Run:
    ;; Loop forever.
    halt
    nop
    jr Run

OnVBlankInterrupt::
    ;; a = (*FadeCounter >> 2) & 0x7
    ldh a, [FadeCounter]
    inc a
    ldh [FadeCounter], a
    srl a
    srl a
    and a, $07
    ;; a = FadeTable[a]
    ld hl, FadeTable
    or a, l
    ld l, a
    ld a, [hl]
    ;; Set last background palette color to `a`.
    or a, %11100100
    ldh [rBGP], a
    reti

;;; Copies bytes.
;;; @param hl Destination start address.
;;; @param de Source start address.
;;; @param bc Num bytes to copy.
;;; @return a Zero.
MemCopy:
    .loop
    ld a, b
    or c
    ret z
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc
    jr .loop

SECTION "Fade-Table", ROM0, ALIGN[3]
FadeTable:
    DB 0, 0, 1, 2, 3, 3, 2, 1

SECTION "Fade-Counter", HRAM
FadeCounter:
    DB

SECTION "VRAM", VRAM[$8000]
VramSpriteTiles:
    DS $800
    .end
VramSharedTiles:
    DS $800
    .end
VramBgTiles:
    DS $800
    .end
VramBgMap:
    DS $400
    .end
VramWindowMap:
    DS $400
    .end
