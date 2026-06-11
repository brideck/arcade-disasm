cothello-disasm-QoL introduces a number of improvements, fixes, and optimizations to the code.

Quality-of-Life Improvements
----------------------------
The prompts for Judge and Reset have been removed when a game is completed. The game detects when it's in the appropriate state for either action and automatically triggers it after a wait of appropriate length.

Prompts to confirm pressing Judge and Reset while a game is in progress have been added. This is to prevent a player from accidentally ending their game unexpectedly.

The "PRESS PASS" prompt no longer flickers, but just stays visible until the button is pressed. The text of the prompt has been updated to "MUST PASS."

Added an informative "MUST PLAY" message that is displayed when a player presses the Pass button in a situation where they have a legal move they can play.

Added an informative "ILLEGAL MOVE" message that is displayed when a player presses the Set button while the move cursors are marking a space where they aren't allowed to play a piece.

Updated the blinking cadence of the "INSERT COIN" message when time has expired to a more even on/off pattern.

Completed games no longer enter the continue screen if the timer expires while scoring is in progress. After the final score is displayed, the machine waits 6 seconds and automatically resets.

Once the board is full, the game automatically ends and the scoring routine is called. This used to take 2-3 button presses to Pass turns and press Judge.

Reduced the victory jingle from 9 seconds to 3 seconds.


ROM Optimizations
-----------------
Removed redundant GAME_SCORED_FLAG check from the player input loop.

Removed SHORT_DELAY as it is no longer used.

Removed unused code from the CPU's move selection routine.

Removed unused stored value for NUM_OUTFLANKED_PIECES.

Removed unused inline variable from DRAW_MESSAGE calls.
