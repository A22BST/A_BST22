// Simon Says Game - Phase 1 (Refined Version)
// Hardware: Omron NX102-1100 with NX-ID4442 and NX-OD4256
// Buttons: Yellow (DI1/DO2), Blue (DI3/DO1), Red (DI5/DO0)

// =============================================================================
// I/O MAPPING AND VARIABLES
// =============================================================================

// Digital Inputs
%DI1 = Yellow_Button
%DI3 = Blue_Button
%DI5 = Red_Button
%DI7 = Start_Stop_Switch

// Digital Outputs
%DO0 = Red_LED
%DO1 = Blue_LED
%DO2 = Yellow_LED

// Game Variables
%MW0 = Game_State          // 0=Off, 1=Ready, 2=Sequence_Play, 3=Wait_Input, 4=Game_Over
%MW1 = Sequence_Length     // Current sequence length (1-10)
%MW2 = Play_Step          // Current step in sequence playback
%MW3 = Input_Step         // Current step in user input
%MW4 = Score              // Player's score
%MW5 = Flash_Timer        // Timer for button flash duration
%MW6 = Gap_Timer          // Timer for gap between flashes
%MW7 = Input_Timer        // Timer for user input timeout
%MW8 = Button_Debounce    // Button debounce timer

// Sequence Storage (10 steps max)
%MW10 = Seq_1             // Step 1 of sequence (1=Yellow, 2=Blue, 3=Red)
%MW11 = Seq_2
%MW12 = Seq_3
%MW13 = Seq_4
%MW14 = Seq_5
%MW15 = Seq_6
%MW16 = Seq_7
%MW17 = Seq_8
%MW18 = Seq_9
%MW19 = Seq_10

// Button State Variables
%MW20 = Yellow_Pressed
%MW21 = Blue_Pressed
%MW22 = Red_Pressed
%MW23 = Last_Button

// =============================================================================
// MAIN PROGRAM
// =============================================================================

// Initialize on first scan
[%SM0.1]
    MOV 0, %MW0        // Game state = Off
    MOV 0, %MW1        // Sequence length = 0
    MOV 0, %MW4        // Score = 0
    MOV 0, %MW5        // Reset timers
    MOV 0, %MW6
    MOV 0, %MW7
    MOV 0, %MW8

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

// State 2: Sequence_Play - Flash buttons in sequence
[%MW0 = 2]
    // Play current step
    CALL Play_Current_Step
    // Check if sequence complete
    [%MW2 >= %MW1]
        MOV 3, %MW0    // Move to Wait_Input state
        MOV 0, %MW3    // Reset input step
        MOV 0, %MW7    // Reset input timer

// State 3: Wait_Input - Wait for user input
[%MW0 = 3]
    // Check for user input
    CALL Check_User_Input
    // Check for timeout (3 seconds)
    [%MW7 > 3000]
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
    MOV 1, %MW10       // Step 1: Yellow
    MOV 2, %MW11       // Step 2: Blue
    MOV 3, %MW12       // Step 3: Red
    MOV 1, %MW13       // Step 4: Yellow
    MOV 2, %MW14       // Step 5: Blue
    MOV 3, %MW15       // Step 6: Red
    MOV 1, %MW16       // Step 7: Yellow
    MOV 2, %MW17       // Step 8: Blue
    MOV 3, %MW18       // Step 9: Red
    MOV 1, %MW19       // Step 10: Yellow
    ADD 1, %MW1        // Increment sequence length
    RET

// Play current step in sequence
Play_Current_Step:
    // Get current step value
    [%MW2 = 0]
        MOV %MW10, %MW23
    [%MW2 = 1]
        MOV %MW11, %MW23
    [%MW2 = 2]
        MOV %MW12, %MW23
    [%MW2 = 3]
        MOV %MW13, %MW23
    [%MW2 = 4]
        MOV %MW14, %MW23
    [%MW2 = 5]
        MOV %MW15, %MW23
    [%MW2 = 6]
        MOV %MW16, %MW23
    [%MW2 = 7]
        MOV %MW17, %MW23
    [%MW2 = 8]
        MOV %MW18, %MW23
    [%MW2 = 9]
        MOV %MW19, %MW23
    
    // Flash the appropriate button
    [%MW23 = 1]
        CALL Flash_Yellow
    [%MW23 = 2]
        CALL Flash_Blue
    [%MW23 = 3]
        CALL Flash_Red
    
    // Wait for flash to complete
    [%MW5 > 500]       // 500ms flash duration
        ADD 1, %MW2    // Move to next step
        MOV 0, %MW5    // Reset flash timer
        MOV 0, %MW6    // Reset gap timer
    
    RET

// Flash Yellow button
Flash_Yellow:
    SET %DO2           // Turn on Yellow LED
    ADD 1, %MW5        // Increment flash timer
    RET

// Flash Blue button
Flash_Blue:
    SET %DO1           // Turn on Blue LED
    ADD 1, %MW5        // Increment flash timer
    RET

// Flash Red button
Flash_Red:
    SET %DO0           // Turn on Red LED
    ADD 1, %MW5        // Increment flash timer
    RET

// Check user input
Check_User_Input:
    // Button debounce
    [%MW8 > 50]        // 50ms debounce
        // Check for button presses
        [%DI1 = 1]     // Yellow pressed
            CALL Process_Input(1)
        [%DI3 = 1]     // Blue pressed
            CALL Process_Input(2)
        [%DI5 = 1]     // Red pressed
            CALL Process_Input(3)
        MOV 0, %MW8    // Reset debounce timer
    
    // Increment timers
    ADD 1, %MW7        // Input timer
    ADD 1, %MW8        // Debounce timer
    RET

// Process user input
Process_Input:
    // Get expected input for current step
    [%MW3 = 0]
        MOV %MW10, %MW23
    [%MW3 = 1]
        MOV %MW11, %MW23
    [%MW3 = 2]
        MOV %MW12, %MW23
    [%MW3 = 3]
        MOV %MW13, %MW23
    [%MW3 = 4]
        MOV %MW14, %MW23
    [%MW3 = 5]
        MOV %MW15, %MW23
    [%MW3 = 6]
        MOV %MW16, %MW23
    [%MW3 = 7]
        MOV %MW17, %MW23
    [%MW3 = 8]
        MOV %MW18, %MW23
    [%MW3 = 9]
        MOV %MW19, %MW23
    
    // Check if input matches expected
    [%MW23 = %MW23]    // This needs to be fixed - compare with actual input
        ADD 1, %MW3    // Move to next input step
        MOV 0, %MW7    // Reset input timer
        // Check if sequence complete
        [%MW3 >= %MW1]
            ADD 1, %MW4    // Increment score
            MOV 1, %MW0    // Move to Ready state for next sequence
    [%MW23 <> %MW23]   // Input doesn't match
        MOV 4, %MW0    // Move to Game_Over state
    
    RET

// Game over flash sequence
Game_Over_Flash:
    // Flash all buttons 3 times
    [%MW5 < 1500]      // 3 flashes * 500ms each
        [%MW5 < 500]
            SET %DO0   // Red LED
            SET %DO1   // Blue LED
            SET %DO2   // Yellow LED
        [%MW5 >= 500]
            CLR %DO0   // Turn off all LEDs
            CLR %DO1
            CLR %DO2
        ADD 1, %MW5
    [%MW5 >= 1500]
        MOV 0, %MW5    // Reset timer
    RET

// =============================================================================
// END OF PROGRAM
// =============================================================================