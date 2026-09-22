    ORG 0000H

RESET:
    DI
    JMP STARTUP

PLUS_PIECE:
; (WHITE)
    DB $00                         ; ----------
    DB $20                         ; ----xx----
    DB $70                         ; --xxxxxx--
    DB $20                         ; ----xx----
    DB $00                         ; ----------

SQUARE_PIECE:
; (BLACK)
    DB $00                         ; ----------
    DB $70                         ; --xxxxxx--
    DB $70                         ; --xxxxxx--
    DB $70                         ; --xxxxxx--
    DB $00                         ; ----------

BLANK_SPACE:
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------

CPU_OPENING_MOVE_TABLE:
; (COL, ROW)
    DB $03, $02
    DB $02, $03
    DB $05, $04
    DB $04, $05

BOARD_SPACE_VALUE_TABLE:
; Used by the CPU player to determine its next move.
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

MSG_COMPUTER_OTHELLO:
; "CPU OTHELLO" - Title displayed during attract sequence
    DB $01, $0D, $11, $14, $0C, $10, $05, $03, $09, $09, $0C, $8D

    DB $00                         ; cushion for RST 7 address

; TIMER EXPIRED (RST 7 INTERRUPT)
    JMP TIMER_EXPIRED_ADD_COIN_PROMPT ; @org $0038

MSG_INSERT_COIN:
; "INSERT COIN" - Prompt displayed during attract sequence and timer expiration
    DB $06, $0B, $0F, $03, $0E, $10, $14, $01, $0C, $06, $0B, $8D

MSG_SELECT_GAME:
; "SELECT GAME" - Prompt displayed after coin inserted during attract
    DB $0F, $03, $09, $03, $01, $10, $14, $04, $00, $0A, $03, $8D

MSG_MUST_PLAY:
; "MUST PLAY" - Message displayed when there is a legal move and Pass is pressed
    DB $0A, $11, $0F, $10, $14, $0D, $09, $00, $13, $8D

MSG_MUST_PASS:
; "MUST PASS" - Message displayed when there are no legal moves for the active player
    DB $0A, $11, $0F, $10, $14, $0D, $00, $0F, $0F, $8D

MSG_ILLEGAL_MOVE:
; "ILLEGAL MOVE" - Message displayed when Set is pressed on a space that is not a legal move
    DB $06, $09, $09, $03, $04, $00, $09, $14, $0A, $0C, $12, $03, $8D

MSG_CPU_PASSES:
; "CPU PASSES" - Message indicating that the CPU player has had to pass
    DB $01, $0D, $11, $14, $0D, $00, $0F, $0F, $03, $0F, $8D

MSG_JUDGE_OK:
; "JUDGE OK?" - Confirmation prompt when Judge is pressed
    DB $07, $11, $02, $04, $03, $14, $0C, $08, $15, $8D

MSG_RESET_OK:
; "RESET OK?" - Confirmation prompt when Reset is pressed
    DB $0E, $03, $0F, $03, $10, $14, $0C, $08, $15, $8D

STARTUP:
; Resets stack, clears memory, draws initial board, sets sensible state
; defaults, and starts attract mode.
    LXI SP, $40FA                  ; INIT_STACK <= $40F9 (63 bytes reserved for stack)
    CALL INIT_GAME
; Initializes CURRENT_PIECE to '+'. This will be immediately toggled in attract
; mode, so that '■' goes first there.
    MVI A, $03
    STA $408A                      ; CURRENT_PIECE = '+'
    MVI A, $00
    STA $40FC                      ; ACTIVE_PLAYER_SIDE = 0 (1P)
    MVI A, $03                     ; A = #03
    STA $40FB                      ; P1_PIECE = '+'
    MVI A, $01
    STA $40FF                      ; NUM_PLAYERS = 1
    MVI A, $07                     ; ATTRACT_MOVE_COUNT = 7

; The coin selector logic is a bit of a black box, so the following are
; educated guesses based on code behavior. Analysis of the involved hardware
; would be needed to determine exact meanings.
; 
; States tested by the game:
; #0E -> #03 = coin drop with some kind of anti-fraud/debounce test?
; #06 = another accepted coin path, potentially used when the Reset button is
;       pressed while the timer is active?
; #05 = game in progress / coin blocker engaged?
; #0F/#07 = presumed idle state when waiting for coin

