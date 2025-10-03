PROGRAM PLC_Arcade_System
VAR
    // ============================================================================
    // INPUT MAPPING (Contacts)
    // ============================================================================
    IBTN_R: BOOL;       // Red button - DI0
    IBTN_B: BOOL;       // Blue button - DI2
    IBTN_Y: BOOL;       // Yellow button - DI4
    ISEL_LT: BOOL;      // Simon Says selector - DI3 (Yellow wire)
    ISEL_R: BOOL;       // Reaction Game selector - DI5 (Green wire)
    IBTN_M: BOOL;       // Main button - DI1 (Brown wire)
    
    // ============================================================================
    // OUTPUT MAPPING (LEDs)
    // ============================================================================
    OLED_R: BOOL;       // Red LED - DO1
    OLED_B: BOOL;       // Blue LED - DO3
    OLED_Y: BOOL;       // Yellow LED - DO5
    OLED_MAIN: BOOL;    // Main LED - DO0 (White wire)
    
    // ============================================================================
    // SYSTEM CONTROL VARIABLES
    // ============================================================================
    SystemActive: BOOL := FALSE;
    GameRunning: BOOL := FALSE;
    ModeLocked: BOOL := FALSE;
    EmergencyStop: BOOL := FALSE;
    
    // Mode Selection
    CurrentMode: INT := 0;  // 0=Simon Says, 1=Reaction Game, 2=Idle
    PreviousMode: INT := 0;
    
    // Button States (Debounced)
    BtnR_State: BOOL := FALSE;
    BtnB_State: BOOL := FALSE;
    BtnY_State: BOOL := FALSE;
    BtnM_State: BOOL := FALSE;
    
    // Button Edge Detection
    BtnR_Rising: BOOL := FALSE;
    BtnB_Rising: BOOL := FALSE;
    BtnY_Rising: BOOL := FALSE;
    BtnM_Rising: BOOL := FALSE;
    
    // Previous Button States for Edge Detection
    PrevBtnR: BOOL := FALSE;
    PrevBtnB: BOOL := FALSE;
    PrevBtnY: BOOL := FALSE;
    PrevBtnM: BOOL := FALSE;
    
    // ============================================================================
    // DEBOUNCE TIMERS
    // ============================================================================
    DebounceTimer: TON;
    ModeLockTimer: TON;
    
    // ============================================================================
    // CONTINUOUS RANDOM GENERATOR VARIABLES
    // ============================================================================
    RandomGenActive: BOOL := FALSE;
    RandomGenRunning: BOOL := FALSE;
    RandomCounter: INT := 0;
    OutputSelect: INT := 0;
    
    // Random Generator Outputs
    RandomOut1: BOOL := FALSE;
    RandomOut2: BOOL := FALSE;
    RandomOut3: BOOL := FALSE;
    
    // ============================================================================
    // SIMON SAYS GAME VARIABLES
    // ============================================================================
    SimonActive: BOOL := FALSE;
    SimonGameOver: BOOL := FALSE;
    SimonState: INT := 0;  // 0=Off, 1=Init, 2=Generate, 3=Show, 4=Input, 5=Check, 6=Complete
    
    SimonSequence: ARRAY[1..20] OF INT := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    SequenceLength: INT := 1;
    CurrentStep: INT := 0;
    PlayerInputStep: INT := 0;
    
    SimonScore: INT := 0;
    SimonLevel: INT := 1;
    
    // Simon Says Timers
    SimonSequenceTimer: TON;
    SimonInputTimer: TON;
    SimonPauseTimer: TON;
    
    // Simon Says Outputs
    SimonOut1: BOOL := FALSE;
    SimonOut2: BOOL := FALSE;
    SimonOut3: BOOL := FALSE;
    
    // ============================================================================
    // REACTION GAME VARIABLES
    // ============================================================================
    ReactionActive: BOOL := FALSE;
    ReactionGameOver: BOOL := FALSE;
    ReactionState: INT := 0;  // 0=Off, 1=Wait, 2=Show, 3=Score
    
    ReactionStartTime: INT := 0;
    ReactionEndTime: INT := 0;
    ReactionScore: INT := 0;
    ReactionTarget: INT := 0;  // Which LED to light up (1,2,3)
    
    // Reaction Game Timers
    ReactionWaitTimer: TON;
    ReactionShowTimer: TON;
    
    // Reaction Game Outputs
    ReactionOut1: BOOL := FALSE;
    ReactionOut2: BOOL := FALSE;
    ReactionOut3: BOOL := FALSE;
    
    // ============================================================================
    // OUTPUT MAPPER VARIABLES
    // ============================================================================
    OutputPriority: INT := 0;  // 0=Off, 1=Game, 2=Status, 3=Emergency
    OutputConflict: BOOL := FALSE;
    SafetyInterlock: BOOL := TRUE;
    SystemHealthy: BOOL := TRUE;
    
    // Status Outputs
    StatusOut1: BOOL := FALSE;
    StatusOut2: BOOL := FALSE;
    StatusOut3: BOOL := FALSE;
    
    // Emergency Outputs
    EmergencyOut1: BOOL := FALSE;
    EmergencyOut2: BOOL := FALSE;
    EmergencyOut3: BOOL := FALSE;
    
    // ============================================================================
    // TIMING VARIABLES
    // ============================================================================
    SystemTimer: TON;
    BlinkTimer: TON;
    
    // ============================================================================
    // DIAGNOSTIC VARIABLES
    // ============================================================================
    ConflictCounter: INT := 0;
    SafetyFailureCounter: INT := 0;
    SystemFailureCounter: INT := 0;
    
