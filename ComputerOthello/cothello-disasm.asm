	ORG	0000H

RESET:
	DI
	JMP STARTUP

; PLUS_PIECE (WHITE)
	DB $00                         ; ----------
	DB $20                         ; ----xx----
	DB $70                         ; --xxxxxx--
	DB $20                         ; ----xx----
	DB $00                         ; ----------

; SQUARE_PIECE (BLACK)
	DB $00                         ; ----------
	DB $70                         ; --xxxxxx--
	DB $70                         ; --xxxxxx--
	DB $70                         ; --xxxxxx--
	DB $00                         ; ----------

; BLANK_SPACE
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------

; CPU_OPENING_MOVE_TABLE (COL, ROW)
	DB $03, $02
	DB $02, $03
	DB $05, $04
	DB $04, $05

; BOARD_SPACE_VALUE_TABLE
; Used by the CPU player to determine its next move
; FF 03 3C 28 28 3C 03 FF
; 03 01 0A 05 05 0A 01 03
; 3C 0A 1E 14 14 1E 0A 3C
; 28 05 14 01 01 14 05 28
; 28 05 14 01 01 14 05 28
; 3C 0A 1E 14 14 1E 0A 3C
; 03 01 0A 05 05 0A 01 03
; FF 03 3C 28 28 3C 03 FF
	DB $FF                         ; #00 (Corners) = 255
	DB $03                         ; #01 = 3
	DB $3C                         ; #02 = 60
	DB $28                         ; #03 = 40
	DB $03                         ; #04 = 3
	DB $01                         ; #05 (X-squares) = 1
	DB $0A                         ; #06 = 10
	DB $05                         ; #07 = 5
	DB $3C                         ; #08 = 60
	DB $0A                         ; #09 = 10
	DB $1E                         ; #0A = 30
	DB $14                         ; #0B = 20
	DB $28                         ; #0C = 40
	DB $05                         ; #0D = 5
	DB $14                         ; #0E = 20
	DB $01                         ; #0F (Starters) = 1

; MESSAGES

; コンピュータオセロ
; "COMPUTER OTHELLO" - Title displayed during attract sequence
	DB $05, $10, $0D, $17, $0E, $18, $09, $02, $07, $12, $8D

	DB $00, $00

; TIMER EXPIRED (RST 7 INTERRUPT)
	JMP TIMER_EXPIRED_ADD_COIN_PROMPT

; ￥100ドーゾ
; "INSERT ￥100" - Prompt displayed during attract sequence and timer expiration
	DB $13, $14, $15, $15, $0B, $16, $18, $08, $16, $8D

; セレクトドーゾ
; "SELECT GAME" - Prompt displayed after coin inserted during attract
	DB $07, $11, $04, $0B, $0B, $16, $18, $08, $16, $8D

; ハンテイドーゾ
; "PRESS JUDGE" - Prompt displayed when game is over
	DB $0C, $10, $0A, $00, $0B, $16, $18, $08, $16, $8D

; パスキードーゾ
; "PRESS PASS" - Prompt displayed when no player moves are possible
	DB $0C, $17, $06, $03, $18, $0B, $16, $18, $08, $16, $8D

; リセットドーゾ
; "PRESS RESET" - Prompt displayed after game has been scored
	DB $0F, $07, $01, $0B, $0B, $16, $18, $08, $16, $8D

; コンピュータパス
; "CPU PASSES" - Message indicating that the CPU player has had to pass
	DB $05, $10, $0D, $17, $0E, $18, $09, $0C, $17, $06, $8D

STARTUP:
; Resets stack, clears memory, draws initial board, and starts attract mode
	LXI	SP, $40FA                  ; INIT_STACK <= $40F9 (63 bytes reserved for stack)
	CALL INIT_GAME
; Sets CURRENT_PIECE to '■' and the MOVE coordinates to (3,2),
; which is the equivalent of CPU_OPENING_MOVE_TABLE(1). However, this
; doesn't get used by anything before being changed in attract mode.
	MVI	A, $05
	STA	$408A                      ; CURRENT_PIECE = '■'
	MVI	A, $03
	STA	$408B                      ; MOVE_COL = 3
	MVI	A, $02
	STA	$408C                      ; MOVE_ROW = 2
	XRA	A
	STA	$40FC                      ; GAME_SCORED_FLAG = 0
	MVI	A, $07                     ; ATTRACT_MOVE_COUNT = 7

; The coin selector logic is a bit of a black box, so the following are
; educated guesses based on code behavior. Analysis of the involved
; hardware would be needed to determine exact meanings.
; 
; States tested by the game:
; #0E -> #03 = coin drop with some kind of anti-fraud/debounce test?
; #06 = another accepted coin path, potentially used when the
;       Reset button is pressed while the timer is active?
; #05 = game in progress / coin blocker engaged?
; #0F/#07 = presumed idle state when waiting for coin

