# Simon Says Variable Definitions

## Global Variables for Sysmac Studio

### Input/Output Variables
```
// Digital Inputs
VAR_GLOBAL
    RedButton_Input     : BOOL;     // DI5 - Red button contact
    BlueButton_Input    : BOOL;     // DI3 - Blue button contact  
    YellowButton_Input  : BOOL;     // DI1 - Yellow button contact
END_VAR

// Digital Outputs  
VAR_GLOBAL
    RedLED_Output       : BOOL;     // DO0 - Red LED
    BlueLED_Output      : BOOL;     // DO1 - Blue LED
    YellowLED_Output    : BOOL;     // DO2 - Yellow LED
END_VAR
```

### Game State Variables
```
VAR_GLOBAL
    // Game States
    GameState           : INT;      // 0=Idle, 1=Generate, 2=Playback, 3=Input, 4=Success, 5=Fail
    GameActive          : BOOL;     // TRUE when game is running
    GameReset           : BOOL;     // Reset game to beginning
    
    // Sequence Management
    GameSequence        : ARRAY[1..20] OF INT;  // Stores button sequence (1=Red, 2=Blue, 3=Yellow)
    SequenceLength      : INT;      // Current length of sequence
    CurrentLevel        : INT;      // Current game level (starts at 1)
    MaxLevel            : INT := 20; // Maximum sequence length
    
    // Playback Control
    PlaybackIndex       : INT;      // Current position in playback
    PlaybackActive      : BOOL;     // TRUE during LED playback
    
    // Input Control  
    InputIndex          : INT;      // Current expected input position
    InputReceived       : BOOL;     // TRUE when valid input received
    InputTimeout        : BOOL;     // TRUE when input times out
    
    // Button Edge Detection
    RedButton_Rising    : BOOL;     // Rising edge of red button
    BlueButton_Rising   : BOOL;     // Rising edge of blue button
    YellowButton_Rising : BOOL;     // Rising edge of yellow button
    RedButton_Prev      : BOOL;     // Previous state for edge detection
    BlueButton_Prev     : BOOL;     // Previous state for edge detection
    YellowButton_Prev   : BOOL;     // Previous state for edge detection
END_VAR
```

### Timer Variables
```
VAR_GLOBAL
    // Timing Control
    FlashTimer          : TON;      // Timer for LED flash duration
    GapTimer            : TON;      // Timer for gap between flashes
    InputTimer          : TON;      // Timer for input timeout
    SuccessTimer        : TON;      // Timer for success delay
    
    // Timing Constants
    FLASH_TIME          : TIME := T#500ms;   // LED flash duration
    GAP_TIME            : TIME := T#300ms;   // Gap between LED flashes
    INPUT_TIMEOUT       : TIME := T#3000ms;  // Input timeout per button
    SUCCESS_DELAY       : TIME := T#1000ms;  // Delay after successful level
END_VAR
```

### Random Number Generation
```
VAR_GLOBAL
    // Random Number Generation
    RandomSeed          : DWORD;    // Seed for random number generator
    RandomValue         : DWORD;    // Current random value
    NextButton          : INT;      // Next button in sequence (1-3)
END_VAR
```

### Status and Debug Variables
```
VAR_GLOBAL
    // Status Indicators
    AllLEDs_Test        : BOOL;     // Test mode - all LEDs on
    GameWon             : BOOL;     // TRUE when max level reached
    GameLost            : BOOL;     // TRUE when player fails
    
    // Debug/Monitoring
    DebugState          : STRING;   // Human readable game state
    LastButtonPressed   : INT;      // Last button pressed by player
    CorrectSequence     : BOOL;     // TRUE if current input is correct
END_VAR
```