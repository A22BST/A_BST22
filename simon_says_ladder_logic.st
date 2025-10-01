(* 
Simon Says Game - Ladder Logic Implementation
Phase 1: 3 Buttons (Red, Blue, Yellow)
For Omron NX102-1100 PLC with Sysmac Studio

Author: Assistant
Date: 2025-10-01
Version: 1.0
*)

PROGRAM SimonSaysGame
VAR
    // Local working variables
    i : INT;
    ButtonPressed : INT;
    SequenceMatch : BOOL;
END_VAR

(* ========================================
   RUNG 1: INPUT MAPPING AND EDGE DETECTION
   ======================================== *)

// Map physical inputs to variables
RedButton_Input := %IX0.5;      // DI5
BlueButton_Input := %IX0.3;     // DI3  
YellowButton_Input := %IX0.1;   // DI1

// Edge detection for button presses
RedButton_Rising := RedButton_Input AND NOT RedButton_Prev;
BlueButton_Rising := BlueButton_Input AND NOT BlueButton_Prev;
YellowButton_Rising := YellowButton_Input AND NOT YellowButton_Prev;

// Store previous states
RedButton_Prev := RedButton_Input;
BlueButton_Prev := BlueButton_Input;
YellowButton_Prev := YellowButton_Input;

(* ========================================
   RUNG 2: GAME INITIALIZATION
   ======================================== *)

// Initialize game on first scan or reset
IF FIRST_SCAN OR GameReset THEN
    GameState := 0;             // Idle state
    GameActive := FALSE;
    CurrentLevel := 1;
    SequenceLength := 1;
    PlaybackIndex := 0;
    InputIndex := 1;
    GameReset := FALSE;
    
    // Clear sequence array
    FOR i := 1 TO MaxLevel DO
        GameSequence[i] := 0;
    END_FOR;
    
    // Initialize random seed with system time
    RandomSeed := DWORD_TO_TIME(TIME());
END_IF;

(* ========================================
   RUNG 3: GAME START TRIGGER
   ======================================== *)

// Start game when any button is pressed in idle state
IF GameState = 0 AND (RedButton_Rising OR BlueButton_Rising OR YellowButton_Rising) THEN
    GameState := 1;             // Generate new sequence
    GameActive := TRUE;
    CurrentLevel := 1;
    SequenceLength := 1;
    GameWon := FALSE;
    GameLost := FALSE;
END_IF;

(* ========================================
   RUNG 4: RANDOM SEQUENCE GENERATION
   ======================================== *)

// Generate new sequence element
IF GameState = 1 THEN
    // Simple linear congruential generator for random numbers
    RandomValue := (RandomSeed * 1103515245 + 12345) MOD 16#7FFFFFFF;
    RandomSeed := RandomValue;
    
    // Convert to button number (1=Red, 2=Blue, 3=Yellow)
    NextButton := (INT(RandomValue MOD 3)) + 1;
    
    // Add to sequence
    GameSequence[SequenceLength] := NextButton;
    
    // Move to playback state
    GameState := 2;
    PlaybackIndex := 1;
    PlaybackActive := TRUE;
    
    // Start first flash timer
    FlashTimer.IN := TRUE;
    FlashTimer.PT := FLASH_TIME;
END_IF;

(* ========================================
   RUNG 5: SEQUENCE PLAYBACK LOGIC
   ======================================== *)

// Handle LED flashing during playback
IF GameState = 2 AND PlaybackActive THEN
    
    // Flash current button in sequence
    CASE GameSequence[PlaybackIndex] OF
        1: RedLED_Output := FlashTimer.IN AND NOT FlashTimer.Q;      // Red
        2: BlueLED_Output := FlashTimer.IN AND NOT FlashTimer.Q;     // Blue  
        3: YellowLED_Output := FlashTimer.IN AND NOT FlashTimer.Q;   // Yellow
    END_CASE;
    
    // When flash timer expires, start gap timer
    IF FlashTimer.Q THEN
        FlashTimer.IN := FALSE;
        GapTimer.IN := TRUE;
        GapTimer.PT := GAP_TIME;
        
        // Turn off all LEDs during gap
        RedLED_Output := FALSE;
        BlueLED_Output := FALSE;
        YellowLED_Output := FALSE;
    END_IF;
    
    // When gap timer expires, move to next button or finish playback
    IF GapTimer.Q THEN
        GapTimer.IN := FALSE;
        PlaybackIndex := PlaybackIndex + 1;
        
        IF PlaybackIndex > SequenceLength THEN
            // Playback complete, start input phase
            PlaybackActive := FALSE;
            GameState := 3;
            InputIndex := 1;
            InputTimer.IN := TRUE;
            InputTimer.PT := INPUT_TIMEOUT;
        ELSE
            // Start next flash
            FlashTimer.IN := TRUE;
            FlashTimer.PT := FLASH_TIME;
        END_IF;
    END_IF;
