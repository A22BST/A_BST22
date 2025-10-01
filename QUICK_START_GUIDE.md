# Quick Start Guide - Simon Says Ladder Logic
## Get Up and Running in 30 Minutes

---

## Step 1: Open Sysmac Studio (5 min)

1. **Launch Sysmac Studio**
2. **Create New Project:**
   - File → New Project
   - Project Name: `SimonSays_Phase1`
   - Device: Select `NX102-1100` from the list
   - Click OK

3. **Configure Hardware:**
   - Open "Configuration and Setup" tab
   - Right-click on the CPU → Insert Unit
   - Add `NX-ID4442` (Digital Input Unit)
   - Add `NX-OD4256` (Digital Output Unit)
   - Save configuration

---

## Step 2: Create Variables (10 min)

1. **Open Global Variable List:**
   - Right-click "Global Variables" in project tree
   - Select "Insert Global Variable List"
   - Name it: `GVL_Main`

2. **Copy Variables from File:**
   - Open `sysmac_studio_variable_definitions.txt` (in this workspace)
   - Copy the entire contents of each GVL section
   - Paste into Sysmac Studio variable editor

3. **Important Variables to Verify:**
   ```
   GVL_IO_MAPPING:
   - diButtonYellow AT %IX0.1
   - diButtonBlue AT %IX0.3
   - diButtonRed AT %IX0.5
   - diStartButton AT %IX0.10
   - doLedRed AT %QX0.0
   - doLedBlue AT %QX0.1
   - doLedYellow AT %QX0.2
   ```

4. **Adjust I/O Addresses if Needed:**
   - Match your actual hardware configuration
   - Format: `%IX[slot].[channel]` for inputs
   - Format: `%QX[slot].[channel]` for outputs

---

## Step 3: Create Main Program (10 min)

1. **Create Ladder Program:**
   - Right-click "Programs" in project tree
   - Insert Program → Name: `PLC_PRG`
   - Language: **Ladder Diagram (LD)**

2. **Implement Rungs:**
   - Open `ladder_logic_detailed_rungs.txt`
   - Implement rungs section by section:
     - Section 1: Edge Detection (Rungs 010-019)
     - Section 2: IDLE State (Rungs 020-029)
     - Section 3: PLAYBACK State (Rungs 030-049)
     - Section 4: WAIT_INPUT State (Rungs 050-069)
     - Section 5: GAME_OVER State (Rungs 070-079)
     - Section 6: LED Output (Rungs 080-099)

3. **Use Sysmac Studio Tools:**
   - Drag contacts from toolbox: `[ ]` for NO contact
   - Drag coils for outputs: `( )` for output coil
   - Use function blocks: TON for timers
   - Use function calls: MOV, ADD, etc.

---

## Step 4: Build and Download (5 min)

1. **Build Project:**
   - Click "Build" button (or F7)
   - Check for errors in output window
   - Fix any syntax errors

2. **Connect to PLC:**
   - Connect programming cable to NX102
   - Click "Connect" button
   - Select communication path (usually EtherNet/IP or USB)

3. **Download Program:**
   - Click "Transfer to Controller" button
   - Select "Program"
   - Click OK to transfer
   - Wait for completion

4. **Set to RUN Mode:**
   - Click "RUN" button in Sysmac Studio
   - PLC should enter RUN mode
   - Green RUN LED on CPU should light up

---

## Step 5: Test the Game (5+ min)

### Initial Power-On Test

1. **Verify Inputs:**
   - Go to "Watch" tab in Sysmac Studio
   - Add variables to watch:
     - `diButtonYellow`
     - `diButtonBlue`
     - `diButtonRed`
     - `diStartButton`
   - Press each button and verify input changes to TRUE

2. **Verify Outputs:**
   - Add to watch window:
     - `doLedYellow`
     - `doLedBlue`
     - `doLedRed`
   - Force outputs ON/OFF manually to test LEDs
   - Verify each LED lights up correctly

### Game Flow Test

1. **Start Game:**
   - Watch `iGameState` variable (should be 0 = IDLE)
   - Press Start button
   - State should change to 1 (PLAYBACK)

2. **Observe Playback:**
   - Watch `iSequenceLength` (should increment to 1)
   - Watch `aiSequence[0]` (shows first button: 1, 2, or 3)
   - Corresponding LED should flash
   - State changes to 2 (WAIT_INPUT)

3. **Test Correct Input:**
   - Press the same button that flashed
   - LED should light while pressed
   - If correct: next level starts (back to PLAYBACK)
   - Watch `iLevel` increment

