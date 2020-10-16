;;; Executes a conditional instruction if `a` is equal to the first argument
;;; (constant or register).
;;;
;;; For example:
;;;     if_eq 9, jr, .label
;;; Will jump-relative to .label if a == 9.
if_eq: MACRO
    cp \1
    \2 z, \3
ENDM

;;; Executes a conditional instruction if `a` is not equal to the first
;;; argument (constant or register).
;;;
;;; For example:
;;;     if_ne 9, jr, .label
;;; Will jump-relative to .label if a != 9.
if_ne: MACRO
    cp \1
    \2 nz, \3
ENDM

;;; Executes a conditional instruction if `a` is strictly less than the first
;;; argument (constant or register) when treated as unsigned.
;;;
;;; For example:
;;;     if_lt 9, jr, .label
;;; Will jump-relative to .label if a < 9 (unsigned).
if_lt: MACRO
    cp \1
    \2 c, \3
ENDM

;;; Executes a conditional instruction if `a` is less than or equal to the
;;; first argument (which must be a constant) when treated as unsigned.
;;;
;;; For example:
;;;     if_le 9, jr, .label
;;; Will jump-relative to .label if a <= 9 (unsigned).
if_le: MACRO
  IF (\1) > $fe
    \2 \3
  ELSE
    if_lt (\1) + 1, \2, \3
  ENDC
ENDM

;;; Executes a conditional instruction if `a` is greater than or equal to the
;;; first argument (which must be a constant) when treated as unsigned.
;;;
;;; For example:
;;;     if_le 9, jr, .label
;;; Will jump-relative to .label if a <= 9 (unsigned).
if_gt: MACRO
  IF (\1) == 0
    or a
    \2 nz, \3
  ELSE
    if_ge (\1) - 1, \2, \3
  ENDC
ENDM

;;; Executes a conditional instruction if `a` is greater than or equal to the
;;; first argument (constant or register) when treated as unsigned.
;;;
;;; For example:
;;;     if_ge 9, jr, .label
;;; Will jump-relative to .label if a >= 9 (unsigned).
if_ge: MACRO
    cp \1
    \2 nc, \3
ENDM

;;; Executes a conditional instruction if `a` is negative when treated as
;;; signed.
;;;
;;; For example:
;;;     if_neg jr, .label
;;; Will jump-relative to .label if a < 0 (signed).
if_neg: MACRO
    if_ge $80, \1, \2
ENDM

;;; Executes a conditional instruction if `a` is non-negative when treated as
;;; signed.
;;;
;;; For example:
;;;     if_nonneg jr, .label
;;; Will jump-relative to .label if a >= 0 (signed).
if_nonneg: MACRO
    if_lt $80, \1, \2
ENDM
