FUNCTION_BLOCK FB_CheckButtonPress
VAR_INPUT
    ButtonPressed : BOOL;          // Trigger for this button
    ExpectedLED : INT;             // Which LED should be lit (1=Yellow, 2=Blue, 3=Red)
    CurrentLED : INT;              // Which LED is actually lit
    Score : INT;                   // Current score
    HighScore : INT;               // Current high score
END_VAR

VAR_OUTPUT
    IsCorrect : BOOL;              // TRUE if correct button pressed
    IsWrong : BOOL;                // TRUE if wrong button pressed
    NewScore : INT;                // Updated score
    NewHighScore : INT;            // Updated high score
    NextGapTime : TIME;            // Random gap time for next round
    EndGame : BOOL;                // Signal to end the game
    ContinueGame : BOOL;           // Signal to continue to next round
END_VAR

VAR
    Rand_Gen : FB_RandomGenerator; // Random number generator (adjust to your actual FB name)
    RandN : REAL;
END_VAR

// Initialize outputs
IsCorrect := FALSE;
IsWrong := FALSE;
NewScore := Score;
NewHighScore := HighScore;
EndGame := FALSE;
ContinueGame := FALSE;

// Check if button was pressed
IF ButtonPressed THEN
    // Check if it's the correct button
    IF CurrentLED = ExpectedLED THEN
        // Correct button pressed
        IsCorrect := TRUE;
        ContinueGame := TRUE;
        NewScore := Score + 1;
        
        // Generate next random gap time
        Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);
        IF RandN < 0.2 THEN
            NextGapTime := t#500ms;
        ELSIF RandN < 0.4 THEN
            NextGapTime := t#750ms;
        ELSIF RandN < 0.6 THEN
            NextGapTime := t#1000ms;
        ELSIF RandN < 0.8 THEN
            NextGapTime := t#1250ms;
        ELSE
            NextGapTime := t#1500ms;
        END_IF;
    ELSE
        // Wrong button pressed - game over
        IsWrong := TRUE;
        EndGame := TRUE;
        
        // Update high score if needed
        IF Score > HighScore THEN
            NewHighScore := Score;
        ELSE
            NewHighScore := HighScore;
        END_IF;
    END_IF;
END_IF;

END_FUNCTION_BLOCK
