// Enhanced Simon Says with Sequence Display

// Variables for sequence display
VAR
    // Existing variables (keep all your existing ones)
    OLED_MAIN : BOOL;
    OLED_B : BOOL;
    OLED_R : BOOL;
    OLED_Y : BOOL;
    IBTN_MAIN : BOOL;
    IBTN_B : BOOL;
    IBTN_R : BOOL;
    IBTN_Y : BOOL;
    B : BOOL;
    RandN : REAL;
    L_N : INT;
    WriteIndex : INT := 0;
    ArrayFull : BOOL;
    Idx : INT;
    GameFlow_SN : ARRAY[0..49] OF INT;
    GameFlow_S : ARRAY[0..49] OF INT;
    ResetReq : BOOL;
    RI : BOOL;
    GameOver_Active : BOOL;
    GameOver_Step : INT;
    GameOver_Tick : BOOL;
    
    // New variables for sequence display
    SequenceDisplay_Active : BOOL := FALSE;
    SequenceDisplay_Index : INT := 0;
    SequenceDisplay_State : INT := 0; // 0=OFF, 1=ON
    CurrentRound : INT := 0;
    RoundStarted : BOOL := FALSE;
    
    // Timers
    T_Seq : TON;
    T_Display : TON;  // Timer for sequence display
    
    // Triggers
    Trig_Start : R_TRIG;
    Trig_Wrap : R_TRIG;
    Trig_Reset : R_TRIG;
    Trig_Tick : R_TRIG;
    Trig_DisplayTick : R_TRIG;
    Trig_RoundStart : R_TRIG;
    
    // Function blocks
    Rand_Gen : RAND;
    AryAddV : ARRAY_ADD;
END_VAR

// MAIN is N.C. → LED on when pressed 
OLED_MAIN := NOT IBTN_MAIN;  

// --- SEQUENCE DISPLAY LOGIC ---
// This runs before player input to show the sequence
IF SequenceDisplay_Active THEN
    // Timer for sequence display timing
    IF NOT T_Display.Q THEN
        IF SequenceDisplay_State = 0 THEN
            T_Display(IN := TRUE, PT := T#500ms);  // LED ON time
        ELSE
            T_Display(IN := TRUE, PT := T#300ms);  // LED OFF time between elements
        END_IF;
    ELSE
        T_Display(IN := FALSE);
    END_IF;
    
    Trig_DisplayTick(CLK := T_Display.Q);
    
    IF Trig_DisplayTick.Q THEN
        IF SequenceDisplay_State = 0 THEN
            // Turn ON the LED for current sequence element
            SequenceDisplay_State := 1;
        ELSE
            // Turn OFF and move to next element
            SequenceDisplay_State := 0;
            SequenceDisplay_Index := SequenceDisplay_Index + 1;
            
            // Check if we've displayed all elements for current round
            IF SequenceDisplay_Index >= CurrentRound THEN
                SequenceDisplay_Active := FALSE;
                SequenceDisplay_Index := 0;
                // Now player can start inputting
            END_IF;
        END_IF;
    END_IF;
    
    // Control LEDs based on sequence display
    IF SequenceDisplay_State = 1 AND SequenceDisplay_Index < CurrentRound THEN
        CASE GameFlow_SN[SequenceDisplay_Index] OF
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
    ELSE
        // Turn off all LEDs between sequence elements
        OLED_Y := FALSE;
        OLED_B := FALSE;
        OLED_R := FALSE;
    END_IF;
    
ELSIF NOT GameOver_Active THEN
    // Normal button → LED control (only when not displaying sequence or game over)
    OLED_B := IBTN_B;     
    OLED_R := IBTN_R;        
    OLED_Y := IBTN_Y;
END_IF;

// --- MAIN GAME LOGIC ---
Trig_Start(Clk := IBTN_B, Q => B);

IF B AND NOT SequenceDisplay_Active AND NOT GameOver_Active THEN
    // Generate random number for new sequence element
    Rand_Gen(Execute := TRUE, Seed := 0, Rnd => RandN);

    IF RandN < 0.333 THEN
        L_N := 1;  // Yellow
    ELSIF RandN < 0.666 THEN
        L_N := 2;  // Blue
    ELSE
        L_N := 3;  // Red
    END_IF;

    // Add to sequence array
    IF WriteIndex >= 50 THEN
        WriteIndex := 0;
        ArrayFull := TRUE;
    ELSIF WriteIndex < 0 THEN
        WriteIndex := 0;
    END_IF;

    Idx := TO_INT(WriteIndex);
    GameFlow_SN[Idx] := L_N;
    WriteIndex := WriteIndex + 1;
    
    // Update current round and trigger sequence display
    CurrentRound := WriteIndex;
    SequenceDisplay_Active := TRUE;
    SequenceDisplay_Index := 0;
    SequenceDisplay_State := 0;
    T_Display(IN := FALSE);  // Reset display timer
END_IF;

// --- RESET LOGIC ---
// Auto-reset edge when WriteIndex hits 50 
Trig_Wrap(CLK := (WriteIndex = 50));
ResetReq := RI OR Trig_Wrap.Q;      // manual RI or auto edge at 50
Trig_Reset(CLK := ResetReq);

IF Trig_Reset.Q THEN
    AryAddV(In1 := GameFlow_S[0], In2 := L_N, Size := 50, AryOut := GameFlow_SN[0]);

    // Stop sequence display if active
    SequenceDisplay_Active := FALSE;
    SequenceDisplay_Index := 0;
    CurrentRound := 0;
    
    // Start game over sequence
    GameOver_Active := TRUE;
    GameOver_Step := -1;
    T_Seq(IN := FALSE, PT := T#300ms);

    WriteIndex := 0;
    ArrayFull := TRUE;
END_IF;

// --- GAME OVER LED SEQUENCE ---
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