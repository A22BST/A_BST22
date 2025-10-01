(* ====================================================================== *)
(* Simon Says Game - Phase 1 (3 Buttons)                                 *)
(* For Omron NX102-1100 PLC                                             *)
(* Version: 1.0                                                          *)
(* Date: October 2025                                                    *)
(* ====================================================================== *)

(* ====================================================================== *)
(* I/O MAPPING                                                           *)
(* ====================================================================== *)
(* INPUTS (NX-ID4442):
   DI1 - Yellow Button Contact (Pin 4, Black wire)
   DI3 - Blue Button Contact (Pin 4, Black wire)  
   DI5 - Red Button Contact (Pin 4, Black wire)
   
   OUTPUTS (NX-OD4256):
   DO0 - Red Button LED (Pin 2, White wire)
   DO1 - Blue Button LED (Pin 2, White wire)
   DO2 - Yellow Button LED (Pin 2, White wire)
*)

(* ====================================================================== *)
(* VARIABLE DECLARATIONS                                                 *)
(* ====================================================================== *)

VAR_GLOBAL
    (* Physical I/O *)
    YellowButton_Input AT %IX0.1 : BOOL;    (* DI1 *)
    BlueButton_Input AT %IX0.3 : BOOL;      (* DI3 *)
    RedButton_Input AT %IX0.5 : BOOL;       (* DI5 *)
    
    RedButton_LED AT %QX0.0 : BOOL;         (* DO0 *)
    BlueButton_LED AT %QX0.1 : BOOL;        (* DO1 *)
    YellowButton_LED AT %QX0.2 : BOOL;      (* DO2 *)
    
    (* Game State Machine *)
    GameState : INT := 0;
    (* 0 = IDLE/WAITING
       1 = SHOW_SEQUENCE
       2 = WAIT_FOR_INPUT
       3 = GAME_OVER_WIN
       4 = GAME_OVER_LOSE *)
    
    (* Game Control *)
    GameStart : BOOL := FALSE;
    GameReset : BOOL := FALSE;
    StartButton : BOOL := FALSE;  (* Will be mapped to selector switch later *)
    
    (* Sequence Storage *)
    GameSequence : ARRAY[0..49] OF INT;     (* Store up to 50 moves *)
    CurrentLevel : INT := 0;                (* Current game level/length *)
    SequenceIndex : INT := 0;                (* Current position in sequence *)
    PlayerInputIndex : INT := 0;             (* Player's current input position *)
    MaxLevel : INT := 10;                    (* Maximum sequence length *)
    
    (* Player Input *)
    PlayerInput : INT := 0;                  (* Current button pressed by player *)
    LastPlayerInput : INT := 0;              (* Previous input for edge detection *)
    InputCorrect : BOOL := TRUE;             (* Track if player input is correct *)
    
    (* Timing *)
    ShowTimer : TON;                         (* Timer for showing each LED *)
    GapTimer : TON;                          (* Timer for gap between LEDs *)
    InputTimer : TON;                        (* Timer for player input timeout *)
    GameOverTimer : TON;                     (* Timer for game over display *)
    
    ShowTime : TIME := T#500MS;             (* Time to show each LED *)
    GapTime : TIME := T#200MS;              (* Gap between LEDs *)
    InputTimeout : TIME := T#3S;            (* Player input timeout *)
    GameOverTime : TIME := T#2S;            (* Game over display time *)
    
    (* Random Number Generation *)
    RandomSeed : DINT := 0;
    RandomValue : INT := 0;
    
    (* Edge Detection *)
    YellowButton_Rising : R_TRIG;
    BlueButton_Rising : R_TRIG;
    RedButton_Rising : R_TRIG;
    StartButton_Rising : R_TRIG;
    
    (* Flags *)
    ShowingLED : BOOL := FALSE;
    WaitingGap : BOOL := FALSE;
    SequenceComplete : BOOL := FALSE;
    InputReceived : BOOL := FALSE;
    
END_VAR

(* ====================================================================== *)
(* MAIN PROGRAM                                                          *)
(* ====================================================================== *)

PROGRAM SimonSaysMain
    
    (* Edge Detection for Buttons *)
    YellowButton_Rising(CLK := YellowButton_Input);
    BlueButton_Rising(CLK := BlueButton_Input);
    RedButton_Rising(CLK := RedButton_Input);
    StartButton_Rising(CLK := StartButton);
    
    (* Random Seed Update - Use system time or counter *)
    RandomSeed := RandomSeed + 1;
    IF RandomSeed > 1000000 THEN
        RandomSeed := 0;
    END_IF;
    
    (* ====================================================================== *)
    (* GAME STATE MACHINE                                                    *)
    (* ====================================================================== *)
    
    CASE GameState OF
        
        (* ------------------------------------------------------------ *)
        0: (* IDLE/WAITING STATE *)
        (* ------------------------------------------------------------ *)
            (* Reset all LEDs *)
            RedButton_LED := FALSE;
            BlueButton_LED := FALSE;
            YellowButton_LED := FALSE;
            
            (* Reset game variables *)
            CurrentLevel := 0;
            SequenceIndex := 0;
            PlayerInputIndex := 0;
            InputCorrect := TRUE;
            ShowingLED := FALSE;
            WaitingGap := FALSE;
            
            (* Wait for start signal *)
            IF StartButton_Rising.Q OR GameStart THEN
                GameStart := FALSE;
                (* Initialize first sequence *)
                CurrentLevel := 1;
                (* Generate first random button (1=Yellow, 2=Blue, 3=Red) *)
                RandomValue := INT(RandomSeed MOD 3) + 1;
                GameSequence[0] := RandomValue;
                (* Move to show sequence state *)
                GameState := 1;
                SequenceIndex := 0;
            END_IF;
        
        (* ------------------------------------------------------------ *)
        1: (* SHOW_SEQUENCE STATE *)
        (* ------------------------------------------------------------ *)
            (* Display the current sequence to the player *)
            
            IF NOT ShowingLED AND NOT WaitingGap THEN
                (* Start showing next LED in sequence *)
                IF SequenceIndex < CurrentLevel THEN
                    ShowingLED := TRUE;
                    ShowTimer(IN := FALSE);
                    ShowTimer(IN := TRUE, PT := ShowTime);
                ELSE
                    (* Sequence complete, move to input state *)
                    SequenceComplete := TRUE;
                    GameState := 2;
                    PlayerInputIndex := 0;
                    InputTimer(IN := FALSE);
                    InputTimer(IN := TRUE, PT := InputTimeout);
                END_IF;
            END_IF;
            
            (* Show LED based on sequence *)
            IF ShowingLED THEN
                ShowTimer(IN := TRUE, PT := ShowTime);
                
                (* Turn on appropriate LED *)
                CASE GameSequence[SequenceIndex] OF
                    1: YellowButton_LED := TRUE;
                    2: BlueButton_LED := TRUE;
                    3: RedButton_LED := TRUE;
                END_CASE;
                
                (* Check if show time expired *)
                IF ShowTimer.Q THEN
                    (* Turn off all LEDs *)
                    RedButton_LED := FALSE;
                    BlueButton_LED := FALSE;
                    YellowButton_LED := FALSE;
                    
                    ShowingLED := FALSE;
                    WaitingGap := TRUE;
                    GapTimer(IN := FALSE);
                    GapTimer(IN := TRUE, PT := GapTime);
                END_IF;
            END_IF;
            
            (* Gap between LEDs *)
            IF WaitingGap THEN
                GapTimer(IN := TRUE, PT := GapTime);
                
                IF GapTimer.Q THEN
                    WaitingGap := FALSE;
                    SequenceIndex := SequenceIndex + 1;
                END_IF;
            END_IF;
        
        (* ------------------------------------------------------------ *)
        2: (* WAIT_FOR_INPUT STATE *)
        (* ------------------------------------------------------------ *)
            (* Wait for player to repeat the sequence *)
            
            (* Update input timeout timer *)
            InputTimer(IN := TRUE, PT := InputTimeout);
            
            (* Check for timeout *)
            IF InputTimer.Q THEN
                (* Player took too long - game over *)
                GameState := 4; (* GAME_OVER_LOSE *)
                GameOverTimer(IN := FALSE);
                GameOverTimer(IN := TRUE, PT := GameOverTime);
            END_IF;
            
            (* Check for button presses *)
            InputReceived := FALSE;
            PlayerInput := 0;
            
            IF YellowButton_Rising.Q THEN
                PlayerInput := 1;
                InputReceived := TRUE;
                YellowButton_LED := TRUE;
            ELSIF BlueButton_Rising.Q THEN
                PlayerInput := 2;
                InputReceived := TRUE;
                BlueButton_LED := TRUE;
            ELSIF RedButton_Rising.Q THEN
                PlayerInput := 3;
                InputReceived := TRUE;
                RedButton_LED := TRUE;
            END_IF;
            
            (* Turn off LED when button is released *)
            IF NOT YellowButton_Input THEN
                YellowButton_LED := FALSE;
            END_IF;
            IF NOT BlueButton_Input THEN
                BlueButton_LED := FALSE;
            END_IF;
            IF NOT RedButton_Input THEN
                RedButton_LED := FALSE;
            END_IF;
            
            (* Process input if received *)
            IF InputReceived THEN
                (* Reset timeout timer *)
                InputTimer(IN := FALSE);
                InputTimer(IN := TRUE, PT := InputTimeout);
                
                (* Check if input matches sequence *)
                IF PlayerInput = GameSequence[PlayerInputIndex] THEN
                    (* Correct input *)
                    PlayerInputIndex := PlayerInputIndex + 1;
                    
                    (* Check if player completed current sequence *)
                    IF PlayerInputIndex >= CurrentLevel THEN
                        (* Sequence completed successfully *)
                        IF CurrentLevel >= MaxLevel THEN
                            (* Player wins! *)
                            GameState := 3; (* GAME_OVER_WIN *)
                        ELSE
                            (* Add next random button to sequence *)
                            CurrentLevel := CurrentLevel + 1;
                            RandomValue := INT((RandomSeed + CurrentLevel * 7) MOD 3) + 1;
                            GameSequence[CurrentLevel - 1] := RandomValue;
                            
                            (* Wait a bit then show new sequence *)
                            GapTimer(IN := FALSE);
                            WaitingGap := TRUE;
                            GapTimer(IN := TRUE, PT := T#1S);
                            
                            (* Return to show sequence state *)
                            GameState := 1;
                            SequenceIndex := 0;
                            ShowingLED := FALSE;
                        END_IF;
                    END_IF;
                ELSE
                    (* Wrong input - game over *)
                    GameState := 4; (* GAME_OVER_LOSE *)
                    GameOverTimer(IN := FALSE);
                    GameOverTimer(IN := TRUE, PT := GameOverTime);
                END_IF;
            END_IF;
        
        (* ------------------------------------------------------------ *)
        3: (* GAME_OVER_WIN STATE *)
        (* ------------------------------------------------------------ *)
            (* Flash all LEDs to indicate win *)
            GameOverTimer(IN := TRUE, PT := GameOverTime);
            
            (* Flash pattern for win *)
            IF (GameOverTimer.ET < T#200MS) OR 
               ((GameOverTimer.ET >= T#400MS) AND (GameOverTimer.ET < T#600MS)) OR
               ((GameOverTimer.ET >= T#800MS) AND (GameOverTimer.ET < T#1S)) THEN
                RedButton_LED := TRUE;
                BlueButton_LED := TRUE;
                YellowButton_LED := TRUE;
            ELSE
                RedButton_LED := FALSE;
                BlueButton_LED := FALSE;
                YellowButton_LED := FALSE;
            END_IF;
            
            (* Return to idle after celebration *)
            IF GameOverTimer.Q THEN
                GameState := 0;
            END_IF;
        
        (* ------------------------------------------------------------ *)
        4: (* GAME_OVER_LOSE STATE *)
        (* ------------------------------------------------------------ *)
            (* Flash red LED to indicate loss *)
            GameOverTimer(IN := TRUE, PT := GameOverTime);
            
            (* Flash pattern for lose *)
            IF (GameOverTimer.ET < T#300MS) OR 
               ((GameOverTimer.ET >= T#600MS) AND (GameOverTimer.ET < T#900MS)) OR
               ((GameOverTimer.ET >= T#1200MS) AND (GameOverTimer.ET < T#1500MS)) THEN
                RedButton_LED := TRUE;
            ELSE
                RedButton_LED := FALSE;
            END_IF;
            
            BlueButton_LED := FALSE;
            YellowButton_LED := FALSE;
            
            (* Return to idle after game over display *)
            IF GameOverTimer.Q THEN
                GameState := 0;
            END_IF;
            
    END_CASE;
    
    (* Manual Reset *)
    IF GameReset THEN
        GameState := 0;
        GameReset := FALSE;
    END_IF;

END_PROGRAM