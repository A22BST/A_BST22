# Phase 2 & 3 Expansion Guide
## Adding 4th Button and Difficulty Control

---

## Phase 2: Adding the White Button (4-Button Mode)

### Overview
Phase 2 adds a 4th button (White) and mode selection between 3-button and 4-button gameplay.

---

### Hardware Additions

**New Components:**
1. **1 × Standard Illuminated Pushbutton (White)**
   - Not a hybrid pilot light (no built-in contact)
   - Separate 1NO contact + LED indicator
   - M12 connector or similar

**Wiring for White Button:**

| Pin | Wire Color | Function | Connects To |
|-----|-----------|----------|-------------|
| 1   | Brown     | Contact COM | +24V terminal |
| 4   | Black     | Contact IN | DI7 (NX-ID4442) |
| 2   | White     | LED + | DO3 (NX-OD4256) |
| 3   | Blue      | LED – | 0V terminal |

**Mode Selector (3-position):**
- **Left Position:** 4-button mode → DI11
- **Middle Position:** OFF/Idle (neither input active)
- **Right Position:** 3-button mode → DI12

---

### Variable Additions

Add to `GVL_IO_MAPPING`:
```iecst
(* NEW INPUTS *)
diButtonWhite       AT %IX0.7  : BOOL;  (* White button contact - DI7 *)
diMode3Button       AT %IX0.11 : BOOL;  (* 3-button mode selector *)
diMode4Button       AT %IX0.12 : BOOL;  (* 4-button mode selector *)

(* NEW OUTPUTS *)
doLedWhite          AT %QX0.3  : BOOL;  (* White LED - DO3 *)
```

Add to `GVL_GameState`:
```iecst
(* Mode Selection *)
bButtonW_Pressed    : BOOL := FALSE;    (* White button rising edge *)
bButtonW_Last       : BOOL := FALSE;    (* Previous scan state *)
iNumButtonsActive   : INT := 3;         (* Current mode: 3 or 4 buttons *)
bMode3Selected      : BOOL := FALSE;    (* 3-button mode active *)
bMode4Selected      : BOOL := FALSE;    (* 4-button mode active *)
```

Update `GVL_Constants`:
```iecst
BTN_WHITE           : INT := 4;         (* White button code *)
MAX_BUTTONS         : INT := 4;         (* Maximum in Phase 2 *)
```

---

### Ladder Logic Changes

#### Section 1: Edge Detection (Add these rungs)

**Rung 018: Detect rising edge on White button**
```ladder
──┤diButtonWhite├──┤/bButtonW_Last├──( bButtonW_Pressed )──
```

**Rung 019: Store White button state**
```ladder
──┤diButtonWhite├──( bButtonW_Last )──
```

---

#### Section 2: Mode Selection (New section before IDLE)

**Rung 008: Read 3-button mode selector**
```ladder
──┤diMode3Button├──( bMode3Selected )──
                   [MOV 3 iNumButtonsActive]
```

**Rung 009: Read 4-button mode selector**
```ladder
──┤diMode4Button├──( bMode4Selected )──
                   [MOV 4 iNumButtonsActive]
```

**Rung 010: Default to 3-button if neither selected**
```ladder
──┤/bMode3Selected├──┤/bMode4Selected├──[MOV 3 iNumButtonsActive]──
```

---

#### Section 3: Modified Random Generation (Update Rung 030)

**Original (Phase 1):**
```
iCurrentButton := (iRandomSeed MOD 3) + 1;
```

**Updated (Phase 2):**
```ladder
──┤iGameState = STATE_PLAYBACK├──┤iPlaybackIndex = 0├──┤/bPlaybackActive├──[COMPUTE]──

COMPUTE block:
  iRandomSeed := (iRandomSeed * RNG_MULTIPLIER + RNG_INCREMENT) MOD RNG_MODULUS;
  iCurrentButton := (iRandomSeed MOD iNumButtonsActive) + 1;  (* Now uses mode setting *)
  aiSequence[iSequenceLength] := iCurrentButton;
  iSequenceLength := iSequenceLength + 1;
  bPlaybackActive := TRUE;
```

**Key Change:** `MOD iNumButtonsActive` instead of `MOD 3`

