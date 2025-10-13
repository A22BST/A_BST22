// OPTIMIZED REACTION GAME LOGIC WITH UNIFIED BUTTON HANDLING

// =============================================================================
// UNIFIED BUTTON HANDLER FUNCTION BLOCK
// =============================================================================

FUNCTION_BLOCK FB_ProcessButtonInput
VAR_INPUT
    // Button triggers
    Yellow_Pressed : BOOL;
    Blue_Pressed : BOOL;
    Red_Pressed : BOOL;
    
    // Game state
    CurrentLED : INT;          // Which LED is on (1=Y, 2=B, 3=R, 0=none)
    IsGapPhase : BOOL;         // TRUE if in gap phase
    IsLEDPhase : BOOL;         // TRUE if in LED phase
END_VAR

VAR_OUTPUT
    ButtonPressed : INT;       // Which button was pressed (1=Y, 2=B, 3=R, 0=none)
    IsCorrect : BOOL;         // TRUE if correct button
    IsError : BOOL;           // TRUE if wrong button or wrong timing
    ShouldAddPoint : BOOL;    // TRUE to increment score
END_VAR

// Reset outputs
ButtonPressed := 0;
IsCorrect := FALSE;
IsError := FALSE;
ShouldAddPoint := FALSE;

// Determine which button was pressed
IF Yellow_Pressed THEN
    ButtonPressed := 1;
ELSIF Blue_Pressed THEN
    ButtonPressed := 2;
ELSIF Red_Pressed THEN
    ButtonPressed := 3;
END_IF;

// Process button press
IF ButtonPressed > 0 THEN
    IF IsGapPhase THEN
        // Any button during gap = error
        IsError := TRUE;
    ELSIF IsLEDPhase THEN
        IF ButtonPressed = CurrentLED THEN
            // Correct!
            IsCorrect := TRUE;
            ShouldAddPoint := TRUE;
        ELSE
            // Wrong button
            IsError := TRUE;
        END_IF;
    END_IF;
END_IF;

END_FUNCTION_BLOCK

// =============================================================================
// HELPER FUNCTION FOR RANDOM GAP GENERATION
// =============================================================================

FUNCTION F_GetRandomGapTime : TIME
VAR_INPUT
    RandomValue : REAL;
END_VAR

IF RandomValue < 0.2 THEN
    F_GetRandomGapTime := t#500ms;
ELSIF RandomValue < 0.4 THEN
    F_GetRandomGapTime := t#750ms;
ELSIF RandomValue < 0.6 THEN
    F_GetRandomGapTime := t#1000ms;
ELSIF RandomValue < 0.8 THEN
    F_GetRandomGapTime := t#1250ms;
ELSE
    F_GetRandomGapTime := t#1500ms;
END_IF;

END_FUNCTION

// =============================================================================
// HELPER FUNCTION BLOCK FOR TRANSITIONING TO GAME OVER
// =============================================================================

FUNCTION_BLOCK FB_TriggerGameOver
VAR_INPUT
    Execute : BOOL;
    CurrentScore : INT;
END_VAR

VAR_IN_OUT
    GameActive : BOOL;
    GameOver_Active : BOOL;
    GameOver_Step : INT;
    LEDActive : BOOL;
    GapActive : BOOL;
    HighScore : INT;
END_VAR

VAR_OUTPUT
    Done : BOOL;
END_VAR

Done := FALSE;

IF Execute THEN
    // Update game state
    GameActive := FALSE;
    GameOver_Active := TRUE;
    GameOver_Step := 0;
    LEDActive := FALSE;
    GapActive := FALSE;
    
    // Check high score
    IF CurrentScore > HighScore THEN
        HighScore := CurrentScore;
    END_IF;
    
    Done := TRUE;
END_IF;

END_FUNCTION_BLOCK

// =============================================================================
// HELPER FUNCTION BLOCK FOR STARTING NEXT ROUND
// =============================================================================

FUNCTION_BLOCK FB_PrepareNextRound
VAR_INPUT
    Execute : BOOL;
END_VAR

VAR_IN_OUT
    Score : INT;
    LEDActive : BOOL;
    GapActive : BOOL;
END_VAR

VAR_OUTPUT
    NewGapTime : TIME;
    Done : BOOL;
END_VAR

VAR
    LocalRand : REAL;
