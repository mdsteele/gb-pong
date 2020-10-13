SECTION "Header-Init", ROM0[$0100]
    ;; Execution starts here.
    nop
    jp Main

SECTION "Header-Nintendo-Logo", ROM0[$0104]
    ;; $0104-$0133: Nintendo logo
    DS 48  ; This gets filled in by rgbfix.

SECTION "Header-Game-Title", ROM0[$0134]
    ;; 11-byte-max game title, padded with zeros.
    DB "PONG"
    DS 7

SECTION "Header-Metadata", ROM0[$013f]
    ;; $013F-$0142: Manufacturer code
    DS 4  ; blank
    ;; $0143: Game Boy Color flag
    DB $00  ; DMG (i.e. original Game Boy)
    ;; $0144-$0145: New licensee code
    DW $0000  ; none
    ;; $0146: Super Game Boy indicator
    DB $00  ; Game Boy (not SGB)
    ;; $0147: Cartridge type
    DB $00  ; ROM Only
    ;; $0148: ROM size
    DB $00  ; 32kB
    ;; $0149: RAM size
    DB $00  ; none
    ;; $014A: Destination code
    DB $01  ; non-Japan
    ;; $014B: Old licensee code
    DB $33  ; Use new licensee code
    ;; $014C: Mask ROM version
    DB $00
    ;; $014D: Header checksum
    DB $00  ; This gets filled in by rgbfix.
    ;; $014E-$014F: Global checksum
    DW $0000  ; This gets filled in by rgbfix.
