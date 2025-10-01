# Simon Says Game - Phase 1 Implementation

## Project Overview

This project implements a Simon Says memory game using an Omron NX102-1100 PLC with 3 illuminated pushbuttons (Red, Blue, Yellow). The game follows a state machine approach with proper I/O mapping and timing controls.

## Hardware Configuration

### Power Supply
- **RS PRO LI60-20B24PR2**: 24V DC, 2.5A DIN-rail SMPS

### PLC System
- **CPU**: Omron NX102-1100 (NX1 Series CPU Unit)
- **Power Supply**: NX Power Supply Unit
- **Digital Input**: NX-ID4442 (64-channel Digital Input Unit)
- **Digital Output**: NX-OD4256 (32-channel Digital Output Unit)

### Operator Devices
- **3 × RAFI RAMO 22 T** illuminated pushbuttons (M12, 4-pin, 1NO + LED)
  - Red Button
  - Blue Button  
  - Yellow Button

### Button Pinout (M12 A-coded, 4-pin)
| Pin | Wire Color | Function | Connection |
|-----|------------|----------|------------|
| 1 | Brown | Contact COM | +24V terminal block |
| 2 | White | LED + | PLC Digital Output |
| 3 | Blue | LED - | 0V terminal block |
| 4 | Black | Contact OUT | PLC Digital Input |

## I/O Mapping

### Digital Inputs (NX-ID4442)
- **DI1**: Yellow Button Contact
- **DI3**: Blue Button Contact
- **DI5**: Red Button Contact

### Digital Outputs (NX-OD4256)
- **DO0**: Red Button LED
- **DO1**: Blue Button LED
- **DO2**: Yellow Button LED

## Wiring Diagram

```
Power Supply (24V)
    |
    +---> +24V Terminal Block
    |         |
    |         +---> Red Button Pin 1 (Brown)
    |         +---> Blue Button Pin 1 (Brown)
    |         +---> Yellow Button Pin 1 (Brown)
    |
    +---> 0V Terminal Block
            |
            +---> Red Button Pin 3 (Blue)
            +---> Blue Button Pin 3 (Blue)
            +---> Yellow Button Pin 3 (Blue)

PLC Digital Inputs
    |
    +---> DI1 <-- Yellow Button Pin 4 (Black)
    +---> DI3 <-- Blue Button Pin 4 (Black)
    +---> DI5 <-- Red Button Pin 4 (Black)

PLC Digital Outputs
    |
    +---> DO0 --> Red Button Pin 2 (White)
    +---> DO1 --> Blue Button Pin 2 (White)
    +---> DO2 --> Yellow Button Pin 2 (White)
```

## Memory Map

| Address | Variable | Description |
|---------|----------|-------------|
| W0 | GameState | 0=Idle, 1=Play, 2=Wait, 3=Over |
| W1 | SeqLength | Current sequence length |
| W2 | CurrStep | Current playback step |
| W3 | PlayerStep | Player input position |
| W4-W53 | Sequence | Sequence storage (50 steps max) |
| W100 | Score | Player score |
| W101 | FlashTime | LED flash duration (500ms) |
| W102 | GapTime | Gap between flashes (200ms) |

## Game Logic

### State Machine
1. **Idle State (W0=0)**: Game waiting for start
   - Any button press starts the game
   - Generates first random sequence step

2. **Play State (W0=1)**: Playing sequence to player
   - Flashes LEDs in sequence order
   - 500ms flash, 200ms gap between flashes
   - Advances through sequence steps

3. **Wait State (W0=2)**: Waiting for player input
   - Player must repeat the sequence
   - Validates each button press
   - 3-second timeout if no input

4. **Over State (W0=3)**: Game over
   - Wrong button pressed or timeout
   - Any button press returns to Idle

### Sequence Generation
- Random numbers 1-3 generated for each step
- 1 = Red, 2 = Blue, 3 = Yellow
- Sequence stored in W4-W53 array
- Maximum 50 steps supported

### Scoring
- Score incremented when player completes sequence correctly
- Sequence length increases by 1 for next round
- Game continues until player makes mistake

## Files

- `simon_says_simple.lad`: Main ladder logic program (simplified version)
- `simon_says_nx102.lad`: Detailed ladder logic with full documentation
- `simon_says_phase1.lad`: Initial implementation attempt

## Installation Instructions

1. **Hardware Setup**:
   - Install power supply on DIN rail
   - Install PLC CPU and I/O modules
   - Wire buttons according to pinout diagram
   - Connect 24V power distribution

2. **Software Setup**:
   - Use Omron Sysmac Studio to program PLC
   - Load `simon_says_simple.lad` into CPU
   - Configure I/O mapping as specified
   - Download program to PLC

3. **Testing**:
   - Power on system
   - Press any button to start game
   - Follow LED sequence
   - Press buttons in same order
   - Game should advance to next level

## Troubleshooting

### Common Issues
1. **Buttons not responding**: Check wiring and input configuration
2. **LEDs not flashing**: Verify output wiring and DO configuration
3. **Game not starting**: Check that inputs are properly mapped
4. **Sequence too fast/slow**: Adjust FlashTime and GapTime values

### Debug Tips
- Monitor W0 (GameState) to see current state
- Check W1 (SeqLength) to verify sequence generation
- Watch W100 (Score) to confirm scoring logic
- Use PLC diagnostics to verify I/O status

## Future Enhancements (Phase 2)

- Add 4th button (White)
- Implement 3-button vs 4-button mode selection
- Add difficulty levels using 8-position selector
- Implement high score tracking
- Add sound effects using analog outputs

## Safety Notes

- Ensure proper 24V power supply grounding
- Use appropriate wire gauge for current requirements
- Follow electrical safety standards for industrial control systems
- Test all connections before powering on system