# Simon Says - Ladder Logic Implementation for Omron NX102-1100
## Phase 1: Minimal Core (3 Buttons)

---

## Hardware Configuration

### PLC System
- **CPU**: Omron NX102-1100 (NX1 Series)
- **Digital Input Module**: NX-ID4442 (64 channels)
- **Digital Output Module**: NX-OD4256 (32 channels)
- **Power Supply**: RS PRO LI60-20B24PR2 (24V DC, 2.5A)

### Button I/O Mapping (Phase 1)

| Button | Color  | Contact Input | LED Output | Wire Pinout                    |
|--------|--------|---------------|------------|--------------------------------|
| BTN_Y  | Yellow | DI1           | DO2        | Pin1→+24V, Pin2→DO2, Pin3→0V, Pin4→DI1 |
| BTN_B  | Blue   | DI3           | DO1        | Pin1→+24V, Pin2→DO1, Pin3→0V, Pin4→DI3 |
| BTN_R  | Red    | DI5           | DO0        | Pin1→+24V, Pin2→DO0, Pin3→0V, Pin4→DI5 |

### Control Inputs
- **Start Button**: Selector switch position (e.g., DI10)

---

## I/O Address Assignments

### Digital Inputs (NX-ID4442)
```
DI1  - Yellow Button Contact
DI3  - Blue Button Contact  
DI5  - Red Button Contact
DI10 - Start/Game Mode Selector
```

### Digital Outputs (NX-OD4256)
```
DO0 - Red LED
DO1 - Blue LED
DO2 - Yellow LED
```

---

## Game Logic Overview

### State Machine
The game operates in 4 main states:

1. **IDLE** (State = 0)
   - Waiting for start button press
   - All LEDs off or in attract mode
   - Reset game variables

2. **PLAYBACK** (State = 1)
   - Display the current sequence to player
   - Flash each LED in order with timing
   - No button input accepted

3. **WAIT_INPUT** (State = 2)
   - Wait for player to repeat the sequence
   - Validate each button press
   - Track current position in sequence

4. **GAME_OVER** (State = 3)
   - All LEDs flash on error
   - Display score/level
   - Return to IDLE after timeout

---

## Memory Allocation

### Boolean Variables
```
bGameActive          - Game is running
bStartPressed        - Rising edge of start button
bButtonY_Pressed     - Yellow button pressed (rising edge)
bButtonB_Pressed     - Blue button pressed (rising edge)
bButtonR_Pressed     - Red button pressed (rising edge)
bPlaybackActive      - Currently playing back sequence
bWaitingForInput     - Waiting for player input
bCorrectInput        - Last input was correct
bGameOver            - Game ended (win or lose)
bSequenceComplete    - Player completed current sequence
```

### Integer Variables
```
iGameState           - Current state (0-3)
iSequenceLength      - Current sequence length (1-100)
iPlaybackIndex       - Current position during playback (0-based)
iInputIndex          - Current position during input (0-based)
iCurrentButton       - Current button being shown/expected (1=Y, 2=B, 3=R)
iPlayerInput         - Button pressed by player (1=Y, 2=B, 3=R)
iLevel               - Current game level (starts at 1)
iRandomSeed          - Seed for pseudo-random generation
```

### Timer Variables
```
tFlashTimer          - LED flash duration (e.g., 500ms)
tGapTimer            - Gap between LED flashes (e.g., 200ms)
tInputTimeout        - Time allowed for player input (e.g., 3000ms)
tGameOverTimer       - Display game over before reset (e.g., 3000ms)
```

### Array Variables
```
aiSequence[100]      - Stores the sequence (1=Y, 2=B, 3=R)
                       Each element holds which button to press
```

### Constants
```
FLASH_TIME = 500     - LED on duration (ms)
GAP_TIME = 200       - Delay between flashes (ms)
INPUT_TIMEOUT = 3000 - Max time per button press (ms)
MAX_SEQUENCE = 100   - Maximum sequence length
NUM_BUTTONS = 3      - Number of buttons in Phase 1
```

---

