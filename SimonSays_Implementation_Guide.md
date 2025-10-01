# Simon Says Game - Ladder Logic Implementation Guide
## For Omron NX102-1100 PLC with Sysmac Studio

---

## Project Overview

This guide provides a complete implementation of a Simon Says game using ladder logic on an Omron NX102-1100 PLC. The project is designed in three phases, progressing from a simple 3-button game to a full-featured 4-button game with difficulty control.

### Hardware Configuration

#### Power Supply
- **RS PRO LI60-20B24PR2** (24 V DC, 2.5 A DIN-rail SMPS)

#### PLC & CPU
- **Omron NX102-1100** (NX1 Series CPU Unit)
- **NX Power Supply Unit**

#### I/O Modules
- **Omron NX-ID4442** (Digital Input Unit, 64 channels)
- **Omron NX-OD4256** (Digital Output Unit, 32 channels)
- **Omron AD3203** (Analog Input Unit)
- **Omron LW0600** (Unit)

#### Operator Devices
- **3 × RAFI RAMO 22 T Hybrid Pilot Light Pushbuttons** (M12, 4-pin, 1NO + LED)
  - Yellow Button
  - Blue Button
  - Red Button
- **1 × Illuminated Pushbutton** (White - Phase 2)
- **1 × Selector Switch, 3-position** (Mode selection)
- **1 × Selector Switch, 8-position** (Difficulty selection - Phase 3)

---

## Phase 1: Minimal Core (3 Buttons)

### I/O Mapping

#### Digital Inputs (NX-ID4442)
| Input | Function | Button Color | Pin Connection |
|-------|----------|--------------|----------------|
| DI1   | Yellow Button Contact | Yellow | M12 Pin 4 (Black) |
| DI3   | Blue Button Contact | Blue | M12 Pin 4 (Black) |
| DI5   | Red Button Contact | Red | M12 Pin 4 (Black) |
| DI7   | Start/Stop Selector | - | Selector Switch |

#### Digital Outputs (NX-OD4256)
| Output | Function | Button Color | Pin Connection |
|--------|----------|--------------|----------------|
| DO0    | Red LED | Red | M12 Pin 2 (White) |
| DO1    | Blue LED | Blue | M12 Pin 2 (White) |
| DO2    | Yellow LED | Yellow | M12 Pin 2 (White) |

### Button Wiring (M12 A-coded, 4-pin)

| Button | Pin | Wire Color | Function | Connects To |
|--------|-----|------------|----------|-------------|
| Yellow | 1   | Brown      | Contact COM | +24 V terminal block |
|        | 2   | White      | LED +    | DO2 (NX-OD4256) |
|        | 3   | Blue       | LED –    | 0 V terminal block |
|        | 4   | Black      | Contact IN | DI1 (NX-ID4442) |
| Blue   | 1   | Brown      | Contact COM | +24 V terminal block |
|        | 2   | White      | LED +    | DO1 (NX-OD4256) |
|        | 3   | Blue       | LED –    | 0 V terminal block |
|        | 4   | Black      | Contact IN | DI3 (NX-ID4442) |
| Red    | 1   | Brown      | Contact COM | +24 V terminal block |
|        | 2   | White      | LED +    | DO0 (NX-OD4256) |
|        | 3   | Blue       | LED –    | 0 V terminal block |
|        | 4   | Black      | Contact IN | DI5 (NX-ID4442) |

### Variable Definitions