---

#### Section 4: White Button Input Capture (Add to WAIT_INPUT)

**Rung 053: Capture White button press**
```ladder
──┤iGameState = STATE_WAIT_INPUT├──┤bButtonW_Pressed├──┤iPlayerInput = 0├──
  [MOV BTN_WHITE iPlayerInput]──
```

---

#### Section 5: White LED Control (Add to LED section)

**Rung 088: White LED during PLAYBACK**
```ladder
──┤iGameState = STATE_PLAYBACK├──┤bFlashOn├──┤iCurrentButton = BTN_WHITE├──
  ( doLedWhite )──
```

**Rung 089: White LED feedback during WAIT_INPUT**
```ladder
──┤iGameState = STATE_WAIT_INPUT├──┤diButtonWhite├──( doLedWhite )──
```

**Rung 090: White LED flash during GAME_OVER**
```ladder
──┤iGameState = STATE_GAME_OVER├──┤CLOCK_500ms├──( doLedWhite )──
```

---

#### Section 6: Mode Indication (Optional - shows selected mode)

**Rung 095: Indicate 3-button mode in IDLE**
```ladder
(* Flash Yellow+Blue in IDLE when 3-button mode selected *)
──┤iGameState = STATE_IDLE├──┤bMode3Selected├──┤CLOCK_1000ms├──
  ( doLedYellow )
  ( doLedBlue )
```

**Rung 096: Indicate 4-button mode in IDLE**
```ladder
(* Flash all 4 LEDs in IDLE when 4-button mode selected *)
──┤iGameState = STATE_IDLE├──┤bMode4Selected├──┤CLOCK_1000ms├──
  ( doLedYellow )
  ( doLedBlue )
  ( doLedRed )
  ( doLedWhite )
```

---

### Testing Phase 2

**Test Procedure:**

1. **3-Button Mode Test:**
   - Set selector to right position (3-button)
   - Verify `iNumButtonsActive = 3`
   - Start game
   - Verify only buttons 1-3 (Y, B, R) appear in sequence
   - White button should never flash

2. **4-Button Mode Test:**
   - Set selector to left position (4-button)
   - Verify `iNumButtonsActive = 4`
   - Start game
   - Verify all buttons 1-4 (Y, B, R, W) can appear
   - White button should occasionally flash

3. **Mode Switching:**
   - Start game in 3-button mode
   - Play a few rounds
   - Switch to 4-button mode
   - Start new game
   - Verify mode change takes effect

4. **White Button Response:**
   - In 4-button mode, wait for White to flash
   - Press White button
   - Verify LED lights up
   - Verify input registers correctly

---

## Phase 3: Difficulty Control (8-Position Selector)

### Overview
Phase 3 adds an 8-position rotary selector to adjust game difficulty by changing timing parameters.

---

### Hardware Additions

**New Component:**
1. **8-Position Rotary Selector Switch**
   - Binary encoded output (3 bits = 8 positions)
   - Positions 0-7
   - 3 output terminals (Bit 0, Bit 1, Bit 2)

**Wiring for Difficulty Selector:**

| Position | Binary | Bit2 (DI22) | Bit1 (DI21) | Bit0 (DI20) |
|----------|--------|-------------|-------------|-------------|
| 0        | 000    | 0           | 0           | 0           |
| 1        | 001    | 0           | 0           | 1           |
| 2        | 010    | 0           | 1           | 0           |
| 3        | 011    | 0           | 1           | 1           |
| 4        | 100    | 1           | 0           | 0           |
| 5        | 101    | 1           | 0           | 1           |
| 6        | 110    | 1           | 1           | 0           |
| 7        | 111    | 1           | 1           | 1           |

**Connections:**
- Bit 0 → DI20
- Bit 1 → DI21
- Bit 2 → DI22
- Common → 0V or +24V (depending on switch type)

---

### Variable Additions

Add to `GVL_IO_MAPPING`:
```iecst
(* DIFFICULTY SELECTOR - Binary Encoded *)
diDiffBit0          AT %IX0.20 : BOOL;  (* LSB - Position bit 0 *)
diDiffBit1          AT %IX0.21 : BOOL;  (* Position bit 1 *)
diDiffBit2          AT %IX0.22 : BOOL;  (* MSB - Position bit 2 *)
```