## Ladder Logic Implementation

### Section 1: Initialization & Input Conditioning

**Rung 1-3: Button Edge Detection**
```
Purpose: Detect rising edge of button presses
- Use rising edge detection on DI1, DI3, DI5
- Set bButtonY_Pressed, bButtonB_Pressed, bButtonR_Pressed for one scan
- Clear after one scan to ensure single detection
```

**Ladder Logic:**
```
[DI1]--[DIFU]--( bButtonY_Pressed )
[DI3]--[DIFU]--( bButtonB_Pressed )
[DI5]--[DIFU]--( bButtonR_Pressed )
```

**Rung 4: Start Button Edge Detection**
```
[DI10]--[DIFU]--( bStartPressed )
```

---

### Section 2: Game State Machine

**Rung 10: IDLE State - Initialize Game**
```
Purpose: When start pressed in IDLE, initialize and move to PLAYBACK
Condition: iGameState = 0 AND bStartPressed
Action:
  - Reset iSequenceLength to 0
  - Reset iLevel to 1
  - Reset iPlaybackIndex to 0
  - Reset iInputIndex to 0
  - Set iGameState = 1 (PLAYBACK)
  - Set bGameActive = TRUE
```

**Ladder Logic:**
```
[iGameState = 0]--[bStartPressed]--[MOV 0 iSequenceLength]
                                   [MOV 1 iLevel]
                                   [MOV 0 iPlaybackIndex]
                                   [MOV 0 iInputIndex]
                                   [MOV 1 iGameState]
                                   ( bGameActive )
```

---

**Rung 11: Add New Step to Sequence**
```
Purpose: At start of PLAYBACK state, add one random button to sequence
Condition: iGameState = 1 AND iPlaybackIndex = 0 AND NOT bPlaybackActive
Action:
  - Generate random number 1-3 using pseudo-random algorithm
  - Store in aiSequence[iSequenceLength]
  - Increment iSequenceLength
  - Set bPlaybackActive = TRUE
```

**Pseudo-Random Generation (Linear Congruential Generator):**
```
iRandomSeed = (iRandomSeed * 214013 + 2531011) MOD 65536
iCurrentButton = (iRandomSeed MOD 3) + 1
aiSequence[iSequenceLength] = iCurrentButton
iSequenceLength = iSequenceLength + 1
```

**Ladder Logic:**
```
[iGameState = 1]--[iPlaybackIndex = 0]--[NOT bPlaybackActive]--[COMPUTE]
                                                                 iRandomSeed := (iRandomSeed * 214013 + 2531011) MOD 65536
                                                                 iCurrentButton := (iRandomSeed MOD 3) + 1
                                                                 aiSequence[iSequenceLength] := iCurrentButton
                                                                 iSequenceLength := iSequenceLength + 1
                                                                 ( bPlaybackActive )
```

---

### Section 3: Playback Logic

**Rung 20: Start Playback Flash**
```
Purpose: Flash LED for current sequence position
Condition: iGameState = 1 AND iPlaybackIndex < iSequenceLength AND tFlashTimer.DN = FALSE
Action:
  - Load aiSequence[iPlaybackIndex] into iCurrentButton
  - Turn on corresponding LED
  - Start tFlashTimer (FLASH_TIME ms)
```

**Ladder Logic:**
```
[iGameState = 1]--[iPlaybackIndex < iSequenceLength]--[NOT tFlashTimer.TT]--[MOV aiSequence[iPlaybackIndex] iCurrentButton]
                                                                             [TON tFlashTimer FLASH_TIME]
```

**Rung 21-23: LED Control During Playback**
```
Purpose: Turn on LED based on iCurrentButton during playback
Condition: bPlaybackActive AND tFlashTimer.TT AND NOT tFlashTimer.DN

Rung 21: Yellow LED (DO2)
[bPlaybackActive]--[iCurrentButton = 1]--[tFlashTimer.TT]--( DO2 )

Rung 22: Blue LED (DO1)
[bPlaybackActive]--[iCurrentButton = 2]--[tFlashTimer.TT]--( DO1 )

Rung 23: Red LED (DO0)
[bPlaybackActive]--[iCurrentButton = 3]--[tFlashTimer.TT]--( DO0 )
```

