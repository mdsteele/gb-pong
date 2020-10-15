;;; TODO:
;;; - Scoring

INCLUDE "src/hardware.inc"

;;;=========================================================================;;;

;;; Initial ball velocity:
INIT_BALL_X_VEL EQU 2
INIT_BALL_Y_VEL EQU 0
;;; How many pixels each paddle can move per frame:
PADDLE1_SPEED EQU 3
PADDLE2_SPEED EQU 1
;;; The X position for the center of each paddle:
PADDLE1_MIDX EQU 16
PADDLE2_MIDX EQU 160
;;; Min/max Y position for paddle center.
PADDLE_Y_MIN EQU 32
PADDLE_Y_MAX EQU 152
;;; The initial Y position for paddle center.
PADDLE_Y_INIT EQU 96

;;;=========================================================================;;;

SECTION "Main", ROM0[$0150]
Main::
    ;; Initialize the stack.
    ld sp, InitStackPointer

    ;; Set up the OAM DMA routine.
    ld hl, PerformOamDma               ; dest
    ld de, OamDmaCode                  ; src
    ld bc, OamDmaCodeEnd - OamDmaCode  ; count
    call MemCopy

    ;; Clear the shadow OAM.
    ld hl, ShadowOam                 ; dest
    ld bc, ShadowOamEnd - ShadowOam  ; count
    call MemZero

    ;; Add ball obj:
    ld a, 20
    ld [BallXPos], a
    ld a, 80
    ld [BallYPos], a
    xor a
    ld [BallObj], a

    ;; Add paddle objs:
    ld a, PADDLE1_MIDX - 4
    ld [P1TopXPos], a
    ld [P1BotXPos], a
    ld a, PADDLE2_MIDX - 4
    ld [P2TopXPos], a
    ld [P2BotXPos], a
    ld a, PADDLE_Y_INIT - 8
    ld [P1TopYPos], a
    ld [P2TopYPos], a
    ld a, PADDLE_Y_INIT
    ld [P1BotYPos], a
    ld [P2BotYPos], a
    ld a, 1
    ld [P1TopObj], a
    ld [P2TopObj], a
    ld a, 2
    ld [P1BotObj], a
    ld [P2BotObj], a

    ;; Initialize game state:
    ld a, INIT_BALL_X_VEL
    ld [BallXVel], a
    ld a, INIT_BALL_Y_VEL
    ld [BallYVel], a
    xor a
    ld [IsPaused], a
    ld [HoldingStartButton], a

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

    ;; Initialize background palette.
    ld a, %11100100
    ldh [rBGP], a

    ;; Initialize obj palettes.
    ld a, %11100100
    ldh [rOBP0], a
    ldh [rOBP1], a

    ;; Enable sound.
    ld a, AUDENA_ON
    ldh [rAUDENA], a
    ld a, $11
    ldh [rAUDTERM], a
    ld a, $77
    ldh [rAUDVOL], a

    ;; Turn on the LCD.
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_WIN9C00
    ldh [rLCDC], a

    ;; Enable VBlank interrupt.
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

RunLoop:
    call AwaitRedraw
    call StoreButtonStateInB
PauseOrUnpause:
    ;; When press start, pause/unpause.
    ld a, b
    and PADF_START
    jr z, .noToggle
    ld a, [HoldingStartButton]
    or a
    jr nz, .toggleEnd
    ld a, 1
    ld [HoldingStartButton], a
    ld a, [IsPaused]
    cpl
    ld [IsPaused], a
    or a
    jr z, .unpause
    .pause
    ld a, %00011011
    ldh [rBGP], a
    jr .toggleEnd
    .unpause
    ld a, %11100100
    ldh [rBGP], a
    jr .toggleEnd
    .noToggle
    xor a
    ld [HoldingStartButton], a
    .toggleEnd
CheckIfPaused:
    ld a, [IsPaused]
    or a
    jr nz, RunLoop
UpdateP1YPos:
    ;; If holding UP button, move P1 paddle up.
    ld a, b
    and PADF_UP
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
    ld a, b
    and PADF_DOWN
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
    ;; b : old Y velocity
    ;; c : new Y position, ignoring collisions
    ld a, [BallYVel]
    ld b, a
    ld a, [BallYPos]
    add b
    ld c, a
    ;; if (newY < 24)
    cp 24
    jr nc, .yElif
    ld a, 24
    ld [BallYPos], a
    xor a
    sub b
    ld [BallYVel], a
    call PlayWallBounceSound
    jr .yEnd
    ;; elif (newY > 152)
    .yElif
    ld a, c
    cp 152
    jr c, .yElse
    ld a, 152
    ld [BallYPos], a
    xor a
    sub b
    ld [BallYVel], a
    call PlayWallBounceSound
    jr .yEnd
    ;; else
    .yElse
    ld [BallYPos], a
    .yEnd