Add to `GVL_GameState`:
```iecst
(* Difficulty Control *)
iDifficultyLevel    : INT := 1;         (* 0-7 difficulty setting *)
```

Add to `GVL_Timers`:
```iecst
(* Difficulty-Adjusted Timers *)
tFlashTimeAdjusted      : TIME;         (* Calculated flash time *)
tGapTimeAdjusted        : TIME;         (* Calculated gap time *)
tInputTimeoutAdjusted   : TIME;         (* Calculated input timeout *)
```

Add to `GVL_Constants`:
```iecst
(* Difficulty Presets - Flash Time (ms) *)
FLASH_TIME_DIFF0    : INT := 800;       (* Very Easy *)
FLASH_TIME_DIFF1    : INT := 600;       (* Easy *)
FLASH_TIME_DIFF2    : INT := 500;       (* Normal *)
FLASH_TIME_DIFF3    : INT := 400;       (* Medium *)
FLASH_TIME_DIFF4    : INT := 350;       (* Hard *)
FLASH_TIME_DIFF5    : INT := 300;       (* Very Hard *)
FLASH_TIME_DIFF6    : INT := 250;       (* Expert *)
FLASH_TIME_DIFF7    : INT := 200;       (* Master *)

(* Difficulty Presets - Input Timeout (ms) *)
TIMEOUT_DIFF0       : INT := 6000;      (* Very Easy *)
TIMEOUT_DIFF1       : INT := 5000;      (* Easy *)
TIMEOUT_DIFF2       : INT := 4000;      (* Normal *)
TIMEOUT_DIFF3       : INT := 3000;      (* Medium *)
TIMEOUT_DIFF4       : INT := 2500;      (* Hard *)
TIMEOUT_DIFF5       : INT := 2000;      (* Very Hard *)
TIMEOUT_DIFF6       : INT := 1500;      (* Expert *)
TIMEOUT_DIFF7       : INT := 1000;      (* Master *)

(* Gap time scales with flash time *)
GAP_RATIO           : REAL := 0.4;      (* Gap = 40% of flash time *)
```

---

### Ladder Logic for Difficulty

#### Section 1: Read Difficulty Selector

**Rung 005: Decode binary selector to integer**
```ladder
──[COMPUTE iDifficultyLevel]──

COMPUTE block:
  (* Convert 3-bit binary to decimal 0-7 *)
  iDifficultyLevel := 0;
  IF diDiffBit0 THEN iDifficultyLevel := iDifficultyLevel + 1; END_IF;
  IF diDiffBit1 THEN iDifficultyLevel := iDifficultyLevel + 2; END_IF;
  IF diDiffBit2 THEN iDifficultyLevel := iDifficultyLevel + 4; END_IF;
```

**Alternative using bit manipulation (more efficient):**
```ladder
──[COMPUTE]──
  iDifficultyLevel := (BOOL_TO_INT(diDiffBit2) * 4) + 
                      (BOOL_TO_INT(diDiffBit1) * 2) + 
                      (BOOL_TO_INT(diDiffBit0) * 1);
```

---

#### Section 2: Apply Difficulty Settings

**Rung 006: Set timing based on difficulty (Method 1: CASE Statement)**

```structured_text
CASE iDifficultyLevel OF
    0:  (* Very Easy *)
        tFlashTimeAdjusted := T#800ms;
        tInputTimeoutAdjusted := T#6000ms;
    1:  (* Easy *)
        tFlashTimeAdjusted := T#600ms;
        tInputTimeoutAdjusted := T#5000ms;
    2:  (* Normal *)
        tFlashTimeAdjusted := T#500ms;
        tInputTimeoutAdjusted := T#4000ms;
    3:  (* Medium *)
        tFlashTimeAdjusted := T#400ms;
        tInputTimeoutAdjusted := T#3000ms;
    4:  (* Hard *)
        tFlashTimeAdjusted := T#350ms;
        tInputTimeoutAdjusted := T#2500ms;
    5:  (* Very Hard *)
        tFlashTimeAdjusted := T#300ms;
        tInputTimeoutAdjusted := T#2000ms;
    6:  (* Expert *)
        tFlashTimeAdjusted := T#250ms;
        tInputTimeoutAdjusted := T#1500ms;
    7:  (* Master *)
        tFlashTimeAdjusted := T#200ms;
        tInputTimeoutAdjusted := T#1000ms;
ELSE
    (* Default to Normal if invalid *)
    tFlashTimeAdjusted := T#500ms;
    tInputTimeoutAdjusted := T#4000ms;
END_CASE;

(* Calculate gap time as percentage of flash time *)
tGapTimeAdjusted := TIME#(REAL_TO_INT(TIME_TO_REAL(tFlashTimeAdjusted) * GAP_RATIO));
```

