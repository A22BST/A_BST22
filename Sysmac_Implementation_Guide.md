# Sysmac Studio Implementation Guide for Simon Says Phase 1

## Project Setup in Sysmac Studio

### Step 1: Create New Project
1. Open Sysmac Studio
2. File → New → Project
3. Select:
   - Device: NX102-1100
   - Version: Latest available
   - Project Name: "SimonSays_Phase1"

### Step 2: Configure I/O Modules
1. In Project tree, expand "Configurations and Setup"
2. Right-click "I/O Map" → Edit
3. Add modules:
   - Slot 1: NX-ID4442 (Digital Input, 64ch)
   - Slot 2: NX-OD4256 (Digital Output, 32ch)

### Step 3: Create Global Variables
1. Navigate to "Programming" → "Data" → "Global Variables"
2. Create new variable table: "GameVariables"
3. Add the following variables:

```
Variable Name          | Data Type        | Initial Value | AT      | Comment
----------------------|------------------|---------------|---------|---------------------------
Yellow_Button_Input   | BOOL             | FALSE         | %IX0.1  | DI1 - Yellow button
Blue_Button_Input     | BOOL             | FALSE         | %IX0.3  | DI3 - Blue button  
Red_Button_Input      | BOOL             | FALSE         | %IX0.5  | DI5 - Red button
Red_LED_Output        | BOOL             | FALSE         | %QX0.0  | DO0 - Red LED
Blue_LED_Output       | BOOL             | FALSE         | %QX0.1  | DO1 - Blue LED
Yellow_LED_Output     | BOOL             | FALSE         | %QX0.2  | DO2 - Yellow LED
GameState             | INT              | 0             |         | Game state machine
GameSequence          | ARRAY[0..49] OF INT | [50(0)]   |         | Button sequence storage
CurrentLevel          | INT              | 0             |         | Current sequence length
SequenceIndex         | INT              | 0             |         | Display position
PlayerInputIndex      | INT              | 0             |         | Player input position
MaxLevel              | INT              | 10            |         | Maximum sequence length
LastButtonPressed     | INT              | 0             |         | Last button pressed
RandomSeed            | DINT             | 12345         |         | Random seed
```

### Step 4: Create Timer Instances
Add these timer variables to the global variables:

```
Variable Name          | Data Type | Initial Value | Comment
----------------------|-----------|---------------|---------------------------
TMR_Flash             | TON       |               | LED flash timer
TMR_Gap               | TON       |               | Gap between flashes
TMR_InputTimeout      | TON       |               | Player timeout
TMR_StartDelay        | TON       |               | Start delay timer
```

### Step 5: Create Main Program

#### Option A: Structured Text (ST)
1. Right-click "Programs" → Add → Program
2. Name: "SimonSays_Main"
3. Language: Structured Text (ST)
4. Copy the ST code from `SimonSays_Phase1.st`

#### Option B: Ladder Diagram (LD)
1. Right-click "Programs" → Add → Program  
2. Name: "SimonSays_Main"
3. Language: Ladder Diagram (LD)
4. Implement rungs as described in `SimonSays_Phase1_Ladder.txt`

## Ladder Diagram Implementation Details

### Creating Edge Detection Rungs

For each button, create positive edge detection:

**Rung for Yellow Button Edge Detection:**
```
|--[P]--[Yellow_Button_Input]---(SET Yellow_Press)---|
|--[N]--[Yellow_Button_Input]---(RESET Yellow_Press)-|
```

### State Machine Implementation

**Example: Idle State (GameState = 0)**
```
Network 1: Check if in Idle State
|--[CMP]==--[GameState][0]---(Idle_Active)---|

Network 2: Reset outputs when idle
|--[Idle_Active]--+--(/)--(Yellow_LED_Output)---|
                  +--(/)--(Blue_LED_Output)-----|
                  +--(/)--(Red_LED_Output)------|

Network 3: Reset counters when idle
|--[Idle_Active]--+--[MOV]--[0]--(CurrentLevel)---|
                  +--[MOV]--[0]--(SequenceIndex)---|
```

### Timer Configuration

**Flash Timer Setup:**
```
|--[ShowSequence_Active]--[TMR_Flash]--|
                          EN        Q   |
                          PT=T#500MS    |
                          ET            |
```

### Random Number Generation

Create a function block for random number generation:

```
FUNCTION_BLOCK FB_Random
VAR_INPUT
    Trigger : BOOL;
    Seed : DINT;
END_VAR
VAR_OUTPUT
    RandomValue : INT;  // 1-3 for buttons
END_VAR
VAR
    InternalSeed : DINT;
END_VAR

IF Trigger THEN
    InternalSeed := (Seed * 1103515245 + 12345) MOD 2147483648;
    RandomValue := (ABS(InternalSeed) MOD 3) + 1;
END_IF;
END_FUNCTION_BLOCK
```

## Testing Procedure

### 1. Initial Hardware Check
- Verify wiring matches the specification
- Check 24V power to buttons (Pin 1)
- Verify 0V connections (Pin 3)

### 2. I/O Test Mode
Create a simple test program:
```
|--[Yellow_Button_Input]---(Yellow_LED_Output)---|
|--[Blue_Button_Input]-----(Blue_LED_Output)-----|
|--[Red_Button_Input]------(Red_LED_Output)------|
```

### 3. Game Testing Sequence
1. **Power On**: All LEDs should be OFF
2. **Start Game**: Press any button
   - All LEDs flash together for 2 seconds
3. **First Round**: 
   - One LED flashes
   - Press the same button
   - If correct, proceed to round 2
4. **Subsequent Rounds**:
   - Previous sequence + 1 new LED
   - Input entire sequence
5. **Error Testing**:
   - Press wrong button → Red LED flashes
   - Wait for timeout → Red LED flashes
6. **Victory Testing**:
   - Complete 10 rounds → Celebration pattern

## Troubleshooting Guide

### Common Issues and Solutions

1. **LEDs not lighting**
   - Check 24V supply to output module
   - Verify DO channel assignment
   - Check LED wiring (Pin 2 to DO, Pin 3 to 0V)

2. **Buttons not responding**
   - Verify DI channel assignment  
   - Check button wiring (Pin 1 to 24V, Pin 4 to DI)
   - Test with forced inputs in Sysmac Studio

3. **Random sequence always the same**
   - Ensure RandomSeed is being updated
   - Use system clock for seed if available

4. **Timing issues**
   - Adjust timer preset values
   - Check PLC scan time
   - Verify timer data types (TIME format)

## Optimization Tips

1. **Scan Time**: Keep ladder logic simple for faster scan times
2. **Memory Usage**: Use appropriate data types (BOOL vs INT)
3. **Modularity**: Create function blocks for repeated logic
4. **Documentation**: Add comments to every rung/network
5. **Version Control**: Save project versions before major changes

## Phase 2 Preparation

To prepare for Phase 2 (4th button + mode selector):

1. Reserve I/O points:
   - DI7: White button input
   - DO3: White LED output
   - DI8-10: 3-position selector switch

2. Extend arrays:
   - Increase sequence storage if needed
   - Add mode variable (3-button vs 4-button)

3. Modify random generation:
   - Mode-dependent range (1-3 or 1-4)

## Safety Considerations

1. **Emergency Stop**: Consider adding E-stop functionality
2. **Watchdog Timer**: Implement system watchdog
3. **Error Handling**: Add fault detection and recovery
4. **Input Debouncing**: Add debounce timers if needed