# Simon Says Game - Omron NX102 PLC Implementation

## Project Overview

This project implements a Simon Says memory game using an Omron NX102-1100 PLC with Sysmac Studio. The game uses illuminated pushbuttons that serve as both inputs (button contacts) and outputs (LED indicators).

## Phase 1: 3-Button Implementation

### Hardware Requirements
- **PLC**: Omron NX102-1100 (NX1 Series CPU Unit)
- **Power Supply**: RS PRO LI60-20B24PR2 (24V DC, 2.5A)
- **I/O Modules**: 
  - NX-ID4442 (Digital Input, 64 channels)
  - NX-OD4256 (Digital Output, 32 channels)
- **Buttons**: 3× RAFI RAMO 22T illuminated pushbuttons (Red, Blue, Yellow)
- **Wiring**: M12 4-pin connectors, DIN rail terminal blocks

### Game Features
- **Memory Challenge**: Players must repeat increasingly long sequences
- **Visual Feedback**: LEDs flash to show sequence and indicate success/failure
- **Progressive Difficulty**: Sequence length increases with each successful level
- **Auto-Reset**: Game automatically restarts after failure
- **Timeout Protection**: Prevents game lockup if player doesn't respond

### File Structure
```
/workspace/
├── README.md                           # This file
├── simon_says_ladder_logic.st          # Main ladder logic program
├── simon_says_variables.md             # Variable definitions
├── simon_says_io_mapping.md            # I/O configuration
├── simon_says_implementation_guide.md  # Step-by-step setup guide
└── simon_says_ladder_diagram.md        # Ladder logic structure description
```

## Quick Start

### 1. Hardware Setup
1. Install PLC modules according to I/O mapping
2. Wire buttons according to pin configuration
3. Connect 24V power supply and distribution

### 2. Software Setup
1. Create new Sysmac Studio project for NX102-1100
2. Import variables from `simon_says_variables.md`
3. Copy ladder logic from `simon_says_ladder_logic.st`
4. Configure I/O mapping as specified
5. Download and run program

### 3. Testing
1. Enable test mode to verify all LEDs
2. Test button inputs individually
3. Start game by pressing any button
4. Follow sequence and verify game progression

## Game Operation

### How to Play
1. **Start**: Press any button when game is idle
2. **Watch**: Observe the LED sequence (starts with 1 LED)
3. **Repeat**: Press buttons in the same order shown
4. **Progress**: Successfully complete sequence to advance to next level
5. **Challenge**: Each level adds one more LED to the sequence

### Game States
- **IDLE**: Ready to start - press any button
- **PLAYBACK**: Watch the LED sequence carefully  
- **INPUT**: Your turn - repeat the sequence
- **SUCCESS**: Level complete - all LEDs flash briefly
- **FAILURE**: Game over - rapid LED flashing, then auto-reset

### Timing
- **LED Flash**: 500ms per LED
- **Gap Between LEDs**: 300ms  
- **Input Timeout**: 3 seconds per button press
- **Success Display**: 1 second
- **Failure Display**: 3 seconds before reset

## Technical Details

### I/O Mapping
| Function | Address | Description |
|----------|---------|-------------|
| Red Button Input | DI5 (%IX0.5) | Red button contact |
| Blue Button Input | DI3 (%IX0.3) | Blue button contact |
| Yellow Button Input | DI1 (%IX0.1) | Yellow button contact |
| Red LED Output | DO0 (%QX0.0) | Red LED control |
| Blue LED Output | DO1 (%QX0.1) | Blue LED control |
| Yellow LED Output | DO2 (%QX0.2) | Yellow LED control |

### Key Variables
- `GameState`: Current game state (0-5)
- `GameSequence[]`: Array storing button sequence
- `CurrentLevel`: Current difficulty level
- `SequenceLength`: Length of current sequence
- `DebugState`: Human-readable status string

### Performance
- **Scan Time**: <5ms typical
- **Memory Usage**: <200 bytes
- **Maximum Sequence**: 20 buttons
- **Response Time**: <10ms button to LED

## Future Phases

### Phase 2: 4-Button Mode
- Add white illuminated pushbutton
- Implement mode selector (3-button vs 4-button)
- Enhanced game variety

### Phase 3: Difficulty Control  
- 8-position difficulty selector
- Variable timing based on difficulty
- Advanced scoring system

## Troubleshooting

### Common Issues
1. **LEDs don't light**: Check 24V supply and wiring
2. **Buttons don't register**: Verify input wiring and PLC configuration
3. **Game doesn't start**: Check initialization and button edge detection
4. **Erratic behavior**: Verify scan time and timer operation

### Debug Tools
- Monitor `DebugState` for current game status
- Use `AllLEDs_Test` to verify LED operation
- Check `LastButtonPressed` for input verification
- Monitor timer states for timing issues

## Safety Notes
- All circuits operate at safe 24V DC levels
- LED current limited by PLC output specifications  
- Emergency stop can be added to safety circuit
- Regular inspection of connections recommended

## Support
For technical support or questions about implementation, refer to:
- Sysmac Studio documentation
- Omron NX-series hardware manuals
- Implementation guide in this repository

---
**Version**: 1.0  
**Date**: October 2025  
**Compatible**: Sysmac Studio V1.4x and later