4. **Test Wrong Input:**
   - Deliberately press wrong button
   - State should go to 3 (GAME_OVER)
   - All LEDs flash together
   - After 3 seconds, return to IDLE

5. **Test Timeout:**
   - Start game, wait for sequence
   - Don't press any button for 3 seconds
   - Should trigger GAME_OVER

---

## Troubleshooting Common Issues

### Issue: Buttons Don't Register

**Symptom:** Pressing button doesn't change input variable

**Solutions:**
1. Check wiring:
   - Pin 1 (Brown) → +24V terminal
   - Pin 4 (Black) → PLC input terminal
   - Common 0V connected
2. Verify I/O address in variable AT clause
3. Check input filter settings in I/O configuration
4. Test with multimeter: should read 24V when pressed

---

### Issue: LEDs Don't Light Up

**Symptom:** Output variable is TRUE but LED doesn't turn on

**Solutions:**
1. Check wiring:
   - Pin 2 (White) → PLC output terminal
   - Pin 3 (Blue) → 0V terminal
2. Verify output address in variable AT clause
3. Check LED polarity (White=+, Blue=-)
4. Verify output module has 24V supply
5. Test LED with external 24V source

---

### Issue: Random Sequence Not Working

**Symptom:** Same sequence every time or no sequence

**Solutions:**
1. Check `iRandomSeed` initialization
2. Verify random calculation in Rung 030:
   ```
   iRandomSeed := (iRandomSeed * 214013 + 2531011) MOD 65536;
   iCurrentButton := (iRandomSeed MOD 3) + 1;
   ```
3. Watch `aiSequence[]` array values
4. Try different seed value: `iRandomSeed := 54321`

---

### Issue: Game State Stuck

**Symptom:** Game doesn't progress through states

**Solutions:**
1. Watch `iGameState` variable
2. Check transition conditions:
   - IDLE→PLAYBACK: `bStartPressed` edge detection working?
   - PLAYBACK→WAIT_INPUT: `iPlaybackIndex >= iSequenceLength`?
   - WAIT_INPUT→PLAYBACK: `iInputIndex >= iSequenceLength`?
3. Verify edge detection rungs (010-017)
4. Check timer done bits: `.DN`

---

### Issue: Timers Not Working

**Symptom:** LED flashes too fast/slow or not at all

**Solutions:**
1. Verify TON function block calls
2. Check preset values:
   - `tFlashTime := T#500ms` (500 milliseconds)
   - `tGapTime := T#200ms`
3. Monitor timer variables:
   - `tFlashTimer.Q` (output)
   - `tFlashTimer.ET` (elapsed time)
   - `tFlashTimer.DN` (done bit)
4. Ensure timer reset logic works

---

## Monitoring Variables in Real-Time

### Watch Window Setup

Add these key variables to watch during testing:

**State Monitoring:**
- `iGameState` (0=IDLE, 1=PLAYBACK, 2=WAIT_INPUT, 3=GAME_OVER)
- `bGameActive` (TRUE when playing)
- `iLevel` (current level number)

**Sequence Monitoring:**
- `iSequenceLength` (how many steps)
- `aiSequence[0]` through `aiSequence[9]` (first 10 steps)
- `iPlaybackIndex` (current position in playback)
- `iInputIndex` (current position in player input)

**Button Monitoring:**
- `diButtonYellow`, `diButtonBlue`, `diButtonRed` (raw inputs)
- `bButtonY_Pressed`, `bButtonB_Pressed`, `bButtonR_Pressed` (edge detected)
- `iPlayerInput` (which button player pressed: 1=Y, 2=B, 3=R)
- `iCurrentButton` (which button being shown: 1=Y, 2=B, 3=R)

**Timer Monitoring:**
- `tFlashTimer.ET` (how long LED has been on)
- `tGapTimer.ET` (how long gap has been)
- `tInputTimeout.ET` (how long player has been thinking)
- `tGameOverTimer.ET` (game over countdown)

**LED Output:**
- `doLedYellow`, `doLedBlue`, `doLedRed` (output states)

---

## Wiring Verification Checklist

### Power Distribution
- [ ] 24V DC supply connected to terminal block
- [ ] 0V (GND) connected to terminal block
- [ ] PLC power supply unit energized
- [ ] All modules show power indicator LEDs

### Yellow Button (RAFI RAMO 22 T)
- [ ] Pin 1 (Brown) → +24V terminal
- [ ] Pin 2 (White) → DO2 (NX-OD4256, channel 2)
- [ ] Pin 3 (Blue) → 0V terminal
- [ ] Pin 4 (Black) → DI1 (NX-ID4442, channel 1)