END_IF;

// Call timer function blocks
FlashTimer();
GapTimer();

(* ========================================
   RUNG 6: PLAYER INPUT HANDLING
   ======================================== *)

// Handle player input during input phase
IF GameState = 3 THEN
    
    // Determine which button was pressed
    ButtonPressed := 0;
    IF RedButton_Rising THEN
        ButtonPressed := 1;
        LastButtonPressed := 1;
    ELSIF BlueButton_Rising THEN
        ButtonPressed := 2;
        LastButtonPressed := 2;
    ELSIF YellowButton_Rising THEN
        ButtonPressed := 3;
        LastButtonPressed := 3;
    END_IF;
    
    // Process button press
    IF ButtonPressed > 0 THEN
        // Check if correct button
        IF ButtonPressed = GameSequence[InputIndex] THEN
            CorrectSequence := TRUE;
            InputIndex := InputIndex + 1;
            
            // Reset input timer for next button
            InputTimer.IN := FALSE;
            InputTimer.IN := TRUE;
            InputTimer.PT := INPUT_TIMEOUT;
            
            // Check if sequence complete
            IF InputIndex > SequenceLength THEN
                // Level complete!
                GameState := 4;  // Success state
                SuccessTimer.IN := TRUE;
                SuccessTimer.PT := SUCCESS_DELAY;
            END_IF;
        ELSE
            // Wrong button - game over
            CorrectSequence := FALSE;
            GameState := 5;  // Fail state
            GameLost := TRUE;
        END_IF;
    END_IF;
    
    // Check for input timeout
    IF InputTimer.Q THEN
        GameState := 5;  // Fail state
        GameLost := TRUE;
        InputTimeout := TRUE;
    END_IF;
    
    InputTimer();
END_IF;

(* ========================================
   RUNG 7: SUCCESS HANDLING
   ======================================== *)

// Handle successful level completion
IF GameState = 4 THEN
    
    // Flash all LEDs to indicate success
    RedLED_Output := TRUE;
    BlueLED_Output := TRUE;
    YellowLED_Output := TRUE;
    
    // When success timer expires, advance to next level
    IF SuccessTimer.Q THEN
        SuccessTimer.IN := FALSE;
        CurrentLevel := CurrentLevel + 1;
        SequenceLength := SequenceLength + 1;
        
        // Check if game won (max level reached)
        IF CurrentLevel > MaxLevel THEN
            GameWon := TRUE;
            GameState := 0;  // Return to idle
            GameActive := FALSE;
        ELSE
            // Generate next level
            GameState := 1;
        END_IF;
        
        // Turn off success LEDs
        RedLED_Output := FALSE;
        BlueLED_Output := FALSE;
        YellowLED_Output := FALSE;
    END_IF;
    
    SuccessTimer();
END_IF;

(* ========================================
   RUNG 8: FAILURE HANDLING
   ======================================== *)

// Handle game failure
IF GameState = 5 THEN
    
    // Flash all LEDs rapidly to indicate failure
    IF (TIME() MOD T#200ms) < T#100ms THEN
        RedLED_Output := TRUE;
        BlueLED_Output := TRUE;
        YellowLED_Output := TRUE;
    ELSE
        RedLED_Output := FALSE;
        BlueLED_Output := FALSE;
        YellowLED_Output := FALSE;
    END_IF;
    
    // Auto-reset after 3 seconds
    IF NOT SuccessTimer.IN THEN
        SuccessTimer.IN := TRUE;
        SuccessTimer.PT := T#3000ms;
    END_IF;
    
    IF SuccessTimer.Q THEN
        GameReset := TRUE;
        SuccessTimer.IN := FALSE;
    END_IF;
    
    SuccessTimer();
END_IF;

(* ========================================
   RUNG 9: OUTPUT MAPPING
   ======================================== *)

// Map LED outputs to physical outputs
%QX0.0 := RedLED_Output;        // DO0
%QX0.1 := BlueLED_Output;       // DO1  
%QX0.2 := YellowLED_Output;     // DO2

(* ========================================
   RUNG 10: STATUS AND DEBUG
   ======================================== *)

// Update debug status string
CASE GameState OF
    0: DebugState := 'IDLE - Press any button to start';
    1: DebugState := 'GENERATING sequence';
    2: DebugState := 'PLAYBACK - Watch the sequence';
    3: DebugState := 'INPUT - Repeat the sequence';
    4: DebugState := 'SUCCESS - Level complete!';
    5: DebugState := 'FAILED - Game over';
END_CASE;

// Test mode - all LEDs on (for testing)
IF AllLEDs_Test THEN
    %QX0.0 := TRUE;  // Red LED
    %QX0.1 := TRUE;  // Blue LED
    %QX0.2 := TRUE;  // Yellow LED
END_IF;

END_PROGRAM