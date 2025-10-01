(* ====================================================================== *)
(* Simon Says Game - Phase 1 Ladder Logic                                *)
(* For Omron NX102-1100 PLC                                             *)
(* Version: 1.0                                                          *)
(* ====================================================================== *)

(* ====================================================================== *)
(* RUNG 0001: Input Edge Detection                                       *)
(* ====================================================================== *)
|----[P]---- YellowButton_Input ----( YellowButton_Press )
|
|----[P]---- BlueButton_Input ------( BlueButton_Press )
|
|----[P]---- RedButton_Input --------( RedButton_Press )
|

(* ====================================================================== *)
(* RUNG 0002: Game Start Logic                                           *)
(* ====================================================================== *)
|----[/]---- GameActive ----[P]---- StartButton ----( StartGame )
|

(* ====================================================================== *)
(* RUNG 0003: Game State Control                                         *)
(* ====================================================================== *)
|----[ ]---- StartGame ----+----( SET GameActive )
|                          |
|                          +----( RST GameState_Idle )
|                          |
|                          +----( SET GameState_ShowSeq )
|                          |
|                          +----[MOV 1 --> CurrentLevel]
|                          |
|                          +----[MOV 0 --> SequenceIndex]
|

(* ====================================================================== *)
(* RUNG 0004: Generate Random Sequence                                   *)
(* ====================================================================== *)
|----[ ]---- GameState_ShowSeq ----[/]---- SeqGenerated ----+
|                                                            |
|    +----[ADD RandomCounter + 1 --> RandomCounter]         |
|    |                                                       |
|    +----[MOD RandomCounter 3 --> TempRandom]             |
|    |                                                       |
|    +----[ADD TempRandom + 1 --> NewButton]               |
|    |                                                       |
|    +----[MOV NewButton --> GameSequence[CurrentLevel-1]] |
|    |                                                       |
|    +----( SET SeqGenerated )                             |
|

(* ====================================================================== *)
(* RUNG 0005: Sequence Display Timer Control                             *)
(* ====================================================================== *)
|----[ ]---- GameState_ShowSeq ----[<]---- SequenceIndex CurrentLevel ----+
|                                                                          |
|    +----[/]---- LED_ON ----[/]---- LED_GAP ----( SET LED_ON )          |
|    |                                                                     |
|    |                                           +----[TMR ShowTimer]     |
|    |                                           |    [500ms]             |
|    |                                           |                        |
|    +----[ ]---- LED_ON ------------------------+                        |
|

(* ====================================================================== *)
(* RUNG 0006: LED Output Control During Sequence Display                 *)
(* ====================================================================== *)
|----[ ]---- GameState_ShowSeq ----[ ]---- LED_ON ----+
|                                                      |
|    +----[=]---- GameSequence[SequenceIndex] 1 ------( YellowButton_LED )
|    |
|    +----[=]---- GameSequence[SequenceIndex] 2 ------( BlueButton_LED )
|    |
|    +----[=]---- GameSequence[SequenceIndex] 3 ------( RedButton_LED )
|

(* ====================================================================== *)
(* RUNG 0007: Sequence Display State Transition                          *)
(* ====================================================================== *)
|----[ ]---- ShowTimer.Q ----+----( RST LED_ON )
|                            |
|                            +----( SET LED_GAP )
|                            |
|                            +----[TMR GapTimer]
|                                  [200ms]
|

(* ====================================================================== *)
(* RUNG 0008: Gap Timer Complete - Advance Sequence                      *)
(* ====================================================================== *)
|----[ ]---- GapTimer.Q ----+----( RST LED_GAP )
|                           |
|                           +----[ADD SequenceIndex + 1 --> SequenceIndex]
|

(* ====================================================================== *)
(* RUNG 0009: Sequence Display Complete - Switch to Input Mode           *)
(* ====================================================================== *)
|----[ ]---- GameState_ShowSeq ----[>=]---- SequenceIndex CurrentLevel ----+
|                                                                           |
|    +----( RST GameState_ShowSeq )                                       |
|    |                                                                      |
|    +----( SET GameState_WaitInput )                                     |
|    |                                                                      |
|    +----[MOV 0 --> PlayerInputIndex]                                    |
|    |                                                                      |
|    +----[TMR InputTimeout]                                               |
|         [3000ms]                                                         |
|

(* ====================================================================== *)
(* RUNG 0010: Player Input Processing - Yellow Button                    *)
(* ====================================================================== *)
|----[ ]---- GameState_WaitInput ----[ ]---- YellowButton_Press ----+
|                                                                    |
|    +----[MOV 1 --> CurrentInput]                                 |
|    |                                                              |
|    +----( SET InputReceived )                                    |
|    |                                                              |
|    +----( SET YellowButton_LED )                                 |
|

(* ====================================================================== *)
(* RUNG 0011: Player Input Processing - Blue Button                      *)
(* ====================================================================== *)
|----[ ]---- GameState_WaitInput ----[ ]---- BlueButton_Press ----+
|                                                                  |
|    +----[MOV 2 --> CurrentInput]                               |
|    |                                                            |
|    +----( SET InputReceived )                                  |
|    |                                                            |
|    +----( SET BlueButton_LED )                                 |
|

