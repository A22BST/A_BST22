# Simon Says Implementation Guide - Sysmac Studio

## Overview
This guide provides step-by-step instructions for implementing the Simon Says game on an Omron NX102-1100 PLC using Sysmac Studio.

## Hardware Setup Verification

### 1. Power Supply Connection
- Ensure RS PRO LI60-20B24PR2 (24V DC, 2.5A) is properly connected
- Verify +24V and 0V distribution to terminal blocks

### 2. PLC Module Installation
- Install NX102-1100 CPU unit
- Install NX Power Supply Unit  
- Install NX-ID4442 Digital Input module
- Install NX-OD4256 Digital Output module

### 3. Button Wiring Verification
Verify each button connection according to the I/O mapping:

| Button | Input | Output | Pin 1 (Brown) | Pin 2 (White) | Pin 3 (Blue) | Pin 4 (Black) |
|--------|-------|--------|---------------|---------------|--------------|---------------|
| Red    | DI5   | DO0    | +24V          | DO0           | 0V           | DI5           |
| Blue   | DI3   | DO1    | +24V          | DO1           | 0V           | DI3           |
| Yellow | DI1   | DO2    | +24V          | DO2           | 0V           | DI1           |

## Sysmac Studio Configuration

### 1. Create New Project
1. Open Sysmac Studio
2. Create new project for NX102-1100
3. Configure I/O modules:
   - Add NX-ID4442 to slot 1
   - Add NX-OD4256 to slot 2

### 2. Variable Declaration
1. Open Global Variables
2. Import or manually create variables from `simon_says_variables.md`
3. Ensure all I/O variables are properly mapped:
   ```
   RedButton_Input AT %IX0.5 : BOOL;
   BlueButton_Input AT %IX0.3 : BOOL;
   YellowButton_Input AT %IX0.1 : BOOL;
   RedLED_Output AT %QX0.0 : BOOL;
   BlueLED_Output AT %QX0.1 : BOOL;
   YellowLED_Output AT %QX0.2 : BOOL;
   ```

### 3. Program Implementation
1. Create new Program: `SimonSaysGame`
2. Copy the ladder logic from `simon_says_ladder_logic.st`
3. Compile and check for errors

### 4. I/O Configuration
Verify I/O configuration matches physical wiring:
- **Inputs**: DI1 (Yellow), DI3 (Blue), DI5 (Red)
- **Outputs**: DO0 (Red), DO1 (Blue), DO2 (Yellow)

## Game Operation

### Game States
The game operates in 6 distinct states:

1. **IDLE (0)**: Waiting for player to start
2. **GENERATE (1)**: Creating new sequence element
3. **PLAYBACK (2)**: Displaying sequence to player
4. **INPUT (3)**: Waiting for player input
5. **SUCCESS (4)**: Level completed successfully
6. **FAIL (5)**: Game over (wrong input or timeout)

### Game Flow
1. **Start**: Press any button when in IDLE state
2. **Watch**: Observe the LED sequence during PLAYBACK
3. **Repeat**: Press buttons in same order during INPUT phase
4. **Progress**: Successfully complete sequence to advance level
5. **Reset**: Game auto-resets after failure

### Timing Parameters
- **Flash Duration**: 500ms per LED
- **Gap Between Flashes**: 300ms
- **Input Timeout**: 3000ms per button press
- **Success Display**: 1000ms
- **Failure Display**: 3000ms before auto-reset

## Testing Procedures

### 1. Initial Testing
1. Download program to PLC
2. Enable `AllLEDs_Test` variable to test all LEDs
3. Verify each button input registers correctly
4. Test each LED output individually

### 2. Game Logic Testing
1. Start game by pressing any button
2. Verify single LED flashes (Level 1)
3. Press correct button to advance
4. Verify sequence grows with each level
5. Test wrong button press (should trigger failure)
6. Test input timeout (wait 3+ seconds without pressing)

### 3. Edge Case Testing
- Rapid button presses
- Button held down during playback
- Multiple simultaneous button presses
- Power cycle during game

## Troubleshooting

### Common Issues

#### LEDs Don't Light
- Check +24V supply to LED pins
- Verify 0V connections to LED negative pins
- Check DO module wiring and configuration

#### Buttons Don't Register
- Verify +24V supply to button contacts
- Check DI module wiring and configuration
- Test button continuity with multimeter

#### Game Doesn't Start
- Check that `GameState` variable shows 0 (IDLE)
- Verify button edge detection is working
- Check `FIRST_SCAN` initialization

#### Sequence Doesn't Play
- Monitor `PlaybackActive` variable
- Check timer function blocks are being called
- Verify `GameSequence` array contains valid values (1-3)

#### Random Sequence Issues
- Check `RandomSeed` initialization
- Monitor `RandomValue` generation
- Verify sequence array bounds (1-20)

### Debug Variables
Monitor these variables for troubleshooting:
- `DebugState`: Human-readable game state
- `GameState`: Numeric state (0-5)
- `CurrentLevel`: Current game level
- `SequenceLength`: Length of current sequence
- `LastButtonPressed`: Last button pressed by player
- `CorrectSequence`: Whether current input is correct

## Performance Optimization

### Scan Time Considerations
- Current implementation should run comfortably under 10ms scan time
- Timer resolution is adequate for game timing requirements
- Random number generation is lightweight

### Memory Usage
- Sequence array: 20 integers (40 bytes)
- Timer instances: 4 TON blocks
- Total variable memory: <200 bytes

## Future Enhancements (Phase 2 & 3)

### Phase 2 Additions
- Add 4th button (White) with DI/DO pair
- Implement mode selector switch
- Add 3-button vs 4-button mode selection

### Phase 3 Additions  
- Implement 8-position difficulty selector
- Variable timing based on difficulty
- Advanced scoring system
- Sound effects integration

## Safety Considerations
- All circuits operate at safe 24V DC levels
- Emergency stop capability can be added to safety circuit
- LED current is limited by PLC output specifications
- Button contacts are isolated from LED circuits

## Maintenance
- Regular inspection of terminal connections
- Periodic cleaning of button contacts
- Backup of PLC program recommended
- Monitor scan time during operation