END_VAR

Done := FALSE;

IF Execute THEN
    // Update score
    Score := Score + 1;
    
    // Switch to gap phase
    LEDActive := FALSE;
    GapActive := TRUE;
    
    // Generate random gap time
    Rand_Gen(Execute := TRUE, Seed := 0, Rnd => LocalRand);
    NewGapTime := F_GetRandomGapTime(RandomValue := LocalRand);
    
    Done := TRUE;
END_IF;

END_FUNCTION_BLOCK

// =============================================================================
// MAIN PROGRAM - OPTIMIZED VERSION
// =============================================================================

PROGRAM ReactionGame_Optimized
VAR
    // Main button handler
    ButtonHandler : FB_ProcessButtonInput;
    
    // Helper blocks
    GameOverTrigger : FB_TriggerGameOver;
    NextRoundPrep : FB_PrepareNextRound;
    
    // Working variables
    NewGapTime : TIME;
END_VAR

// Main LED feedback
OLED_MAIN := NOT IBTN_MAIN;

// Start game
Trig_Start(CLK := IBTN_MAIN AND NOT GameActive AND NOT GameOver_Active);

IF Trig_Start.Q THEN
    GameActive := TRUE;
    Score := 0;
    GapActive := TRUE;
    LEDActive := FALSE;
    CurrentLED := 0;
    T_GameTimer(IN := FALSE, PT := t#60s);
    T_Gap(IN := FALSE);
    T_LED_On(IN := FALSE);
    
    // Generate first random gap
    Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);
    NewGapTime := F_GetRandomGapTime(RandomValue := RandN);
    T_Gap(PT := NewGapTime);
END_IF;

// Emergency stop
Trig_Mainreset(CLK := IBTN_MAIN AND GameActive AND NOT GameOver_Active);