(* ====================================================================== *)
(* RUNG 0012: Player Input Processing - Red Button                       *)
(* ====================================================================== *)
|----[ ]---- GameState_WaitInput ----[ ]---- RedButton_Press ----+
|                                                                 |
|    +----[MOV 3 --> CurrentInput]                              |
|    |                                                           |
|    +----( SET InputReceived )                                 |
|    |                                                           |
|    +----( SET RedButton_LED )                                 |
|

(* ====================================================================== *)
(* RUNG 0013: LED Release Control                                        *)
(* ====================================================================== *)
|----[ ]---- GameState_WaitInput ----+
|                                     |
|    +----[/]---- YellowButton_Input ----( RST YellowButton_LED )
|    |
|    +----[/]---- BlueButton_Input ------( RST BlueButton_LED )
|    |
|    +----[/]---- RedButton_Input --------( RST RedButton_LED )
|

(* ====================================================================== *)
(* RUNG 0014: Input Verification                                         *)
(* ====================================================================== *)
|----[ ]---- InputReceived ----+
|                              |
|    +----[CMP CurrentInput = GameSequence[PlayerInputIndex]] ----( InputCorrect )
|    |
|    +----[CMP CurrentInput <> GameSequence[PlayerInputIndex]] ----( InputWrong )
|

(* ====================================================================== *)
(* RUNG 0015: Correct Input Processing                                   *)
(* ====================================================================== *)
|----[ ]---- InputCorrect ----+
|                             |
|    +----[ADD PlayerInputIndex + 1 --> PlayerInputIndex]
|    |
|    +----( RST InputReceived )
|    |
|    +----( RST InputTimeout )
|    |
|    +----[TMR InputTimeout]
|         [3000ms]
|

(* ====================================================================== *)
(* RUNG 0016: Level Complete Check                                       *)
(* ====================================================================== *)
|----[ ]---- GameState_WaitInput ----[>=]---- PlayerInputIndex CurrentLevel ----+
|                                                                                |
|    +----[<]---- CurrentLevel MaxLevel ----+----( LevelComplete )             |
|    |                                       |                                  |
|    |                                       +----[ADD CurrentLevel + 1 --> CurrentLevel]
|    |                                       |                                  |
|    |                                       +----( RST GameState_WaitInput )  |
|    |                                       |                                  |
|    |                                       +----( SET GameState_ShowSeq )    |
|    |                                       |                                  |
|    |                                       +----[MOV 0 --> SequenceIndex]    |
|    |                                       |                                  |
|    |                                       +----( RST SeqGenerated )         |
|    |                                                                          |
|    +----[>=]---- CurrentLevel MaxLevel ----( SET GameWin )                   |
|

(* ====================================================================== *)
(* RUNG 0017: Wrong Input or Timeout - Game Over                         *)
(* ====================================================================== *)
|----+----[ ]---- InputWrong -----------+----( SET GameLose )
|    |                                  |
|    +----[ ]---- InputTimeout.Q -------+----( RST GameState_WaitInput )
|                                       |
|                                       +----( RST GameActive )
|                                       |
|                                       +----[TMR GameOverTimer]
|                                             [2000ms]
|

(* ====================================================================== *)
(* RUNG 0018: Game Win Display                                           *)
(* ====================================================================== *)
|----[ ]---- GameWin ----+
|                        |
|    +----[TMR T0 100ms] ----( YellowButton_LED )
|    |                   |
|    |                   ----( BlueButton_LED )
|    |                   |
|    |                   ----( RedButton_LED )
|    |
|    +----[TMR T1 100ms] ----( RST YellowButton_LED )
|    |                   |
|    |                   ----( RST BlueButton_LED )
|    |                   |
|    |                   ----( RST RedButton_LED )
|    |
|    +----[ ]---- GameOverTimer.Q ----( RST GameWin )
|                                |
|                                ----( RST GameActive )
|

(* ====================================================================== *)
(* RUNG 0019: Game Lose Display                                          *)
(* ====================================================================== *)
|----[ ]---- GameLose ----+
|                         |
|    +----[BLINK 300ms] ----( RedButton_LED )
|    |
|    +----[ ]---- GameOverTimer.Q ----( RST GameLose )
|                                 |
|                                 ----( RST GameActive )
|

(* ====================================================================== *)
(* RUNG 0020: Reset to Idle State                                        *)
(* ====================================================================== *)
|----[/]---- GameActive ----+----( SET GameState_Idle )
|                           |
|                           +----( RST GameState_ShowSeq )
|                           |
|                           +----( RST GameState_WaitInput )
|                           |
|                           +----( RST YellowButton_LED )
|                           |
|                           +----( RST BlueButton_LED )
|                           |
|                           +----( RST RedButton_LED )
|                           |
|                           +----[MOV 0 --> CurrentLevel]
|                           |
|                           +----[MOV 0 --> SequenceIndex]
|                           |
|                           +----[MOV 0 --> PlayerInputIndex]
|