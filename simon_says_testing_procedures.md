# Simon Says - Testing Procedures and Documentation

## Pre-Testing Setup

### Hardware Verification Checklist
- [ ] Power supply (24V DC, 2.5A) connected and operational
- [ ] NX102-1100 CPU powered and communicating
- [ ] NX-ID4442 input module installed and configured
- [ ] NX-OD4256 output module installed and configured
- [ ] All three buttons (Yellow, Blue, Red) wired correctly
- [ ] LED connections verified (DO0=Red, DO1=Blue, DO2=Yellow)
- [ ] Start button connected to DI7
- [ ] All protective earth connections in place

### Software Verification Checklist
- [ ] PLC program uploaded successfully
- [ ] I/O configuration matches hardware setup
- [ ] Variable declarations correct
- [ ] Timer presets configured properly

## Phase 1 Testing Procedures

### Test 1: Basic I/O Functionality
**Objective**: Verify all inputs and outputs are working correctly

**Steps**:
1. Power on the system
2. Press each button individually and verify:
   - Yellow button → DI1 activates, DO2 LED lights
   - Blue button → DI3 activates, DO1 LED lights  
   - Red button → DI5 activates, DO0 LED lights
3. Press Start button → DI7 activates

**Expected Results**:
- Each button press lights corresponding LED
- No cross-wiring or incorrect mappings
- LEDs turn off when button is released

**Pass Criteria**: All buttons and LEDs respond correctly

---

### Test 2: Game State Machine - IDLE to INIT
**Objective**: Verify game starts correctly

**Steps**:
1. Ensure system is in IDLE state (all LEDs off)
2. Press Start button (DI7)
3. Observe system behavior

**Expected Results**:
- System transitions from IDLE (State 0) to INIT (State 1)
- Status LED turns on
- System automatically progresses to SHOW_SEQUENCE (State 2)

**Pass Criteria**: Game starts and begins showing sequence

---

### Test 3: Sequence Display
**Objective**: Verify sequence is displayed correctly

**Steps**:
1. Start a new game
2. Observe the first sequence display
3. Count flash duration and gap timing
4. Verify only one LED flashes at a time

**Expected Results**:
- One LED flashes for 500ms
- 200ms gap between flashes
- Sequence displays completely before waiting for input
- Status LED remains on during sequence

**Pass Criteria**: Sequence displays with correct timing

---

### Test 4: Player Input - Correct Sequence
**Objective**: Verify correct input handling

**Steps**:
1. Start game and observe sequence (e.g., Red)
2. Press the correct button (Red) within timeout period
3. Observe system response

**Expected Results**:
- Button press lights corresponding LED immediately
- System advances to SUCCESS state
- All LEDs flash briefly (celebration)
- New sequence starts with length = 2

**Pass Criteria**: Correct input advances game to next level

---

### Test 5: Player Input - Incorrect Sequence
**Objective**: Verify incorrect input handling

**Steps**:
1. Start game and observe sequence (e.g., Red)
2. Press wrong button (e.g., Blue) within timeout
3. Observe system response

**Expected Results**:
- System enters GAME_OVER state
- All LEDs blink rapidly 3 times
- LEDs hold on for 2 seconds
- System returns to IDLE state

**Pass Criteria**: Wrong input triggers game over sequence

---

### Test 6: Input Timeout
**Objective**: Verify timeout handling

**Steps**:
1. Start game and observe sequence
2. Do not press any button
3. Wait for timeout (3 seconds)
4. Observe system response

**Expected Results**:
- After 3 seconds, system enters GAME_OVER state
- Error display sequence plays
- System returns to IDLE

**Pass Criteria**: Timeout triggers game over

---

### Test 7: Multi-Level Progression
**Objective**: Verify game progresses through multiple levels

**Steps**:
1. Start game and complete level 1 correctly
2. Observe level 2 sequence (should have 2 elements)
3. Complete level 2 correctly
4. Continue for several levels

**Expected Results**:
- Each level adds one more element to sequence
- Sequence elements are random
- Player must repeat entire sequence each level
- Game continues until mistake or level 20

**Pass Criteria**: Game progresses correctly through multiple levels

---