UpdateBallXPos:
    ;; b : old X velocity
    ;; c : new X position, ignoring collisions
    ld a, [BallXVel]
    ld b, a
    ld a, [BallXPos]
    add b
    ld c, a
    ;; Check which direction the ball is moving.
    ld a, b
    and %10000000
    jr z, .movingRight
    ;; When moving left, we can hit the P1 paddle.
    .movingLeft
    ld a, c
    cp PADDLE1_MIDX
    jr nc, .movingEnd
    ld a, [P1TopYPos]
    sub 7
    ld e, a
    ld a, [BallYPos]
    sub e
    jr c, .movingEnd
    cp 30
    jr nc, .movingEnd
    srl a
    srl a
    sub 3
    ld [BallYVel], a
    ld a, INIT_BALL_X_VEL
    ld [BallXVel], a
    call PlayPaddleBounceSound
    jr .movingEnd
    ;; When moving right, we can hit the P2 paddle.
    .movingRight
    ld a, c
    cp PADDLE2_MIDX - 8
    jr c, .movingEnd
    ld a, [P2TopYPos]
    sub 7
    ld e, a
    ld a, [BallYPos]
    sub e
    jr c, .movingEnd
    cp 30
    jr nc, .movingEnd
    srl a
    srl a
    sub 3
    ld [BallYVel], a
    ld a, -INIT_BALL_X_VEL
    ld [BallXVel], a
    call PlayPaddleBounceSound
    .movingEnd
    ;; if (newX < 8)
    ld a, c
    cp 8
    jr nc, .xElif
    ld a, 8
    ld [BallXPos], a
    xor a
    sub b
    ld [BallXVel], a
    call PlayWallBounceSound
    jr .xEnd
    ;; elif (newX > 160)
    .xElif
    ld a, c
    cp 160
    jr c, .xElse
    ld a, 160
    ld [BallXPos], a
    xor a
    sub b
    ld [BallXVel], a
    call PlayWallBounceSound
    jr .xEnd
    ;; else
    .xElse
    ld [BallXPos], a
    .xEnd
    jp RunLoop

;;;=========================================================================;;;

;;; Copies bytes.
;;; @param hl Destination start address.
;;; @param de Source start address.
;;; @param bc Num bytes to copy.
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

;;; Zeroes bytes.
;;; @param hl Destination start address.
;;; @param bc Num bytes to zero.
MemZero:
    .loop
    ld a, b
    or c
    ret z
    xor a
    ld [hl+], a
    dec bc
    jr .loop

;;; Blocks until the next VBlank, then performs an OAM DMA.
AwaitRedraw:
    di    ; "Lock"
    xor a
    ldh [VBlankFlag], a
    .loop
    ei    ; "Await condition variable" (which is "notified" when an interrupt
    halt  ; occurs).  Note that the effect of an ei is delayed by one
    di    ; instruction, so no interrupt can occur here between ei and halt.
    ldh a, [VBlankFlag]
    or a
    jr z, .loop
    call PerformOamDma
    ei    ; "Unlock"
    ret

;;; Reads and returns state of D-pad/buttons.
;;; @return b The 8-bit button state.
StoreButtonStateInB:
    ld a, P1F_GET_DPAD
    ld [rP1], a
    REPT 2  ; It takes a couple cycles to get an accurate reading.
    ld a, [rP1]
    ENDR
    cpl
    and $0f
    swap a
    ld b, a
    ld a, P1F_GET_BTN
    ld [rP1], a
    REPT 6  ; It takes several cycles to get an accurate reading.
    ld a, [rP1]
    ENDR
    cpl
    and $0f
    or b
    ld b, a
    ld a, P1F_GET_NONE
    ld [rP1], a
    ret

;;; Plays a sound for when the ball bounces off a paddle.
PlayPaddleBounceSound:
    ld a, %00101101
    ldh [rAUD1SWEEP], a
    ld a, %10010000
    ldh [rAUD1LEN], a
    ld a, %01000010
    ldh [rAUD1ENV], a
    ld a, %11000000
    ldh [rAUD1LOW], a
    ld a, %10000111
    ldh [rAUD1HIGH], a
    ret

;;; Plays a sound for when the ball bounces off a wall.
PlayWallBounceSound:
    ld a, %00101101
    ldh [rAUD1SWEEP], a
    ld a, %10010000
    ldh [rAUD1LEN], a
    ld a, %01000010
    ldh [rAUD1ENV], a
    ld a, %11100000
    ldh [rAUD1LOW], a
    ld a, %10000111
    ldh [rAUD1HIGH], a
    ret

;;;=========================================================================;;;