### Blue Button
- [ ] Pin 1 (Brown) → +24V terminal
- [ ] Pin 2 (White) → DO1 (NX-OD4256, channel 1)
- [ ] Pin 3 (Blue) → 0V terminal
- [ ] Pin 4 (Black) → DI3 (NX-ID4442, channel 3)

### Red Button
- [ ] Pin 1 (Brown) → +24V terminal
- [ ] Pin 2 (White) → DO0 (NX-OD4256, channel 0)
- [ ] Pin 3 (Blue) → 0V terminal
- [ ] Pin 4 (Black) → DI5 (NX-ID4442, channel 5)

### Start/Mode Selector
- [ ] Common → +24V terminal
- [ ] Output → DI10 (NX-ID4442, channel 10)

### Earth/Ground
- [ ] Protective earth (PE) bonded to DIN rail
- [ ] Yellow/Green wire to all metal enclosures
- [ ] PE terminal on power supply connected

---

## Performance Tuning

### Make Game Easier
```
In GVL_Timers, change:
tFlashTime := T#800ms          (slower LED flash)
tGapTime := T#400ms            (longer gap between LEDs)
tInputTimeoutVal := T#5000ms   (more time to respond)
```

### Make Game Harder
```
In GVL_Timers, change:
tFlashTime := T#300ms          (faster LED flash)
tGapTime := T#100ms            (shorter gap)
tInputTimeoutVal := T#2000ms   (less time to respond)
```

### Progressive Difficulty
Add to Rung 057 (after level increment):
```ladder
[COMPUTE]
  (* Reduce timeout by 100ms each level, minimum 1 second *)
  tInputTimeoutVal := MAX(T#1000ms, T#3000ms - TIME#(iLevel * 100));
```

---

## Next Steps: Phase 2 Expansion

Once Phase 1 works perfectly:

1. **Add 4th Button (White):**
   - Wire up white illuminated pushbutton
   - Add variables: `diButtonWhite`, `doLedWhite`
   - Duplicate button handling rungs

2. **Add Mode Selector (3-position):**
   - Wire 3-position selector switch
   - Add variables: `diMode3Button`, `diMode4Button`
   - Modify random generation based on mode

3. **Test Both Modes:**
   - Verify 3-button mode still works
   - Test 4-button mode with white button included

---

## Phase 3: Difficulty Selector

1. **Add 8-Position Selector:**
   - Wire rotary switch with binary encoding
   - Add variables: `diDiff0`, `diDiff1`, `diDiff2` (3 bits = 8 positions)

2. **Create Difficulty Lookup:**
   ```
   Position 0: Easy (slow)
   Position 1: Normal
   Position 2: Hard (fast)
   Position 3-7: Custom
   ```

3. **Apply Difficulty Settings:**
   - Read binary value from selector
   - Use CASE statement to set timer values
   - Apply before each level

---

## Resources

**Documents in this workspace:**
- `SIMON_SAYS_LADDER_LOGIC.md` - Complete design documentation
- `ladder_logic_detailed_rungs.txt` - Every rung explained
- `sysmac_studio_variable_definitions.txt` - Copy-paste variables

**Omron Manuals:**
- NX102-1100 Hardware Manual
- NX-Series Programming Manual
- Sysmac Studio Operation Manual

**IEC 61131-3 References:**
- Ladder Diagram (LD) programming guide
- Timer function blocks (TON, TOF, TP)
- Data types and variables

---

## Safety Reminder

⚠️ **Before Working on Electrical Connections:**
1. Turn OFF 24V DC power supply
2. Verify power is OFF with multimeter
3. Discharge any capacitors
4. Follow lockout/tagout procedures
5. Never work on live circuits

⚠️ **During Testing:**
1. Use proper eye protection
2. Keep hands away from moving parts
3. Ensure proper earth grounding
4. Have emergency stop readily accessible

---

## Support Checklist

If you're stuck, work through this checklist:

- [ ] Verified all wiring matches documentation
- [ ] Tested each button input individually
- [ ] Tested each LED output individually
- [ ] Confirmed PLC is in RUN mode
- [ ] Watched variables in online mode
- [ ] Checked for build errors
- [ ] Verified I/O addresses match hardware
- [ ] Reviewed edge detection logic
- [ ] Monitored state transitions
- [ ] Tested timers separately
- [ ] Read through troubleshooting section

---

**Good luck with your Simon Says project!**

*If you encounter issues not covered here, document the symptoms and check the detailed rung documentation for specific logic details.*

---

Document Version: 1.0  
Last Updated: October 1, 2025  