**Rung 24: End Flash, Start Gap**
```
Purpose: When flash timer done, turn off LED and start gap timer
Condition: tFlashTimer.DN
Action:
  - Turn off all LEDs
  - Start tGapTimer (GAP_TIME ms)
  - Reset tFlashTimer
```

**Ladder Logic:**
```
[tFlashTimer.DN]--[TON tGapTimer GAP_TIME]
                  [RESET tFlashTimer]
```

**Rung 25: Advance Playback Index**
```
Purpose: After gap, move to next sequence position
Condition: tGapTimer.DN
Action:
  - Increment iPlaybackIndex
  - Reset tGapTimer
```

**Ladder Logic:**
```
[tGapTimer.DN]--[ADD iPlaybackIndex 1 iPlaybackIndex]
                [RESET tGapTimer]
```

**Rung 26: Playback Complete**
```
Purpose: When entire sequence shown, switch to WAIT_INPUT state
Condition: iGameState = 1 AND iPlaybackIndex >= iSequenceLength
Action:
  - Set iGameState = 2 (WAIT_INPUT)
  - Reset iInputIndex to 0
  - Set bPlaybackActive = FALSE
  - Start tInputTimeout timer
```

**Ladder Logic:**
```
[iGameState = 1]--[iPlaybackIndex >= iSequenceLength]--[MOV 2 iGameState]
                                                        [MOV 0 iInputIndex]
                                                        [RESET bPlaybackActive]
                                                        [TON tInputTimeout INPUT_TIMEOUT]
```

---

### Section 4: Player Input Logic

**Rung 30: Capture Player Input**
```
Purpose: Determine which button player pressed
Condition: iGameState = 2 (WAIT_INPUT)
Action: Set iPlayerInput based on button pressed
```

**Ladder Logic:**
```
Rung 30a: Yellow pressed
[iGameState = 2]--[bButtonY_Pressed]--[MOV 1 iPlayerInput]

Rung 30b: Blue pressed
[iGameState = 2]--[bButtonB_Pressed]--[MOV 2 iPlayerInput]

Rung 30c: Red pressed
[iGameState = 2]--[bButtonR_Pressed]--[MOV 3 iPlayerInput]
```

**Rung 31: LED Feedback on Button Press**
```
Purpose: Light up LED briefly when player presses button
Condition: iPlayerInput > 0
Action: Turn on corresponding LED for brief moment
```

**Ladder Logic:**
```
Rung 31a: Yellow feedback
[iGameState = 2]--[iPlayerInput = 1]--[DI1]--( DO2 )

Rung 31b: Blue feedback
[iGameState = 2]--[iPlayerInput = 2]--[DI3]--( DO1 )

Rung 31c: Red feedback
[iGameState = 2]--[iPlayerInput = 3]--[DI5]--( DO0 )
```

**Rung 35: Validate Input**
```
Purpose: Check if player input matches sequence
Condition: iGameState = 2 AND iPlayerInput > 0
Action:
  - Compare iPlayerInput with aiSequence[iInputIndex]
  - If match: increment iInputIndex, reset timeout
  - If no match: set iGameState = 3 (GAME_OVER)
```

**Ladder Logic:**
```
Rung 35a: Correct input
[iGameState = 2]--[iPlayerInput > 0]--[iPlayerInput = aiSequence[iInputIndex]]--[ADD iInputIndex 1 iInputIndex]
                                                                                  [MOV 0 iPlayerInput]
                                                                                  [RESET tInputTimeout]
                                                                                  [TON tInputTimeout INPUT_TIMEOUT]

Rung 35b: Wrong input
[iGameState = 2]--[iPlayerInput > 0]--[iPlayerInput <> aiSequence[iInputIndex]]--[MOV 3 iGameState]
                                                                                   [MOV 0 iPlayerInput]
                                                                                   [RESET bGameActive]
```

