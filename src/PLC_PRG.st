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

  (* Internal state *)
  RunLatch      : BOOL := FALSE;
  SystemEnable  : BOOL := FALSE;
  Fault         : BOOL := FALSE;
  State         : INT := 0; (* S_Idle *)

  (* FB instances *)
  tFill         : TON;
  tCap          : TON;
  tEject        : TON;
  rStart        : R_TRIG;
  rBottle       : R_TRIG;
  rFaultReset   : R_TRIG;

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
rFaultReset(CLK := FaultReset);

(* Step 2: Start/Stop latch *)
IF rStart.Q THEN
    RunLatch := TRUE;
END_IF;
IF StopPB OR EStop THEN
    RunLatch := FALSE;
END_IF;

(* Step 3: Fault conditions *)
(* EStop is latched into Fault and requires FaultReset after EStop release. *)
IF EStop OR LowLevel THEN
    Fault := TRUE;
END_IF;
IF rFaultReset.Q AND NOT EStop AND NOT LowLevel THEN
    Fault := FALSE;
    RunLatch := FALSE;
END_IF;

(* Step 4: Master enable *)
(* Keep NOT EStop explicitly for immediate disable on the same scan as EStop press. *)
SystemEnable := RunLatch AND NOT Fault AND NOT EStop;

(* Step 5: Timers *)
tFill(IN := (State = S_Fill) AND SystemEnable, PT := tFill_PT);
tCap(IN := (State = S_Cap) AND SystemEnable, PT := tCap_PT);
tEject(IN := (State = S_Eject) AND SystemEnable, PT := tEject_PT);

(* Step 6: State machine *)
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
    IF NOT SystemEnable THEN
        FillValve := FALSE;
        State := S_Idle;
    ELSIF tFill.Q THEN
        FillValve := FALSE;
        State := S_Cap;
    END_IF;

  S_Cap:
    Capper := TRUE;
    IF NOT SystemEnable THEN
        Capper := FALSE;
        State := S_Idle;
    ELSIF tCap.Q THEN
        Capper := FALSE;
        State := S_Eject;
    END_IF;

  S_Eject:
    ConveyorMotor := TRUE;
    IF NOT SystemEnable THEN
        ConveyorMotor := FALSE;
        State := S_Idle;
    ELSIF tEject.Q THEN
        ConveyorMotor := FALSE;
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

(* Step 7: Force fault state and reset timers *)
IF Fault AND State <> S_Fault THEN
    ConveyorMotor := FALSE;
    FillValve := FALSE;
    Capper := FALSE;
    State := S_Fault;
END_IF;

(* Step 8: Lamps and alarm *)
GreenLamp := SystemEnable;
RedLamp := Fault OR EStop;
AlarmBuzzer := Fault;
