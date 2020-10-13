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

    ;; Initialize background palette.
    ld a, %11100100
    ldh [rBGP], a

    ;; Disable sound.
    ld a, AUDENA_OFF
    ldh [rAUDENA], a

    ;;  Turn screen on and display background.
    ld a, LCDCF_ON | LCDCF_BGON
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

SECTION "Fade-Table", ROM0, ALIGN[3]
FadeTable:
    DB 0, 0, 1, 2, 3, 3, 2, 1

SECTION "Fade-Counter", HRAM
FadeCounter:
    DB
