    ORG 0000H

; Boolean convention:
;   FALSE = $00
;   TRUE  = $FF
;
; Many game-state variables use this convention, including two-state selections
; such as PLAYER_2_ACTIVE and GAME_PADDLE_MODE.

; Active-low hardware inputs:
;   0 = PRESSED / ON / ACTIVE
;   1 = RELEASED / OFF / INACTIVE
;
; Buttons, DIP switches, and the coin slot all use this convention.

; Coordinate convention:
;   Ball X/Y coordinates follow the hardware's native raster orientation,
; matching MAME's $8002/$8003 registers.
;
;   The player's view is rotated 90 degrees.
;   Hardware X corresponds to the player's vertical axis.
;   Hardware Y corresponds to the player's horizontal axis.
;
;   Block rows/columns and VRAM coordinates likewise follow the hardware
;   orientation.

RESET:
    JMP STARTUP

; Ball trajectory data:
;   $11 = Move 1 pixel along both axes
;   $10 = Move 1 pixel along hardware Y only
;   $01 = Move 1 pixel along hardware X only
;   $80 = End of current movement step
;   $FF = End of trajectory sequence (loop to start)
;
; Consecutive movement bytes without an $80 separator are executed during the
; same movement step. Trajectory angles are measured above horizontal from the
; player's perspective.

; Trajectory 3: 45 degrees
    DB $11,$FF

; Trajectory 2: 63.435 degrees
    DB $11,$80,$01,$FF

; Trajectory 4: 26.565 degrees
    DB $11,$80,$10,$FF

; Trajectory 1: 71.565 degrees
    DB $11,$01,$80,$01,$FF

0012 BALL_TRAJECTORY_POINTER_TABLE:
; IDX, DATA_PTR_HI/LO
    DB $01,$00,$0D
    DB $02,$00,$05
    DB $03,$00,$03
    DB $04,$00,$09

001E PADDLE_COLLISION_TABLE:
; IDX, BALL_SPEED, PADDLE_WIDTH, OUTER_QUADRANT_IDX, INNER_QUADRANT_IDX
    DB $00,$02,$18,$03,$02
    DB $01,$04,$18,$02,$02
    DB $02,$04,$0C,$02,$02
    DB $03,$05,$0C,$02,$02
    DB $04,$04,$09,$02,$02

0037 PADDLE_COLLISION_TABLE_BOARD_2:
    DB $00,$02,$18,$03,$02
    DB $01,$04,$18,$02,$01
    DB $02,$04,$0C,$03,$02
    DB $03,$05,$0C,$02,$02
    DB $04,$04,$09,$03,$02

0050 PADDLE_COLLISION_TABLE_BOARD_3:
    DB $00,$02,$18,$03,$02
    DB $01,$04,$18,$02,$01
    DB $02,$04,$0C,$04,$03
    DB $03,$05,$0C,$03,$02
    DB $04,$04,$09,$03,$02

0069 PADDLE_COLLISION_SELECTOR_TABLE:
    DB $01,$00,$37
    DB $02,$00,$50
    DB $FF

0070 LEFT_PADDLE_TILE_TABLE:
    DB $24,$25,$26,$27,$28,$29,$2A,$2B,$0E,$2C,$2D,$2E

007C RIGHT_PADDLE_TILE_TABLE:
    DB $39,$38,$37,$36,$35,$34,$33,$32,$31,$30,$2F,$24

0088 SMALL_PADDLE_TILE_TABLE:
    DB $31,$3A,$3B,$27

008C GLYPH_TABLE:
; 0
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx------------------------xxxxxxxx--
; ------xxxxxxxx------------------------xxxxxxxx--
; ------xxxxxxxx------------------------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $0B,$0A,$09

; 1
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $0E,$0D,$0C

; 2
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
    DB $11,$10,$0F

; 3
; ------------------------------------------------
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $13,$12,$0F

; 4
; ------------------------------------------------
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxx------------------
; ----------------------xxxxxxxx------------------
; ----------------------xxxxxxxx------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $0E,$15,$14

; 5
; ------------------------------------------------
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxx--------xxxxxxxx--
    DB $13,$17,$16

; 6
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx------------------
; ------xxxxxxxx--------xxxxxxxx------------------
; ------xxxxxxxx--------xxxxxxxx------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx------------------
    DB $0B,$19,$18

; 7
; ------------------------------------------------
; --------------------------------------xxxxxxxx--
; --------------------------------------xxxxxxxx--
; --------------------------------------xxxxxxxx--
; --------------------------------------xxxxxxxx--
; --------------------------------------xxxxxxxx--
; --------------------------------------xxxxxxxx--
; --------------------------------------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $0E,$0D,$0F

; 8
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxx--------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $0B,$1A,$09

; 9
; ------------------------------------------------
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxxxxxxxxxxxxxxxxxx--
; ----------------------xxxxxxxx--------xxxxxxxx--
; ----------------------xxxxxxxx--------xxxxxxxx--
; ----------------------xxxxxxxx--------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
    DB $0E,$1B,$09

; A = blank
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
; ------------------------------------------------
    DB $00,$00,$00

; B = letter 'A'
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxx--------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx----------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx------
; --------------xxxxxxxx------xxxxxxxxxxxxxxxxxx--
; --------------xxxxxxxx------xxxxxxxxxxxxxxxxxx--
; --------------xxxxxxxx------xxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx----------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxx--------------
; ------xxxxxxxxxxxxxxxxxxxxxxxx------------------
    DB $1E,$1D,$1C

; C = letter 'B'
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx------xxxxxxxxxxxx------xxxxxxxx--
; ------xxxxxxxx------xxxxxxxxxxxx------xxxxxxxx--
; ------xxxxxxxx------xxxxxxxxxxxx------xxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; --------xxxxxxxxxxxxxxxx----xxxxxxxxxxxxxxxx----
; ----------xxxxxxxxxxxx--------xxxxxxxxxxxx------
    DB $21,$20,$1F

; D = letter 'C'
; ------------------------------------------------
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx--
; ------xxxxxxxx------------------------xxxxxxxx--
; ------xxxxxxxx------------------------xxxxxxxx--
; ------xxxxxxxx------------------------xxxxxxxx--
; ------xxxxxxxxxxxxxxxx--------xxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxx--------xxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxx--------xxxxxxxxxxxxxxxx--
; ------xxxxxxxxxxxxxxxx--------xxxxxxxxxxxxxxxx--
    DB $3E,$23,$22

00B6 BLOCK_POINTS_TABLE:
    DB $01,$01,$02,$02,$04,$04,$08,$08

00BE NUM_BALLS_DIP_TABLE:
; DIP Value, NUM_BALLS
    DB $18,$03
    DB $10,$04
    DB $08,$05
    DB $00,$06

00C6 REPLAY_SCORE_DIP_TABLE:
; DIP Value, REPLAY_SCORE_LO, REPLAY_SCORE_HI
    DB $06,$00,$04                     ; 400 pts
    DB $04,$00,$08                     ; 800 pts
    DB $02,$00,$12                     ; 1200 pts
    DB $00,$00,$16                     ; 1600 pts

; GAME_TYPES
;   packed GAME_TYPE glyph + space glyph
;   GAME_TYPE_OFFSET (used for high scores)

00D2 GAME_TYPE_A:
    DB $BA,$00

00D4 GAME_TYPE_B:
    DB $CA,$02

00D6 GAME_TYPE_C:
    DB $DA,$04

00D8 SERVE_DATA_TABLE:
    DB $B1,$42,$B4,$45,$80,$80
    DB $0F,$5A,$0F,$5D,$00,$80
    DB $B1,$62,$B4,$65,$80,$80
    DB $0F,$4A,$0F,$4D,$00,$80
    DB $B1,$52,$B4,$55,$80,$80
    DB $0F,$6A,$0F,$6D,$00,$80
    DB $FF

00FD INITIAL_PLAYER_STATE:
; Player 1
    DB $00,$10                         ; P1_BLOCKS_PTR
    DB $70,$10                         ; P1_HANDICAP_ROWS_PTR
    DB $1E,$00
    DB $12                             ; BLOCKS_BASE_COLUMN
    DB $00
    DB $70                             ; NORMAL_BLOCK_COUNT
; Player 2
    DB $7E,$10                         ; P2_BLOCKS_PTR
    DB $EE,$10                         ; P2_HANDICAP_ROWS_PTR
    DB $1E,$00
    DB $12                             ; BLOCKS_BASE_COLUMN
    DB $00
    DB $70                             ; NORMAL_BLOCK_COUNT

010F PIXEL_TO_ROW_AND_OFFSET:
; Input:
;   A = pixel coordinate, e.g. PADDLE_LEFT_EDGE
; Output:
;   A = pixel in row
;   B = ROW_INDEX
    MVI B,$00                          ; ROW_INDEX = 0
CHECK_NEXT_ROW:
    SUI $0C                            ; if A -= 12 < 0,
    JC RESTORE_A
                                       ; else
    INR B                              ; ROW_INDEX++
    JMP CHECK_NEXT_ROW

RESTORE_A:
    ADI $0C                            ; A += 12
    RET                                ; RETURN

