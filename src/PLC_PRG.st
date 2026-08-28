(*
  PLC_PRG.st — Main Program for CODESY-SIM Bottle-Filling PLC
  -----------------------------------------------------------------------
  Core runtime variables are declared in PLC_PRG Declaration (not in GVL).
  This keeps the demo self-contained and beginner-friendly for Ladder/ST flow.

  Add Standard library in Library Manager for TON and R_TRIG types.
*)

(* ================================================================
   PLC_PRG — Declaration (paste in Declaration tab)
   ================================================================ *)
TYPE
  T_State : (
    S_Idle,
    S_WaitBottle,
    S_Fill,
    S_Cap,
    S_Eject,
    S_Fault
  );
END_TYPE

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

  (* Internal state *)
  RunLatch      : BOOL := FALSE;
  SystemEnable  : BOOL := FALSE;
  Fault         : BOOL := FALSE;
  State         : T_State := S_Idle;

  (* FB instances *)
  tFill         : TON;
  tCap          : TON;
  tEject        : TON;
  rStart        : R_TRIG;
  rBottle       : R_TRIG;

  (* Timer presets *)
  tFill_PT      : TIME := T#5s;
  tCap_PT       : TIME := T#2s;
  tEject_PT     : TIME := T#3s;
END_VAR

(* ================================================================
   PLC_PRG — Implementation (paste in Implementation tab)
   ================================================================ *)

(* Step 1: Edge detectors *)
rStart(CLK := StartPB);
rBottle(CLK := BottleSensor);

(* Step 2: Start/Stop latch *)
IF rStart.Q THEN
    RunLatch := TRUE;
END_IF;
IF StopPB OR EStop THEN
    RunLatch := FALSE;
END_IF;

(* Step 3: Master enable *)
SystemEnable := RunLatch AND NOT Fault AND NOT EStop;

(* Step 4: Fault conditions *)
IF EStop OR LowLevel THEN
    Fault := TRUE;
END_IF;
IF FaultReset AND NOT EStop AND NOT LowLevel THEN
    Fault := FALSE;
    RunLatch := FALSE;
END_IF;

(* Step 5: State machine *)
CASE State OF
  S_Idle:
    ConveyorMotor := FALSE;
    FillValve := FALSE;
    Capper := FALSE;
    IF SystemEnable THEN
        State := S_WaitBottle;
    END_IF;

  S_WaitBottle:
    ConveyorMotor := TRUE;
    FillValve := FALSE;
    Capper := FALSE;
    IF NOT SystemEnable THEN
        State := S_Idle;
    ELSIF rBottle.Q THEN
        ConveyorMotor := FALSE;
        State := S_Fill;
    END_IF;

  S_Fill:
    FillValve := TRUE;
    tFill(IN := TRUE, PT := tFill_PT);
    IF NOT SystemEnable THEN
        tFill(IN := FALSE, PT := tFill_PT);
        FillValve := FALSE;
        State := S_Idle;
    ELSIF tFill.Q THEN
        FillValve := FALSE;
        tFill(IN := FALSE, PT := tFill_PT);
        State := S_Cap;
    END_IF;

  S_Cap:
    Capper := TRUE;
    tCap(IN := TRUE, PT := tCap_PT);
    IF NOT SystemEnable THEN
        tCap(IN := FALSE, PT := tCap_PT);
        Capper := FALSE;
        State := S_Idle;
    ELSIF tCap.Q THEN
        Capper := FALSE;
        tCap(IN := FALSE, PT := tCap_PT);
        State := S_Eject;
    END_IF;

  S_Eject:
    ConveyorMotor := TRUE;
    tEject(IN := TRUE, PT := tEject_PT);
    IF NOT SystemEnable THEN
        tEject(IN := FALSE, PT := tEject_PT);
        ConveyorMotor := FALSE;
        State := S_Idle;
    ELSIF tEject.Q THEN
        ConveyorMotor := FALSE;
        tEject(IN := FALSE, PT := tEject_PT);
        State := S_WaitBottle;
    END_IF;

  S_Fault:
    ConveyorMotor := FALSE;
    FillValve := FALSE;
    Capper := FALSE;
    IF NOT Fault THEN
        State := S_Idle;
    END_IF;
END_CASE;

(* Step 6: Force fault state and reset timers *)
IF Fault AND State <> S_Fault THEN
    ConveyorMotor := FALSE;
    FillValve := FALSE;
    Capper := FALSE;
    tFill(IN := FALSE, PT := tFill_PT);
    tCap(IN := FALSE, PT := tCap_PT);
    tEject(IN := FALSE, PT := tEject_PT);
    State := S_Fault;
END_IF;

(* Step 7: Lamps and alarm *)
GreenLamp := SystemEnable AND NOT Fault;
RedLamp := Fault OR EStop;
AlarmBuzzer := Fault;
