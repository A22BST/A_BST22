(* Simon Says Game - Timer Functions and Utilities *)
(* For Omron NX102-1100 PLC *)

(* ============================================================================ *)
(* FUNCTION BLOCK: SequenceTimer *)
(* Purpose: Manages timing for sequence display with adjustable flash and gap times *)
(* ============================================================================ *)

FUNCTION_BLOCK SequenceTimer
VAR_INPUT
    Enable      : BOOL;     (* Enable the timer *)
    FlashTime   : TIME;     (* Duration for LED flash *)
    GapTime     : TIME;     (* Duration for gap between flashes *)
    Reset       : BOOL;     (* Reset the timer *)
END_VAR

VAR_OUTPUT
    FlashActive : BOOL;     (* TRUE when LED should be on *)
    StepComplete: BOOL;     (* TRUE when one complete flash+gap cycle is done *)
    Busy        : BOOL;     (* TRUE when timer is running *)
END_VAR

VAR
    FlashTimer  : TON;      (* Timer for flash duration *)
    GapTimer    : TON;      (* Timer for gap duration *)
    State       : INT;      (* 0=Idle, 1=Flash, 2=Gap *)
END_VAR

(* Reset logic *)
IF Reset THEN
    State := 0;
    FlashActive := FALSE;
    StepComplete := FALSE;
    Busy := FALSE;
    FlashTimer(IN := FALSE);
    GapTimer(IN := FALSE);
    RETURN;
END_IF;

(* Main timer logic *)
IF Enable THEN
    Busy := TRUE;
    
    CASE State OF
        0: (* Idle - start flash *)
            IF Enable THEN
                State := 1;
                FlashActive := TRUE;
                StepComplete := FALSE;
            END_IF;
            
        1: (* Flash phase *)
            FlashTimer(IN := TRUE, PT := FlashTime);
            IF FlashTimer.Q THEN
                FlashActive := FALSE;
                State := 2;
                FlashTimer(IN := FALSE);
            END_IF;
            
        2: (* Gap phase *)
            GapTimer(IN := TRUE, PT := GapTime);
            IF GapTimer.Q THEN
                StepComplete := TRUE;
                State := 0;
                GapTimer(IN := FALSE);
                Busy := FALSE;
            END_IF;
    END_CASE;
ELSE
    Busy := FALSE;
    FlashActive := FALSE;
    StepComplete := FALSE;
    State := 0;
END_IF;

END_FUNCTION_BLOCK

(* ============================================================================ *)
(* FUNCTION BLOCK: InputTimer *)
(* Purpose: Manages player input timeout with visual countdown *)
(* ============================================================================ *)

FUNCTION_BLOCK InputTimer
VAR_INPUT
    Enable      : BOOL;     (* Start the input timer *)
    TimeoutValue: TIME;     (* Timeout duration *)
    Reset       : BOOL;     (* Reset the timer *)
END_VAR

VAR_OUTPUT
    TimeExpired : BOOL;     (* TRUE when timeout occurs *)
    TimeRemaining: TIME;    (* Time remaining *)
    WarningActive: BOOL;    (* TRUE when in warning period (last 25% of time) *)
END_VAR

VAR
    InputTimer  : TON;      (* Main timeout timer *)
    ElapsedTime : TIME;     (* Elapsed time *)
END_VAR

(* Reset logic *)
IF Reset THEN
    TimeExpired := FALSE;
    TimeRemaining := TimeoutValue;
    WarningActive := FALSE;
    InputTimer(IN := FALSE);
    RETURN;
END_IF;

(* Timer logic *)
InputTimer(IN := Enable, PT := TimeoutValue);

IF Enable THEN
    ElapsedTime := InputTimer.ET;
    TimeRemaining := TimeoutValue - ElapsedTime;
    
    (* Warning when 75% of time has elapsed *)
    WarningActive := (ElapsedTime >= (TimeoutValue * 3 / 4));
    
    (* Timeout check *)
    TimeExpired := InputTimer.Q;
ELSE
    TimeRemaining := TimeoutValue;
    WarningActive := FALSE;
    TimeExpired := FALSE;
END_IF;

END_FUNCTION_BLOCK

(* ============================================================================ *)
(* FUNCTION BLOCK: CelebrationTimer *)
(* Purpose: Manages success celebration effects *)
(* ============================================================================ *)

FUNCTION_BLOCK CelebrationTimer
VAR_INPUT
    Trigger     : BOOL;     (* Start celebration *)
    Duration    : TIME;     (* Celebration duration *)
END_VAR

VAR_OUTPUT
    Active      : BOOL;     (* TRUE during celebration *)
    FlashPattern: BOOL;     (* Flashing pattern for LEDs *)
    Complete    : BOOL;     (* TRUE when celebration is finished *)
END_VAR

VAR
    CelebTimer  : TON;      (* Main celebration timer *)
    FlashTimer  : TON;      (* Flash pattern timer *)
    TriggerEdge : R_TRIG;   (* Edge detection for trigger *)
END_VAR

TriggerEdge(CLK := Trigger);

IF TriggerEdge.Q THEN
    Active := TRUE;
    Complete := FALSE;
    CelebTimer(IN := FALSE); (* Reset timer *)
END_IF;

