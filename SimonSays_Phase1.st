(* ====================================================================
   SIMON SAYS GAME - PHASE 1 (3 BUTTONS)
   For Omron NX102-1100 PLC
   
   Hardware Configuration:
   - Yellow Button: DI1 (input), DO2 (LED)
   - Blue Button:   DI3 (input), DO1 (LED)  
   - Red Button:    DI5 (input), DO0 (LED)
   
   Author: PLC Programming Assistant
   Date: October 2025
   Version: 1.0
   ==================================================================== *)

PROGRAM SimonSays_Phase1
VAR
    (* ==================== INPUT MAPPING ==================== *)
    Yellow_Button_Input AT %IX0.1 : BOOL;  (* DI1 - Yellow button press *)
    Blue_Button_Input   AT %IX0.3 : BOOL;  (* DI3 - Blue button press *)
    Red_Button_Input    AT %IX0.5 : BOOL;  (* DI5 - Red button press *)
    
    (* ==================== OUTPUT MAPPING ==================== *)
    Red_LED_Output      AT %QX0.0 : BOOL;  (* DO0 - Red LED *)
    Blue_LED_Output     AT %QX0.1 : BOOL;  (* DO1 - Blue LED *)
    Yellow_LED_Output   AT %QX0.2 : BOOL;  (* DO2 - Yellow LED *)
    
    (* ==================== GAME STATE MACHINE ==================== *)
    GameState           : INT := 0;        (* 0=Idle, 1=StartNewGame, 2=ShowSequence, 3=WaitForPlayer, 4=CheckInput, 5=GameOver, 6=Victory *)
    
    (* ==================== SEQUENCE MANAGEMENT ==================== *)
    GameSequence        : ARRAY[0..49] OF INT := [50(0)];  (* Stores the sequence (1=Yellow, 2=Blue, 3=Red) *)
    CurrentLevel        : INT := 0;        (* Current level/length of sequence *)
    SequenceIndex       : INT := 0;        (* Index for displaying/checking sequence *)
    PlayerInputIndex    : INT := 0;        (* Current position in player input *)
    MaxLevel            : INT := 10;       (* Maximum sequence length *)
    
    (* ==================== TIMING CONTROLS ==================== *)
    FlashTimer          : TON;              (* Timer for LED flash duration *)
    GapTimer            : TON;              (* Timer for gap between flashes *)
    InputTimeoutTimer   : TON;              (* Timer for player input timeout *)
    StartDelayTimer     : TON;              (* Timer for game start delay *)
    
    FlashTime           : TIME := T#500MS;  (* LED on duration *)
    GapTime             : TIME := T#300MS;  (* Gap between LED flashes *)
    InputTimeout        : TIME := T#5S;     (* Player input timeout *)
    StartDelay          : TIME := T#2S;     (* Delay before starting game *)
    
    (* ==================== PLAYER INPUT HANDLING ==================== *)
    LastButtonPressed   : INT := 0;        (* Last button pressed by player *)
    ButtonPressDetected : BOOL := FALSE;   (* Flag for button press detection *)
    InputCorrect        : BOOL := TRUE;    (* Flag for correct input *)
    
    (* ==================== EDGE DETECTION ==================== *)
    Yellow_Button_Edge  : R_TRIG;          (* Rising edge detection for Yellow *)
    Blue_Button_Edge    : R_TRIG;          (* Rising edge detection for Blue *)
    Red_Button_Edge     : R_TRIG;          (* Rising edge detection for Red *)
    
    (* ==================== RANDOM NUMBER GENERATION ==================== *)
    RandomSeed          : DINT := 12345;   (* Seed for random number *)
    RandomValue         : INT;             (* Generated random value *)
    
    (* ==================== CONTROL FLAGS ==================== *)
    StartGame           : BOOL := FALSE;   (* Start game trigger *)
    ResetGame           : BOOL := FALSE;   (* Reset game trigger *)
    ShowingSequence     : BOOL := FALSE;   (* Flag indicating sequence display *)
    WaitingForInput     : BOOL := FALSE;   (* Flag indicating waiting for player *)
    
END_VAR

(* ==================== MAIN PROGRAM LOGIC ==================== *)