**Rung 007: Alternative - Array Lookup (More Compact)**

```structured_text
VAR_GLOBAL CONSTANT
    (* Lookup tables *)
    aiFlashTimes : ARRAY[0..7] OF INT := [800, 600, 500, 400, 350, 300, 250, 200];
    aiTimeouts   : ARRAY[0..7] OF INT := [6000, 5000, 4000, 3000, 2500, 2000, 1500, 1000];
END_VAR

(* In main program: *)
──[COMPUTE]──
  (* Bounds check *)
  IF iDifficultyLevel < 0 OR iDifficultyLevel > 7 THEN
      iDifficultyLevel := 2;  (* Default to Normal *)
  END_IF;
  
  (* Lookup and apply *)
  tFlashTimeAdjusted := INT_TO_TIME(aiFlashTimes[iDifficultyLevel]);
  tInputTimeoutAdjusted := INT_TO_TIME(aiTimeouts[iDifficultyLevel]);
  tGapTimeAdjusted := INT_TO_TIME(aiFlashTimes[iDifficultyLevel] * 40 / 100);
```

---

#### Section 3: Update Timer Calls

**Modify all timer calls to use adjusted values:**

**OLD (Phase 1):**
```ladder
[TON tFlashTimer PT:=tFlashTime]
```

**NEW (Phase 3):**
```ladder
[TON tFlashTimer PT:=tFlashTimeAdjusted]
```

**Apply to:**
- Rung 032: Flash timer (use `tFlashTimeAdjusted`)
- Rung 034: Gap timer (use `tGapTimeAdjusted`)
- Rung 036: Input timeout (use `tInputTimeoutAdjusted`)

---

### Advanced Difficulty Features

#### Progressive Difficulty (Increases With Level)

Add this calculation at the start of each new level:

**Rung 058 Enhancement:**
```structured_text
(* After iLevel increment *)
[COMPUTE]
  (* Base difficulty from selector *)
  iBaseDifficulty := iDifficultyLevel;
  
  (* Reduce timeout by 5% per level, minimum 20% of base *)
  rTimeoutMultiplier := MAX(0.2, 1.0 - (REAL(iLevel - 1) * 0.05));
  tInputTimeoutAdjusted := INT_TO_TIME(
      REAL_TO_INT(TIME_TO_REAL(tInputTimeoutAdjusted) * rTimeoutMultiplier)
  );
  
  (* Reduce flash time by 3% per level, minimum 40% of base *)
  rFlashMultiplier := MAX(0.4, 1.0 - (REAL(iLevel - 1) * 0.03));
  tFlashTimeAdjusted := INT_TO_TIME(
      REAL_TO_INT(TIME_TO_REAL(tFlashTimeAdjusted) * rFlashMultiplier)
  );
```

---

#### Difficulty Display (LED Indicator)

**Use LEDs to show selected difficulty at startup:**

```ladder
(* In IDLE state, flash LEDs to indicate difficulty *)
──┤iGameState = STATE_IDLE├──┤CLOCK_500ms├──[COMPUTE]──

COMPUTE:
  (* Light up 1-4 LEDs based on difficulty bracket *)
  IF iDifficultyLevel >= 0 AND iDifficultyLevel <= 1 THEN
      (* Easy: 1 LED *)
      doLedYellow := TRUE;
  ELSIF iDifficultyLevel >= 2 AND iDifficultyLevel <= 3 THEN
      (* Normal: 2 LEDs *)
      doLedYellow := TRUE;
      doLedBlue := TRUE;
  ELSIF iDifficultyLevel >= 4 AND iDifficultyLevel <= 5 THEN
      (* Hard: 3 LEDs *)
      doLedYellow := TRUE;
      doLedBlue := TRUE;
      doLedRed := TRUE;
  ELSE
      (* Expert/Master: All 4 LEDs *)
      doLedYellow := TRUE;
      doLedBlue := TRUE;
      doLedRed := TRUE;
      doLedWhite := TRUE;
  END_IF;
```

