(*
  PLC_PRG.st — Main Program for CODESY-SIM Bottle-Filling PLC
  -----------------------------------------------------------------------
  Language: Structured Text (ST) — equivalent to Ladder Diagram logic.
  Assigned to: MainTask (see Task Configuration notes in README).

  HOW TO USE IN CODESYS:
    1. Open or create PLC_PRG (Program, ST language).
    2. In the DECLARATION area paste the VAR block below.
    3. In the IMPLEMENTATION area paste the program body below.
    4. Save (Ctrl+S) and build (Ctrl+F7).

  DECLARATION SECTION — paste inside the Declaration tab of PLC_PRG:
  -------------------------------------------------------------------
  (No local variables needed; all variables live in GVL_vars.)
  Leave the Declaration area as:

      VAR
      END_VAR

  IMPLEMENTATION SECTION — paste everything below into the
  Implementation tab of PLC_PRG:
*)

(* ================================================================
   PLC_PRG — Implementation
   ================================================================ *)

(* ── Step 1: Edge detectors ────────────────────────────────────── *)
GVL_vars.rStart (CLK  := GVL_vars.StartPB);
GVL_vars.rBottle(CLK  := GVL_vars.BottleSensor);

(* ── Step 2: Start / Stop latch ────────────────────────────────── *)
(* SET on rising edge of Start, RESET on Stop or EStop *)
IF GVL_vars.rStart.Q THEN
    GVL_vars.RunLatch := TRUE;
END_IF;
IF GVL_vars.StopPB OR GVL_vars.EStop THEN
    GVL_vars.RunLatch := FALSE;
END_IF;

(* ── Step 3: Master enable ─────────────────────────────────────── *)
(* System runs only when latched, not faulted, and EStop clear *)
GVL_vars.SystemEnable := GVL_vars.RunLatch
                         AND NOT GVL_vars.Fault
                         AND NOT GVL_vars.EStop;

(* ── Step 4: Fault conditions ──────────────────────────────────── *)
(* Any fault source latches the Fault flag *)
IF GVL_vars.EStop OR GVL_vars.LowLevel THEN
    GVL_vars.Fault := TRUE;
END_IF;
(* Operator reset clears fault (only when EStop is released) *)
IF GVL_vars.FaultReset AND NOT GVL_vars.EStop THEN
    GVL_vars.Fault    := FALSE;
    GVL_vars.RunLatch := FALSE;  (* Force re-start after reset *)
END_IF;

(* ── Step 5: State machine ─────────────────────────────────────── *)
CASE GVL_vars.State OF

  S_Idle:
    (* All outputs off while idle *)
    GVL_vars.ConveyorMotor := FALSE;
    GVL_vars.FillValve     := FALSE;
    GVL_vars.Capper        := FALSE;
    IF GVL_vars.SystemEnable THEN
        GVL_vars.State := S_WaitBottle;
    END_IF;

  S_WaitBottle:
    (* Conveyor runs; wait for bottle *)
    GVL_vars.ConveyorMotor := TRUE;
    GVL_vars.FillValve     := FALSE;
    GVL_vars.Capper        := FALSE;
    IF NOT GVL_vars.SystemEnable THEN
        GVL_vars.State := S_Idle;
    ELSIF GVL_vars.rBottle.Q THEN
        GVL_vars.ConveyorMotor := FALSE;  (* Stop conveyor while filling *)
        GVL_vars.State         := S_Fill;
    END_IF;

  S_Fill:
    (* Open fill valve; run tFill timer *)
    GVL_vars.FillValve := TRUE;
    GVL_vars.tFill(IN := TRUE,  PT := GVL_vars.tFill_PT);
    IF NOT GVL_vars.SystemEnable THEN
        GVL_vars.tFill(IN := FALSE, PT := GVL_vars.tFill_PT);  (* Reset timer *)
        GVL_vars.FillValve := FALSE;
        GVL_vars.State     := S_Idle;
    ELSIF GVL_vars.tFill.Q THEN
        GVL_vars.FillValve := FALSE;
        GVL_vars.tFill(IN  := FALSE, PT := GVL_vars.tFill_PT);  (* Reset timer *)
        GVL_vars.State     := S_Cap;
    END_IF;

  S_Cap:
    (* Activate capper; run tCap timer *)
    GVL_vars.Capper := TRUE;
    GVL_vars.tCap(IN := TRUE, PT := GVL_vars.tCap_PT);
    IF NOT GVL_vars.SystemEnable THEN
        GVL_vars.tCap(IN := FALSE, PT := GVL_vars.tCap_PT);
        GVL_vars.Capper := FALSE;
        GVL_vars.State  := S_Idle;
    ELSIF GVL_vars.tCap.Q THEN
        GVL_vars.Capper := FALSE;
        GVL_vars.tCap(IN := FALSE, PT := GVL_vars.tCap_PT);
        GVL_vars.State  := S_Eject;
    END_IF;

  S_Eject:
    (* Restart conveyor to eject bottle; run tEject timer *)
    GVL_vars.ConveyorMotor := TRUE;
    GVL_vars.tEject(IN := TRUE, PT := GVL_vars.tEject_PT);
    IF NOT GVL_vars.SystemEnable THEN
        GVL_vars.tEject(IN := FALSE, PT := GVL_vars.tEject_PT);
        GVL_vars.ConveyorMotor := FALSE;
        GVL_vars.State         := S_Idle;
    ELSIF GVL_vars.tEject.Q THEN
        GVL_vars.ConveyorMotor := FALSE;
        GVL_vars.tEject(IN := FALSE, PT := GVL_vars.tEject_PT);
        GVL_vars.State         := S_WaitBottle;  (* Ready for next bottle *)
    END_IF;

  S_Fault:
    (* All outputs off; alarm on *)
    GVL_vars.ConveyorMotor := FALSE;
    GVL_vars.FillValve     := FALSE;
    GVL_vars.Capper        := FALSE;
    IF NOT GVL_vars.Fault THEN
        GVL_vars.State := S_Idle;  (* Fault cleared — return to Idle *)
    END_IF;

END_CASE;

(* ── Step 6: Fault → force S_Fault state + reset all timers ────── *)
IF GVL_vars.Fault AND GVL_vars.State <> S_Fault THEN
    (* Reset any timer that may have been active mid-sequence *)
    GVL_vars.tFill (IN := FALSE, PT := GVL_vars.tFill_PT);
    GVL_vars.tCap  (IN := FALSE, PT := GVL_vars.tCap_PT);
    GVL_vars.tEject(IN := FALSE, PT := GVL_vars.tEject_PT);
    GVL_vars.State := S_Fault;
END_IF;

(* ── Step 7: Lamp and buzzer outputs ───────────────────────────── *)
GVL_vars.GreenLamp   := GVL_vars.SystemEnable AND NOT GVL_vars.Fault;
GVL_vars.RedLamp     := GVL_vars.Fault OR GVL_vars.EStop;
GVL_vars.AlarmBuzzer := GVL_vars.Fault;