IF Trig_Mainreset.Q THEN
    GameOverTrigger(
        Execute := TRUE,
        CurrentScore := Score,
        GameActive := GameActive,
        GameOver_Active := GameOver_Active,
        GameOver_Step := GameOver_Step,
        LEDActive := LEDActive,
        GapActive := GapActive,
        HighScore := HighScore
    );
    
    IF GameOverTrigger.Done THEN
        T_Seq(IN := FALSE, PT := t#300ms);
    END_IF;
ELSE
    GameOverTrigger(Execute := FALSE);
END_IF;

// Main game logic
IF GameActive THEN
    
    // Run 60 second timer
    T_GameTimer(IN := TRUE, PT := t#60s);
    
    // Time's up
    IF T_GameTimer.Q THEN
        GameOverTrigger(
            Execute := TRUE,
            CurrentScore := Score,
            GameActive := GameActive,
            GameOver_Active := GameOver_Active,
            GameOver_Step := GameOver_Step,
            LEDActive := LEDActive,
            GapActive := GapActive,
            HighScore := HighScore
        );
        
        IF GameOverTrigger.Done THEN
            T_Seq(IN := FALSE, PT := t#300ms);
        END_IF;
    END_IF;
    
    // GAP PHASE
    IF GapActive THEN
        // All LEDs off
        OLED_Y := FALSE;
        OLED_B := FALSE;
        OLED_R := FALSE;
        CurrentLED := 0;
        
        // Run gap timer
        T_Gap(IN := TRUE);
        
        // Check button presses
        Trig_Y(CLK := IBTN_Y);
        Trig_B(CLK := IBTN_B);
        Trig_R(CLK := IBTN_R);
        
        // Process all button inputs with single function block call
        ButtonHandler(
            Yellow_Pressed := Trig_Y.Q,
            Blue_Pressed := Trig_B.Q,
            Red_Pressed := Trig_R.Q,
            CurrentLED := CurrentLED,
            IsGapPhase := TRUE,
            IsLEDPhase := FALSE
        );
        
        // Handle any button press during gap (all are errors)
        IF ButtonHandler.IsError THEN
            GameOverTrigger(
                Execute := TRUE,
                CurrentScore := Score,
                GameActive := GameActive,
                GameOver_Active := GameOver_Active,
                GameOver_Step := GameOver_Step,
                LEDActive := LEDActive,
                GapActive := GapActive,
                HighScore := HighScore
            );
            
            T_Seq(IN := FALSE, PT := t#300ms);
            T_Gap(IN := FALSE);
            T_LED_On(IN := FALSE);
        END_IF;
        
        // Gap finished - light up random LED
        IF T_Gap.Q THEN
            T_Gap(IN := FALSE);
            GapActive := FALSE;
            LEDActive := TRUE;
            
            Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);
            CurrentLED := F_Rand(RandomValue := RandN);
            
            // Start 500ms timer
            T_LED_On(IN := FALSE, PT := t#500ms);
        END_IF;
    END_IF;
    
    // LED PHASE
    IF LEDActive THEN
        // Turn on the appropriate LED
        CASE CurrentLED OF
            1: 
                OLED_Y := TRUE; 
                OLED_B := FALSE; 
                OLED_R := FALSE;
            2: 
                OLED_Y := FALSE; 
                OLED_B := TRUE; 
                OLED_R := FALSE;
            3: 
                OLED_Y := FALSE; 
                OLED_B := FALSE; 
                OLED_R := TRUE;
            ELSE 
                OLED_Y := FALSE; 
                OLED_B := FALSE; 
                OLED_R := FALSE;
        END_CASE;
        
        // Run LED timer
        T_LED_On(IN := TRUE, PT := t#500ms);
        
        // Check button presses
        Trig_Y(CLK := IBTN_Y);
        Trig_B(CLK := IBTN_B);
        Trig_R(CLK := IBTN_R);
        
        // Process all button inputs with single function block call
        ButtonHandler(
            Yellow_Pressed := Trig_Y.Q,
            Blue_Pressed := Trig_B.Q,
            Red_Pressed := Trig_R.Q,
            CurrentLED := CurrentLED,
            IsGapPhase := FALSE,
            IsLEDPhase := TRUE
        );
        
        // Handle correct button press
        IF ButtonHandler.IsCorrect THEN
            NextRoundPrep(
                Execute := TRUE,
                Score := Score,
                LEDActive := LEDActive,
                GapActive := GapActive
            );
            
            IF NextRoundPrep.Done THEN
                T_LED_On(IN := FALSE);
                T_Gap(IN := FALSE);
                T_Gap(PT := NextRoundPrep.NewGapTime);
            END_IF;
        ELSE
            NextRoundPrep(Execute := FALSE);
        END_IF;
        
        // Handle wrong button press
        IF ButtonHandler.IsError THEN
            GameOverTrigger(
                Execute := TRUE,
                CurrentScore := Score,
                GameActive := GameActive,
                GameOver_Active := GameOver_Active,
                GameOver_Step := GameOver_Step,
                LEDActive := LEDActive,
                GapActive := GapActive,
                HighScore := HighScore
            );
            
            T_Seq(IN := FALSE, PT := t#300ms);
            T_LED_On(IN := FALSE);
            T_Gap(IN := FALSE);
        END_IF;
        
        // Timer expired - too slow
        IF T_LED_On.Q AND NOT ButtonHandler.IsCorrect THEN
            GameOverTrigger(
                Execute := TRUE,
                CurrentScore := Score,
                GameActive := GameActive,
                GameOver_Active := GameOver_Active,
                GameOver_Step := GameOver_Step,
                LEDActive := LEDActive,
                GapActive := GapActive,
                HighScore := HighScore
            );
            
            OLED_Y := FALSE;
            OLED_B := FALSE;
            OLED_R := FALSE;
            
            T_Seq(IN := FALSE, PT := t#300ms);
            T_LED_On(IN := FALSE);
            T_Gap(IN := FALSE);
        END_IF;
    END_IF;
END_IF;

// Game over animation using FB
IF GameOver_Active THEN
    GameOverA(
        Start := TRUE,
        Reset := FALSE
    );
    
    // Apply LED outputs
    OLED_Y := GameOverA.LED_Yellow;
    OLED_B := GameOverA.LED_Blue;
    OLED_R := GameOverA.LED_Red;
    
    // Check if animation done
    IF GameOverA.Done THEN
        GameOver_Active := FALSE;
        GameActive := FALSE;
        LEDActive := FALSE;
        GapActive := FALSE;
        Score := 0;
    END_IF;
ELSE
    // Reset animation when not in game over
    GameOverA(
        Start := FALSE,
        Reset := TRUE
    );
END_IF;

END_PROGRAM