011D GET_BLOCK_AT_BALL_COORDS:
; Input:
;   A = BALL_Y
;   C = BALL_X
; Output:
;   HL = BLOCK_PTR (if ball is in block formation's space) || undefined
;   A = BLOCK_STATE (if ball is in block formation's space) || 0
    CPI $B4                            ; if BALL_Y < 180,
    JC CHECK_BALL_IN_BLOCKS
                                       ; else
    MVI A,$B3                          ; BALL_Y = 179
CHECK_BALL_IN_BLOCKS:
    CALL PIXEL_TO_ROW_AND_OFFSET
    MOV A,B
    STA $113D                          ; $113D = BALL_ROW
    DCR A
    RLC
    RLC
    RLC
    ANI $F8
    MOV B,A                            ; B = (BALL_ROW - 1) * 8 (BLOCKS offset for row)

    LDA $116F
    MOV E,A                            ; E = ACTIVE_BLOCKS_BASE_COLUMN
    MOV A,C
    RRC
    RRC
    RRC
    ANI $1F                            ; A = BALL_X \ 8
    STA $113E                          ; $113E = BALL_COLUMN
    MOV D,A                            ; D = BALL_COLUMN
    SUB E                              ; if BALL_COLUMN < ACTIVE_BLOCKS_BASE_COLUMN,
    JC BALL_NOT_IN_BLOCKS
                                       ; else
    SUI $08                            ; if BALL_COLUMN < (ACTIVE_BLOCKS_BASE_COLUMN + 8),
    JC GET_BALL_BLOCK
                                       ; else
BALL_NOT_IN_BLOCKS:
    XRA A                              ; A = 0
    JMP ESCAPE_BALL_BLOCK

GET_BALL_BLOCK:
    MOV A,D
    ADD B
    SUB E
    MOV E,A                            ; E = BLOCKS offset + (BALL_COLUMN - ACTIVE_BLOCKS_BASE_COLUMN)
    MVI D,$00
    LHLD $1169
    DAD D                              ; HL = ACTIVE_BLOCKS_PTR + E
    MOV A,M                            ; A = BLOCK_STATE
ESCAPE_BALL_BLOCK:
    RET

0159 GET_BLOCK_PTR_AND_STATE:
; Input:
;   B = ROW_INDEX
;   C = SCREEN_VRAM_COLUMN
; Output:
;   HL = BLOCK_PTR
;   A = BLOCK_STATE
;
; WORK_BLOCKS is a 14-row x 8-column array of on/off block states. ROW_INDEX
; selects one of the 14 rows. SCREEN_VRAM_COLUMN is converted to a logical
; block-column index by subtracting BLOCKS_BASE_COLUMN. Callers therefore
; depend on the current on-screen position of the block field.
;
; BLOCK_PTR =
;    WORK_BLOCKS_PTR
;    + (ROW_INDEX - 1) * 8
;    + (SCREEN_VRAM_COLUMN - BLOCKS_BASE_COLUMN)
; 
; Returns HL pointing to the referenced block-state byte and A containing that
; byte's current value.
    MOV A,B
    DCR A
    RLC
    RLC
    RLC                            ; A = (ROW_INDEX - 1) * 8
    ANI $F8                        ; mask carry/wraparound
    ADD C                          ; A += SCREEN_VRAM_COLUMN
    LXI H,$116F
    SUB M                          ; A -= ACTIVE_BLOCKS_BASE_COLUMN
    LHLD $1172                     ; HL = WORK_BLOCKS_PTR
    ADD L
    MOV L,A
    MOV A,H
    ACI $00
    MOV H,A                        ; HL = BLOCK_PTR
    MOV A,M                        ; A = BLOCK_STATE
    RET

0170 SET_HANDICAP_ROW_AT_INDEX:
; Input:
;   B = ROW_INDEX
;   D = HANDICAP_ROW
; Output:
;   B = ROW_INDEX - 1
;
; WORK_HANDICAP_ROWS is a 14-entry array representing the 14 rows of the block
; formation. If a row is set to #FF, it contains a handicap block. If set to
; #00, it doesn't. ROW_INDEX selects one entry and ROW_VALUE is stored there.
;
; ROW_INDEX is returned decremented.
    LHLD $1174                     ; HL = WORK_HANDICAP_ROWS_PTR
    DCR B                          ; ROW_INDEX--
    MOV A,B
    ADD L
    MOV L,A
    MOV A,H
    ACI $00
    MOV H,A                        ; HL = WORK_HANDICAP_ROWS_PTR + (ROW_INDEX - 1)
    MOV M,D                        ; HANDICAP_ROW(PTR) = HANDICAP_ROW
    RET

017D INIT_BLOCKS:
; Input:
;   HL = BLOCKS_PTR
;   DE = HANDICAP_ROWS_PTR
;   C = HANDICAP_PAIR_COUNT (0, 1, or 2)
;
; Initializes all blocks to 1 and all row values to 0. Sets up the indicated
; number of Handicap block pairs. C=1 sets up rows 6 & 9. C=2 additionally sets
; up rows 3 & 12. Handicap blocks are set to 0 and their row values to FF.
    SHLD $1172                         ; WORK_BLOCKS_PTR = BLOCKS_PTR
    XCHG
    SHLD $1174                         ; WORK_HANDICAP_ROWS_PTR = HANDICAP_ROWS_PTR
    XCHG                               ; HL = BLOCKS_PTR
    MVI A,$01                          ; FILL_VALUE = 1
    MVI B,$70                          ; LOOP_COUNTER = 112
    CALL FILL_RAM

    XCHG                               ; HL = HANDICAP_ROWS_PTR
    XRA A                              ; FILL_VALUE = 0
    MVI B,$0E                          ; LOOP_COUNTER = 14
    CALL FILL_RAM

    MOV A,C
    CPI $00                            ; if HANDICAP_PAIR_COUNT == 0,
    JZ EXIT_INIT_BLOCKS
                                       ; else
    DCR A                              ; if HANDICAP_PAIR_COUNT == 1,
    JZ CENTRAL_HANDICAP_PAIR
                                       ; else
    MVI B,$03                          ; ROW_INDEX = 3
    CALL INIT_HANDICAP_PAIR
CENTRAL_HANDICAP_PAIR:
    MVI B,$06                          ; ROW_INDEX = 6
INIT_HANDICAP_PAIR:
    MVI D,$FF                          ; HANDICAP_ROW = TRUE
    MVI C,$17                          ; SCREEN_VRAM_COLUMN = #17
    CALL GET_BLOCK_PTR_AND_STATE
    XRA A
    MOV M,A                            ; BLOCK_STATE(PTR) = 0
    CALL SET_HANDICAP_ROW_AT_INDEX     ; decrements original ROW_INDEX
    MOV A,B
    SUI $0E
    CMA
    MOV B,A
    INR B                              ; ROW_INDEX = 14 - (ROW_INDEX - 1)
    CALL GET_BLOCK_PTR_AND_STATE
    XRA A
    MOV M,A                            ; BLOCK_STATE(PTR) = 0
    CALL SET_HANDICAP_ROW_AT_INDEX
EXIT_INIT_BLOCKS:
    RET                                ; RETURN

01BF INIT_DISPLAY:
; Clears video RAM and constructs the initial playfield display.
; Draws the left, right, and top walls, then draws both players'
; scores and remaining ball counts.
;
; Video RAM occupies $2000-$21FF as a 32 x 16 tilemap.
    LXI H,$2000                        ; RAM_PTR = $2000
    XRA A                              ; FILL_VALUE = 0
    MVI D,$02                          ; VRAM_HALF_COUNTER = 2
CLEAR_VRAM_HALF:
    MVI B,$00                          ; LOOP_COUNTER = 256
    CALL FILL_RAM
    DCR D                              ; if --VRAM_HALF_COUNTER != 0,
    JNZ CLEAR_VRAM_HALF
                                       ; else
; Draw left side
    MVI B,$20                          ; LOOP_COUNTER = 32
    LXI H,$2000                        ; RAM_PTR = $2000
    MVI A,$06                          ; FILL_VALUE = #06 (left wall)
    CALL FILL_RAM

; Draw right side
    MVI B,$1F                          ; LOOP_COUNTER = 31
    LXI H,$21E0                        ; RAM_PTR = $21E0
    MVI A,$07                          ; FILL_VALUE = #07 (right wall)
    CALL FILL_RAM

; Draw top
    MVI B,$1F                          ; VRAM_COLUMN = #1F
    CALL DRAW_TOP_OR_BOTTOM

01E7 DRAW_SCORES_AND_BALLS:
    MVI C,$02                          ; SCORE_COUNTER = 2
    LXI D,$1145                        ; DATA_PTR = PLAYER_1_SCORE
    LXI H,$207A                        ; GLYPH_POSITION = P1_SCORE
01EF DRAW_SCORE:
    CALL DRAW_4_GLYPHS
    LXI H,$213A                        ; GLYPH_POSITION = P2_SCORE
    DCR C                              ; if --SCORE_COUNTER != 0,
    JNZ DRAW_SCORE                     ; DATA_PTR = PLAYER_2_SCORE
                                       ; else
    LXI H,$205C                        ; GLYPH_POSITION = P1_BALLS
    CALL DRAW_BALL_COUNT               ; returns to DRAW_BALL_COUNT for P2
01FF DRAW_BALL_COUNT:
    LDAX D                             ; GLYPH = BALL_COUNT
    CALL DRAW_GLYPH_AND_ADVANCE
    INX D                              ; next player's BALL_COUNT
    LXI H,$21BC                        ; GLYPH_POSITION = P2_BALLS
    RET

0208 DRAW_BOTTOM:
    MVI B,$00                          ; VRAM_COLUMN = #00
DRAW_TOP_OR_BOTTOM:
; Input:
;   B = VRAM_COLUMN
;
; Draws a 15-tile wall along VRAM_COLUMN.
    MVI A,$0F                          ; ROW_INDEX = #0F
    MVI C,$08                          ; TILE_VALUE = #08 (right-side corners)
DRAW_TILE:
    CALL WRITE_TILE_TO_VRAM
    MVI C,$05                          ; TILE_VALUE = #05 (horizontal wall)
    DCR A                              ; if --ROW_INDEX != 0,
    JNZ DRAW_TILE
                                       ; else
    RET                                ; RETURN

0218 CLEAR_BLOCK_DISPLAY_AREA:
    MVI A,$0E                          ; ROW_INDEX = 14
    MVI C,$00                          ; TILE_VALUE = #00 (blank)
021C CLEAR_NEXT_ROW:
    MVI D,$14                          ; COLUMN_LOOP_COUNTER = 20
    MVI B,$06                          ; VRAM_COLUMN = 6
0220 WRITE_NEXT_BLANK:
    CALL WRITE_TILE_TO_VRAM
    INR B                              ; VRAM_COLUMN++
    DCR D                              ; if --COLUMN_LOOP_COUNTER != 0,
    JNZ WRITE_NEXT_BLANK
                                       ; else
    DCR A                              ; if --ROW_INDEX != 0,
    JNZ CLEAR_NEXT_ROW
                                       ; else
    RET                                ; RETURN

022D WRITE_TILE_TO_VRAM:
; Input:
;   A = ROW_INDEX (1-15)
;   B = VRAM_COLUMN
;   C = TILE_VALUE
;
; Stores TILE_VALUE at:
;   $2000 + (ROW_INDEX * $20) + VRAM_COLUMN
;
; Preserves A, flags, and HL.
    PUSH PSW
    PUSH H
    STC
    CMC                                ; clear carry
    MVI H,$20                          ; H = #20
; A = ROW_INDEX * $20
    RAR
    RAR
    RAR
    RAR                                ; if ROW_INDEX < 8,
    JNC STORE_TILE
                                       ; else
    INR H                              ; H = #21
STORE_TILE:
    ADD B
    MOV L,A                            ; L = A + VRAM_COLUMN
    MOV M,C                            ; VRAM(INDEX) = TILE_VALUE
    POP H
    POP PSW
    RET                                ; RETURN

0241 DRAW_BLOCKS:
; Draws the current state of each block in the 14x8 array to the screen. #00
; is blank and #01 is a block 13 pixels wide by 6 pixels tall, with a 1-pixel
; gap on its left and a 2-pixel gap beneath it.
;
; When finished, this routine also redraws the right-side wall to complete the
; block shift animation from Game B.
    LHLD $1169
    LXI D,$006F
    DAD D                              ; HL = ACTIVE_BLOCKS_PTR + $6F
    MVI E,$0E                          ; ROW_INDEX = #0E
024A DRAW_BLOCK_ROW:
    MVI D,$08                          ; COL_COUNTER = 8
    LDA $116F
    ADI $07                            ; adjust to top row of blocks
    MOV B,A                            ; VRAM_COLUMN = BLOCKS_BASE_COLUMN + 7
0252 DRAW_BLOCK:
    MOV C,M                            ; TILE_VALUE = BLOCK_STATE
    MOV A,E                            ; A = ROW_INDEX
    CALL WRITE_TILE_TO_VRAM
    DCR B                              ; VRAM_COLUMN--
    DCX H                              ; ACTIVE_BLOCKS_PTR--
    DCR D                              ; if --COL_COUNTER != 0,
    JNZ DRAW_BLOCK
                                       ; else
    DCR E                              ; if --ROW_INDEX != 0,
    JNZ DRAW_BLOCK_ROW
                                       ; else
; Redraw right side next to blocks
    LXI H,$21F2                        ; RAM_PTR = $21F2 (right wall)
    MVI A,$07                          ; TILE_VALUE = #07
    MVI B,$08                          ; SIDE_LOOP_COUNTER = 8
; This could be replaced by a call to FILL_RAM as it is identical code.
DRAW_SIDE:
    MOV M,A                            ; RAM_PTR = TILE_VALUE
    INX H                              ; RAM_PTR++
    DCR B                              ; if --SIDE_LOOP_COUNTER != 0,
    JNZ DRAW_SIDE
                                       ; else
    RET                                ; RETURN

026F UPDATE_HANDICAP_BLOCK_DISPLAY:
    MVI D,$01                          ; ROW_INDEX = 1
    MVI E,$0E                          ; ROW_LOOP_COUNTER = 14

    LDA $116F                          ; A = ACTIVE_BLOCKS_BASE_COLUMN
    ADI $05
    MOV B,A                            ; VRAM_COLUMN = BASE_COLUMN + 5

    LHLD $116B                         ; HL = ACTIVE_HANDICAP_ROWS_PTR
027C CHECK_NEXT_HANDICAP_BLOCK:
    MOV A,M
    CPI $00                            ; if HANDICAP_ROWS(PTR) == FALSE,
    JZ NEXT_HANDICAP_BLOCK
                                       ; else
    MOV A,D                            ; A = ROW_INDEX
    CALL WRITE_TILE_TO_VRAM
0286 NEXT_HANDICAP_BLOCK:
    INX H                              ; HANDICAP_ROWS_PTR++
    INR D                              ; ROW_INDEX++
    DCR E                              ; if --ROW_LOOP_COUNTER != 0,
    JNZ CHECK_NEXT_HANDICAP_BLOCK
                                       ; else
    RET                                ; RETURN

028D ROTATE_BLOCKS_RIGHT:
    LHLD $1169                         ; HL = ACTIVE_BLOCKS_PTR
    SHLD $1172                         ; WORK_BLOCKS_PTR = ACTIVE_BLOCKS_PTR

    MVI A,$08
    STA $1151                          ; COLUMN_LOOP_COUNTER = 8

    LDA $116F
    MOV C,A                            ; SCREEN_VRAM_COLUMN = ACTIVE_BLOCKS_BASE_COLUMN

ROTATE_NEXT_COLUMN:
    MVI B,$0E                          ; ROW_INDEX = 14
    CALL GET_BLOCK_PTR_AND_STATE
    MOV D,A                            ; D = BLOCK_STATE (previous row)

    MVI B,$01                          ; ROW_INDEX = 1

    MVI A,$0E
    STA $1152                          ; ROW_LOOP_COUNTER = 14

ROTATE_NEXT_BLOCK_STATE:
    CALL GET_BLOCK_PTR_AND_STATE
    MOV M,D                            ; BLOCK_PTR = BLOCK_STATE (previous row)
    MOV D,A                            ; D = BLOCK_STATE (current row)

    INR B                              ; ROW_INDEX++

    LXI H,$1152
    DCR M                              ; if --ROW_LOOP_COUNTER != 0,
    JNZ ROTATE_NEXT_BLOCK_STATE
                                       ; else
    INR C                              ; SCREEN_VRAM_COLUMN++

    LXI H,$1151
    DCR M                              ; if --COLUMN_LOOP_COUNTER != 0,
    JNZ ROTATE_NEXT_COLUMN
                                       ; else
    RET                                ; RETURN

02BF DRAW_HALF_SHIFTED_BLOCKS:
    LXI H,$2032
    SHLD $1151                         ; BLOCK_SHIFT_VRAM_PTR = $2032

    LHLD $1169                         ; HL = ACTIVE_BLOCKS_PTR (right row = 1)
    PUSH H

    MOV A,L
    ADI $68
    MOV E,A
    MOV A,H
    ACI $00
    MOV D,A                            ; DE = ACTIVE_BLOCKS_PTR + $68 (left row = 14)

    CALL DRAW_SHIFTED_BLOCK_ROW

    MVI C,$0D                          ; ROW_LOOP_COUNTER = 13
    POP D                              ; DE = ACTIVE_BLOCKS_PTR (left row = 1)
DRAW_NEXT_SHIFTED_ROW:
    CALL DRAW_SHIFTED_BLOCK_ROW
    DCR C                              ; if --ROW_LOOP_COUNTER != 0,
    JNZ DRAW_NEXT_SHIFTED_ROW
                                       ; else
    MVI B,$08                          ; BLOCK_LOOP_COUNTER = 8
    LHLD $1151                         ; HL = BLOCK_SHIFT_VRAM_PTR (always $21F2)
GET_NEXT_RIGHT_WALL_BLOCK_STATE:
    LDAX D                             ; A = BLOCK_STATE
    MVI C,$07                          ; TILE_VALUE = #07 (right wall)
    DCR A                              ; if --BLOCK_STATE != 0,
    JNZ DRAW_RIGHT_WALL_PIECE
                                       ; else
    MVI C,$3D                          ; TILE_VALUE = #3D (right wall w/ block)
DRAW_RIGHT_WALL_PIECE:
    MOV M,C                            ; VRAM(INDEX) = TILE_VALUE
    INX H                              ; BLOCK_SHIFT_VRAM_PTR++
    INX D                              ; ACTIVE_BLOCKS_PTR++
    DCR B                              ; if --BLOCK_LOOP_COUNTER != 0,
    JNZ GET_NEXT_RIGHT_WALL_BLOCK_STATE
                                       ; else
    RET                                ; RETURN

02F4 DRAW_SHIFTED_BLOCK_ROW:
; Input:
;   DE = BLOCK_ROW_PTR (left row)
;   HL = BLOCK_ROW_PTR (right row)
;
; Under normal play rules, the BLOCK_STATE (0 = blank, 1 = block) is used
; directly as a TILE_VALUE when drawing the block formation. In Game B, the
; block formation is shifted to the right half a block at a time. The following
; is used to determine what tiles to draw when shifted out of normal alignment:
;
; Sum the BLOCK_STATE from two adjacent blocks.
; 0: Both blocks are blank -> draw tile 0 (blank)
; 2: Both blocks are present -> draw tile 2 (two half blocks)
; 1: Exactly one block is present. Add 3 to the left BLOCK_STATE:
;    3: Left blank, right present -> draw tile 3
;    4: Left present, right blank -> draw tile 4
    MVI B,$08                          ; BLOCK_LOOP_COUNTER = 8

DRAW_NEXT_SHIFTED_BLOCK:
    LDAX D
    ADD M                              ; TILE_VALUE = BLOCK_STATE (left row) + BLOCK_STATE (right row)
    CPI $01                            ; if TILE_VALUE != 1,
    JNZ DRAW_SHIFTED_BLOCK
                                       ; else
    LDAX D
    ADI $03                            ; TILE_VALUE = BLOCK_STATE (left row) + 3

DRAW_SHIFTED_BLOCK:
    PUSH H                             ; save BLOCK_ROW_PTR (right row)
    LHLD $1151                         ; HL = BLOCK_SHIFT_VRAM_PTR
    MOV M,A                            ; VRAM(INDEX) = TILE_VALUE
    INX H
    SHLD $1151                         ; BLOCK_SHIFT_VRAM_PTR++
    POP H                              ; restore BLOCK_ROW_PTR (right row)

    INX H                              ; BLOCK_ROW_PTR (right row)++
    INX D                              ; BLOCK_ROW_PTR (left row)++
    DCR B                              ; if --BLOCK_LOOP_COUNTER != 0,
    JNZ DRAW_NEXT_SHIFTED_BLOCK
                                       ; else
    LDA $1151
    ADI $18
    STA $1151
    LDA $1152
    ACI $00
    STA $1152                          ; BLOCK_SHIFT_VRAM_PTR += #18 (next row)
    RET                                ; RETURN

0321 DRAW_GAME_TYPE_AND_HIGH_SCORE:
; Input:
;   DE = DATA_PTR
    LXI H,$20FC                        ; GLYPH_POSITION = GAME_TYPE
    LDAX D                             ; A = GAME_TYPE_AND_SPACE
    RRC
    RRC
    RRC
    RRC
    CALL DRAW_GLYPH_AND_ADVANCE        ; draw GAME_TYPE glyph

    LXI H, $20E3                       ; GLYPH_POSITION = HIGH_SCORE_TYPE
    CALL DRAW_2_GLYPHS                 ; draw GAME_TYPE followed by a space

    LDAX D                             ; A = GAME_TYPE_OFFSET (#00, #02, #04)
    LXI D,$114B
    ADD E
    MOV E,A                            ; DATA_PTR = GAME_TYPE_HIGH_SCORE
    CALL DRAW_4_GLYPHS                 ; draw 4-digit high score
    RET                                ; RETURN

033C DRAW_GLYPH_TILES:
; Input:
;   A = GLYPH_PTR (0-D)
;   HL = GLYPH_POSITION
;
; Draws a 3-tile glyph identified by GLYPH_PTR from GLYPH_TABLE, starting at
; GLYPH_POSITION.
    PUSH H
    PUSH D
    PUSH B
    XCHG                              ; DE = GLYPH_POSITION
    LXI H,$008C                       ; HL = GLYPH_TABLE
    MOV B,A
    ADD B
    ADD B                             ; A = GLYPH_PTR * 3
    ADD L
    MOV L,A
    MOV A,H
    ACI $00
    MOV H,A                           ; HL = GLYPH_TABLE + GLYPH_PTR*3
    MOV A,M
    STAX D                            ; write GLYPH tile 1
    INX H
    INX D
    MOV A,M
    STAX D                            ; write GLYPH tile 2
    INX H
    INX D
    MOV A,M
    STAX D                            ; write GLYPH tile 3
    POP B
    POP D
    POP H
    RET

035A CLEAR_HIGH_SCORE_DISPLAY:
    LXI H,$20A3                        ; GLYPH_POSITION = $20A3
    CALL CLEAR_4_GLYPHS

0360 CLEAR_4_GLYPHS:
    MVI B,$04                          ; BLANK_LOOP_COUNTER = 4
DRAW_BLANK_GLYPH:
    MVI A,$0A                          ; A = Blank
    CALL DRAW_GLYPH_AND_ADVANCE
    DCR B                              ; if --BLANK_LOOP_COUNTER != 0,
    JNZ DRAW_BLANK_GLYPH
                                       ; else
    RET                                ; RETURN

036C FILL_RAM:
; Input:
;   HL = RAM_PTR
;   A = FILL_VALUE
;   B = LOOP_COUNTER
;
; Fills LOOP_COUNTER bytes starting at RAM_PTR with FILL_VALUE.
    MOV M,A                            ; RAM(PTR) = FILL_VALUE
    INX H                              ; RAM_PTR++
    DCR B                              ; if --LOOP_COUNTER != 0,
    JNZ FILL_RAM
                                       ; else
    RET

0373 DRAW_GLYPH_AND_ADVANCE:
; Input:
;   A  = GLYPH
;   HL = GLYPH_POSITION
; Output:
;   HL += $20
;
; Masks A to one glyph, draws it at GLYPH_POSITION, then advances to the next
; vertical glyph position.
    ANI $0F                            ; A = GLYPH (low nibble)
    CALL DRAW_GLYPH_TILES
    MOV A,L
    ADI $20
    MOV L,A
    MOV A,H
    ACI $00
    MOV H,A                            ; HL += $20
    RET

0381 DRAW_4_GLYPHS:
; Input:
;   HL = GLYPH_POSITION
;   DE = DATA_PTR
    CALL DRAW_2_GLYPHS                 ; returns to DRAW_2_GLYPHS for glyphs 3 & 4
0384 DRAW_2_GLYPHS:
    LDAX D
    RRC
    RRC
    RRC
    RRC
    CALL DRAW_GLYPH_AND_ADVANCE        ; GLYPH = high nibble of DE
    LDAX D
    CALL DRAW_GLYPH_AND_ADVANCE        ; GLYPH = low nibble of DE
    INX D
    RET

0392 CHECK_BALL_PADDLE_COLLISION:
; Output:
;   S = 0: Ball has not missed paddle
;   S = 1: Ball missed paddle
    LDA $1152
    CPI $07                            ; if BALL_X_WORK < 7,
    JC RESULT_MISS
                                       ; else if BALL_X_WORK != 7,
    JNZ RESULT_NO_MISS
                                       ; else
    LDA $1151
    MOV C,A                            ; C = BALL_Y_WORK
    LDA $1142
    SUI $04                            ; if (A = PADDLE_LEFT_EDGE - 4) >= 0,
    JNC CHECK_PADDLE_EDGES
                                       ; else
    ADI $04                            ; A = PADDLE_LEFT_EDGE
03AB CHECK_PADDLE_EDGES:
    MOV D,A                            ; D = (PADDLE_LEFT_EDGE - 4) || PADDLE_LEFT_EDGE
    MOV A,C
    SUB D                              ; if BALL_Y_WORK < (PADDLE_LEFT_EDGE - 4),
    JC RESULT_MISS
                                       ; else
    LDA $1143
    ADI $04
    MOV D,A                            ; D = PADDLE_RIGHT_EDGE + 4
    MOV A,C
    SUB D
    DCR A                              ; A = --BALL_Y_WORK
                                       ; if BALL_Y_WORK >= (PADDLE_RIGHT_EDGE + 4),
    JNC RESULT_MISS
                                       ; else
    LXI H,$1144
    INR M                              ; PADDLE_HIT_COUNT++

    LDA $10FD
    CPI $00                            ; if GAME_ACTIVE == false,
    JZ SELECT_PADDLE_COLLISION_STAGE
                                       ; else
    MVI C,$01                          ; SOUND_BIT_MASK = 1 (ball bounce)
    CALL START_BALL_HIT_SOUND
03CE SELECT_PADDLE_COLLISION_STAGE:
    MVI B,$03                          ; B = 3
    LDA $1137
    CPI $FF                            ; if HIT_HIGH_VALUE_BLOCK == TRUE,
    JZ FIND_PADDLE_COLLISION_RECORD
                                       ; else
    INR B                              ; B = 4
    LDA $1138
    CPI $FF                            ; if HIT_TOP_WALL == TRUE,
    JZ FIND_PADDLE_COLLISION_RECORD
                                       ; else
    MVI B,$00                          ; B = 0
    LDA $1144
    CPI $05                            ; if PADDLE_HIT_COUNT < 5,
    JC FIND_PADDLE_COLLISION_RECORD
                                       ; else
    INR B                              ; B = 1
    CPI $09                            ; if PADDLE_HIT_COUNT < 9,
    JC FIND_PADDLE_COLLISION_RECORD
                                       ; else
    INR B                              ; B = 2
03F2 FIND_PADDLE_COLLISION_RECORD:
    MOV A,B
    LHLD $116D                         ; HL = ACTIVE_PADDLE_COLLISION_TABLE_PTR
03F6 GET_NEXT_PADDLE_COLLISION_RECORD:
    CMP M                              ; if B == PADDLE_COLLISION_TABLE_IDX (PTR),
    JZ UPDATE_BALL_SPEED
                                       ; else
    INX H
    INX H
    INX H
    INX H
    INX H                              ; PADDLE_COLLISION_TABLE (++)
    JMP GET_NEXT_PADDLE_COLLISION_RECORD

0402 UPDATE_BALL_SPEED:
    INX H                              ; PADDLE_COLLISION_TABLE_PTR++
    MOV A,M                            ; A = TABLE_BALL_SPEED (PTR)
    XCHG                               ; save PADDLE_COLLISION_TABLE_PTR
    LXI H,$1133                        ; HL = BALL_SPEED
    CMP M                              ; change_speed = (TABLE_BALL_SPEED >= BALL_SPEED)
    XCHG                               ; restore PADDLE_COLLISION_TABLE_PTR
                                       ; if !change_speed,
    JM APPLY_TABLE_PADDLE_WIDTH
                                       ; else
    STA $1133                          ; BALL_SPEED = TABLE_BALL_SPEED
0410 APPLY_TABLE_PADDLE_WIDTH:
    INX H                              ; PADDLE_COLLISION_TABLE_PTR++
    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == FALSE,
    JZ COMPLETE_PADDLE_BOUNCE
                                       ; else
    MOV A,M                            ; A = TABLE_PADDLE_WIDTH (PTR)
    XCHG                               ; save PADDLE_COLLISION_TABLE_PTR
    LXI H,$1141                        ; HL = PADDLE_WIDTH
    MOV C,M                            ; C = PADDLE_WIDTH
    CMP M                              ; change_paddle = TABLE_PADDLE_WIDTH < PADDLE_WIDTH
    XCHG                               ; restore PADDLE_COLLISION_TABLE_PTR
                                       ; if !change_paddle,
    JP SELECT_PADDLE_QUADRANT
                                       ; else
    MOV C,A                            ; C = TABLE_PADDLE_WIDTH (PTR)
0425 SELECT_PADDLE_QUADRANT:
    LDA $1141
    RRC
    RRC
    ANI $3F
    MOV B,A                            ; B = PADDLE_WIDTH \ 4

    LDA $1142
    DCR A                              ; A = PADDLE_LEFT_EDGE - 1
    INX H                              ; PADDLE_COLLISION_TABLE_PTR++
    PUSH H                             ; save PADDLE_COLLISION_TABLE_PTR
    LXI H,$1151
    MOV D,M                            ; D = BALL_Y_WORK
    POP H                              ; restore PADDLE_COLLISION_TABLE_PTR

    ADD B
    MVI E,$80                          ; E = #80 (LEFT)
    CMP D                              ; if BALL_Y_WORK <= ((PADDLE_LEFT_EDGE - 1) + (PADDLE_WIDTH \ 4)),
    JNC UPDATE_PADDLE_WIDTH
                                       ; else
    INX H                              ; TABLE_PTR++
    ADD B
    CMP D                              ; if BALL_Y_WORK <= ((PADDLE_LEFT_EDGE--) + (2 * (PADDLE_WIDTH \ 4))),
    JNC UPDATE_PADDLE_WIDTH
                                       ; else
    MVI E,$00                          ; E = #00 (RIGHT)
    ADD B
    CMP D                              ; if BALL_Y_WORK <= ((PADDLE_LEFT_EDGE--) + (3 * (PADDLE_WIDTH \ 4))),
    JNC UPDATE_PADDLE_WIDTH
                                       ; else
    DCX H                              ; TABLE_PTR--
044D UPDATE_PADDLE_WIDTH:
    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == FALSE,
    JZ UPDATE_BALL_Y_DIRECTION_PADDLE
                                       ; else
    MOV A,C
    STA $1141                          ; PADDLE_WIDTH = TABLE_PADDLE_WIDTH (PTR)
0459 UPDATE_BALL_Y_DIRECTION_PADDLE:
    LDA $1130
    CMP E                              ; if BALL_Y_DIR == E,
    JZ LOOKUP_BALL_TRAJECTORY
                                       ; else
    MOV A,E
    STA $1130                          ; BALL_Y_DIR = E
    CPI $00
    MVI C,$03
                                       ; if BALL_Y_DIR == RIGHT,
    JZ UPDATE_BALL_Y_LEAD_EDGE_PADDLE
                                       ; else
    MVI C,$FD
046D UPDATE_BALL_Y_LEAD_EDGE_PADDLE:
    LDA $112C
    ADD C
    STA $112C                          ; BALL_Y_LEAD_EDGE = BALL_Y_LEAD_EDGE ± 3
0474 LOOKUP_BALL_TRAJECTORY:
    MOV A,M                            ; A = TABLE_QUADRANT_IDX (PTR)
    LXI H,BALL_TRAJECTORY_POINTER_TABLE
0478 GET_NEXT_BALL_TRAJECTORY_RECORD:
    CMP M                              ; if A == TABLE_IDX (PTR),
    JZ SET_BALL_TRAJECTORY_POINTERS
                                       ; else
    INX H
    INX H
    INX H                              ; BALL_TRAJECTORY_POINTER_TABLE (++)
    JMP GET_NEXT_BALL_TRAJECTORY_RECORD

0482 SET_BALL_TRAJECTORY_POINTERS:
    INX H
    MOV D,M
    INX H
    MOV E,M                            ; DE = TABLE_DATA_PTR
    XCHG
    SHLD $1139                         ; BALL_TRAJECTORY_START_PTR = TABLE_DATA_PTR
    SHLD $113B                         ; BALL_TRAJECTORY_CURRENT_PTR = TABLE_DATA_PTR
048D COMPLETE_PADDLE_BOUNCE:
    CALL REVERSE_BALL_X_DIRECTION
    XRA A
    STA $1136                          ; BLOCK_COLLISION_DISABLED = FALSE

0494 RESULT_NO_MISS:
    XRA A
    CPI $00                            ; flag S = 0
    RET

0498 RESULT_MISS:
    MVI A,$FF
    CPI $00                            ; flag S = 1
    RET

049D CHECK_BALL_WALL_COLLISION:
    LDA $1151
    MVI B,$00                          ; wall hit = FALSE
    CPI $0C                            ; if BALL_Y_WORK == 12 (left wall),
    JZ UPDATE_BALL_Y_DIRECTION_WALL
                                       ; else
    CPI $B4                            ; if BALL_Y_WORK != 180 (right wall),
    JNZ CHECK_BALL_TOP_COLLISION
                                       ; else
04AC UPDATE_BALL_Y_DIRECTION_WALL:
    LDA $1130
    XRI $80
    STA $1130                          ; toggle BALL_Y_DIR

    LDA $112C
    MVI D,$03                          ; Y offset = 3
                                       ; if BALL_Y_DIR == RIGHT,
    JP UPDATE_BALL_Y_LEAD_EDGE_WALL
                                       ; else
    MVI D,$FD                          ; Y offset = -3
04BE UPDATE_BALL_Y_LEAD_EDGE_WALL:
    ADD D
    STA $112C                          ; BALL_Y_LEAD_EDGE = BALL_Y_LEAD_EDGE ± 3
    MVI B,$FF                          ; wall hit = true

04C4 CHECK_BALL_TOP_COLLISION:
    LDA $1152
    CPI $F7                            ; if BALL_X_WORK != 247 (top wall),
    JNZ PROCESS_BALL_WALL_COLLISION
                                       ; else
    CALL REVERSE_BALL_X_DIRECTION
    MVI B,$FF                          ; wall hit = true
04D1 PROCESS_BALL_WALL_COLLISION:
    INR B                              ; if wall hit == FALSE,
    JNZ EXIT_BALL_WALL_COLLISION
                                       ; else
    LHLD $1139
    SHLD $113B                         ; BALL_TRAJECTORY_CURRENT_PTR = BALL_TRAJECTORY_START_PTR

    LDA $10FD
    CPI $00                            ; if GAME_ACTIVE == FALSE,
    JZ EXIT_BALL_WALL_COLLISION
                                       ; else
    LDA $1152
    CPI $F7                            ; if BALL_X_WORK != 247 (top wall),
    JNZ PLAY_BALL_BOUNCE_SOUND
                                       ; else
    XRA A
    STA $1137                          ; HIT_HIGH_VALUE_BLOCK = FALSE
    STA $1136                          ; BLOCK_COLLISION_DISABLED = FALSE

    MVI A,$FF
    STA $1138                          ; HIT_TOP_WALL = TRUE

    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == FALSE,
    JZ SET_BALL_SPEED_TOP_COLLISION
                                       ; else
    MVI A,$09
    STA $1141                          ; PADDLE_WIDTH = 9
0504 SET_BALL_SPEED_TOP_COLLISION:
    LDA $1133
    SUI $04                            ; if BALL_SPEED >= 4,
    JNC PLAY_BALL_BOUNCE_SOUND
                                       ; else
    MVI A,$04
    STA $1133                          ; BALL_SPEED = 4
0511 PLAY_BALL_BOUNCE_SOUND:
    MVI C,$01                          ; SOUND_BIT_MASK = 1 (ball bounce)
    CALL START_BALL_HIT_SOUND
0516 EXIT_BALL_WALL_COLLISION:
    RET                                ; RETURN

0517 START_BALL_HIT_SOUND:
; Input:
;   C = SOUND_BIT_MASK
    LDA $112A
    ORA C                              ; set SOUND/FLIP_STATE bit C
    STA $112A
    STA $8000                          ; update SOUND/FLIP_STATE

    MVI A,$FF
    STA $1123                          ; SOUND_TIMER_ACTIVE = TRUE

    MVI A,$02
    STA $1124                          ; SOUND_DURATION_TIMER = 2
    RET                                ; RETURN

052C REVERSE_BALL_X_DIRECTION:
    LDA $1131
    XRI $80
    STA $1131                          ; toggle BALL_X_DIR

    MVI C,$03
                                       ; if BALL_X_DIR == UP,
    JP UPDATE_BALL_LEAD_EDGE
                                       ; else
    MVI C,$FD
UPDATE_BALL_LEAD_EDGE:
    LDA $112D
    ADD C
    STA $112D                          ; BALL_X_LEAD_EDGE = BALL_X_LEAD_EDGE ± 3
    RET

0543 CHECK_FORMATION_CLEARED:
    LDA $113E                          ; A = BALL_COLUMN
    LXI H,$116F                        ; HL = ACTIVE_BLOCKS_BASE_COLUMN
    SUB M
    INR A                              ; if BALL_COLUMN != BASE_COLUMN - 1,
    JNZ $05A7
                                       ; else
    LDA $1171
    CPI $00                            ; if ACTIVE_NORMAL_BLOCK_COUNT != 0,
    JNZ $05A7
                                       ; else
    LDA $1170
    CPI $16                            ; if ACTIVE_FORMATIONS_CLEARED == 22,
    JZ RETURN_FORMATION_CHECK
                                       ; else
    INR A
    STA $1170                          ; ACTIVE_FORMATIONS_CLEARED++

    LXI H,PADDLE_COLLISION_SELECTOR_TABLE
0565 GET_NEXT_PADDLE_COLLISION_TABLE:
    MOV B,M
    INR B                              ; if PADDLE_COLLISION_SELECTOR_IDX == #FF,
    JZ INIT_NEXT_FORMATION
                                       ; else
    CMP M                              ; if ACTIVE_FORMATIONS_CLEARED == PADDLE_COLLISION_SELECTOR_IDX,
    JZ SET_NEW_PADDLE_COLLISION_TABLE
                                       ; else
    INX H
    INX H
    INX H                              ; PADDLE_COLLISION_SELECTOR_TABLE (++)
    JMP GET_NEXT_PADDLE_COLLISION_TABLE

0574 SET_NEW_PADDLE_COLLISION_TABLE:
    INX H
    MOV D,M
    INX H
    MOV E,M
    XCHG
    SHLD $116D                         ; ACTIVE_PADDLE_COLLISION_TABLE_PTR = PADDLE_COLLISION_SELECTOR_PTR
057C INIT_NEXT_FORMATION:
    MVI A,$12
    STA $116F                          ; ACTIVE_BLOCKS_BASE_COLUMN = 18

    XRA A
    STA $1107                          ; HANDICAP_BLOCK_DESCENDING = FALSE

    MVI B,$70                          ; B = 112
    MVI C,$00                          ; C = 0

    LDA $1104
    CPI $00                            ; if HANDICAP_BLINK_ENABLED == FALSE,
    JZ RESET_FORMATION
                                       ; else
    MVI B,$6C                          ; B = 108
    MVI C,$02                          ; C = 2
0595 RESET_FORMATION:
    MOV A,B
    STA $1171                          ; ACTIVE_NORMAL_BLOCK_COUNT = B

    CALL INIT_ACTIVE_BLOCKS
    CALL CLEAR_BLOCK_DISPLAY_AREA
    CALL DRAW_BLOCKS

    MVI A,$04
    STA $1133                          ; BALL_SPEED = 4
05A7 RETURN_FORMATION_CHECK:
    RET                                ; RETURN

05A8 INIT_ACTIVE_BLOCKS:
    LHLD $116B
    XCHG                               ; DE = ACTIVE_HANDICAP_ROWS_PTR
    LHLD $1169                         ; HL = ACTIVE_BLOCKS_PTR
    CALL INIT_BLOCKS
    RET

05B3 UPDATE_BALL_POSITION:
    LHLD $113B                         ; HL = BALL_TRAJECTORY_CURRENT_PTR
    MOV A,M
    INR A                              ; if TRAJECTORY_DATA != #FF,
    JNZ CHECK_TRAJECTORY_ADVANCE
                                       ; else
    LHLD $1139                         ; HL = BALL_TRAJECTORY_START_PTR
    JMP PROCESS_TRAJECTORY_STEP

05C1 CHECK_TRAJECTORY_ADVANCE:
    DCR A                              ; restore TRAJECTORY_DATA
                                       ; if TRAJECTORY_DATA != #80,
    JP PROCESS_TRAJECTORY_STEP
                                       ; else
    INX H                              ; HL = BALL_TRAJECTORY_CURRENT_PTR++
05C6 PROCESS_TRAJECTORY_STEP:
    MOV A,M
    MOV C,A                            ; C = TRAJECTORY_DATA
    ANI $F0                            ; if TRAJECTORY_DATA high nibble == 0,
    JZ UPDATE_BALL_X
                                       ; else
    PUSH H                             ; save BALL_TRAJECTORY_PTR
    LXI H,$1130                        ; HL = BALL_Y_DIR
    CALL ADVANCE_BALL_COORDINATE
    POP H                              ; restore BALL_TRAJECTORY_PTR

    CALL PIXEL_TO_ROW_AND_OFFSET
    MOV D,A                            ; D = pixel in row
    MOV A,B                            ; A = ROW_INDEX
    RLC
    RLC
    RLC
    RLC
    ANI $F0
    ORA D
    STA $8003                          ; Hardware ball Y = (ROW_INDEX << 4) + pixel in row
05E4 UPDATE_BALL_X:
    MOV A,C                            ; A = TRAJECTORY_DATA
    ANI $0F                            ; if TRAJECTORY_DATA low nibble == 0,
    JZ ADVANCE_TRAJECTORY_POINTER
                                       ; else
    PUSH H                             ; save BALL_TRAJECTORY_PTR
    LXI H,$1131                        ; HL = BALL_X_DIR
    CALL ADVANCE_BALL_COORDINATE
    POP H                              ; restore BALL_TRAJECTORY_PTR
    STA $8002                          ; Hardware ball X = BALL_X_RENDER
05F5 ADVANCE_TRAJECTORY_POINTER:
    INX H
    SHLD $113B                         ; BALL_TRAJECTORY_CURRENT_PTR = BALL_TRAJECTORY_PTR++
    MVI B,$00                          ; B = FALSE
    MOV A,M                            ; A = next TRAJECTORY_DATA
    INR A                              ; if TRAJECTORY_DATA == #FF,
    JZ STORE_ADDITIONAL_BALL_STEP
                                       ; else
    DCR A                              ; restore TRAJECTORY_DATA
                                       ; if TRAJECTORY_DATA == #80,
    JM STORE_ADDITIONAL_BALL_STEP
                                       ; else
    DCR B                              ; B = TRUE
0605 STORE_ADDITIONAL_BALL_STEP:
    MOV A,B
    STA $1156                          ; ADDITIONAL_BALL_STEP = B
    RET                                ; RETURN

060A ADVANCE_BALL_COORDINATE:
; Input:
;   HL = BALL_X_DIR or BALL_Y_DIR
; Output:
;   A = BALL_X_RENDER or BALL_Y_RENDER
    MOV A,M                            ; A = BALL_DIR
    MVI B,$01                          ; BALL offset = 1
    CPI $00                            ; if BALL_DIR == #00,
    JP APPLY_BALL_COORDINATE_OFFSET
                                       ; else
    MVI B,$FF                          ; BALL offset = -1
0614 APPLY_BALL_COORDINATE_OFFSET:
    DCX H
    DCX H
    MOV A,M
    ADD B
    MOV M,A                            ; BALL_RENDER = BALL_RENDER ± 1
    MOV D,A                            ; D = BALL_RENDER

    DCX H
    DCX H
    MOV A,M
    ADD B
    MOV M,A                            ; BALL_LEAD_EDGE = BALL_LEAD_EDGE ± 1

    MOV A,D                            ; A = BALL_RENDER
    RET

0621 HANDLE_COIN:
; When a coin is detected, check COIN_PROCESSING to see if it's already being
; processed. If not, increment the CREDIT_COUNT (max 15). If GAME_IN_PROGRESS
; is clear, enable and light the appropriate 1-PLAYER/2-PLAYER buttons based on
; the resulting credit count.
    LDA $8006
    ANI $08                            ; if COIN_SWITCH == INACTIVE,
    JNZ CLEAR_COIN_PROCESSING
                                       ; else
    LDA $111B
    CPI $00                            ; if COIN_PROCESSING == TRUE,
    RNZ                                ; RETURN
                                       ; else
    MVI A,$FF
    STA $111B                          ; COIN_PROCESSING = TRUE
    LDA $111A
    CPI $0F                            ; if CREDIT_COUNT == 15,
    JZ CHECK_GAME_IN_PROGRESS
                                       ; else
    INR A
    STA $111A                          ; CREDIT_COUNT++
CHECK_GAME_IN_PROGRESS:
    MOV B,A
    LDA $1101
    CPI $00                            ; if GAME_IN_PROGRESS == TRUE,
    RNZ                                ; RETURN
                                       ; else
    MOV A,B
    CPI $01                            ; if CREDIT_COUNT != 1,
    JNZ HANDLE_2_CREDITS
                                       ; else
HANDLE_1_CREDIT:
    MVI A,$FF
    STA $1115                          ; 1_PLAYER_AVAILABLE = TRUE

    LDA $112B                          ; A = LAMPS_STATE
    ORI $02
    STA $112B
    STA $8001                          ; Light 1-Player Button
    RET                                ; RETURN

HANDLE_2_CREDITS:
    MVI A,$FF
    STA $1115                          ; 1_PLAYER_AVAILABLE = TRUE
    STA $1116                          ; 2_PLAYER_AVAILABLE = TRUE

    LDA $112B                          ; A = LAMPS_STATE
    ORI $06
    STA $112B
    STA $8001                          ; Light 1-Player/2-Player Buttons
    RET                                ; RETURN

CLEAR_COIN_PROCESSING:
    XRA A
    STA $111B                          ; COIN_PROCESSING = FALSE
    RET                                ; RETURN

0677 HANDLE_PLAYER_BUTTONS:
; Check 1-Player and 2-Player Buttons to see if they are pressed. If a button
; is PRESSED and the corresponding flag (1/2_PLAYER_AVAILABLE) is TRUE,
; initialize a new game -- scores are cleared, lamps are turned off, buttons
; are disabled, the ball is hidden, timers and state are initialized.
    LDA $8006                          ; read inputs
    MOV B,A
    ANI $02                            ; if 1-Player Button == RELEASED,
    JNZ CHECK_2_PLAYER
                                       ; else
    MVI C,$00
    LDA $1115
    CMP C                              ; if 1_PLAYER_AVAILABLE == TRUE,
    JNZ INIT_NEW_GAME

CHECK_2_PLAYER:
    MOV A,B
    ANI $04                            ; if 2-Player Button == RELEASED,
    RNZ                                ; RETURN
                                       ; else
    MVI C,$FF
    LDA $1116
    CPI $00                            ; if 2_PLAYER_AVAILABLE == FALSE,
    RZ                                 ; RETURN
                                       ; else
INIT_NEW_GAME:
    MOV A,C                            ; A = #00 (1-Player) or #FF (2-Player)
    STA $10FF                          ; 2_PLAYER_GAME = A
    XRA A
    CALL CLEAR_PLAYER_SCORES

    LDA LAMPS_STATE
    ANI $01                            ; Preserve mystery bit
    STA $8001                          ; Turn off 1-Player/2-Player lamps
    STA LAMPS_STATE

    XRA A
    STA $1115                          ; 1_PLAYER_AVAILABLE = FALSE
    STA $1116                          ; 2_PLAYER_AVAILABLE = FALSE
    STA $1132                          ; BALL_IN_PLAY = FALSE
    STA $1114                          ; SCORE_BLINK_OFF = FALSE

    LXI H,$FFFF
    SHLD $8002                         ; Ball X/Y = FF,FF (hidden)

    MVI A, $FF
    STA $1117                          ; SERVE_AVAILABLE = TRUE
    STA $10FD                          ; GAME_ACTIVE = TRUE
    STA $1101                          ; GAME_IN_PROGRESS = TRUE
    STA $110E                          ; AUTO_SERVE_ENABLED = TRUE
    STA $1118                          ; GAME_SELECT_ENABLED = TRUE
    STA $1102                          ; BLOCK_MOTION_ENABLED = TRUE

    LXI H,$2A30
    SHLD $110F                         ; AUTO_SERVE_TIMER = 10800 (3 mins)

    MVI A,$3C
    STA $1113                          ; SCORE_BLINK_TIMER = 60 (1 sec)
    RET                                ; RETURN

06DB INIT_PLAYER_BLOCKS:
; Input:
;   C = HANDICAP_PAIR_COUNT
;
; Initializes the saved block/row arrays for both players using the indicated
; Handicap-block configuration.
    PUSH B                             ; save HANDICAP_PAIR_COUNT
    LHLD $1159
    XCHG                               ; DE = P1_HANDICAP_ROWS_PTR
    LHLD $1157                         ; HL = P1_BLOCKS_PTR
    CALL INIT_BLOCKS

    POP B                              ; restore HANDICAP_PAIR_COUNT
    LHLD $1162
    XCHG                               ; DE = P2_HANDICAP_ROWS_PTR
    LHLD $1160                         ; HL = P2_BLOCKS_PTR
    CALL INIT_BLOCKS
    RET

06F2 HANDLE_SERVE_BUTTON:
    LDA $8006                          ; read inputs
    ANI $01                            ; if Serve Button == RELEASED,
    JNZ CHECK_AUTO_SERVE
                                       ; else
    LDA $1111
    CPI $00                            ; if SERVE_PENDING == TRUE,
    JNZ CHECK_SERVE_DELAY_TIMER
                                       ; else
    LDA $1117
    CPI $00                            ; if SERVE_AVAILABLE == FALSE,
    RZ                                 ; RETURN
                                       ; else
0708 INIT_SERVE:
    XRA A
    STA $1118                          ; GAME_SELECT_ENABLED = FALSE
    STA $1117                          ; SERVE_AVAILABLE = FALSE

    MVI A,$FF
    STA $1111                          ; SERVE_PENDING = TRUE
    STA $10FC                          ; $10FC (unused) = TRUE
    STA $1102                          ; BLOCK_MOTION_ENABLED = TRUE
    STA $1103                          ; SCORE_BLINK_ENABLED = TRUE

    CALL CLEAR_HIGH_SCORE_DISPLAY
    MVI A,$78
    STA $1112                          ; SERVE_DELAY_TIMER = 120 (2 secs)
    RET                                ; RETURN

0726 CHECK_AUTO_SERVE:
    LDA $1111
    CPI $00                            ; if SERVE_PENDING == FALSE,
    JZ HANDLE_AUTO_SERVE
                                       ; else
072E CHECK_SERVE_DELAY_TIMER:
    LDA $1112
    CPI $00                            ; if SERVE_DELAY_TIMER != 0,
    RNZ                                ; RETURN
                                       ; else
    LHLD $1134                         ; HL = SERVE_DATA_TABLE_PTR
    MOV A,M
    CPI $FF                            ; if SERVE_DATA_TABLE(PTR) != #FF,
    JNZ DETERMINE_PLAYER_OFFSET
                                       ; else
    LXI H,$00D8                        ; HL = SERVE_DATA_TABLE (first entry)
0740 DETERMINE_PLAYER_OFFSET:
    LXI D,$112C                        ; DE = SERVE_RECORD
    MVI C,$00                          ; C = #00 (0 for Player 1)
    LDA $10FF
    CMP C                              ; if 2_PLAYER_GAME == FALSE,
    JZ COPY_SERVE_DATA
                                       ; else
    LDA $1100
    CMP C                              ; if PLAYER_2_ACTIVE == FALSE,
    JZ COPY_SERVE_DATA
                                       ; else
    MVI C,$FD                          ; C = #FD (-3 for Player 2)
0755 COPY_SERVE_DATA:
; Copies a six byte record from the SERVE_DATA_TABLE to the SERVE_RECORD in
; RAM. If Player 2 is active, 3 is subtracted from bytes 3 and 4 before storing
; the values.
    MOV A,M
    STAX D
    INX D
    INX H

    MOV A,M
    STAX D
    INX D
    INX H

    MOV A,M
    ADD C
    STAX D
    INX D
    INX H

    MOV A,M
    ADD C
    STAX D
    INX D
    INX H

    MOV A,M
    STAX D
    INX D
    INX H

    MOV A,M
    STAX D
    INX H
; Advance SERVE_DATA_TABLE_PTR to next record
    SHLD $1134

    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == FALSE,
    JZ COMPLETE_SERVE_INIT
                                       ; else
    MVI A,$18
    STA $1141                          ; PADDLE_WIDTH = 24
077E COMPLETE_SERVE_INIT:
    MVI A,$02
    STA $1133                          ; BALL_SPEED = 2

    LXI H,$0005
    SHLD $1139                         ; BALL_TRAJECTORY_START_PTR = $0005 (Trajectory 2)
    SHLD $113B                         ; BALL_TRAJECTORY_CURRENT_PTR = $0005 (Trajectory 2)

    XRA A
    STA $1137                          ; HIT_HIGH_VALUE_BLOCK = FALSE
    STA $1138                          ; HIT_TOP_WALL = FALSE
    STA $1144                          ; PADDLE_HIT_COUNT = 0
    STA $110E                          ; AUTO_SERVE_ENABLED = FALSE
    STA $1111                          ; SERVE_PENDING = FALSE

    MVI A,$FF
    STA $1136                          ; BLOCK_COLLISION_DISABLED = TRUE
    STA $1132                          ; BALL_IN_PLAY = TRUE
    RET
    
07A5 HANDLE_AUTO_SERVE:
    LDA $110E
    CPI $00                            ; if AUTO_SERVE_ENABLED == FALSE,
    RZ                                 ; RETURN
                                       ; else
    LHLD $110F                         ; HL = AUTO_SERVE_TIMER
    XRA A                              ; A = 0
    ORA H
    ORA L                              ; if AUTO_SERVE_TIMER != 0,
    RNZ                                ; RETURN
                                       ; else
    JMP INIT_SERVE

07B5 INIT_TEST_PADDLE:
    MVI A,$0C
    STA $1142                          ; PADDLE_LEFT_EDGE = 12
    MVI A,$A9
    STA $1141                          ; PADDLE_WIDTH = 169
    MVI A,$B4
    STA $1143                          ; PADDLE_RIGHT_EDGE = 180
    RET

07C5 HANDLE_GAME_SELECT:
    LDA $1118
    CPI $00                            ; if GAME_SELECT_ENABLED == FALSE,
    RZ                                 ; RETURN
                                       ; else
    LDA $8006                          ; read inputs
    ANI $70                            ; A = GAME_SELECT
    LXI H,$1119
    CMP M                              ; if GAME_SELECT == GAME_TYPE,
    RZ                                 ; RETURN
                                       ; else
    MVI B,$12                          ; PLAYER_STATE_LOOP_COUNTER = 18
    LXI D,$1157                        ; DE = player 1&2 state
    LXI H,$00FD                        ; HL = INITIAL_PLAYER_STATE
COPY_INITIAL_PLAYER_STATE_BYTE:
    MOV A,M
    STAX D                             ; player 1&2 state = INITIAL_PLAYER_STATE
    INX H
    INX D
    DCR B                              ; if --PLAYER_STATE_LOOP_COUNTER != 0,
    JNZ COPY_INITIAL_PLAYER_STATE_BYTE
                                       ; else
    CALL RESET_DISPLAY_AND_PLAYER_STATE_PTR
    LXI H,$1169                        ; HL = active player state
    MVI B,$09                          ; PLAYER_STATE_LOOP_COUNTER = 9
COPY_ACTIVE_PLAYER_STATE_BYTE:
    LDAX D
    MOV M,A                            ; active player state = INITIAL_PLAYER_STATE (P1)
    INX D
    INX H
    DCR B                              ; if --PLAYER_STATE_LOOP_COUNTER != 0,
    JNZ COPY_ACTIVE_PLAYER_STATE_BYTE

    LDA $8006                          ; read inputs
    MOV B,A                            ; B = all inputs
    ANI $70                            ; A = GAME_SELECT
    STA $1119                          ; GAME_TYPE = GAME_SELECT
    MOV A,B                            ; A = all inputs
    ANI $10                            ; if bit 4 == 0,
    JZ INIT_GAME_A
                                       ; else
    MOV A,B                            ; A = all inputs
    ANI $20                            ; if bit 5 != 0,
    JNZ INIT_GAME_C
                                       ; else
    JMP INIT_GAME_B

080D INIT_GAME_A:
    MVI C,$01                          ; HANDICAP_PAIR_COUNT = 1
    MVI D,$6E                          ; NORMAL_BLOCK_COUNT = 110
    LDA $8007                          ; read DIP switches
    MOV B,A                            ; B = DIP switches
    ANI $20                            ; if HANDICAP_BLOCK_MODE_DIP == OFF,
    JNZ SET_HANDICAP_BLOCK_MODE
                                       ; else
    MVI C,$02                          ; HANDICAP_PAIR_COUNT = 2
    MVI D,$6C                          ; NORMAL_BLOCK_COUNT = 108
SET_HANDICAP_BLOCK_MODE:
    MOV A,D
    STA $1171                          ; ACTIVE_NORMAL_BLOCK_COUNT = NORMAL_BLOCK_COUNT
    PUSH B                             ; save DIP switches
    STA $115F                          ; P1_NORMAL_BLOCK_COUNT = NORMAL_BLOCK_COUNT
    STA $1168                          ; P2_NORMAL_BLOCK_COUNT = NORMAL_BLOCK_COUNT
    CALL INIT_PLAYER_BLOCKS

    POP B                              ; restore DIP switches
    MOV A,B
    MVI C,$0E                          ; C = 14 (descent = 4)
    ANI $40                            ; if HANDICAP_BLOCK_DESCENT_LIMIT_DIP == OFF,
    JNZ SET_HANDICAP_BLOCK_DESCENT_LIMIT
                                       ; else
    MVI C,$0A                          ; C = 10 (descent = 8)
SET_HANDICAP_BLOCK_DESCENT_LIMIT:
    MOV A,C
    STA $110A                          ; HANDICAP_BLOCK_DESCENT_LIMIT = C
    XRA A
    STA $110B                          ; BLOCK_SHIFT_ENABLED = FALSE
    LXI D,$00D2                        ; DE = GAME_TYPE_A
    CALL DRAW_GAME_TYPE_AND_HIGH_SCORE

    MVI A,$FF
    STA $1106                          ; HANDICAP_BLOCKS_VISIBLE = TRUE
    STA $1104                          ; HANDICAP_BLINK_ENABLED = TRUE

    MVI A,$3C
    STA $1105                          ; HANDICAP_BLINK_TIMER = 60 (1 sec)
    JMP INIT_COMMON

0855 INIT_GAME_B:
    MVI A,$FF
    STA $110B                          ; BLOCK_SHIFT_ENABLED = TRUE
    LXI D,$00D4                        ; DE = GAME_TYPE_B
    CALL DRAW_GAME_TYPE_AND_HIGH_SCORE

    MVI A,$78
    STA $110C                          ; BLOCK_SHIFT_TIMER = 120 (2 secs)
    JMP INIT_GAME_B_AND_C

0868 INIT_GAME_C:
    XRA A
    STA $110B                          ; BLOCK_SHIFT_ENABLED = FALSE

    LXI D,$00D6                        ; DE = GAME_TYPE_C
    CALL DRAW_GAME_TYPE_AND_HIGH_SCORE

0872 INIT_GAME_B_AND_C:
    XRA A
    STA $1104                          ; HANDICAP_BLINK_ENABLED = FALSE

    MVI C,$00                          ; HANDICAP_PAIR_COUNT = 0
    CALL INIT_PLAYER_BLOCKS

087B INIT_COMMON:
    LDA $8007                          ; read DIP switches
    MOV B,A                            ; B = DIP switches
    ANI $18                            ; A = NUM_BALLS_DIPS
    LXI H,$00BE                        ; HL = NUM_BALLS_DIP_TABLE_PTR
CHECK_NUM_BALLS_DIP_VALUE:
    CMP M                              ; if NUM_BALLS_DIPS == NUM_BALLS_DIP_TABLE(PTR)
    JZ SET_PLAYERS_BALLS
                                       ; else
    INX H
    INX H                              ; NUM_BALLS_DIP_TABLE_PTR++
    JMP CHECK_NUM_BALLS_DIP_VALUE

SET_PLAYERS_BALLS:
    INX H
    MOV A,M
    STA $1149                          ; PLAYER_1_BALLS = NUM_BALLS
    STA $114A                          ; PLAYER_2_BALLS = NUM_BALLS

    MOV A,B
    ANI $06                            ; A = REPLAY_SCORE_DIPS
    LXI H,$00C6                        ; HL = REPLAY_SCORE_DIP_TABLE_PTR
CHECK_REPLAY_SCORE_DIP_VALUE:
    CMP M                              ; if REPLAY_SCORE_DIPS == REPLAY_SCORE_DIP_TABLE(PTR)
    JZ SET_REPLAY_SCORE
                                       ; else
    INX H
    INX H
    INX H                              ; REPLAY_SCORE_DIP_TABLE_PTR++
    JMP CHECK_REPLAY_SCORE_DIP_VALUE

SET_REPLAY_SCORE:
    INX H
    MOV D,M                            ; D = REPLAY_SCORE_LO
    INX H
    MOV E,M                            ; E = REPLAY_SCORE_HI
    XCHG
    SHLD $111E                         ; REPLAY_SCORE = REPLAY_SCORE_LO/REPLAY_SCORE_HI

    MVI C,$FF                          ; C = TRUE (Game Paddle)
    MOV A,B
    ANI $80                            ; if PADDLE_MODE_DIP == OFF,
    JNZ SET_PADDLE_MODE
                                       ; else
    INR C                              ; C = FALSE (Test Paddle)
SET_PADDLE_MODE:
    MOV A,C
    STA $10FE                          ; GAME_PADDLE_MODE = C

    MOV A,B
    ANI $01                            ; C = FALSE
    MVI C,$00                          ; if REPLAY_FUNCTION_DIP == FALSE,
    JNZ SET_REPLAY_FUNCTION
                                       ; else
    DCR C                              ; C = TRUE
SET_REPLAY_FUNCTION:
    MOV A,C
    STA $111C                          ; REPLAY_FUNCTION = C

    XRA A
    STA $110D                          ; BLOCK_SHIFT_HALF = FALSE
    STA $1107                          ; HANDICAP_BLOCK_DESCENDING = FALSE

    LXI H,$1145
    MOV M,A                            ; PLAYER_1_SCORE_HI = 0
    INX H
    MOV M,A                            ; PLAYER_1_SCORE_LO = 0
    INX H
    MOV M,A                            ; PLAYER_2_SCORE_HI = 0
    INX H
    MOV M,A                            ; PLAYER_2_SCORE_LO = 0
    CALL DRAW_SCORES_AND_BALLS

    MVI A,$18
    STA $1141                          ; PADDLE_WIDTH = 24

    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == TRUE,
    JNZ FINISH_SETUP
                                       ; else
    CALL INIT_TEST_PADDLE
    CALL DRAW_BOTTOM
FINISH_SETUP:
    CALL DRAW_BLOCKS
    RET                                ; RETURN

08F2 PROCESS_BALL_COLLISIONS:
    LDA $1136
    CPI $00                            ; if BLOCK_COLLISION_DISABLED == TRUE,
    JNZ USE_BALL_INTERIOR
                                       ; else
    LDA $10FD
    CPI $00                            ; if GAME_ACTIVE == FALSE,
    JZ USE_BALL_INTERIOR
                                       ; else
    CALL COPY_BALL_COORDS_TO_WORK
    CALL CHECK_BALL_BLOCK_COLLISION

0908 USE_BALL_INTERIOR:
    LDA $1130
    MVI C,$01                          ; Y offset = +1
    CPI $00                            ; if BALL_Y_DIR == LEFT,
    JNZ TRY_BALL_PADDLE_COLLISION
                                       ; else
    MVI C,$FF                          ; Y offset = -1
0914 TRY_BALL_PADDLE_COLLISION:
    LDA $112C
    ADD C
    STA $1151                          ; BALL_Y_WORK = BALL_Y_LEAD_EDGE ± 1

    LDA $112D
    STA $1152                          ; BALL_X_WORK = BALL_X_LEAD_EDGE

    CALL CHECK_BALL_PADDLE_COLLISION   ; if miss,
    JM USE_BALL_TRAILING_EDGE
                                       ; else
0927 CHECK_WALLS_AND_RETURN:
    CALL COPY_BALL_COORDS_TO_WORK
    CALL CHECK_BALL_WALL_COLLISION

    XRA A
    CPI $00                            ; flag S = 0
    RET                                ; RETURN

0931 COPY_BALL_COORDS_TO_WORK:
    LDA $112C
    STA $1151                          ; BALL_Y_WORK = BALL_Y_LEAD_EDGE

    LDA $112D
    STA $1152                          ; BALL_X_WORK = BALL_X_LEAD_EDGE
    RET

093E USE_BALL_TRAILING_EDGE:
    LDA $1130
    MVI C,$03                          ; Y offset = +3
    CPI $00                            ; if BALL_Y_DIR == RIGHT,
    JNZ RETRY_BALL_PADDLE_COLLISION
                                       ; else
    MVI C,$FD                          ; Y offset = -3
094A RETRY_BALL_PADDLE_COLLISION:
    LDA $112C
    ADD C
    STA $1151                          ; BALL_Y_WORK = BALL_Y_LEAD_EDGE ± 3

    LDA $112D
    STA $1152                          ; BALL_X_WORK = BALL_X_LEAD_EDGE

    CALL CHECK_BALL_PADDLE_COLLISION   ; if !miss,
    JP CHECK_WALLS_AND_RETURN
                                       ; else
    RET                                ; RETURN

095E CHECK_BALL_BLOCK_COLLISION:
    LDA $110D
    CPI $00                            ; if BLOCK_SHIFT_HALF == TRUE,
    JNZ ADJUST_FOR_SHIFTED_BLOCKS
                                       ; else
    LDA $1152
    MOV C,A
    LDA $1151
096D CHECK_BLOCK_AT_BALL_COORDS:
    CALL GET_BLOCK_AT_BALL_COORDS

    CPI $00                            ; if BLOCK_STATE == 0,
    JZ CHECK_HANDICAP_BLOCK_COLLISION
                                       ; else
    XRA A
    MOV M,A                            ; BLOCK(PTR) = 0

    LXI H,$1171
    DCR M                              ; ACTIVE_NORMAL_BLOCK_COUNT--

    LDA $113E
    LXI H,$116F
    SUB M
    MOV B,A
    INR B                              ; B = BLOCK_COLUMN (BALL_COLUMN - ACTIVE_BLOCKS_BASE_COLUMN + 1)

    LXI H,BLOCK_POINTS_TABLE
    CALL LOOKUP_TABLE_BYTE             ; C = BLOCK_POINTS
    CALL ADD_POINTS_TO_SCORE
    DCR C                              ; Z = (BLOCK_POINTS == 1)
    MVI C,$02                          ; SOUND_BIT_MASK = 2 (block hit)
                                       ; if BLOCK_POINTS != 1,
    JNZ START_TRIPLE_BRICK_HIT_SOUND
                                       ; else
    CALL START_BALL_HIT_SOUND
0996 CHECK_BALL_SPEED_INCREASE:
    LDA $1137
    CPI $00                            ; if HIT_HIGH_VALUE_BLOCK == TRUE,
    JNZ FINISH_BLOCK_HIT
                                       ; else
    MOV A,B
    SUI $05                            ; if BLOCK_COLUMN < 5,
    JM FINISH_BLOCK_HIT
                                       ; else
    MVI A,$05
    STA $1133                          ; BALL_SPEED = 5

    LXI H,$0005
    SHLD $1139                         ; BALL_TRAJECTORY_START_PTR = $0005 (Trajectory 2)

    MVI A,$FF
    STA $1137                          ; HIT_HIGH_VALUE_BLOCK = TRUE
09B4 FINISH_BLOCK_HIT:
    LDA $113E
    MOV B,A                            ; VRAM_COLUMN = BALL_COLUMN
    LDA $113D                          ; ROW_INDEX = BALL_ROW
    MVI C,$00                          ; TILE_VALUE = #00 (blank)
    CALL WRITE_TILE_TO_VRAM
    CALL REVERSE_BALL_Y_DIRECTION
    LDA $110D
    CPI $00                            ; if BLOCK_SHIFT_HALF == FALSE,
    JZ $09CE
                                       ; else
    CALL DRAW_HALF_SHIFTED_BLOCKS
09CE:
    MVI A,$FF
    STA $1136                          ; BLOCK_COLLISION_DISABLED = TRUE
    LHLD $1139
    SHLD $113B                         ; BALL_TRAJECTORY_CURRENT_PTR = BALL_TRAJECTORY_START_PTR
    RET                                ; RETURN

09DA CHECK_HANDICAP_BLOCK_COLLISION:
    LDA $1104
    CPI $00                            ; if HANDICAP_BLINK_ENABLED == FALSE,
    RZ                                 ; RETURN
                                       ; else
    LDA $1106
    CPI $00                            ; if HANDICAP_BLOCKS_VISIBLE == FALSE,
    RZ                                 ; RETURN
                                       ; else
    LDA $116F
    ADI $05                            ; HANDICAP_BLOCK_COLUMN = ACTIVE_BLOCKS_BASE_COLUMN + 5
    LXI H,$113E                        ; HL = BALL_COLUMN
    CMP M                              ; if BALL_COLUMN != HANDICAP_BLOCK_COLUMN,
    RNZ                                ; RETURN
                                       ; else
    LDA $113D
    DCR A
    LHLD $116B
    ADD L
    MOV L,A
    MOV A,H
    ACI $00
    MOV H,A                            ; HL = ACTIVE_HANDICAP_ROWS_PTR + BALL_ROW - 1
    MOV A,M
    CPI $00                            ; if HANDICAP_ROWS(PTR) == FALSE,
    RZ                                 ; RETURN
                                       ; else
    XRA A
    MOV M,A                            ; HANDICAP_ROWS(PTR) = FALSE

    MVI A,$FF
    STA $1107                          ; HANDICAP_BLOCK_DESCENDING = TRUE

    LXI H,$0002
    SHLD $1108                         ; HANDICAP_BLOCK_DESCENT_TIMER = 2 (1/30 sec)

    MVI C,$04                          ; POINTS_TO_ADD = 4 and SOUND_BIT_MASK = 4 (handicap block hit)
    CALL ADD_POINTS_TO_SCORE
    CALL START_BALL_HIT_SOUND

    MVI B,$06                          ; BLOCK_COLUMN = 6
    JMP CHECK_BALL_SPEED_INCREASE

0A1B ADJUST_FOR_SHIFTED_BLOCKS:
    LDA $1152
    MOV C,A                            ; C = BALL_X
    LDA $1151                          ; A = BALL_Y - 6
    SUI $06                            ; if A < 0,
    JC WRAPPED_BLOCK
                                       ; else
    CPI $0C                            ; if A >= 12,
    JNC CHECK_SHIFTED_BLOCK
                                       ; else
WRAPPED_BLOCK:
    MVI A,$B3                          ; A = 179 (rightmost block)
CHECK_SHIFTED_BLOCK:
    JMP CHECK_BLOCK_AT_BALL_COORDS

0A31 ADD_POINTS_TO_SCORE:
; Input:
;   C = POINTS_TO_ADD
    LXI H,$1146                        ; HL = PLAYER_1_SCORE_LO
    LDA $10FF
    CPI $00                            ; if 2-PLAYER_GAME == FALSE,
    JZ ADD_POINTS
                                       ; else
    LDA $1100
    CPI $00                            ; if PLAYER_2_ACTIVE == FALSE,
    JZ ADD_POINTS
                                       ; else
    LXI H,$1148                        ; HL = PLAYER_2_SCORE_LO
ADD_POINTS:
    MOV A,M
    ADD C
    DAA
    MOV M,A                            ; SCORE_LO += POINTS_TO_ADD
    DCX H                              ; HL = SCORE_HI
    MOV A,M
    ACI $00
    DAA
    MOV M,A                            ; carry into SCORE_HI
    RET                                ; RETURN

0A52 START_TRIPLE_BRICK_HIT_SOUND:
    XRA A
    STA $1126                          ; BLOCK_HIT_SOUND_OFF_PHASE = FALSE

    MVI A,$02
    STA $1127                          ; BLOCK_HIT_SOUND_ON_TIMER = 2 (1/30 sec)
    STA $1128                          ; BLOCK_HIT_SOUND_OFF_TIMER = 2 (1/30 sec)

    MVI A,$03
    STA $1129                          ; BLOCK_HIT_SOUND_COUNT = 3
    STA $1125                          ; BLOCK_HIT_SOUND_ACTIVE = TRUE

    LDA $112A
    ORI $02                            ; set SOUND/FLIP STATE bit 1 (brick hit sound)
    STA $112A
    STA $8000                          ; update SOUND/FLIP STATE

    JMP CHECK_BALL_SPEED_INCREASE

0A74 UPDATE_AND_DRAW_GAME_PADDLE:
    MVI B,$00                          ; VRAM_COLUMN = 0
    CALL CLEAR_VRAM_COLUMN

    XRA A
    STA $1142                          ; PADDLE_LEFT_EDGE = 0

    LDA $8005                          ; read paddle
    CMA
    SUI $1E                            ; if inverted paddle < 30,
    JC PADDLE_LEFT_EXTREME
                                       ; else
    CPI $0C                            ; if (inverted paddle - 30) < 12,
    JC PADDLE_LEFT_EXTREME

    STA $1143                          ; PADDLE_RIGHT_EDGE = (inverted paddle - 30)

    LXI H,$1141
    SUB M
    INR A                              ; if PADDLE_RIGHT_EDGE < PADDLE_WIDTH,
    JC CHECK_FOR_PADDLE_RENDER
                                       ; else
    CPI $B4                            ; if (PADDLE_RIGHT_EDGE - PADDLE_WIDTH + 1) >= 180,
    JNC PADDLE_RIGHT_EXTREME
                                       ; else
    STA $1142                          ; PADDLE_LEFT_EDGE = PADDLE_RIGHT_EDGE - PADDLE_WIDTH + 1

0A9E CHECK_FOR_PADDLE_RENDER:
    LDA $1141
    CPI $09                            ; if PADDLE_WIDTH != 9,
    JNZ RENDER_PADDLE
                                       ; else
    LDA $1142                          ; A = PADDLE_LEFT_EDGE
    CALL PIXEL_TO_ROW_AND_OFFSET

    CPI $04                            ; if pixel in row(PADDLE_LEFT_EDGE) >= 4,
    JP RENDER_PADDLE
                                       ; else
    LXI H,SMALL_PADDLE_TILE_TABLE
0AB4 LOOKUP_AND_DRAW_PADDLE_TILE:
    CALL LOOKUP_TABLE_BYTE

0AB7 DRAW_PADDLE_TILE:
; Input:
;   B = ROW_INDEX (1-15)
;   C = TILE_VALUE
    MOV A,B
    MVI B,$00                          ; VRAM_COLUMN = 0
    CALL WRITE_VALUE_TO_VRAM
    RET                                ; RETURN

0ABE PADDLE_RIGHT_EXTREME:
    MVI C,$3C                          ; TILE_VALUE = 3C (paddle, right extreme)
    MVI B,$0F                          ; ROW_INDEX = 15
    MVI A,$B5
    STA $1142                          ; PADDLE_LEFT_EDGE = #B5 (181)
    JMP DRAW_PADDLE_TILE

0ACA PADDLE_LEFT_EXTREME:
    MVI C,$39                          ; TILE_VALUE = 39 (paddle, left extreme)
    MVI B,$01                          ; ROW_INDEX = 1
    MVI A,$0C
    STA $1143                          ; PADDLE_RIGHT_EDGE = #0C (12)
    JMP DRAW_PADDLE_TILE

0AD6 RENDER_PADDLE:
    XRA A
    STA $1151                          ; PADDLE_LEFT_TILE_ROW = 0

    LDA $1142                          ; A = PADDLE_LEFT_EDGE
    CPI $0C                            ; if PADDLE_LEFT_EDGE < 12,
    JC RENDER_RIGHT_SIDE
                                       ; else
    CALL PIXEL_TO_ROW_AND_OFFSET
    LXI H,LEFT_PADDLE_TILE_TABLE
    CALL LOOKUP_AND_DRAW_PADDLE_TILE
    STA $1151                          ; set PADDLE_LEFT_TILE_ROW

0AEE RENDER_RIGHT_SIDE:
    MVI B,$0F                          ; ROW_INDEX = 15
    MVI C,$3C                          ; TILE_VALUE = 3C (paddle, right extreme)

    LDA $1143                          ; A = PADDLE_RIGHT_EDGE
    CPI $B4                            ; if PADDLE_RIGHT_EDGE >= 180,
    JNC DRAW_RIGHT_SIDE
                                       ; else
    CALL PIXEL_TO_ROW_AND_OFFSET
    LXI H,RIGHT_PADDLE_TILE_TABLE
    CALL LOOKUP_TABLE_BYTE

0B03 DRAW_RIGHT_SIDE:
    CALL DRAW_PADDLE_TILE
    STA $1152                          ; set PADDLE_RIGHT_TILE_ROW

    LDA $1151                          ; A = PADDLE_LEFT_TILE_ROW
    LXI H,$1152
    CMP M                              ; if PADDLE_LEFT_TILE_ROW == PADDLE_RIGHT_TILE_ROW,
    RZ                                 ; RETURN
                                       ; else
    MVI B,$00                          ; VRAM_COLUMN = 0
    MVI C,$24                          ; TILE_VALUE = 24 (paddle, 12px)

0B15 DRAW_MIDDLE_TILE:
    INR A
    CMP M                              ; if ++PADDLE_LEFT_TILE_ROW == PADDLE_RIGHT_TILE_ROW,
    RZ                                 ; RETURN
                                       ; else
    CALL WRITE_VALUE_TO_VRAM
    JMP DRAW_MIDDLE_TILE

0B1E LOOKUP_TABLE_BYTE:
; Input:
;   HL = TABLE_PTR
;   A = TABLE_INDEX
; Output:
;   HL = TABLE_PTR + TABLE_INDEX
;   C = TABLE_VALUE
    ADD L
    MOV L,A
    MOV A,H
    ACI $00
    MOV H,A                            ; HL += A
    MOV C,M                            ; TABLE_VALUE = TABLE(A)
    RET                                ; RETURN

0B26 COPY_PLAYER_STATE_DE->HL:
    MVI B,$09                          ; COPY_LOOP_COUNTER = 9
COPY_B_BYTES_DE->HL:
; Input:
;   DE = DATA_PTR
;   HL = RAM_PTR
;   B = COPY_LOOP_COUNTER
; Output:
;   RAM <- DATA
;
; Copies COPY_LOOP_COUNTER bytes of data starting from DATA_PTR into RAM
; starting from RAM_PTR.
    LDAX D                             ; A = DATA(PTR)
    MOV M,A                            ; RAM(PTR) = DATA(PTR)
    INX D                              ; DATA_PTR++
    INX H                              ; RAM_PTR++
    DCR B                              ; if COPY_LOOP_COUNTER-- > 0,
    JNZ COPY_B_BYTES_DE->HL
                                       ; else
    RET                                ; RETURN

0B31 SWITCH_PLAYER_DISPLAY:
    STA $112A
    STA $8000                          ; update SOUND/FLIP_STATE
    CALL CLEAR_BLOCK_DISPLAY_AREA
    CALL DRAW_BLOCKS
    RET                                ; RETURN

0B3E CLEAR_VRAM_COLUMN:
; Input:
;   B = VRAM_COLUMN
    MVI A,$0F                          ; ROW_INDEX = 15
    MVI C,$07                          ; TILE_VALUE = #07 (right wall)
WRITE_NEXT_TILE:
    CALL WRITE_TILE_TO_VRAM
    MVI C,$00                          ; TILE_VALUE = #00 (blank)
    DCR A                              ; if --ROW_INDEX != 0,
    JNZ WRITE_NEXT_TILE
                                       ; else
    RET                                ; RETURN

0B4C STARTUP:
    LXI SP,$1200                       ; INIT_STACK <= $11FF (? bytes reserved for stack)
; Init RAM from $10FC-$11FA = 0
    XRA A                              ; A = 0
    MVI B,$FF                          ; CLEAR_RAM_LOOP_COUNTER = 255
    LXI H,$10FC                        ; RAM_PTR = $10FC

ZERO_OUT_RAM:
    MOV M,A                            ; RAM(PTR) = 0
    INX H                              ; RAM_PTR++
    DCR B                              ; if --CLEAR_RAM_LOOP_COUNTER != 0,
    JNZ ZERO_OUT_RAM
                                       ; else
; Initialize attract mode. The attract display uses Game A with four Handicap
; blocks.
    LXI H,$0008
    SHLD $112A                         ; SOUND/FLIP_STATE = #80, LAMPS_STATE = #00
    SHLD $8000                         ; $8000 (sound bits = 000, screen-flip = 1), $8001 (lamps = 0)
    LXI H,$00D8
    SHLD $1134                         ; $1134 = #D8, $1135 = #00
; Initialize attract-mode active player state from ROM.
    LXI D,$00FD                        ; DE = INITIAL_PLAYER_STATE
    LXI H,$1169                        ; HL = ACTIVE_PLAYER_STATE
    CALL COPY_PLAYER_STATE_DE->HL

    MVI A,$FF
    STA $1106                          ; HANDICAP_BLOCKS_VISIBLE = TRUE
    STA $1104                          ; HANDICAP_BLINK_ENABLED = TRUE

    MVI A,$3C
    STA $1105                          ; HANDICAP_BLINK_TIMER = 60 (1 sec)

    MVI C,$02                          ; HANDICAP_PAIR_COUNT = 2
    CALL INIT_ACTIVE_BLOCKS
    CALL INIT_DISPLAY
    CALL DRAW_BOTTOM

    LXI D,$00D2                        ; DATA_PTR = GAME_TYPE_A
    CALL DRAW_GAME_TYPE_AND_HIGH_SCORE
    CALL DRAW_BLOCKS

0B94:
    LXI D,$00D8                        ; DE = SERVE_DATA_TABLE
    LXI H,$112C                        ; HL = SERVE_RECORD
    MVI B,$06                          ; B = 6
    CALL COPY_B_BYTES_DE->HL

    CALL INIT_TEST_PADDLE
    CALL COMPLETE_SERVE_INIT
0BA5 WAIT_FOR_VBLANK:
    CALL HANDLE_COIN
    CALL HANDLE_PLAYER_BUTTONS
    CALL HANDLE_GAME_SELECT
    CALL HANDLE_SERVE_BUTTON
    LDA $8004
    ANI $01                            ; if VBLANK == FALSE,
    JZ WAIT_FOR_VBLANK
                                       ; else
    MVI B,$00
    LDA $1123
    CMP B                              ; if SOUND_TIMER_ACTIVE == FALSE,
    JZ CHECK_REPLAY_OUTPUT_TIMER
                                       ; else
    LXI H,$1124
    DCR M                              ; if --SOUND_TIMER != 0,
    JNZ CHECK_REPLAY_OUTPUT_TIMER
                                       ; else
    LDA $112A                          ; load SOUND/FLIP STATE
    ANI $08                            ; clear sound bits, preserve flip
    STA $8000
    STA $112A                          ; save SOUND/FLIP STATE

    XRA A
    STA $1123                          ; SOUND_TIMER_ACTIVE = FALSE

0BD8 CHECK_REPLAY_OUTPUT_TIMER:
    LDA $1120
    CMP B                              ; if REPLAY_OUTPUT_TIMER_ACTIVE == FALSE,
    JZ $0BF5
                                       ; else
    LXI H,$1121
    DCR M                              ; if --REPLAY_OUTPUT_TIMER != 0,
    JNZ $0BF5
                                       ; else
; Turn off LAMPS bit 0
    LDA $112B                          ; load LAMPS_STATE
    ANI $FE                            ; clear bit 0, preserve P1/P2 button lamps
    STA $8001
    STA $112B                          ; save LAMPS_STATE

    XRA A
    STA $1120                          ; REPLAY_OUTPUT_TIMER_ACTIVE = FALSE

0BF5:
    LHLD $110F
    DCX H
    SHLD $110F                         ; AUTO_SERVE_TIMER--

    LXI H,$1112
    DCR M                              ; SERVE_DELAY_TIMER--
    LDA $1102
    CMP B                              ; if BLOCK_MOTION_ENABLED == FALSE,
    JZ $0C6E
                                       ; else
    LDA $110B
    CMP B                              ; if BLOCK_SHIFT_ENABLED = FALSE,
    JZ $0C32
                                       ; else
    LXI H,$110C
    DCR M                              ; if --BLOCK_SHIFT_TIMER != 0,
    JNZ $0C32
                                       ; else
    LDA $110D
    CMA                                ; toggle BLOCK_SHIFT_HALF
    STA $110D
    CPI $00                            ; if BLOCK_SHIFT_HALF == TRUE,
    JNZ DRAW_BLOCK_SHIFT_HALF
                                       ; else
    CALL ROTATE_BLOCKS_RIGHT
    CALL DRAW_BLOCKS
    JMP RESET_BLOCK_SHIFT_TIMER

DRAW_BLOCK_SHIFT_HALF:
    CALL DRAW_HALF_SHIFTED_BLOCKS
RESET_BLOCK_SHIFT_TIMER:
    MVI A,$78
    STA $110C                          ; BLOCK_SHIFT_TIMER = 120 (2 secs)
0C32:
    LDA $1107
    CPI $00                            ; if HANDICAP_BLOCK_DESCENDING == FALSE,
    JZ $0C6E
                                       ; else
    XRA A
    LHLD $1108
    DCX H
    SHLD $1108                         ; HANDICAP_BLOCK_DESCENT_TIMER--

    ORA H
    ORA L                              ; if HANDICAP_BLOCK_DESCENT_TIMER != 0,
    JNZ $0C6E
                                       ; else
    LDA $116F                          ; A = ACTIVE_BLOCKS_BASE_COLUMN
    LXI H,$110A                        ; HL = HANDICAP_BLOCK_DESCENT_LIMIT
    CMP M                              ; if ACTIVE_BLOCKS_BASE_COLUMN == HANDICAP_BLOCK_DESCENT_LIMIT,
    JZ STOP_DESCENDING
                                       ; else
    DCR A
    STA $116F                          ; ACTIVE_BLOCKS_BASE_COLUMN--

    LXI H,$0096
    SHLD $1108                         ; HANDICAP_BLOCK_DESCENT_TIMER = 150 (2.5 sec)
    LDA $116F
    ADI $08
    MOV B,A                            ; VRAM_COLUMN = ACTIVE_BLOCKS_BASE_COLUMN + 8 (vacated column)
    CALL CLEAR_VRAM_COLUMN
    CALL DRAW_BLOCKS
    JMP $0C6E

STOP_DESCENDING:
    XRA A
    STA $1107                          ; HANDICAP_BLOCK_DESCENDING = FALSE

0C6E:
    CALL HANDLE_TEST_PADDLE_DIP
    CALL UPDATE_BRICK_HIT_SOUND
    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == FALSE,
    JZ $0C87
                                       ; else
    LDA $10FD
    CPI $00                            ; if GAME_ACTIVE == FALSE,
    JZ $0C87
                                       ; else
    CALL UPDATE_AND_DRAW_GAME_PADDLE

0C87:
    LDA $1132
    CPI $00                            ; if BALL_IN_PLAY == FALSE,
    JZ $0CBA
                                       ; else
    LDA $1133
    STA $1155                          ; BALL_SPEED_WORK = BALL_SPEED
0C95:
    CALL PROCESS_BALL_COLLISIONS       ; if miss,
    JNZ $0D36
                                       ; else
    CALL UPDATE_BALL_POSITION
    LDA $112D
    MOV C,A                            ; C = BALL_X_LEAD_EDGE
    LDA $112C                          ; A = BALL_Y_LEAD_EDGE
    CALL GET_BLOCK_AT_BALL_COORDS
    CALL CHECK_FORMATION_CLEARED
    LDA $1156
    CPI $00                            ; if ADDITIONAL_BALL_STEP == FALSE,
    JNZ $0C95
                                       ; else
    LXI H,$1155
    DCR M                              ; if --BALL_SPEED_WORK != 0,
    JNZ $0C95
                                       ; else
0CBA:
    LDA $1103
    CPI $00                            ; if SCORE_BLINK_ENABLED == FALSE,
    JZ $0D04
                                       ; else
    LXI H,$1113
    DCR M                              ; if --SCORE_BLINK_TIMER != 0,
    JNZ $0D04
                                       ; else
    LXI H,$207A                        ; GLYPH_POSITION = P1_SCORE
    LDA $10FF
    CPI $00                            ; if 2_PLAYER_GAME == FALSE,
    JZ HIDE_ACTIVE_SCORE
                                       ; else
    LDA $1100
    CPI $00                            ; if PLAYER_2_ACTIVE == FALSE,
    JZ HIDE_ACTIVE_SCORE
                                       ; else
    LXI H,$213A                        ; GLYPH_POSITION = P2_SCORE
0CDF HIDE_ACTIVE_SCORE:
    LDA $1114
    CPI $00                            ; if SCORE_BLINK_OFF == FALSE,
    JNZ SHOW_ACTIVE_SCORE

    CALL CLEAR_4_GLYPHS
    MVI A,$FF
    STA $1114                          ; SCORE_BLINK_OFF = TRUE
    MVI A,$14
    STA $1113                          ; SCORE_BLINK_TIMER = 20 (1/3 sec)
    JMP $0D04

0CF7 SHOW_ACTIVE_SCORE:
    MOV A,B
    CALL DRAW_SCORES_AND_BALLS
    XRA A
    STA $1114                          ; SCORE_BLINK_OFF = FALSE
    MVI A,$3C
    STA $1113                          ; SCORE_BLINK_TIMER = 60 (1 sec)

0D04:
    LDA $1104
    CPI $00                            ; if HANDICAP_BLINK_ENABLED == FALSE,
    JZ $0D2B
                                       ; else
    LXI H,$1105
    DCR M                              ; if --HANDICAP_BLINK_TIMER != 0,
    JNZ $0D2B
                                       ; else
    MVI C,$01                          ; TILE_VALUE = #01 (block)
    LDA $1106
    CPI $00                            ; if HANDICAP_BLOCKS_VISIBLE == FALSE,
    JZ $0D1F
                                       ; else
    MVI C,$00                          ; TILE_VALUE = #00 (blank)
0D1F:
    CMA
    STA $1106                          ; toggle HANDICAP_BLOCKS_VISIBLE
    CALL UPDATE_HANDICAP_BLOCK_DISPLAY
    MVI A,$3C
    STA $1105                          ; HANDICAP_BLINK_TIMER = 60 (1 sec)

0D2B WAIT_FOR_VBLANK_END:
    LDA $8004
    ANI $01                            ; if VBLANK == TRUE,
    JNZ WAIT_FOR_VBLANK_END
                                       ; else
    JMP WAIT_FOR_VBLANK

0D36:
    XRA A
    STA $1132                          ; BALL_IN_PLAY = FALSE
    STA $10FC                          ; $10FC (unused) = FALSE
    STA $1102                          ; BLOCK_MOTION_ENABLED = FALSE
    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == FALSE,
    JZ $0D4D
                                       ; else
    MVI A,$18
    STA $1141                          ; PADDLE_WIDTH = 24
0D4D:
    LXI H,$FFFF
    SHLD $8002                         ; Ball X/Y = FF,FF (hidden)
    LDA $10FF
    CPI $00                            ; if 2_PLAYER_GAME == FALSE,
    JZ $0DE2
                                       ; else
    LDA $1100
    CPI $00                            ; if PLAYER_2_ACTIVE == TRUE,
    JNZ HANDLE_PLAYER_2_BALL_LOSS
                                       ; else
    MVI A,$FF
    STA $1100                          ; PLAYER_2_ACTIVE = TRUE
    LXI H,$1149
    DCR M                              ; PLAYER_1_BALLS--
    CALL DRAW_SCORES_AND_BALLS
    LXI D,$1169                        ; DE = ACTIVE_PLAYER_STATE
    LXI H,$1157                        ; HL = PLAYER_1_STATE
    CALL COPY_PLAYER_STATE_DE->HL
    LXI D,$1160                        ; DE = PLAYER_2_STATE
    LXI H,$1169                        ; HL = ACTIVE_PLAYER_STATE
    CALL COPY_PLAYER_STATE_DE->HL
    LDA $112A
    ANI $F7                            ; clear FLIP_STATE (select Player 2 orientation)
    CALL SWITCH_PLAYER_DISPLAY
    LDA $1149
    CPI $00                            ; if PLAYER_1_BALLS != 0,
    JNZ $0D97
                                       ; else
    LXI H,$1146                        ; HL = PLAYER_1_SCORE_LO
    CALL $0EF5
0D97:
    XRA A
    STA $1107                          ; HANDICAP_BLOCK_DESCENDING = FALSE
    MVI A,$FF
    STA $1117                          ; SERVE_AVAILABLE = TRUE
    STA $110E                          ; AUTO_SERVE_ENABLED = TRUE
    LXI H,$2A30
    SHLD $110F                         ; AUTO_SERVE_TIMER = 10800 (3 mins)
    JMP $0CBA

0DAC HANDLE_PLAYER_2_BALL_LOSS:
    XRA A
    STA $1100                          ; PLAYER_2_ACTIVE = FALSE
    LXI H,$114A
    DCR M                              ; PLAYER_2_BALLS--
    CALL DRAW_SCORES_AND_BALLS
    LXI D,$1169                        ; DE = ACTIVE_PLAYER_STATE
    LXI H,$1160                        ; HL = PLAYER_2_STATE
    CALL COPY_PLAYER_STATE_DE->HL
    LXI D,$1157                        ; DE = PLAYER_1_STATE
    LXI H,$1169                        ; HL = ACTIVE_PLAYER_STATE
    CALL COPY_PLAYER_STATE_DE->HL
    LDA $112A
    ORI $08                            ; set FLIP_STATE (select Player 1 orientation)
    CALL SWITCH_PLAYER_DISPLAY
    LDA $114A
    CPI $00                            ; if PLAYER_2_BALLS != 0,
    JNZ $0D97
                                       ; else
    LXI H,$1148                        ; HL = PLAYER_2_SCORE_LO
    CALL $0EF5
    JMP $0DF7

0DE2:
    LXI H,$1149
    DCR M                              ; PLAYER_1_BALLS--
    CALL DRAW_SCORES_AND_BALLS
    LDA $1149
    CPI $00                            ; if PLAYER_1_BALLS != 0,
    JNZ $0D97
                                       ; else
    LXI H,$1146                        ; HL = PLAYER_1_SCORE_LO
    CALL $0EF5
0DF7:
    XRA A
    STA $10FD                          ; GAME_ACTIVE = FALSE
    NOP                                ; Unused 3-byte instruction slot
    NOP                                ; Probable removal of setting a flag to FALSE
    NOP                                ; HANDICAP_BLOCK_DESCENDING?
    STA $1103                          ; SCORE_BLINK_ENABLED = FALSE
    MVI A,$FF
    STA $1102                          ; BLOCK_MOTION_ENABLED = TRUE
    CALL DRAW_SCORES_AND_BALLS
    CALL DRAW_BOTTOM
    CALL INIT_TEST_PADDLE
    LDA $1119
    CPI $60                            ; if GAME_TYPE bit 4 == 1,
    JNZ $0E26
                                       ; else
; Game A
    LHLD $114B                         ; HL = GAME_A_HIGH_SCORE
    CALL UPDATE_GAME_HIGH_SCORE
    SHLD $114B                         ; update GAME_A_HIGH_SCORE
    LXI D,$00D2                        ; D = GAME_TYPE_A
    JMP $0E43

0E26:
    CPI $50                            ; if GAME_TYPE bit 5 == 1,
    JNZ $0E37
                                       ; else
; Game B
    LHLD $114D                         ; HL = GAME_B_HIGH_SCORE
    CALL UPDATE_GAME_HIGH_SCORE
    SHLD $114D                         ; update GAME_B_HIGH_SCORE
    JMP $0F7B

; Game C
0E37:
    LHLD $114F                         ; HL = GAME_C_HIGH_SCORE
    CALL UPDATE_GAME_HIGH_SCORE
    SHLD $114F                         ; update GAME_C_HIGH_SCORE
    LXI D,$00D6                        ; D = GAME_TYPE_C
0E43:
    CALL UPDATE_GAME_OVER_DISPLAY
    LDA $1122
    CPI $00                            ; if REPLAY_EARNED == FALSE,
    JZ $0E5E
                                       ; else
    LDA $111C
    CPI $00                            ; if REPLAY_FUNCTION == FALSE,
    JZ $0E5E
                                       ; else
    LDA $111D
    CPI $00                            ; if REPLAY_IN_PROGRESS == FALSE,
    JZ $0E8D
                                       ; else
0E5E:
    XRA A
    STA $111D                          ; REPLAY_IN_PROGRESS = FALSE
    STA $1122                          ; REPLAY_EARNED = FALSE
    STA $1101                          ; GAME_IN_PROGRESS = FALSE
    LDA $111A
    DCR A
    MOV B,A                            ; UPDATED_CREDIT_COUNT (B) = CREDIT_COUNT - 1
    LDA $10FF
    CPI $00                            ; if 2_PLAYER_GAME == FALSE,
    JZ $0E76
                                       ; else
    DCR B                              ; UPDATED_CREDIT_COUNT--
0E76:
    MOV A,B
    CPI $00                            ; no_credits = (UPDATED_CREDIT_COUNT == 0)
    STA $111A                          ; CREDIT_COUNT = UPDATED_CREDIT_COUNT
                                       ; if no_credits,
    JZ $0E86
                                       ; else
    DCR A                              ; if UPDATED_CREDIT_COUNT > 1,
    JNZ $0EA0
                                       ; else
    JMP $0E9A

0E86:
    XRA A
    STA $10FE                          ; GAME_PADDLE_MODE = FALSE
    JMP $0B94

0E8D:
    MVI A,$FF
    STA $111D                          ; REPLAY_IN_PROGRESS = TRUE
    LDA $10FF
    CPI $00                            ; if 2_PLAYER_GAME == TRUE,
    JNZ $0EA6
                                       ; else
0E9A:
    CALL HANDLE_1_CREDIT
    JMP $0CBA

0EA0:
    CALL HANDLE_2_CREDITS
    JMP $0CBA

0EA6:
    MVI A,$FF
    STA $1116                          ; 2_PLAYER_AVAILABLE = TRUE
    LDA $112B                          ; A = LAMPS_STATE
    ORI $04                            ; set lamp bit 2
    STA $112B
    STA $8001                          ; update LAMPS_STATE
    JMP $0CBA

0EB9 CHECK_REPLAY_SCORE:
; Input:
;   HL = PLAYER_SCORE_LO
    XCHG                               ; DE = PLAYER_SCORE_LO
    LXI H,$111F                        ; HL = REPLAY_SCORE_LO

    LDAX D                             ; A = PLAYER_SCORE_LO
    SUB M
    DCX H                              ; HL = REPLAY_SCORE_HI
    DCX D
    LDAX D                             ; A = PLAYER_SCORE_HI
    SBB M                              ; if PLAYER_SCORE < REPLAY_SCORE,
    JC ESCAPE_CHECK_REPLAY
                                       ; else
    MVI A,$FF
    STA $1120                          ; REPLAY_OUTPUT_TIMER_ACTIVE = TRUE
    STA $1122                          ; REPLAY_EARNED = TRUE

    LDA $112B                          ; A = LAMPS_STATE
    ORI $01                            ; set lamp bit 0
    STA $112B
    STA $8001                          ; update LAMPS_STATE

    MVI A,$07
    STA $1121                          ; REPLAY_OUTPUT_TIMER = 7 (7/60 sec)
0EDE ESCAPE_CHECK_REPLAY:
    RET                                ; RETURN

0EDF UPDATE_HIGH_SCORE_IF_GREATER:
; Input:
;   HL = PLAYER_SCORE
;   DE = HIGH_SCORE
; Output:
;   DE = max(PLAYER_SCORE,HIGH_SCORE)
    MOV A,D
    SUB H
    MOV A,E
    SBB L                              ; if PLAYER_SCORE <= HIGH_SCORE,
    RNC                                ; RETURN
                                       ; else
    XCHG                               ; DE = PLAYER_SCORE
    RET                                ; RETURN

0EE6 UPDATE_GAME_HIGH_SCORE:
; Input:
;   HL = HIGH_SCORE
; Output:
;   HL = max(HIGH_SCORE,PLAYER_1_SCORE,PLAYER_2_SCORE)
    XCHG                               ; DE = HIGH_SCORE
    LHLD $1145                         ; HL = PLAYER_1_SCORE
    CALL UPDATE_HIGH_SCORE_IF_GREATER
    LHLD $1147                         ; HL = PLAYER_2_SCORE
    CALL UPDATE_HIGH_SCORE_IF_GREATER
    XCHG                               ; HL = HIGH_SCORE (updated)
    RET                                ; RETURN

0EF5:
    LDA $111D
    CPI $00                            ; if REPLAY_IN_PROGRESS == TRUE,
    RNZ                                ; RETURN
                                       ; else
    CALL $0EB9
    RET                                ; RETURN

0EFF UPDATE_BRICK_HIT_SOUND:
    LDA $1125
    CPI $00                            ; if BLOCK_HIT_SOUND_ACTIVE == FALSE,
    RZ                                 ; RETURN
                                       ; else
    LDA $1126
    CPI $00                            ; if BLOCK_HIT_SOUND_OFF_PHASE == TRUE,
    JNZ UPDATE_BRICK_HIT_SOUND_GAP
                                       ; else
    LXI H,$1127
    DCR M                              ; if --BLOCK_HIT_SOUND_ON_TIMER != 0,
    RNZ                                ; RETURN
                                       ; else
    LDA $112A
    ANI $FD                            ; clear SOUND/FLIP STATE bit 1 (brick hit sound)
    STA $112A
    STA $8000                          ; update SOUND/FLIP STATE

    MVI A,$FF
    STA $1126                          ; BLOCK_HIT_SOUND_OFF_PHASE = TRUE
    RET                                ; RETURN

UPDATE_BRICK_HIT_SOUND_GAP:
    LXI H,$1128
    DCR M                              ; if --BLOCK_HIT_SOUND_OFF_TIMER != 0,
    RNZ                                ; RETURN
                                       ; else
    LXI H,$1129
    DCR M                              ; if --BLOCK_HIT_SOUND_COUNT != 0,
    JNZ START_BRICK_HIT_SOUND
                                       ; else
    XRA A
    STA $1125                          ; BLOCK_HIT_SOUND_ACTIVE = FALSE
    RET                                ; RETURN

0F34 START_BRICK_HIT_SOUND:
    XRA A
    STA $1126                          ; BLOCK_HIT_SOUND_OFF_PHASE = FALSE

    MVI A,$02
    STA $1127                          ; BLOCK_HIT_SOUND_ON_TIMER = 2 (1/30 sec)
    STA $1128                          ; BLOCK_HIT_SOUND_OFF_TIMER = 2 (1/30 sec)

    LDA $112A
    ORI $02                            ; set SOUND/FLIP STATE bit 1 (brick hit sound)
    STA $112A
    STA $8000                          ; update SOUND/FLIP STATE
    RET

0F4C HANDLE_TEST_PADDLE_DIP:
    LDA $10FD
    CPI $00                            ; if GAME_ACTIVE == FALSE,
    RZ                                 ; RETURN
                                       ; else
    LDA $10FE
    CPI $00                            ; if GAME_PADDLE_MODE == TRUE,
    RNZ                                ; RETURN
                                       ; else
    LDA $8007                          ; read DIP switches
    ANI $80                            ; if PADDLE_MODE_DIP == OFF,
    JNZ DISABLE_TEST_PADDLE
                                       ; else
    CALL INIT_TEST_PADDLE
    CALL DRAW_BOTTOM
    RET                                ; RETURN

0F67 DISABLE_TEST_PADDLE:
    MVI B,$00                          ; VRAM_COLUMN = 0 (bottom)
    CALL CLEAR_VRAM_COLUMN

    MVI A,$B5
    STA $1142                          ; PADDLE_LEFT_EDGE = 181

    MVI A,$0B
    STA $1143                          ; PADDLE_RIGHT_EDGE = 11

    XRA A
    STA $1141                          ; PADDLE_WIDTH = 0
    RET                                ; RETURN

0F7B:
    LXI D,$00D4                        ; D = GAME_TYPE_B
    JMP $0E43

0F81 UPDATE_GAME_OVER_DISPLAY:
    CALL DRAW_GAME_TYPE_AND_HIGH_SCORE
    XRA A
    STA $1119                          ; clear GAME_TYPE
    RET

0F89 RESET_DISPLAY_AND_PLAYER_STATE_PTR:
    CALL INIT_DISPLAY
    LXI D,$00FD                        ; DE = INITIAL_PLAYER_STATE
    RET

0F90 CLEAR_PLAYER_SCORES:
; Input:
;   A must be 0.
;
; Sets PLAYER_2_ACTIVE to FALSE and clears PLAYER_1/2_SCORE.
    STA $1100                          ; PLAYER_2_ACTIVE = FALSE
    LXI H,$1145
    MOV M,A
    INX H
    MOV M,A                            ; PLAYER_1_SCORE = 0
    INX H
    MOV M,A
    INX H
    MOV M,A                            ; PLAYER_2_SCORE = 0
    RET                                ; RETURN

0F9E:
; 98 bytes of apparently unused ROM.
; Contains high-bit ASCII strings and apparent address records.
; Possibly residual development-tool data.
; No known references.
    ; L  ADR 3140<CR>
    DB $CC,$A0,$A0,$C1,$C4,$D2,$A0,$B3,$B1,$B4,$B0,$8D
    DB $00,$00
    ; J00S  ADR 5250<CR>
    DB $CA,$B0,$B0,$D3,$A0,$A0,$C1,$C4,$D2,$A0,$B5,$B2,$B5,$B0,$8D
    DB $CC,$0F
    ; J00S  ADR 7265<CR>
    DB $CA,$B0,$B0,$D3,$A0,$A0,$C1,$C4,$D2,$A0,$B7,$B2,$B6,$B5,$8D
    DB $DD,$0F
    ; H00S  ADR 5250<CR>
    DB $C8,$B0,$B0,$D3,$A0,$A0,$C1,$C4,$D2,$A0,$B5,$B2,$B5,$B0,$8D
    DB $EE,$0F
    ; SRS   ADR 2277<CR>
    DB $D3,$D2,$D3,$A0,$A0,$A0,$C1,$C4,$D2,$A0,$B2,$B2,$B7,$B7,$8D
    DB $FF,$0F
    ; SBTAB ADR 1035<CR>
    DB $D3,$C2,$D4,$C1,$C2,$A0,$C1,$C4,$D2,$A0,$B1,$B0,$B3,$B5,$8D
    DB $01