ATTRACT_MODE_LOOP:
    DI
    STA $4088
    LDA $A000                      ; READ_COIN_SLOT (possible values: #0E, #05, #06, #03)
    ANI $0F
    CPI $0E                        ; #0E:
    JZ REREAD_COIN_SLOT
    CPI $05                        ; #05:
    JZ CONTINUE_ATTRACT
    CPI $06                        ; #06:
    JZ COIN_INSERTED

REREAD_COIN_SLOT:
    LDA $A000                      ; READ_COIN_SLOT
    ANI $07
    CPI $03                        ; #03:
    JZ COIN_INSERTED

CONTINUE_ATTRACT:
; Attract mode toggles messages between "CPU OTHELLO" and "INSERT COIN." Every
; time it toggles to "INSERT COIN," the computer plays a piece. There is no
; sound. After 7 moves are played, the program resets.
    CALL CLEAR_AND_DRAW_MESSAGE
    DB $00, $2B                    ; @addr MSG_COMPUTER_OTHELLO
    CALL LONG_DELAY                ; [1s]
    CALL LONG_DELAY                ; [1s]
    CALL CLEAR_AND_DRAW_MESSAGE
    DB $00, $3B                    ; @addr MSG_INSERT_COIN
    LDA $6000                      ; READ_INPUT
    CPI $7F                        ; Service:
    JZ SET_SERVICE_MODE_FLAGS
                                   ; else
; Note that this toggles the piece before it calculates any moves, so the side
; that STARTUP doesn't seed in CURRENT_PIECE will go first in attract mode.
    CALL TOGGLE_CURRENT_PIECE
    CALL CLEAR_MOVE_CURSORS
    MVI A, $01
    STA $40FD                      ; ATTRACT_MODE_SUPPRESS_SOUND = 1
; FIRST_MOVE_CPU isn't used here. Instead, it simply finds the best move every
; turn. For the first move, since all four of the possible opening moves are
; equivalent, it uses the last one scanned, which is (4,5).
    CALL CPU_FIND_AND_PLAY_BEST_MOVE
    LDA $4088
    DCR A                          ; if --ATTRACT_MOVE_COUNT != 0,
    JNZ ATTRACT_MODE_LOOP
                                   ; else
    JMP RESET

SET_SERVICE_MODE_FLAGS:
; If Service B is enabled, set CPU_OPENING_MOVE_TABLE_INDEX = 4,
; NUM_PLAYERS = 0, and CURRENT_PIECE = '■'; reenable sound; and reinitialize
; the game to clear any changes made during attract mode. In service mode, both
; sides are controlled by the CPU and all input prompts are disabled.
    XRA A
    STA $40FD                      ; ATTRACT_MODE_SUPPRESS_SOUND = 0
    LXI SP, $40FA                  ; INIT_STACK <= $40F9
    CALL INIT_GAME
    MVI A, $05
    STA $408A                      ; CURRENT_PIECE = '■'
    MVI A, $00
    STA $40FF                      ; NUM_PLAYERS = 0
    MVI B, $04                     ; B = 4
    JMP FIRST_MOVE_CPU

COIN_INSERTED:
; Reset attract mode state if needed, reenable sound, and prompt for game type
; selection. Each time through, the prompt loop changes what the CPU's first
; move will be if 1P Gote is selected.
;
; If ATTRACT_MOVE_COUNT is still 7, STARTUP has already initialized the board
; and no attract-mode move has completed yet. Skip INIT_GAME to avoid
; clearing/redrawing the board twice after Reset is pressed while time remains.
    LXI SP, $40FA                  ; INIT_STACK <= $40F9
    LDA $4088
    CPI $07                        ; if ATTRACT_MOVE_COUNT == 7,
    JZ SKIP_ATTRACT_MODE_CLEAR
                                   ; else
    CALL INIT_GAME

SKIP_ATTRACT_MODE_CLEAR:
    XRA A
    STA $40FD                      ; ATTRACT_MODE_SUPPRESS_SOUND = 0
; Set so Black ('■') always goes first.
    MVI A, $05
    STA $408A                      ; CURRENT_PIECE = '■'

RESET_PSEUDORANDOM_OPENING_MOVE:
    DI
    MVI B, $04                     ; PSEUDORANDOM_OPENING_MOVE = 4

PROMPT_SELECT_GAME:
    DI
    PUSH B                         ; save PSEUDORANDOM_OPENING_MOVE
    CALL DRAW_MESSAGE
    DB $00, $47                    ; @addr MSG_SELECT_GAME
    POP B                          ; restore PSEUDORANDOM_OPENING_MOVE
    EI
    LDA $6000                      ; READ_INPUT
; Sente and Gote are terms borrowed from Go. Here they indicate which side
; moves first.
    CPI $FE                        ; 1P Sente:
    JZ SENTE_1P
    CPI $FD                        ; 1P Gote:
    JZ FIRST_MOVE_CPU
    CPI $FB                        ; 2P Sente:
    JZ SENTE_2P
    CPI $F7                        ; 2P Gote:
    JZ FIRST_MOVE_2P
    DCR B                          ; if --PSEUDORANDOM_OPENING_MOVE != 0,
    JNZ PROMPT_SELECT_GAME
                                   ; else
    JMP RESET_PSEUDORANDOM_OPENING_MOVE

; Initialize state to reflect the selected game mode.
; NUM_PLAYERS: the number of human-controlled players (0, 1, or 2)
; ACTIVE_PLAYER_SIDE: 0 = P1 side, 1 = P2/CPU side
; P1_PIECE: P1's piece color

SENTE_2P:
    DI
    MVI A, $02
    STA $40FF                      ; NUM_PLAYERS = 2

SENTE_1P:
    DI
    MVI A, $05                     ; A = #05
    STA $40FB                      ; P1_PIECE = '■'

FIRST_MOVE_COMMON:
    CALL WAIT_FOR_INPUT_RELEASE
    JMP PLAYER_TURN_CORE

FIRST_MOVE_2P:
    DI
    MVI A, $02
    STA $40FF                      ; NUM_PLAYERS = 2
    MVI A, $01
    STA $40FC                      ; ACTIVE_PLAYER_SIDE = 1 (P2)
    JMP FIRST_MOVE_COMMON

FIRST_MOVE_CPU:
; Input:
;   B = CPU_OPENING_MOVE_INDEX (1..4)
;     is always 4 when in Service mode
    DI
    MOV A,B
    STA $40FE                      ; CPU_OPENING_MOVE_INDEX = B
    CALL CLEAR_MESSAGE

    MVI A, $01
    STA $40FC                      ; ACTIVE_PLAYER_SIDE = 1 (P2)
    CALL DRAW_TURN_INDICATOR
    CALL PERFORM_CPU_OPENING_MOVE
    JMP EXIT_CPU_TURN

CPU_TURN:
    DI
    CALL CLEAR_MESSAGE
; If both players passed on their previous turns, then neither side has a legal
; move and the game is over.
    LDA $4089
    CPI $02                        ; if CONSECUTIVE_PASS_COUNTER == 2,
    JZ WAIT_THEN_JUDGE
                                   ; else
    CALL CLEAR_MOVE_CURSORS
    CALL DRAW_TURN_INDICATOR
    CALL CPU_FIND_AND_PLAY_BEST_MOVE

EXIT_CPU_TURN:
    CALL TOGGLE_ACTIVE_PLAYER_SIDE
    LDA $40FF
    CPI $00                        ; if NUM_PLAYERS == 0,
    JZ CPU_TURN
                                   ; else
PLAYER_TURN:
    DI
; If both players passed on their previous turns, then neither side has a legal
; move and the game is over.
    LDA $4089
    CPI $02                        ; if CONSECUTIVE_PASS_COUNTER == 2,
    JZ WAIT_THEN_JUDGE
                                   ; else
PLAYER_TURN_CORE:
    CALL CLEAR_MOVE_CURSORS
    CALL CLEAR_MESSAGE
    CALL DRAW_TURN_INDICATOR
    CALL PLAYER_INPUT_LOOP
    CALL TOGGLE_ACTIVE_PLAYER_SIDE
    LDA $40FF
    CPI $02                        ; if NUM_PLAYERS == 2,
    JZ PLAYER_TURN
                                   ; else
    JMP CPU_TURN

TOGGLE_ACTIVE_PLAYER_SIDE:
; Flips which side of the screen represents the active player and flips the
; piece of the current player from White to Black and vice versa.
    LDA $40FC
    XRI $01
    STA $40FC                      ; ACTIVE_PLAYER_SIDE = 0 <--> 1
    CALL TOGGLE_CURRENT_PIECE
    RET                            ; RETURN

WAIT_THEN_JUDGE:
; When the caller has detected one of the endgame states, the game waits for 1
; second and then performs the Judge routine. After scoring is complete, the
; game waits for 6 seconds and then automatically resets.
;
; This is a QoL update. The original ROM prompted the player to press the Judge
; button before scoring could begin and then prompted the player to press the
; Reset button when scoring was completed.
; 
; Possible endgame states include two consecutive passes, every space on the
; board being filled, or all of the pieces of one side being eliminated.
    CALL LONG_DELAY                ; [1s]

JUDGE_PRESSED_FINAL:
    DI
    CALL SCORE_GAME
    CALL VERY_LONG_DELAY           ; [6s]
    JMP RESET

PLAYER_INPUT_LOOP:
; Handles player input during a human player's turn. The Pass and Set buttons
; end the turn when their use is permitted. The Judge and Reset buttons trigger
; a confirmation prompt before ending the game immediately. The Arrow buttons
; update the location of the move cursors.
;
; The confirmation prompts are a QoL update that help prevent players from
; accidentally ending a game in progress.
    DI
    XRA A
    STA $408B                      ; MOVE_COL = 0
    XRA A
    STA $408C                      ; MOVE_ROW = 0
    CALL DRAW_MOVE_CURSORS
    CALL CHECK_IF_PLAYER_MUST_PASS
    MOV A,B
    STA $4098                      ; PASS_REQUIRED_FLAG = PLAYER_MUST_PASS

PLAYER_INPUT_LOOP_CORE:
    DI
    LDA $4098
    CPI $01                        ; if PASS_REQUIRED_FLAG == 1,
    JZ PASS_BUTTON_PROMPT
                                   ; else
PLAYER_INPUT_LOOP_SKIP_PASS_PROMPT:
; In the original ROM, the "PRESS PASS" message was cleared and redrawn every
; iteration of the input loop, causing it to flicker. This QoL update keeps the
; message visible until the pass condition is resolved.
    EI
    LDA $6000                      ; READ_INPUT
; Both players' Pass buttons are mapped to the same value. There's no need to
; differentiate them because the Pass button only has an effect when there are
; no legal moves for the active player.
    CPI $FB                        ; Pass:
    JZ PASS_PRESSED
; Both players' Arrow buttons are mapped to the same values. The controls are
; mirrored on opposite sides of the screen, so 'Right' for P1 and 'Left' for P2
; both move the horizontal cursor in the same direction.
    CPI $FD                        ; P1 Right/P2 Left Arrow:
    JZ P1_RIGHT_P2_LEFT_PRESSED
; Likewise, 'Down' for P1 and 'Up' for P2 both move the vertical cursor in the
; same direction.
    CPI $FE                        ; P1 Up/P2 Down Arrow:
    JZ P1_DOWN_P2_UP_PRESSED
; A QoL update adds confirmation prompts when either the Judge or Reset buttons
; are pressed. Pressing the same button again confirms the action. Any other
; button clears the prompt and restarts the player's turn.
    CPI $BF                        ; Judge:
    JZ CLEAR_AND_ESCAPABLE_PROMPT_FOR_JUDGE
    CPI $DF                        ; Reset:
    JZ CLEAR_AND_ESCAPABLE_PROMPT_FOR_RESET
    LDA $40FC                      ; else
; Unlike the Pass and Arrow buttons, the Set buttons are treated as distinct
; inputs. The current value of ACTIVE_PLAYER_SIDE determines which player's Set
; button is accepted. Both inputs ultimately lead to the SET_PRESSED function.
    CPI $00                        ; if ACTIVE_PLAYER_SIDE == 0 (P1),
    JZ CHECK_P1_SET_PRESSED
                                   ; else
    LDA $6000                      ; READ_INPUT
    CPI $F7                        ; P2_Set:
    JZ SET_PRESSED
                                   ; else
    JMP PLAYER_INPUT_LOOP_CORE

PASS_BUTTON_PROMPT:
; PASS_REQUIRED_FLAG indicates that the active player has no legal moves and
; must pass. Unlike most prompts in the game, this one does not suspend normal
; input handling. The player can still press any button and they will function
; normally, but since there are no legal moves they will be unable to set a
; piece anywhere.
    CALL DRAW_MESSAGE
    DB $00, $5D                    ; @addr MSG_MUST_PASS
    JMP PLAYER_INPUT_LOOP_SKIP_PASS_PROMPT

PASS_PRESSED:
    DI
    CALL WAIT_FOR_INPUT_RELEASE
; If passing is not allowed, a QoL update displays a brief "MUST PLAY" message
; before restarting the player's turn. Otherwise, update the pass counter and
; end the player's turn.
    LDA $4098
    CPI $00                        ; if PASS_REQUIRED_FLAG == 0,
    JZ MUST_PLAY
                                   ; else
    LXI H, $4089
    INR M                          ; CONSECUTIVE_PASS_COUNTER++

EXIT_INPUT_LOOP:
; Ends the player's current turn.
    RET                            ; RETURN

MUST_PLAY:
    CALL CLEAR_AND_DRAW_MESSAGE
    DB $00, $53                    ; @addr MSG_MUST_PLAY
    CALL LONG_DELAY                ; [1s]
    CALL CLEAR_MESSAGE
    JMP PLAYER_INPUT_LOOP_CORE

CHECK_P1_SET_PRESSED:
    LDA $6000                      ; READ_INPUT
    CPI $EF                        ; P1 Set:
    JZ SET_PRESSED
                                   ; else
    JMP PLAYER_INPUT_LOOP_CORE

SET_PRESSED:
    DI
; If the attempted move is illegal, a QoL update displays a brief
; "ILLEGAL MOVE" message before restarting the player's turn. Otherwise, apply
; the move and end the player's turn.
    CALL CHECK_IF_MOVE_IS_LEGAL
    MOV A,B
    CPI $00                        ; if MOVE_LEGAL == 0,
    JZ ILLEGAL_MOVE_MESSAGE
                                   ; else
    CALL PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES
    CALL WAIT_FOR_INPUT_RELEASE
    JMP EXIT_INPUT_LOOP

ILLEGAL_MOVE_MESSAGE:
    CALL CLEAR_AND_DRAW_MESSAGE
    DB $00, $67                    ; @addr MSG_ILLEGAL_MOVE
    CALL LONG_DELAY                ; [1s]
    CALL CLEAR_MESSAGE
    JMP PLAYER_INPUT_LOOP_CORE

CLEAR_AND_ESCAPABLE_PROMPT_FOR_JUDGE:
; Clear the board UI, wait for the original Judge press to be released, then
; ask for confirmation.
    CALL CLEAR_MOVE_CURSORS
    CALL CLEAR_MESSAGE
    CALL WAIT_FOR_INPUT_RELEASE

ESCAPABLE_PROMPT_FOR_JUDGE:
    CALL DRAW_MESSAGE
    DB $00, $7F                    ; @addr MSG_JUDGE_OK
    EI
    LDA $6000                      ; READ_INPUT
    CPI $BF                        ; Judge:
    JZ JUDGE_PRESSED_FINAL
; Any other button cancels the prompt. Return through PLAYER_TURN_CORE so the
; confirmation message is cleared and the turn display is restored.
    CPI $FF                        ; Any Button:
    JNZ PLAYER_TURN_CORE
                                   ; else
    JMP ESCAPABLE_PROMPT_FOR_JUDGE

CLEAR_AND_ESCAPABLE_PROMPT_FOR_RESET:
; Clear the board UI, wait for the original Reset press to be released, then
; ask for confirmation.
    CALL CLEAR_MOVE_CURSORS
    CALL CLEAR_MESSAGE
    CALL WAIT_FOR_INPUT_RELEASE

ESCAPABLE_PROMPT_FOR_RESET:
    CALL DRAW_MESSAGE
    DB $00, $89                    ; @addr MSG_RESET_OK
    EI
    LDA $6000                      ; READ_INPUT
    CPI $DF                        ; Reset:
    JZ RESET
; Any other button cancels the prompt. Return through PLAYER_TURN_CORE so the
; confirmation message is cleared and the turn display is restored.
    CPI $FF                        ; Any Button:
    JNZ PLAYER_TURN_CORE
                                   ; else
    JMP ESCAPABLE_PROMPT_FOR_RESET

; The move cursors each only move in one direction and wrap around at the board
; edge.

P1_RIGHT_P2_LEFT_PRESSED:
    DI
    LDA $408B                      ; A = MOVE_COL
    INR A                          ; A++
    CPI $08                        ; if A != 8,
    JNZ UPDATE_MOVE_COL
                                   ; else
    XRA A                          ; A = 0

UPDATE_MOVE_COL:
    STA $408B                      ; MOVE_COL = A

UPDATE_MOVE_CURSOR:
    CALL HIGH_TONE_AND_DRAW_MOVE_CURSORS
    CALL WAIT_FOR_INPUT_RELEASE
    JMP PLAYER_INPUT_LOOP_CORE

P1_DOWN_P2_UP_PRESSED:
    DI
    LDA $408C                      ; A = MOVE_ROW
    INR A                          ; A++
    CPI $08                        ; if A != 8,
    JNZ UPDATE_MOVE_ROW
                                   ; else
    XRA A                          ; A = 0

UPDATE_MOVE_ROW:
    STA $408C                      ; MOVE_ROW = A
    JMP UPDATE_MOVE_CURSOR

TIMER_EXPIRED_ADD_COIN_PROMPT:
    DI
    PUSH PSW                       ; save everything
    PUSH H
    PUSH D
    PUSH B
    CALL CLEAR_MESSAGE

WAIT_05_COIN_CLEAR:
; Waits for coin slot state #05 to clear before proceeding. Based on code
; behavior, this may indicate that a game is active and/or that the coin
; blocker is engaged.
    LDA $A000                      ; READ_COIN_SLOT (possible values: #0E, #05, #06, #03)
    ANI $07
    CPI $05                        ; #05:
    JZ WAIT_05_COIN_CLEAR
                                   ; else
    MVI C, $1E                     ; CONTINUE_LOOP_COUNTER = 30

CHECK_FOR_CONTINUE_LOOP:
; Slowly blink the 'INSERT COIN' message and check the coin slot for roughly
; one minute before resetting.
;
; Coin slot states #06, #03, and #05 are all treated as valid continue states.
; Their exact hardware meaning is unknown.
    CALL CHECK_COIN_SLOT_FOR_CONTINUE_COIN
    DCR B                          ; if --ESCAPE_FLAG < 0,
    JM ESCAPE

    DCR C                          ; if --CONTINUE_LOOP_COUNTER != 0,
    JNZ CHECK_FOR_CONTINUE_LOOP
                                   ; else
    LDA $A000                      ; READ_COIN_SLOT
    ANI $07
    CPI $05                        ; #05:
    JZ ESCAPE
                                   ; else
    JMP RESET

CHECK_COIN_SLOT_FOR_CONTINUE_COIN:
    MVI B, $01                     ; ESCAPE_FLAG = 1
    LDA $A000                      ; READ_COIN_SLOT
    ANI $07
    CPI $06                        ; #06:
    JZ SET_ESCAPE
    CPI $03                        ; #03:
    JZ SET_ESCAPE
    CPI $05                        ; #05:
    JZ SET_ESCAPE 
; The Judge button is still functional during the continue screen.
    LDA $6000                      ; READ_INPUT
    CPI $BF                        ; Judge:
    JZ JUDGE_PRESSED_AT_CONTINUE
                                   ; else
    PUSH B                         ; save ESCAPE_FLAG
    CALL DRAW_MESSAGE
    DB $00, $3B                    ; @addr MSG_INSERT_COIN
    CALL LONG_DELAY                ; [1s]
    CALL CLEAR_MESSAGE
    CALL LONG_DELAY                ; [1s]
    POP B	                       ; restore ESCAPE_FLAG
    RET                            ; RETURN

SET_ESCAPE:
    DCR B                          ; ESCAPE_FLAG = 0
    RET                            ; RETURN

JUDGE_PRESSED_AT_CONTINUE:
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
; 6 second delay used before resetting the game after generating the scores.
    PUSH B                         ; save BC
    MVI B, $C8                     ; DELAY_LOOP_COUNTER = 200
    JMP DELAY_LOOP

LONG_DELAY:
; 1 second delay used as the standard duration when informational messages are displayed, as
; the blink duration on the continue screen, and as the built-in delay between
; reaching an endgame state and scoring the game.
;
; Also used twice in succession after the CPU passes and to cycle messages
; during attract mode.
; 742,487 cycles
    PUSH B                         ; save BC
    MVI B, $1E                     ; DELAY_LOOP_COUNTER = 30
    JMP DELAY_LOOP

DELAY_LOOP:
    CALL CORE_DELAY
    DCR B                          ; if --DELAY_LOOP_COUNTER != 0,
    JNZ DELAY_LOOP
    POP B                          ; restore BC

DOUBLE_DELAY:
; 60 ms delay used as the spacing between tones in the victory jingle.
    CALL CORE_DELAY

CORE_DELAY:
; 23,171 cycles
; 30 ms delay that serves as the basis for all longer delays. Also used directly to flash the
; board after a move is made and when adding pieces to the board during
; SCORE_GAME.
    PUSH H                         ; save HL
    LXI H, $0600                   ; OUTER_LOOP_COUNTER = 6, INNER_LOOP_COUNTER = 256/0

INNER_LOOP:
    DCR L                          ; if --INNER_LOOP_COUNTER != 0,
    JNZ INNER_LOOP
                                   ; else
    DCR H                          ; if --OUTER_LOOP_COUNTER != 0,
    JNZ INNER_LOOP
                                   ; else
    POP H                          ; restore HL
    RET                            ; RETURN

CPU_FIND_AND_PLAY_BEST_MOVE:
; Creates a MOVE_ASSESSMENT, a packed 16-byte representation of the board's
; current contents. On the first pass, it marks the X-squares as illegal moves,
; so they won't be considered during move evaluation. Each legal move is
; attempted on the ANALYSIS_BOARD and the resulting position is scored using
; the BOARD_SPACE_VALUE_TABLE. The move that leads to the best score is the one
; that is selected.
;
; If no legal moves are found on the first pass, a second pass is performed,
; this time with the X-squares under consideration.
    MVI A, $01                     ; AI_FIRST_PASS_FLAG = 1

CPU_FIND_AND_PLAY_BEST_MOVE_CORE:
    STA $4086
    XRA A
    STA $408B                      ; MOVE_COL = 0
    XRA A
    STA $408C                      ; MOVE_ROW = 0
    LXI H, $8000
    SHLD $408D                     ; BEST_MOVE_EVAL_SCORE = -32,768
    CALL CREATE_DISPLAY_BOARD_MOVE_ASSESSMENT
    LDA $4086
    CPI $01                        ; if AI_FIRST_PASS_FLAG != 1,
    JNZ BEGIN_MOVE_SEARCH
                                   ; else
    CALL FIRST_PASS_REMOVE_HIGH_RISK_SQUARES

BEGIN_MOVE_SEARCH:
    LXI D, $0000                   ; ROW_D, COL_E = (0,0)
    CALL FIND_NEXT_CANDIDATE_MOVE_FROM_ROW_COL
    MOV A,B
    CPI $01                        ; if NO_CANDIDATE_MOVE == 1,
    JZ NO_LEGAL_MOVES
                                   ; else
    CALL TRY_CANDIDATE_MOVE_ON_ANALYSIS_BOARD

EVALUATE_CANDIDATE_AND_CONTINUE_MOVE_SEARCH:
    CALL GENERATE_CANDIDATE_MOVE_EVAL_SCORE
    CALL UPDATE_BEST_MOVE_EVAL_SCORE_IF_BETTER
    CALL GET_CANDIDATE_MOVE
    INR E                          ; COL_E++
    MOV A,E
    CPI $08                        ; if COL_E != 8,
    JNZ CONTINUE_MOVE_SEARCH
                                   ; else
    MVI E, $00                     ; COL_E = 0
    INR D                          ; ROW_D++
    MOV A,D
    CPI $08                        ; if ROW_D != 8,
    JNZ CONTINUE_MOVE_SEARCH
                                   ; else
    JMP PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES

CONTINUE_MOVE_SEARCH:
    CALL FIND_NEXT_CANDIDATE_MOVE_FROM_ROW_COL
    MOV A,B
    CPI $01                        ; if NO_CANDIDATE_MOVE == 1,
    JZ PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES
                                   ; else
    CALL TRY_CANDIDATE_MOVE_ON_ANALYSIS_BOARD
    JMP EVALUATE_CANDIDATE_AND_CONTINUE_MOVE_SEARCH

NO_LEGAL_MOVES:
    LDA $4086
    CPI $01                        ; if AI_FIRST_PASS_FLAG != 1,
    JNZ STILL_NO_LEGAL_MOVES
                                   ; else
    DCR A                          ; AI_FIRST_PASS_FLAG = 0
    JMP CPU_FIND_AND_PLAY_BEST_MOVE_CORE

PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES:
; Add a move (MOVE_COL, MOVE_ROW) to the ANALYSIS_BOARD that has been
; previously selected by either the player or the CPU.
;
; The new piece is flashed on the screen 3 times, followed by the newly
; outflanked pieces flashing 3 times. The DISPLAY_BOARD is then updated with
; all of the changes.
;
; If the board is now full or one side has been completely eliminated as a
; result of the move, end the game and call the scoring routine.
    XRA A
    STA $4089                      ; CONSECUTIVE_PASS_COUNTER = 0
    CALL COPY_DISPLAY_BOARD_TO_ANALYSIS_BOARD

    LDA $408C
    MOV H,A                        ; H = MOVE_ROW
    LDA $408B
    MOV L,A                        ; L = MOVE_COL
    PUSH H                         ; save MOVE_ROW/COL
    CALL GET_SPACE_ON_ANALYSIS_BOARD

    LDA $408A
    MOV M,A                        ; ANALYSIS_BOARD (H,L) = CURRENT_PIECE
    CALL FLASH_BOARD_CHANGE
    POP H                          ; restore MOVE_ROW/COL
    MVI A, $01
    STA $4084                      ; BOARD_SELECTION_FOR_SCAN = 1 (ANALYSIS)
    CALL SCAN_AND_FLIP_OUTFLANKED_PIECES
    CALL FLASH_BOARD_CHANGE
    CALL COPY_ANALYSIS_BOARD_TO_DISPLAY_BOARD

; QoL improvement to track the total number of pieces on the board. If all 64
; spaces are occupied, the game is automatically ended and scored without
; requiring presses of the Pass button(s) and the Judge button.
    LXI H, $4080
    INR M                          ; PIECE_COUNT++
    MOV A,M
    CPI $40                        ; if PIECE_COUNT == 64,
    JZ WAIT_THEN_JUDGE
                                   ; else
; QoL improvement to check if one side has been completely eliminated from the
; board. If so, the game is automatically ended and scored.
    LXI H, $4000                   ; DISPLAY_BOARD_POINTER = $4000
    MVI B, $40                     ; SPACE_LOOP_COUNTER = 64

    LDA $408A                      ; A = CURRENT_PIECE
    XRI $06                        ; A = OPPONENT_PIECE ('+' <-> '■')

CHECK_NEXT_SPACE_IS_OPPONENT:
    CMP M                          ; if DISPLAY_BOARD(POINTER) != OPPONENT_PIECE,
    JNZ GET_NEXT_SPACE
                                   ; else
    RET                            ; RETURN

GET_NEXT_SPACE:
    INX H                          ; DISPLAY_BOARD_POINTER++
    DCR B                          ; if --SPACE_LOOP_COUNTER != 0,
    JNZ CHECK_NEXT_SPACE_IS_OPPONENT
                                   ; else
    JMP WAIT_THEN_JUDGE

STILL_NO_LEGAL_MOVES:
; If no legal moves are found on either search pass, record a pass, display the
; 'CPU PASSES' message, and advance to the other player's turn.
    LXI H, $4089
    INR M                          ; CONSECUTIVE_PASS_COUNTER++
    CALL CLEAR_AND_DRAW_MESSAGE
    DB $00, $74                    ; @addr MSG_CPU_PASSES
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
;
; Advances to (D,E) and then scans the MOVE_ASSESSMENT to find the next legal
; candidate move from there.
    LXI H, $4099                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER = (0,0)
    PUSH D                         ; save ROW_D, COL_E
    INR D                          ; ROW_D++

; Advance the MOVE_ASSESSMENT_POINTER to (D,E) before searching for candidate
; moves.

FIND_ROW_D:
    DCR D                          ; if --ROW_D != 0,
    JNZ ADVANCE_POINTER_1_ROW
                                   ; else
FIND_COL_E_BYTE:
    MOV B,M                        ; B = ROW_D_POINTER_BYTE
    MOV A,E
    CPI $04                        ; if COL_E == 4,
    JZ ADVANCE_POINTER_4_COLS
                                   ; else if COL_E > 4,
    JP ADVANCE_POINTER_4_COLS
                                   ; else
    MOV A,B                        ; A = POINTER_BYTE
    INR E                          ; COL_E++

FIND_COL_E_BITS:
    DCR E                          ; if --COL_E != 0,
    JNZ ADVANCE_POINTER_1_COL
                                   ; else
; MOVE_ASSESSMENT_POINTER is now set to (D,E), so begin scanning for a legal
; move from there.
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
    INR E                          ; COL_E++
    MOV A,E
    CPI $04                        ; if COL_E == 4,
    JZ GET_NEXT_POINTER_BYTE
    CPI $08                        ; else if COL_E != 8,
    JNZ INSPECT_NEXT_SPACE
                                   ; else
    MVI E, $00                     ; COL_E = 0
    INR D                          ; ROW_D++
    MOV A,D
    CPI $08                        ; if ROW_D != 8,
    JNZ GET_NEXT_POINTER_BYTE
                                   ; else
    MVI B, $01                     ; NO_CANDIDATE_MOVE = 1
    POP PSW                        ; clear POINTER_BYTE from stack
    RET                            ; RETURN

INSPECT_NEXT_SPACE:
    POP PSW                        ; restore POINTER_BYTE
    JMP INSPECT_SPACE

RETURN_LEGAL_SPACE:
; Store CANDIDATE_MOVE in RAM
    LXI H, $40A9
    MOV M,E                        ; CANDIDATE_MOVE_COL = COL_E
    INX H
    MOV M,D                        ; CANDIDATE_MOVE_ROW = ROW_D
    MVI B, $00                     ; NO_CANDIDATE_MOVE = 0
    RET                            ; RETURN

SKIP_OCCUPIED_SPACE:
    RLC                            ; discard low bit (POINTER_BYTE << 1)
    JMP ADVANCE_POINTER_TO_NEXT_SPACE

GET_NEXT_POINTER_BYTE:
    INX H                          ; MOVE_ASSESSMENT_POINTER++
    JMP GET_POINTER_BYTE

ADVANCE_POINTER_1_ROW:
    INX H
    INX H                          ; MOVE_ASSESSEMENT_POINTER = (x++,y)
    JMP FIND_ROW_D

ADVANCE_POINTER_4_COLS:
    INX H                          ; MOVE_ASSESSEMENT_POINTER = (x,y+4)
    DCR E
    DCR E
    DCR E
    DCR E                          ; COL_E = COL_E-4
    JMP FIND_COL_E_BYTE

ADVANCE_POINTER_1_COL:
    RLC
    RLC                            ; FOUND_POINTER_BYTE << 2
    JMP FIND_COL_E_BITS

TRY_CANDIDATE_MOVE:
    MVI A, $01
    STA $4084                      ; BOARD_SELECTION_FOR_SCAN = 1 (ANALYSIS)
    CALL GET_CANDIDATE_MOVE
    XCHG                           ; HL = CANDIDATE_MOVE_ROW, CANDIDATE_MOVE_COL
    CALL SCAN_AND_FLIP_OUTFLANKED_PIECES
    RET                            ; RETURN

SCAN_AND_FLIP_OUTFLANKED_PIECES:
; Input:
;   HL = MOVE_ROW, MOVE_COL
;
; Scan all 8 directions from the selected move on the ANALYSIS_BOARD, flipping
; all of the resulting outflanked pieces. Once all directions have been
; processed, place the new piece on the board.
    MVI D, $01                     ; DIRECTION = 1

CONTINUE_SCAN_FOR_OUTFLANKED_PIECES:
    CALL INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
    MVI E, $01                     ; FLIP_PIECES = 1
    CALL SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
; Upon exit, D holds the next DIRECTION to be scanned.
    MOV A,D
    CPI $09                        ; if DIRECTION != 9,
    JNZ CONTINUE_SCAN_FOR_OUTFLANKED_PIECES
                                   ; else
; Finally, actually play the piece on the board.
    CALL GET_SPACE_ON_ANALYSIS_BOARD
    LDA $408A                      ; A = CURRENT_PIECE
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
    ADI $40
    MOV L,A
    MVI A, $00
    ADC H
    MOV H,A                        ; ANALYSIS_BOARD_POINTER = DISPLAY_BOARD_POINTER + #0040
    RET                            ; RETURN

TRY_CANDIDATE_MOVE_ON_ANALYSIS_BOARD:
; Expand the MOVE_ASSESSMENT into the ANALYSIS_BOARD and apply the current
; candidate move.
    CALL POPULATE_ANALYSIS_BOARD_FROM_DISPLAY_BOARD_MOVE_ASSESSMENT
    CALL TRY_CANDIDATE_MOVE
    RET                            ; RETURN

COPY_DISPLAY_BOARD_TO_ANALYSIS_BOARD:
    LXI H, $4000                   ; HL = DISPLAY_BOARD_POINTER
    LXI D, $4040                   ; DE = ANALYSIS_BOARD_POINTER
    JMP COPY_BOARD_CORE

COPY_ANALYSIS_BOARD_TO_DISPLAY_BOARD:
    LXI H, $4040                   ; HL = ANALYSIS_BOARD_POINTER
    LXI D, $4000                   ; DE = DISPLAY_BOARD_POINTER

COPY_BOARD_CORE:
; Input:
;   HL = SOURCE_BOARD_POINTER
;   DE = TARGET_BOARD_POINTER
    MVI B, $40                     ; COPY_SPACE_LOOP_COUNTER = 64

COPY_SPACE:
    MOV A,M
    STAX D                         ; TARGET_BOARD(POINTER) = SOURCE_BOARD(POINTER)
    INX H                          ; SOURCE_BOARD_POINTER++
    INX D                          ; TARGET_BOARD_POINTER++
    DCR B                          ; if --COPY_SPACE_LOOP_COUNTER != 0
    JNZ COPY_SPACE
                                   ; else
    RET                            ; RETURN

LOAD_CANDIDATE_MOVE_EVAL_SCORE:
; Output:
;   BC = CANDIDATE_MOVE_EVAL_SCORE
    PUSH H                         ; save HL
    LXI H, $4095
    MOV C,M
    INX H
    MOV B,M                        ; BC = CANDIDATE_MOVE_EVAL_SCORE
    POP H                          ; restore HL
    RET                            ; RETURN

DRAW_ANALYSIS_BOARD:
    LXI D, $4040                   ; DE = ANALYSIS_BOARD_POINTER
    JMP DRAW_BOARD_CORE

DRAW_DISPLAY_BOARD:
    LXI D, $4000                   ; DE = DISPLAY_BOARD_POINTER

DRAW_BOARD_CORE:
    LXI H, $CE0A                   ; HL = VRAM_POINTER(0,0) = $CE0A
    MVI C, $08                     ; ROW_COUNTER = 8

DRAW_ROW:
    PUSH H                         ; save VRAM_POINTER (start of row)
    MVI B, $08                     ; COL_COUNTER = 8

DRAW_SPACE:
    PUSH H                         ; save VRAM_POINTER
    LDAX D                         ; SPACE_CONTENTS = BOARD(POINTER)
    CALL DRAW_GAME_PIECE
    INX D                          ; BOARD_POINTER++
    POP H                          ; restore VRAM_POINTER
    MOV A,L
; Advance VRAM pointer 6 pixels horizontally (5 for the space + 1 for the line)
    ADI $06                        ; VRAM_POINTER = VRAM_POINTER + 6
    MOV L,A                        ; HL = VRAM_POINTER(x++,y)
    DCR B                          ; if --COL_COUNTER != 0,
    JNZ DRAW_SPACE
                                   ; else
    POP H                          ; restore VRAM_POINTER (start of row)
    MOV A,H
; Advance VRAM pointer 6 pixels vertically (5 for the space + 1 for the line)
    ADI $06                        ; VRAM_POINTER += #0600
    MOV H,A                        ; HL = VRAM_POINTER(x,y++)
    DCR C                          ; if --ROW_COUNTER != 0,
    JNZ DRAW_ROW
                                   ; else
    RET                            ; RETURN

TOGGLE_CURRENT_PIECE:
    LDA $408A
    XRI $06                        ; CURRENT_PIECE = '+' <-> '■'
    STA $408A
    RET                            ; RETURN

CLEAR_WORK_RAM:
; Output:
;   RAM from $4000-$40EF = 0
;
; Preserves top of stack (so calls through INIT_GAME can return) as well as
; P1_PIECE, ACTIVE_PLAYER_SIDE, ATTRACT_MODE_SUPPRESS_SOUND,
; CPU_OPENING_MOVE_INDEX, and NUM_PLAYERS. These values are required by code
; that executes after INIT_GAME returns, so need to be preserved.
    LXI H, $4000                   ; RAM_POINTER = $4000
    MVI C, $F0                     ; CLEAR_RAM_LOOP_COUNTER = 240

ZERO_OUT_RAM:
    MVI M, $00                     ; RAM(POINTER) = 0
    INX H                          ; RAM_POINTER++
    DCR C                          ; if --CLEAR_RAM_LOOP_COUNTER != 0,
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
    LXI B, $0001                   ; INCREMENTER = 1
    LXI H, $C000                   ; VRAM_POINTER = $C000
    XRA A

ZERO_OUT_VRAM:
    MOV M,A                        ; VRAM(POINTER) = 0
    DAD B                          ; VRAM_POINTER = VRAM_POINTER + INCREMENTER
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
    XRA A
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
; If FLIP_PIECES is 0, scan the current direction for outflanked pieces. An
; empty space, board edge, or CURRENT_PIECE without first encountering any
; opponent pieces advances the scan to the next direction. Opponent pieces
; increment NUM_OUTFLANKED_PIECES and continue the scan in the same direction.
; If one or more opponent pieces are followed by a CURRENT_PIECE, then
; outflanked pieces have been found and the count and direction of the pieces
; are returned to the caller.
;
; If FLIP_PIECES is 1, then NUM_OUTFLANKED_PIECES is the number of pieces to
; flip in the current direction. Flip the pieces one by one until all of the
; outflanked pieces have been handled. Return the next direction to scan to the
; caller.
    MOV A,D                        ; CURR_DIRECTION = DIRECTION
    PUSH H                         ; save MOVE_ROW, MOVE_COL
    LXI H, DIRECTION_TABLE         ; HL = DIRECTION_TABLE(1)

FIND_DIRECTION_IN_DIRECTION_TABLE:
; Set DIRECTION_TABLE pointer to match caller's indicated direction.
    DCR A                          ; if --CURR_DIRECTION == 0,
    JZ EXEC_DIRECTION_TABLE

    PUSH PSW                       ; save CURR_DIRECTION
    MOV A,L
    ADI $06
    MOV L,A
    MVI A, $00
    ADC H
    MOV H,A                        ; HL = HL + 6, DIRECTION_TABLE(++)
    POP PSW                        ; restore CURR_DIRECTION
    JMP FIND_DIRECTION_IN_DIRECTION_TABLE

EXEC_DIRECTION_TABLE:
; Each DIRECTION_TABLE entry adjusts MOVE_ROW/MOVE_COL, then jumps into the
; common scan logic.
    PCHL                           ; exec DIRECTION_TABLE(D)

DIRECTION_TABLE:
; (1) - UP
    POP H                          ; restore MOVE_ROW, MOVE_COL
    DCR H                          ; MOVE_ROW--
    NOP
    JMP SCAN_DIRECTION

; (2) - UP-RIGHT
    POP H                          ; restore MOVE_ROW, MOVE_COL
    INR L                          ; MOVE_COL++
    DCR H                          ; MOVE_ROW--
    JMP SCAN_DIRECTION

; (3) - RIGHT
    POP H                          ; restore MOVE_ROW, MOVE_COL
    INR L                          ; MOVE_COL++
    NOP
    JMP SCAN_DIRECTION

; (4) - DOWN-RIGHT
    POP H                          ; restore MOVE_ROW, MOVE_COL
    INR H                          ; MOVE_ROW++
    INR L                          ; MOVE_COL++
    JMP SCAN_DIRECTION

; (5) - DOWN
    POP H                          ; restore MOVE_ROW, MOVE_COL
    INR H                          ; MOVE_ROW++
    NOP
    JMP SCAN_DIRECTION

; (6) - DOWN-LEFT
    POP H                          ; restore MOVE_ROW, MOVE_COL
    INR H                          ; MOVE_ROW++
    DCR L                          ; MOVE_COL--
    JMP SCAN_DIRECTION

; (7) - LEFT
    POP H                          ; restore MOVE_ROW, MOVE_COL
    DCR L                          ; MOVE_COL--
    NOP
    JMP SCAN_DIRECTION

; (8) - UP-LEFT
    POP H                          ; restore MOVE_ROW, MOVE_COL
    DCR L                          ; MOVE_COL--
    DCR H                          ; MOVE_ROW++
    JMP SCAN_DIRECTION

; (9) - RETURN
; Reached when all 8 directions have been exhausted.
    POP H                          ; clear MOVE_ROW, MOVE_COL from stack
    POP H                          ; restore MOVE_ROW, MOVE_COL
    RET                            ; RETURN

SCAN_DIRECTION:
; If board edges are found, advance the scan to the next direction.
    MOV A,H
    CPI $FF                        ; if MOVE_ROW == -1,
    JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
    CPI $08                        ; else if MOVE_ROW == 8,
    JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
                                   ; else
    MOV A,L
    CPI $FF                        ; if MOVE_COL == -1,
    JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
    CPI $08                        ; else if MOVE_COL == 8,
    JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
                                   ; else
    LDA $408A
    MOV C,A                        ; C = CURRENT_PIECE
    PUSH H                         ; save MOVE_ROW, MOVE_COL
; Scan either the DISPLAY_BOARD or ANALYSIS_BOARD as requested by caller.
    LDA $4084
    RAR                            ; if BOARD_SELECTION_FOR_SCAN == 1,
    JC USE_ANALYSIS_BOARD
                                   ; else
    CALL GET_SPACE_ON_DISPLAY_BOARD

EXAMINE_SPACE_CONTENTS:
    MOV A,M                        ; SPACE_CONTENTS = BOARD_POINTER (MOVE_ROW, MOVE_COL)
    POP H                          ; restore MOVE_ROW, MOVE_COL
    CPI $00                        ; if SPACE_CONTENTS == 0 (BLANK),
    JZ INCREMENT_DIRECTION_AND_CONTINUE_SCAN
    CMP C                          ; else if SPACE_CONTENTS != CURRENT_PIECE,
    JNZ HANDLE_OPPONENT_PIECE
                                   ; else
    MOV A,B
    CPI $00                        ; if NUM_OUTFLANKED_PIECES != 0,
    JNZ OUTFLANK_COMPLETE
                                   ; else
INCREMENT_DIRECTION_AND_CONTINUE_SCAN:
    POP H                          ; restore MOVE_ROW, MOVE_COL
    INR D                          ; DIRECTION++
    MVI B, $00                     ; NUM_OUTFLANKED_PIECES = 0
    MOV A,D
    CPI $09                        ; if DIRECTION != 9,
    JNZ SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
                                   ; else
    RET                            ; RETURN

USE_ANALYSIS_BOARD:
    CALL GET_SPACE_ON_ANALYSIS_BOARD
    JMP EXAMINE_SPACE_CONTENTS

OUTFLANK_COMPLETE:
    POP H                          ; restore MOVE_ROW, MOVE_COL
    RET                            ; RETURN

HANDLE_OPPONENT_PIECE:
; Flip or count piece depending on FLIP_PIECES setting.
    MOV A,E
    CPI $01                        ; if FLIP_PIECES == 1,
    JZ FLIP_SQUARE
                                   ; else
    INR B                          ; NUM_OUTFLANKED_PIECES++
    JMP SCAN_FOR_OUTFLANKED_PIECES_CORE

FLIP_SQUARE:
    CALL FLIP_SQUARE_ON_ANALYSIS_BOARD
    DCR B	                       ; if --NUM_OUTFLANKED_PIECES != 0,
    JNZ SCAN_FOR_OUTFLANKED_PIECES_CORE
                                   ; else
    INR D                          ; DIRECTION++
    POP H                          ; restore MOVE_ROW, MOVE_COL
    RET                            ; RETURN

GET_CANDIDATE_MOVE:
; Output:
;   DE = CANDIDATE_MOVE_ROW, CANDIDATE_MOVE_COL
;
; Retrieve stored CANDIDATE_MOVE.
    LHLD $40A9                     ; HL = stored CANDIDATE_MOVE
    XCHG                           ; DE = CANDIDATE_MOVE_ROW, CANDIDATE_MOVE_COL
    RET                            ; RETURN

UPDATE_BEST_MOVE_EVAL_SCORE_IF_BETTER:
; Input:
;   BC = CANDIDATE_MOVE_EVAL_SCORE
;
; Compare CANDIDATE_MOVE_EVAL_SCORE against the stored BEST_MOVE_EVAL_SCORE.
; Scores are signed 16-bit values. If the candidate score is greater than or
; equal to the current best score, update BEST_MOVE_EVAL_SCORE and update
; MOVE_COL/MOVE_ROW with the associated candidate move.
;
; Ties update the best move, so moves scanned later win.
    LXI H, $408D
    MOV E,M
    INX H
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
    LXI H, $408D
    MOV M,C
    INX H
    MOV M,B                        ; BEST_MOVE_EVAL_SCORE = CANDIDATE_MOVE_EVAL_SCORE
    LDA $40A9
    STA $408B                      ; MOVE_COL = CANDIDATE_MOVE_COL
    LDA $40AA
    STA $408C                      ; MOVE_ROW = CANDIDATE_MOVE_ROW
    RET                            ; RETURN

GENERATE_CANDIDATE_MOVE_EVAL_SCORE:
; Output:
;   BC = CANDIDATE_MOVE_EVAL_SCORE
;
; Scans all of the spaces of the ANALYSIS_BOARD after a candidate move has been
; applied to it and generates a move evaluation score for that candidate. The
; move evaluation score uses the values from the BOARD_SPACE_VALUE_TABLE.
; Spaces occupied by the current player's pieces are added to the total. Spaces
; occupied by their opponent's pieces are subtracted from the total. Unoccupied
; spaces are not included.
;
; The largest possible value is 2252 (#08CC), so the score must be stored in a
; register pair rather than a single byte.
    LXI H, $4095
    MVI M, $00
    INX H
    MVI M, $00                     ; CANDIDATE_MOVE_EVAL_SCORE = 0
    LXI H, $4040                   ; HL = ANALYSIS_BOARD_POINTER
    MVI D, $00                     ; ROW_D = 0

START_NEXT_EVAL_ROW:
    MVI E, $00                     ; COL_E = 0

GET_NEXT_EVAL_SPACE:
    MOV A,M                        ; CURRENT_SPACE = ANALYSIS_BOARD (ROW_D,COL_E)
    PUSH PSW                       ; save CURRENT_SPACE
    LDA $408A
    MOV B,A                        ; B = CURRENT_PIECE
    POP PSW                        ; restore CURRENT_SPACE
    PUSH D                         ; save ROW_D
    CMP B                          ; if CURRENT_SPACE == CURRENT_PIECE,
    JZ ADD_SPACE_VALUE
    CPI $00                        ; else if CURRENT_SPACE == 0,
    JZ NEXT_EVAL_SPACE
                                   ; else
    CALL GET_SPACE_VALUE
    CALL SUB_VALUE_FROM_MOVE_EVAL_SCORE

NEXT_EVAL_SPACE:
    POP D                          ; restore ROW_D
    INX H                          ; ANALYSIS_BOARD_POINTER++
    INR E                          ; COL_E++
    MOV A,E
    CPI $08                        ; if COL_E != 8,
    JNZ GET_NEXT_EVAL_SPACE
                                   ; else
    INR D                          ; ROW_D++
    MOV A,D
    CPI $08                        ; if ROW_D != 8,
    JNZ START_NEXT_EVAL_ROW
                                   ; else
    LXI H, $4095
    MOV C,M
    INX H
    MOV B,M                        ; BC = CANDIDATE_MOVE_EVAL_SCORE
    RET                            ; RETURN

ADD_SPACE_VALUE:
    CALL GET_SPACE_VALUE
    CALL ADD_VALUE_TO_MOVE_EVAL_SCORE
    JMP NEXT_EVAL_SPACE

GET_SPACE_VALUE:
; The BOARD_SPACE_VALUE_TABLE contains only 16 entries. Due to the symmetry of
; the board, every space can be mapped into the upper-left 4x4 quadrant, where
; unique values are stored.
;
; Any ROW or COL coordinate greater than 3 is reflected about the board's
; centerline by replacing it with (7 - coordinate).
;
; The resulting 2-bit ROW and 2-bit COL values are then combined to form a
; 4-bit table index:
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
    LXI H, BOARD_SPACE_VALUE_TABLE ; HL = BOARD_SPACE_VALUE_TABLE(0)
    MOV A,E
    ADD L
    MOV L,A
    MVI A, $00
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
    MVI A, $03
    CMP B                          ; if ROW_D|COL_E > 3,
    JM MODIFY_INDEX_BITS
                                   ; else
    MOV C,B                        ; BITS = ROW_D|COL_E
    RET                            ; RETURN

MODIFY_INDEX_BITS:
; Reflects coordinates about the board's centerline.
    MVI A, $07
    SUB B
    MOV C,A                        ; BITS = 7 - ROW_D|COL_E
    RET                            ; RETURN

ADD_VALUE_TO_MOVE_EVAL_SCORE:
    CALL LOAD_CANDIDATE_MOVE_EVAL_SCORE

; Because a register pair is needed to store the score, the 8-bit
; BOARD_SPACE_VALUE is added to or subtracted from MOVE_EVAL_SCORE by repeated
; increment/decrement of BC. The 8080 has 16-bit addition via DAD, but not a
; compact way to add or subtract an 8-bit value directly to/from a register
; pair.

INCREMENT_MOVE_EVAL_SCORE:
    INX B                          ; MOVE_EVAL_SCORE++
    DCR A                          ; if --BOARD_SPACE_VALUE != 0,
    JNZ INCREMENT_MOVE_EVAL_SCORE
                                   ; else
    CALL UPDATE_CANDIDATE_MOVE_EVAL_SCORE
    RET                            ; RETURN

UPDATE_CANDIDATE_MOVE_EVAL_SCORE:
    PUSH H                         ; save ANALYSIS_BOARD_POINTER
    LXI H, $4095
    MOV M,C
    INX H
    MOV M,B                        ; CANDIDATE_MOVE_EVAL_SCORE = MOVE_EVAL_SCORE
    POP H                          ; restore ANALYSIS_BOARD_POINTER
    RET                            ; RETURN

SUB_VALUE_FROM_MOVE_EVAL_SCORE:
    CALL LOAD_CANDIDATE_MOVE_EVAL_SCORE

DECREMENT_MOVE_EVAL_SCORE:
    DCX B                          ; MOVE_EVAL_SCORE--
    DCR A                          ; if --BOARD_SPACE_VALUE != 0,
    JNZ DECREMENT_MOVE_EVAL_SCORE
                                   ; else
    CALL UPDATE_CANDIDATE_MOVE_EVAL_SCORE
    RET                            ; RETURN

CREATE_DISPLAY_BOARD_MOVE_ASSESSMENT:
; Creates a 16-byte packed representation of the board. Each byte holds four
; two-bit values representing a set of four adjacent spaces. Empty spaces are
; scanned to determine whether playing there would outflank opponent pieces.
;
; Possible values are:
;   0 = Empty but illegal
;   1 = Empty and legal
;   2 = Contains black piece ('■')
;   3 = Contains white piece ('+')
    LXI D, $4000                   ; DE = DISPLAY_BOARD_POINTER (0,0)
    XRA A
    STA $4084                      ; BOARD_SELECTION_FOR_SCAN = 0 (DISPLAY)
    LXI H, $4099                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER (0,0)
    SHLD $4092                     ; MOVE_ASSESSMENT_WRITE_POINTER = BOARD_MOVE_ASSESSMENT_POINTER
    MVI C, $04                     ; ACCUMULATOR_COUNTER = 4
    LXI H, $0000                   ; ROW_H, COL_L = (0,0)

ASSESS_SPACE:
    LDAX D
    CPI $03                        ; if BOARD_POINTER (x,y) == '+'
    JZ ASSESSMENT_HANDLE_WHITE
    CPI $05                        ; if BOARD_POINTER (x,y) == '■'
    JZ ASSESSMENT_HANDLE_BLACK
                                   ; else
    PUSH D                         ; save BOARD_POINTER
    MVI D, $01                     ; DIRECTION = 1
    PUSH B                         ; save CURRENT_SPACE_ACCUMULATOR (unnecessary, uninitialized)
; Unlike when applying moves, this call does not flip pieces. It only checks
; whether the empty space would outflank pieces in any direction.
    CALL INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
    POP B                          ; restore CURRENT_SPACE_ACCUMULATOR
    MOV A,D
    CPI $09                        ; if DIRECTION == 9,
    JZ ILLEGAL_SPACE
                                   ; else
    MVI B, $01                     ; CURRENT_SPACE_ACCUMULATOR = 1
    POP D                          ; restore BOARD_POINTER

ACCUMULATOR_HANDLER:
; Pack CURRENT_SPACE_ACCUMULATOR into MOVE_ASSESSMENT_ACCUMULATOR. After four
; spaces, write the completed byte and advance MOVE_ASSESSMENT_WRITE_POINTER.
    PUSH H                         ; save ROW_H, COL_L
    MOV A,C
    CPI $04                        ; if ACCUMULATOR_COUNTER != 4,
    JNZ LOAD_ACCUMULATOR
                                   ; else
    XRA A                          ; TEMP_ACCUMULATOR = 0

ADD_CURRENT_SPACE_ACCUMULATOR:
    ADD B                          ; TEMP_ACCUMULATOR = TEMP_ACCUMULATOR + CURRENT_SPACE_ACCUMULATOR
    DCR C                          ; if --ACCUMULATOR_COUNTER != 0,
    JNZ SHIFT_ACCUMULATOR_BITS_AND_SAVE
                                   ; else
    LHLD $4092
    MOV M,A                        ; MOVE_ASSESSMENT(WRITE_POINTER) = TEMP_ACCUMULATOR
    INX H
    SHLD $4092                     ; MOVE_ASSESSMENT_WRITE_POINTER++
    MVI C, $04                     ; ACCUMULATOR_COUNTER = 4

GET_NEXT_ASSESSMENT_SPACE:
    POP H                          ; restore ROW_H, COL_L
    INR L                          ; COL_L++
    MOV A,L
    CPI $08                        ; if COL_L == 8,
    JZ GET_NEXT_ASSESSMENT_ROW
                                   ; else
ASSESS_NEXT_SPACE:
    INX D                          ; BOARD_POINTER++
    JMP ASSESS_SPACE

GET_NEXT_ASSESSMENT_ROW:
    MVI L, $00                     ; COL_L = 0
    INR H                          ; ROW_H++
    MOV A,H
    CPI $08                        ; if ROW_H != 8,
    JNZ ASSESS_NEXT_SPACE
                                   ; else
    RET                            ; RETURN

ASSESSMENT_HANDLE_WHITE:
    MVI B, $03                     ; CURRENT_SPACE_ACCUMULATOR = 3
    JMP ACCUMULATOR_HANDLER

ASSESSMENT_HANDLE_BLACK:
    MVI B, $02                     ; CURRENT_SPACE_ACCUMULATOR = 2
    JMP ACCUMULATOR_HANDLER

ILLEGAL_SPACE:
    MVI B, $00                     ; CURRENT_SPACE_ACCUMULATOR = 0
    POP D                          ; restore BOARD_POINTER
    JMP ACCUMULATOR_HANDLER

LOAD_ACCUMULATOR:
    LDA $4094                      ; TEMP_ACCUMULATOR = MOVE_ASSESSMENT_ACCUMULATOR
    JMP ADD_CURRENT_SPACE_ACCUMULATOR

SHIFT_ACCUMULATOR_BITS_AND_SAVE:
    RLC
    RLC
    STA $4094                      ; MOVE_ASSESSMENT_ACCUMULATOR = TEMP_ACCUMULATOR << 2
    JMP GET_NEXT_ASSESSMENT_SPACE

POPULATE_ANALYSIS_BOARD_FROM_DISPLAY_BOARD_MOVE_ASSESSMENT:
    LXI H, $4099                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER
    MVI D, $00                     ; ROW_D = 0

START_NEXT_ASSESSMENT_ROW:
    MVI E, $00                     ; COL_E = 0

GET_NEXT_MOVE_ASSESSMENT_BYTE:
    MOV A,M                        ; MOVE_ASSESSMENT_BYTE = MOVE_ASSESSMENT(POINTER)

EXAMINE_MOVE_ASSESSMENT_BITS:
    RLC                            ; if MOVE_ASSESSMENT_HI_BIT = 1,
    JC SPACE_OCCUPIED
    RLC                            ; else
    MVI B, $00                     ; SPACE_CONTENTS = 0 (BLANK)

ADD_CONTENTS_TO_ANALYSIS_BOARD:
    PUSH D                         ; save ROW_D, COL_E
    MOV C,A                        ; CURR_MOVE_ASSESSMENT_BYTE = MOVE_ASSESSMENT_BYTE << 2
    XCHG                           ; HL = ROW_D, COL_E; DE = MOVE_ASSESSMENT_POINTER
    CALL GET_SPACE_ON_ANALYSIS_BOARD
    MOV M,B                        ; ANALYSIS_BOARD (D,E) = SPACE_CONTENTS
    XCHG                           ; HL = MOVE_ASSESSMENT_POINTER
    POP D                          ; restore ROW_D, COL_E
    INR E                          ; COL_E++
    MOV A,E
    CPI $04                        ; if COL_E == 4,
    JZ ADVANCE_MOVE_ASSESSMENT_POINTER
    CPI $08                        ; if COL_E != 8,
    JNZ CONTINUE_WITH_MOVE_ASSESSMENT_BYTE
                                   ; else
    INR D                          ; ROW_D++
    INX H                          ; MOVE_ASSESSMENT_POINTER++
    MOV A,D
    CPI $08                        ; if ROW_D != 8,
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
    MVI B, $05                     ; SPACE_CONTENTS = '■'
    JMP ADD_CONTENTS_TO_ANALYSIS_BOARD

SPACE_IS_WHITE:
    MVI B, $03                     ; SPACE_CONTENTS = '+'
    JMP ADD_CONTENTS_TO_ANALYSIS_BOARD

ADVANCE_MOVE_ASSESSMENT_POINTER:
    INX H                          ; MOVE_ASSESSMENT_POINTER++
    JMP GET_NEXT_MOVE_ASSESSMENT_BYTE

DRAW_GRID:
; Draws the nine intersecting vertical and horizontal lines that make up the
; 8x8 gameboard. Each line is 49 pixels in length, spanning eight 5-pixel cells
; and the nine perpendicular 1-pixel lines.
    MVI C, $09                     ; NUM_LINES = 9
    LXI H, $CD09                   ; HORI_LINE_VRAM_POINTER = $CD09
    PUSH H
    POP D                          ; VERT_LINE_VRAM_POINTER = $CD09

DRAW_NEXT_LINES:
    PUSH H                         ; save HORI_LINE_VRAM_POINTER
    PUSH D                         ; save VERT_LINE_VRAM_POINTER
    MVI B, $31                     ; GRID_LINE_LENGTH = 49

DRAW_NEXT_PIXELS:
    MVI A, $01                     ; PIXEL_TYPE = 1
    MOV M,A                        ; HORI_LINE_VRAM(POINTER) = PIXEL_TYPE
    STAX D                         ; VERT_LINE_VRAM(POINTER) = PIXEL_TYPE
    INR L                          ; HORI_LINE_VRAM_POINTER++
    INR D                          ; VERT_LINE_VRAM_POINTER += #0100
    DCR B                          ; if --GRID_LINE_LENGTH != 0,
    JNZ DRAW_NEXT_PIXELS
                                   ; else
    POP D                          ; restore VERT_LINE_VRAM_POINTER
    POP H                          ; restore HORI_LINE_VRAM_POINTER
; Advance pointers by 6 to next lines, moving past the next 5-pixel cell.
    MOV A,H
    ADI $06
    MOV H,A                        ; HORI_LINE_VRAM_POINTER += #0600
    MOV A,E
    ADI $06
    MOV E,A                        ; VERT_LINE_VRAM_POINTER += #0006
    DCR C                          ; if --NUM_LINES != 0,
    JNZ DRAW_NEXT_LINES
                                   ; else
    RET                            ; RETURN

ADD_STARTING_PIECES_TO_BOARDS_AND_DRAW:
; Initialize the ANALYSIS and DISPLAY boards to Othello's standard starting
; position, then draw the DISPLAY_BOARD. Pieces are written directly into the
; ANALYSIS_BOARD's RAM rather than using GET_SPACE_ON_ANALYSIS_BOARD with
; coordinates.
;
; + ■
; ■ +
    MVI A, $03
    LXI H, $405B
    MOV M,A                        ; ANALYSIS_BOARD(3,3) = '+'
    MVI A, $03
    LXI H, $4064
    MOV M,A                        ; ANALYSIS_BOARD(4,4) = '+'
    MVI A, $05
    LXI H, $405C
    MOV M,A                        ; ANALYSIS_BOARD(4,3) = '■'
    MVI A, $05
    LXI H, $4063
    MOV M,A                        ; ANALYSIS_BOARD(3,4) = '■'
    CALL COPY_ANALYSIS_BOARD_TO_DISPLAY_BOARD
    CALL DRAW_DISPLAY_BOARD
; Initialize the total number of pieces on the board to 4.
    MVI A, $04
    STA $4080                      ; PIECE_COUNT = 4
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
; which exactly matches the DISPLAY_BOARD's memory map.
    MOV A,H
    RLC
    RLC
    RLC                            ; A = H_ROW << 3
    ADD L
    MOV L,A                        ; OFFSET = H_ROW*8 + L_COL
    MVI H, $40                     ; HL = $4000 + OFFSET
    RET                            ; RETURN

FLIP_SQUARE_ON_ANALYSIS_BOARD:
; Input:
;   HL = H_ROW, L_COL
;
; Set ANALYSIS_BOARD (H_ROW,L_COL) to CURRENT_PIECE. This routine does not
; toggle the existing piece. Callers are responsible for ensuring that the
; space contained an opponent piece.
    PUSH H                         ; save H_ROW, L_COL
    CALL GET_SPACE_ON_ANALYSIS_BOARD
    LDA $408A
    MOV M,A                        ; ANALYSIS_BOARD (H_ROW, L_COL) = CURRENT_PIECE
    POP H                          ; restore H_ROW, L_COL
    RET                            ; RETURN

WAIT_FOR_INPUT_RELEASE:
; Loops until no pressed inputs are detected.
    LDA $6000                      ; READ_INPUT
    CPI $FF                        ; !No Input:
    JNZ WAIT_FOR_INPUT_RELEASE
                                   ; else
    RET                            ; RETURN

CHECK_IF_MOVE_IS_LEGAL:
    LDA $408C
    MOV H,A                        ; H_ROW = MOVE_ROW
    LDA $408B
    MOV L,A                        ; L_COL = MOVE_COL

CHECK_IF_SPACE_IS_LEGAL_MOVE:
; Input:
;   H = H_ROW (0..7)
;   L = L_COL (0..7)
; Output:
;   B = MOVE_LEGAL (0/1)
;
; A move is legal only if the selected DISPLAY_BOARD space is empty and placing
; CURRENT_PIECE there would outflank at least one opponent piece.
    PUSH H                         ; save H_ROW, L_COL
    CALL GET_SPACE_ON_DISPLAY_BOARD
    MOV A,M                        ; SPACE_CONTENTS = DISPLAY_BOARD(H_ROW,L_COL)
    POP H                          ; restore H_ROW, L_COL
    CPI $00                        ; if SPACE_CONTENTS != 0,
    JNZ MOVE_ILLEGAL
    XRA A
    STA $4084                      ; BOARD_SELECTION_FOR_SCAN = 0 (DISPLAY)
    MVI D, $01                     ; DIRECTION = 1
; Unlike when applying moves, this call does not flip pieces. It only checks
; whether the empty space would outflank pieces in any direction. If it would,
; then MOVE_LEGAL is set to 1.
    CALL INIT_SCAN_CLOCKWISE_FOR_OUTFLANKED_PIECES_FROM_DIRECTION
    MOV A,D
    CPI $09                        ; if DIRECTION == 9,
    JZ MOVE_ILLEGAL
                                   ; else
    MVI B, $01                     ; MOVE_LEGAL = 1
    RET                            ; RETURN

MOVE_ILLEGAL:
    MVI B, $00                     ; MOVE_LEGAL = 0
    RET                            ; RETURN

CHECK_IF_PLAYER_MUST_PASS:
; Output:
;   B = PLAYER_MUST_PASS (0/1)
;
; Scans the entire board for a legal move for the current player. The search
; terminates immediately if one is found. If no legal move exists,
; PLAYER_MUST_PASS is set to 1.
    MVI H, $07                     ; H_ROW = 7

CHECK_NEXT_ROW:
    MVI L, $07                     ; L_COL = 7

CHECK_NEXT_SPACE:
    CALL CHECK_IF_SPACE_IS_LEGAL_MOVE
    MOV A,B
    CPI $00                        ; if MOVE_LEGAL != 0,
    JNZ PLAYER_HAS_LEGAL_MOVE
    DCR L                          ; if --L_COL >= 0,
    JP CHECK_NEXT_SPACE
                                   ; else
    DCR H                          ; if --H_ROW >= 0,
    JP CHECK_NEXT_ROW
                                   ; else
    MVI B, $01                     ; PLAYER_MUST_PASS = 1
    RET                            ; RETURN

PLAYER_HAS_LEGAL_MOVE:
    MVI B, $00                     ; PLAYER_MUST_PASS = 0
    RET                            ; RETURN

HIGH_TONE_AND_DRAW_MOVE_CURSORS:
    CALL HIGH_TONE

DRAW_MOVE_CURSORS:
; Clear the old move cursors, then draw new 5-pixel length cursors matching
; MOVE_COL/MOVE_ROW.
;
; From 1P's perspective, the horizontal cursor is drawn above the board, and
; the vertical cursor is drawn to the left of the board.
    CALL CLEAR_MOVE_CURSORS
    LXI H, $CA0A                   ; HL = VRAM_HORI_CURSOR_POINTER(0) = $CA0A
    LDA $408C
    MOV D,A                        ; D = MOVE_ROW
    LDA $408B
    MOV E,A                        ; E = MOVE_COL

SET_HORIZONTAL_CURSOR:
    DCR E                          ; if --MOVE_COL < 0,
    JM DRAW_HORIZONTAL_CURSOR
                                   ; else
    MOV A,L
; Cursor moves 6 pixels at a time to skip over 5-pixel cell and 1-pixel line.
    ADI $06                        ; VRAM_HORI_CURSOR_POINTER += #0006
    MOV L,A                        ; VRAM_HORI_CURSOR_POINTER(++)
    JMP SET_HORIZONTAL_CURSOR

DRAW_HORIZONTAL_CURSOR:
    LDA $408A                      ; A = CURRENT_PIECE
    CALL DRAW_HORIZONTAL_MOVE_CURSOR

    LXI H, $CE06                   ; HL = VRAM_VERT_CURSOR_POINTER(0) = $CE06

SET_VERTICAL_CURSOR:
    DCR D                          ; if --MOVE_ROW < 0,
    JM DRAW_VERTICAL_CURSOR
                                   ; else
    MOV A,H
; Cursor moves 6 pixels at a time to skip over 5-pixel cell and 1-pixel line.
    ADI $06                        ; VRAM_VERT_CURSOR_POINTER += #0600
    MOV H,A                        ; VRAM_VERT_CURSOR_POINTER(++)
    JMP SET_VERTICAL_CURSOR

DRAW_VERTICAL_CURSOR:
    LDA $408A                      ; A = CURRENT_PIECE
    CALL DRAW_VERTICAL_MOVE_CURSOR
    RET                            ; RETURN

CLEAR_MOVE_CURSORS:
; Blanks out the entire 52-pixel horizontal and vertical lines where the move
; cursors are displayed.
;
; The cursor lines extend slightly beyond the 49-pixel board span. The extra
; pixels are never drawn as cursors, but clearing them simplifies the
; implementation.
    MVI B, $34                     ; MOVE_CURSOR_LINE_LENGTH = 52
    LXI H, $CA06                   ; VRAM_HORI_CURSOR_POINTER = $CA06
    PUSH H
    POP D                          ; VRAM_VERT_CURSOR_POINTER = $CA06

BLANK_NEXT_PIXELS:
    XRA A                          ; PIXEL_TYPE = 0 (BLANK)
    MOV M,A                        ; VRAM_HORI_CURSOR(POINTER) = PIXEL_TYPE
    STAX D                         ; VRAM_VERT_CURSOR(POINTER) = PIXEL_TYPE
    INR L                          ; VRAM_HORI_CURSOR_POINTER++
    INR D                          ; VRAM_VERT_CURSOR_POINTER += #0100
    DCR B                          ; if --MOVE_CURSOR_LINE_LENGTH != 0,
    JNZ BLANK_NEXT_PIXELS
                                   ; else
    RET                            ; RETURN

FLASH_BOARD_CHANGE:
; Alternates between the DISPLAY_BOARD (before the move) and ANALYSIS_BOARD
; (after the move) 3 times in rapid succession, highlighting the newly played
; piece or any resulting flips.
;
; If not in attract mode, LOW_TONE is emitted each time the ANALYSIS_BOARD is
; drawn.
    MVI A, $03                     ; FLASH_LOOP_COUNTER = 3

FLASH_BOARD:
    PUSH PSW                       ; save FLASH_LOOP_COUNTER
    CALL DRAW_DISPLAY_BOARD
    CALL CORE_DELAY                ; [30ms]
    LDA $40FD
    CPI $01                        ; if ATTRACT_MODE_SUPPRESS_SOUND == 0,
    JZ SWAP_BOARD
                                   ; else
    CALL LOW_TONE

SWAP_BOARD:
    CALL DRAW_ANALYSIS_BOARD
    CALL CORE_DELAY                ; [30ms]
    POP PSW                        ; restore FLASH_LOOP_COUNTER
    DCR A                          ; if --FLASH_LOOP_COUNTER != 0,
    JNZ FLASH_BOARD
                                   ; else
    RET                            ; RETURN

FIRST_PASS_REMOVE_HIGH_RISK_SQUARES:
; X-squares are the diagonally corner-adjacent squares:
;   (1,1), (1,6), (6,1), (6,6)
; Othello strategy classifies these as high risk positions to avoid because
; they often allow an opponent to capture a corner.
;
; Zeroes the four X-squares in the MOVE_ASSESSMENT if they are unoccupied,
; marking them as illegal moves. This prevents the CPU from considering them as
; moves on the first pass.
    MVI B, $02                     ; ROW_LOOP_COUNTER = 2
    LXI H, $409B                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER(1,0) = $409B

REMOVE_HIGH_RISK_FROM_ROW:
    MOV A,M
    ANI $20                        ; if X-square is occupied (hi bit != 0),
    JNZ SKIP_X_SQUARE_1
                                   ; else
; Reload X-square (x,1) and mark it as an illegal move.
    MOV A,M
    ANI $CF
    MOV M,A                        ; DISPLAY_BOARD_MOVE_ASSESSMENT(x,1) = 0
SKIP_X_SQUARE_1:
    INX H                          ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER++
    MOV A,M
    ANI $08                        ; if X-square is occupied (hi bit != 0),
    JNZ SKIP_X_SQUARE_6
                                   ; else
; Reload X-square (x,6) and mark it as an illegal move.
    MOV A,M
    ANI $F3
    MOV M,A                        ; DISPLAY_BOARD_MOVE_ASSESSMENT(x,6) = 0
SKIP_X_SQUARE_6:
    LXI H, $40A5                   ; HL = DISPLAY_BOARD_MOVE_ASSESSMENT_POINTER(6,0) = $40A5
    DCR B                          ; if --ROW_LOOP_COUNTER != 0,
    JNZ REMOVE_HIGH_RISK_FROM_ROW
                                   ; else
    RET                            ; RETURN

DRAW_HORIZONTAL_MOVE_CURSOR:
; Input:
;   HL = VRAM_HORI_CURSOR_POINTER
;   A = CURRENT_PIECE
    MVI B, $05                     ; MOVE_CURSOR_LENGTH = 5

DRAW_NEXT_HORI_PIXEL:
    MOV M,A                        ; VRAM_HORI_CURSOR(POINTER) = CURRENT_PIECE
    INR L                          ; VRAM_HORI_CURSOR_POINTER++
    DCR B                          ; if --MOVE_CURSOR_LENGTH != 0,
    JNZ DRAW_NEXT_HORI_PIXEL
                                   ; else
    RET                            ; RETURN

DRAW_VERTICAL_MOVE_CURSOR:
; Input:
;   HL = VRAM_VERT_CURSOR_POINTER
;   A = CURRENT_PIECE
    MVI B, $05                     ; MOVE_CURSOR_LENGTH = 5

DRAW_NEXT_VERT_PIXEL:
    MOV M,A                        ; VRAM_VERT_CURSOR(POINTER) = CURRENT_PIECE
    INR H                          ; VRAM_VERT_CURSOR_POINTER += #0100
    DCR B                          ; if --MOVE_CURSOR_LENGTH != 0,
    JNZ DRAW_NEXT_VERT_PIXEL
                                   ; else
    RET                            ; RETURN

PERFORM_CPU_OPENING_MOVE:
; Look up the coordinates of the selected CPU_OPENING_MOVE from the four-entry
; table and play it. All of the opening moves would be equivalent if using the
; normal MOVE_ASSESSMENT approach, so CPU_FIND_AND_PLAY_BEST_MOVE would just
; result in the same move always being selected.
;
; Instead, the PROMPT_SELECT_GAME loop supplies a pseudo-random index into the
; table, and the selected opening move is played without checking its legality.
    LDA $40FE                      ; A = CPU_OPENING_MOVE_INDEX
    LXI H, CPU_OPENING_MOVE_TABLE  ; HL = CPU_OPENING_MOVE_TABLE(0)

GET_CPU_OPENING_MOVE:
    DCR A                          ; if --CPU_OPENING_MOVE_INDEX == 0,
    JZ PLAY_OPENING_MOVE
                                   ; else
    INX H
    INX H                          ; CPU_OPENING_MOVE_TABLE(++)
    JMP GET_CPU_OPENING_MOVE

PLAY_OPENING_MOVE:
    MOV A,M
    STA $408B                      ; MOVE_COL = CPU_OPENING_MOVE_TABLE().COL
    INX H
    MOV A,M
    STA $408C                      ; MOVE_ROW = CPU_OPENING_MOVE_TABLE().ROW
    CALL PLAY_MOVE_AND_FLIP_OUTFLANKED_PIECES
    RET                            ; RETURN

INIT_GAME:
; Reset game state, clear the screen, draw the board, and place the starting
; pieces so a new game can begin.
    CALL CLEAR_WORK_RAM
    CALL CLEAR_VRAM
    CALL DRAW_GRID
    CALL ADD_STARTING_PIECES_TO_BOARDS_AND_DRAW
    RET                            ; RETURN

VERY_LOW_TONE:
; ~583 Hz tone used as pieces are counted during the SCORE_GAME routine and as
; part of the victory jingle.
    MVI B, $85                     ; TONE_COMMAND = #85, FREQUENCY_DIVISOR = low bits (5)
    JMP PLAY_TONE

LOW_TONE:
; ~700 Hz tone used every time the board flashes when a move is made and as
; part of the victory jingle.
    MVI B, $84                     ; TONE_COMMAND = #84, FREQUENCY_DIVISOR = low bits (4)
    JMP PLAY_TONE

HIGH_TONE:
; ~1167 Hz tone used every time a player presses an Arrow button and the move
; cursors move and as part of the victory jingle.
    MVI B, $82                     ; TONE_COMMAND = #82, FREQUENCY_DIVISOR = low bits (2)

PLAY_TONE:
; Writes a command sequence to the sound hardware at $8000. The ROM selects the
; pitch, and tone duration appears to be controlled by the hardware, but each
; call begins by clearing the sound state, so rapid successive calls can cut
; off earlier tones.
    LXI H, $8000
    MVI M, $00                     ; CLEAR_SOUND_STATE
    MVI M, $88                     ; START_TONE
    MVI M, $00                     ; CLEAR_SOUND_STATE
    MOV M,B                        ; SET_TONE_FREQUENCY (Mame: 3500/(FREQUENCY_DIVISOR+1))
    RET                            ; RETURN

; Piece and character graphics are stored as 5x5 and 5x6 bitmap images
; respectively. Each row of the image is stored in one byte, with the five
; most-significant bits representing the pixels from left to right.

DRAW_GAME_PIECE:
; Input:
;   A = SPACE_CONTENTS
;   HL = VRAM_POINTER
;
; Draws a 5x5 game piece image at the specified VRAM location. Blank spaces are
; rendered as an empty 5x5 image.
    PUSH B                         ; save BC
    MVI C, $05                     ; ROW_COUNTER = 5
    PUSH D                         ; save DE
    CPI $03                        ; if SPACE_CONTENTS == '+',
    JZ LOAD_WHITE_PIECE
    CPI $05                        ; else if SPACE_CONTENTS == '■',
    JZ LOAD_BLACK_PIECE
                                   ; else
    JMP LOAD_BLANK

DRAW_5x6_IMAGE:
; Input:
;   DE = FONT_TABLE_POINTER
;   HL = VRAM_POINTER
;
; Used for drawing messages and the digits in the final game score.
    MVI A, $01                     ; PIXEL_TYPE = 1
    PUSH B                         ; save BC
    PUSH D                         ; save DE
    MVI C, $06                     ; ROW_COUNTER = 6

DRAW_IMAGE:
; Input:
;   DE = IMAGE_DATA_POINTER
;   HL = VRAM_POINTER
;   C = ROW_COUNTER
;   A = PIXEL_TYPE
;
; Scans the bitmap one row at a time and expands set bits into VRAM as
; PIXEL_TYPE. Clear bits are written as 0.
;
; For example:
;   01110000 (#70)
; becomes:
;   0 PIXEL_TYPE PIXEL_TYPE PIXEL_TYPE 0
    STA $4081                      ; IMAGE_PIXEL_VALUE = PIXEL_TYPE

DRAW_NEXT_ROW:
    MVI B, $05                     ; PIXEL_COUNTER = 5
    LDAX D                         ; A = IMAGE_DATA(POINTER)
    PUSH H                         ; save VRAM_POINTER

GET_AND_DRAW_NEXT_PIXEL:
; Shift next image bit into carry, which is tested with JC.
    RAL                            ; IMAGE_DATA << 1
    PUSH PSW                       ; save IMAGE_DATA
                                   ; if IMAGE_DATA_HI_BIT == 1,
    JC USE_IMAGE_PIXEL_VALUE
                                   ; else
    MVI A, $00                     ; PIXEL_TYPE = #00

DRAW_NEXT_PIXEL:
    MOV M,A                        ; VRAM(POINTER) = PIXEL_TYPE
    POP PSW                        ; restore IMAGE_DATA
    INX H                          ; VRAM_POINTER++
    DCR B                          ; if --PIXEL_COUNTER != 0,
    JNZ GET_AND_DRAW_NEXT_PIXEL
                                   ; else
    INX D                          ; IMAGE_DATA_POINTER++
    POP H                          ; restore VRAM_POINTER
    INR H                          ; VRAM_POINTER += #0100
    DCR C                          ; if --ROW_COUNTER != 0,
    JNZ DRAW_NEXT_ROW
                                   ; else
    XRA A                          ; A = 0
    POP D                          ; restore DE
    POP B                          ; restore BC
    RET                            ; RETURN

LOAD_WHITE_PIECE:
    LXI D, PLUS_PIECE              ; IMAGE_DATA_POINTER = PLUS_PIECE
    JMP DRAW_IMAGE

LOAD_BLACK_PIECE:
    LXI D, SQUARE_PIECE            ; IMAGE_DATA_POINTER = SQUARE_PIECE
    JMP DRAW_IMAGE

USE_IMAGE_PIXEL_VALUE:
    LDA $4081                      ; PIXEL_TYPE = IMAGE_PIXEL_VALUE
    JMP DRAW_NEXT_PIXEL

LOAD_BLANK:
    LXI D, BLANK_SPACE             ; IMAGE_DATA_POINTER = BLANK_SPACE
    JMP DRAW_IMAGE

CLEAR_MESSAGE:
; Clears the 8x64 pixel message area:
; $C000-$C03F
; ...
; $C700-$C73F
;
; Sets all of the pixels in the message space to 0 (blank).
    MVI H, $C0                     ; VRAM_POINTER_HI = #C0
    MVI B, $08                     ; ROW_COUNTER = 8

CLEAR_NEXT_ROW:
    MVI L, $00                     ; VRAM_POINTER_LO = #00
    MVI C, $40                     ; COL_COUNTER = 64

CLEAR_NEXT_PIXEL:
    MVI M, $00                     ; VRAM(POINTER) = 0
    INR L                          ; VRAM_POINTER_LO++
    DCR C                          ; if --COL_COUNTER != 0,
    JNZ CLEAR_NEXT_PIXEL
                                   ; else
    INR H	                       ; VRAM_POINTER_HI++
    DCR B                          ; if --ROW_COUNTER != 0,
    JNZ CLEAR_NEXT_ROW
                                   ; else
    RET                            ; RETURN

CLEAR_AND_DRAW_MESSAGE:
    CALL CLEAR_MESSAGE

DRAW_MESSAGE:
; Looks up the supplied message by its pointer, reads it one character at a
; time. Each character is looked up in the MESSAGE_FONT_TABLE and is drawn to
; the message space. #8D is the message stop character. Once it is encountered
; in the string, this function exits.
    XTHL                           ; save HL / pop RETURN_ADDRESS
    MOV D,M                        ; D = MESSAGES_POINTER_HI
    INX H                          ; RETURN_ADDRESS++
    MOV E,M                        ; E = MESSAGES_POINTER_LO
    INX H                          ; RETURN_ADDRESS++
    XTHL                           ; push RETURN_ADDRESS / restore HL
    LXI H, $C002                   ; VRAM_POINTER = $C002

INIT_FIND_CHARACTER:
    LDAX D                         ; MESSAGE_FONT_TABLE_INDEX = MESSAGES(POINTER)
    CPI $8D                        ; if MESSAGE_FONT_TABLE_INDEX == #8D,
    RZ                             ; RETURN
                                   ; else
    PUSH D                         ; save MESSAGES_POINTER
    MOV B,A                        ; B = MESSAGE_FONT_TABLE_INDEX
    LXI D, MESSAGE_FONT_TABLE      ; MESSAGE_FONT_TABLE_POINTER = (0)

FIND_CHARACTER_BY_INDEX:
    DCR B                          ; if --MESSAGE_FONT_TABLE_INDEX < 0,
    JM DRAW_CHARACTER
                                   ; else
    INX D
    INX D
    INX D
    INX D
    INX D
    INX D                          ; MESSAGE_FONT_TABLE_POINTER += #06 (++)
    JMP FIND_CHARACTER_BY_INDEX

DRAW_CHARACTER:
; After the character is drawn, the VRAM_POINTER is advanced 5 pixels to the
; right. This localization uses narrower English glyphs with built-in blank
; rows/columns, so no extra column between characters is needed.
;
; The original ROM advanced by 6 pixels because the Japanese glyphs used the
; full 5x7 bitmap width. Reducing the spacing increases the maximum message
; length from 10 to 12 characters.
    PUSH H                         ; save VRAM_POINTER
    CALL DRAW_5x6_IMAGE
    POP H                          ; restore VRAM_POINTER
    INX H
    INX H
    INX H
    INX H
    INX H                          ; VRAM_POINTER += 6
    POP D                          ; restore MESSAGES_POINTER
    INX D                          ; MESSAGES_POINTER++
    JMP INIT_FIND_CHARACTER

DIGIT_FONT_TABLE:
; Used when displaying the final score. This localization uses narrower glyphs
; to match the look and feel of the updated English message font.
; 0
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 1
    DB $20                         ; ----xx----
    DB $60                         ; --xxxx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $70                         ; --xxxxxx--

; 2
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $10                         ; ------xx--
    DB $20                         ; ----xx----
    DB $40                         ; --xx------
    DB $F0                         ; xxxxxxxx--

; 3
    DB $F0                         ; xxxxxxxx--
    DB $10                         ; ------xx--
    DB $60                         ; --xxxx----
    DB $10                         ; ------xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 4
    DB $20                         ; ----xx----
    DB $60                         ; --xxxx----
    DB $A0                         ; xx--xx----
    DB $F0                         ; xxxxxxxx--
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----

; 5
    DB $F0                         ; xxxxxxxx--
    DB $80                         ; xx--------
    DB $E0                         ; xxxxxx----
    DB $10                         ; ------xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 6
    DB $60                         ; --xxxx----
    DB $80                         ; xx--------
    DB $E0                         ; xxxxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 7
    DB $F0                         ; xxxxxxxx--
    DB $10                         ; ------xx--
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $40                         ; --xx------
    DB $40                         ; --xx------

; 8
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 9
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $70                         ; --xxxxxx--
    DB $10                         ; ------xx--
    DB $60                         ; --xxxx----

SCORE_GAME:
; Clears the message area, the move cursors, and the ANALYSIS_BOARD before
; making a three-pass scoring loop.
;
; Pass 1 scans the DISPLAY_BOARD for P2's pieces. Each such piece increments
; P2's score and is copied into the ANALYSIS_BOARD, filling spaces from
; upper-left to lower-right.
;
; Pass 2 scans for blank spaces and copies them into the next available
; ANALYSIS_BOARD spaces.
;
; Pass 3 scans for P1's pieces. Each such piece increments P1's score and is
; copied into the next available ANALYSIS_BOARD space.
;
; As a result, the ANALYSIS_BOARD ends up sorted into P2's pieces, then blanks,
; then P1's pieces.
;
; Each space drawn to the ANALYSIS_BOARD, including blanks, is accompanied by
; the VERY_LOW_TONE.
;
; The final scores are displayed in the message area and a winner is
; determined.
    CALL CLEAR_MESSAGE
    CALL CLEAR_MOVE_CURSORS
    CALL CLEAR_TURN_INDICATORS
    XRA A
    STA $4082                      ; P1_COUNT = 0
    XRA A
    STA $4083                      ; P2_COUNT = 0
    LXI H, $4040                   ; ANALYSIS_BOARD_POINTER = $4040
    MVI B, $40                     ; SPACE_LOOP_COUNTER = 64

CLEAR_NEXT_SPACE:
    MVI M, $00                     ; ANALYSIS_BOARD(POINTER) = BLANK (#00)
    INX H                          ; ANALYSIS_BOARD_POINTER++
    DCR B                          ; if --SPACE_LOOP_COUNTER != 0,
    JNZ CLEAR_NEXT_SPACE
                                   ; else
    CALL DRAW_ANALYSIS_BOARD
    LXI D, $4040                   ; ANALYSIS_BOARD_POINTER = $4040
; Selects what this pass is looking for:
;   3 = P2, 2 = Blanks, 1 = P1, 0 = done
    MVI C, $03                     ; SCORING_PASS_COUNTER = 3

START_SCORING_PASS:
    LXI H, $4000                   ; DISPLAY_BOARD_POINTER = $4000
    MVI B, $40                     ; SPACE_LOOP_COUNTER = 64

SCORE_NEXT_SPACE:
    MOV A,C
    CPI $03                        ; if SCORING_PASS_COUNTER == 3,
    JZ SCORE_P2
    CPI $02                        ; else if SCORING_PASS_COUNTER == 2,
    JZ SCORE_BLANK
    CPI $01                        ; else if SCORING_PASS_COUNTER == 1,
    JZ SCORE_P1
                                   ; else
    CALL DRAW_SCORES
    CALL CHECK_PLAYER_WIN
    RET                            ; RETURN

SCORE_P2:
    LDA $40FB
    XRI $06                        ; PIECE_TYPE = P2_PIECE
    CMP M                          ; if DISPLAY_BOARD(POINTER) != P2_PIECE,
    JNZ GET_NEXT_SCORE_SPACE
                                   ; else
    PUSH PSW                       ; save PIECE_TYPE
    LDA $4083                      ; A = P2_COUNT
    CALL INC_DECIMAL_COUNTER
    STA $4083                      ; P2_COUNT = A
    JMP WRITE_PIECE_TO_ANALYSIS_BOARD

SCORE_BLANK:
    XRA A
    CMP M                          ; if DISPLAY_BOARD(POINTER) != BLANK,
    JNZ GET_NEXT_SCORE_SPACE
                                   ; else
    PUSH PSW                       ; save PIECE_TYPE
    JMP WRITE_PIECE_TO_ANALYSIS_BOARD

SCORE_P1:
    LDA $40FB                      ; PIECE_TYPE = P1_PIECE
    CMP M                          ; if DISPLAY_BOARD(POINTER) != P1_PIECE,
    JNZ GET_NEXT_SCORE_SPACE
                                   ; else
    PUSH PSW                       ; save PIECE_TYPE
    LDA $4082                      ; A = P1_COUNT
    CALL INC_DECIMAL_COUNTER
    STA $4082                      ; P1_COUNT = A

WRITE_PIECE_TO_ANALYSIS_BOARD:
; Write the scored piece to the next position in the ANALYSIS_BOARD, redraw
; that board, and play VERY_LOW_TONE.
    POP PSW                        ; restore PIECE_TYPE
    STAX D                         ; ANALYSIS_BOARD(POINTER) = PIECE_TYPE
    INX D                          ; ANALYSIS_BOARD_POINTER++
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
    INX H                          ; DISPLAY_BOARD_POINTER++
    DCR B                          ; if --SPACE_LOOP_COUNTER != 0,
    JNZ SCORE_NEXT_SPACE
                                   ; else
    DCR C                          ; SCORING_PASS_COUNTER--
    JMP START_SCORING_PASS

DRAW_SCORES:
; Draw the white ('+') and black ('■') pieces in the message space, then draw
; their two-digit BCD counts beside them.
    LDA $40FB                      ; SPACE_CONTENTS = P1_PIECE
    LXI H, $C208                   ; VRAM_POINTER = $C208
    CALL DRAW_GAME_PIECE
    LDA $40FB
    XRI $06                        ; SPACE_CONTENTS = P2_PIECE
    LXI H, $C226                   ; VRAM_POINTER = $C226
    CALL DRAW_GAME_PIECE
    MVI C, $02                     ; SCORE_COUNTER = 2
    LDA $4082                      ; A = P1_COUNT
    LXI H, $C10E                   ; VRAM_POINTER = $C10E

DRAW_ONE_SCORE:
    MOV B,A                        ; B = P1|P2_COUNT
    ANI $F0                        ; A = P1|P2_COUNT_TENS
    RRC
    RRC
    RRC
    RRC                            ; P1|P2_COUNT_TENS >> 4
    CALL LOOKUP_DIGIT_IMAGE
    PUSH H                         ; save VRAM_POINTER
    CALL DRAW_5x6_IMAGE
; Advance 5 pixels to the next digit. The localized digit font has built-in
; spacing, matching the updated message font.
;
; The original ROM advanced by 6 pixels because the original digits used the
; full 5x7 bitmap width.
    POP H                          ; restore VRAM_POINTER
    INX H
    INX H
    INX H
    INX H
    INX H                          ; VRAM_POINTER += 5
    MOV A,B                        ; A = P1|P2_COUNT
    ANI $0F                        ; A = P1|P2_COUNT_ONES
    CALL LOOKUP_DIGIT_IMAGE
    PUSH H                         ; save VRAM_POINTER
    CALL DRAW_5x6_IMAGE
    POP H                          ; restore VRAM_POINTER
    DCR C                          ; if --SCORE_COUNTER == 0,
    RZ                             ; RETURN
                                   ; else
    LXI H, $C12C                   ; VRAM_POINTER = $C12C
    LDA $4083                      ; A = P2_COUNT
    JMP DRAW_ONE_SCORE

LOOKUP_DIGIT_IMAGE:
; Input:
;   A = DIGIT_FONT_TABLE_INDEX
; Output:
;   DE = DIGIT_FONT_TABLE_POINTER
    LXI D, DIGIT_FONT_TABLE        ; DIGIT_FONT_TABLE_POINTER = (0)

FIND_DIGIT_BY_INDEX:
; Digit 0 returns the initial table pointer.
    DCR A
    CPI $FF                        ; if --DIGIT_FONT_TABLE_INDEX == #FF,
    RZ                             ; RETURN
                                   ; else
    PUSH PSW                       ; save DIGIT_FONT_TABLE_INDEX
    INX D
    INX D
    INX D
    INX D
    INX D
    INX D                          ; DIGIT_FONT_TABLE_POINTER += 6 (++)
    POP PSW                        ; restore DIGIT_FONT_TABLE_INDEX
    JMP FIND_DIGIT_BY_INDEX

DRAW_TURN_INDICATOR:
; Blanks out the previous side marker, then draws a black ('■') or white ('+')
; piece beside the board to show the active side.
;
; The markers are outside the move cursor track. The 1P indicator is drawn near
; the 1P controls and the 2P indicator is drawn near the 2P controls.
;
; In 1-player games, only the 1P indicator is displayed, and not during the
; CPU's turns.
    LDA $40FC
    ORA A                          ; if ACTIVE_PLAYER_SIDE == 1 (P2),
    JNZ DRAW_P2_INDICATOR
                                   ; else
    XRA A                          ; SPACE_CONTENTS = BLANK
    LXI H, $CA00                   ; VRAM_POINTER = $CA00 (P2_TURN_INDICATOR)
    CALL DRAW_GAME_PIECE
    LXI H, $F800                   ; VRAM_POINTER = $F800 (P1_TURN_INDICATOR)
    JMP DRAW_INDICATOR

DRAW_P2_INDICATOR:
    XRA A                          ; SPACE_CONTENTS = BLANK
    LXI H, $F800                   ; VRAM_POINTER = $F800 (P1_TURN_INDICATOR)
    CALL DRAW_GAME_PIECE
    LDA $40FF
    CPI $01                        ; if NUM_PLAYERS == 1,
    RZ                             ; RETURN
                                   ; else
    LXI H, $CA00                   ; VRAM_POINTER = $CA00 (P2_TURN_INDICATOR)

DRAW_INDICATOR:
    LDA $408A                      ; SPACE_CONTENTS = CURRENT_PIECE
    CALL DRAW_GAME_PIECE
    RET                            ; RETURN

CLEAR_TURN_INDICATORS:
    XRA A                          ; SPACE_CONTENTS = BLANK
    LXI H, $F800                   ; VRAM_POINTER = $F800 (P1_TURN_INDICATOR)
    CALL DRAW_GAME_PIECE
    LXI H, $CA00                   ; VRAM_POINTER = $CA00 (P2_TURN_INDICATOR)
    CALL DRAW_GAME_PIECE
    RET                            ; RETURN

INC_DECIMAL_COUNTER:
; Input:
;   A = P1_COUNT|P2_COUNT
; Output:
;   A++
;
; Increments a BCD value while scoring the game.
    STC                            ; set carry bit
    CMC                            ; clear carry bit
    ADI $01                        ; P1|P2_COUNT++
    DAA                            ; make decimal adjustment to P1|P2_COUNT
    RET                            ; RETURN

MESSAGE_FONT_TABLE:
; In this localization, the English glyphs are adapted from the public-domain
; 5x7 -misc-fixed- font distributed with Markus Kuhn's UCS fonts.
; 00 = A
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $F0                         ; xxxxxxxx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--

; 01 = C
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $80                         ; xx--------
    DB $80                         ; xx--------
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 02 = D
    DB $E0                         ; xxxxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $E0                         ; xxxxxx----

; 03 = E
    DB $F0                         ; xxxxxxxx--
    DB $80                         ; xx--------
    DB $E0                         ; xxxxxx----
    DB $80                         ; xx--------
    DB $80                         ; xx--------
    DB $F0                         ; xxxxxxxx--

; 04 = G
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $80                         ; xx--------
    DB $B0                         ; xx--xxxx--
    DB $90                         ; xx----xx--
    DB $70                         ; --xxxxxx--

; 05 = H
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $F0                         ; xxxxxxxx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--

; 06 = I
    DB $70                         ; --xxxxxx--
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $70                         ; --xxxxxx--

; 07 = J
    DB $10                         ; ------xx--
    DB $10                         ; ------xx--
    DB $10                         ; ------xx--
    DB $10                         ; ------xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 08 = K
    DB $90                         ; xx----xx--
    DB $A0                         ; xx--xx----
    DB $C0                         ; xxxx------
    DB $C0                         ; xxxx------
    DB $A0                         ; xx--xx----
    DB $90                         ; xx----xx--

; 09 = L
    DB $80                         ; xx--------
    DB $80                         ; xx--------
    DB $80                         ; xx--------
    DB $80                         ; xx--------
    DB $80                         ; xx--------
    DB $F0                         ; xxxxxxxx--

; 0A = M
    DB $90                         ; xx----xx--
    DB $F0                         ; xxxxxxxx--
    DB $F0                         ; xxxxxxxx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--

; 0B = N
    DB $90                         ; xx----xx--
    DB $D0                         ; xxxx--xx--
    DB $D0                         ; xxxx--xx--
    DB $B0                         ; xx--xxxx--
    DB $B0                         ; xx--xxxx--
    DB $90                         ; xx----xx--

; 0C = O
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 0D = P
    DB $E0                         ; xxxxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $E0                         ; xxxxxx----
    DB $80                         ; xx--------
    DB $80                         ; xx--------

; 0E = R
    DB $E0                         ; xxxxxx----
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $E0                         ; xxxxxx----
    DB $A0                         ; xx--xx----
    DB $90                         ; xx----xx--

; 0F = S
    DB $60                         ; --xxxx----
    DB $90                         ; xx----xx--
    DB $40                         ; --xx------
    DB $20                         ; ----xx----
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 10 = T
    DB $70                         ; --xxxxxx--
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----

; 11 = U
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----

; 12 = V
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $90                         ; xx----xx--
    DB $60                         ; --xxxx----
    DB $60                         ; --xxxx----

; 13 = Y
    DB $50                         ; --xx--xx--
    DB $50                         ; --xx--xx--
    DB $50                         ; --xx--xx--
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----
    DB $20                         ; ----xx----

; 14 = ' '
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------
    DB $00                         ; ----------

; 15 = ?
    DB $20                         ; ----xx----
    DB $50                         ; --xx--xx--
    DB $10                         ; ------xx--
    DB $20                         ; ----xx----
    DB $00                         ; ----------
    DB $20                         ; ----xx----

CHECK_PLAYER_WIN:
; In 1-player games, checks whether 1P defeated the CPU. If so, play the
; victory jingle. Ties, CPU wins, and all 2-player games return without playing
; anything.
;
; A QoL update reduces the duration of the victory jingle from ~9 seconds to ~3
; seconds.
    LDA $40FF
    CPI $01                        ; if NUM_PLAYERS == 1,
    JZ WIN_CHECK
                                   ; else
    RET                            ; RETURN

WIN_CHECK:
    LDA $4083
    MOV B,A                        ; B = P2_COUNT (CPU_COUNT)
    LDA $4082                      ; A = P1_COUNT (HUMAN_COUNT)
    SUB B                          ; if HUMAN_COUNT == CPU_COUNT,
    RZ                             ; RETURN
                                   ; else if HUMAN_COUNT < CPU_COUNT,
    RM                             ; RETURN
                                   ; else
    MVI D, $10                     ; JINGLE_LOOP_COUNTER = 16

PLAY_TONES:
; All three tones are used. PLAY_TONE is called every ~60ms, so each new tone
; likely cuts off the previous one before its natural hardware-controlled
; duration ends.
    CALL VERY_LOW_TONE
    CALL DOUBLE_DELAY              ; [60ms]
    CALL LOW_TONE
    CALL DOUBLE_DELAY              ; [60ms]
    CALL HIGH_TONE
    CALL DOUBLE_DELAY              ; [60ms]
    DCR D                          ; if --JINGLE_LOOP_COUNTER != 0,
    JNZ PLAY_TONES

    RET                            ; RETURN
