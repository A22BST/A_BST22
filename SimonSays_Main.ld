// Simon Says Game - Phase 1 (3 Buttons: Yellow, Blue, Red)
// Hardware: Omron NX102-1100 with NX-ID4442 and NX-OD4256
// Buttons: Yellow (DI1/DO2), Blue (DI3/DO1), Red (DI5/DO0)

// =============================================================================
// I/O MAPPING
// =============================================================================
// Digital Inputs (NX-ID4442):
// DI1 = Yellow Button Contact
// DI3 = Blue Button Contact  
// DI5 = Red Button Contact
// DI7 = Start/Stop Selector Switch (Right = Start, Middle = Stop, Left = Off)

// Digital Outputs (NX-OD4256):
// DO0 = Red LED
// DO1 = Blue LED
// DO2 = Yellow LED

// =============================================================================
// GAME VARIABLES
// =============================================================================
// Game State Variables
%MW0 = Game_State          // 0=Off, 1=Ready, 2=Playing, 3=Sequence_Play, 4=Wait_Input, 5=Game_Over
%MW1 = Sequence_Length     // Current sequence length (1-10)
%MW2 = Current_Step        // Current step in sequence playback
%MW3 = Input_Step          // Current step in user input
%MW4 = Score               // Player's score
%MW5 = Difficulty          // Difficulty level (0=Easy, 1=Normal, 2=Hard)

// Timing Variables
%MW10 = Flash_Timer        // Timer for button flash duration
%MW11 = Gap_Timer          // Timer for gap between flashes
%MW12 = Input_Timer        // Timer for user input timeout
%MW13 = Game_Timer         // General game timer

// Button State Variables
%MW20 = Yellow_Pressed     // Yellow button press detection
%MW21 = Blue_Pressed       // Blue button press detection
%MW22 = Red_Pressed        // Red button press detection
%MW23 = Button_Debounce    // Button debounce timer

// Sequence Storage (10 steps max)
%MW30 = Sequence_1         // Step 1 of sequence (1=Yellow, 2=Blue, 3=Red)
%MW31 = Sequence_2
%MW32 = Sequence_3
%MW33 = Sequence_4
%MW34 = Sequence_5
%MW35 = Sequence_6
%MW36 = Sequence_7
%MW37 = Sequence_8
%MW38 = Sequence_9
%MW39 = Sequence_10

// =============================================================================
// MAIN PROGRAM START
// =============================================================================

// Initialize game on first scan
[%SM0.1]
    MOV 0, %MW0        // Set game state to Off
    MOV 0, %MW1        // Reset sequence length
    MOV 0, %MW4        // Reset score
    MOV 1, %MW5        // Set default difficulty to Normal

// =============================================================================
// GAME STATE MACHINE
// =============================================================================

// State 0: Off - Wait for start
[%MW0 = 0]
    // Check for start condition (selector switch right position)
    [%DI7 = 1]
        MOV 1, %MW0    // Move to Ready state
        MOV 0, %MW1    // Reset sequence length
        MOV 0, %MW4    // Reset score

// State 1: Ready - Generate first sequence
[%MW0 = 1]
    // Generate random sequence
    CALL Generate_Sequence
    MOV 2, %MW0        // Move to Playing state
    MOV 0, %MW2        // Reset current step
    MOV 0, %MW3        // Reset input step

// State 2: Playing - Play sequence
[%MW0 = 2]
    // Start sequence playback
    MOV 3, %MW0        // Move to Sequence_Play state
    MOV 0, %MW2        // Reset current step

// State 3: Sequence_Play - Flash buttons in sequence
[%MW0 = 3]
    // Play current step in sequence
    CALL Play_Sequence_Step
    // Check if sequence complete
    [%MW2 >= %MW1]
        MOV 4, %MW0    // Move to Wait_Input state
        MOV 0, %MW3    // Reset input step

// State 4: Wait_Input - Wait for user input
[%MW0 = 4]
    // Check for correct input
    CALL Check_User_Input
    // Check for timeout
    [%MW12 > 3000]     // 3 second timeout
        MOV 5, %MW0    // Move to Game_Over state

// State 5: Game_Over - End game
[%MW0 = 5]
    // Flash all buttons to indicate game over
    CALL Game_Over_Sequence
    // Check for restart
    [%DI7 = 1]
        MOV 1, %MW0    // Restart game

