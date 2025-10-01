(* ====================================================================== *)
(* Function Block: FB_SimonSays                                          *)
(* Simon Says Game Logic for Omron NX102                                *)
(* ====================================================================== *)

FUNCTION_BLOCK FB_SimonSays
    
VAR_INPUT
    (* Button Inputs *)
    i_YellowButton : BOOL;     (* Yellow button contact *)
    i_BlueButton : BOOL;       (* Blue button contact *)
    i_RedButton : BOOL;         (* Red button contact *)
    i_StartButton : BOOL;       (* Start/Stop button *)
    i_Reset : BOOL;             (* Reset game *)
    
    (* Game Parameters *)
    i_MaxLevel : INT := 10;    (* Maximum sequence length *)
    i_ShowTime : TIME := T#500MS;   (* LED display time *)
    i_GapTime : TIME := T#200MS;    (* Gap between LEDs *)
    i_InputTimeout : TIME := T#3S;  (* Player input timeout *)
END_VAR

VAR_OUTPUT
    (* LED Outputs *)
    q_YellowLED : BOOL;        (* Yellow button LED *)
    q_BlueLED : BOOL;          (* Blue button LED *)
    q_RedLED : BOOL;           (* Red button LED *)
    
    (* Status Outputs *)
    q_GameActive : BOOL;        (* Game is active *)
    q_CurrentLevel : INT;       (* Current level *)
    q_GameWon : BOOL;          (* Player won *)
    q_GameLost : BOOL;         (* Player lost *)
    q_State : INT;             (* Current state for diagnostics *)
END_VAR

VAR
    (* Internal State Machine *)
    State : INT := 0;
    NextState : INT := 0;
    
    (* Sequence Storage *)
    Sequence : ARRAY[0..49] OF INT;
    Level : INT := 0;
    SeqIndex : INT := 0;
    InputIndex : INT := 0;
    
    (* Timers *)
    tmr_Show : TON;
    tmr_Gap : TON;
    tmr_Input : TON;
    tmr_GameOver : TON;
    tmr_Blink : TON;
    
    (* Edge Detection *)
    rtrig_Yellow : R_TRIG;
    rtrig_Blue : R_TRIG;
    rtrig_Red : R_TRIG;
    rtrig_Start : R_TRIG;
    
    (* Flags *)
    ShowingLED : BOOL := FALSE;
    InGap : BOOL := FALSE;
    InputReceived : BOOL := FALSE;
    CorrectInput : BOOL := FALSE;
    
    (* Random Generation *)
    RandomSeed : DINT := 0;
    RandomValue : INT := 0;
    
    (* Temporary Variables *)
    i : INT;
    BlinkState : BOOL := FALSE;
END_VAR

(* ====================================================================== *)
(* MAIN LOGIC                                                            *)
(* ====================================================================== *)

(* Edge Detection *)
rtrig_Yellow(CLK := i_YellowButton);
rtrig_Blue(CLK := i_BlueButton);
rtrig_Red(CLK := i_RedButton);
rtrig_Start(CLK := i_StartButton);

(* Update Random Seed *)
RandomSeed := RandomSeed + 1;
IF RandomSeed > 100000 THEN
    RandomSeed := 1;
END_IF;

(* Reset Logic *)
IF i_Reset THEN
    State := 0;
    Level := 0;
    SeqIndex := 0;
    InputIndex := 0;
    q_YellowLED := FALSE;
    q_BlueLED := FALSE;
    q_RedLED := FALSE;
    q_GameActive := FALSE;
    q_GameWon := FALSE;
    q_GameLost := FALSE;
    ShowingLED := FALSE;
    InGap := FALSE;
    RETURN;
END_IF;

