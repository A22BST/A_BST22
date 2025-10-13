FUNCTION HandleButtonPress : BOOL
VAR_INPUT
    ButtonPressed : BOOL;           // TRUE if this button was pressed
    ExpectedLED : INT;             // The LED number that should be lit (1=Yellow, 2=Blue, 3=Red)
    CurrentLED : INT;              // The currently lit LED number
END_VAR

VAR_IN_OUT
    Score : INT;                   // Player's current score
    GameActive : BOOL;             // Game state flag
    GameOver_Active : BOOL;        // Game over state flag
    LEDActive : BOOL;              // LED phase active flag
    GapActive : BOOL;              // Gap phase active flag
    HighScore : INT;               // High score tracking
    GameOver_Step : INT;           // Game over sequence step
    T_LED_On : TON;                // LED timer
    T_Gap : TON;                   // Gap timer
    T_Seq : TON;                   // Sequence timer
    Rand_Gen : FB_Random;          // Random number generator
    RandN : REAL;                  // Random number output
END_VAR

// Function returns TRUE if button was handled (pressed)
HandleButtonPress := ButtonPressed;

IF ButtonPressed THEN
    IF CurrentLED = ExpectedLED THEN
        // Correct button pressed - add point and continue
        Score := Score + 1;
        LEDActive := FALSE;
        GapActive := TRUE;
        T_LED_On(IN := FALSE);
        
        // Generate next random gap duration
        Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);
        T_Gap(IN := FALSE);
        IF RandN < 0.2 THEN
            T_Gap(PT := t#500ms);
        ELSIF RandN < 0.4 THEN
            T_Gap(PT := t#750ms);
        ELSIF RandN < 0.6 THEN
            T_Gap(PT := t#1000ms);
        ELSIF RandN < 0.8 THEN
            T_Gap(PT := t#1250ms);
        ELSE
            T_Gap(PT := t#1500ms);
        END_IF;
    ELSE
        // Wrong button pressed - game over
        GameActive := FALSE;
        GameOver_Active := TRUE;
        GameOver_Step := 0;
        T_Seq(IN := FALSE, PT := t#300ms);
        LEDActive := FALSE;
        GapActive := FALSE;
        T_LED_On(IN := FALSE);
        T_Gap(IN := FALSE);
        
        // Update high score if needed
        IF Score > HighScore THEN
            HighScore := Score;
        END_IF;
    END_IF;
END_IF;

END_FUNCTION