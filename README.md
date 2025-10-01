# Simon Says Game - PLC Implementation

## Project Overview

This project implements a Simon Says memory game using an Omron NX102-1100 PLC system. The game challenges players to repeat increasingly complex sequences of colored button presses, testing memory and reaction time.

### Phase 1 Implementation
- **3-Button Version**: Red, Blue, Yellow illuminated pushbuttons
- **Simple Controls**: Single start button operation
- **Progressive Difficulty**: Sequences grow from 1 to 20 elements
- **Visual Feedback**: Immediate LED response to button presses
- **Error Handling**: Timeout and incorrect input detection

## Hardware Components

### Power Supply
- **RS PRO LI60-20B24PR2**: 24V DC, 2.5A DIN-rail SMPS

### PLC System
- **Omron NX102-1100**: NX1 Series CPU Unit
- **NX Power Supply Unit**: PLC power supply
- **NX-ID4442**: Digital Input Unit (64 channels)
- **NX-OD4256**: Digital Output Unit (32 channels)

### Operator Interface
- **3× RAFI RAMO 22 T**: Illuminated pushbuttons (M12, 4-pin, 1NO + LED)
  - Yellow Button (DI1 → DO2)
  - Blue Button (DI3 → DO1)  
  - Red Button (DI5 → DO0)
- **1× Start Button**: Connected to DI7

### Wiring Infrastructure
- DIN-rail mounted terminal blocks
- Protective earth bonding (yellow/green)
- Power distribution blocks for +24V and 0V

## File Structure

```
/workspace/
├── README.md                          # This file - project overview
├── simon_says_io_mapping.md           # Hardware I/O mapping and wiring
├── simon_says_game_logic.md           # Game state machine design
├── simon_says_ladder_logic.st         # Main PLC program (Structured Text)
├── simon_says_ladder_diagram.lad      # Ladder logic implementation
├── simon_says_timer_functions.st      # Timer utilities and functions
└── simon_says_testing_procedures.md   # Testing and validation procedures
```

## Installation Instructions

### 1. Hardware Setup
1. Install all components on DIN rail
2. Connect 24V power supply to system
3. Wire buttons according to I/O mapping document
4. Verify all connections with multimeter
5. Apply power and check LED indicators

### 2. PLC Programming
1. Open Sysmac Studio (Omron programming software)
2. Create new NX102-1100 project
3. Import the Structured Text program (`simon_says_ladder_logic.st`)
4. Configure I/O mapping to match hardware
5. Compile and download to PLC
6. Verify online connection

### 3. Testing and Commissioning
1. Follow testing procedures in `simon_says_testing_procedures.md`
2. Verify all 10 test cases pass
3. Document any issues or modifications
4. Complete acceptance testing

## Game Operation

### Starting the Game
1. Ensure system is powered and in IDLE state (all LEDs off)
2. Press the Start button (DI7)
3. Game begins with a single LED flash

### Playing the Game
1. Watch the sequence of LED flashes carefully
2. After sequence completes, repeat it by pressing buttons
3. Press buttons in the exact same order as shown
4. Each correct sequence advances to the next level
5. Sequences get longer with each level (up to 20 elements)

### Game Over Conditions
- **Wrong Button**: Pressing incorrect button in sequence
- **Timeout**: Taking longer than 3 seconds per button press
- **Completion**: Successfully completing all 20 levels

### Visual Feedback
- **Sequence Display**: LEDs flash for 500ms with 200ms gaps
- **Input Feedback**: LEDs light immediately when buttons pressed
- **Success**: All LEDs flash briefly before next level
- **Game Over**: All LEDs blink rapidly 3 times, then hold on for 2 seconds

## Technical Specifications

### Timing Parameters
- **Flash Duration**: 500ms (LED on time during sequence)
- **Gap Duration**: 200ms (pause between sequence elements)
- **Input Timeout**: 3000ms (maximum time per button press)
- **Response Time**: <50ms (button press to LED response)

### Memory Usage
- **Program Memory**: ~2KB (estimated)
- **Data Memory**: ~1KB (including sequence storage)
- **Maximum Sequence**: 20 elements
- **Supported Levels**: 1-20

### I/O Requirements
- **Digital Inputs**: 4 (3 buttons + start)
- **Digital Outputs**: 4 (3 LEDs + status)
- **Analog I/O**: None required for Phase 1

## Future Expansion (Phase 2 & 3)

### Phase 2 Additions
- 4th button (White) with normal illuminated pushbutton
- Mode selector switch (3-position: 3-button/Off/4-button)
- Enhanced game logic for mode selection

### Phase 3 Additions
- 8-position difficulty selector
- Variable timing based on difficulty
- Advanced game modes and challenges

## Troubleshooting

### Common Issues
1. **LEDs not lighting**: Check output wiring and power supply
2. **Buttons not responding**: Verify input connections and +24V supply
3. **Game won't start**: Check start button wiring (DI7)
4. **Incorrect timing**: Verify timer preset values in program
5. **Random sequences not random**: Check random seed initialization

### Diagnostic Tools
- Use Sysmac Studio online monitoring
- Check I/O status in real-time
- Monitor game state variables
- Verify timer operations

## Safety Considerations

- All electrical work should be performed by qualified personnel
- Ensure proper protective earth connections
- Use appropriate PPE when working with electrical systems
- Follow local electrical codes and regulations
- Test emergency stop procedures if implemented

## Support and Maintenance

### Regular Maintenance
- Visual inspection of connections monthly
- Clean button contacts as needed
- Verify LED operation quarterly
- Update documentation for any modifications

### Software Updates
- Keep backup of working program
- Test all changes in simulation first
- Document all program modifications
- Maintain version control

## Contact Information

For technical support or questions about this implementation, refer to:
- Omron technical documentation
- PLC programming manuals
- Hardware component datasheets

---

**Project Status**: Phase 1 Complete - Ready for Testing
**Last Updated**: October 2025
**Version**: 1.0