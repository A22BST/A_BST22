PROGRAM GameFlow_Logic
VAR
    // Existing variables
    B : BOOL;                    // Button trigger
    RandN : REAL;                // Random number 0.0-1.0
    L_N : INT;                   // LED number (1-3)
    WriteIndex : LINT := 0;      // Array write index
    Idx : INT;                   // Converted index for array access
    ArrayFull : BOOL := FALSE;   // Array full flag
    
    // Array declarations
    GameFlow_S : ARRAY[0..49] OF INT;     // Source array
    GameFlow_SN : ARRAY[0..49] OF INT;    // New array for reset
    
    // Reset signal handling
    ResetSignal : BOOL;          // Reset signal input
    ResetTrigger : BOOL;         // Rising edge detection for reset
    
    // LED control variables
    OLED_R : BOOL;               // Red LED
    OLED_B : BOOL;               // Blue LED  
    OLED_Y : BOOL;               // Yellow LED
    
    // Game over sequence variables
    GameOverActive : BOOL := FALSE;
    GameOverTimer : TIME := T#0s;
    GameOverStep : INT := 0;
    GameOverStepTime : TIME := T#1s;  // 1 second per step
    
    // LED sequence pattern (1=Red, 2=Blue, 3=Yellow)
    LEDSequence : ARRAY[0..8] OF INT := [1, 2, 3, 1, 2, 3, 1, 2, 3];
    SequenceIndex : INT := 0;
    
END_VAR

// Rising edge detection for button
Trig_Start(Clk := IBTN_B, Q => B);

// Rising edge detection for reset signal
Trig_Start(Clk := ResetSignal, Q => ResetTrigger);

// Reset signal handling
IF ResetTrigger THEN
    // Add current game flow to array when reset is triggered
    AryAddV(In1 := GameFlow_S[0], In2 := L_N, Size := 50, AryOut := GameFlow_SN[0]);
    
    // Start game over sequence
    GameOverActive := TRUE;
    GameOverTimer := T#0s;
    GameOverStep := 0;
    SequenceIndex := 0;
END_IF;

// Game over LED sequence
IF GameOverActive THEN
    GameOverTimer := GameOverTimer + T#10ms;  // Increment timer (assuming 10ms cycle)
    
    // Check if it's time for next step
    IF GameOverTimer >= GameOverStepTime THEN
        GameOverTimer := T#0s;
        GameOverStep := GameOverStep + 1;
        
        // Turn off all LEDs
        OLED_R := FALSE;
        OLED_B := FALSE;
        OLED_Y := FALSE;
        
        // Check if sequence is complete
        IF GameOverStep >= 9 THEN  // 9 steps total (3 cycles of 3 LEDs)
            GameOverActive := FALSE;
            GameOverStep := 0;
            SequenceIndex := 0;
        ELSE
            // Light up the appropriate LED based on sequence
            CASE LEDSequence[SequenceIndex] OF
                1: OLED_R := TRUE;   // Red LED
                2: OLED_B := TRUE;   // Blue LED
                3: OLED_Y := TRUE;   // Yellow LED
            END_CASE;
            
            SequenceIndex := SequenceIndex + 1;
        END_IF;
    END_IF;
END_IF;

// Original button press logic (only when not in game over sequence)
IF B AND NOT GameOverActive THEN
    // Random number 0.0–1.0
    Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);

    // Map to 1..3
    IF RandN < 0.333 THEN
        L_N := 1;
    ELSIF RandN < 0.666 THEN
        L_N := 2;
    ELSE
        L_N := 3;
    END_IF;

    // Keep WriteIndex in 0..49 and set "full" once we wrap
    IF WriteIndex >= 50 THEN
        WriteIndex := 0;
        ArrayFull := TRUE;
    ELSIF WriteIndex < 0 THEN
        // (safety, in case WriteIndex ever goes negative)
        WriteIndex := 0;
    END_IF;

    // Convert LINT -> INT for array subscript
    Idx := TO_INT(WriteIndex);          // or: Idx := LINT_TO_INT(WriteIndex);

    // Write value into the next slot
    GameFlow_SN[Idx] := L_N;
    // Optional mirror:
    // GameFlow_S[Idx] := L_N;

    // Advance for next press
    WriteIndex := WriteIndex + 1;
END_IF;

END_PROGRAM