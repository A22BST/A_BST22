// MAIN is N.C. → LED on when pressed 
OLED_MAIN := NOT IBTN_MAIN;  

// Color buttons → LED
OLED_B := IBTN_B;     
OLED_R := IBTN_R;        
OLED_Y := IBTN_Y;      

//  main game logic
Trig_Start(Clk := IBTN_B, Q => B);

IF B THEN
    Rand_Gen(Execute := TRUE, Seed => 0, Rnd => RandN);

    IF RandN < 0.333 THEN
        L_N := 1;
    ELSIF RandN < 0.666 THEN
        L_N := 2;
    ELSE
        L_N := 3;
    END_IF;

    IF WriteIndex >= 50 THEN
        WriteIndex := 0;
        ArrayFull := TRUE;
    ELSIF WriteIndex < 0 THEN
        WriteIndex := 0;
    END_IF;

    Idx := TO_INT(WriteIndex);
    GameFlow_SN[Idx] := L_N;
    WriteIndex := WriteIndex + 1;
END_IF;

// -auto-reset edge when WriteIndex hits 50 
Trig_Wrap(CLK := (WriteIndex = 50));
ResetReq := RI OR Trig_Wrap.Q;      // manual RI or auto edge at 50
Trig_Reset(CLK := ResetReq);

IF Trig_Reset.Q THEN
    AryAddV(In1 := GameFlow_S[0], In2 := L_N, Size := 50, AryOut := GameFlow_SN[0]);

    GameOver_Active := TRUE;
    GameOver_Step := -1;
    T_Seq(IN := FALSE, PT := T#300ms);

    WriteIndex := 0;
    ArrayFull := TRUE;
END_IF;

// --- SEQUENCE DISPLAY LOGIC ---
// Variables for sequence display
VAR
    SequenceDisplay_Active : BOOL := FALSE;
    SequenceDisplay_Step : INT := 0;
    SequenceDisplay_Index : INT := 0;
    SequenceDisplay_Timer : TON;
    SequenceDisplay_Delay : TIME := T#500ms;  // Delay between each LED in sequence
    SequenceDisplay_OnTime : TIME := T#300ms; // How long each LED stays on
    SequenceDisplay_OffTime : TIME := T#200ms; // Delay between LEDs
    SequenceDisplay_CurrentLED : INT := 0;
    SequenceDisplay_ShowLED : BOOL := FALSE;
    SequenceDisplay_OffLED : BOOL := FALSE;
    SequenceDisplay_OffTimer : TON;
END_VAR;

// Start sequence display when a new round begins (after button press)
IF B AND NOT SequenceDisplay_Active THEN
    SequenceDisplay_Active := TRUE;
    SequenceDisplay_Step := 0;
    SequenceDisplay_Index := 0;
    SequenceDisplay_CurrentLED := 0;
    SequenceDisplay_ShowLED := FALSE;
    SequenceDisplay_OffLED := FALSE;
END_IF;

// Sequence display state machine
IF SequenceDisplay_Active THEN
    CASE SequenceDisplay_Step OF
        0: // Wait before starting sequence
            SequenceDisplay_Timer(IN := TRUE, PT := T#500ms);
            IF SequenceDisplay_Timer.Q THEN
                SequenceDisplay_Step := 1;
                SequenceDisplay_Timer(IN := FALSE, PT := T#500ms);
            END_IF;
            
        1: // Display current LED in sequence
            IF SequenceDisplay_Index < WriteIndex THEN
                SequenceDisplay_CurrentLED := GameFlow_SN[SequenceDisplay_Index];
                SequenceDisplay_ShowLED := TRUE;
                SequenceDisplay_OffLED := FALSE;
                SequenceDisplay_Step := 2;
            ELSE
                // All LEDs in sequence have been shown
                SequenceDisplay_Step := 3;
            END_IF;
            
        2: // LED is on, wait for on-time
            SequenceDisplay_Timer(IN := TRUE, PT := SequenceDisplay_OnTime);
            IF SequenceDisplay_Timer.Q THEN
                SequenceDisplay_ShowLED := FALSE;
                SequenceDisplay_OffLED := TRUE;
                SequenceDisplay_Step := 4;
                SequenceDisplay_Timer(IN := FALSE, PT := SequenceDisplay_OnTime);
            END_IF;
            
        4: // LED is off, wait for off-time
            SequenceDisplay_Timer(IN := TRUE, PT := SequenceDisplay_OffTime);
            IF SequenceDisplay_Timer.Q THEN
                SequenceDisplay_OffLED := FALSE;
                SequenceDisplay_Index := SequenceDisplay_Index + 1;
                SequenceDisplay_Step := 1;
                SequenceDisplay_Timer(IN := FALSE, PT := SequenceDisplay_OffTime);
            END_IF;
            
        3: // Sequence complete, wait before allowing input
            SequenceDisplay_Timer(IN := TRUE, PT := T#1000ms);
            IF SequenceDisplay_Timer.Q THEN
                SequenceDisplay_Active := FALSE;
                SequenceDisplay_Timer(IN := FALSE, PT := T#1000ms);
            END_IF;
    END_CASE;
END_IF;

// LED control during sequence display
IF SequenceDisplay_Active AND SequenceDisplay_ShowLED THEN
    CASE SequenceDisplay_CurrentLED OF
        1: // Yellow
            OLED_Y := TRUE;
            OLED_B := FALSE;
            OLED_R := FALSE;
        2: // Blue
            OLED_Y := FALSE;
            OLED_B := TRUE;
            OLED_R := FALSE;
        3: // Red
            OLED_Y := FALSE;
            OLED_B := FALSE;
            OLED_R := TRUE;
        ELSE
            OLED_Y := FALSE;
            OLED_B := FALSE;
            OLED_R := FALSE;
    END_CASE;
ELSIF SequenceDisplay_Active AND SequenceDisplay_OffLED THEN
    // All LEDs off during off-time
    OLED_Y := FALSE;
    OLED_B := FALSE;
    OLED_R := FALSE;
ELSIF NOT SequenceDisplay_Active THEN
    // Normal LED control when not displaying sequence
    OLED_B := IBTN_B;     
    OLED_R := IBTN_R;        
    OLED_Y := IBTN_Y;
END_IF;

// --- game over LED sequence (R -> B -> Y, once) ---
IF GameOver_Active THEN
    IF NOT T_Seq.Q THEN
        T_Seq(IN := TRUE, PT := T#300ms);
    ELSE
        T_Seq(IN := FALSE, PT := T#300ms);
    END_IF;

    Trig_Tick(CLK := T_Seq.Q);
    GameOver_Tick := Trig_Tick.Q;

    IF GameOver_Tick THEN
        GameOver_Step := GameOver_Step + 1;
    END_IF;

    CASE GameOver_Step OF
        0:  OLED_R := TRUE;  OLED_B := FALSE; OLED_Y := FALSE;
        1:  OLED_R := FALSE; OLED_B := TRUE;  OLED_Y := FALSE;
        2:  OLED_R := FALSE; OLED_B := FALSE; OLED_Y := TRUE;
		 4:  OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
		 5:  OLED_R := TRUE; OLED_B := TRUE; OLED_Y := TRUE;
		 6:  OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
		  7:  OLED_R := TRUE; OLED_B := TRUE; OLED_Y := TRUE;
        ELSE
            OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
    END_CASE;

    IF GameOver_Step > 7 THEN
        GameOver_Active := FALSE;
        OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
    END_IF;
END_IF;