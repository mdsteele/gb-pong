INCLUDE "src/hardware.inc"

;;;=========================================================================;;;

SECTION "Game-State", WRAM0
BallXVel::
    DB
BallYVel::
    DB
P1Score::
    DB
P2Score::
    DB
IsPaused::
    DB
HoldingStartButton::
    DB

;;;=========================================================================;;;

SECTION "Shadow-OAM", WRAM0, ALIGN[8]
ShadowOam::
UNION
    DS 4 * 40
NEXTU

BallYPos::
    DB
BallXPos::
    DB
BallObj::
    DB
    DB

P1TopYPos::
    DB
P1TopXPos::
    DB
P1TopObj::
    DB
    DB

P1BotYPos::
    DB
P1BotXPos::
    DB
P1BotObj::
    DB
    DB

P2TopYPos::
    DB
P2TopXPos::
    DB
P2TopObj::
    DB
    DB

P2BotYPos::
    DB
P2BotXPos::
    DB
P2BotObj::
    DB
    DB

P1ScoreTenYPos::
    DB
P1ScoreTenXPos::
    DB
P1ScoreTenObj::
    DB
    DB

P1ScoreOneYPos::
    DB
P1ScoreOneXPos::
    DB
P1ScoreOneObj::
    DB
    DB

P2ScoreTenYPos::
    DB
P2ScoreTenXPos::
    DB
P2ScoreTenObj::
    DB
    DB

P2ScoreOneYPos::
    DB
P2ScoreOneXPos::
    DB
P2ScoreOneObj::
    DB
    DB

ENDU
ShadowOamEnd::

;;;=========================================================================;;;

SECTION "VRAM", VRAM[$8000]
VramObjTiles::
    DS $800
VramSharedTiles::
    DS $800
VramBgTiles::
    DS $800
VramBgMap::
    DS $400
VramWindowMap::
    DS $400

;;;=========================================================================;;;

SECTION "OAM-Routine-ROM", ROMX
OamDmaCode::
    ld a, HIGH(ShadowOam)
    ldh [rDMA], a  ; Start DMA transfer.
    ;; We need to wait 160 microseconds for the transfer to complete; the
	;; following loop takes exactly that long.
    ld a, 40
    .loop
    dec a
    jr nz, .loop
    ret
OamDmaCodeEnd::

SECTION "OAM-Routine-HRAM", HRAM
PerformOamDma::
    DS OamDmaCodeEnd - OamDmaCode

;;;=========================================================================;;;

;;; Store the stack at the back of RAM bank 0.
SECTION "Stack", WRAM0[$CF00]
    DS $100
InitStackPointer::

;;;=========================================================================;;;
