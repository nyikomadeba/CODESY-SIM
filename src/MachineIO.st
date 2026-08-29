(*
  MachineIO.st — Global Variable List for plain-English LD project
  -----------------------------------------------------------------
  HOW TO USE IN CODESYS:
    1. Project → Add Object → Global Variable List → name it "MachineIO"
    2. Open MachineIO in the editor (Declaration area).
    3. Replace default content with this file.
    4. Save (Ctrl+S).

  NOTE:
    Add Standard library in Library Manager for TON support.
*)

VAR_GLOBAL
  (* Inputs (operator + simulated sensors) *)
  StartButton           : BOOL := FALSE;  (* Momentary start button *)
  StopButton            : BOOL := FALSE;  (* Stop button *)
  EmergencyStop         : BOOL := FALSE;  (* E-stop, active TRUE *)
  BottlePresentSensor   : BOOL := FALSE;  (* Simulated digital bottle sensor; real-world: photoelectric sensor *)
  LowLiquidLevelSensor  : BOOL := FALSE;  (* Simulated digital low-level alarm; real-world: float/level switch *)
  ResetFaultButton      : BOOL := FALSE;  (* Fault reset button *)

  (* Outputs *)
  ConveyorMotor         : BOOL := FALSE;
  FillValve             : BOOL := FALSE;
  CapperMotor           : BOOL := FALSE;
  AlarmBuzzer           : BOOL := FALSE;
  RunLight              : BOOL := FALSE;
  FaultLight            : BOOL := FALSE;

  (* Internal control bits *)
  MachineRunning        : BOOL := FALSE;  (* Start/Stop latch *)
  FaultActive           : BOOL := FALSE;  (* Fault latch *)
  MachineEnabled        : BOOL := FALSE;  (* Running + safe + no fault *)

  (* Step bits *)
  StepWaitBottle        : BOOL := FALSE;
  StepFill              : BOOL := FALSE;
  StepCap               : BOOL := FALSE;
  StepEject             : BOOL := FALSE;

  (* Timer FBs *)
  FillTimer             : TON;
  CapTimer              : TON;
  EjectTimer            : TON;

  (* Timer presets *)
  FillTimerPreset       : TIME := T#5s;
  CapTimerPreset        : TIME := T#2s;
  EjectTimerPreset      : TIME := T#3s;
END_VAR

