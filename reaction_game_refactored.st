// REFACTORED REACTION GAME LOGIC WITH MODULAR FUNCTIONS

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

// Function to generate random gap time
FUNCTION F_GenerateRandomGap : TIME
VAR_INPUT
    RandValue : REAL;  // Random value 0.0 to 1.0
END_VAR

IF RandValue < 0.2 THEN
    F_GenerateRandomGap := t#500ms;
ELSIF RandValue < 0.4 THEN
    F_GenerateRandomGap := t#750ms;
ELSIF RandValue < 0.6 THEN
    F_GenerateRandomGap := t#1000ms;
ELSIF RandValue < 0.8 THEN
    F_GenerateRandomGap := t#1250ms;
ELSE
    F_GenerateRandomGap := t#1500ms;
END_IF;

END_FUNCTION

// =============================================================================
// FUNCTION BLOCK FOR BUTTON PRESS HANDLING
// =============================================================================

FUNCTION_BLOCK FB_HandleButtonPress
VAR_INPUT
    ButtonPressed : BOOL;      // Trigger from button press
    ButtonID : INT;           // Which button (1=Yellow, 2=Blue, 3=Red)
    CurrentLED : INT;          // Which LED is currently on
    GamePhase : INT;           // 0=Gap, 1=LED Active
END_VAR

VAR_OUTPUT
    CorrectPress : BOOL;       // TRUE if correct button pressed
    WrongPress : BOOL;         // TRUE if wrong button/timing
    UpdateScore : BOOL;        // TRUE to increment score
END_VAR

VAR
    // Internal processing
END_VAR

// Reset outputs
CorrectPress := FALSE;
WrongPress := FALSE;
UpdateScore := FALSE;

IF ButtonPressed THEN
    IF GamePhase = 0 THEN
        // Button pressed during gap phase - always wrong
        WrongPress := TRUE;
    ELSIF GamePhase = 1 THEN
        // Button pressed during LED phase
        IF ButtonID = CurrentLED THEN
            // Correct button!
            CorrectPress := TRUE;
            UpdateScore := TRUE;
        ELSE
            // Wrong button
            WrongPress := TRUE;
        END_IF;
    END_IF;
END_IF;

END_FUNCTION_BLOCK

// =============================================================================
// FUNCTION BLOCK FOR GAME OVER SEQUENCE
// =============================================================================

FUNCTION_BLOCK FB_InitGameOver
VAR_INPUT
    Trigger : BOOL;            // Trigger to start game over
    CurrentScore : INT;        // Current game score
END_VAR

VAR_IN_OUT
    HighScore : INT;           // High score to update
    GameActive : BOOL;         // Game active flag
    GameOver_Active : BOOL;    // Game over flag
    GameOver_Step : INT;       // Game over animation step
    LEDActive : BOOL;          // LED phase flag
    GapActive : BOOL;          // Gap phase flag
END_VAR

VAR_OUTPUT
    // Timers to reset
    ResetTimers : BOOL;
END_VAR

IF Trigger THEN
    // Set game over state
    GameActive := FALSE;
    GameOver_Active := TRUE;
    GameOver_Step := 0;
    LEDActive := FALSE;
    GapActive := FALSE;
    ResetTimers := TRUE;
    
    // Update high score if needed
    IF CurrentScore > HighScore THEN
        HighScore := CurrentScore;
    END_IF;
ELSE
    ResetTimers := FALSE;
END_IF;

END_FUNCTION_BLOCK

// =============================================================================
// MAIN PROGRAM - REFACTORED
// =============================================================================

PROGRAM ReactionGame_Main
VAR
    // Button handlers
    ButtonHandler_Y : FB_HandleButtonPress;
    ButtonHandler_B : FB_HandleButtonPress;
    ButtonHandler_R : FB_HandleButtonPress;
    
    // Game over handler
    GameOverHandler : FB_InitGameOver;
    
    // Temporary variables for button processing
    ButtonProcessed : BOOL;
    NextGapTime : TIME;
END_VAR

// MAIN Logic reaction game

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
    NextGapTime := F_GenerateRandomGap(RandValue := RandN);
    T_Gap(PT := NextGapTime);
END_IF;

// Emergency stop
Trig_Mainreset(CLK := IBTN_MAIN AND GameActive AND NOT GameOver_Active);

