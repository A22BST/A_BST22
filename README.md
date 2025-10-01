# Simon Says Game - Ladder Logic Project

Welcome to the Simon Says game implementation for the Omron NX102-1100 PLC using Sysmac Studio!

## 📁 Project Files

### Main Documentation
- **`SimonSays_Implementation_Guide.md`** - Complete implementation guide with detailed instructions, wiring diagrams, and code examples

### Ladder Logic Files  
Multiple versions of the ladder logic program have been created. The most complete ones are:
- **`SimonSays_Main.ld`** - Initial working version
- **`SimonSays_Complete.ld`** - Enhanced version with better structure
- **`SimonSays_Phase1_Final_Corrected.ld`** - Latest version with corrections

**Note**: All `.ld` files contain the same core logic with minor variations. Use the Implementation Guide as your primary reference.

## 🎮 Game Overview

This project implements a classic Simon Says memory game using:
- **3 colored buttons** (Yellow, Blue, Red) - Phase 1
- **4 buttons** (adding White) - Phase 2  
- **Variable difficulty levels** - Phase 3

## 🔧 Hardware Requirements

### PLC & I/O
- Omron NX102-1100 CPU
- NX-ID4442 Digital Input Module (64 channels)
- NX-OD4256 Digital Output Module (32 channels)
- RS PRO LI60-20B24PR2 Power Supply (24V DC, 2.5A)

### Operator Devices
- 3× RAFI RAMO 22 T Illuminated Pushbuttons (M12, 4-pin, 1NO + LED)
  - Yellow, Blue, Red
- 1× Additional Illuminated Pushbutton (White) - for Phase 2
- 1× 3-position Selector Switch (Mode selection)
- 1× 8-position Selector Switch (Difficulty selection) - for Phase 3

## 📊 I/O Mapping - Phase 1

### Digital Inputs (NX-ID4442)
| Input | Function | Connection |
|-------|----------|------------|
| DI1   | Yellow Button | M12 Pin 4 (Black) |
| DI3   | Blue Button | M12 Pin 4 (Black) |
| DI5   | Red Button | M12 Pin 4 (Black) |
| DI7   | Start/Stop Switch | Selector Switch |

### Digital Outputs (NX-OD4256)
| Output | Function | Connection |
|--------|----------|------------|
| DO0    | Red LED | M12 Pin 2 (White) |
| DO1    | Blue LED | M12 Pin 2 (White) |
| DO2    | Yellow LED | M12 Pin 2 (White) |

## 🔌 Button Wiring

Each RAFI RAMO 22 T button has 4 pins (M12 connector):

| Pin | Wire Color | Function | Connects To |
|-----|------------|----------|-------------|
| 1   | Brown      | Contact COM | +24V terminal block |
| 2   | White      | LED + | DO (Output) |
| 3   | Blue       | LED – | 0V terminal block |
| 4   | Black      | Contact IN | DI (Input) |

**Example - Yellow Button:**
- Pin 1 (Brown) → +24V
- Pin 2 (White) → DO2
- Pin 3 (Blue) → 0V
- Pin 4 (Black) → DI1

## 🎯 Development Phases

### Phase 1: Minimal Core (3 Buttons)
- ✅ Basic game with Yellow, Blue, Red buttons
- ✅ Sequence generation and playback
- ✅ User input validation
- ✅ Start/stop control
- ✅ Game over detection

### Phase 2: Expansion (4th Button + Mode Selector)
- ⏳ Add White button
- ⏳ 3-button vs 4-button mode selection
- ⏳ Mode selector switch logic

### Phase 3: Difficulty Control
- ⏳ 8-position difficulty selector
- ⏳ Dynamic timing adjustment
- ⏳ Easy, Normal, Hard presets

## 📖 Getting Started

1. **Review the Implementation Guide**: Open `SimonSays_Implementation_Guide.md` for complete details

2. **Set up Hardware**: 
   - Wire buttons according to the wiring table
   - Connect I/O modules to PLC
   - Apply 24V power

3. **Configure Sysmac Studio**:
   - Create new project with NX102-1100 CPU
   - Add I/O modules (NX-ID4442, NX-OD4256)
   - Map inputs and outputs

4. **Program the PLC**:
   - Use ladder logic from `.ld` files or
   - Follow step-by-step instructions in Implementation Guide
   - Test each section as you build

5. **Test and Debug**:
   - Start with power-on test
   - Verify button inputs
   - Test sequence generation
   - Validate game logic

## 🎮 Game Rules

1. **Start**: Flip the selector switch to start position
2. **Watch**: PLC flashes a sequence of buttons
3. **Repeat**: Press the buttons in the same order
4. **Continue**: Each round adds one more button to the sequence
5. **Game Over**: Wrong button or timeout ends the game
6. **Restart**: Flip selector switch again to play another round

## 📝 Key Variables

### Game State (`%MW0`)
- 0 = Off
- 1 = Ready (generating sequence)
- 2 = Sequence_Play (flashing buttons)
- 3 = Wait_Input (waiting for user)
- 4 = Game_Over (game ended)

### Timing Parameters (Phase 1 defaults)
- Flash Duration: 500 ms
- Gap Duration: 200 ms
- Input Timeout: 3000 ms (3 seconds)
- Debounce Time: 50 ms

## 🔍 Troubleshooting

### Buttons Not Responding
- Check +24V and 0V connections
- Verify input wiring (Pin 4 to DI)
- Test button with multimeter

### LEDs Not Lighting
- Check output wiring (Pin 2 to DO)
- Verify output configuration in Sysmac Studio
- Test LED with external power

### Timing Issues
- Use hardware timers instead of software counters
- Check PLC scan time
- Adjust timing constants in code

## 📚 Additional Resources

- **Omron NX102 Manual**: [industrial.omron.com](https://industrial.omron.com/)
- **Sysmac Studio Documentation**: [automation.omron.com](https://automation.omron.com/)
- **Ladder Logic Tutorials**: Various online PLC programming resources

## 🚀 Next Steps

1. ✅ **Phase 1 Complete**: Basic 3-button game working
2. ⏳ **Phase 2**: Add 4th button and mode selection
3. ⏳ **Phase 3**: Implement difficulty control
4. ⏳ **Enhancements**: Consider adding score display, sounds, etc.

## 📞 Support

For detailed implementation instructions, troubleshooting, and advanced features, refer to:
- `SimonSays_Implementation_Guide.md` - Complete technical documentation

---

**Project Status**: Phase 1 Implementation Complete  
**Last Updated**: October 1, 2025  
**Platform**: Omron NX102-1100 with Sysmac Studio  
**Programming Language**: Ladder Logic (LD)

Good luck with your Simon Says project! 🎮✨