(* State Machine *)
CASE State OF
    
    (* ====================================================================== *)
    0: (* IDLE STATE *)
    (* ====================================================================== *)
        q_GameActive := FALSE;
        q_YellowLED := FALSE;
        q_BlueLED := FALSE;
        q_RedLED := FALSE;
        q_GameWon := FALSE;
        q_GameLost := FALSE;
        
        IF rtrig_Start.Q THEN
            (* Initialize new game *)
            Level := 1;
            SeqIndex := 0;
            InputIndex := 0;
            
            (* Generate first random button *)
            RandomValue := INT(RandomSeed MOD 3) + 1;
            Sequence[0] := RandomValue;
            
            (* Start game *)
            q_GameActive := TRUE;
            State := 1;
        END_IF;
    
    (* ====================================================================== *)
    1: (* SHOW SEQUENCE STATE *)
    (* ====================================================================== *)
        IF SeqIndex < Level THEN
            IF NOT ShowingLED AND NOT InGap THEN
                (* Start showing next LED *)
                ShowingLED := TRUE;
                tmr_Show(IN := FALSE);
                tmr_Show(IN := TRUE, PT := i_ShowTime);
                
                (* Turn on appropriate LED *)
                CASE Sequence[SeqIndex] OF
                    1: q_YellowLED := TRUE;
                    2: q_BlueLED := TRUE;
                    3: q_RedLED := TRUE;
                END_CASE;
            END_IF;
            
            (* Handle LED display timing *)
            IF ShowingLED THEN
                tmr_Show(IN := TRUE, PT := i_ShowTime);
                IF tmr_Show.Q THEN
                    (* Turn off LEDs *)
                    q_YellowLED := FALSE;
                    q_BlueLED := FALSE;
                    q_RedLED := FALSE;
                    ShowingLED := FALSE;
                    InGap := TRUE;
                    tmr_Gap(IN := FALSE);
                    tmr_Gap(IN := TRUE, PT := i_GapTime);
                END_IF;
            END_IF;
            
            (* Handle gap timing *)
            IF InGap THEN
                tmr_Gap(IN := TRUE, PT := i_GapTime);
                IF tmr_Gap.Q THEN
                    InGap := FALSE;
                    SeqIndex := SeqIndex + 1;
                END_IF;
            END_IF;
        ELSE
            (* Sequence display complete *)
            SeqIndex := 0;
            InputIndex := 0;
            State := 2;
            tmr_Input(IN := FALSE);
            tmr_Input(IN := TRUE, PT := i_InputTimeout);
        END_IF;
    
    (* ====================================================================== *)
    2: (* WAIT FOR PLAYER INPUT STATE *)
    (* ====================================================================== *)
        (* Check for timeout *)
        tmr_Input(IN := TRUE, PT := i_InputTimeout);
        IF tmr_Input.Q THEN
            (* Timeout - player loses *)
            State := 4;
            tmr_GameOver(IN := FALSE);
            tmr_GameOver(IN := TRUE, PT := T#2S);
        END_IF;
        
        (* Process button inputs *)
        InputReceived := FALSE;
        CorrectInput := FALSE;
        
        IF rtrig_Yellow.Q THEN
            InputReceived := TRUE;
            q_YellowLED := TRUE;
            IF Sequence[InputIndex] = 1 THEN
                CorrectInput := TRUE;
            END_IF;
        ELSIF rtrig_Blue.Q THEN
            InputReceived := TRUE;
            q_BlueLED := TRUE;
            IF Sequence[InputIndex] = 2 THEN
                CorrectInput := TRUE;
            END_IF;
        ELSIF rtrig_Red.Q THEN
            InputReceived := TRUE;
            q_RedLED := TRUE;
            IF Sequence[InputIndex] = 3 THEN
                CorrectInput := TRUE;
            END_IF;
        END_IF;
        
        (* Turn off LEDs when buttons released *)
        IF NOT i_YellowButton THEN q_YellowLED := FALSE; END_IF;
        IF NOT i_BlueButton THEN q_BlueLED := FALSE; END_IF;
        IF NOT i_RedButton THEN q_RedLED := FALSE; END_IF;
        
        (* Process input result *)
        IF InputReceived THEN
            IF CorrectInput THEN
                (* Correct input *)
                InputIndex := InputIndex + 1;
                tmr_Input(IN := FALSE);
                tmr_Input(IN := TRUE, PT := i_InputTimeout);
                
                (* Check if sequence complete *)
                IF InputIndex >= Level THEN
                    IF Level >= i_MaxLevel THEN
                        (* Player wins! *)
                        State := 3;
                        tmr_GameOver(IN := FALSE);
                        tmr_GameOver(IN := TRUE, PT := T#3S);
                    ELSE
                        (* Next level *)
                        Level := Level + 1;
                        RandomValue := INT((RandomSeed * Level) MOD 3) + 1;
                        Sequence[Level - 1] := RandomValue;
                        
                        (* Small delay before showing new sequence *)
                        tmr_Gap(IN := FALSE);
                        InGap := TRUE;
                        tmr_Gap(IN := TRUE, PT := T#1S);
                        
                        IF tmr_Gap.Q THEN
                            InGap := FALSE;
                            SeqIndex := 0;
                            State := 1;
                        END_IF;
                    END_IF;
                END_IF;
            ELSE
                (* Wrong input - player loses *)
                State := 4;
                tmr_GameOver(IN := FALSE);
                tmr_GameOver(IN := TRUE, PT := T#2S);
            END_IF;
        END_IF;
    
    (* ====================================================================== *)
    3: (* GAME WON STATE *)
    (* ====================================================================== *)
        q_GameWon := TRUE;
        
        (* Victory light show *)
        tmr_Blink(IN := TRUE, PT := T#200MS);
        IF tmr_Blink.Q THEN
            tmr_Blink(IN := FALSE);
            BlinkState := NOT BlinkState;
        END_IF;
        
        IF BlinkState THEN
            q_YellowLED := TRUE;
            q_BlueLED := TRUE;
            q_RedLED := TRUE;
        ELSE
            q_YellowLED := FALSE;
            q_BlueLED := FALSE;
            q_RedLED := FALSE;
        END_IF;
        
        (* Check if celebration complete *)
        tmr_GameOver(IN := TRUE, PT := T#3S);
        IF tmr_GameOver.Q THEN
            State := 0;
        END_IF;
    
    (* ====================================================================== *)
    4: (* GAME LOST STATE *)
    (* ====================================================================== *)
        q_GameLost := TRUE;
        
        (* Flash red LED *)
        tmr_Blink(IN := TRUE, PT := T#300MS);
        IF tmr_Blink.Q THEN
            tmr_Blink(IN := FALSE);
            BlinkState := NOT BlinkState;
        END_IF;
        
        q_RedLED := BlinkState;
        q_YellowLED := FALSE;
        q_BlueLED := FALSE;
        
        (* Check if game over display complete *)
        tmr_GameOver(IN := TRUE, PT := T#2S);
        IF tmr_GameOver.Q THEN
            State := 0;
        END_IF;
        
END_CASE;

(* Update outputs *)
q_State := State;
q_CurrentLevel := Level;

END_FUNCTION_BLOCK