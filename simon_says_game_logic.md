# Simon Says - Game Logic Design

## State Machine Overview

The Simon Says game operates as a finite state machine with the following states:

### Game States
1. **IDLE** - Waiting for start button
2. **INIT** - Initialize new game sequence
3. **SHOW_SEQUENCE** - Display the current sequence to player
4. **WAIT_INPUT** - Wait for player to repeat the sequence
5. **CHECK_INPUT** - Validate player input
6. **SUCCESS** - Player got sequence correct, advance to next level
7. **GAME_OVER** - Player made mistake, show failure indication

### Game Variables

#### Memory Allocation
| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| GameState | INT | Current game state | 0-6 |
| SequenceLength | INT | Current sequence length | 1-20 |
| SequenceArray[20] | INT Array | Stores the sequence | 0-2 (0=Red, 1=Blue, 2=Yellow) |
| CurrentStep | INT | Current position in sequence | 0-19 |
| PlayerStep | INT | Player's current input position | 0-19 |
| RandomSeed | DINT | For random number generation | 0-65535 |

#### Timing Variables
| Variable | Type | Description | Default Value |
|----------|------|-------------|---------------|
| FlashTime | TIME | LED flash duration | T#500ms |
| GapTime | TIME | Gap between flashes | T#200ms |
| InputTimeout | TIME | Player input timeout | T#3s |
| GameTimer | TIMER | Multi-purpose timer | - |

#### Button Mapping
- **Button 0**: Red (DI5 → DO0)
- **Button 1**: Blue (DI3 → DO1) 
- **Button 2**: Yellow (DI1 → DO2)

## State Machine Logic

### State 0: IDLE
**Entry Conditions**: Power-up or game reset
**Actions**:
- All LEDs OFF
- Clear sequence array
- Reset counters
**Exit Conditions**: Start button pressed (DI7)
**Next State**: INIT

### State 1: INIT
**Entry Conditions**: From IDLE or SUCCESS states
**Actions**:
- Generate new random number for sequence
- Add to sequence array at current position
- Set CurrentStep = 0
- Set PlayerStep = 0
**Exit Conditions**: Immediate
**Next State**: SHOW_SEQUENCE

### State 2: SHOW_SEQUENCE
**Entry Conditions**: From INIT or after adding new sequence element
**Actions**:
- Flash LED corresponding to SequenceArray[CurrentStep]
- Use FlashTime timer for LED on duration
- Use GapTime timer for gap between flashes
- Increment CurrentStep after each flash
**Exit Conditions**: All sequence elements shown (CurrentStep >= SequenceLength)
**Next State**: WAIT_INPUT

### State 3: WAIT_INPUT
**Entry Conditions**: After sequence display complete
**Actions**:
- Start InputTimeout timer
- Monitor button presses (DI1, DI3, DI5)
- Light up pressed button LED immediately
**Exit Conditions**: 
- Button pressed → CHECK_INPUT
- Timeout expired → GAME_OVER
**Next State**: CHECK_INPUT or GAME_OVER

### State 4: CHECK_INPUT
**Entry Conditions**: Player pressed a button
**Actions**:
- Compare pressed button with SequenceArray[PlayerStep]
- If correct: increment PlayerStep
- If incorrect: go to GAME_OVER
- If PlayerStep >= SequenceLength: go to SUCCESS
**Exit Conditions**: Input validated
**Next State**: WAIT_INPUT, SUCCESS, or GAME_OVER

### State 5: SUCCESS
**Entry Conditions**: Player completed current sequence correctly
**Actions**:
- Flash all LEDs briefly (celebration)
- Increment SequenceLength
- Check if maximum length reached
**Exit Conditions**: After celebration delay
**Next State**: INIT (next level) or GAME_OVER (max level reached)

### State 6: GAME_OVER
**Entry Conditions**: Player made mistake or timeout
**Actions**:
- Flash all LEDs in error pattern (fast blink 3 times)
- Hold all LEDs on for 2 seconds
- Reset game variables
**Exit Conditions**: After error display
**Next State**: IDLE

## Timing Specifications

### Phase 1 Settings (Fixed)
- **Flash Duration**: 500ms (LED on time during sequence display)
- **Gap Duration**: 200ms (pause between sequence flashes)
- **Input Timeout**: 3000ms (time allowed for each player input)
- **Success Celebration**: 1000ms (all LEDs flash time)
- **Error Display**: 2000ms (error pattern duration)

### Random Number Generation
- Use PLC's built-in random function or implement LFSR
- Generate values 0-2 for button selection
- Seed with system time or button press timing