ATTRACT_MODE_LOOP:
	DI
	STA	$4088
	LDA	$A000                      ; READ_COIN_SLOT (possible values: #0E, #05, #06, #03)
	ANI	$0F
	CPI	$0E                        ; #0E:
	JZ REREAD_COIN_SLOT
	CPI	$05                        ; #05:
	JZ CONTINUE_ATTRACT
	CPI	$06                        ; #06:
	JZ COIN_INSERTED

REREAD_COIN_SLOT:
	LDA	$A000                      ; READ_COIN_SLOT
	ANI	$07
	CPI	$03                        ; #03:
	JZ COIN_INSERTED

CONTINUE_ATTRACT:
; Attract mode toggles messages between "COMPUTER OTHELLO" and "INSERT COIN."
; Every time it toggles to "INSERT COIN," the computer plays a piece.
; There is no sound. After 7 moves are played, the program resets.
	CALL CLEAR_MESSAGE
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $2B                    ; "COMPUTER OTHELLO"
	CALL LONG_DELAY                ; [1s]
	CALL LONG_DELAY                ; [1s]
	CALL CLEAR_MESSAGE
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $3B                    ; "INSERT ￥100"
	LDA	$6000                      ; READ_INPUT
	CPI	$7F                        ; Service:
	JZ SET_SERVICE_MODE_FLAGS
                                   ; Default:
; Note that this toggles the piece before it calculates any moves, so
; the side that STARTUP doesn't seed in CURRENT_PIECE will go first
; in attract mode.
	CALL TOGGLE_CURRENT_PIECE
	CALL CLEAR_MOVE_CURSORS
	CALL DRAW_GRID
	MVI	A, $01
	STA	$40FD                      ; ATTRACT_MODE_SUPPRESS_SOUND = 1
; Note how it doesn't use the MOVE coordinates that were set in STARTUP.
; It also can't use FIRST_MOVE_CPU at all, since that is strictly for '■'
; going first. Instead, it simply finds the best move every turn. For
; the first move, since all four of the possible opening moves are
; equivalent, it uses the last one scanned, which is (3,5).
	CALL CPU_FIND_AND_PLAY_BEST_MOVE
	LDA	$4088
	DCR	A                          ; if --ATTRACT_MOVE_COUNT != 0,
	JNZ ATTRACT_MODE_LOOP
                                   ; else
	JMP RESET

SET_SERVICE_MODE_FLAGS:
; If Service B is enabled, set CPU_OPENING_MOVE_TABLE_INDEX = 4,
; GAME_MODE = Service, and reenable sound. In this mode, both sides
; are controlled by the CPU and all input prompts are disabled.
	MVI	B, $04                     ; B = 4
	XRA	A
	STA	$40FD                      ; ATTRACT_MODE_SUPPRESS_SOUND = 0
	MVI	A, $7F                     ; A = #7F
	JMP FIRST_MOVE_CPU

COIN_INSERTED:
; Reset attract mode state, reenable sound, and prompt for game
; type selection. Each time through the prompt loop changes what
; the CPU's first move will be if 1P Gote is selected.
	LXI	SP, $40FA                  ; INIT_STACK <= $40F9
	CALL INIT_GAME
	XRA	A
	STA	$40FD                      ; ATTRACT_MODE_SUPPRESS_SOUND = 0

RESET_PSEUDORANDOM_OPENING_MOVE:
	DI
	MVI	B, $04                     ; PSEUDORANDOM_OPENING_MOVE = 4

PROMPT_SELECT_GAME:
	DI
	PUSH B                         ; save PSEUDORANDOM_OPENING_MOVE
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $45                    ; "SELECT GAME"
	POP B                          ; restore PSEUDORANDOM_OPENING_MOVE
	EI
	LDA	$6000                      ; READ_INPUT
; By the rules of Othello, black ('■') always moves first, but that is
; not the case here. 1P is always white ('+') and 2P (or the CPU) is
; always black ('■'). Sente and Gote are terms borrowed from Go. Here
; they indicate which side moves first.
	CPI	$FE                        ; 1P Sente:
	JZ FIRST_MOVE_WHITE
	CPI	$FD                        ; 1P Gote:
	JZ FIRST_MOVE_CPU
	CPI	$FB                        ; 2P Sente:
	JZ FIRST_MOVE_WHITE
	CPI	$F7                        ; 2P Gote:
	JZ FIRST_MOVE_BLACK
                                   ; Default:
	DCR	B                          ; if --PSEUDORANDOM_OPENING_MOVE != 0,
	JNZ PROMPT_SELECT_GAME
                                   ; else
	JMP RESET_PSEUDORANDOM_OPENING_MOVE

; Instead of having a distinct turn indicator value, when playing a 2P
; game the GAME_MODE is toggled back and forth between #FB and #F7.
; This gets used to determine which player's inputs to read, where to
; display the on-screen turn indicator, etc.

FIRST_MOVE_WHITE:
	DI
	STA	$40FF                      ; GAME_MODE = 1P Sente/2P Sente
	MVI	A, $03                     ; CURRENT_PIECE = '+'

FIRST_MOVE_COMMON:
	STA	$408A
	CALL WAIT_FOR_INPUT_RELEASE
	JMP PLAYER_TURN_CORE

FIRST_MOVE_BLACK:
	DI
	STA	$40FF                      ; GAME_MODE = 2P Gote
	MVI	A, $05                     ; CURRENT_PIECE = '■'
	JMP FIRST_MOVE_COMMON

FIRST_MOVE_CPU:
; Input:
;   A = GAME_MODE
;     Service or 1P Gote
;   B = CPU_OPENING_MOVE_INDEX (1..4)
;     is always 4 when GAME_MODE = Service
;
; INIT_GAME is always called here. This is required for the Service
; path because execution reaches this code directly from attract mode.
; For 1P Gote, however, the board was already initialized by
; COIN_INSERTED, making this second INIT_GAME call redundant.
	DI
	STA	$40FF                      ; GAME_MODE = A
	MOV A,B
	STA	$40FE                      ; CPU_OPENING_MOVE_INDEX = B
	LXI	SP, $40FA                  ; INIT_STACK <= $40F9
	CALL INIT_GAME
	MVI	A, $05
	STA	$408A                      ; CURRENT_PIECE = '■'
	CALL PERFORM_CPU_OPENING_MOVE
	JMP EXIT_CPU_TURN

CPU_TURN:
	DI
	CALL CLEAR_MESSAGE
	LDA	$4089
; If both players passed on their previous turns, then neither
; side has a legal move and the game is over.
	CPI	$02                        ; if CONSECUTIVE_PASS_COUNTER == 2,
	JZ PROMPT_FOR_JUDGE_WITH_SERVICE_CHECK
                                   ; else
	CALL TOGGLE_CURRENT_PIECE
	CALL CLEAR_MOVE_CURSORS
	CALL DRAW_TURN_INDICATOR
	CALL CPU_FIND_AND_PLAY_BEST_MOVE

EXIT_CPU_TURN:
	LDA	$40FF
	CPI	$7F                        ; if GAME_MODE == Service,
	JZ CPU_TURN
                                   ; else
PLAYER_TURN:
	DI
	LDA	$4089
; If both players passed on their previous turns, then neither
; side has a legal move and the game is over.
	CPI	$02                        ; if CONSECUTIVE_PASS_COUNTER == 2,
	JZ CLEAR_AND_PROMPT_FOR_JUDGE
                                   ; else
	CALL TOGGLE_CURRENT_PIECE

PLAYER_TURN_CORE:
	CALL CLEAR_MOVE_CURSORS
	CALL CLEAR_MESSAGE
	CALL DRAW_TURN_INDICATOR
	CALL PLAYER_INPUT_LOOP
	DB $01, $BD                    ; JUMP_ADDRESS = CLEAR_AND_PROMPT_FOR_JUDGE
	LDA	$40FF
	CPI	$FB                        ; if GAME_MODE == 2P Sente,
	JZ TOGGLE_2P_GAME_MODE
	CPI	$F7                        ; else if GAME_MODE == 2P Gote,
	JZ TOGGLE_2P_GAME_MODE
                                   ; else
	JMP CPU_TURN

TOGGLE_2P_GAME_MODE:
; Input:
;   A = GAME_MODE
;     2P Sente or 2P Gote
	CMA
	ADI	$F3
	STA	$40FF                      ; GAME_MODE = 2P Sente (#FB) <-> 2P Gote (#F7)
	JMP PLAYER_TURN

PROMPT_FOR_JUDGE_WITH_SERVICE_CHECK:
; In Service mode, automatically score the game. Otherwise
; make 1P press the Judge button.
	LDA	$40FF
	CPI	$7F                        ; if GAME_MODE = Service,
	JZ JUDGE_PRESSED_FINAL
                                   ; else
CLEAR_AND_PROMPT_FOR_JUDGE:
	CALL CLEAR_MOVE_CURSORS
	CALL CLEAR_MESSAGE

PROMPT_FOR_JUDGE:
	EI
	LDA	$6000                      ; READ_INPUT
	CPI	$BF                        ; Judge:
	JZ JUDGE_PRESSED_FINAL
                                   ; Default:
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $4F                    ; "PRESS JUDGE"
	JMP PROMPT_FOR_JUDGE

JUDGE_PRESSED_FINAL:
	DI
	CALL CLEAR_MESSAGE
	CALL CLEAR_MOVE_CURSORS
	CALL SCORE_GAME
	CALL VERY_LONG_DELAY           ; [6s]
; In Service mode, automatically reset after scoring.
; Otherwise make 1P press the Reset button.
	LDA	$40FF
	CPI	$7F                        ; if GAME_MODE = Service,
	JZ RESET
                                   ; else
PROMPT_FOR_RESET:
	EI
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $64                    ; "PRESS RESET"
	LDA	$6000                      ; READ_INPUT
	CPI	$DF                        ; Reset:
	JZ RESET
                                   ; Default:
	JMP PROMPT_FOR_RESET

PLAYER_INPUT_LOOP:
; Handles player input during a human player's turn. The Pass and
; Set buttons end the turn when their use is permitted. The Judge
; and Reset buttons end the game immediately. The Arrow buttons
; update the location of the move cursors.
	DI
	XRA	A
	STA	$408B                      ; MOVE_COL = 0
	XRA	A
	STA	$408C                      ; MOVE_ROW = 0
	XRA	A
	STA	$4098                      ; PASS_REQUIRED_FLAG = 0
	CALL DRAW_MOVE_CURSORS
	CALL DRAW_GRID
	CALL CHECK_IF_PLAYER_MUST_PASS
; If the player doesn't have any legal moves, then prompt them to
; press the Pass button. Unlike most prompts in the game, this
; doesn't suspend normal input handling. The player can still press
; any button and they will function normally, but since there are
; no legal moves they will be unable to set a piece anywhere.
	MOV A,B
	CPI	$00                        ; if PLAYER_MUST_PASS != 0,
	JNZ PASS_BUTTON_PROMPT
                                   ; else
PLAYER_INPUT_LOOP_CORE:
	DI
	LDA	$4098
	CPI	$01                        ; if PASS_REQUIRED_FLAG == 1,
	JZ PASS_BUTTON_PROMPT
                                   ; else
PLAYER_INPUT_LOOP_SKIP_PASS_PROMPT:
	CALL CLEAR_MESSAGE
	EI
	LDA	$6000                      ; READ_INPUT
; Both players' Pass buttons are mapped to the same value. There's
; no need to differentiate them because the Pass button only has an
; effect when there are no legal moves for the active player.
	CPI	$FB                        ; Pass:
	JZ PASS_PRESSED
; Both players' Arrow buttons are mapped to the same values. The controls
; are mirrored on opposite sides of the screen, so 'Right' for P1 and
; 'Left' for P2 both move the horizontal cursor in the same direction.
	CPI	$FD                        ; Right/Left Arrow:
	JZ P1_RIGHT_P2_LEFT_PRESSED
; Likewise, 'Down' for P1 and 'Up' for P2 both move the vertical
; cursor in the same direction.
	CPI	$FE                        ; Up/Down Arrow:
	JZ P1_DOWN_P2_UP_PRESSED
                                   ; Default:
; The Judge button is skipped if GAME_SCORED_FLAG is set. This is
; meaningless in practice, since control never returns to the player
; input loop after SCORE_GAME has begun.
	LDA	$40FC
	CPI	$01                        ; if GAME_SCORED_FLAG != 1,
	JZ CHECK_FOR_RESET
                                   ; else
; The Judge and Reset buttons are immediate game-ending actions.
; There is no confirmation prompt.
	LDA	$6000                      ; READ_INPUT
	CPI	$BF                        ; Judge:
	JZ JUDGE_PRESSED
                                   ; Default:
CHECK_FOR_RESET:
	LDA	$6000                      ; READ_INPUT
	CPI	$DF                        ; Reset:
	JZ RESET
                                   ; Default:
; Unlike the Pass and Arrow buttons, the Set buttons are treated as
; distinct inputs. The current value of GAME_MODE determines which
; player's Set button is accepted. Both inputs ultimately lead to
; the SET_PRESSED function.
	LDA	$40FF
	CPI	$FB                        ; if GAME_MODE == 2P Sente,
	JZ CHECK_P1_SET_PRESSED
	CPI	$F7                        ; else if GAME_MODE != 2P Gote,
	JNZ CHECK_P1_SET_PRESSED
                                   ; else
	LDA	$6000                      ; READ_INPUT
	CPI	$F7                        ; P2_Set:
	JZ SET_PRESSED
                                   ; Default:
	JMP PLAYER_INPUT_LOOP_CORE

PASS_BUTTON_PROMPT:
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $59                    ; "PRESS PASS"
	CALL SHORT_DELAY               ; [0.37s]
	MVI	A, $01
	STA	$4098                      ; PASS_REQUIRED_FLAG = 1
	JMP PLAYER_INPUT_LOOP_SKIP_PASS_PROMPT

PASS_PRESSED:
	DI
	CALL WAIT_FOR_INPUT_RELEASE
; Run CHECK_IF_PLAYER_MUST_PASS again, even though checking PASS_REQUIRED_FLAG
; should probably suffice. Restart the player's turn if passing is not allowed,
; otherwise update the pass counter and end the player's turn.
	CALL CHECK_IF_PLAYER_MUST_PASS
	MOV A,B
	CPI	$00                        ; if PLAYER_MUST_PASS == 0,
	JZ PLAYER_INPUT_LOOP
                                   ; else
	LXI	H, $4089
	INR	M                          ; CONSECUTIVE_PASS_COUNTER++

EXIT_INPUT_LOOP:
; Ends the player's current turn. The caller placed a 2-byte inline
; Judge target after the CALL, so normal exits must skip over it.
	XTHL                           ; save HL / pop RETURN_ADDRESS
	INX	H                          ; RETURN_ADDRESS++
	INX	H                          ; RETURN_ADDRESS++
	XTHL                           ; push RETURN_ADDRESS / restore HL
	RET                            ; return to RETURN_ADDRESS

JUDGE_PRESSED:
; Replace PLAYER_INPUT_LOOP's return address with the inline Judge
; target. Judge is handled outside PLAYER_INPUT_LOOP because it can
; also be invoked from non-input contexts. When called here,
; CLEAR_AND_PROMPT_FOR_JUDGE will not prompt because the Judge
; button has already been pressed and inputs are not cleared, so
; execution falls through to JUDGE_PRESSED_FINAL.
;
; Jumping directly to JUDGE_PRESSED_FINAL instead would appear to
; produce the same behavior.
	DI
	XTHL                           ; save HL / pop RETURN_ADDRESS
	MOV D,M                        ; D = JUMP_ADDRESS_HI
	INX	H                          ; RETURN_ADDRESS++
	MOV E,M                        ; E = JUMP_ADDRESS_LO
	XCHG                           ; HL = JUMP_ADDRESS
	XTHL                           ; push JUMP_ADDRESS / restore HL
	RET                            ; return to JUMP_ADDRESS (CLEAR_AND_PROMPT_FOR_JUDGE)

CHECK_P1_SET_PRESSED:
	LDA	$6000                      ; READ_INPUT
	CPI	$EF                        ; P1 Set:
	JZ SET_PRESSED
                                   ; Default:
	JMP PLAYER_INPUT_LOOP_CORE

SET_PRESSED:
	DI
; Restart the player's turn if the attempted move is illegal, otherwise
; apply the move and end the player's turn.
	CALL CHECK_IF_MOVE_IS_LEGAL
	MOV A,B
	CPI	$00                        ; if MOVE_LEGAL == 0,
	JZ PLAYER_INPUT_LOOP
                                   ; else
	CALL PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES
	CALL WAIT_FOR_INPUT_RELEASE
	JMP EXIT_INPUT_LOOP

; The move cursors each only move in one direction and wrap around
; at the board edge.

P1_RIGHT_P2_LEFT_PRESSED:
	DI
	LDA	$408B                      ; A = MOVE_COL
	INR	A                          ; A++
	CPI	$08                        ; if A != 8,
	JNZ UPDATE_MOVE_COL
                                   ; else
	XRA	A                          ; A = 0

UPDATE_MOVE_COL:
	STA	$408B                      ; MOVE_COL = A

UPDATE_MOVE_CURSOR:
	CALL HIGH_TONE_AND_DRAW_MOVE_CURSORS
	CALL WAIT_FOR_INPUT_RELEASE
	JMP PLAYER_INPUT_LOOP_CORE

P1_DOWN_P2_UP_PRESSED:
	DI
	LDA	$408C                      ; A = MOVE_ROW
	INR	A                          ; A++
	CPI	$08                        ; if A != 8,
	JNZ UPDATE_MOVE_ROW
                                   ; else
	XRA	A                          ; A = 0

UPDATE_MOVE_ROW:
	STA	$408C                      ; MOVE_ROW = A
	JMP UPDATE_MOVE_CURSOR

TIMER_EXPIRED_ADD_COIN_PROMPT:
	DI
	PUSH PSW                       ; save everything
	PUSH H
	PUSH D
	PUSH B

WAIT_05_COIN_CLEAR:
; Waits for coin slot state #05 to clear before proceeding.
; Based on code behavior, this may indicate that a game is active
; and/or that the coin blocker is engaged.
	LDA	$A000                      ; READ_COIN_SLOT (possible values: #0E, #05, #06, #03)
	ANI	$07
	CPI	$05                        ; #05:
	JZ WAIT_05_COIN_CLEAR
                                   ; else
	MVI	C, $82                     ; CONTINUE_LOOP_COUNTER = 130

CHECK_FOR_CONTINUE_LOOP:
; Flash the 'INSERT ￥100' message and check the coin slot
; for roughly one minute before resetting.
;
; Coin slot states #06, #03, and #05 are all treated as valid
; continue states. Their exact hardware meaning is unknown.
	CALL CHECK_COIN_SLOT_FOR_CONTINUE_COIN
	DCR	B                          ; if --ESCAPE_FLAG < 0,
	JM ESCAPE

	DCR	C                          ; if --CONTINUE_LOOP_COUNTER != 0,
	JNZ CHECK_FOR_CONTINUE_LOOP
                                   ; else
	LDA	$A000                      ; READ_COIN_SLOT
	ANI	$07
	CPI	$05                        ; #05:
	JZ ESCAPE
                                   ; Default:
	JMP RESET

CHECK_COIN_SLOT_FOR_CONTINUE_COIN:
	MVI	B, $01                     ; ESCAPE_FLAG = 1
	LDA	$A000                      ; READ_COIN_SLOT
	ANI	$07
	CPI	$06                        ; #06:
	JZ SET_ESCAPE
	CPI	$03                        ; #03:
	JZ SET_ESCAPE
	CPI	$05                        ; #05:
	JZ SET_ESCAPE
; The Judge button is still functional during the continue
; screen unless GAME_SCORED_FLAG is set. This occurs when
; the game has already ended and SCORE_GAME has started
; when the timer expires. Since interrupts are disabled while
; scoring, the game is always fully scored before entering the
; continue loop.
;
; If a new coin is inserted in this state, the only remaining
; action is to prompt the player to push the Reset button.
;
; Note: Once scoring has completed, entering the continue loop
; serves little practical purpose. The program could instead
; reset immediately.
	LDA	$40FC
	CPI	$01                        ; if GAME_SCORED_FLAG == 1,
	JZ COIN_PROMPT
                                   ; else
	LDA	$6000                      ; READ_INPUT
	CPI	$BF                        ; Judge:
	JZ JUDGE_PRESSED_AT_CONTINUE
                                   ; Default:
COIN_PROMPT:
	PUSH B                         ; save ESCAPE_FLAG
	CALL DRAW_MESSAGE
	DB $01                         ; unused arg
	DB $00, $3B                    ; "INSERT ￥100"
	CALL SHORT_DELAY               ; [0.37s]
	CALL CLEAR_MESSAGE
	CALL CORE_DELAY                ; [30ms]
	POP B                          ; restore ESCAPE_FLAG
	RET                            ; RETURN

SET_ESCAPE:
	DCR	B                          ; ESCAPE_FLAG = 0
	RET                            ; RETURN

JUDGE_PRESSED_AT_CONTINUE:
	CALL CLEAR_MOVE_CURSORS
	CALL CLEAR_MESSAGE
	CALL SCORE_GAME
	CALL VERY_LONG_DELAY           ; [6s]
	JMP RESET

ESCAPE:
	POP B                          ; restore everything
	POP D
	POP H
	POP PSW
	EI
	RET                            ; RETURN

VERY_LONG_DELAY:
; 6 second delay used before resetting the game after generating the scores
	PUSH B                         ; save BC
	MVI	B, $C8                     ; DELAY_LOOP_COUNTER = 200
	JMP DELAY_LOOP

LONG_DELAY:
; 1 second delay used twice in succession after the CPU passes and to cycle
; messages during attract mode.
;
; Note: LONG_DELAY is always called twice consecutively. A dedicated
; 2-second delay routine would have reduced code size slightly.
; 742,487 cycles
	PUSH B                         ; save BC
	MVI	B, $1E                     ; DELAY_LOOP_COUNTER = 30
	JMP DELAY_LOOP

SHORT_DELAY:
; 0.37 second delay used to flash the 'PRESS PASS' and continue messages
; 278,417 cycles
	PUSH B                         ; save BC
	MVI	B, $0A                     ; DELAY_LOOP_COUNTER = 10

DELAY_LOOP:
	CALL CORE_DELAY
	DCR	B                          ; if --DELAY_LOOP_COUNTER != 0,
	JNZ DELAY_LOOP
	POP B                          ; restore BC

DOUBLE_DELAY:
; 60 ms delay used as the spacing between tones in the victory jingle.
	CALL CORE_DELAY

CORE_DELAY:
; 23,171 cycles
; 30 ms delay that serves as the basis for all longer delays. Also used directly
; to flash the board after a move is made and when adding
; pieces to the board during SCORE_GAME.
	PUSH H                         ; save HL
	LXI	H, $0600                   ; OUTER_LOOP_COUNTER = 6, INNER_LOOP_COUNTER = 256/0

INNER_LOOP:
	DCR	L                          ; if --INNER_LOOP_COUNTER != 0,
	JNZ INNER_LOOP
                                   ; else
	DCR	H                          ; if --OUTER_LOOP_COUNTER != 0,
	JNZ INNER_LOOP
                                   ; else
	POP H                          ; restore HL
	RET                            ; RETURN

CPU_FIND_AND_PLAY_BEST_MOVE:
; Creates a MOVE_ASSESSMENT (a packed 16-byte representation
; of the board's contents) of the current board status. On the
; first pass, it marks the X-squares as illegal moves, so they
; won't be considered during move evaluation. Each legal move
; is attempted on the ANALYSIS_BOARD and the resulting position
; is scored using the BOARD_SPACE_VALUE_TABLE. The move that
; leads to the best score is the one that is selected.
;
; If no legal moves are found on the first pass, a second pass
; is performed, this time with the X-squares under consideration.
	MVI	A, $01                     ; AI_FIRST_PASS_FLAG = 1

CPU_FIND_AND_PLAY_BEST_MOVE_CORE:
	STA	$4086
	XRA	A
	STA	$408B                      ; MOVE_COL = 0
	XRA	A
	STA	$408C                      ; MOVE_ROW = 0
	LXI	H, $8000
	SHLD $408D                     ; BEST_MOVE_EVAL_SCORE = -32,768
	MVI	A, $01
	STA	$408F                      ; CPU_PERSPECTIVE_FLAG? = 1 (unused)
	CALL CREATE_DISPLAY_BOARD_MOVE_ASSESSMENT
	LDA	$4086
	CPI	$01                        ; if AI_FIRST_PASS_FLAG != 1,
	JNZ FIND_MOVE
	                               ; else
	CALL FIRST_PASS_REMOVE_HIGH_RISK_SQUARES

FIND_MOVE:
	XRA	A
	STA	$4090                      ; UNUSED? = 0
	LXI	D, $0000                   ; ROW_D, COL_E = (0,0)
	CALL FIND_NEXT_CANDIDATE_MOVE_FROM_ROW_COL
	MOV A,B
	CPI	$01                        ; if NO_CANDIDATE_MOVE == 1,
	JZ NO_LEGAL_MOVES
                                   ; else
	CALL TRY_CANDIDATE_MOVE_ON_ANALYSIS_BOARD
; Builds an opponent-perspective move map for the first candidate
; on each pass, but it does not appear to be used in move
; evaluation. This code is not repeated for the second and
; subsequent candidates.
	MVI	A, $02
	STA	$408F                      ; CPU_PERSPECTIVE_FLAG? = 2 (unused)
	CALL TOGGLE_CURRENT_PIECE
	CALL CREATE_ANALYSIS_BOARD_MOVE_ASSESSMENT
	MVI	A, $01
	STA	$408F                      ; CPU_PERSPECTIVE_FLAG? = 1 (unused)
	CALL TOGGLE_CURRENT_PIECE

EVALUATE_CANDIDATE_AND_CONTINUE_MOVE_SEARCH:
	CALL GENERATE_CANDIDATE_MOVE_EVAL_SCORE
	CALL UPDATE_BEST_MOVE_EVAL_SCORE_IF_BETTER
	CALL GET_CANDIDATE_MOVE
	INR	E                          ; COL_E++
	MOV A,E
	CPI	$08                        ; if COL_E != 8,
	JNZ CONTINUE_MOVE_SEARCH
                                   ; else
	MVI	E, $00                     ; COL_E = 0
	INR	D                          ; ROW_D++
	MOV A,D
	CPI	$08                        ; if ROW_D != 8,
	JNZ CONTINUE_MOVE_SEARCH
                                   ; else
	JMP PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES

CONTINUE_MOVE_SEARCH:
	CALL FIND_NEXT_CANDIDATE_MOVE_FROM_ROW_COL
	MOV A,B
	CPI	$01                        ; if NO_CANDIDATE_MOVE == 1,
	JZ PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES
                                   ; else
	CALL TRY_CANDIDATE_MOVE_ON_ANALYSIS_BOARD
	JMP EVALUATE_CANDIDATE_AND_CONTINUE_MOVE_SEARCH

NO_LEGAL_MOVES:
	LDA	$4086
	CPI	$01                        ; if AI_FIRST_PASS_FLAG != 1,
	JNZ STILL_NO_LEGAL_MOVES
                                   ; else
	DCR	A                          ; AI_FIRST_PASS_FLAG = 0
	JMP CPU_FIND_AND_PLAY_BEST_MOVE_CORE

PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES:
; A move (MOVE_COL, MOVE_ROW) has been previously selected by
; either the player or the CPU. This adds it to the ANALYSIS_BOARD.
;
; The new piece is flashed on the screen 3 times, followed by the
; newly outflanked pieces flashing 3 times. The DISPLAY_BOARD is
; then updated with all of the changes.
	XRA	A
	STA	$4089                      ; CONSECUTIVE_PASS_COUNTER = 0
	CALL DRAW_GRID
	CALL COPY_DISPLAY_BOARD_TO_ANALYSIS_BOARD

	LDA	$408C
	MOV H,A                        ; H = MOVE_ROW
	LDA	$408B
	MOV L,A                        ; L = MOVE_COL
	PUSH H                         ; save MOVE_ROW/COL
	CALL GET_SPACE_ON_ANALYSIS_BOARD

	LDA	$408A
	MOV M,A                        ; ANALYSIS_BOARD (H,L) = CURRENT_PIECE
	CALL FLASH_BOARD_CHANGE
	POP H                          ; restore MOVE_ROW/COL
	MVI	A, $01
	STA	$4084                      ; BOARD_SELECTION_FOR_SCAN = 1 (ANALYSIS)
	CALL SCAN_AND_FLIP_OUTFLANKED_PIECES
	CALL FLASH_BOARD_CHANGE
	CALL COPY_ANALYSIS_BOARD_TO_DISPLAY_BOARD
	RET                            ; RETURN

STILL_NO_LEGAL_MOVES:
; If no legal moves are found on either pass, record a pass,
; display the 'CPU PASSES' message, and advance to the other
; player's turn.
	LXI	H, $4089
	INR	M                          ; CONSECUTIVE_PASS_COUNTER++
	CALL DRAW_MESSAGE
	DB $01                         ; unused
	DB $00, $6E                    ; "CPU PASSES"
	CALL LONG_DELAY                ; [1s]
	CALL LONG_DELAY                ; [1s]
	RET                            ; RETURN

FIND_NEXT_CANDIDATE_MOVE_FROM_ROW_COL:
; Input:
;   D = ROW_D (0..7)
;   E = COL_E (0..7)
; Output:
;   B = NO_CANDIDATE_MOVE (0/1)
;     if 0,
;       set CANDIDATE_MOVE_COL, CANDIDATE_MOVE_ROW
	LXI	H, $4099                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER = (0,0)
	PUSH D                         ; save ROW_D, COL_E
	INR	D                          ; ROW_D++

; Advance the MOVE_ASSESSMENT_POINTER to (D,E) before searching
; for candidate moves.

FIND_ROW_D:
	DCR	D                          ; if --ROW_D != 0,
	JNZ ADVANCE_POINTER_1_ROW
                                   ; else
FIND_COL_E_BYTE:
	MOV B,M                        ; B = ROW_D_POINTER_BYTE
	MOV A,E
	CPI	$04                        ; if COL_E == 4,
	JZ ADVANCE_POINTER_4_COLS
                                   ; else if COL_E > 4,
	JP ADVANCE_POINTER_4_COLS
                                   ; else
	MOV A,B                        ; A = POINTER_BYTE
	INR	E                          ; COL_E++

FIND_COL_E_BITS:
	DCR	E                          ; if --COL_E != 0,
	JNZ ADVANCE_POINTER_1_COL
                                   ; else
; MOVE_ASSESSMENT_POINTER is now set to (D,E), so begin
; scanning for a legal move.
	POP D                          ; restore ROW_D, COL_E
	JMP INSPECT_SPACE

GET_POINTER_BYTE:
	POP PSW                        ; clear POINTER_BYTE from stack
	MOV A,M                        ; A = POINTER_BYTE

INSPECT_SPACE:
; Occupied spaces are set to 10/11, legal moves are 01
	RLC                            ; if SPACE == 1x,
	JC SKIP_OCCUPIED_SPACE
	RLC                            ; else if SPACE == 01,
	JC RETURN_LEGAL_SPACE
                                   ; else
ADVANCE_POINTER_TO_NEXT_SPACE:
	PUSH PSW                       ; save POINTER_BYTE
	INR	E                          ; COL_E++
	MOV A,E
	CPI	$04                        ; if COL_E == 4,
	JZ GET_NEXT_POINTER_BYTE
	CPI	$08                        ; else if COL_E != 8,
	JNZ INSPECT_NEXT_SPACE
                                   ; else
	MVI	E, $00                     ; COL_E = 0
	INR	D                          ; ROW_D++
	MOV A,D
	CPI	$08                        ; if ROW_D != 8,
	JNZ GET_NEXT_POINTER_BYTE
                                   ; else
	MVI	B, $01                     ; NO_CANDIDATE_MOVE = 1
	POP PSW                        ; clear POINTER_BYTE from stack
	RET                            ; RETURN

INSPECT_NEXT_SPACE:
	POP	PSW                        ; restore POINTER_BYTE
	JMP INSPECT_SPACE

RETURN_LEGAL_SPACE:
; Store CANDIDATE_MOVE in RAM
	LXI	H, $40A9
	MOV M,E                        ; CANDIDATE_MOVE_COL = COL_E
	INX	H
	MOV M,D                        ; CANDIDATE_MOVE_ROW = ROW_D
	MVI	B, $00                     ; NO_CANDIDATE_MOVE = 0
	RET                            ; RETURN

SKIP_OCCUPIED_SPACE:
	RLC                            ; discard low bit (POINTER_BYTE << 1)
	JMP ADVANCE_POINTER_TO_NEXT_SPACE

GET_NEXT_POINTER_BYTE:
	INX	H                          ; MOVE_ASSESSMENT_POINTER++
	JMP GET_POINTER_BYTE

ADVANCE_POINTER_1_ROW:
	INX	H
	INX	H                          ; MOVE_ASSESSEMENT_POINTER = (x++,y)
	JMP FIND_ROW_D

ADVANCE_POINTER_4_COLS:
	INX	H                          ; MOVE_ASSESSEMENT_POINTER = (x,y+4)
	DCR	E
	DCR	E
	DCR	E
	DCR	E                          ; COL_E = COL_E-4
	JMP FIND_COL_E_BYTE

ADVANCE_POINTER_1_COL:
	RLC
	RLC                            ; FOUND_POINTER_BYTE << 2
	JMP FIND_COL_E_BITS

TRY_CANDIDATE_MOVE:
	MVI	A, $01
	STA	$4084                      ; BOARD_SELECTION_FOR_SCAN = 1 (ANALYSIS)
	CALL GET_CANDIDATE_MOVE
	XCHG                           ; HL = CANDIDATE_MOVE_ROW, CANDIDATE_MOVE_COL
	CALL SCAN_AND_FLIP_OUTFLANKED_PIECES
	RET                            ; RETURN

SCAN_AND_FLIP_OUTFLANKED_PIECES:
; Input:
;   HL = MOVE_ROW, MOVE_COL
; Scan all 8 directions from the selected move on the ANALYSIS_BOARD,
; flipping all of the resulting outflanked pieces. Once all directions
; have been processed, place the new piece on the board.
	MVI	D, $01                     ; DIRECTION = 1

CONTINUE_SCAN_FOR_OUTFLANKED_PIECES:
	CALL INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
	MVI	E, $01                     ; FLIP_PIECES = 1
	CALL SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
; Upon exit, D holds the next DIRECTION to be scanned
	MOV A,D
	CPI	$09                        ; if DIRECTION != 9,
	JNZ CONTINUE_SCAN_FOR_OUTFLANKED_PIECES
                                   ; else
; Finally, actually play the piece on the board
	CALL GET_SPACE_ON_ANALYSIS_BOARD
	LDA	$408A                      ; A = CURRENT_PIECE
	MOV M,A                        ; ANALYSIS_BOARD (MOVE_ROW,MOVE_COL) = CURRENT_PIECE
	RET                            ; RETURN

GET_SPACE_ON_ANALYSIS_BOARD:
; Input:
;   H = H_ROW (0..7)
;   L = L_COL (0..7)
; Output:
;   HL = ANALYSIS_BOARD_POINTER (H,L)
	CALL GET_SPACE_ON_DISPLAY_BOARD
	MOV A,L
	ADI	$40
	MOV L,A
	MVI	A, $00
	ADC H
	MOV H,A                        ; ANALYSIS_BOARD_POINTER = DISPLAY_BOARD_POINTER + #0040
	RET                            ; RETURN

TRY_CANDIDATE_MOVE_ON_ANALYSIS_BOARD:
; Expand the MOVE_ASSESSMENT into the ANALYSIS_BOARD and apply
; the current candidate move.
	CALL POPULATE_ANALYSIS_BOARD_FROM_DISPLAY_BOARD_MOVE_ASSESSMENT
	CALL TRY_CANDIDATE_MOVE
	RET                            ; RETURN

COPY_DISPLAY_BOARD_TO_ANALYSIS_BOARD:
	LXI	H, $4000                   ; HL = DISPLAY_BOARD_POINTER
	LXI	D, $4040                   ; DE = ANALYSIS_BOARD_POINTER
	JMP COPY_BOARD_CORE

COPY_ANALYSIS_BOARD_TO_DISPLAY_BOARD:
	LXI	H, $4040                   ; HL = ANALYSIS_BOARD_POINTER
	LXI	D, $4000                   ; DE = DISPLAY_BOARD_POINTER

COPY_BOARD_CORE:
; Input:
;   HL = SOURCE_BOARD_POINTER
;   DE = TARGET_BOARD_POINTER
	MVI	B, $40                     ; COPY_SPACE_LOOP_COUNTER = 64

COPY_SPACE:
	MOV A,M
	STAX D                         ; TARGET_BOARD(POINTER) = SOURCE_BOARD(POINTER)
	INX	H                          ; SOURCE_BOARD_POINTER++
	INX	D                          ; TARGET_BOARD_POINTER++
	DCR	B                          ; if --COPY_SPACE_LOOP_COUNTER != 0
	JNZ COPY_SPACE
                                   ; else
	RET                            ; RETURN

LOAD_CANDIDATE_MOVE_EVAL_SCORE:
; Output:
;   BC = CANDIDATE_MOVE_EVAL_SCORE
	PUSH H                         ; save HL
	LXI	H, $4095
	MOV C,M
	INX	H
	MOV B,M                        ; BC = CANDIDATE_MOVE_EVAL_SCORE
	POP H                          ; restore HL
	RET                            ; RETURN

DRAW_ANALYSIS_BOARD:
	LXI	D, $4040                   ; DE = ANALYSIS_BOARD_POINTER
	JMP DRAW_BOARD_CORE

DRAW_DISPLAY_BOARD:
	LXI	D, $4000                   ; DE = DISPLAY_BOARD_POINTER

DRAW_BOARD_CORE:
	LXI	H, $CE0A                   ; HL = VRAM_POINTER(0,0) = $CE0A
	MVI	C, $08                     ; ROW_COUNTER = 8

DRAW_ROW:
	PUSH H                         ; save VRAM_POINTER (start of row)
	MVI	B, $08                     ; COL_COUNTER = 8

DRAW_SPACE:
	PUSH H                         ; save VRAM_POINTER
	LDAX D                         ; SPACE_CONTENTS = BOARD(POINTER)
	CALL DRAW_GAME_PIECE
	INX	D                          ; BOARD_POINTER++
	POP H                          ; restore VRAM_POINTER
	MOV A,L
; Advance VRAM pointer 6 pixels horizontally
; (5 for the space + 1 for the grid line)
	ADI	$06                        ; VRAM_POINTER = VRAM_POINTER + 6
	MOV L,A                        ; HL = VRAM_POINTER(x++,y)
	DCR	B                          ; if --COL_COUNTER != 0,
	JNZ DRAW_SPACE
                                   ; else
	POP H                          ; restore VRAM_POINTER (start of row)
	MOV A,H
; Advance VRAM pointer 6 pixels vertically
; (5 for the space + 1 for the grid line)
	ADI	$06                        ; VRAM_POINTER += #0600
	MOV H,A                        ; HL = VRAM_POINTER(x,y++)
	DCR	C                          ; if --ROW_COUNTER != 0,
	JNZ DRAW_ROW
                                   ; else
	RET                            ; RETURN

TOGGLE_CURRENT_PIECE:
	LDA	$408A
	CPI	$03                        ; if CURRENT_PIECE == '+',
	JZ SET_CURRENT_PIECE_BLACK
                                   ; else
	MVI	A, $03
	STA	$408A                      ; CURRENT_PIECE = '+'
	RET                            ; RETURN

SET_CURRENT_PIECE_BLACK:
	MVI	A, $05
	STA	$408A                      ; CURRENT_PIECE = '■'
	RET                            ; RETURN

CLEAR_WORK_RAM:
; Output:
;   RAM from $4000-$40EF = 0
; Preserves top of stack (so calls through INIT_GAME can return) as
; well as GAME_SCORED_FLAG, ATTRACT_MODE_SUPPRESS_SOUND,
; CPU_OPENING_MOVE_INDEX, and GAME_MODE. These values are required by
; code that executes after INIT_GAME returns, so need to be preserved.
	LXI	H, $4000                   ; RAM_POINTER = $4000
	MVI	C, $F0                     ; CLEAR_RAM_LOOP_COUNTER = 240

ZERO_OUT_RAM:
	MVI	M, $00                     ; RAM(POINTER) = 0
	INX	H                          ; RAM_POINTER++
	DCR	C                          ; if --CLEAR_RAM_LOOP_COUNTER != 0,
	JNZ ZERO_OUT_RAM
                                   ; else
	RET                            ; RETURN

CLEAR_VRAM:
; Output:
;   VRAM from $C000-$FFFF = 0
;
; Total viewable space (64 x 64):
;   $C000-$C03F
;   ...
;   $FF00-$FF3F
;
; Space is used as follows:
; MESSAGE space (8 x 64):
;   $C000-$C03F
;   ...
;   $C700-$C73F
; P2_TURN_INDICATOR (5 x 5):
;   $CA00-$CA04
;   ...
;   $CE00-$CE04
; P1_TURN_INDICATOR (5 x 5):
;   $F800-$F804
;   ...
;   $FC00-$FC04
; MOVE_CURSORS (1 x 52):
;   $CA06-$CA3A (Horizontal)
;   ...
;   $FE06 (Vertical)
; BOARD space (49 x 49):
;   $CD09-$CD39
;   ...
;   $FD09-$FD39
	LXI	B, $0001                   ; INCREMENTER = 1
	LXI	H, $C000                   ; VRAM_POINTER = $C000
	XRA	A

ZERO_OUT_VRAM:
	MOV M,A                        ; VRAM(POINTER) = 0
	DAD	B                          ; VRAM_POINTER = VRAM_POINTER + INCREMENTER
	JNC ZERO_OUT_VRAM              ; while VRAM_POINTER < $0000 (carry not set)
                                   ; else
	RET                            ; RETURN

INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION:
; Input:
;   HL = MOVE_ROW, MOVE_COL
;   D = DIRECTION
; Output:
;   B = NUM_OUTFLANKED_PIECES
;   D = DIRECTION_OUTFLANKED_PIECES (9, if no outflanked pieces found)
	XRA	A
	MOV B,A                        ; NUM_OUTFLANKED_PIECES = 0
	MOV E,A                        ; FLIP_PIECES = 0

SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION:
; Input:
;   HL = MOVE_ROW, MOVE_COL
;   B = NUM_OUTFLANKED_PIECES
;   D = DIRECTION
;   E = FLIP_PIECES (0/1)
;     if 0, scans for outflanked pieces and returns with:
;       B = NUM_OUTFLANKED_PIECES
;       D = DIRECTION_OUTFLANKED_PIECES (9, if no outflanked pieces found)
;     if 1, flips outflanked pieces and returns with:
;       B = 0
;       D = DIRECTION_OUTFLANKED_PIECES++
	PUSH H                         ; save MOVE_ROW, MOVE_COL

SCAN_FOR_OUTFLANKED_PIECES_CORE:
; If FLIP_PIECES is 0, scan the current direction for outflanked
; pieces. An empty space, board edge, or CURRENT_PIECE without
; first encountering any opponent pieces advances the scan to
; the next direction. Opponent pieces increment
; NUM_OUTFLANKED_PIECES and continue the scan in the same
; direction. If one or more opponent pieces are followed by a
; CURRENT_PIECE, then outflanked pieces have been found and the
; count and direction of the pieces are returned to the caller.
;
; If FLIP_PIECES is 1, then NUM_OUTFLANKED_PIECES is the number
; of pieces to flip in the current direction. Flip the pieces
; one by one until all of the outflanked pieces have been
; handled. Return the next direction to scan to the caller.
	MOV A,D                        ; CURR_DIRECTION = DIRECTION
	PUSH H                         ; save MOVE_ROW, MOVE_COL
	LXI	H, $0573                   ; HL = $0573, DIRECTION_TABLE(1)

FIND_DIRECTION_IN_DIRECTION_TABLE:
; Set DIRECTION_TABLE pointer to match caller's indicated direction.
	DCR	A                          ; if --CURR_DIRECTION == 0,
	JZ EXEC_DIRECTION_TABLE

	PUSH PSW                       ; save CURR_DIRECTION
	MOV A,L
	ADI	$06
	MOV L,A
	MVI	A, $00
	ADC H
	MOV H,A                        ; HL = HL + 6, DIRECTION_TABLE(++)
	POP PSW                        ; restore CURR_DIRECTION
	JMP FIND_DIRECTION_IN_DIRECTION_TABLE

EXEC_DIRECTION_TABLE:
; Each DIRECTION_TABLE entry adjusts MOVE_ROW/MOVE_COL, then
; jumps into the common scan logic.
	PCHL                           ; exec DIRECTION_TABLE(D)

; DIRECTION_TABLE(1) - UP
	POP H                          ; restore MOVE_ROW, MOVE_COL
	DCR	H                          ; MOVE_ROW--
	NOP
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(2) - UP-RIGHT
	POP H                          ; restore MOVE_ROW, MOVE_COL
	INR	L                          ; MOVE_COL++
	DCR	H                          ; MOVE_ROW--
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(3) - RIGHT
	POP H                          ; restore MOVE_ROW, MOVE_COL
	INR	L                          ; MOVE_COL++
	NOP
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(4) - DOWN-RIGHT
	POP H                          ; restore MOVE_ROW, MOVE_COL
	INR	H                          ; MOVE_ROW++
	INR	L                          ; MOVE_COL++
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(5) - DOWN
	POP H                          ; restore MOVE_ROW, MOVE_COL
	INR	H                          ; MOVE_ROW++
	NOP
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(6) - DOWN-LEFT
	POP H                          ; restore MOVE_ROW, MOVE_COL
	INR	H                          ; MOVE_ROW++
	DCR	L                          ; MOVE_COL--
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(7) - LEFT
	POP H                          ; restore MOVE_ROW, MOVE_COL
	DCR	L                          ; MOVE_COL--
	NOP
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(8) - UP-LEFT
	POP H                          ; restore MOVE_ROW, MOVE_COL
	DCR	L                          ; MOVE_COL--
	DCR	H                          ; MOVE_ROW++
	JMP SCAN_DIRECTION

; DIRECTION_TABLE(9) - RETURN
; Reached when all 8 directions have been exhausted.
	POP H                          ; clear MOVE_ROW, MOVE_COL from stack
	POP H                          ; restore MOVE_ROW, MOVE_COL
	RET                            ; RETURN

SCAN_DIRECTION:
; If board edges are found, advance the scan to the next direction.
	MOV A,H
	CPI	$FF                        ; if MOVE_ROW == -1,
	JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
	CPI	$08                        ; else if MOVE_ROW == 8,
	JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
                                   ; else
	MOV A,L
	CPI	$FF                        ; if MOVE_COL == -1,
	JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
	CPI	$08                        ; else if MOVE_COL == 8,
	JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
                                   ; else
	LDA	$408A
	MOV C,A                        ; C = CURRENT_PIECE
	PUSH H                         ; save MOVE_ROW, MOVE_COL
; Scan either the DISPLAY_BOARD or ANALYSIS_BOARD as requested by caller.
	LDA	$4084
	RAR                            ; if BOARD_SELECTION_FOR_SCAN == 1,
	JC USE_ANALYSIS_BOARD
                                   ; else
	CALL GET_SPACE_ON_DISPLAY_BOARD

EXAMINE_SPACE_CONTENTS:
	MOV A,M                        ; SPACE_CONTENTS = BOARD_POINTER (MOVE_ROW, MOVE_COL)
	POP H                          ; restore MOVE_ROW, MOVE_COL
	CPI	$00                        ; if SPACE_CONTENTS == 0 (BLANK),
	JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
	CMP C                          ; else if SPACE_CONTENTS != CURRENT_PIECE,
	JNZ HANDLE_OPPONENT_PIECE
                                   ; else
	MOV A,B
	CPI	$00                        ; if NUM_OUTFLANKED_PIECES != 0,
	JNZ OUTFLANK_COMPLETE
                                   ; else
INCREMENT_DIRECTION_AND_CONTINUE_SCAN:
	POP H                          ; restore MOVE_ROW, MOVE_COL
	INR	D                          ; DIRECTION++
	MVI	B, $00                     ; NUM_OUTFLANKED_PIECES = 0
	MOV A,D
	CPI	$09                        ; if DIRECTION != 9,
	JNZ SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
                                   ; else
	RET                            ; RETURN

USE_ANALYSIS_BOARD:
	CALL GET_SPACE_ON_ANALYSIS_BOARD
	JMP EXAMINE_SPACE_CONTENTS

OUTFLANK_COMPLETE:
; Save NUM_OUTFLANKED_PIECES to RAM, though no other code
; appears to reference this value.
	MOV A,B
	STA	$4097                      ; NUM_OUTFLANKED_PIECES? (unused) = NUM_OUTFLANKED_PIECES
	POP H                          ; restore MOVE_ROW, MOVE_COL
	RET                            ; RETURN

HANDLE_OPPONENT_PIECE:
; Flip or count piece depending on FLIP_PIECES setting.
	MOV A,E
	CPI	$01                        ; if FLIP_PIECES == 1,
	JZ FLIP_SQUARE
                                   ; else
	INR	B                          ; NUM_OUTFLANKED_PIECES++
	JMP SCAN_FOR_OUTFLANKED_PIECES_CORE

FLIP_SQUARE:
	CALL FLIP_SQUARE_ON_ANALYSIS_BOARD
	DCR	B                          ; if --NUM_OUTFLANKED_PIECES != 0,
	JNZ SCAN_FOR_OUTFLANKED_PIECES_CORE
                                   ; else
	INR	D                          ; DIRECTION++
	POP H                          ; restore MOVE_ROW, MOVE_COL
	RET                            ; RETURN

GET_CANDIDATE_MOVE:
; Output:
;   DE = CANDIDATE_MOVE_ROW, CANDIDATE_MOVE_COL
;
; Retrieve stored CANDIDATE_MOVE
	LHLD $40A9                     ; HL = stored CANDIDATE_MOVE
	XCHG                           ; DE = CANDIDATE_MOVE_ROW, CANDIDATE_MOVE_COL
	RET                            ; RETURN

UPDATE_BEST_MOVE_EVAL_SCORE_IF_BETTER:
; Input:
;   BC = CANDIDATE_MOVE_EVAL_SCORE
;
; Compare CANDIDATE_MOVE_EVAL_SCORE against the stored
; BEST_MOVE_EVAL_SCORE. Scores are signed 16-bit values.
; If the candidate score is greater than or equal to the
; current best score, update BEST_MOVE_EVAL_SCORE and update
; MOVE_COL/MOVE_ROW with the associated candidate move.
;
; Ties update the best move, so moves scanned later win.
	LXI	H, $408D
	MOV E,M
	INX	H
	MOV D,M                        ; DE = BEST_MOVE_EVAL_SCORE
	XCHG                           ; HL = BEST_MOVE_EVAL_SCORE
	MOV A,H
	RLC                            ; if BEST_MOVE_EVAL_SCORE < 0,
	JC BEST_MOVE_EVAL_SCORE_IS_NEGATIVE
                                   ; else
	MOV A,B
	RLC                            ; if CANDIDATE_MOVE_EVAL_SCORE < 0,
	RC                             ; RETURN_WITH_NO_UPDATE
                                   ; else
SCORES_HAVE_SAME_SIGN:
	MOV A,H
	CMP B                          ; if BEST_MOVE_EVAL_SCORE_HI == CANDIDATE_MOVE_EVAL_SCORE_HI,
	JZ COMPARE_SCORE_LO_BYTES
                                   ; else if BEST_MOVE_EVAL_SCORE < CANDIDATE_MOVE_EVAL_SCORE,
	JM UPDATE_BEST_MOVE_EVAL_SCORE
                                   ; else,
	RET                            ; RETURN_WITH_NO_UPDATE

BEST_MOVE_EVAL_SCORE_IS_NEGATIVE:
	MOV A,B
	RLC                            ; if CANDIDATE_MOVE_EVAL_SCORE < 0,
	JC SCORES_HAVE_SAME_SIGN
                                   ; else
	JMP UPDATE_BEST_MOVE_EVAL_SCORE

COMPARE_SCORE_LO_BYTES:
	MOV A,L
	CMP C                          ; if BEST_MOVE_EVAL_SCORE_LO == CANDIDATE_MOVE_EVAL_SCORE_LO,
	JZ UPDATE_BEST_MOVE_EVAL_SCORE
                                   ; else if BEST_MOVE_EVAL_SCORE_LO > CANDIDATE_MOVE_EVAL_SCORE_LO,
	RNC                            ; RETURN_WITH_NO_UPDATE
                                   ; else
UPDATE_BEST_MOVE_EVAL_SCORE:
	LXI	H, $408D
	MOV M,C
	INX	H
	MOV M,B                        ; BEST_MOVE_EVAL_SCORE = CANDIDATE_MOVE_EVAL_SCORE
	LDA	$40A9
	STA	$408B                      ; MOVE_COL = CANDIDATE_MOVE_COL
	LDA	$40AA
	STA	$408C                      ; MOVE_ROW = CANDIDATE_MOVE_ROW
	RET                            ; RETURN

GENERATE_CANDIDATE_MOVE_EVAL_SCORE:
; Output:
;   BC = CANDIDATE_MOVE_EVAL_SCORE
;
; Scans all of the spaces of the ANALYSIS_BOARD after a
; candidate move has been applied to it and generates a move
; evaluation score for that candidate. The move evaluation
; score uses the values from the BOARD_SPACE_VALUE_TABLE.
; Spaces occupied by the current player's pieces are added
; to the total. Spaces occupied by their opponent's pieces
; are subtracted from the total. Unoccupied spaces are not
; included.
;
; The largest possible value is 2252 (#08CC), so the score
; must be stored in a register pair rather than a single byte.
	LXI	H, $4095
	MVI	M, $00
	INX	H
	MVI	M, $00                     ; CANDIDATE_MOVE_EVAL_SCORE = 0
	LXI	H, $4040                   ; HL = ANALYSIS_BOARD_POINTER
	MVI	D, $00                     ; ROW_D = 0

START_NEXT_EVAL_ROW:
	MVI	E, $00                     ; COL_E = 0

GET_NEXT_EVAL_SPACE:
	MOV A,M                        ; CURRENT_SPACE = ANALYSIS_BOARD (ROW_D,COL_E)
	PUSH PSW                       ; save CURRENT_SPACE
	LDA	$408A
	MOV B,A                        ; B = CURRENT_PIECE
	POP PSW                        ; restore CURRENT_SPACE
	PUSH D                         ; save ROW_D
	CMP B                          ; if CURRENT_SPACE == CURRENT_PIECE,
	JZ ADD_SPACE_VALUE
	CPI	$00                        ; else if CURRENT_SPACE == 0,
	JZ NEXT_EVAL_SPACE
                                   ; else
	CALL GET_SPACE_VALUE
	CALL SUB_VALUE_FROM_MOVE_EVAL_SCORE

NEXT_EVAL_SPACE:
	POP D                          ; restore ROW_D
	INX	H                          ; ANALYSIS_BOARD_POINTER++
	INR	E                          ; COL_E++
	MOV A,E
	CPI	$08                        ; if COL_E != 8,
	JNZ GET_NEXT_EVAL_SPACE
                                   ; else
	INR	D                          ; ROW_D++
	MOV A,D
	CPI	$08                        ; if ROW_D != 8,
	JNZ START_NEXT_EVAL_ROW
                                   ; else
	LXI	H, $4095
	MOV C,M
	INX	H
	MOV B,M                        ; BC = CANDIDATE_MOVE_EVAL_SCORE
	RET                            ; RETURN

ADD_SPACE_VALUE:
	CALL GET_SPACE_VALUE
	CALL ADD_VALUE_TO_MOVE_EVAL_SCORE
	JMP NEXT_EVAL_SPACE

GET_SPACE_VALUE:
; The BOARD_SPACE_VALUE_TABLE contains only 16 entries. Due to the
; symmetry of the board, every space can be mapped into the upper-left
; 4x4 quadrant, where unique values are stored.
;
; Any ROW or COL coordinate greater than 3 is reflected about the
; board's centerline by replacing it with (7 - coordinate).
;
; The resulting 2-bit ROW and 2-bit COL values are then combined to
; form a 4-bit table index:
;
;     Index = (COL << 2) | ROW
;
; Examples:
;   (3,1) -> (11,01) -> index 1101 = D (13)
;   (5,2) -> (2,2) -> (10,10) -> index 1010 = A (10)
	PUSH H                         ; save ANALYSIS_BOARD_POINTER
	MOV B,D                        ; B = ROW_D
	CALL GET_BOARD_SPACE_VALUE_TABLE_INDEX_BITS
	MOV D,C                        ; D = BOARD_SPACE_VALUE_TABLE_INDEX_HI_BITS
	MOV B,E                        ; B = COL_E
	CALL GET_BOARD_SPACE_VALUE_TABLE_INDEX_BITS
	MOV E,C                        ; E = BOARD_SPACE_VALUE_TABLE_INDEX_LO_BITS
	MOV A,D
	RLC
	RLC
	ADD E
	MOV E,A                        ; E = BOARD_SPACE_VALUE_TABLE_INDEX = (HI_BITS << 2) + LO_BITS
	LXI	H, $001B                   ; HL = BOARD_SPACE_VALUE_TABLE(0) = $001B
	MOV A,E
	ADD L
	MOV L,A
	MVI	A, $00
	ADC H
	MOV H,A
	MOV A,M                        ; BOARD_SPACE_VALUE = BOARD_SPACE_VALUE_TABLE(E)
	POP H                          ; restore ANALYSIS_BOARD_POINTER
	RET                            ; RETURN

GET_BOARD_SPACE_VALUE_TABLE_INDEX_BITS:
; Input:
;   B = ROW_D or COL_E
; Output:
;   C = coordinate reflected in 0..3
;       0,1,2,3,3,2,1,0
	MVI	A, $03
	CMP B                          ; if ROW_D|COL_E > 3,
	JM MODIFY_INDEX_BITS
                                   ; else
	MOV C,B                        ; BITS = ROW_D|COL_E
	RET                            ; RETURN

MODIFY_INDEX_BITS:
; Reflects coordinates about the board's centerline.
	MVI	A, $07
	SUB B
	MOV C,A                        ; BITS = 7 - ROW_D|COL_E
	RET                            ; RETURN

ADD_VALUE_TO_MOVE_EVAL_SCORE:
	CALL LOAD_CANDIDATE_MOVE_EVAL_SCORE

; Because a register pair is needed to store the score, the 8-bit
; BOARD_SPACE_VALUE is added to or subtracted from MOVE_EVAL_SCORE
; by repeated increment/decrement of BC. The 8080 has 16-bit addition
; via DAD, but not a compact way to add or subtract an 8-bit value
; directly to/from a register pair.

INCREMENT_MOVE_EVAL_SCORE:
	INX	B                          ; MOVE_EVAL_SCORE++
	DCR	A                          ; if --BOARD_SPACE_VALUE != 0,
	JNZ INCREMENT_MOVE_EVAL_SCORE
                                   ; else
	CALL UPDATE_CANDIDATE_MOVE_EVAL_SCORE
	RET                            ; RETURN

UPDATE_CANDIDATE_MOVE_EVAL_SCORE:
	PUSH H                         ; save ANALYSIS_BOARD_POINTER
	LXI	H, $4095
	MOV M,C
	INX	H
	MOV M,B                        ; CANDIDATE_MOVE_EVAL_SCORE = MOVE_EVAL_SCORE
	POP H                          ; restore ANALYSIS_BOARD_POINTER
	RET                            ; RETURN

SUB_VALUE_FROM_MOVE_EVAL_SCORE:
	CALL LOAD_CANDIDATE_MOVE_EVAL_SCORE

DECREMENT_MOVE_EVAL_SCORE:
	DCX	B                          ; MOVE_EVAL_SCORE--
	DCR	A                          ; if --BOARD_SPACE_VALUE != 0,
	JNZ DECREMENT_MOVE_EVAL_SCORE
                                   ; else
	CALL UPDATE_CANDIDATE_MOVE_EVAL_SCORE
	RET                            ; RETURN

CREATE_DISPLAY_BOARD_MOVE_ASSESSMENT:
	LXI	D, $4000                   ; DE = DISPLAY_BOARD_POINTER (0,0)
	XRA	A
	STA	$4084                      ; BOARD_SELECTION_FOR_SCAN = 0 (DISPLAY)
	LXI	H, $4099                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER (0,0)
	JMP CREATE_MOVE_ASSESSMENT_CORE

CREATE_ANALYSIS_BOARD_MOVE_ASSESSMENT:
; An opponent-perspective MOVE_ASSESSMENT is generated here, but
; GENERATE_CANDIDATE_MOVE_EVAL_SCORE only uses the contents of
; ANALYSIS_BOARD directly and does not consult this MOVE_ASSESSMENT.
	LXI	D, $4040                   ; DE = ANALYSIS_BOARD_POINTER (0,0)
	MVI	A, $01
	STA	$4084                      ; BOARD_SELECTION_FOR_SCAN = 1 (ANALYSIS)
	LXI	H, $40AB                   ; HL = ANALYSIS_BOARD_MOVE_ASSESSMENT_POINTER (0,0)

CREATE_MOVE_ASSESSMENT_CORE:
; Creates a 16-byte packed representation of the board. Each byte
; holds four two-bit values representing a set of four adjacent
; spaces. Empty spaces are scanned to determine whether playing
; there would outflank opponent pieces.
;
; Possible values are:
;   0 = Empty but illegal
;   1 = Empty and legal
;   2 = Contains black piece ('■')
;   3 = Contains white piece ('+')
	SHLD $4092                     ; MOVE_ASSESSMENT_WRITE_POINTER = BOARD_MOVE_ASSESSMENT_POINTER
	MVI	C, $04                     ; ACCUMULATOR_COUNTER = 4
	LXI	H, $0000                   ; ROW_H, COL_L = (0,0)

ASSESS_SPACE:
	LDAX D
	CPI	$03                        ; if BOARD_POINTER (x,y) == '+'
	JZ ASSESSMENT_HANDLE_WHITE
	CPI	$05                        ; if BOARD_POINTER (x,y) == '■'
	JZ ASSESSMENT_HANDLE_BLACK
                                   ; else
	PUSH D                         ; save BOARD_POINTER
	MVI	D, $01                     ; DIRECTION = 1
	PUSH B                         ; save CURRENT_SPACE_ACCUMULATOR (unnecessary, uninitialized)
; Unlike when applying moves, this call does not flip pieces.
; It only checks whether the empty space would outflank pieces
; in any direction.
	CALL INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
	POP B                          ; restore CURRENT_SPACE_ACCUMULATOR
	MOV A,D
	CPI	$09                        ; if DIRECTION == 9,
	JZ ILLEGAL_SPACE
                                   ; else
	MVI	B, $01                     ; CURRENT_SPACE_ACCUMULATOR = 1
	POP D                          ; restore BOARD_POINTER

ACCUMULATOR_HANDLER:
; Pack CURRENT_SPACE_ACCUMULATOR into MOVE_ASSESSMENT_ACCUMULATOR.
; After four spaces, write the completed byte and advance
; MOVE_ASSESSMENT_WRITE_POINTER.
	PUSH H                         ; save ROW_H, COL_L
	MOV A,C
	CPI	$04                        ; if ACCUMULATOR_COUNTER != 4,
	JNZ LOAD_ACCUMULATOR
                                   ; else
	XRA	A                          ; TEMP_ACCUMULATOR = 0

ADD_CURRENT_SPACE_ACCUMULATOR:
	ADD B                          ; TEMP_ACCUMULATOR = TEMP_ACCUMULATOR + CURRENT_SPACE_ACCUMULATOR
	DCR	C                          ; if --ACCUMULATOR_COUNTER != 0,
	JNZ SHIFT_ACCUMULATOR_BITS_AND_SAVE
                                   ; else
	LHLD $4092
	MOV M,A                        ; MOVE_ASSESSMENT(WRITE_POINTER) = TEMP_ACCUMULATOR
	INX	H
	SHLD $4092                     ; MOVE_ASSESSMENT_WRITE_POINTER++
	MVI	C, $04                     ; ACCUMULATOR_COUNTER = 4

GET_NEXT_ASSESSMENT_SPACE:
	POP H                          ; restore ROW_H, COL_L
	INR	L                          ; COL_L++
	MOV A,L
	CPI	$08                        ; if COL_L == 8,
	JZ GET_NEXT_ASSESSMENT_ROW
                                   ; else
ASSESS_NEXT_SPACE:
	INX	D                          ; BOARD_POINTER++
	JMP ASSESS_SPACE

GET_NEXT_ASSESSMENT_ROW:
	MVI	L, $00                     ; COL_L = 0
	INR	H                          ; ROW_H++
	MOV A,H
	CPI	$08                        ; if ROW_H != 8,
	JNZ ASSESS_NEXT_SPACE
                                   ; else
	RET                            ; RETURN

ASSESSMENT_HANDLE_WHITE:
	MVI	B, $03                     ; CURRENT_SPACE_ACCUMULATOR = 3
	JMP ACCUMULATOR_HANDLER

ASSESSMENT_HANDLE_BLACK:
	MVI	B, $02                     ; CURRENT_SPACE_ACCUMULATOR = 2
	JMP ACCUMULATOR_HANDLER

ILLEGAL_SPACE:
	MVI	B, $00                     ; CURRENT_SPACE_ACCUMULATOR = 0
	POP D                          ; restore BOARD_POINTER
	JMP ACCUMULATOR_HANDLER

LOAD_ACCUMULATOR:
	LDA	$4094                      ; TEMP_ACCUMULATOR = MOVE_ASSESSMENT_ACCUMULATOR
	JMP ADD_CURRENT_SPACE_ACCUMULATOR

SHIFT_ACCUMULATOR_BITS_AND_SAVE:
	RLC
	RLC
	STA	$4094                      ; MOVE_ASSESSMENT_ACCUMULATOR = TEMP_ACCUMULATOR << 2
	JMP GET_NEXT_ASSESSMENT_SPACE

POPULATE_ANALYSIS_BOARD_FROM_DISPLAY_BOARD_MOVE_ASSESSMENT:
	LXI	H, $4099                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER
	MVI	D, $00                     ; ROW_D = 0

START_NEXT_ASSESSMENT_ROW:
	MVI	E, $00                     ; COL_E = 0

GET_NEXT_MOVE_ASSESSMENT_BYTE:
	MOV A,M                        ; MOVE_ASSESSMENT_BYTE = MOVE_ASSESSMENT(POINTER)

EXAMINE_MOVE_ASSESSMENT_BITS:
	RLC                            ; if MOVE_ASSESSMENT_HI_BIT = 1,
	JC SPACE_OCCUPIED
	RLC                            ; else
	MVI	B, $00                     ; SPACE_CONTENTS = 0 (BLANK)

ADD_CONTENTS_TO_ANALYSIS_BOARD:
	PUSH D                         ; save ROW_D, COL_E
	MOV C,A                        ; CURR_MOVE_ASSESSMENT_BYTE = MOVE_ASSESSMENT_BYTE << 2
	XCHG                           ; HL = ROW_D, COL_E; DE = MOVE_ASSESSMENT_POINTER
	CALL GET_SPACE_ON_ANALYSIS_BOARD
	MOV M,B                        ; ANALYSIS_BOARD (D,E) = SPACE_CONTENTS
	XCHG                           ; HL = MOVE_ASSESSMENT_POINTER
	POP D                          ; restore ROW_D, COL_E
	INR	E                          ; COL_E++
	MOV A,E
	CPI	$04                        ; if COL_E == 4,
	JZ ADVANCE_MOVE_ASSESSMENT_POINTER
	CPI	$08                        ; if COL_E != 8,
	JNZ CONTINUE_WITH_MOVE_ASSESSMENT_BYTE
                                   ; else
	INR	D                          ; ROW_D++
	INX	H                          ; MOVE_ASSESSMENT_POINTER++
	MOV A,D
	CPI	$08                        ; if ROW_D != 8,
	JNZ START_NEXT_ASSESSMENT_ROW
                                   ; else
	RET                            ; RETURN

CONTINUE_WITH_MOVE_ASSESSMENT_BYTE:
	MOV A,C                        ; MOVE_ASSESSMENT_BYTE = CURR_MOVE_ASSESSMENT_BYTE
	JMP EXAMINE_MOVE_ASSESSMENT_BITS

SPACE_OCCUPIED:
	RLC                            ; if MOVE_ASSESSMENT_LO_BIT = 1,
	JC SPACE_IS_WHITE
                                   ; else
	MVI	B, $05                     ; SPACE_CONTENTS = '■'
	JMP ADD_CONTENTS_TO_ANALYSIS_BOARD

SPACE_IS_WHITE:
	MVI	B, $03                     ; SPACE_CONTENTS = '+'
	JMP ADD_CONTENTS_TO_ANALYSIS_BOARD

ADVANCE_MOVE_ASSESSMENT_POINTER:
	INX	H                          ; MOVE_ASSESSMENT_POINTER++
	JMP GET_NEXT_MOVE_ASSESSMENT_BYTE

DRAW_GRID:
; Draws the 9 intersecting vertical and horizontal lines that
; make up the 8x8 gameboard. Each line is 49 pixels in length,
; spanning 8 5-pixel cells and the 9 perpendicular 1-pixel lines.
	MVI	C, $09                     ; NUM_LINES = 9
	LXI	H, $CD09                   ; HORI_LINE_VRAM_POINTER = $CD09
	PUSH H
	POP D                          ; VERT_LINE_VRAM_POINTER = $CD09

DRAW_NEXT_LINES:
	PUSH H                         ; save HORI_LINE_VRAM_POINTER
	PUSH D                         ; save VERT_LINE_VRAM_POINTER
	MVI	B, $31                     ; GRID_LINE_LENGTH = 49

DRAW_NEXT_PIXELS:
	MVI	A, $01                     ; PIXEL_TYPE = 1
	MOV M,A                        ; HORI_LINE_VRAM(POINTER) = PIXEL_TYPE
	STAX D                         ; VERT_LINE_VRAM(POINTER) = PIXEL_TYPE
	INR	L                          ; HORI_LINE_VRAM_POINTER++
	INR	D                          ; VERT_LINE_VRAM_POINTER += #0100
	DCR	B                          ; if --GRID_LINE_LENGTH != 0,
	JNZ DRAW_NEXT_PIXELS
                                   ; else
	POP D                          ; restore VERT_LINE_VRAM_POINTER
	POP H                          ; restore HORI_LINE_VRAM_POINTER
; Advance pointers by 6 to next lines, moving past the next 5-pixel cell.
	MOV A,H
	ADI	$06
	MOV H,A                        ; HORI_LINE_VRAM_POINTER += #0600
	MOV A,E
	ADI	$06
	MOV E,A                        ; VERT_LINE_VRAM_POINTER += #0006
	DCR	C                          ; if --NUM_LINES != 0,
	JNZ DRAW_NEXT_LINES
                                   ; else
	RET                            ; RETURN

ADD_STARTING_PIECES_TO_BOARDS_AND_DRAW:
; Initialize the ANALYSIS and DISPLAY boards to Othello's
; standard starting position, then draw the DISPLAY_BOARD.
; Pieces are written directly into the ANALYSIS_BOARD's RAM
; rather than using GET_SPACE_ON_ANALYSIS_BOARD with
; coordinates.
;
; + ■
; ■ +
	MVI	A, $03
	LXI	H, $405B
	MOV M,A                        ; ANALYSIS_BOARD(3,3) = '+'
	MVI	A, $03
	LXI	H, $4064
	MOV M,A                        ; ANALYSIS_BOARD(4,4) = '+'
	MVI	A, $05
	LXI	H, $405C
	MOV M,A                        ; ANALYSIS_BOARD(4,3) = '■'
	MVI	A, $05
	LXI	H, $4063
	MOV M,A                        ; ANALYSIS_BOARD(3,4) = '■'
	CALL COPY_ANALYSIS_BOARD_TO_DISPLAY_BOARD
	CALL DRAW_DISPLAY_BOARD
	RET                            ; RETURN

GET_SPACE_ON_DISPLAY_BOARD:
; Input:
;   H = H_ROW (0..7)
;   L = L_COL (0..7)
; Output:
;   HL = DISPLAY_BOARD_POINTER (H,L)
;
; H_ROW and L_COL are 3-bit values, so the byte offset is:
;   00rrrccc
; which exactly matches the DISPLAY_BOARD's memory map
	MOV A,H
	RLC
	RLC
	RLC                            ; A = H_ROW << 3
	ADD L
	MOV L,A                        ; OFFSET = H_ROW*8 + L_COL
	MVI	H, $40                     ; HL = $4000 + OFFSET
	RET                            ; RETURN

FLIP_SQUARE_ON_ANALYSIS_BOARD:
; Input:
;   HL = H_ROW, L_COL
;
; Set ANALYSIS_BOARD (H_ROW,L_COL) to CURRENT_PIECE. This
; routine does not toggle the existing piece. Callers are
; responsible for ensuring that the space contained an
; opponent piece.
	PUSH H                         ; save H_ROW, L_COL
	CALL GET_SPACE_ON_ANALYSIS_BOARD
	LDA	$408A
	MOV M,A                        ; ANALYSIS_BOARD (H_ROW, L_COL) = CURRENT_PIECE
	POP H                          ; restore H_ROW, L_COL
	RET                            ; RETURN

WAIT_FOR_INPUT_RELEASE:
; Loops until no pressed inputs are detected.
	LDA	$6000                      ; READ_INPUT
	CPI	$FF                        ; !No Input:
	JNZ WAIT_FOR_INPUT_RELEASE
                                   ; else
	RET                            ; RETURN

CHECK_IF_MOVE_IS_LEGAL:
	LDA	$408C
	MOV H,A                        ; H_ROW = MOVE_ROW
	LDA	$408B
	MOV L,A                        ; L_COL = MOVE_COL

CHECK_IF_SPACE_IS_LEGAL_MOVE:
; Input:
;   H = H_ROW (0..7)
;   L = L_COL (0..7)
; Output:
;   B = MOVE_LEGAL (0/1)
;
; A move is legal only if the selected DISPALY_BOARD space is empty
; and placing CURRENT_PIECE there would outflank at least one
; opponent piece.
	PUSH H                         ; save H_ROW, L_COL
	CALL GET_SPACE_ON_DISPLAY_BOARD
	MOV A,M                        ; SPACE_CONTENTS = DISPLAY_BOARD(H_ROW,L_COL)
	POP H                          ; restore H_ROW, L_COL
	CPI	$00                        ; if SPACE_CONTENTS != 0,
	JNZ INVALID_MOVE
	XRA	A
	STA	$4084                      ; BOARD_SELECTION_FOR_SCAN = 0 (DISPLAY)
	MVI	D, $01                     ; DIRECTION = 1
; Unlike when applying moves, this call does not flip pieces.
; It only checks whether the empty space would outflank pieces
; in any direction. If it would, then MOVE_LEGAL is set to 1.
	CALL INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
	MOV A,D
	CPI	$09                        ; if DIRECTION == 9,
	JZ INVALID_MOVE
                                   ; else
	MVI	B, $01                     ; MOVE_LEGAL = 1
	RET                            ; RETURN

INVALID_MOVE:
	MVI	B, $00                     ; MOVE_LEGAL = 0
	RET                            ; RETURN

CHECK_IF_PLAYER_MUST_PASS:
; Output:
;   B = PLAYER_MUST_PASS (0/1)
;
; Scans the entire board for a legal move for the current
; player. The search terminates immediately if one is found.
; If no legal move exists, PLAYER_MUST_PASS is set to 1.
	MVI	H, $07                     ; H_ROW = 7

CHECK_NEXT_ROW:
	MVI	L, $07                     ; L_COL = 7

CHECK_NEXT_SPACE:
	CALL CHECK_IF_SPACE_IS_LEGAL_MOVE
	MOV A,B
	CPI	$00                        ; if MOVE_LEGAL != 0,
	JNZ PLAYER_HAS_LEGAL_MOVE
	DCR	L                          ; if --L_COL >= 0,
	JP CHECK_NEXT_SPACE
                                   ; else
	DCR	H                          ; if --H_ROW >= 0,
	JP CHECK_NEXT_ROW
                                   ; else
	MVI	B, $01                     ; PLAYER_MUST_PASS = 1
	RET                            ; RETURN

PLAYER_HAS_LEGAL_MOVE:
	MVI	B, $00                     ; PLAYER_MUST_PASS = 0
	RET                            ; RETURN

HIGH_TONE_AND_DRAW_MOVE_CURSORS:
	CALL HIGH_TONE

DRAW_MOVE_CURSORS:
; Clear the old move cursors, then draw new 5-pixel length
; cursors matching MOVE_COL/MOVE_ROW.
;
; From 1P's perspective, the horizontal cursor is drawn
; above the board, and the vertical cursor is drawn to the
; left of the board.
	CALL CLEAR_MOVE_CURSORS
	LXI	H, $CA0A                   ; HL = VRAM_HORI_CURSOR_POINTER(0) = $CA0A
	LDA	$408C
	MOV D,A                        ; D = MOVE_ROW
	LDA	$408B
	MOV E,A                        ; E = MOVE_COL

SET_HORIZONTAL_CURSOR:
	DCR	E                          ; if --MOVE_COL < 0,
	JM DRAW_HORIZONTAL_CURSOR
                                   ; else
	MOV A,L
; Cursor moves 6 pixels at a time to skip over 5-pixel cell
; and 1-pixel line.
	ADI	$06                        ; VRAM_HORI_CURSOR_POINTER += #0006
	MOV L,A                        ; VRAM_HORI_CURSOR_POINTER(++)
	JMP SET_HORIZONTAL_CURSOR

DRAW_HORIZONTAL_CURSOR:
	LDA	$408A                      ; A = CURRENT_PIECE
	CALL DRAW_HORIZONTAL_MOVE_CURSOR

	LXI	H, $CE06                   ; HL = VRAM_VERT_CURSOR_POINTER(0) = $CE06

SET_VERTICAL_CURSOR:
	DCR	D                          ; if --MOVE_ROW < 0,
	JM DRAW_VERTICAL_CURSOR
                                   ; else
	MOV A,H
; Cursor moves 6 pixels at a time to skip over 5-pixel cell
; and 1-pixel line.
	ADI	$06                        ; VRAM_VERT_CURSOR_POINTER += #0600
	MOV H,A                        ; VRAM_VERT_CURSOR_POINTER(++)
	JMP SET_VERTICAL_CURSOR

DRAW_VERTICAL_CURSOR:
	LDA	$408A                      ; A = CURRENT_PIECE
	CALL DRAW_VERTICAL_MOVE_CURSOR
	RET                            ; RETURN

CLEAR_MOVE_CURSORS:
; Blanks out the entire 52-pixel horizontal and vertical lines
; where the move cursors are displayed.
;
; The cursor lines extend slightly beyond the 49-pixel board span.
; The extra pixels are never drawn as cursors, but clearing them
; simplifies the implementation.
	MVI	B, $34                     ; MOVE_CURSOR_LINE_LENGTH = 52
	LXI	H, $CA06                   ; VRAM_HORI_CURSOR_POINTER = $CA06
	PUSH H
	POP D                          ; VRAM_VERT_CURSOR_POINTER = $CA06

BLANK_NEXT_PIXELS:
	XRA	A                          ; PIXEL_TYPE = 0 (BLANK)
	MOV M,A                        ; VRAM_HORI_CURSOR(POINTER) = PIXEL_TYPE
	STAX D                         ; VRAM_VERT_CURSOR(POINTER) = PIXEL_TYPE
	INR	L                          ; VRAM_HORI_CURSOR_POINTER++
	INR	D                          ; VRAM_VERT_CURSOR_POINTER += #0100
	DCR	B                          ; if --MOVE_CURSOR_LINE_LENGTH != 0,
	JNZ BLANK_NEXT_PIXELS
                                   ; else
	RET                            ; RETURN

FLASH_BOARD_CHANGE:
; Alternates between the DISPLAY_BOARD (before the move) and
; ANALYSIS_BOARD (after the move) 3 times in rapid succession,
; highlighting the newly played piece or any resulting flips.
;
; If not in attract mode, LOW_TONE is emitted each time the
; ANALYSIS_BOARD is drawn.
	MVI	A, $03                     ; FLASH_LOOP_COUNTER = 3

FLASH_BOARD:
	PUSH PSW                       ; save FLASH_LOOP_COUNTER
	CALL DRAW_DISPLAY_BOARD
	CALL CORE_DELAY                ; [30ms]
	LDA	$40FD
	CPI	$01                        ; if ATTRACT_MODE_SUPPRESS_SOUND == 0,
	JZ SWAP_BOARD
                                   ; else
	CALL LOW_TONE

SWAP_BOARD:
	CALL DRAW_ANALYSIS_BOARD
	CALL CORE_DELAY                ; [30ms]
	POP PSW                        ; restore FLASH_LOOP_COUNTER
	DCR	A                          ; if --FLASH_LOOP_COUNTER != 0,
	JNZ FLASH_BOARD
                                   ; else
	RET                            ; RETURN

FIRST_PASS_REMOVE_HIGH_RISK_SQUARES:
; X-squares are the diagonally corner-adjacent squares:
;   (1,1), (1,6), (6,1), (6,6)
; Othello strategy classifies these as high risk positions to avoid
; because they often allow an opponent to capture a corner.
;
; Zeroes the four X-squares in the MOVE_ASSESSMENT, marking them as
; illegal moves. This prevents the CPU from considering them as
; moves on the first pass.
;
; But this also causes those squares to appear empty when the
; ANALYSIS_BOARD is reconstructed from the MOVE_ASSESSMENT. As a
; result, first-pass evaluation can miss otherwise-legal corner
; captures or other outflanked pieces that depend on actual occupancy
; of an X-square. A better implementation would somehow only mark
; these spaces as illegal if they didn't already contain pieces.
	MVI	B, $02                     ; ROW_LOOP_COUNTER = 2
	LXI	H, $409B                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER(1,0) = $409B

REMOVE_HIGH_RISK_FROM_ROW:
	MOV A,M
	ANI	$CF
	MOV M,A                        ; DISPLAY_BOARD_MOVE_ASSESSMENT(x,1) = 0
	INX	H                          ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER++
	MOV A,M
	ANI	$F3
	MOV M,A                        ; DISPLAY_BOARD_MOVE_ASSESSMENT(x,6) = 0
	LXI	H, $40A5                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER(6,0) = $40A5
	DCR	B                          ; if --ROW_LOOP_COUNTER != 0,
	JNZ REMOVE_HIGH_RISK_FROM_ROW
                                   ; else
	RET                            ; RETURN

DRAW_HORIZONTAL_MOVE_CURSOR:
; Input:
;   HL = VRAM_HORI_CURSOR_POINTER
;   A = CURRENT_PIECE
	MVI	B, $05                     ; MOVE_CURSOR_LENGTH = 5

DRAW_NEXT_HORI_PIXEL:
	MOV M,A                        ; VRAM_HORI_CURSOR(POINTER) = CURRENT_PIECE
	INR	L                          ; VRAM_HORI_CURSOR_POINTER++
	DCR	B                          ; if --MOVE_CURSOR_LENGTH != 0,
	JNZ DRAW_NEXT_HORI_PIXEL
                                   ; else
	RET                            ; RETURN

DRAW_VERTICAL_MOVE_CURSOR:
; Input:
;   HL = VRAM_VERT_CURSOR_POINTER
;   A = CURRENT_PIECE
	MVI	B, $05                     ; MOVE_CURSOR_LENGTH = 5

DRAW_NEXT_VERT_PIXEL:
	MOV M,A                        ; VRAM_VERT_CURSOR(POINTER) = CURRENT_PIECE
	INR	H                          ; VRAM_VERT_CURSOR_POINTER += #0100
	DCR	B                          ; if --MOVE_CURSOR_LENGTH != 0,
	JNZ DRAW_NEXT_VERT_PIXEL
                                   ; else
	RET                            ; RETURN

PERFORM_CPU_OPENING_MOVE:
; Look up the coordinates of the selected CPU_OPENING_MOVE
; from the four-entry table and play it. All of the opening
; moves would be equivalent if using the normal MOVE_ASSESSMENT
; approach, so CPU_FIND_AND_PLAY_BEST_MOVE would just result in
; the same move always being selected.
;
; Instead, the PROMPT_SELECT_GAME loop supplies a pseudo-random
; index into the table, and the selected opening move is played
; without checking its legality.
	LDA	$40FE                      ; A = CPU_OPENING_MOVE_INDEX
	LXI	H, $0013                   ; HL = CPU_OPENING_MOVE_TABLE(0)

GET_CPU_OPENING_MOVE:
	DCR	A                          ; if --CPU_OPENING_MOVE_INDEX == 0,
	JZ PLAY_OPENING_MOVE
                                   ; else
	INX	H
	INX	H                          ; CPU_OPENING_MOVE_TABLE(++)
	JMP GET_CPU_OPENING_MOVE

PLAY_OPENING_MOVE:
	MOV A,M
	STA	$408B                      ; MOVE_COL = CPU_OPENING_MOVE_TABLE().COL
	INX	H
	MOV A,M
	STA	$408C                      ; MOVE_ROW = CPU_OPENING_MOVE_TABLE().ROW
	CALL PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES
	RET                            ; RETURN

INIT_GAME:
; Reset game state, clear the screen, draw the board, and
; place the starting pieces so a new game can begin.
	CALL CLEAR_WORK_RAM
	CALL CLEAR_VRAM
	CALL DRAW_GRID
	CALL ADD_STARTING_PIECES_TO_BOARDS_AND_DRAW
	RET                            ; RETURN

VERY_LOW_TONE:
; ~583 Hz tone used as pieces are counted during the SCORE_GAME
; routine and as part of the victory jingle.
	MVI	B, $85                     ; TONE_COMMAND = #85, FREQUENCY_DIVISOR = low bits (5)
	JMP PLAY_TONE

LOW_TONE:
; ~700 Hz tone used every time the board flashes when a move is
; made and as part of the victory jingle.
	MVI	B, $84                     ; TONE_COMMAND = #84, FREQUENCY_DIVISOR = low bits (4)
	JMP PLAY_TONE

HIGH_TONE:
; ~1167 Hz tone used every time a player presses an Arrow button
; and the move cursors move and as part of the victory jingle.
	MVI	B, $82                     ; TONE_COMMAND = #82, FREQUENCY_DIVISOR = low bits (2)

PLAY_TONE:
; Writes a command sequence to the sound hardware at $8000.
; The ROM selects the pitch, and tone duration appears to be
; controlled by the hardware, but each call begins by clearing
; the sound state, so rapid successive calls can cut off
; earlier tones.
	LXI	H, $8000
	MVI	M, $00                     ; CLEAR_SOUND_STATE
	MVI	M, $88                     ; START_TONE
	MVI	M, $00                     ; CLEAR_SOUND_STATE
	MOV M,B                        ; SET_TONE_FREQUENCY (Mame: 3500/(FREQUENCY_DIVISOR+1))
	RET                            ; RETURN

; Piece and character graphics are stored as 5x5 and 5x7 bitmap
; images respectively. Each row of the image is stored in one byte,
; with the five most-significant bits representing the pixels from
; left to right.

DRAW_GAME_PIECE:
; Input:
;   A = SPACE_CONTENTS
;   HL = VRAM_POINTER
;
; Draws a 5x5 game piece image at the specified VRAM location.
; Blank spaces are rendered as an empty 5x5 image.
	PUSH B                         ; save BC
	MVI	C, $05                     ; ROW_COUNTER = 5
	PUSH D                         ; save DE
	CPI	$03                        ; if SPACE_CONTENTS == '+',
	JZ LOAD_WHITE_PIECE
	CPI	$05                        ; else if SPACE_CONTENTS == '■',
	JZ LOAD_BLACK_PIECE
                                   ; else
	JMP LOAD_BLANK

DRAW_5x7_IMAGE:
; Input:
;   DE = FONT_TABLE_POINTER
;   HL = VRAM_POINTER
;
; Used for drawing messages and the digits in the final game score.
	MVI	A, $01                     ; PIXEL_TYPE = 1
	PUSH B                         ; save BC
	PUSH D                         ; save DE
	MVI	C, $07                     ; ROW_COUNTER = 7
	JMP DRAW_IMAGE

DRAW_5x6_IMAGE:
; Unused in this ROM.
	MVI	A, $01                     ; PIXEL_TYPE = 1
	PUSH B                         ; save BC
	PUSH D                         ; save DE
	MVI	C, $06                     ; ROW_COUNTER = 6

DRAW_IMAGE:
; Input:
;   DE = IMAGE_DATA_POINTER
;   HL = VRAM_POINTER
;   C = ROW_COUNTER
;   A = PIXEL_TYPE
;
; Scans the bitmap one row at a time and expands set bits
; into VRAM as PIXEL_TYPE. Clear bits are written as 0.
;
; For example:
;   01110000 (#70)
; becomes:
;   0 PIXEL_TYPE PIXEL_TYPE PIXEL_TYPE 0
	STA	$4081                      ; IMAGE_PIXEL_VALUE = PIXEL_TYPE

DRAW_NEXT_ROW:
	MVI	B, $05                     ; PIXEL_COUNTER = 5
	LDAX D                         ; A = IMAGE_DATA(POINTER)
	PUSH H                         ; save VRAM_POINTER

GET_AND_DRAW_NEXT_PIXEL:
; Shift next image bit into carry, which is tested with JC.
	RAL	; IMAGE_DATA << 1
	PUSH PSW                       ; save IMAGE_DATA
                                   ; if IMAGE_DATA_HI_BIT == 1,
	JC USE_IMAGE_PIXEL_VALUE
                                   ; else
	MVI	A, $00                     ; PIXEL_TYPE = #00

DRAW_NEXT_PIXEL:
	MOV M,A                        ; VRAM(POINTER) = PIXEL_TYPE
	POP PSW                        ; restore IMAGE_DATA
	INX	H                          ; VRAM_POINTER++
	DCR	B                          ; if --PIXEL_COUNTER != 0,
	JNZ GET_AND_DRAW_NEXT_PIXEL
                                   ; else
	INX	D                          ; IMAGE_DATA_POINTER++
	POP H                          ; restore VRAM_POINTER
	INR	H                          ; VRAM_POINTER += #0100
	DCR	C                          ; if --ROW_COUNTER != 0,
	JNZ DRAW_NEXT_ROW
                                   ; else
	XRA	A                          ; A = 0
	POP D                          ; restore DE
	POP B                          ; restore BC
	RET                            ; RETURN

LOAD_WHITE_PIECE:
	LXI	D, $0004                   ; IMAGE_DATA_POINTER = PLUS_PIECE
	JMP DRAW_IMAGE

LOAD_BLACK_PIECE:
	LXI	D, $0009                   ; IMAGE_DATA_POINTER = SQUARE_PIECE
	JMP DRAW_IMAGE

USE_IMAGE_PIXEL_VALUE:
	LDA	$4081                      ; PIXEL_TYPE = IMAGE_PIXEL_VALUE
	JMP DRAW_NEXT_PIXEL

LOAD_BLANK:
	LXI	D, $000E                   ; IMAGE_DATA_POINTER = BLANK_SPACE
	JMP DRAW_IMAGE

CLEAR_MESSAGE:
; Clears the 8x64 pixel message area:
; $C000-$C03F
; ...
; $C700-$C73F
;
; Sets all of the pixels in the message space to 0 (blank).
	MVI	H, $C0                     ; VRAM_POINTER_HI = #C0
	MVI	B, $08                     ; ROW_COUNTER = 8

CLEAR_NEXT_ROW:
	MVI	L, $00                     ; VRAM_POINTER_LO = #00
	MVI	C, $40                     ; COL_COUNTER = 64

CLEAR_NEXT_PIXEL:
	MVI	M, $00                     ; VRAM(POINTER) = 0
	INR	L                          ; VRAM_POINTER_LO++
	DCR	C                          ; if --COL_COUNTER != 0,
	JNZ CLEAR_NEXT_PIXEL
                                   ; else
	INR	H                          ; VRAM_POINTER_HI++
	DCR	B                          ; if --ROW_COUNTER != 0,
	JNZ CLEAR_NEXT_ROW
                                   ; else
	RET                            ; RETURN

DRAW_MESSAGE:
; Looks up the supplied message by its pointer, reads it one
; character at a time. Each character is looked up in the
; MESSAGE_FONT_TABLE and is drawn to the message space.
; #8D is the message stop character. Once it is encountered
; in the string, this function exits.
	XTHL                           ; save HL / pop RETURN_ADDRESS
	MOV B,M                        ; B = PARAM_1 (unused)
	INX	H                          ; RETURN_ADDRESS++
	MOV D,M                        ; D = MESSAGES_POINTER_HI
	INX	H                          ; RETURN_ADDRESS++
	MOV E,M                        ; E = MESSAGES_POINTER_LO
	INX	H                          ; RETURN_ADDRESS++
	XTHL                           ; push RETURN_ADDRESS / restore HL
	LXI	H, $C002                   ; VRAM_POINTER = $C002

INIT_FIND_CHARACTER:
	LDAX D                         ; MESSAGE_FONT_TABLE_INDEX = MESSAGES(POINTER)
	CPI	$8D                        ; if MESSAGE_FONT_TABLE_INDEX == #8D,
	RZ                             ; RETURN
                                   ; else
	PUSH D                         ; save MESSAGES_POINTER
	MOV B,A                        ; B = MESSAGE_FONT_TABLE_INDEX
	LXI	D, $0B09                   ; MESSAGE_FONT_TABLE_POINTER = $0B09 (0)

FIND_CHARACTER_BY_INDEX:
	DCR	B                          ; if --MESSAGE_FONT_TABLE_INDEX < 0,
	JM DRAW_CHARACTER
                                   ; else
	INX	D
	INX	D
	INX	D
	INX	D
	INX	D
	INX	D
	INX	D                          ; MESSAGE_FONT_TABLE_POINTER += #07 (++)
	JMP FIND_CHARACTER_BY_INDEX

DRAW_CHARACTER:
; After the character is drawn, the VRAM_POINTER is advanced
; 6 pixels to the right.
	PUSH H                         ; save VRAM_POINTER
	CALL DRAW_5x7_IMAGE
	POP H                          ; restore VRAM_POINTER
	INX	H
	INX	H
	INX	H
	INX	H
	INX	H
	INX	H                          ; VRAM_POINTER += 6
	POP D                          ; restore MESSAGES_POINTER
	INX	D                          ; MESSAGES_POINTER++
	JMP INIT_FIND_CHARACTER

; DIGIT_FONT_TABLE
; Used when displaying the final score.
; 0
	DB $70                         ; --xxxxxx--
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $70                         ; --xxxxxx--

; 1
	DB $20                         ; ----xx----
	DB $60                         ; --xxxx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $70                         ; --xxxxxx--

; 2
	DB $70                         ; --xxxxxx--
	DB $88                         ; xx------xx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $20                         ; ----xx----
	DB $40                         ; --xx------
	DB $F8                         ; xxxxxxxxxx

; 3
	DB $F8                         ; xxxxxxxxxx
	DB $10                         ; ------xx--
	DB $20                         ; ----xx----
	DB $10                         ; ------xx--
	DB $08                         ; --------xx
	DB $88                         ; xx------xx
	DB $70                         ; --xxxxxx--

; 4
	DB $10                         ; ------xx--
	DB $30                         ; ----xxxx--
	DB $50                         ; --xx--xx--
	DB $90                         ; xx----xx--
	DB $F8                         ; xxxxxxxxxx
	DB $10                         ; ------xx--
	DB $10                         ; ------xx--

; 5
	DB $F8                         ; xxxxxxxxxx
	DB $80                         ; xx--------
	DB $F0                         ; xxxxxxxx--
	DB $08                         ; --------xx
	DB $08                         ; --------xx
	DB $88                         ; xx------xx
	DB $70                         ; --xxxxxx--

; 6
	DB $30                         ; ----xxxx--
	DB $40                         ; --xx------
	DB $80                         ; xx--------
	DB $F0                         ; xxxxxxxx--
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $70                         ; --xxxxxx--

; 7
	DB $F8                         ; xxxxxxxxxx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $20                         ; ----xx----
	DB $40                         ; --xx------
	DB $40                         ; --xx------
	DB $40                         ; --xx------

; 8
	DB $70                         ; --xxxxxx--
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $70                         ; --xxxxxx--
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $70                         ; --xxxxxx--

; 9
	DB $70                         ; --xxxxxx--
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $78                         ; --xxxxxxxx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $60                         ; --xxxx----

SCORE_GAME:
; Removes the move cursors and clears the ANALYSIS_BOARD before
; making a three-pass scoring loop.
;
; Pass 1 scans the DISPLAY_BOARD for black pieces ('■'). Each
; black piece increments black's score and is copied into the
; ANALYSIS_BOARD, filling spaces from upper-left to lower-right.
;
; Pass 2 scans for blank spaces and copies them into the next
; available ANALYSIS_BOARD spaces.
;
; Pass 3 scans for white pieces ('+'). Each white piece
; increments white's score and is copied into the next available
; ANALYSIS_BOARD space.
;
; As a result, the ANALYSIS_BOARD ends up sorted into black
; pieces, then blanks, then white pieces.
;
; Each space drawn to the ANALYSIS_BOARD, including blanks,
; is accompanied by the VERY_LOW_TONE.
;
; The final scores are displayed in the message area and a
; winner is determined.
	CALL CLEAR_MOVE_CURSORS
	XRA	A
	STA	$4082                      ; ■_COUNT = 0
	XRA	A
	STA	$4083                      ; +_COUNT = 0
	MVI	A, $01
	STA	$40FC                      ; GAME_SCORED_FLAG = 1
	LXI	H, $4040                   ; ANALYSIS_BOARD_POINTER = $4040
	MVI	B, $40                     ; SPACE_LOOP_COUNTER = 64

CLEAR_NEXT_SPACE:
	MVI	M, $00                     ; ANALYSIS_BOARD(POINTER) = BLANK (#00)
	INX	H                          ; ANALYSIS_BOARD_POINTER++
	DCR	B                          ; if --SPACE_LOOP_COUNTER != 0,
	JNZ CLEAR_NEXT_SPACE
                                   ; else
	CALL DRAW_ANALYSIS_BOARD
	LXI	D, $4040                   ; ANALYSIS_BOARD_POINTER = $4040
; Selects what this pass is looking for:
;   3 = Black ('■'), 2 = Blanks, 1 = White ('+'), 0 = done
	MVI	C, $03                     ; SCORING_PASS_COUNTER = 3

START_SCORING_PASS:
	LXI	H, $4000                   ; DISPLAY_BOARD_POINTER = $4000
	MVI	B, $40                     ; SPACE_LOOP_COUNTER = 64

SCORE_NEXT_SPACE:
	MOV A,C
	CPI	$03                        ; if SCORING_PASS_COUNTER == 3,
	JZ SCORE_BLACK
	CPI	$02                        ; else if SCORING_PASS_COUNTER == 2,
	JZ SCORE_BLANK
	CPI	$01                        ; else if SCORING_PASS_COUNTER == 1,
	JZ SCORE_WHITE
                                   ; else
	CALL DRAW_SCORES
	CALL CHECK_PLAYER_WIN
	RET                            ; RETURN

SCORE_BLACK:
	MVI	A, $05
	CMP M                          ; if DISPLAY_BOARD(POINTER) != '■',
	JNZ GET_NEXT_SCORE_SPACE
                                   ; else
	PUSH PSW                       ; save PIECE_TYPE
	LDA	$4082                      ; A = ■_COUNT
	CALL INC_DECIMAL_COUNTER
	STA	$4082                      ; ■_COUNT = A
	JMP WRITE_PIECE_TO_ANALYSIS_BOARD

SCORE_BLANK:
	XRA	A
	CMP M                          ; if DISPLAY_BOARD(POINTER) != BLANK,
	JNZ GET_NEXT_SCORE_SPACE
                                   ; else
	PUSH PSW                       ; save PIECE_TYPE
	JMP WRITE_PIECE_TO_ANALYSIS_BOARD

SCORE_WHITE:
	MVI	A, $03
	CMP M                          ; if DISPLAY_BOARD(POINTER) != '+',
	JNZ GET_NEXT_SCORE_SPACE
                                   ; else
	PUSH PSW                       ; save PIECE_TYPE
	LDA	$4083                      ; A = +_COUNT
	CALL INC_DECIMAL_COUNTER
	STA	$4083                      ; +_COUNT = A

WRITE_PIECE_TO_ANALYSIS_BOARD:
; Write the scored piece to the next position in the
; ANALYSIS_BOARD, redraw that board, and play VERY_LOW_TONE.
	POP PSW                        ; restore PIECE_TYPE
	STAX D                         ; ANALYSIS_BOARD(POINTER) = PIECE_TYPE
	INX	D                          ; ANALYSIS_BOARD_POINTER++
	PUSH D                         ; save ANALYSIS_BOARD_POINTER
	PUSH H                         ; save DISPLAY_BOARD_POINTER
	PUSH B                         ; save SPACE_LOOP_COUNTER
	CALL VERY_LOW_TONE
	CALL DRAW_ANALYSIS_BOARD
	CALL CORE_DELAY                ; [30ms]
	POP B                          ; restore SPACE_LOOP_COUNTER
	POP H                          ; restore DISPLAY_BOARD_POINTER
	POP D                          ; restore ANALYSIS_BOARD_POINTER

GET_NEXT_SCORE_SPACE:
	INX	H                          ; DISPLAY_BOARD_POINTER++
	DCR	B                          ; if --SPACE_LOOP_COUNTER != 0,
	JNZ SCORE_NEXT_SPACE
                                   ; else
	DCR	C                          ; SCORING_PASS_COUNTER--
	JMP START_SCORING_PASS

DRAW_SCORES:
; Draw the white ('+') and black ('■') pieces in the message
; space, then draw their two-digit BCD counts beside them.
	MVI	A, $03                     ; SPACE_CONTENTS = '+'
	LXI	H, $C208                   ; VRAM_POINTER = $C208
	CALL DRAW_GAME_PIECE
	MVI	A, $05                     ; SPACE_CONTENTS = '■'
	LXI	H, $C226                   ; VRAM_POINTER = $C226
	CALL DRAW_GAME_PIECE
	MVI	C, $02                     ; SCORE_COUNTER = 2
	LDA	$4083                      ; A = +_COUNT
	LXI	H, $C00E                   ; VRAM_POINTER = $C00E

DRAW_ONE_SCORE:
	MOV B,A                        ; B = +|■_COUNT
	ANI	$F0                        ; A = +|■_COUNT_TENS
	RRC
	RRC
	RRC
	RRC                            ; +|■_COUNT_TENS >> 4
	CALL LOOKUP_DIGIT_IMAGE
	PUSH H                         ; save VRAM_POINTER
	CALL DRAW_5x7_IMAGE
; Advance 6 pixels to the next digit.
	POP H                          ; restore VRAM_POINTER
	INX	H
	INX	H
	INX	H
	INX	H
	INX	H
	INX	H                          ; VRAM_POINTER += 6
	MOV A,B                        ; A = +|■_COUNT
	ANI	$0F                        ; A = +|■_COUNT_ONES
	CALL LOOKUP_DIGIT_IMAGE
	PUSH H                         ; save VRAM_POINTER
	CALL DRAW_5x7_IMAGE
	POP H                          ; restore VRAM_POINTER
	DCR	C                          ; if --SCORE_COUNTER == 0,
	RZ                             ; RETURN
                                   ; else
	LXI	H, $C02C                   ; VRAM_POINTER = $C02C
	LDA	$4082                      ; A = ■_COUNT
	JMP DRAW_ONE_SCORE

LOOKUP_DIGIT_IMAGE:
; Input:
;   A = DIGIT_FONT_TABLE_INDEX
; Output:
;   DE = DIGIT_FONT_TABLE_POINTER
	LXI	D, $09B1                   ; DIGIT_FONT_TABLE_POINTER = $09B1 (0)

FIND_DIGIT_BY_INDEX:
; Digit 0 returns the initial table pointer.
	DCR	A
	CPI	$FF                        ; if --DIGIT_FONT_TABLE_INDEX == #FF,
	RZ                             ; RETURN
                                   ; else
	PUSH PSW                       ; save DIGIT_FONT_TABLE_INDEX
	INX	D
	INX	D
	INX	D
	INX	D
	INX	D
	INX	D
	INX	D                          ; DIGIT_FONT_TABLE_POINTER += 7 (++)
	POP PSW                        ; restore DIGIT_FONT_TABLE_INDEX
	JMP FIND_DIGIT_BY_INDEX

DRAW_TURN_INDICATOR:
; Blanks out the previous side marker, then draws a black ('■')
; or white ('+') piece beside the board to show the active side.
;
; The markers are outside the move cursor track. Since 1P is
; always white, '+' is drawn near the 1P controls and '■' is
; drawn near the 2P controls.
;
; In 1-player games, only the '+' marker is displayed.
	LDA	$408A                      ; A = CURRENT_PIECE
	CPI	$03                        ; if CURRENT_PIECE == '+',
	JZ DRAW_WHITE_INDICATOR
                                   ; else
	XRA	A                          ; SPACE_CONTENTS = BLANK
	LXI	H, $F800                   ; VRAM_POINTER = $F800 (P1_TURN_INDICATOR)
	CALL DRAW_GAME_PIECE
	LDA	$40FF                      ; A = GAME_MODE
	CPI	$FE                        ; if GAME_MODE == 1P Sente,
	RET Z                          ; RETURN
	CPI	$FD                        ; else if GAME_MODE == 1P Gote,
	RET Z                          ; RETURN
                                   ; else
	LXI	H, $CA00                   ; VRAM_POINTER = $CA00 (P2_TURN_INDICATOR)

DRAW_INDICATOR:
	LDA	$408A                      ; SPACE_CONTENTS = CURRENT_PIECE
	CALL DRAW_GAME_PIECE
	RET                            ; RETURN

DRAW_WHITE_INDICATOR:
	XRA	A                          ; SPACE_CONTENTS = BLANK
	LXI	H, $CA00                   ; VRAM_POINTER = $CA00 (P2_TURN_INDICATOR)
	CALL DRAW_GAME_PIECE
	LXI	H, $F800                   ; VRAM_POINTER = $F800 (P1_TURN_INDICATOR)
	JMP DRAW_INDICATOR

INC_DECIMAL_COUNTER:
; Input:
;   A = ■_COUNT|+_COUNT
; Output:
;   A++
;
; Increments a BCD value while scoring the game.
	STC                            ; set carry bit
	CMC                            ; clear carry bit
	ADI	$01                        ; ■|+_COUNT++
	DAA                            ; make decimal adjustment to ■|+_COUNT
	RET                            ; RETURN

; MESSAGE_FONT_TABLE
; Some message strings use dakuten (゛) and handakuten (゜)
; marks. These are stored as separate glyphs which modify the
; preceding kana character, e.g. カ + ゛ = ガ and ハ + ゜ = パ.
; 00 = イ
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $20                         ; ----xx----
	DB $60                         ; --xxxx----
	DB $A0                         ; xx--xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----

; 01 = ッ
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $A8                         ; xx--xx--xx
	DB $A8                         ; xx--xx--xx
	DB $08                         ; --------xx
	DB $30                         ; ----xxxx--

; 02 = オ
	DB $10                         ; ------xx--
	DB $F8                         ; xxxxxxxxxx
	DB $10                         ; ------xx--
	DB $30                         ; ----xxxx--
	DB $50                         ; --xx--xx--
	DB $90                         ; xx----xx--
	DB $10                         ; ------xx--

; 03 = キ
	DB $20                         ; ----xx----
	DB $F8                         ; xxxxxxxxxx
	DB $20                         ; ----xx----
	DB $F8                         ; xxxxxxxxxx
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----

; 04 = ク
	DB $00                         ; ----------
	DB $78                         ; --xxxxxxxx
	DB $48                         ; --xx----xx
	DB $88                         ; xx------xx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $60                         ; --xxxx----

; 05 = コ
	DB $00                         ; ----------
	DB $F8                         ; xxxxxxxxxx
	DB $08                         ; --------xx
	DB $08                         ; --------xx
	DB $08                         ; --------xx
	DB $08                         ; --------xx
	DB $F8                         ; xxxxxxxxxx

; 06 = ス
	DB $00                         ; ----------
	DB $F8                         ; xxxxxxxxxx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $20                         ; ----xx----
	DB $50                         ; --xx--xx--
	DB $88                         ; xx------xx

; 07 = セ
	DB $40                         ; --xx------
	DB $F8                         ; xxxxxxxxxx
	DB $48                         ; --xx----xx
	DB $50                         ; --xx--xx--
	DB $40                         ; --xx------
	DB $40                         ; --xx------
	DB $38                         ; ----xxxxxx

; 08 = ソ
	DB $00                         ; ----------
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $48                         ; --xx----xx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $60                         ; --xxxx----

; 09 = タ
	DB $00                         ; ----------
	DB $78                         ; --xxxxxxxx
	DB $48                         ; --xx----xx
	DB $A8                         ; xx--xx--xx
	DB $18                         ; ------xxxx
	DB $10                         ; ------xx--
	DB $60                         ; --xxxx----

; 0A = テ
	DB $70                         ; --xxxxxx--
	DB $00                         ; ----------
	DB $F8                         ; xxxxxxxxxx
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $40                         ; --xx------

; 0B = ト
	DB $40                         ; --xx------
	DB $40                         ; --xx------
	DB $40                         ; --xx------
	DB $60                         ; --xxxx----
	DB $50                         ; --xx--xx--
	DB $40                         ; --xx------
	DB $40                         ; --xx------

; 0C = ハ
	DB $00                         ; ----------
	DB $20                         ; ----xx----
	DB $10                         ; ------xx--
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx

; 0D = ヒ
	DB $80                         ; xx--------
	DB $80                         ; xx--------
	DB $F8                         ; xxxxxxxxxx
	DB $80                         ; xx--------
	DB $80                         ; xx--------
	DB $80                         ; xx--------
	DB $78                         ; --xxxxxxxx

; 0E = ュ
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $70                         ; --xxxxxx--
	DB $10                         ; ------xx--
	DB $10                         ; ------xx--
	DB $F8                         ; xxxxxxxxxx

; 0F = リ
	DB $90                         ; xx----xx--
	DB $90                         ; xx----xx--
	DB $90                         ; xx----xx--
	DB $90                         ; xx----xx--
	DB $10                         ; ------xx--
	DB $20                         ; ----xx----
	DB $40                         ; --xx------

; 10 = ン
	DB $00                         ; ----------
	DB $C0                         ; xxxx------
	DB $00                         ; ----------
	DB $08                         ; --------xx
	DB $08                         ; --------xx
	DB $10                         ; ------xx--
	DB $E0                         ; xxxxxx----

; 11 = レ
	DB $00                         ; ----------
	DB $80                         ; xx--------
	DB $80                         ; xx--------
	DB $88                         ; xx------xx
	DB $90                         ; xx----xx--
	DB $A0                         ; xx--xx----
	DB $C0                         ; xxxx------

; 12 = ロ
	DB $00                         ; ----------
	DB $F8                         ; xxxxxxxxxx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $F8                         ; xxxxxxxxxx

; 13 = ￥
	DB $88                         ; xx------xx
	DB $50                         ; --xx--xx--
	DB $F8                         ; xxxxxxxxxx
	DB $20                         ; ----xx----
	DB $F8                         ; xxxxxxxxxx
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----

; 14 = 1
	DB $20                         ; ----xx----
	DB $60                         ; --xxxx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $20                         ; ----xx----
	DB $70                         ; --xxxxxx--

; 15 = 0
	DB $F8                         ; xxxxxxxxxx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $88                         ; xx------xx
	DB $F8                         ; xxxxxxxxxx

; 16 = ゛
	DB $20                         ; ----xx----
	DB $90                         ; xx----xx--
	DB $40                         ; --xx------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------

; 17 = ゜
	DB $E0                         ; xxxxxx----
	DB $A0                         ; xx--xx----
	DB $E0                         ; xxxxxx----
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------

; 18 = ー
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $F8                         ; xxxxxxxxxx
	DB $00                         ; ----------
	DB $00                         ; ----------
	DB $00                         ; ----------

CHECK_PLAYER_WIN:
; In 1-player games, checks whether 1P defeated the CPU.
; If so, play the victory jingle. Ties, CPU wins, and all
; 2-player games return without playing anything.
	LDA	$40FF
	CPI	$FE                        ; if GAME_MODE == 1P Sente,
	JZ WIN_CHECK
	CPI	$FD                        ; else if GAME_MODE == 1P Gote,
	JZ WIN_CHECK
                                   ; else
	RET                            ; RETURN

WIN_CHECK:
	LDA	$4082
	CPI	$00                        ; if ■_COUNT == 0,
	JZ PLAYER_WINS
                                   ; else
	MOV B,A                        ; B = ■_COUNT
	LDA	$4083                      ; A = +_COUNT
	SUB B                          ; if +_COUNT == ■_COUNT,
	RZ                             ; RETURN
                                   ; else if +_COUNT < ■_COUNT,
	RM                             ; RETURN
                                   ; else
PLAYER_WINS:
	CALL PLAY_VICTORY_JINGLE
	RET                            ; RETURN

PLAY_VICTORY_JINGLE:
; The jingle that plays when the player defeats the CPU in a 1-player
; game. It plays for ~9 seconds before it finally stops.
;
; Preserves BC and HL, though this seems unnecessary. The only used
; call path is at the end of SCORE_GAME.
	PUSH B                         ; save BC
	PUSH H                         ; save HL
	MVI	D, $32                     ; JINGLE_LOOP_COUNTER = 50

PLAY_TONES:
; All three tones are used. PLAY_TONE is called every ~60ms, so each
; new tone likely cuts off the previous one before its natural
; hardware-controlled duration ends.
	CALL VERY_LOW_TONE
	CALL DOUBLE_DELAY              ; [60ms]
	CALL LOW_TONE
	CALL DOUBLE_DELAY              ; [60ms]
	CALL HIGH_TONE
	CALL DOUBLE_DELAY              ; [60ms]
	DCR	D                          ; if --JINGLE_LOOP_COUNTER != 0,
	JNZ PLAY_TONES

	POP H                          ; restore HL
	POP B                          ; restore BC
	RET                            ; RETURN

; unused ROM space
	DB $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