IF Active THEN
    CelebTimer(IN := TRUE, PT := Duration);
    
    (* Create flash pattern (200ms on/off) *)
    FlashTimer(IN := TRUE, PT := T#200ms);
    IF FlashTimer.Q THEN
        FlashPattern := NOT FlashPattern;
        FlashTimer(IN := FALSE);
    END_IF;
    
    (* Check if celebration is complete *)
    IF CelebTimer.Q THEN
        Active := FALSE;
        Complete := TRUE;
        FlashPattern := FALSE;
    END_IF;
ELSE
    FlashPattern := FALSE;
    IF Complete THEN
        Complete := FALSE; (* Reset complete flag after one scan *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK

(* ============================================================================ *)
(* FUNCTION BLOCK: ErrorTimer *)
(* Purpose: Manages game over error display *)
(* ============================================================================ *)

FUNCTION_BLOCK ErrorTimer
VAR_INPUT
    Trigger     : BOOL;     (* Start error display *)
    BlinkCount  : INT;      (* Number of blinks (default 3) *)
    BlinkSpeed  : TIME;     (* Blink speed (default 200ms) *)
    HoldTime    : TIME;     (* Final hold time (default 2s) *)
END_VAR

VAR_OUTPUT
    Active      : BOOL;     (* TRUE during error display *)
    BlinkState  : BOOL;     (* Blink pattern for LEDs *)
    Complete    : BOOL;     (* TRUE when error display is finished *)
END_VAR

VAR
    BlinkTimer  : TON;      (* Blink timing *)
    HoldTimer   : TON;      (* Final hold timing *)
    TriggerEdge : R_TRIG;   (* Edge detection *)
    BlinkCounter: INT;      (* Current blink count *)
    Phase       : INT;      (* 0=Blink, 1=Hold *)
END_VAR

TriggerEdge(CLK := Trigger);

IF TriggerEdge.Q THEN
    Active := TRUE;
    Complete := FALSE;
    BlinkCounter := 0;
    Phase := 0;
    BlinkState := FALSE;
    BlinkTimer(IN := FALSE);
    HoldTimer(IN := FALSE);
END_IF;

IF Active THEN
    CASE Phase OF
        0: (* Blinking phase *)
            BlinkTimer(IN := TRUE, PT := BlinkSpeed);
            IF BlinkTimer.Q THEN
                BlinkState := NOT BlinkState;
                BlinkCounter := BlinkCounter + 1;
                BlinkTimer(IN := FALSE);
                
                IF BlinkCounter >= (BlinkCount * 2) THEN (* *2 for on/off cycles *)
                    Phase := 1;
                    BlinkState := TRUE; (* Final state ON *)
                END_IF;
            END_IF;
            
        1: (* Hold phase *)
            HoldTimer(IN := TRUE, PT := HoldTime);
            IF HoldTimer.Q THEN
                Active := FALSE;
                Complete := TRUE;
                BlinkState := FALSE;
            END_IF;
    END_CASE;
ELSE
    BlinkState := FALSE;
    IF Complete THEN
        Complete := FALSE; (* Reset complete flag *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK

(* ============================================================================ *)
(* FUNCTION: RandomGenerator *)
(* Purpose: Generate random numbers for sequence *)
(* ============================================================================ *)

FUNCTION RandomGenerator : INT
VAR_INPUT
    Seed        : DINT;     (* Random seed *)
    MinValue    : INT;      (* Minimum value (inclusive) *)
    MaxValue    : INT;      (* Maximum value (inclusive) *)
END_VAR

VAR
    NewSeed     : DINT;
    Range       : INT;
END_VAR

(* Linear Congruential Generator *)
NewSeed := Seed * 1103515245 + 12345;

(* Calculate range *)
Range := MaxValue - MinValue + 1;

(* Return random value in range *)
RandomGenerator := MinValue + (NewSeed MOD Range);

END_FUNCTION

(* ============================================================================ *)
(* FUNCTION BLOCK: GameDifficulty *)
(* Purpose: Manages difficulty settings for future phases *)
(* ============================================================================ *)

FUNCTION_BLOCK GameDifficulty
VAR_INPUT
    DifficultyLevel : INT;  (* 0=Easy, 1=Normal, 2=Hard *)
END_VAR

VAR_OUTPUT
    FlashTime       : TIME; (* LED flash duration *)
    GapTime         : TIME; (* Gap between flashes *)
    InputTimeout    : TIME; (* Player input timeout *)
    MaxSequence     : INT;  (* Maximum sequence length *)
END_VAR

CASE DifficultyLevel OF
    0: (* Easy *)
        FlashTime := T#800ms;
        GapTime := T#400ms;
        InputTimeout := T#5s;
        MaxSequence := 10;
        
    1: (* Normal *)
        FlashTime := T#500ms;
        GapTime := T#200ms;
        InputTimeout := T#3s;
        MaxSequence := 15;
        
    2: (* Hard *)
        FlashTime := T#300ms;
        GapTime := T#100ms;
        InputTimeout := T#2s;
        MaxSequence := 20;
        
    ELSE (* Default to Normal *)
        FlashTime := T#500ms;
        GapTime := T#200ms;
        InputTimeout := T#3s;
        MaxSequence := 15;
END_CASE;

END_FUNCTION_BLOCK