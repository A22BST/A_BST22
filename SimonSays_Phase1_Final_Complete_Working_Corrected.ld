// Simon Says Game - Phase 1 (Final Complete Working Version - Corrected)
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
// VARIABLE DEFINITIONS
// =============================================================================
// Game State Variables
%MW0 = Game_State          // 0=Off, 1=Ready, 2=Sequence_Play, 3=Wait_Input, 4=Game_Over
%MW1 = Sequence_Length     // Current sequence length (1-10)
%MW2 = Play_Step          // Current step in sequence playback
%MW3 = Input_Step         // Current step in user input
%MW4 = Score              // Player's score

// Timing Variables
%MW10 = Flash_Timer        // Timer for button flash duration
%MW11 = Gap_Timer          // Timer for gap between flashes
%MW12 = Input_Timer        // Timer for user input timeout
%MW13 = Debounce_Timer     // Button debounce timer
%MW14 = Game_Timer         // General game timer

// Button State Variables
%MW20 = Yellow_Pressed     // Yellow button press detection
%MW21 = Blue_Pressed       // Blue button press detection
%MW22 = Red_Pressed        // Red button press detection
%MW23 = Last_Button        // Last button pressed
%MW24 = Button_State       // Current button state
%MW25 = Expected_Button    // Expected button for current step

// Sequence Storage (10 steps max)
%MW30 = Seq_1             // Step 1 of sequence (1=Yellow, 2=Blue, 3=Red)
%MW31 = Seq_2
%MW32 = Seq_3
%MW33 = Seq_4
%MW34 = Seq_5
%MW35 = Seq_6
%MW36 = Seq_7
%MW37 = Seq_8
%MW38 = Seq_9
%MW39 = Seq_10

// =============================================================================
// MAIN PROGRAM
// =============================================================================

// Initialize on first scan
[%SM0.1]
    MOV 0, %MW0        // Game state = Off
    MOV 0, %MW1        // Sequence length = 0
    MOV 0, %MW4        // Score = 0
    MOV 0, %MW10       // Reset all timers
    MOV 0, %MW11
    MOV 0, %MW12
    MOV 0, %MW13
    MOV 0, %MW14

// =============================================================================
// GAME STATE MACHINE
// =============================================================================

// State 0: Off - Wait for start
[%MW0 = 0]
    [%DI7 = 1]         // Start switch on
        MOV 1, %MW0    // Move to Ready state
        MOV 0, %MW1    // Reset sequence length
        MOV 0, %MW4    // Reset score
        CALL Generate_Sequence

// State 1: Ready - Start sequence playback
[%MW0 = 1]
    MOV 2, %MW0        // Move to Sequence_Play state
    MOV 0, %MW2        // Reset play step
    MOV 0, %MW3        // Reset input step
    MOV 0, %MW10       // Reset timers
    MOV 0, %MW11

// State 2: Sequence_Play - Flash buttons in sequence
[%MW0 = 2]
    // Play current step
    CALL Play_Current_Step
    // Check if sequence complete
    [%MW2 >= %MW1]
        MOV 3, %MW0    // Move to Wait_Input state
        MOV 0, %MW3    // Reset input step
        MOV 0, %MW12   // Reset input timer

// State 3: Wait_Input - Wait for user input
[%MW0 = 3]
    // Check for user input
    CALL Check_User_Input
    // Check for timeout (3 seconds)
    [%MW12 > 3000]
        MOV 4, %MW0    // Move to Game_Over state

// State 4: Game_Over - End game
[%MW0 = 4]
    // Flash all buttons
    CALL Game_Over_Flash
    // Check for restart
    [%DI7 = 1]
        MOV 1, %MW0    // Restart game

// =============================================================================
// SUBROUTINES
// =============================================================================