(* Edge detection for button inputs *)
Yellow_Button_Edge(CLK := Yellow_Button_Input);
Blue_Button_Edge(CLK := Blue_Button_Input);
Red_Button_Edge(CLK := Red_Button_Input);

(* ==================== GAME STATE MACHINE ==================== *)
CASE GameState OF
    
    0: (* IDLE STATE - Waiting to start *)
        (* Reset all LEDs *)
        Yellow_LED_Output := FALSE;
        Blue_LED_Output := FALSE;
        Red_LED_Output := FALSE;
        
        (* Reset game variables *)
        CurrentLevel := 0;
        SequenceIndex := 0;
        PlayerInputIndex := 0;
        ShowingSequence := FALSE;
        WaitingForInput := FALSE;
        
        (* Check for start trigger - any button press starts the game *)
        IF Yellow_Button_Edge.Q OR Blue_Button_Edge.Q OR Red_Button_Edge.Q THEN
            StartGame := TRUE;
        END_IF;
        
        IF StartGame THEN
            GameState := 1;  (* Move to StartNewGame *)
            StartGame := FALSE;
        END_IF;
    
    1: (* START NEW GAME / ADD TO SEQUENCE *)
        (* Flash all LEDs to indicate new round *)
        StartDelayTimer(IN := TRUE, PT := StartDelay);
        
        Yellow_LED_Output := TRUE;
        Blue_LED_Output := TRUE;
        Red_LED_Output := TRUE;
        
        IF StartDelayTimer.Q THEN
            StartDelayTimer(IN := FALSE);
            
            (* Turn off all LEDs *)
            Yellow_LED_Output := FALSE;
            Blue_LED_Output := FALSE;
            Red_LED_Output := FALSE;
            
            (* Add new random element to sequence *)
            CurrentLevel := CurrentLevel + 1;
            
            (* Generate random number 1-3 *)
            RandomSeed := (RandomSeed * 1103515245 + 12345) MOD 2147483648;
            RandomValue := (ABS(RandomSeed) MOD 3) + 1;
            GameSequence[CurrentLevel - 1] := RandomValue;
            
            (* Reset indices *)
            SequenceIndex := 0;
            PlayerInputIndex := 0;
            
            (* Move to show sequence *)
            GameState := 2;
        END_IF;
    
    2: (* SHOW SEQUENCE - Display pattern to player *)
        ShowingSequence := TRUE;
        WaitingForInput := FALSE;
        
        (* Display current element in sequence *)
        IF SequenceIndex < CurrentLevel THEN
            
            (* Flash the appropriate LED *)
            IF NOT FlashTimer.IN AND NOT GapTimer.IN THEN
                (* Start flash *)
                FlashTimer(IN := TRUE, PT := FlashTime);
                
                (* Turn on appropriate LED *)
                CASE GameSequence[SequenceIndex] OF
                    1: Yellow_LED_Output := TRUE;
                    2: Blue_LED_Output := TRUE;
                    3: Red_LED_Output := TRUE;
                END_CASE;
            END_IF;
            
            (* Handle flash timing *)
            FlashTimer(IN := FlashTimer.IN, PT := FlashTime);
            IF FlashTimer.Q THEN
                (* Turn off all LEDs *)
                Yellow_LED_Output := FALSE;
                Blue_LED_Output := FALSE;
                Red_LED_Output := FALSE;
                
                FlashTimer(IN := FALSE);
                
                (* Start gap timer *)
                GapTimer(IN := TRUE, PT := GapTime);
            END_IF;
            
            (* Handle gap timing *)
            GapTimer(IN := GapTimer.IN, PT := GapTime);
            IF GapTimer.Q THEN
                GapTimer(IN := FALSE);
                
                (* Move to next element *)
                SequenceIndex := SequenceIndex + 1;
            END_IF;
            
        ELSE
            (* Sequence display complete *)
            ShowingSequence := FALSE;
            PlayerInputIndex := 0;
            GameState := 3;  (* Move to wait for player *)
        END_IF;
    
    3: (* WAIT FOR PLAYER INPUT *)
        WaitingForInput := TRUE;
        ShowingSequence := FALSE;
        
        (* Start input timeout timer *)
        InputTimeoutTimer(IN := TRUE, PT := InputTimeout);
        
        (* Check for button presses *)
        ButtonPressDetected := FALSE;
        LastButtonPressed := 0;
        
        IF Yellow_Button_Edge.Q THEN
            ButtonPressDetected := TRUE;
            LastButtonPressed := 1;
            Yellow_LED_Output := TRUE;  (* Light up while pressed *)
        ELSIF Blue_Button_Edge.Q THEN
            ButtonPressDetected := TRUE;
            LastButtonPressed := 2;
            Blue_LED_Output := TRUE;    (* Light up while pressed *)
        ELSIF Red_Button_Edge.Q THEN
            ButtonPressDetected := TRUE;
            LastButtonPressed := 3;
            Red_LED_Output := TRUE;     (* Light up while pressed *)
        END_IF;
        
        (* Turn off LEDs when buttons are released *)
        IF NOT Yellow_Button_Input THEN
            Yellow_LED_Output := FALSE;
        END_IF;
        IF NOT Blue_Button_Input THEN
            Blue_LED_Output := FALSE;
        END_IF;
        IF NOT Red_Button_Input THEN
            Red_LED_Output := FALSE;
        END_IF;
        
        (* Process button press *)
        IF ButtonPressDetected THEN
            InputTimeoutTimer(IN := FALSE);  (* Reset timeout *)
            GameState := 4;  (* Move to check input *)
        END_IF;
        
        (* Check for timeout *)
        IF InputTimeoutTimer.Q THEN
            InputTimeoutTimer(IN := FALSE);
            GameState := 5;  (* Game over - timeout *)
        END_IF;
    
    4: (* CHECK PLAYER INPUT *)
        (* Verify if the input matches the sequence *)
        IF LastButtonPressed = GameSequence[PlayerInputIndex] THEN
            (* Correct input *)
            PlayerInputIndex := PlayerInputIndex + 1;
            
            IF PlayerInputIndex >= CurrentLevel THEN
                (* Player completed the sequence *)
                IF CurrentLevel >= MaxLevel THEN
                    GameState := 6;  (* Victory! *)
                ELSE
                    (* Add delay before next round *)
                    StartDelayTimer(IN := TRUE, PT := T#1S);
                    IF StartDelayTimer.Q THEN
                        StartDelayTimer(IN := FALSE);
                        GameState := 1;  (* Next level *)
                    END_IF;
                END_IF;
            ELSE
                (* Wait for next input *)
                GameState := 3;
            END_IF;
        ELSE
            (* Wrong input *)
            GameState := 5;  (* Game over *)
        END_IF;
    
    5: (* GAME OVER *)
        (* Flash red LED to indicate failure *)
        FlashTimer(IN := TRUE, PT := T#200MS);
        
        IF FlashTimer.Q THEN
            Red_LED_Output := NOT Red_LED_Output;
            FlashTimer(IN := FALSE);
        END_IF;
        
        (* Wait for button press to restart *)
        IF Yellow_Button_Edge.Q OR Blue_Button_Edge.Q OR Red_Button_Edge.Q THEN
            FlashTimer(IN := FALSE);
            GameState := 0;  (* Return to idle *)
        END_IF;
    
    6: (* VICTORY *)
        (* Celebration pattern - cycle through all LEDs *)
        FlashTimer(IN := TRUE, PT := T#100MS);
        
        IF FlashTimer.Q THEN
            FlashTimer(IN := FALSE);
            
            (* Rotate LEDs *)
            IF Yellow_LED_Output AND NOT Blue_LED_Output AND NOT Red_LED_Output THEN
                Yellow_LED_Output := FALSE;
                Blue_LED_Output := TRUE;
            ELSIF Blue_LED_Output AND NOT Red_LED_Output THEN
                Blue_LED_Output := FALSE;
                Red_LED_Output := TRUE;
            ELSIF Red_LED_Output THEN
                Red_LED_Output := FALSE;
                Yellow_LED_Output := TRUE;
            ELSE
                Yellow_LED_Output := TRUE;
            END_IF;
        END_IF;
        
        (* Wait for button press to restart *)
        IF Yellow_Button_Edge.Q OR Blue_Button_Edge.Q OR Red_Button_Edge.Q THEN
            FlashTimer(IN := FALSE);
            GameState := 0;  (* Return to idle *)
        END_IF;
        
END_CASE;

END_PROGRAM