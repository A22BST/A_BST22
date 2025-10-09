# New Variables Required for Sequence Display

Add these variables to your variable declaration section:

```
// Sequence Display Variables
SeqDisplay_Active   : BOOL := FALSE;   // TRUE when displaying sequence
SeqDisplay_Index    : INT := 0;        // Current position in sequence being displayed
SeqDisplay_Step     : INT := 0;        // 0 = LED ON, 1 = LED OFF (pause)
SeqDisplay_Tick     : BOOL;            // Edge trigger for sequence timing
T_SeqDisplay        : TON;             // Timer for sequence display (300ms intervals)
Trig_SeqTick        : R_TRIG;          // Rising edge trigger for sequence steps
```

## How It Works

1. **After each round**: When a new random number is added to `GameFlow_SN`, the sequence display is triggered
2. **Display sequence**: The game iterates through the array from index 0 to `WriteIndex-1`
3. **LED mapping**: 
   - 1 = Yellow LED (OLED_Y)
   - 2 = Blue LED (OLED_B)
   - 3 = Red LED (OLED_R)
4. **Timing**: Each LED lights up for 300ms, then turns off for 300ms before showing the next one
5. **Growth**: Round 1 shows 1 light, Round 2 shows 2 lights in sequence, Round 20 shows all 20 lights in order

## Key Changes

- Button LED control is now conditional: `IF NOT SeqDisplay_Active THEN` to prevent manual button presses from interfering during sequence display
- Sequence automatically plays after each round
- Uses the same 300ms timing as your game over sequence for consistency