IF Trig_Mainreset.Q THEN
    GameOverHandler(
        Trigger := TRUE,
        CurrentScore := Score,
        HighScore := HighScore,
        GameActive := GameActive,
        GameOver_Active := GameOver_Active,
        GameOver_Step := GameOver_Step,
        LEDActive := LEDActive,
        GapActive := GapActive
    );
    
    IF GameOverHandler.ResetTimers THEN
        T_Seq(IN := FALSE, PT := t#300ms);
        T_Gap(IN := FALSE);
        T_LED_On(IN := FALSE);
    END_IF;
ELSE
    GameOverHandler(Trigger := FALSE);
END_IF;

// Main game logic
IF GameActive THEN
    
    // Run 60 second timer
    T_GameTimer(IN := TRUE, PT := t#60s);
    
    // Time's up
    IF T_GameTimer.Q THEN
        GameOverHandler(
            Trigger := TRUE,
            CurrentScore := Score,
            HighScore := HighScore,
            GameActive := GameActive,
            GameOver_Active := GameOver_Active,
            GameOver_Step := GameOver_Step,
            LEDActive := LEDActive,
            GapActive := GapActive
        );
        
        IF GameOverHandler.ResetTimers THEN
            T_Seq(IN := FALSE, PT := t#300ms);
        END_IF;
    END_IF;
    
    // Determine current game phase (0=Gap, 1=LED Active)
    VAR
        CurrentPhase : INT;
    END_VAR
    
    IF GapActive THEN
        CurrentPhase := 0;
    ELSIF LEDActive THEN
        CurrentPhase := 1;
    ELSE
        CurrentPhase := -1;
    END_IF;
    
    // GAP PHASE - waiting for LED (don't press anything!)
    IF GapActive THEN
        // All LEDs off
        OLED_Y := FALSE;
        OLED_B := FALSE;
        OLED_R := FALSE;
        CurrentLED := 0;
        
        // Run gap timer
        T_Gap(IN := TRUE);
        
        // Check for button presses using function blocks
        Trig_Y(CLK := IBTN_Y);
        Trig_B(CLK := IBTN_B);
        Trig_R(CLK := IBTN_R);
        
        ButtonProcessed := FALSE;
        
        // Handle Yellow button
        ButtonHandler_Y(
            ButtonPressed := Trig_Y.Q,
            ButtonID := 1,
            CurrentLED := CurrentLED,
            GamePhase := CurrentPhase
        );
        
        // Handle Blue button
        ButtonHandler_B(
            ButtonPressed := Trig_B.Q,
            ButtonID := 2,
            CurrentLED := CurrentLED,
            GamePhase := CurrentPhase
        );
        
        // Handle Red button
        ButtonHandler_R(
            ButtonPressed := Trig_R.Q,
            ButtonID := 3,
            CurrentLED := CurrentLED,
            GamePhase := CurrentPhase
        );
        
        // Any wrong press during gap = game over
        IF ButtonHandler_Y.WrongPress OR ButtonHandler_B.WrongPress OR ButtonHandler_R.WrongPress THEN
            GameOverHandler(
                Trigger := TRUE,
                CurrentScore := Score,
                HighScore := HighScore,
                GameActive := GameActive,
                GameOver_Active := GameOver_Active,
                GameOver_Step := GameOver_Step,
                LEDActive := LEDActive,
                GapActive := GapActive
            );
            
            IF GameOverHandler.ResetTimers THEN
                T_Seq(IN := FALSE, PT := t#300ms);
                T_Gap(IN := FALSE);
                T_LED_On(IN := FALSE);
            END_IF;
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
    
    // LED PHASE - press the correct button
    IF LEDActive THEN
        // Turn on the LED
        CASE CurrentLED OF
            1: OLED_Y := TRUE; OLED_B := FALSE; OLED_R := FALSE;
            2: OLED_Y := FALSE; OLED_B := TRUE; OLED_R := FALSE;
            3: OLED_Y := FALSE; OLED_B := FALSE; OLED_R := TRUE;
            ELSE OLED_Y := FALSE; OLED_B := FALSE; OLED_R := FALSE;
        END_CASE;
        
        // Run LED timer
        T_LED_On(IN := TRUE, PT := t#500ms);
        
        // Check button presses
        Trig_Y(CLK := IBTN_Y);
        Trig_B(CLK := IBTN_B);
        Trig_R(CLK := IBTN_R);
        
        ButtonProcessed := FALSE;
        
        // Handle Yellow button
        ButtonHandler_Y(
            ButtonPressed := Trig_Y.Q,
            ButtonID := 1,
            CurrentLED := CurrentLED,
            GamePhase := CurrentPhase
        );
        
        // Handle Blue button
        ButtonHandler_B(
            ButtonPressed := Trig_B.Q,
            ButtonID := 2,
            CurrentLED := CurrentLED,
            GamePhase := CurrentPhase
        );
        
        // Handle Red button
        ButtonHandler_R(
            ButtonPressed := Trig_R.Q,
            ButtonID := 3,
            CurrentLED := CurrentLED,
            GamePhase := CurrentPhase
        );
        
        // Process button results (only one can be pressed at a time)
        IF ButtonHandler_Y.CorrectPress OR ButtonHandler_B.CorrectPress OR ButtonHandler_R.CorrectPress THEN
            // Correct button pressed
            Score := Score + 1;
            LEDActive := FALSE;
            GapActive := TRUE;
            T_LED_On(IN := FALSE);
            
            // Generate next random gap
            Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);
            NextGapTime := F_GenerateRandomGap(RandValue := RandN);
            T_Gap(IN := FALSE);
            T_Gap(PT := NextGapTime);
            
            ButtonProcessed := TRUE;
        ELSIF ButtonHandler_Y.WrongPress OR ButtonHandler_B.WrongPress OR ButtonHandler_R.WrongPress THEN
            // Wrong button pressed
            GameOverHandler(
                Trigger := TRUE,
                CurrentScore := Score,
                HighScore := HighScore,
                GameActive := GameActive,
                GameOver_Active := GameOver_Active,
                GameOver_Step := GameOver_Step,
                LEDActive := LEDActive,
                GapActive := GapActive
            );
            
            IF GameOverHandler.ResetTimers THEN
                T_Seq(IN := FALSE, PT := t#300ms);
                T_LED_On(IN := FALSE);
                T_Gap(IN := FALSE);
            END_IF;
            
            ButtonProcessed := TRUE;
        END_IF;
        
        // Timer expired - too slow
        IF T_LED_On.Q AND NOT ButtonProcessed THEN
            GameOverHandler(
                Trigger := TRUE,
                CurrentScore := Score,
                HighScore := HighScore,
                GameActive := GameActive,
                GameOver_Active := GameOver_Active,
                GameOver_Step := GameOver_Step,
                LEDActive := LEDActive,
                GapActive := GapActive
            );
            
            OLED_Y := FALSE;
            OLED_B := FALSE;
            OLED_R := FALSE;
            
            IF GameOverHandler.ResetTimers THEN
                T_Seq(IN := FALSE, PT := t#300ms);
                T_LED_On(IN := FALSE);
                T_Gap(IN := FALSE);
            END_IF;
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