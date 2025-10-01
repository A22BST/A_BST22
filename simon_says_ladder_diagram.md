# Simon Says Ladder Logic Diagram Description

## Ladder Logic Structure Overview

This document describes the ladder logic structure for the Simon Says game. The actual ladder diagram would be created in Sysmac Studio using the structured text provided.

## Rung Organization

### RUNG 1: Input Mapping and Edge Detection
```
Purpose: Map physical inputs and detect button press edges
Logic:
- Map %IX0.5, %IX0.3, %IX0.1 to button variables
- Generate rising edge signals for each button
- Store previous button states for next scan
```

### RUNG 2: Game Initialization  
```
Purpose: Initialize game variables on startup or reset
Logic:
- FIRST_SCAN OR GameReset → Initialize all variables
- Clear sequence array
- Set initial game state to IDLE (0)
- Initialize random seed
```

### RUNG 3: Game Start Trigger
```
Purpose: Detect game start condition
Logic:
- GameState=0 AND (Any Button Rising Edge) → Start Game
- Set GameState to 1 (GENERATE)
- Initialize level and sequence variables
```

### RUNG 4: Random Sequence Generation
```
Purpose: Generate random button sequence
Logic:
- GameState=1 → Execute random number generation
- Linear congruential generator algorithm
- Convert random value to button number (1-3)
- Add to sequence array
- Transition to PLAYBACK state
```

### RUNG 5: Sequence Playback Logic
```
Purpose: Flash LEDs in sequence order
Logic:
- GameState=2 AND PlaybackActive → Control LED flashing
- Flash current sequence button using FlashTimer
- Control gap between flashes using GapTimer  
- Advance through sequence or transition to INPUT state
- Turn off all LEDs during gaps
```

### RUNG 6: Player Input Handling
```
Purpose: Process player button presses and validate sequence
Logic:
- GameState=3 → Monitor for button presses
- Detect which button was pressed using rising edges
- Compare against expected sequence position
- Handle correct input: advance index, reset timeout
- Handle incorrect input: transition to FAIL state
- Handle timeout: transition to FAIL state
```

### RUNG 7: Success Handling
```
Purpose: Handle successful level completion
Logic:
- GameState=4 → Flash all LEDs for success indication
- Use SuccessTimer for display duration
- Increment level and sequence length
- Check for game completion (max level reached)
- Transition to next level or game won state
```

### RUNG 8: Failure Handling  
```
Purpose: Handle game failure conditions
Logic:
- GameState=5 → Rapid flash all LEDs for failure indication
- Use timer for failure display duration
- Auto-reset game after delay
- Return to IDLE state
```

### RUNG 9: Output Mapping
```
Purpose: Map LED control variables to physical outputs
Logic:
- RedLED_Output → %QX0.0
- BlueLED_Output → %QX0.1  
- YellowLED_Output → %QX0.2
- Override for test mode (AllLEDs_Test)
```

### RUNG 10: Status and Debug
```
Purpose: Provide status information and debug support
Logic:
- Convert GameState number to readable string
- Update debug variables for monitoring
- Support test mode functionality
```

## Timer Usage

### FlashTimer (TON)
- **Purpose**: Control LED flash duration during playback
- **Preset**: 500ms (FLASH_TIME)
- **Usage**: Activated during sequence playback for each LED

### GapTimer (TON)  
- **Purpose**: Control gap between LED flashes
- **Preset**: 300ms (GAP_TIME)
- **Usage**: Activated after each LED flash completes

### InputTimer (TON)
- **Purpose**: Timeout for player input
- **Preset**: 3000ms (INPUT_TIMEOUT)  
- **Usage**: Started when waiting for each button press

### SuccessTimer (TON)
- **Purpose**: Multi-purpose timer for delays
- **Preset**: Variable (SUCCESS_DELAY or failure display time)
- **Usage**: Success display, failure display, auto-reset timing

## State Machine Logic

```
State Transitions:
IDLE(0) → GENERATE(1) → PLAYBACK(2) → INPUT(3) → SUCCESS(4) → GENERATE(1)
                                           ↓
                                       FAIL(5) → IDLE(0)
```

### State Descriptions:
- **IDLE**: Waiting for game start, all LEDs off
- **GENERATE**: Creating new sequence element  
- **PLAYBACK**: Displaying sequence to player
- **INPUT**: Waiting for player to repeat sequence
- **SUCCESS**: Celebrating successful level completion
- **FAIL**: Indicating game failure and preparing reset

## Critical Logic Elements

### Edge Detection Pattern:
```
ButtonRising := ButtonCurrent AND NOT ButtonPrevious
ButtonPrevious := ButtonCurrent
```

### Random Number Generation:
```
RandomValue := (RandomSeed * 1103515245 + 12345) MOD 16#7FFFFFFF
NextButton := (RandomValue MOD 3) + 1
```

### Sequence Validation:
```
IF ButtonPressed = GameSequence[InputIndex] THEN
    CorrectInput := TRUE
    InputIndex := InputIndex + 1
ELSE  
    GameFailed := TRUE
END_IF
```

## Safety and Reliability Features

1. **Timeout Protection**: Input timeout prevents game lockup
2. **Auto-Reset**: Game automatically resets after failure
3. **Bounds Checking**: Array access is bounds-checked
4. **Edge Detection**: Prevents multiple triggers from single press
5. **State Machine**: Prevents invalid state transitions
6. **Initialization**: Proper startup and reset handling

## Performance Characteristics

- **Scan Time Impact**: Minimal, all logic executes in single scan
- **Memory Usage**: Efficient use of arrays and variables  
- **Timer Resolution**: 1ms resolution adequate for game timing
- **Deterministic**: Consistent timing and behavior
- **Scalable**: Easy to extend for additional buttons/features