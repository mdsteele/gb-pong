SECTION "Game-State", HRAM

BallXVel::
    DB
BallYVel::
    DB


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


SECTION "OAM", OAM[$fe00]

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
