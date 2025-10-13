# Reaction Game Refactoring Summary

## Problem
The original code had significant duplication for checking button presses (Yellow, Blue, and Red). Each button required ~30 lines of nearly identical code to:
- Check if the button was pressed
- Verify if it matched the current LED
- Handle correct response (increment score, generate next gap)
- Handle incorrect response (game over, update high score)

This resulted in ~90 lines of repetitive code.

## Solution
Created a **Function Block** (`FB_CheckButtonPress`) that encapsulates the button-checking logic.

### FB_CheckButtonPress
**Inputs:**
- `ButtonPressed`: Whether this button's trigger fired
- `ExpectedLED`: Which LED number this button should match (1=Yellow, 2=Blue, 3=Red)
- `CurrentLED`: The LED that's actually lit
- `Score` & `HighScore`: Current game scores

**Outputs:**
- `IsCorrect` / `IsWrong`: Flags indicating the result
- `NewScore` / `NewHighScore`: Updated scores
- `NextGapTime`: Randomly generated gap time for the next round
- `EndGame` / `ContinueGame`: Signals for game flow control

## Refactored Code Structure

### Before (for each button):
```
IF Trig_Y.Q THEN
    IF CurrentLED = 1 THEN
        // Correct - 15 lines of code
    ELSE
        // Wrong - 15 lines of code
    END_IF;
END_IF;
```
**×3 buttons = ~90 lines**

### After (all buttons):
```
// Call function blocks (3 lines each = 9 lines)
CheckYellow(ButtonPressed := Trig_Y.Q, ExpectedLED := 1, ...);
CheckBlue(ButtonPressed := Trig_B.Q, ExpectedLED := 2, ...);
CheckRed(ButtonPressed := Trig_R.Q, ExpectedLED := 3, ...);

// Handle correct press (unified, ~10 lines)
IF CheckYellow.ContinueGame OR CheckBlue.ContinueGame OR CheckRed.ContinueGame THEN
    // Handle continue logic
END_IF;

// Handle wrong press (unified, ~10 lines)
IF CheckYellow.EndGame OR CheckBlue.EndGame OR CheckRed.EndGame THEN
    // Handle game over logic
END_IF;
```
**Total: ~35 lines**

## Benefits
1. **Code Reduction**: ~90 lines → ~35 lines (60% reduction)
2. **Maintainability**: Changes to button logic only need to be made once
3. **Readability**: Main logic is clearer and more organized
4. **Consistency**: All buttons guaranteed to behave identically
5. **Testability**: Button logic can be tested independently

## Files Created
1. `FB_CheckButtonPress.st` - The function block
2. `MAIN_ReactionGame_Refactored.st` - Refactored main program

## Usage
Replace your existing button-checking code (Yellow/Blue/Red sections) with the refactored version shown in `MAIN_ReactionGame_Refactored.st`.

**Note:** You may need to adjust the `Rand_Gen` function block reference in `FB_CheckButtonPress.st` to match your actual random number generator implementation.
