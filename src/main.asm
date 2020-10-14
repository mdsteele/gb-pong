;;; TODO:
;;; - Paddle/ball collision detection
;;; - Scoring
;;; - Sound effects
;;; - Press START to pause/unpause

INCLUDE "src/hardware.inc"

P1F_DOWN   EQU P1F_3
P1F_UP     EQU P1F_2

;;; Initial ball velocity:
INIT_BALL_X_VEL EQU 2
INIT_BALL_Y_VEL EQU 3
;;; How many pixels each paddle can move per frame:
PADDLE1_SPEED EQU 3
PADDLE2_SPEED EQU 1
;;; Min/max Y position for paddle center.
PADDLE_Y_MIN EQU 32
PADDLE_Y_MAX EQU 152

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
    ld a, INIT_BALL_X_VEL
    ld [BallXVel], a
    ld a, INIT_BALL_Y_VEL
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
UpdateP1YPos:
    ;; Store D-pad state in `d`.
    ld a, P1F_GET_DPAD
    ld [rP1], a
    REPT 4  ; It takes a few cycles to get an accurate reading.
    ld a, [rP1]
    ENDR
    cpl
    ld d, a
    ;; If holding UP button, move P1 paddle up.
    and P1F_UP
    jr z, .dpadElif
    ld a, [P1BotYPos]
    sub PADDLE1_SPEED
    cp PADDLE_Y_MIN
    jr nc, .upEnd
    ld a, PADDLE_Y_MIN
    .upEnd
    ld [P1BotYPos], a
    sub 8
    ld [P1TopYPos], a
    jr .dpadEnd
    ;; Else if holding DOWN button, move P1 paddle down.
    .dpadElif
    ld a, d
    and P1F_DOWN
    jr z, .dpadEnd
    ld a, [P1BotYPos]
    add PADDLE1_SPEED
    cp PADDLE_Y_MAX
    jr c, .downEnd
    ld a, PADDLE_Y_MAX
    .downEnd
    ld [P1BotYPos], a
    sub 8
    ld [P1TopYPos], a
    .dpadEnd
UpdateP2YPos:
    ;; Store current ball center Y in `b`.
    ld a, [BallYPos]
    add 4
    ld b, a
    ;; Store current P2 paddle center Y in `d`.
    ld a, [P2BotYPos]
    ld d, a
    ;; If ball is above, move P2 paddle up.
    ld a, b
    cp d
    jr nc, .aiElif
    ld a, [P2BotYPos]
    sub PADDLE2_SPEED
    cp PADDLE_Y_MIN
    jr nc, .upEnd
    ld a, PADDLE_Y_MIN
    .upEnd
    ld [P2BotYPos], a
    sub 8
    ld [P2TopYPos], a
    jr .aiEnd
    ;; Else if ball is below, move P2 paddle down.
    .aiElif
    ld a, d
    cp b
    jr nc, .aiEnd
    ld a, [P2BotYPos]
    add PADDLE2_SPEED
    cp PADDLE_Y_MAX
    jr c, .downEnd
    ld a, PADDLE_Y_MAX
    .downEnd
    ld [P2BotYPos], a
    sub 8
    ld [P2TopYPos], a
    .aiEnd
UpdateBallYPos:
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
UpdateBallXPos:
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
