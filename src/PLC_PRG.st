(*
  PLC_PRG.st — Main Program for CODESY-SIM Bottle-Filling PLC
  -----------------------------------------------------------------------
  Language: Structured Text (ST) — equivalent to Ladder Diagram logic.
  Assigned to: MainTask (see Task Configuration notes in README).

  HOW TO USE IN CODESYS:
    1. Open or create PLC_PRG (Program, ST language).
    2. In the DECLARATION area paste the VAR CONSTANT and VAR blocks below.
    3. In the IMPLEMENTATION area paste the program body below.
    4. Save (Ctrl+S) and build (Ctrl+F7).

  DECLARATION SECTION — paste inside the Declaration tab of PLC_PRG:
  -------------------------------------------------------------------
  (Declare runtime variables locally in PLC_PRG; no GVL_vars dependency.)

      VAR CONSTANT
          S_Idle       : INT := 0;
          S_WaitBottle : INT := 1;
          S_Fill       : INT := 2;
          S_Cap        : INT := 3;
          S_Eject      : INT := 4;
          S_Fault      : INT := 5;
      END_VAR

      VAR
          (* Inputs *)
          StartPB       : BOOL := FALSE;
          StopPB        : BOOL := FALSE;
          EStop         : BOOL := FALSE;
          BottleSensor  : BOOL := FALSE;
          LowLevel      : BOOL := FALSE;
          FaultReset    : BOOL := FALSE;

          (* Outputs *)
          ConveyorMotor : BOOL := FALSE;
          FillValve     : BOOL := FALSE;
          Capper        : BOOL := FALSE;
          AlarmBuzzer   : BOOL := FALSE;
          GreenLamp     : BOOL := FALSE;
          RedLamp       : BOOL := FALSE;

          (* Logic *)
          RunLatch      : BOOL := FALSE;
          SystemEnable  : BOOL := FALSE;
          Fault         : BOOL := FALSE;

          (* State machine *)
          State         : INT := 0;

          (* Timers *)
          tFill         : TON;
          tCap          : TON;
          tEject        : TON;

          (* Edge triggers *)
          rStart        : R_TRIG;
          rBottle       : R_TRIG;
          rFaultReset   : R_TRIG;
      END_VAR

  IMPLEMENTATION SECTION — paste everything below into the
  Implementation tab of PLC_PRG:
*)

(* ================================================================
   PLC_PRG — Implementation
   ================================================================ *)

(* ── Step 1: Edge detectors ────────────────────────────────────── *)
rStart(CLK := StartPB);
rBottle(CLK := BottleSensor);
rFaultReset(CLK := FaultReset);

(* ── Step 2: Start / Stop latch ────────────────────────────────── *)
(* SET on rising edge of Start, RESET on Stop or EStop *)
IF rStart.Q THEN
    RunLatch := TRUE;
END_IF;
IF StopPB OR EStop THEN
    RunLatch := FALSE;
END_IF;

(* ── Step 3: Master enable ─────────────────────────────────────── *)
(* System runs only when latched, not faulted, and EStop clear *)
SystemEnable := RunLatch
                AND NOT Fault
                AND NOT EStop;

(* ── Step 4: Fault conditions ──────────────────────────────────── *)
(* Any fault source latches the Fault flag *)
IF EStop OR LowLevel THEN
    Fault := TRUE;
END_IF;
(* Operator reset clears fault (only when EStop is released) *)
IF rFaultReset.Q AND NOT EStop THEN
    Fault    := FALSE;
    RunLatch := FALSE;  (* Force re-start after reset *)
END_IF;

(* ── Step 5: State machine ─────────────────────────────────────── *)
CASE State OF

  S_Idle:
    (* All outputs off while idle *)
    ConveyorMotor := FALSE;
    FillValve     := FALSE;
    Capper        := FALSE;
    IF SystemEnable THEN
        State := S_WaitBottle;
    END_IF;

  S_WaitBottle:
    (* Conveyor runs; wait for bottle *)
    ConveyorMotor := TRUE;
    FillValve     := FALSE;
    Capper        := FALSE;
    IF NOT SystemEnable THEN
        State := S_Idle;
    ELSIF rBottle.Q THEN
        ConveyorMotor := FALSE;  (* Stop conveyor while filling *)
        State         := S_Fill;
    END_IF;

  S_Fill:
    (* Open fill valve; run tFill timer *)
    FillValve := TRUE;
    tFill(IN := TRUE, PT := T#5s);
    IF NOT SystemEnable THEN
        tFill(IN := FALSE, PT := T#5s);  (* Reset timer *)
        FillValve := FALSE;
        State     := S_Idle;
    ELSIF tFill.Q THEN
        FillValve := FALSE;
        tFill(IN := FALSE, PT := T#5s);  (* Reset timer *)
        State    := S_Cap;
    END_IF;

  S_Cap:
    (* Activate capper; run tCap timer *)
    Capper := TRUE;
    tCap(IN := TRUE, PT := T#2s);
    IF NOT SystemEnable THEN
        tCap(IN := FALSE, PT := T#2s);
        Capper := FALSE;
        State  := S_Idle;
    ELSIF tCap.Q THEN
        Capper := FALSE;
        tCap(IN := FALSE, PT := T#2s);
        State  := S_Eject;
    END_IF;

  S_Eject:
    (* Restart conveyor to eject bottle; run tEject timer *)
    ConveyorMotor := TRUE;
    tEject(IN := TRUE, PT := T#3s);
    IF NOT SystemEnable THEN
        tEject(IN := FALSE, PT := T#3s);
        ConveyorMotor := FALSE;
        State         := S_Idle;
    ELSIF tEject.Q THEN
        ConveyorMotor := FALSE;
        tEject(IN := FALSE, PT := T#3s);
        State         := S_WaitBottle;  (* Ready for next bottle *)
    END_IF;

  S_Fault:
    (* All outputs off; alarm on *)
    ConveyorMotor := FALSE;
    FillValve     := FALSE;
    Capper        := FALSE;
    IF NOT Fault THEN
        State := S_Idle;  (* Fault cleared — return to Idle *)
    END_IF;

END_CASE;

(* ── Step 6: Fault → force S_Fault state + reset all timers ────── *)
IF Fault AND State <> S_Fault THEN
    (* Reset any timer that may have been active mid-sequence *)
    tFill(IN := FALSE, PT := T#5s);
    tCap(IN := FALSE, PT := T#2s);
    tEject(IN := FALSE, PT := T#3s);
    State := S_Fault;
END_IF;

(* ── Step 7: Lamp and buzzer outputs ───────────────────────────── *)
GreenLamp   := SystemEnable AND NOT Fault;
RedLamp     := Fault OR EStop;
AlarmBuzzer := Fault;
