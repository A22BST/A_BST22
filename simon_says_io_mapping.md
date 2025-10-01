# Simon Says I/O Mapping - Phase 1

## Hardware Configuration
- **PLC**: Omron NX102-1100 (NX1 Series CPU Unit)
- **Digital Inputs**: NX-ID4442 (64 channels)
- **Digital Outputs**: NX-OD4256 (32 channels)
- **Power Supply**: RS PRO LI60-20B24PR2 (24V DC, 2.5A)

## Button Configuration (Phase 1 - 3 Buttons)

### Physical Wiring
| Button | Color  | Contact Input | LED Output | Description |
|--------|--------|---------------|------------|-------------|
| Button 1 | Red    | DI5          | DO0        | Red button |
| Button 2 | Blue   | DI3          | DO1        | Blue button |
| Button 3 | Yellow | DI1          | DO2        | Yellow button |

### Pin Connections (M12 A-coded, 4-pin)
Each button uses:
- Pin 1 (Brown): Contact COM → +24V terminal block
- Pin 2 (White): LED+ → PLC Digital Output
- Pin 3 (Blue): LED- → 0V terminal block  
- Pin 4 (Black): Contact → PLC Digital Input

### I/O Address Mapping
```
Digital Inputs (NX-ID4442):
- DI1: Yellow Button Contact
- DI3: Blue Button Contact  
- DI5: Red Button Contact

Digital Outputs (NX-OD4256):
- DO0: Red LED
- DO1: Blue LED
- DO2: Yellow LED
```

## Game Logic Overview
1. **Initialization**: All LEDs off, game ready
2. **Sequence Generation**: Create random sequence of button presses
3. **Playback**: Flash LEDs in sequence with timing
4. **Input Phase**: Wait for player to repeat sequence
5. **Validation**: Check if player input matches sequence
6. **Success/Failure**: Advance level or restart game

## Timing Parameters
- LED Flash Duration: 500ms
- Gap Between Flashes: 300ms
- Input Timeout: 3000ms per button
- Success Delay: 1000ms before next level