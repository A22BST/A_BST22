(* Simon Says Game - Structured Text Implementation for Omron NX102-1100 *)
(* Phase 1: 3-Button Version (Red, Blue, Yellow) *)

PROGRAM SimonSaysGame
VAR
    (* I/O Mapping *)
    YellowButton    : BOOL AT %IX1.1;    (* DI1 - Yellow button input *)
    BlueButton      : BOOL AT %IX1.3;    (* DI3 - Blue button input *)
    RedButton       : BOOL AT %IX1.5;    (* DI5 - Red button input *)
    StartButton     : BOOL AT %IX1.7;    (* DI7 - Start/Reset button *)
    
    RedLED          : BOOL AT %QX0.0;    (* DO0 - Red LED output *)
    BlueLED         : BOOL AT %QX0.1;    (* DO1 - Blue LED output *)
    YellowLED       : BOOL AT %QX0.2;    (* DO2 - Yellow LED output *)
    StatusLED       : BOOL AT %QX0.3;    (* DO3 - Status LED *)
    
    (* Game State Variables *)
    GameState       : INT := 0;          (* 0=IDLE, 1=INIT, 2=SHOW, 3=WAIT, 4=CHECK, 5=SUCCESS, 6=GAMEOVER *)
    SequenceLength  : INT := 1;          (* Current sequence length *)
    SequenceArray   : ARRAY[0..19] OF INT; (* Sequence storage (0=Red, 1=Blue, 2=Yellow) *)
    CurrentStep     : INT := 0;          (* Current step in sequence display *)
    PlayerStep      : INT := 0;          (* Player's current input step *)
    
    (* Timing Variables *)
    GameTimer       : TON;               (* Multi-purpose timer *)
    FlashTime       : TIME := T#500ms;   (* LED flash duration *)
    GapTime         : TIME := T#200ms;   (* Gap between flashes *)
    InputTimeout    : TIME := T#3s;      (* Player input timeout *)
    CelebrationTime : TIME := T#1s;      (* Success celebration time *)
    ErrorTime       : TIME := T#2s;      (* Error display time *)
    
    (* Button Edge Detection *)
    YellowButton_R  : R_TRIG;
    BlueButton_R    : R_TRIG;
    RedButton_R     : R_TRIG;
    StartButton_R   : R_TRIG;
    
    (* Internal Variables *)
    RandomSeed      : DINT := 12345;     (* Random number seed *)
    ButtonPressed   : INT := -1;         (* Last button pressed (0=Red, 1=Blue, 2=Yellow) *)
    FlashState      : BOOL := FALSE;     (* For sequence display *)
    ErrorBlink      : INT := 0;          (* Error blink counter *)
    
    (* Temporary variables *)
    TempRandom      : DINT;
END_VAR

(* Edge detection for buttons *)
YellowButton_R(CLK := YellowButton);
BlueButton_R(CLK := BlueButton);
RedButton_R(CLK := RedButton);
StartButton_R(CLK := StartButton);

(* Determine which button was pressed *)
IF YellowButton_R.Q THEN
    ButtonPressed := 2;  (* Yellow *)
ELSIF BlueButton_R.Q THEN
    ButtonPressed := 1;  (* Blue *)
ELSIF RedButton_R.Q THEN
    ButtonPressed := 0;  (* Red *)
ELSE
    ButtonPressed := -1; (* No button *)
END_IF;

(* Main State Machine *)
CASE GameState OF
    
    0: (* IDLE STATE *)
        (* Turn off all LEDs *)
        RedLED := FALSE;
        BlueLED := FALSE;
        YellowLED := FALSE;
        StatusLED := FALSE;
        
        (* Reset game variables *)
        SequenceLength := 1;
        CurrentStep := 0;
        PlayerStep := 0;
        
        (* Wait for start button *)
        IF StartButton_R.Q THEN
            GameState := 1; (* Go to INIT *)
        END_IF;
    
    1: (* INIT STATE *)
        (* Generate new random number for sequence *)
        RandomSeed := RandomSeed * 1103515245 + 12345; (* Linear congruential generator *)
        TempRandom := RandomSeed MOD 3; (* Get 0, 1, or 2 *)
        
        (* Add to sequence if we're extending *)
        IF SequenceLength <= 20 THEN
            SequenceArray[SequenceLength - 1] := TempRandom;
        END_IF;
        
        (* Reset counters *)
        CurrentStep := 0;
        PlayerStep := 0;
        FlashState := FALSE;
        
        (* Start showing sequence *)
        GameState := 2;
        GameTimer(IN := FALSE); (* Reset timer *)
    
    2: (* SHOW_SEQUENCE STATE *)
        StatusLED := TRUE; (* Indicate game is active *)
        
        (* Show current step in sequence *)
        IF CurrentStep < SequenceLength THEN
            
            IF NOT FlashState THEN
                (* Start flashing current LED *)
                CASE SequenceArray[CurrentStep] OF
                    0: RedLED := TRUE;    (* Red *)
                    1: BlueLED := TRUE;   (* Blue *)
                    2: YellowLED := TRUE; (* Yellow *)
                END_CASE;
                
                GameTimer(IN := TRUE, PT := FlashTime);
                IF GameTimer.Q THEN
                    FlashState := TRUE;
                    GameTimer(IN := FALSE); (* Reset for gap timing *)
                END_IF;
                
            ELSE
                (* Turn off LEDs and wait for gap *)
                RedLED := FALSE;
                BlueLED := FALSE;
                YellowLED := FALSE;
                
                GameTimer(IN := TRUE, PT := GapTime);
                IF GameTimer.Q THEN
                    FlashState := FALSE;
                    CurrentStep := CurrentStep + 1;
                    GameTimer(IN := FALSE);
                END_IF;
            END_IF;
            
        ELSE
            (* Sequence display complete *)
            PlayerStep := 0;
            GameState := 3; (* Go to WAIT_INPUT *)
            GameTimer(IN := FALSE);
        END_IF;
    
    3: (* WAIT_INPUT STATE *)
        (* Start input timeout timer *)
        GameTimer(IN := TRUE, PT := InputTimeout);
        
        (* Light up pressed button immediately for feedback *)
        RedLED := RedButton;
        BlueLED := BlueButton;
        YellowLED := YellowButton;
        
        (* Check for button press *)
        IF ButtonPressed >= 0 THEN
            GameState := 4; (* Go to CHECK_INPUT *)
            GameTimer(IN := FALSE);
        ELSIF GameTimer.Q THEN
            (* Timeout - game over *)
            GameState := 6;
            GameTimer(IN := FALSE);
        END_IF;
    
    4: (* CHECK_INPUT STATE *)
        (* Turn off LEDs *)
        RedLED := FALSE;
        BlueLED := FALSE;
        YellowLED := FALSE;
        
        (* Check if input matches sequence *)
        IF ButtonPressed = SequenceArray[PlayerStep] THEN
            (* Correct input *)
            PlayerStep := PlayerStep + 1;
            
            IF PlayerStep >= SequenceLength THEN
                (* Player completed the sequence *)
                GameState := 5; (* Go to SUCCESS *)
            ELSE
                (* Wait for next input *)
                GameState := 3; (* Back to WAIT_INPUT *)
            END_IF;
        ELSE
            (* Wrong input - game over *)
            GameState := 6;
        END_IF;
        
        ButtonPressed := -1; (* Clear button press *)
    
    5: (* SUCCESS STATE *)
        (* Celebration - flash all LEDs *)
        GameTimer(IN := TRUE, PT := CelebrationTime);
        
        RedLED := TRUE;
        BlueLED := TRUE;
        YellowLED := TRUE;
        
        IF GameTimer.Q THEN
            (* Advance to next level *)
            SequenceLength := SequenceLength + 1;
            
            IF SequenceLength > 20 THEN
                (* Maximum level reached - end game *)
                GameState := 6;
            ELSE
                (* Continue to next level *)
                GameState := 1; (* Back to INIT *)
            END_IF;
            
            GameTimer(IN := FALSE);
        END_IF;
    
    6: (* GAME_OVER STATE *)
        (* Error display - blink all LEDs *)
        GameTimer(IN := TRUE, PT := T#200ms);
        
        IF GameTimer.Q THEN
            RedLED := NOT RedLED;
            BlueLED := NOT BlueLED;
            YellowLED := NOT YellowLED;
            
            ErrorBlink := ErrorBlink + 1;
            GameTimer(IN := FALSE);
            
            IF ErrorBlink >= 6 THEN (* 3 complete blinks *)
                (* Hold LEDs on for error display *)
                RedLED := TRUE;
                BlueLED := TRUE;
                YellowLED := TRUE;
                
                GameTimer(IN := TRUE, PT := ErrorTime);
                IF GameTimer.Q THEN
                    (* Return to idle *)
                    ErrorBlink := 0;
                    GameState := 0;
                    GameTimer(IN := FALSE);
                END_IF;
            END_IF;
        END_IF;
        
END_CASE;

END_PROGRAM