**Rung 36: Input Timeout**
```
Purpose: If player takes too long, end game
Condition: iGameState = 2 AND tInputTimeout.DN
Action: Set iGameState = 3 (GAME_OVER)
```

**Ladder Logic:**
```
[iGameState = 2]--[tInputTimeout.DN]--[MOV 3 iGameState]
                                      [RESET bGameActive]
```

**Rung 37: Sequence Complete**
```
Purpose: Player successfully completed current sequence
Condition: iGameState = 2 AND iInputIndex >= iSequenceLength
Action:
  - Increment iLevel
  - Set iGameState = 1 (PLAYBACK) for next round
  - Reset iPlaybackIndex
```

**Ladder Logic:**
```
[iGameState = 2]--[iInputIndex >= iSequenceLength]--[ADD iLevel 1 iLevel]
                                                     [MOV 1 iGameState]
                                                     [MOV 0 iPlaybackIndex]
                                                     [RESET tInputTimeout]
```

---

### Section 5: Game Over State

**Rung 40: Game Over LED Flash**
```
Purpose: Flash all LEDs on game over
Condition: iGameState = 3
Action: Flash all LEDs together 3-4 times
```

**Ladder Logic (using oscillator):**
```
[iGameState = 3]--[CLOCK 250ms]--( DO0 )
                                 ( DO1 )
                                 ( DO2 )
```

**Rung 41: Return to IDLE**
```
Purpose: After game over display, return to idle
Condition: iGameState = 3 AND tGameOverTimer.DN
Action:
  - Set iGameState = 0 (IDLE)
  - Reset all variables
```

**Ladder Logic:**
```
[iGameState = 3]--[TON tGameOverTimer 3000]

[tGameOverTimer.DN]--[MOV 0 iGameState]
                     [MOV 0 iSequenceLength]
                     [MOV 0 iLevel]
                     [RESET tGameOverTimer]
                     [RESET bGameActive]
```

---

## Implementation Notes

### Sysmac Studio Setup

1. **Create New Project**
   - Select NX102-1100 CPU
   - Add NX-ID4442 and NX-OD4256 modules

2. **Configure I/O**
   - Map physical inputs/outputs to memory addresses
   - Verify module placement in rack configuration

3. **Create Program Organization**
   ```
   Main Program (PLC_PRG)
   ├── Section 1: Input Conditioning
   ├── Section 2: State Machine
   ├── Section 3: Playback Logic
   ├── Section 4: Input Validation
   └── Section 5: Game Over
   ```

4. **Variable Declaration**
   - Create global variable list (GVL)
   - Define all booleans, integers, timers, arrays

5. **Timer Setup**
   - Use TON (On-Delay Timer) function blocks
   - Configure preset values in milliseconds

### Testing Procedure

**Phase 1 Testing:**
1. Test individual button inputs (verify DI readings)
2. Test individual LED outputs (manually set DO)
3. Test edge detection (press/release buttons)
4. Test state transitions (IDLE → PLAYBACK → WAIT_INPUT)
5. Test sequence generation (verify array contents)
6. Test playback (observe LED sequence)
7. Test correct input handling
8. Test wrong input detection
9. Test timeout functionality
10. Test game over and reset

### Debug Tips

- **Monitor Variables**: Use online mode to watch:
  - `iGameState` (should transition 0→1→2→3→0)
  - `iSequenceLength` (increments each level)
  - `aiSequence[]` array values
  - `iPlaybackIndex` and `iInputIndex`

- **LED Issues**: If LEDs don't light:
  - Check DO addresses match wiring
  - Verify 24V power supply to LED pins
  - Check LED ground connections

- **Input Issues**: If buttons don't register:
  - Verify DI wiring (Pin 4 to input, Pin 1 to +24V)
  - Check input filtering settings
  - Test with forced inputs in Sysmac Studio

- **Timing Issues**: Adjust timers if needed:
  - Increase FLASH_TIME if LEDs too brief
  - Increase INPUT_TIMEOUT for easier gameplay
  - Adjust GAP_TIME for better visual separation

