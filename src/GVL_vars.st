(*
  GVL_vars.st — Global Variable List for CODESY-SIM Bottle-Filling PLC
  -----------------------------------------------------------------------
  HOW TO USE IN CODESYS:
    1. Project → Add Object → Global Variable List → name it "GVL_vars"
    2. Open GVL_vars in the editor (Declaration area).
    3. Replace the default content with the entire text of this file.
    4. Save (Ctrl+S).

  NOTE: The TYPE block must appear BEFORE the VAR_GLOBAL block.
        The Standard library must be added (Project → Library Manager →
        Add library… → search "Standard") so that TON and R_TRIG are
        recognised.
*)

(* ── State-machine enum ──────────────────────────────────────────── *)
TYPE
  T_State : (
    S_Idle,         (* System stopped, waiting for Start *)
    S_WaitBottle,   (* Running, waiting for bottle sensor *)
    S_Fill,         (* Filling — tFill timer active *)
    S_Cap,          (* Capping — tCap timer active *)
    S_Eject,        (* Ejecting — tEject timer active *)
    S_Fault         (* Fault latched — operator must reset *)
  );
END_TYPE

(* ── Global variables ────────────────────────────────────────────── *)
VAR_GLOBAL
  (* ── Inputs (operator / sensor) ── *)
  StartPB       : BOOL := FALSE;   (* Start pushbutton — rising edge *)
  StopPB        : BOOL := FALSE;   (* Stop pushbutton *)
  EStop         : BOOL := FALSE;   (* Emergency stop — active TRUE *)
  BottleSensor  : BOOL := FALSE;   (* Bottle present sensor *)
  LowLevel      : BOOL := FALSE;   (* Low fluid level sensor *)
  FaultReset    : BOOL := FALSE;   (* Operator fault-reset — momentary *)

  (* ── Outputs ── *)
  ConveyorMotor : BOOL := FALSE;   (* Conveyor motor *)
  FillValve     : BOOL := FALSE;   (* Fill valve *)
  Capper        : BOOL := FALSE;   (* Capper actuator *)
  AlarmBuzzer   : BOOL := FALSE;   (* Alarm buzzer *)
  GreenLamp     : BOOL := FALSE;   (* Green (running) lamp *)
  RedLamp       : BOOL := FALSE;   (* Red (fault/stop) lamp *)

  (* ── Internal state ── *)
  RunLatch      : BOOL := FALSE;   (* Start/Stop latch *)
  SystemEnable  : BOOL := FALSE;   (* Master enable (derived in PLC_PRG) *)
  Fault         : BOOL := FALSE;   (* Global fault latch *)
  State         : T_State := S_Idle; (* Current state-machine state *)

  (* ── Timer function-block instances (Standard library) ── *)
  tFill         : TON;             (* Fill timer *)
  tCap          : TON;             (* Cap timer *)
  tEject        : TON;             (* Eject timer *)

  (* ── Edge-detector instances (Standard library) ── *)
  rStart        : R_TRIG;          (* Rising edge on StartPB *)
  rBottle       : R_TRIG;          (* Rising edge on BottleSensor *)

  (* ── Timer presets (edit these to change dwell times) ── *)
  tFill_PT      : TIME := T#5s;    (* Fill duration  — default 5 s *)
  tCap_PT       : TIME := T#2s;    (* Cap duration   — default 2 s *)
  tEject_PT     : TIME := T#3s;    (* Eject duration — default 3 s *)
END_VAR