---

### Testing Phase 3

**Test Matrix:**

| Difficulty | Position | Flash (ms) | Timeout (ms) | Expected |
|------------|----------|------------|--------------|----------|
| Very Easy  | 0        | 800        | 6000         | Very slow, lots of time |
| Easy       | 1        | 600        | 5000         | Slow, generous time |
| Normal     | 2        | 500        | 4000         | Moderate pace |
| Medium     | 3        | 400        | 3000         | Slightly faster |
| Hard       | 4        | 350        | 2500         | Noticeably harder |
| Very Hard  | 5        | 300        | 2000         | Fast pace |
| Expert     | 6        | 250        | 1500         | Very fast |
| Master     | 7        | 200        | 1000         | Extremely challenging |

**Test Procedure:**

1. **For Each Difficulty Level:**
   - Set rotary selector to position
   - Watch `iDifficultyLevel` variable (should match position)
   - Start game
   - Observe flash speed
   - Note how much time you have to respond
   - Verify timeout occurs at expected time

2. **Verify Binary Decoding:**
   - Position 0: All inputs OFF → `iDifficultyLevel = 0`
   - Position 1: Bit0 ON → `iDifficultyLevel = 1`
   - Position 7: All inputs ON → `iDifficultyLevel = 7`

3. **Test Progressive Difficulty (if implemented):**
   - Set to Normal (position 2)
   - Play to Level 5
   - Note: timeout should get slightly shorter each level
   - Flash speed should also decrease

---

## Combined Phase 2 & 3 Testing

**Full System Test:**

1. **Setup:**
   - All 4 buttons wired and tested
   - Mode selector in 4-button position
   - Difficulty selector at position 2 (Normal)

2. **Gameplay Test:**
   - Start game
   - Play through 10 levels
   - Verify all 4 buttons appear randomly
   - Note timing feels appropriate

3. **Mode Change Test:**
   - Mid-game, switch to 3-button mode
   - Finish current game
   - Start new game
   - Verify only 3 buttons now appear

4. **Difficulty Ramp Test:**
   - Set difficulty to 0 (Very Easy)
   - Play until comfortable
   - Increase by 1 position
   - Repeat until challenging
   - Find your optimal difficulty

---

## Full Variable List (All Phases)

