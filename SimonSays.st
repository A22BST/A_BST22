// MAIN is N.C. → LED on when pressed 
OLED_MAIN := NOT IBTN_MAIN;  

// Color buttons → LED (when not in sequence display mode)
IF NOT SeqDisplay_Active THEN
    OLED_B := IBTN_B;     
    OLED_R := IBTN_R;        
    OLED_Y := IBTN_Y;      
END_IF;

//  main game logic
Trig_Start(Clk := IBTN_B, Q => B);

IF B THEN
    Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);

    IF RandN < 0.333 THEN
        L_N := 1;  // Yellow
    ELSIF RandN < 0.666 THEN
        L_N := 2;  // Blue
    ELSE
        L_N := 3;  // Red
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
    
    // Trigger sequence display after adding new number
    SeqDisplay_Active := TRUE;
    SeqDisplay_Index := 0;
    SeqDisplay_Step := 0;  // 0 = LED ON, 1 = LED OFF
    T_SeqDisplay(IN := FALSE, PT := T#300ms);
END_IF;


// --- Sequence Display Logic ---
IF SeqDisplay_Active THEN
    IF NOT T_SeqDisplay.Q THEN
        T_SeqDisplay(IN := TRUE, PT := T#300ms);
    ELSE
        T_SeqDisplay(IN := FALSE, PT := T#300ms);
    END_IF;

    Trig_SeqTick(CLK := T_SeqDisplay.Q);
    SeqDisplay_Tick := Trig_SeqTick.Q;

    IF SeqDisplay_Tick THEN
        IF SeqDisplay_Step = 0 THEN
            // LED ON - display current sequence element
            CASE GameFlow_SN[SeqDisplay_Index] OF
                1:  OLED_Y := TRUE;  OLED_B := FALSE; OLED_R := FALSE;  // Yellow
                2:  OLED_Y := FALSE; OLED_B := TRUE;  OLED_R := FALSE;  // Blue
                3:  OLED_Y := FALSE; OLED_B := FALSE; OLED_R := TRUE;   // Red
                ELSE
                    OLED_Y := FALSE; OLED_B := FALSE; OLED_R := FALSE;
            END_CASE;
            SeqDisplay_Step := 1;
        ELSE
            // LED OFF - pause between elements
            OLED_Y := FALSE; OLED_B := FALSE; OLED_R := FALSE;
            SeqDisplay_Step := 0;
            SeqDisplay_Index := SeqDisplay_Index + 1;
            
            // Check if we've displayed the entire sequence
            IF SeqDisplay_Index >= WriteIndex THEN
                SeqDisplay_Active := FALSE;
                OLED_Y := FALSE; OLED_B := FALSE; OLED_R := FALSE;
            END_IF;
        END_IF;
    END_IF;
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
        5:  OLED_R := TRUE;  OLED_B := TRUE;  OLED_Y := TRUE;
        6:  OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
        7:  OLED_R := TRUE;  OLED_B := TRUE;  OLED_Y := TRUE;
        ELSE
            OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
    END_CASE;

    IF GameOver_Step > 7 THEN
        GameOver_Active := FALSE;
        OLED_R := FALSE; OLED_B := FALSE; OLED_Y := FALSE;
    END_IF;
END_IF;
