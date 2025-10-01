(* ====================================================================
   FUNCTION BLOCK: Random Number Generator for Simon Says
   Generates pseudo-random numbers 1-3 for button selection
   ==================================================================== *)

FUNCTION_BLOCK FB_RandomGenerator
VAR_INPUT
    Generate : BOOL;        (* Trigger to generate new random number *)
    Reset : BOOL;           (* Reset seed to initial value *)
    MaxValue : INT := 3;    (* Maximum value (3 for 3 buttons, 4 for 4 buttons) *)
END_VAR

VAR_OUTPUT
    RandomValue : INT;      (* Output: 1 to MaxValue *)
    Done : BOOL;           (* Pulse when new number generated *)
END_VAR

VAR
    Seed : DINT := 12345;  (* Internal seed value *)
    LastGenerate : BOOL;   (* Edge detection *)
    PulseTimer : TON;      (* Timer for done pulse *)
END_VAR

(* Reset seed if requested *)
IF Reset THEN
    Seed := 12345;
    RandomValue := 0;
    Done := FALSE;
END_IF;

(* Detect rising edge of Generate signal *)
IF Generate AND NOT LastGenerate THEN
    (* Linear Congruential Generator algorithm *)
    Seed := (Seed * 1103515245 + 12345) MOD 2147483648;
    
    (* Convert to desired range (1 to MaxValue) *)
    RandomValue := (ABS(Seed) MOD MaxValue) + 1;
    
    (* Trigger done pulse *)
    Done := TRUE;
    PulseTimer(IN := TRUE, PT := T#100MS);
END_IF;

(* Clear done pulse after timer *)
PulseTimer(IN := PulseTimer.IN, PT := T#100MS);
IF PulseTimer.Q THEN
    Done := FALSE;
    PulseTimer(IN := FALSE);
END_IF;

(* Update edge detection *)
LastGenerate := Generate;

END_FUNCTION_BLOCK