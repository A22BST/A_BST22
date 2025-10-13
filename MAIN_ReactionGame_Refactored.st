// MAIN Logic reaction game (REFACTORED)

VAR
    // Function block instances for button checking
    CheckYellow : FB_CheckButtonPress;
    CheckBlue : FB_CheckButtonPress;
    CheckRed : FB_CheckButtonPress;
    
    // Other variables (your existing declarations)
    // ... add your other VAR declarations here
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
END_IF;

// Emergency stop
Trig_Mainreset(CLK := IBTN_MAIN AND GameActive AND NOT GameOver_Active);

IF Trig_Mainreset.Q THEN
    GameActive := FALSE;
    GameOver_Active := TRUE;
    GameOver_Step := 0;
    T_Seq(IN := FALSE, PT := t#300ms);
END_IF;

// Main game logic
IF GameActive THEN
    
    // Run 60 second timer
    T_GameTimer(IN := TRUE, PT := t#60s);
    
    // Time's up
    IF T_GameTimer.Q THEN
        GameActive := FALSE;
        GameOver_Active := TRUE;
        GameOver_Step := 0;
        T_Seq(IN := FALSE, PT := t#300ms);
        
        IF Score > HighScore THEN
            HighScore := Score;
        END_IF;
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
        
        // Check for early button press
        Trig_Y(CLK := IBTN_Y);
        Trig_B(CLK := IBTN_B);
        Trig_R(CLK := IBTN_R);
        
        // Pressed during gap - instant game over
        IF Trig_Y.Q OR Trig_B.Q OR Trig_R.Q THEN
            GameActive := FALSE;
            GameOver_Active := TRUE;
            GameOver_Step := 0;
            T_Seq(IN := FALSE, PT := t#300ms);
            GapActive := FALSE;
            LEDActive := FALSE;
            T_Gap(IN := FALSE);
            T_LED_On(IN := FALSE);
            
            IF Score > HighScore THEN
                HighScore := Score;
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
        
        // ====== REFACTORED BUTTON CHECKING ======
        // Check Yellow button
        CheckYellow(
            ButtonPressed := Trig_Y.Q,
            ExpectedLED := 1,
            CurrentLED := CurrentLED,
            Score := Score,
            HighScore := HighScore
        );
        
        // Check Blue button
        CheckBlue(
            ButtonPressed := Trig_B.Q,
            ExpectedLED := 2,
            CurrentLED := CurrentLED,
            Score := Score,
            HighScore := HighScore
        );
        
        // Check Red button
        CheckRed(
            ButtonPressed := Trig_R.Q,
            ExpectedLED := 3,
            CurrentLED := CurrentLED,
            Score := Score,
            HighScore := HighScore
        );
        
        // Handle correct button press (any of the three)
        IF CheckYellow.ContinueGame OR CheckBlue.ContinueGame OR CheckRed.ContinueGame THEN
            // Update score
            IF CheckYellow.ContinueGame THEN
                Score := CheckYellow.NewScore;
                T_Gap(PT := CheckYellow.NextGapTime);
            ELSIF CheckBlue.ContinueGame THEN
                Score := CheckBlue.NewScore;
                T_Gap(PT := CheckBlue.NextGapTime);
            ELSIF CheckRed.ContinueGame THEN
                Score := CheckRed.NewScore;
                T_Gap(PT := CheckRed.NextGapTime);
            END_IF;
            
            // Continue to next round
            LEDActive := FALSE;
            GapActive := TRUE;
            T_LED_On(IN := FALSE);
            T_Gap(IN := FALSE);
        END_IF;
        
        // Handle wrong button press (game over)
        IF CheckYellow.EndGame OR CheckBlue.EndGame OR CheckRed.EndGame THEN
            // Update high score
            IF CheckYellow.EndGame THEN
                HighScore := CheckYellow.NewHighScore;
            ELSIF CheckBlue.EndGame THEN
                HighScore := CheckBlue.NewHighScore;
            ELSIF CheckRed.EndGame THEN
                HighScore := CheckRed.NewHighScore;
            END_IF;
            
            // End game
            GameActive := FALSE;
            GameOver_Active := TRUE;
            GameOver_Step := 0;
            T_Seq(IN := FALSE, PT := t#300ms);
            LEDActive := FALSE;
            GapActive := FALSE;
            T_LED_On(IN := FALSE);
            T_Gap(IN := FALSE);
        END_IF;
        // ====== END REFACTORED SECTION ======
        
        // Timer expired - too slow
        IF T_LED_On.Q THEN
            GameActive := FALSE;
            GameOver_Active := TRUE;
            GameOver_Step := 0;
            T_Seq(IN := FALSE, PT := t#300ms);
            LEDActive := FALSE;
            GapActive := FALSE;
            OLED_Y := FALSE;
            OLED_B := FALSE;
            OLED_R := FALSE;
            T_LED_On(IN := FALSE);
            T_Gap(IN := FALSE);
            
            IF Score > HighScore THEN
                HighScore := Score;
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
