(* ====================================================================== *)
(* Main Program - Simon Says Game                                        *)
(* Uses FB_SimonSays Function Block                                      *)
(* For Omron NX102-1100 PLC                                             *)
(* ====================================================================== *)

PROGRAM MainProgram
    
VAR_GLOBAL
    (* ====================================================================== *)
    (* Physical I/O Mapping                                                  *)
    (* ====================================================================== *)
    (* Inputs from NX-ID4442 *)
    DI_YellowButton AT %IX0.1 : BOOL;    (* DI1 - Yellow button contact *)
    DI_BlueButton AT %IX0.3 : BOOL;      (* DI3 - Blue button contact *)
    DI_RedButton AT %IX0.5 : BOOL;       (* DI5 - Red button contact *)
    
    (* Outputs to NX-OD4256 *)
    DO_RedLED AT %QX0.0 : BOOL;          (* DO0 - Red button LED *)
    DO_BlueLED AT %QX0.1 : BOOL;         (* DO1 - Blue button LED *)
    DO_YellowLED AT %QX0.2 : BOOL;       (* DO2 - Yellow button LED *)
    
    (* Control Inputs - Map to selector switch later *)
    StartButton : BOOL := FALSE;          (* Start game signal *)
    ResetButton : BOOL := FALSE;          (* Reset game signal *)
    
    (* Game Instance *)
    SimonSaysGame : FB_SimonSays;
    
    (* HMI Variables *)
    GameActive : BOOL;
    CurrentLevel : INT;
    GameWon : BOOL;
    GameLost : BOOL;
    CurrentState : INT;
    
    (* Configuration Parameters *)
    MaxLevel : INT := 10;                 (* Maximum sequence length *)
    ShowTime : TIME := T#500MS;           (* LED display duration *)
    GapTime : TIME := T#200MS;            (* Gap between LEDs *)
    InputTimeout : TIME := T#3S;          (* Player input timeout *)
    
END_VAR

(* ====================================================================== *)
(* MAIN PROGRAM EXECUTION                                                *)
(* ====================================================================== *)

(* Call Simon Says Function Block *)
SimonSaysGame(
    (* Inputs *)
    i_YellowButton := DI_YellowButton,
    i_BlueButton := DI_BlueButton,
    i_RedButton := DI_RedButton,
    i_StartButton := StartButton,
    i_Reset := ResetButton,
    i_MaxLevel := MaxLevel,
    i_ShowTime := ShowTime,
    i_GapTime := GapTime,
    i_InputTimeout := InputTimeout,
    
    (* Outputs *)
    q_YellowLED => DO_YellowLED,
    q_BlueLED => DO_BlueLED,
    q_RedLED => DO_RedLED,
    q_GameActive => GameActive,
    q_CurrentLevel => CurrentLevel,
    q_GameWon => GameWon,
    q_GameLost => GameLost,
    q_State => CurrentState
);

(* ====================================================================== *)
(* Additional Logic for Selector Switch Integration                      *)
(* Map selector switch positions to game control                         *)
(* This will be expanded in Phase 2                                      *)
(* ====================================================================== *)

(* For now, you can manually set StartButton to TRUE to start the game *)
(* In actual implementation, this would be connected to selector switch *)

END_PROGRAM