### Test 8: Maximum Level Handling
**Objective**: Verify behavior at maximum sequence length

**Steps**:
1. Modify code temporarily to start at level 18
2. Complete levels 18, 19, and 20
3. Observe behavior after level 20

**Expected Results**:
- Game allows up to level 20
- After completing level 20, game ends with success display
- System returns to IDLE state

**Pass Criteria**: Game handles maximum level correctly

---

### Test 9: Visual Feedback During Input
**Objective**: Verify immediate visual feedback

**Steps**:
1. Start game and wait for input phase
2. Press and hold each button
3. Verify LED lights immediately when pressed
4. Verify LED turns off when released

**Expected Results**:
- LED lights immediately when button pressed
- LED turns off when button released
- No delay in visual feedback

**Pass Criteria**: Immediate visual feedback works correctly

---

### Test 10: Random Sequence Generation
**Objective**: Verify sequences are random

**Steps**:
1. Play multiple games
2. Record the first 5 elements of each game
3. Verify sequences are different

**Expected Results**:
- Each game starts with different sequence
- No obvious patterns in sequence generation
- All three colors appear in sequences

**Pass Criteria**: Sequences appear random and varied

## Performance Testing

### Timing Verification
Use PLC monitoring tools to verify:
- Flash duration: 500ms ± 10ms
- Gap duration: 200ms ± 10ms  
- Input timeout: 3000ms ± 50ms
- State transitions: < 10ms

### Memory Usage
Monitor PLC memory usage:
- Program memory usage
- Data memory usage
- Ensure sufficient memory for expansion

## Troubleshooting Guide

### Common Issues and Solutions

**Issue**: LEDs don't light when buttons pressed
- **Check**: Wiring connections (Pin 2 to DO, Pin 3 to 0V)
- **Check**: Output module power supply
- **Check**: I/O configuration in PLC

**Issue**: Buttons don't register presses
- **Check**: Input wiring (Pin 1 to +24V, Pin 4 to DI)
- **Check**: Input module configuration
- **Check**: Button contact operation

**Issue**: Game doesn't start
- **Check**: Start button wiring (DI7)
- **Check**: GameState variable initialization
- **Check**: Program scan cycle

**Issue**: Timing seems incorrect
- **Check**: Timer preset values
- **Check**: PLC scan time
- **Check**: Timer function blocks

**Issue**: Random sequences not random
- **Check**: RandomSeed initialization
- **Check**: Random number algorithm
- **Consider**: Using system clock for seed

## Acceptance Criteria

### Phase 1 Completion Requirements
- [ ] All I/O functions correctly
- [ ] Game starts reliably with Start button
- [ ] Sequences display with correct timing
- [ ] Correct input advances game
- [ ] Incorrect input triggers game over
- [ ] Timeout handling works properly
- [ ] Multi-level progression functions
- [ ] Visual feedback is immediate
- [ ] System handles edge cases gracefully
- [ ] Documentation is complete and accurate

### Performance Requirements
- [ ] Response time < 50ms for button presses
- [ ] Timing accuracy within ±5%
- [ ] System operates continuously for 8+ hours
- [ ] Memory usage < 50% of available
- [ ] No memory leaks or stack overflows

## Test Log Template

```
Test Date: ___________
Tester: ___________
PLC Program Version: ___________
Hardware Configuration: ___________

Test Results:
[ ] Test 1: Basic I/O - PASS/FAIL - Notes: ___________
[ ] Test 2: State Machine - PASS/FAIL - Notes: ___________
[ ] Test 3: Sequence Display - PASS/FAIL - Notes: ___________
[ ] Test 4: Correct Input - PASS/FAIL - Notes: ___________
[ ] Test 5: Incorrect Input - PASS/FAIL - Notes: ___________
[ ] Test 6: Input Timeout - PASS/FAIL - Notes: ___________
[ ] Test 7: Multi-Level - PASS/FAIL - Notes: ___________
[ ] Test 8: Maximum Level - PASS/FAIL - Notes: ___________
[ ] Test 9: Visual Feedback - PASS/FAIL - Notes: ___________
[ ] Test 10: Random Sequence - PASS/FAIL - Notes: ___________

Overall Result: PASS/FAIL
Comments: ___________
```