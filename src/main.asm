;;; TODO:
;;; - Button controls for player paddle
;;; - Paddle/ball collision detection
;;; - AI for CPU paddle
;;; - Scoring
;;; - Sound effects
;;; - Press START to pause/unpause

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

    ;; Write BG tiles into VRAM.
    ld hl, VramBgTiles                  ; dest
    ld de, RomBgTiles                   ; src
    ld bc, RomBgTiles.end - RomBgTiles  ; count
    call MemCopy

    ;; Write BG map.
    ld hl, VramBgMap                ; dest
    ld de, RomBgMap                 ; src
    ld bc, RomBgMap.end - RomBgMap  ; count
    call MemCopy

    ;; Write obj tiles into VRAM.
    ld hl, VramObjTiles                   ; dest
    ld de, RomObjTiles                    ; src
    ld bc, RomObjTiles.end - RomObjTiles  ; count
    call MemCopy

    ;; Add ball obj to OAM:
    ld a, 20
    ld [BallXPos], a
    ld a, 80
    ld [BallYPos], a
    xor a
    ld [BallObj], a

    ;; Add paddle objs to OAM:
    ld a, 12
    ld [P1TopXPos], a
    ld [P1BotXPos], a
    ld a, 156
    ld [P2TopXPos], a
    ld [P2BotXPos], a
    ld a, 88
    ld [P1TopYPos], a
    ld [P2TopYPos], a
    ld a, 96
    ld [P1BotYPos], a
    ld [P2BotYPos], a
    ld a, 1
    ld [P1TopObj], a
    ld [P2TopObj], a
    ld a, 2
    ld [P1BotObj], a
    ld [P2BotObj], a

    ;; Initialize background palette.
    ld a, %11100100
    ldh [rBGP], a

    ;; Initialize obj palettes.
    ld a, %11100100
    ldh [rOBP0], a
    ldh [rOBP1], a

    ;; Disable sound.
    ld a, AUDENA_OFF
    ldh [rAUDENA], a

    ;; Init game state:
    ld a, 2
    ld [BallXVel], a
    ld a, 1
    ld [BallYVel], a

    ;; Turn on the LCD.
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_WIN9C00
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
    ;; Update Y position/velocity.
    ;; [hl] : current Y position
    ;; b : old Y velocity
    ;; c : new Y position
    ld hl, BallYPos
    ld a, [BallYVel]
    ld b, a
    ld a, [hl]
    add b
    ld c, a
    ;; if (newY < 24)
    cp 24
    jr nc, .yElif
    ld [hl], 24
    xor a
    sub b
    ld [BallYVel], a
    jr .yEnd
    ;; elif (newY > 152)
    .yElif
    ld a, c
    cp 152
    jr c, .yElse
    ld [hl], 152
    xor a
    sub b
    ld [BallYVel], a
    jr .yEnd
    ;; else
    .yElse
    ld [hl], a
    .yEnd

    ;; Update X position/velocity.
    ;; [hl] : current X position
    ;; b : old X velocity
    ;; c : new X position
    ld hl, BallXPos
    ld a, [BallXVel]
    ld b, a
    ld a, [hl]
    add b
    ld c, a
    ;; if (newX < 8)
    cp 8
    jr nc, .xElif
    ld [hl], 8
    ld a, b
    cpl
    add 1
    ld [BallXVel], a
    jr .xEnd
    ;; elif (newX > 160)
    .xElif
    ld a, c
    cp 160
    jr c, .xElse
    ld [hl], 160
    ld a, b
    cpl
    add 1
    ld [BallXVel], a
    jr .xEnd
    ;; else
    .xElse
    ld [hl], a
    .xEnd

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

SECTION "VRAM", VRAM[$8000]
VramObjTiles:
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
