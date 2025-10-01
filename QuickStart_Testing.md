# Simon Says - Quick Start Testing Guide

## Pre-Test Checklist
- [ ] All buttons wired according to wiring table
- [ ] 24V power supply connected and ON
- [ ] PLC powered and connected to PC
- [ ] Sysmac Studio connected to PLC
- [ ] Program downloaded to PLC
- [ ] PLC in RUN mode

## Quick Function Test

### 1. LED Test (Manual)
In Sysmac Studio online mode, force outputs:
```
DO_RedLED = TRUE     → Red button should light
DO_BlueLED = TRUE    → Blue button should light  
DO_YellowLED = TRUE  → Yellow button should light
```

### 2. Button Input Test
Monitor these variables while pressing buttons:
```
Press Yellow → DI_YellowButton should go TRUE
Press Blue   → DI_BlueButton should go TRUE
Press Red    → DI_RedButton should go TRUE
```

## Game Testing Sequence

### Test 1: Basic Game Start
1. Set `StartButton = TRUE` in watch window
2. Observe: One LED should flash (random)
3. Press the same button
4. Observe: Sequence extends to 2 LEDs

### Test 2: Wrong Input
1. Start new game
2. When LED flashes, press different button
3. Observe: Red LED should flash 3 times (game over)

### Test 3: Timeout Test  
1. Start new game
2. When LED flashes, wait 3+ seconds
3. Observe: Game should end (timeout)

### Test 4: Full Sequence
1. Start game
2. Follow sequence correctly
3. Try to reach level 5
4. Verify each level adds one button

## Monitoring Variables

### Key Variables to Watch
| Variable | Expected Values | Notes |
|----------|----------------|-------|
| CurrentState | 0-4 | Game state machine |
| CurrentLevel | 0-10 | Current sequence length |
| GameActive | TRUE/FALSE | Game running status |
| Sequence[0..9] | 1-3 | 1=Yellow, 2=Blue, 3=Red |

### State Values
- 0 = Idle (waiting for start)
- 1 = Showing sequence
- 2 = Waiting for player input
- 3 = Game won
- 4 = Game lost

## Common Issues & Solutions

### Issue: Game won't start
**Solution:** 
- Ensure `StartButton` is pulsed (FALSE→TRUE→FALSE)
- Check `GameActive` variable
- Verify PLC is in RUN mode

### Issue: Buttons don't respond
**Solution:**
- Check DI_*Button variables change when pressed
- Verify wiring (Pin 1 to +24V, Pin 4 to DI)
- Check input module configuration

### Issue: LEDs don't light during game
**Solution:**
- Test manual LED control first
- Check DO_*LED variables during game
- Verify wiring (Pin 2 to DO, Pin 3 to 0V)

### Issue: Random sequence seems fixed
**Solution:**
- RandomSeed should be incrementing
- Restart PLC to reset seed
- Sequence uses modulo 3 for 3 buttons

## Performance Checks
- Button response: Should be < 50ms
- LED timing: 500ms ON, 200ms gap
- Scan time: Should be < 10ms

## Advanced Testing

### Modify Game Parameters
Try changing these in watch window:
```
MaxLevel = 5        (Shorter game)
ShowTime = T#300MS  (Faster display)
GapTime = T#100MS   (Shorter gaps)
InputTimeout = T#5S (More time to respond)
```

### Sequence Verification
Monitor `Sequence` array to verify:
1. Each new level adds one element
2. Values are 1, 2, or 3 only
3. Pattern appears random

## Quick Reset
To reset game at any time:
1. Set `ResetButton = TRUE`
2. Or set `GameState = 0`
3. Or stop/start PLC

## Success Criteria
- [ ] All 3 LEDs can be controlled
- [ ] All 3 buttons register input
- [ ] Game starts on command
- [ ] Sequence displays correctly
- [ ] Correct input advances level
- [ ] Wrong input ends game
- [ ] Timeout works (3 seconds)
- [ ] Win condition at level 10
- [ ] Game resets properly