#### Game State Variables
- `%MW0` - Game_State (0=Off, 1=Ready, 2=Sequence_Play, 3=Wait_Input, 4=Game_Over)
- `%MW1` - Sequence_Length (Current sequence length, 1-10)
- `%MW2` - Play_Step (Current step in sequence playback)
- `%MW3` - Input_Step (Current step in user input)
- `%MW4` - Score (Player's score)

#### Timing Variables
- `%MW10` - Flash_Timer (Timer for button flash duration, ms)
- `%MW11` - Gap_Timer (Timer for gap between flashes, ms)
- `%MW12` - Input_Timer (Timer for user input timeout, ms)
- `%MW13` - Debounce_Timer (Button debounce timer, ms)
- `%MW14` - Game_Timer (General game timer, ms)

#### Button State Variables
- `%MW20` - Yellow_Pressed (Yellow button press detection)
- `%MW21` - Blue_Pressed (Blue button press detection)
- `%MW22` - Red_Pressed (Red button press detection)
- `%MW23` - Current_Button (Current button being processed)
- `%MW24` - Button_State (Current button state)
- `%MW25` - Expected_Button (Expected button for current step)
- `%MW26` - User_Input (User's button press: 1=Yellow, 2=Blue, 3=Red)

#### Sequence Storage (10 steps max)
- `%MW30` - Seq_1 (Step 1: 1=Yellow, 2=Blue, 3=Red)
- `%MW31` - Seq_2
- `%MW32` - Seq_3
- `%MW33` - Seq_4
- `%MW34` - Seq_5
- `%MW35` - Seq_6
- `%MW36` - Seq_7
- `%MW37` - Seq_8
- `%MW38` - Seq_9
- `%MW39` - Seq_10

---

## Game Logic Flow

### State Machine Overview

```
State 0: Off
    ↓ (Start Switch ON)
State 1: Ready (Generate/Extend Sequence)
    ↓
State 2: Sequence_Play (Flash buttons)
    ↓ (Sequence complete)
State 3: Wait_Input (User input)
    ↓ (Correct) → Back to State 1
    ↓ (Wrong/Timeout)
State 4: Game_Over (Flash all buttons)
    ↓ (Start Switch ON)
Back to State 1
```

### Key Timing Parameters (Phase 1)

- **Flash Duration**: 500 ms (button LED on time)
- **Gap Duration**: 200 ms (time between button flashes)
- **Input Timeout**: 3000 ms (3 seconds per user input)
- **Debounce Time**: 50 ms (button debounce)

---

## Implementation Strategy

### 1. Initialization (First Scan)

```
[%SM0.1]  // First scan flag
    MOV 0, %MW0        // Game state = Off
    MOV 0, %MW1        // Sequence length = 0
    MOV 0, %MW4        // Score = 0
    MOV 0, %MW10       // Reset all timers
    MOV 0, %MW11
    MOV 0, %MW12
    MOV 0, %MW13
    MOV 0, %MW14
```

### 2. State 0: Off - Wait for Start

```
[%MW0 = 0]
    // Turn off all LEDs
    CLR %DO0
    CLR %DO1
    CLR %DO2
    
    // Check for start condition
    [%DI7 = 1]
        MOV 1, %MW0        // Move to Ready state
        MOV 0, %MW1        // Reset sequence length
        MOV 0, %MW4        // Reset score
        MOV 0, %MW2        // Reset play step
        MOV 0, %MW3        // Reset input step
```

### 3. State 1: Ready - Generate/Extend Sequence

```
[%MW0 = 1]
    // Increment sequence length
    ADD 1, %MW1
    
    // Generate random button for new step
    // Use system time or random number generator
    // For simplicity, use a pseudo-random pattern:
    MOV %MW1, %MW26    // Current length as seed
    MOD 3, %MW26       // Modulo 3 (0, 1, 2)
    ADD 1, %MW26       // Make it 1, 2, or 3
    
    // Store new step in sequence array
    [%MW1 = 1]
        MOV %MW26, %MW30
    [%MW1 = 2]
        MOV %MW26, %MW31
    [%MW1 = 3]
        MOV %MW26, %MW32
    [%MW1 = 4]
        MOV %MW26, %MW33
    [%MW1 = 5]
        MOV %MW26, %MW34
    [%MW1 = 6]
        MOV %MW26, %MW35
    [%MW1 = 7]
        MOV %MW26, %MW36
    [%MW1 = 8]
        MOV %MW26, %MW37
    [%MW1 = 9]
        MOV %MW26, %MW38
    [%MW1 = 10]
        MOV %MW26, %MW39
    
    // Move to Sequence_Play state
    MOV 2, %MW0
    MOV 0, %MW2        // Reset play step
    MOV 0, %MW10       // Reset flash timer
    MOV 0, %MW11       // Reset gap timer
```

### 4. State 2: Sequence_Play - Flash Buttons

```
[%MW0 = 2]
    // Check if gap timer is active (between flashes)
    [%MW11 > 0]
        ADD 1, %MW11   // Increment gap timer
        [%MW11 > 200]  // 200ms gap
            MOV 0, %MW11   // Reset gap timer
            ADD 1, %MW2    // Move to next step
    
    // If no gap active, flash current button
    [%MW11 = 0]
        // Get current step value
        [%MW2 = 0]
            MOV %MW30, %MW23
        [%MW2 = 1]
            MOV %MW31, %MW23
        [%MW2 = 2]
            MOV %MW32, %MW23
        [%MW2 = 3]
            MOV %MW33, %MW23
        [%MW2 = 4]
            MOV %MW34, %MW23
        [%MW2 = 5]
            MOV %MW35, %MW23
        [%MW2 = 6]
            MOV %MW36, %MW23
        [%MW2 = 7]
            MOV %MW37, %MW23
        [%MW2 = 8]
            MOV %MW38, %MW23
        [%MW2 = 9]
            MOV %MW39, %MW23
        
        // Flash the appropriate button
        [%MW23 = 1]
            SET %DO2       // Yellow LED
        [%MW23 = 2]
            SET %DO1       // Blue LED
        [%MW23 = 3]
            SET %DO0       // Red LED
        
        // Increment flash timer
        ADD 1, %MW10
        
        // Check if flash complete
        [%MW10 > 500]      // 500ms flash duration
            CLR %DO0       // Turn off all LEDs
            CLR %DO1
            CLR %DO2
            MOV 0, %MW10   // Reset flash timer
            MOV 1, %MW11   // Start gap timer
    
    // Check if sequence playback complete
    [%MW2 >= %MW1]
        MOV 3, %MW0        // Move to Wait_Input state
        MOV 0, %MW3        // Reset input step
        MOV 0, %MW12       // Reset input timer
        CLR %DO0           // Turn off all LEDs
        CLR %DO1
        CLR %DO2
```

### 5. State 3: Wait_Input - User Input

```
[%MW0 = 3]
    // Increment input timer
    ADD 1, %MW12
    
    // Check for timeout
    [%MW12 > 3000]
        MOV 4, %MW0        // Move to Game_Over state
    
    // Increment debounce timer
    ADD 1, %MW13
    
    // Check for button presses (after debounce)
    [%MW13 > 50]           // 50ms debounce
        // Yellow button pressed
        [%DI1 = 1]
            MOV 1, %MW26   // User input = Yellow
            CALL Check_Input
        
        // Blue button pressed
        [%DI3 = 1]
            MOV 2, %MW26   // User input = Blue
            CALL Check_Input
        
        // Red button pressed
        [%DI5 = 1]
            MOV 3, %MW26   // User input = Red
            CALL Check_Input
```

### 6. Check_Input Subroutine

```
Check_Input:
    // Get expected input for current step
    [%MW3 = 0]
        MOV %MW30, %MW25
    [%MW3 = 1]
        MOV %MW31, %MW25
    [%MW3 = 2]
        MOV %MW32, %MW25
    [%MW3 = 3]
        MOV %MW33, %MW25
    [%MW3 = 4]
        MOV %MW34, %MW25
    [%MW3 = 5]
        MOV %MW35, %MW25
    [%MW3 = 6]
        MOV %MW36, %MW25
    [%MW3 = 7]
        MOV %MW37, %MW25
    [%MW3 = 8]
        MOV %MW38, %MW25
    [%MW3 = 9]
        MOV %MW39, %MW25
    
    // Compare user input with expected
    [%MW26 = %MW25]
        // Correct input
        // Flash the pressed button briefly
        [%MW26 = 1]
            SET %DO2       // Yellow LED
        [%MW26 = 2]
            SET %DO1       // Blue LED
        [%MW26 = 3]
            SET %DO0       // Red LED
        
        // Wait for button release
        [%DI1 = 0]
        [%DI3 = 0]
        [%DI5 = 0]
            CLR %DO0
            CLR %DO1
            CLR %DO2
            
            ADD 1, %MW3    // Move to next input step
            MOV 0, %MW12   // Reset input timer
            MOV 0, %MW13   // Reset debounce timer
            
            // Check if sequence complete
            [%MW3 >= %MW1]
                ADD 1, %MW4    // Increment score
                MOV 1, %MW0    // Move to Ready state for next sequence
    
    [%MW26 <> %MW25]
        // Wrong input
        MOV 4, %MW0        // Move to Game_Over state
        MOV 0, %MW13       // Reset debounce timer
    
    RET
```

### 7. State 4: Game_Over - Flash All Buttons

```
[%MW0 = 4]
    // Flash all buttons 3 times
    [%MW10 < 1800]         // 3 flashes * 600ms each
        [%MW10 % 600 < 300]
            SET %DO0       // Red LED
            SET %DO1       // Blue LED
            SET %DO2       // Yellow LED
        [%MW10 % 600 >= 300]
            CLR %DO0       // Turn off all LEDs
            CLR %DO1
            CLR %DO2
        ADD 1, %MW10
    
    [%MW10 >= 1800]
        CLR %DO0
        CLR %DO1
        CLR %DO2
        
        // Wait for restart
        [%DI7 = 1]
            MOV 1, %MW0    // Restart game
            MOV 0, %MW10   // Reset timer
```

---

## Phase 2: Adding 4th Button (White) and Mode Selection

### Additional I/O Mapping

#### Digital Inputs
| Input | Function |
|-------|----------|
| DI6   | White Button Contact |
| DI8   | Mode Selector (Left position) |
| DI9   | Mode Selector (Right position) |

#### Digital Outputs
| Output | Function |
|--------|----------|
| DO3    | White LED |

### Additional Variables
- `%MW5` - Game_Mode (0=3-button, 1=4-button)
- `%MW27` - White_Pressed

### Mode Selection Logic

```
// In State 0: Off
[%MW0 = 0]
    // Check mode selector
    [%DI8 = 1]
        MOV 0, %MW5    // 3-button mode
    [%DI9 = 1]
        MOV 1, %MW5    // 4-button mode
```

### Sequence Generation Update

```
// In State 1: Ready
[%MW0 = 1]
    // Generate random button
    [%MW5 = 0]
        // 3-button mode (1, 2, 3)
        MOD 3, %MW26
        ADD 1, %MW26
    [%MW5 = 1]
        // 4-button mode (1, 2, 3, 4)
        MOD 4, %MW26
        ADD 1, %MW26
```

---

## Phase 3: Difficulty Control

### Additional I/O Mapping

#### Digital Inputs (8-position selector)
| Input | Function | Difficulty |
|-------|----------|------------|
| DI10  | Difficulty Bit 0 | |
| DI11  | Difficulty Bit 1 | |
| DI12  | Difficulty Bit 2 | |

### Additional Variables
- `%MW6` - Difficulty (0-7)
- `%MW50` - Flash_Duration (ms, varies by difficulty)
- `%MW51` - Gap_Duration (ms, varies by difficulty)
- `%MW52` - Input_Timeout (ms, varies by difficulty)

### Difficulty Parameters

| Difficulty | Flash (ms) | Gap (ms) | Timeout (ms) |
|------------|------------|----------|--------------|
| 0 (Easy)   | 800        | 400      | 5000         |
| 1 (Normal) | 500        | 200      | 3000         |
| 2 (Hard)   | 300        | 100      | 2000         |
| 3-7 (Custom) | User-defined | User-defined | User-defined |

### Difficulty Selection Logic

```
// In State 0: Off
[%MW0 = 0]
    // Read difficulty selector
    MOV 0, %MW6
    [%DI10 = 1]
        ADD 1, %MW6
    [%DI11 = 1]
        ADD 2, %MW6
    [%DI12 = 1]
        ADD 4, %MW6
    
    // Set timing parameters based on difficulty
    [%MW6 = 0]
        MOV 800, %MW50     // Flash duration
        MOV 400, %MW51     // Gap duration
        MOV 5000, %MW52    // Input timeout
    [%MW6 = 1]
        MOV 500, %MW50
        MOV 200, %MW51
        MOV 3000, %MW52
    [%MW6 = 2]
        MOV 300, %MW50
        MOV 100, %MW51
        MOV 2000, %MW52
```

---

## Implementation Notes for Sysmac Studio

### Creating the Project

1. **Open Sysmac Studio**
2. **Create New Project**:
   - CPU Type: NX102-1100
   - Programming Language: Ladder Diagram (LD)
3. **Configure I/O**:
   - Add NX-ID4442 (Digital Input Unit)
   - Add NX-OD4256 (Digital Output Unit)
   - Map inputs and outputs as described above

### Programming Tips

1. **Use Function Blocks**: Create function blocks for:
   - Sequence generation
   - Button flash control
   - Input validation
   - Timer management

2. **Use Subroutines**: Break down complex logic into subroutines:
   - `Generate_Sequence`
   - `Play_Sequence_Step`
   - `Check_User_Input`
   - `Game_Over_Flash`

3. **Timing Considerations**:
   - Sysmac Studio scans the ladder diagram cyclically
   - Scan time varies based on program complexity
   - For ms-level timing, consider using hardware timers or system time functions

4. **Debugging**:
   - Use online monitoring to watch variable values
   - Set breakpoints to troubleshoot logic flow
   - Use data trace to record button presses and sequence progression

### Hardware Timer Implementation

For more accurate timing, use hardware timers instead of software counters:

```
// Flash timer (TON - Timer On Delay)
TON Flash_TON
    IN: %MW0 = 2          // Active in Sequence_Play state
    PT: %MW50             // Flash duration (from difficulty)
    Q: Flash_Complete     // Output when timer expires
    ET: %MW10             // Elapsed time

// Gap timer
TON Gap_TON
    IN: Flash_Complete
    PT: %MW51             // Gap duration
    Q: Gap_Complete
    ET: %MW11

// Input timeout timer
TON Input_TON
    IN: %MW0 = 3          // Active in Wait_Input state
    PT: %MW52             // Input timeout
    Q: Input_Timeout
    ET: %MW12
```

---

## Testing Strategy

### Phase 1 Testing

1. **Power On Test**:
   - Verify all LEDs off on startup
   - Check selector switch detection

2. **Sequence Generation Test**:
   - Start game and verify first sequence plays
   - Verify sequence length increments correctly

3. **Button Input Test**:
   - Test correct button presses
   - Test wrong button presses
   - Verify game over condition

4. **Timing Test**:
   - Measure flash duration
   - Measure gap duration
   - Verify input timeout

### Phase 2 Testing

1. **Mode Selection Test**:
   - Verify 3-button mode works correctly
   - Verify 4-button mode includes white button
   - Test mode switching between games

2. **4-Button Sequence Test**:
   - Verify all 4 buttons appear in sequence
   - Test random distribution of buttons

### Phase 3 Testing

1. **Difficulty Selection Test**:
   - Verify each difficulty level sets correct timings
   - Test easy mode (longer times)
   - Test hard mode (shorter times)

2. **Advanced Gameplay Test**:
   - Play full game at each difficulty level
   - Verify score tracking
   - Test game restart

---

## Troubleshooting

### Common Issues

#### Issue: Buttons not responding
**Solution**:
- Check wiring: Pin 1 (Brown) to +24V, Pin 4 (Black) to DI
- Verify input is configured as sink/source correctly
- Test button with multimeter

#### Issue: LEDs not lighting
**Solution**:
- Check wiring: Pin 2 (White) to DO, Pin 3 (Blue) to 0V
- Verify output is configured correctly
- Test LED with external power source

#### Issue: Timing inaccurate
**Solution**:
- Use hardware timers instead of software counters
- Verify PLC scan time
- Adjust timing constants

#### Issue: Random sequence not random
**Solution**:
- Use system time as seed for random number generator
- Implement better pseudo-random algorithm
- Consider using external random source

---

## Enhancements and Future Work

### Possible Enhancements

1. **Score Display**:
   - Add 7-segment display or LCD
   - Display current score and high score
   - Store high score in non-volatile memory

2. **Sound Effects**:
   - Add buzzer for button presses
   - Different tones for each button
   - Sound effects for correct/wrong input

3. **Multiplayer Mode**:
   - Add second set of buttons
   - Turn-based gameplay
   - Score competition

4. **Advanced Patterns**:
   - Add pattern modes (e.g., ascending, descending)
   - Add rhythm mode (timing matters)
   - Add memory mode (show all at once)

5. **Network Connectivity**:
   - Log game statistics to database
   - Remote monitoring and control
   - Online leaderboard

---

## Conclusion

This implementation guide provides a complete framework for creating a Simon Says game on an Omron NX102-1100 PLC using ladder logic. The phased approach allows for incremental development and testing, ensuring each feature works before moving to the next.

Start with Phase 1 to get the basic game working, then expand to Phase 2 for the 4-button mode, and finally add Phase 3 for difficulty control. Each phase builds on the previous one, making the development process manageable and logical.

Remember to test thoroughly at each phase and document any changes or improvements you make to the logic. Good luck with your project!

---

## References

- **Omron NX102-1100 Manual**: [Omron Industrial Automation](https://industrial.omron.com/)
- **Sysmac Studio User Manual**: [Sysmac Studio Documentation](https://automation.omron.com/en/us/products/family/Sysmac%20Studio)
- **Ladder Logic Programming Guide**: [PLC Programming Basics](https://www.plcacademy.com/)
- **RAFI RAMO 22 T Datasheet**: [RAFI Product Information](https://rafi-group.com/)

---

**Document Version**: 1.0  
**Last Updated**: October 1, 2025  
**Author**: PLC Programming Assistant
