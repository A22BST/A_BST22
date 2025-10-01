# Simon Says Game - Phase 1 Implementation Guide

## Overview
This implementation provides a complete Simon Says game for the Omron NX102-1100 PLC using 3 illuminated pushbuttons (Yellow, Blue, Red).

## Hardware Configuration

### I/O Mapping
| Component | Signal | I/O Type | Address | Wire Connection |
|-----------|--------|----------|---------|-----------------|
| Yellow Button | Contact Input | DI | %IX0.1 (DI1) | Pin 4 (Black) |
| Yellow Button | LED Output | DO | %QX0.2 (DO2) | Pin 2 (White) |
| Blue Button | Contact Input | DI | %IX0.3 (DI3) | Pin 4 (Black) |
| Blue Button | LED Output | DO | %QX0.1 (DO1) | Pin 2 (White) |
| Red Button | Contact Input | DI | %IX0.5 (DI5) | Pin 4 (Black) |
| Red Button | LED Output | DO | %QX0.0 (DO0) | Pin 2 (White) |

### Wiring Details
Each RAFI RAMO 22 T button requires:
- Pin 1 (Brown): +24V DC (Contact Common)
- Pin 2 (White): From PLC DO (LED+)
- Pin 3 (Blue): 0V DC (LED-)
- Pin 4 (Black): To PLC DI (Contact Signal)

## Software Implementation

### Files Provided
1. **FB_SimonSays.st** - Main function block containing game logic
2. **MainProgram.st** - Main program that instantiates the function block
3. **SimonSays_Phase1_Main.st** - Alternative standalone implementation
4. **SimonSays_Phase1_Ladder.ld** - Ladder logic version
5. **SimonSays_Variables.csv** - Variable list for import

### Implementation Steps in Sysmac Studio

#### Step 1: Create New Project
1. Open Sysmac Studio
2. Create new project for NX102-1100
3. Configure I/O modules:
   - NX-ID4442 (Digital Inputs)
   - NX-OD4256 (Digital Outputs)

#### Step 2: Import Function Block
1. Right-click on "Function Blocks" in project tree
2. Select "Add" → "Function Block"
3. Name it "FB_SimonSays"
4. Set language to "Structured Text (ST)"
5. Copy content from FB_SimonSays.st

#### Step 3: Create Main Program
1. Right-click on "Programs" in project tree
2. Select "Add" → "Program"
3. Name it "MainProgram"
4. Set language to "Structured Text (ST)"
5. Copy content from MainProgram.st

#### Step 4: Configure Task
1. Open "Task Settings"
2. Assign MainProgram to Primary Task
3. Set cycle time to 10ms

#### Step 5: Map Physical I/O
1. Open "I/O Map"
2. Map physical channels to variables:
   - NX-ID4442 Ch1 → DI_YellowButton
   - NX-ID4442 Ch3 → DI_BlueButton
   - NX-ID4442 Ch5 → DI_RedButton
   - NX-OD4256 Ch0 → DO_RedLED
   - NX-OD4256 Ch1 → DO_BlueLED
   - NX-OD4256 Ch2 → DO_YellowLED

## Game Operation

### Game States
1. **IDLE (State 0)**: Waiting for start signal
2. **SHOW_SEQUENCE (State 1)**: Display pattern to player
3. **WAIT_INPUT (State 2)**: Player repeats pattern
4. **GAME_WON (State 3)**: Victory celebration
5. **GAME_LOST (State 4)**: Game over indication

### Game Flow
1. Press Start to begin (set StartButton = TRUE)
2. PLC shows a sequence starting with 1 button
3. Player must repeat the sequence
4. If correct, sequence adds one more button
5. Game continues until:
   - Player reaches maximum level (wins)
   - Player makes mistake (loses)
   - Input timeout expires (loses)

### Timing Parameters (Adjustable)
- **ShowTime**: 500ms - Duration each LED is shown
- **GapTime**: 200ms - Gap between LEDs in sequence
- **InputTimeout**: 3s - Time allowed for player input
- **MaxLevel**: 10 - Maximum sequence length

## Testing Procedure

### Initial Test
1. Download program to PLC
2. Set PLC to RUN mode
3. Monitor variables in online mode
4. Set StartButton = TRUE to start game
5. Test each button individually

### Game Play Test
1. Start game
2. Watch first LED flash
3. Press same button
4. Watch sequence extend to 2 LEDs
5. Repeat sequence
6. Continue until win or lose

### Troubleshooting

#### LEDs not lighting
- Check DO wiring (Pin 2 to DO, Pin 3 to 0V)
- Verify 24V supply to LEDs
- Check DO channel configuration

#### Buttons not responding
- Check DI wiring (Pin 4 to DI, Pin 1 to +24V)
- Verify button contact operation
- Check DI channel configuration

#### Game not starting
- Ensure StartButton variable is set TRUE
- Check PLC is in RUN mode
- Verify program is assigned to task

## Phase 2 Preparation

### Planned Additions
1. **4th Button (White)**
   - Will use DI7 for input
   - Will use DO3 for LED

2. **Mode Selection**
   - 3-position selector switch
   - Position 1: 3-button mode
   - Position 2: Idle
   - Position 3: 4-button mode

3. **Difficulty Control**
   - 8-position selector (0-7)
   - Adjusts timing parameters
   - May add special rules

### Variables to Add
- DI_WhiteButton (DI7)
- DO_WhiteLED (DO3)
- GameMode (INT)
- DifficultyLevel (INT)

## Safety Considerations
1. All buttons operate at safe 24V DC
2. Current limited by PLC outputs
3. No mechanical hazards
4. Emergency stop not required for game application

## Performance Metrics
- Scan time: < 10ms recommended
- Response time: < 50ms for button press
- Memory usage: < 1KB for game logic
- Maximum players: 1 (single player game)

## Maintenance
- No regular maintenance required
- Check connections if buttons become unresponsive
- Monitor for worn button contacts after extended use
- Clean button surfaces as needed