---

## Phase 2 & 3 Expansion Preview

### Phase 2 Changes (4th Button - White)
```
Additional I/O:
- DI7: White button contact
- DO3: White LED

Modified Constants:
- NUM_BUTTONS = 4 (when in 4-button mode)

Mode Selection (3-position selector):
- DI11: 3-button mode
- DI12: 4-button mode
- If DI11: use buttons 1-3 only
- If DI12: use buttons 1-4
```

### Phase 3 Changes (Difficulty Selector)
```
Additional I/O (8-position selector):
- DI20-DI22: Binary encoded position (0-7)

Difficulty Mapping:
- Position 0: FLASH_TIME=800ms, INPUT_TIMEOUT=5000ms
- Position 1: FLASH_TIME=600ms, INPUT_TIMEOUT=4000ms
- Position 2: FLASH_TIME=400ms, INPUT_TIMEOUT=3000ms
- Position 3-7: Custom difficulty curves

Implementation:
- Read binary value from DI20-22
- Use lookup table or CASE statement
- Apply timing adjustments before each round
```

---

## Ladder Logic Symbol Summary

| Symbol | Meaning |
|--------|---------|
| `[ ]`  | Normally open contact (examine if ON) |
| `[/]`  | Normally closed contact (examine if OFF) |
| `( )`  | Output coil (energize) |
| `[DIFU]` | Differentiate Up (rising edge) |
| `[DIFD]` | Differentiate Down (falling edge) |
| `[MOV]` | Move value |
| `[ADD]` | Addition |
| `[SUB]` | Subtraction |
| `[MUL]` | Multiplication |
| `[DIV]` | Division |
| `[MOD]` | Modulo |
| `[TON]` | On-Delay Timer |
| `[RESET]` | Reset timer/counter |
| `[COMPUTE]` | Complex calculation |
| `[CASE]` | Case/Switch statement |

---

## Quick Reference Card

**Game Flow:**
```
IDLE → Start Pressed → PLAYBACK → Show Sequence → WAIT_INPUT → 
Player Input → Correct? → Yes → Next Level (back to PLAYBACK)
                      → No → GAME_OVER → Return to IDLE
```

**Button Mapping:**
- Yellow = 1
- Blue = 2  
- Red = 3
- (White = 4 in Phase 2)

**State Values:**
- 0 = IDLE
- 1 = PLAYBACK
- 2 = WAIT_INPUT
- 3 = GAME_OVER

**Critical Timers:**
- `tFlashTimer`: LED on duration
- `tGapTimer`: Delay between LEDs
- `tInputTimeout`: Player response time
- `tGameOverTimer`: Game over display time

---

## File Structure for Sysmac Studio

```
SimonSays_NX102/
├── Project.yml
├── Programs/
│   ├── PLC_PRG (Main Program)
│   ├── FB_ButtonEdgeDetect (Function Block)
│   └── FB_RandomGenerator (Function Block)
├── GlobalVariableLists/
│   ├── GVL_GameState
│   ├── GVL_IO_Mapping
│   └── GVL_Constants
└── DataTypes/
    └── TYPE_GameState (ENUM)
```

---

## Safety Considerations

⚠️ **Important Safety Notes:**
- Ensure proper earth bonding (PE) on all equipment
- Verify 24V DC supply is properly fused
- Test emergency stop functionality
- Do not modify wiring while power is on
- Follow proper lockout/tagout procedures
- This is a demonstration project - adapt for industrial use

---

## Contact & Support

**Hardware Datasheets:**
- Omron NX102-1100: [Omron NX1 Series Manual]
- NX-ID4442: Digital Input Unit Manual
- NX-OD4256: Digital Output Unit Manual
- RAFI RAMO 22 T: Illuminated Pushbutton Datasheet

**Software:**
- Sysmac Studio Version: [Latest stable version recommended]

---

*Document Version: 1.0*  
*Last Updated: October 1, 2025*  
*Project: Simon Says Game - Phase 1 (3-Button Implementation)*