```iecst
===============================================================================
COMPLETE VARIABLE DEFINITIONS - PHASES 1, 2, 3
===============================================================================

VAR_GLOBAL
    (* === INPUTS === *)
    (* Button Inputs *)
    diButtonYellow      AT %IX0.1  : BOOL;
    diButtonBlue        AT %IX0.3  : BOOL;
    diButtonRed         AT %IX0.5  : BOOL;
    diButtonWhite       AT %IX0.7  : BOOL;  (* Phase 2 *)
    diStartButton       AT %IX0.10 : BOOL;
    
    (* Mode Selection - Phase 2 *)
    diMode3Button       AT %IX0.11 : BOOL;
    diMode4Button       AT %IX0.12 : BOOL;
    
    (* Difficulty Selection - Phase 3 *)
    diDiffBit0          AT %IX0.20 : BOOL;
    diDiffBit1          AT %IX0.21 : BOOL;
    diDiffBit2          AT %IX0.22 : BOOL;
    
    (* === OUTPUTS === *)
    doLedRed            AT %QX0.0  : BOOL;
    doLedBlue           AT %QX0.1  : BOOL;
    doLedYellow         AT %QX0.2  : BOOL;
    doLedWhite          AT %QX0.3  : BOOL;  (* Phase 2 *)
    
    (* === GAME STATE === *)
    iGameState          : INT := 0;
    bGameActive         : BOOL := FALSE;
    iLevel              : INT := 1;
    iSequenceLength     : INT := 0;
    iPlaybackIndex      : INT := 0;
    iInputIndex         : INT := 0;
    aiSequence          : ARRAY[0..99] OF INT;
    iCurrentButton      : INT := 0;
    iPlayerInput        : INT := 0;
    iRandomSeed         : DINT := 12345;
    
    (* === EDGE DETECTION === *)
    bButtonY_Pressed    : BOOL := FALSE;
    bButtonB_Pressed    : BOOL := FALSE;
    bButtonR_Pressed    : BOOL := FALSE;
    bButtonW_Pressed    : BOOL := FALSE;  (* Phase 2 *)
    bStartPressed       : BOOL := FALSE;
    bButtonY_Last       : BOOL := FALSE;
    bButtonB_Last       : BOOL := FALSE;
    bButtonR_Last       : BOOL := FALSE;
    bButtonW_Last       : BOOL := FALSE;  (* Phase 2 *)
    bStart_Last         : BOOL := FALSE;
    
    (* === FLAGS === *)
    bPlaybackActive     : BOOL := FALSE;
    bFlashOn            : BOOL := FALSE;
    bGameOver           : BOOL := FALSE;
    bSequenceComplete   : BOOL := FALSE;
    
    (* === MODE CONTROL - Phase 2 === *)
    iNumButtonsActive   : INT := 3;
    bMode3Selected      : BOOL := FALSE;
    bMode4Selected      : BOOL := FALSE;
    
    (* === DIFFICULTY - Phase 3 === *)
    iDifficultyLevel    : INT := 2;
    
    (* === TIMERS === *)
    tFlashTimer         : TON;
    tGapTimer           : TON;
    tInputTimeout       : TON;
    tGameOverTimer      : TON;
    
    (* === TIMING VALUES === *)
    tFlashTimeAdjusted      : TIME := T#500ms;
    tGapTimeAdjusted        : TIME := T#200ms;
    tInputTimeoutAdjusted   : TIME := T#4000ms;
    tGameOverTime           : TIME := T#3000ms;
END_VAR
```

---

## Migration Path

### From Phase 1 to Phase 2:
1. Add White button hardware
2. Add mode selector hardware
3. Add new variables
4. Add/modify rungs as documented
5. Test 3-button mode (should work like Phase 1)
6. Test 4-button mode
7. Verify mode switching

### From Phase 2 to Phase 3:
1. Add difficulty selector hardware
2. Add difficulty variables
3. Add difficulty decode logic
4. Add timing adjustment logic
5. Update all timer calls
6. Test at each difficulty level
7. Fine-tune timing values

### All at Once:
- Wire all hardware first
- Load complete variable list
- Implement all ladder rungs
- Test systematically through each phase

---

## Troubleshooting Phase 2 & 3

### White Button Issues
- **Not registering:** Check DI7 wiring
- **LED not lighting:** Check DO3 wiring and polarity
- **Never appears in sequence:** Verify `iNumButtonsActive = 4`

### Mode Selection Issues
- **Mode not changing:** Check DI11/DI12 inputs
- **Wrong number of buttons:** Monitor `iNumButtonsActive`
- **Mode switches mid-game:** Add logic to lock mode during gameplay

### Difficulty Selection Issues
- **Wrong difficulty:** Check binary decoding logic
- **Stuck on one difficulty:** Verify DI20-22 wiring
- **Timing doesn't change:** Confirm adjusted timer values are used

---

## Performance Optimizations

### Memory Optimization
```iecst
(* Use smaller data types where possible *)
iDifficultyLevel    : USINT;   (* 0-255, only need 0-7 *)
iNumButtonsActive   : USINT;   (* 0-255, only need 3-4 *)
```

### Scan Time Optimization
```ladder
(* Skip difficulty calculation if not in IDLE state *)
──┤iGameState = STATE_IDLE├──[Calculate Difficulty]──
```

---

**Congratulations! You now have a complete, production-ready Simon Says game with multiple difficulty levels and modes.**

---

Document Version: 1.0  
Last Updated: October 1, 2025  
Project: Simon Says - Phase 2 & 3 Implementation