END_VAR

// ============================================================================
// MAIN PROGRAM LOGIC
// ============================================================================

// Input Mapping
IBTN_R := NOT DI0;      // Red button - DI0 (inverted if normally closed)
IBTN_B := NOT DI2;      // Blue button - DI2
IBTN_Y := NOT DI4;      // Yellow button - DI4
ISEL_LT := NOT DI3;     // Simon Says selector - DI3
ISEL_R := NOT DI5;      // Reaction Game selector - DI5
IBTN_M := NOT DI1;      // Main button - DI1

// Button Edge Detection
BtnR_Rising := IBTN_R AND NOT PrevBtnR;
BtnB_Rising := IBTN_B AND NOT PrevBtnB;
BtnY_Rising := IBTN_Y AND NOT PrevBtnY;
BtnM_Rising := IBTN_M AND NOT PrevBtnM;

PrevBtnR := IBTN_R;
PrevBtnB := IBTN_B;
PrevBtnY := IBTN_Y;
PrevBtnM := IBTN_M;

// Button Debouncing
DebounceTimer(IN := IBTN_R OR IBTN_B OR IBTN_Y OR IBTN_M, PT := T#50MS);

IF DebounceTimer.Q THEN
    BtnR_State := IBTN_R;
    BtnB_State := IBTN_B;
    BtnY_State := IBTN_Y;
    BtnM_State := IBTN_M;
END_IF;

// Mode Selection Logic
PreviousMode := CurrentMode;

IF ISEL_LT THEN
    CurrentMode := 0;  // Simon Says
ELSIF ISEL_R THEN
    CurrentMode := 1;  // Reaction Game
ELSE
    CurrentMode := 2;  // Idle Mode
END_IF;

// Mode Lock Logic
IF BtnM_Rising AND NOT ModeLocked THEN
    ModeLocked := TRUE;
    ModeLockTimer(IN := FALSE, PT := T#0MS);
ELSIF BtnM_Rising AND ModeLocked THEN
    ModeLocked := FALSE;
END_IF;

// System Activation
IF ModeLocked AND BtnM_Rising THEN
    GameRunning := TRUE;
    SystemActive := TRUE;
END_IF;

// Emergency Stop
IF EmergencyStop THEN
    GameRunning := FALSE;
    SystemActive := FALSE;
    ModeLocked := FALSE;
    OutputPriority := 3;  // Emergency priority
END_IF;

// ============================================================================
// CONTINUOUS RANDOM GENERATOR
// ============================================================================

RandomGenActive := SystemActive;

// Random Generator Timer
SystemTimer(IN := RandomGenActive, PT := T#100MS);

// Increment Counter
IF SystemTimer.Q THEN
    SystemTimer(IN := FALSE, PT := T#0MS);
    RandomCounter := RandomCounter + 1;
    IF RandomCounter >= 1000 THEN
        RandomCounter := 0;
    END_IF;
END_IF;

// Calculate Output Selection
OutputSelect := RandomCounter MOD 3;
RandomGenRunning := RandomGenActive;

// Set Random Outputs
RandomOut1 := RandomGenRunning AND (OutputSelect = 0);
RandomOut2 := RandomGenRunning AND (OutputSelect = 1);
RandomOut3 := RandomGenRunning AND (OutputSelect = 2);

// ============================================================================
// SIMON SAYS GAME LOGIC
// ============================================================================

SimonActive := (CurrentMode = 0) AND GameRunning;

// Simon Says State Machine
CASE SimonState OF
    0:  // Game Off
        IF SimonActive THEN
            SimonState := 1;
            SimonScore := 0;
            SimonLevel := 1;
            SequenceLength := 1;
            SimonGameOver := FALSE;
        END_IF;
        
    1:  // Initialize Game
        CurrentStep := 0;
        PlayerInputStep := 0;
        SimonSequenceTimer(IN := FALSE, PT := T#0MS);
        SimonInputTimer(IN := FALSE, PT := T#0MS);
        SimonPauseTimer(IN := FALSE, PT := T#0MS);
        SimonState := 2;
        
    2:  // Generate Sequence
        FOR i := 1 TO SequenceLength DO
            SimonSequence[i] := (RandomCounter + i) MOD 3 + 1;
        END_FOR;
        SimonState := 3;
        
    3:  // Show Sequence
        IF CurrentStep < SequenceLength THEN
            SimonSequenceTimer(IN := TRUE, PT := T#500MS);
            IF SimonSequenceTimer.Q THEN
                SimonSequenceTimer(IN := FALSE, PT := T#0MS);
                CurrentStep := CurrentStep + 1;
            END_IF;
        ELSE
            SimonPauseTimer(IN := TRUE, PT := T#1000MS);
            IF SimonPauseTimer.Q THEN
                SimonPauseTimer(IN := FALSE, PT := T#0MS);
                CurrentStep := 0;
                PlayerInputStep := 0;
                SimonState := 4;
            END_IF;
        END_IF;
        
    4:  // Wait for Player Input
        SimonInputTimer(IN := TRUE, PT := T#5000MS);
        
        // Check for player input
        IF BtnR_Rising THEN
            IF SimonSequence[PlayerInputStep + 1] = 1 THEN
                PlayerInputStep := PlayerInputStep + 1;
            ELSE
                SimonGameOver := TRUE;
                SimonState := 6;
            END_IF;
        ELSIF BtnB_Rising THEN
            IF SimonSequence[PlayerInputStep + 1] = 2 THEN
                PlayerInputStep := PlayerInputStep + 1;
            ELSE
                SimonGameOver := TRUE;
                SimonState := 6;
            END_IF;
        ELSIF BtnY_Rising THEN
            IF SimonSequence[PlayerInputStep + 1] = 3 THEN
                PlayerInputStep := PlayerInputStep + 1;
            ELSE
                SimonGameOver := TRUE;
                SimonState := 6;
            END_IF;
        END_IF;
        
        // Check if input complete or timeout
        IF PlayerInputStep >= SequenceLength THEN
            SimonScore := SimonScore + (SequenceLength * 10);
            SequenceLength := SequenceLength + 1;
            SimonState := 2;  // Generate next sequence
        ELSIF SimonInputTimer.Q THEN
            SimonGameOver := TRUE;
            SimonState := 6;
        END_IF;
        
    5:  // Check Input (Not used in this implementation)
        SimonState := 6;
        
    6:  // Game Complete
        SimonInputTimer(IN := FALSE, PT := T#0MS);
        IF NOT SimonActive THEN
            SimonState := 0;
        END_IF;
END_CASE;

// Simon Says Output Control
SimonOut1 := (SimonState = 3) AND (CurrentStep <= SequenceLength) AND (SimonSequence[CurrentStep] = 1);
SimonOut2 := (SimonState = 3) AND (CurrentStep <= SequenceLength) AND (SimonSequence[CurrentStep] = 2);
SimonOut3 := (SimonState = 3) AND (CurrentStep <= SequenceLength) AND (SimonSequence[CurrentStep] = 3);

// Add player input feedback
SimonOut1 := SimonOut1 OR ((SimonState = 4) AND BtnR_State);
SimonOut2 := SimonOut2 OR ((SimonState = 4) AND BtnB_State);
SimonOut3 := SimonOut3 OR ((SimonState = 4) AND BtnY_State);

// ============================================================================
// REACTION GAME LOGIC
// ============================================================================

ReactionActive := (CurrentMode = 1) AND GameRunning;

// Reaction Game State Machine
CASE ReactionState OF
    0:  // Game Off
        IF ReactionActive THEN
            ReactionState := 1;
            ReactionScore := 0;
            ReactionGameOver := FALSE;
        END_IF;
        
    1:  // Wait Phase
        ReactionWaitTimer(IN := TRUE, PT := T#2000MS + (RandomCounter MOD 3000MS));
        IF ReactionWaitTimer.Q THEN
            ReactionWaitTimer(IN := FALSE, PT := T#0MS);
            ReactionTarget := (RandomCounter MOD 3) + 1;
            ReactionState := 2;
        END_IF;
        
    2:  // Show Target
        ReactionShowTimer(IN := TRUE, PT := T#1000MS);
        
        // Check for player reaction
        IF (ReactionTarget = 1) AND BtnR_Rising THEN
            ReactionEndTime := 1000 - ReactionShowTimer.ET;
            ReactionScore := ReactionEndTime;
            ReactionState := 3;
        ELSIF (ReactionTarget = 2) AND BtnB_Rising THEN
            ReactionEndTime := 1000 - ReactionShowTimer.ET;
            ReactionScore := ReactionEndTime;
            ReactionState := 3;
        ELSIF (ReactionTarget = 3) AND BtnY_Rising THEN
            ReactionEndTime := 1000 - ReactionShowTimer.ET;
            ReactionScore := ReactionEndTime;
            ReactionState := 3;
        ELSIF ReactionShowTimer.Q THEN
            ReactionGameOver := TRUE;
            ReactionState := 3;
        END_IF;
        
    3:  // Score Phase
        IF NOT ReactionActive THEN
            ReactionState := 0;
        ELSIF BtnM_Rising THEN
            ReactionState := 1;  // Start new round
        END_IF;
END_CASE;

// Reaction Game Output Control
ReactionOut1 := (ReactionState = 2) AND (ReactionTarget = 1);
ReactionOut2 := (ReactionState = 2) AND (ReactionTarget = 2);
ReactionOut3 := (ReactionState = 2) AND (ReactionTarget = 3);

// ============================================================================
// OUTPUT MAPPER AND SAFETY LOGIC
// ============================================================================

// Detect Output Conflicts
OutputConflict := (SimonActive AND ReactionActive) OR 
                  (SimonActive AND (CurrentMode = 2)) OR 
                  (ReactionActive AND (CurrentMode = 2));

// Output Priority Control
IF EmergencyStop THEN
    OutputPriority := 3;  // Emergency
ELSIF NOT SystemHealthy THEN
    OutputPriority := 3;  // Emergency
ELSIF OutputConflict THEN
    OutputPriority := 3;  // Emergency
ELSIF GameRunning THEN
    OutputPriority := 1;  // Game
ELSIF SystemActive THEN
    OutputPriority := 2;  // Status
ELSE
    OutputPriority := 0;  // Off
END_IF;

// Status Outputs
StatusOut1 := SystemActive;
StatusOut2 := GameRunning;
StatusOut3 := OutputConflict OR NOT SystemHealthy;

// Emergency Outputs
EmergencyOut1 := EmergencyStop;
EmergencyOut2 := NOT SystemHealthy;
EmergencyOut3 := OutputConflict;

// Final Output Mapping
CASE OutputPriority OF
    0:  // System Off
        OLED_R := FALSE;
        OLED_B := FALSE;
        OLED_Y := FALSE;
        OLED_MAIN := FALSE;
        
    1:  // Game Outputs
        IF CurrentMode = 0 THEN  // Simon Says
            OLED_R := SimonOut1;
            OLED_B := SimonOut2;
            OLED_Y := SimonOut3;
        ELSIF CurrentMode = 1 THEN  // Reaction Game
            OLED_R := ReactionOut1;
            OLED_B := ReactionOut2;
            OLED_Y := ReactionOut3;
        ELSE  // Idle Mode
            OLED_R := RandomOut1;
            OLED_B := RandomOut2;
            OLED_Y := RandomOut3;
        END_IF;
        OLED_MAIN := GameRunning;
        
    2:  // Status Outputs
        OLED_R := StatusOut1;
        OLED_B := StatusOut2;
        OLED_Y := StatusOut3;
        OLED_MAIN := ModeLocked;
        
    3:  // Emergency Outputs
        OLED_R := EmergencyOut1;
        OLED_B := EmergencyOut2;
        OLED_Y := EmergencyOut3;
        OLED_MAIN := FALSE;
END_CASE;

// Output Mapping to Physical DO
DO1 := OLED_R;
DO3 := OLED_B;
DO5 := OLED_Y;
DO0 := OLED_MAIN;

// ============================================================================
// DIAGNOSTIC AND MONITORING
// ============================================================================

// Count Conflicts
IF OutputConflict THEN
    ConflictCounter := ConflictCounter + 1;
END_IF;

// Count Safety Failures
IF NOT SystemHealthy THEN
    SafetyFailureCounter := SafetyFailureCounter + 1;
END_IF;

// System Health Check
SystemHealthy := TRUE;  // Placeholder - implement actual health checks

// ============================================================================
// END OF PROGRAM
// ============================================================================