// =============================================================================
// SUBROUTINES
// =============================================================================

// Generate random sequence
Generate_Sequence:
    // Generate sequence based on current length
    // For now, using simple pattern (will be enhanced)
    MOV 1, %MW30       // Step 1: Yellow
    MOV 2, %MW31       // Step 2: Blue  
    MOV 3, %MW32       // Step 3: Red
    ADD 1, %MW1        // Increment sequence length
    RET

// Play current step in sequence
Play_Sequence_Step:
    // Get current step value
    [%MW2 = 0]
        MOV %MW30, %MW13
    [%MW2 = 1]
        MOV %MW31, %MW13
    [%MW2 = 2]
        MOV %MW32, %MW13
    [%MW2 = 3]
        MOV %MW33, %MW13
    [%MW2 = 4]
        MOV %MW34, %MW13
    [%MW2 = 5]
        MOV %MW35, %MW13
    [%MW2 = 6]
        MOV %MW36, %MW13
    [%MW2 = 7]
        MOV %MW37, %MW13
    [%MW2 = 8]
        MOV %MW38, %MW13
    [%MW2 = 9]
        MOV %MW39, %MW13
    
    // Flash the appropriate button
    [%MW13 = 1]
        CALL Flash_Yellow
    [%MW13 = 2]
        CALL Flash_Blue
    [%MW13 = 3]
        CALL Flash_Red
    
    // Wait for flash to complete
    [%MW10 > 500]      // 500ms flash duration
        ADD 1, %MW2    // Move to next step
        MOV 0, %MW10   // Reset flash timer
    
    RET

// Flash Yellow button
Flash_Yellow:
    SET %DO2           // Turn on Yellow LED
    ADD 1, %MW10       // Increment flash timer
    RET

// Flash Blue button
Flash_Blue:
    SET %DO1           // Turn on Blue LED
    ADD 1, %MW10       // Increment flash timer
    RET

// Flash Red button
Flash_Red:
    SET %DO0           // Turn on Red LED
    ADD 1, %MW10       // Increment flash timer
    RET

// Check user input
Check_User_Input:
    // Check for button presses
    [%DI1 = 1]         // Yellow pressed
        CALL Process_Input(1)
    [%DI3 = 1]         // Blue pressed
        CALL Process_Input(2)
    [%DI5 = 1]         // Red pressed
        CALL Process_Input(3)
    
    // Increment input timer
    ADD 1, %MW12
    RET

// Process user input
Process_Input:
    // Get expected input for current step
    [%MW3 = 0]
        MOV %MW30, %MW13
    [%MW3 = 1]
        MOV %MW31, %MW13
    [%MW3 = 2]
        MOV %MW32, %MW13
    [%MW3 = 3]
        MOV %MW33, %MW13
    [%MW3 = 4]
        MOV %MW34, %MW13
    [%MW3 = 5]
        MOV %MW35, %MW13
    [%MW3 = 6]
        MOV %MW36, %MW13
    [%MW3 = 7]
        MOV %MW37, %MW13
    [%MW3 = 8]
        MOV %MW38, %MW13
    [%MW3 = 9]
        MOV %MW39, %MW13
    
    // Check if input matches expected
    [%MW13 = %MW13]    // This needs to be fixed - compare with actual input
        ADD 1, %MW3    // Move to next input step
        MOV 0, %MW12   // Reset input timer
        // Check if sequence complete
        [%MW3 >= %MW1]
            ADD 1, %MW4    // Increment score
            MOV 2, %MW0    // Move to Playing state for next sequence
    [%MW13 <> %MW13]   // Input doesn't match
        MOV 5, %MW0    // Move to Game_Over state
    
    RET

// Game over sequence
Game_Over_Sequence:
    // Flash all buttons 3 times
    [%MW13 < 3]
        CALL Flash_All_Buttons
        ADD 1, %MW13
    [%MW13 >= 3]
        MOV 0, %MW13   // Reset counter
    RET

// Flash all buttons
Flash_All_Buttons:
    SET %DO0           // Red LED
    SET %DO1           // Blue LED
    SET %DO2           // Yellow LED
    // Wait 200ms
    [%MW10 > 200]
        CLR %DO0       // Turn off all LEDs
        CLR %DO1
        CLR %DO2
        MOV 0, %MW10   // Reset timer
    RET

// =============================================================================
// END OF PROGRAM
// =============================================================================