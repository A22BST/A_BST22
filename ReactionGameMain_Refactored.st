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
        
        // Check button presses using the new function
        Trig_Y(CLK := IBTN_Y);
        Trig_B(CLK := IBTN_B);
        Trig_R(CLK := IBTN_R);
        
        // Handle all button presses with the function
        HandleButtonPress(
            ButtonPressed := Trig_Y.Q,
            ExpectedLED := 1,
            CurrentLED := CurrentLED,
            Score := Score,
            GameActive := GameActive,
            GameOver_Active := GameOver_Active,
            LEDActive := LEDActive,
            GapActive := GapActive,
            HighScore := HighScore,
            GameOver_Step := GameOver_Step,
            T_LED_On := T_LED_On,
            T_Gap := T_Gap,
            T_Seq := T_Seq,
            Rand_Gen := Rand_Gen,
            RandN := RandN
        );
        
        HandleButtonPress(
            ButtonPressed := Trig_B.Q,
            ExpectedLED := 2,
            CurrentLED := CurrentLED,
            Score := Score,
            GameActive := GameActive,
            GameOver_Active := GameOver_Active,
            LEDActive := LEDActive,
            GapActive := GapActive,
            HighScore := HighScore,
            GameOver_Step := GameOver_Step,
            T_LED_On := T_LED_On,
            T_Gap := T_Gap,
            T_Seq := T_Seq,
            Rand_Gen := Rand_Gen,
            RandN := RandN
        );
        
        HandleButtonPress(
            ButtonPressed := Trig_R.Q,
            ExpectedLED := 3,
            CurrentLED := CurrentLED,
            Score := Score,
            GameActive := GameActive,
            GameOver_Active := GameOver_Active,
            LEDActive := LEDActive,
            GapActive := GapActive,
            HighScore := HighScore,
            GameOver_Step := GameOver_Step,
            T_LED_On := T_LED_On,
            T_Gap := T_Gap,
            T_Seq := T_Seq,
            Rand_Gen := Rand_Gen,
            RandN := RandN
        );
        
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