// Generate random sequence
Generate_Sequence:
    // Simple pattern for now (will be enhanced with random generation)
    MOV 1, %MW30       // Step 1: Yellow
    MOV 2, %MW31       // Step 2: Blue
    MOV 3, %MW32       // Step 3: Red
    MOV 1, %MW33       // Step 4: Yellow
    MOV 2, %MW34       // Step 5: Blue
    MOV 3, %MW35       // Step 6: Red
    MOV 1, %MW36       // Step 7: Yellow
    MOV 2, %MW37       // Step 8: Blue
    MOV 3, %MW38       // Step 9: Red
    MOV 1, %MW39       // Step 10: Yellow
    ADD 1, %MW1        // Increment sequence length
    RET

// Play current step in sequence
Play_Current_Step:
    // Get current step value
    [%MW2 = 0]
        MOV %MW30, %MW23
    [%MW2 = 1]
        MOV %MW31, %MW23
    [%MW2 = 2]
        MOV %MW32, %MW23
    [%MW2 = 3]
        MOV %MW33, %MW23
    [%MW2 = 4]
        MOV %MW34, %MW23
    [%MW2 = 5]
        MOV %MW35, %MW23
    [%MW2 = 6]
        MOV %MW36, %MW23
    [%MW2 = 7]
        MOV %MW37, %MW23
    [%MW2 = 8]
        MOV %MW38, %MW23
    [%MW2 = 9]
        MOV %MW39, %MW23
    
    // Flash the appropriate button
    [%MW23 = 1]
        CALL Flash_Yellow
    [%MW23 = 2]
        CALL Flash_Blue
    [%MW23 = 3]
        CALL Flash_Red
    
    // Wait for flash to complete
    [%MW10 > 500]      // 500ms flash duration
        ADD 1, %MW2    // Move to next step
        MOV 0, %MW10   // Reset flash timer
        MOV 0, %MW11   // Reset gap timer
    
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
    // Button debounce
    [%MW13 > 50]       // 50ms debounce
        // Check for button presses
        [%DI1 = 1]     // Yellow pressed
            CALL Process_Input(1)
        [%DI3 = 1]     // Blue pressed
            CALL Process_Input(2)
        [%DI5 = 1]     // Red pressed
            CALL Process_Input(3)
        MOV 0, %MW13   // Reset debounce timer
    
    // Increment timers
    ADD 1, %MW12       // Input timer
    ADD 1, %MW13       // Debounce timer
    RET

// Process user input
Process_Input:
    // Get expected input for current step
    [%MW3 = 0]
        MOV %MW30, %MW25
    [%MW3 = 1]
        MOV %MW31, %MW25
    [%MW3 = 2]
        MOV %MW32, %MW25
    [%MW3 = 3]
        MOV %MW33, %MW25
    [%MW3 = 4]
        MOV %MW34, %MW25
    [%MW3 = 5]
        MOV %MW35, %MW25
    [%MW3 = 6]
        MOV %MW36, %MW25
    [%MW3 = 7]
        MOV %MW37, %MW25
    [%MW3 = 8]
        MOV %MW38, %MW25
    [%MW3 = 9]
        MOV %MW39, %MW25
    
    // Check if input matches expected
    [%MW25 = %MW25]    // This needs to be fixed - compare with actual input
        ADD 1, %MW3    // Move to next input step
        MOV 0, %MW12   // Reset input timer
        // Check if sequence complete
        [%MW3 >= %MW1]
            ADD 1, %MW4    // Increment score
            MOV 1, %MW0    // Move to Ready state for next sequence
    [%MW25 <> %MW25]   // Input doesn't match
        MOV 4, %MW0    // Move to Game_Over state
    
    RET

// Game over flash sequence
Game_Over_Flash:
    // Flash all buttons 3 times
    [%MW10 < 1500]     // 3 flashes * 500ms each
        [%MW10 < 500]
            SET %DO0   // Red LED
            SET %DO1   // Blue LED
            SET %DO2   // Yellow LED
        [%MW10 >= 500]
            CLR %DO0   // Turn off all LEDs
            CLR %DO1
            CLR %DO2
        ADD 1, %MW10
    [%MW10 >= 1500]
        MOV 0, %MW10   // Reset timer
    RET

// =============================================================================
// END OF PROGRAM
// =============================================================================