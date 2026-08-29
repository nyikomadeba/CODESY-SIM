# PLC_PRG Ladder Program — Microstep Build Guide (Code-First)

Use this to build `PLC_PRG` in **Ladder Diagram (LD)** using `MachineIO` variables.

## Before you place rungs

1. Create a **Standard Project**.
2. Device: **CODESYS Control Win V3 x64**.
3. Language for `PLC_PRG`: **Ladder Diagram (LD)**.
4. Add Standard library (for `TON`).
5. Add a GVL named `MachineIO` and paste `/home/runner/work/CODESY-SIM/CODESY-SIM/src/MachineIO.st`.

---

## Network 1 — Start/Stop latch (`MachineRunning`)

- Branch A (SET path):  
  `StartButton` (NO contact) AND `NOT StopButton` (NC contact) AND `NOT EmergencyStop` (NC contact) → **S coil** `MachineRunning`
- Branch B (RESET path):  
  `StopButton` (NO) OR `EmergencyStop` (NO) → **R coil** `MachineRunning`

---

## Network 2 — Fault latch (`FaultActive`)

- `EmergencyStop` (NO) OR `LowLiquidLevelSensor` (NO) → **S coil** `FaultActive`

---

## Network 3 — Fault reset

- `ResetFaultButton` (NO) AND `NOT EmergencyStop` (NC) → **R coil** `FaultActive`
- `ResetFaultButton` (NO) AND `NOT EmergencyStop` (NC) → **R coil** `MachineRunning`

---

## Network 4 — Machine enabled

- `MachineRunning` (NO) AND `NOT FaultActive` (NC) AND `NOT EmergencyStop` (NC) → (normal coil) `MachineEnabled`

---

## Network 5 — Step initialization

- `MachineEnabled` (NO) AND `NOT StepWaitBottle` (NC) AND `NOT StepFill` (NC) AND `NOT StepCap` (NC) AND `NOT StepEject` (NC) → **S coil** `StepWaitBottle`
- `NOT MachineEnabled` (NC used as TRUE when disabled) → **R coils** for all step bits:
  - `StepWaitBottle`
  - `StepFill`
  - `StepCap`
  - `StepEject`

---

## Network 6 — Wait bottle step

- Output rung: `StepWaitBottle` (NO) AND `MachineEnabled` (NO) → (coil) `ConveyorMotor`
- Transition rung:
  - `StepWaitBottle` (NO) AND `MachineEnabled` (NO) AND `BottlePresentSensor` (NO) → **S coil** `StepFill`
  - Same condition → **R coil** `StepWaitBottle`

---

## Network 7 — Fill step

- Output rung: `StepFill` (NO) AND `MachineEnabled` (NO) → (coil) `FillValve`
- Timer call rung: `StepFill` (NO) AND `MachineEnabled` (NO) → call `FillTimer(IN:=TRUE, PT:=FillTimerPreset)`
- Timer reset rung (optional explicit reset): `NOT StepFill` (NC open when false) OR `NOT MachineEnabled` → call `FillTimer(IN:=FALSE, PT:=FillTimerPreset)`
- Transition rung when timer done:
  - `StepFill` (NO) AND `FillTimer.Q` (NO) → **S coil** `StepCap`
  - `StepFill` (NO) AND `FillTimer.Q` (NO) → **R coil** `StepFill`

---

## Network 8 — Cap step

- Output rung: `StepCap` (NO) AND `MachineEnabled` (NO) → (coil) `CapperMotor`
- Timer call rung: `StepCap` (NO) AND `MachineEnabled` (NO) → call `CapTimer(IN:=TRUE, PT:=CapTimerPreset)`
- Timer reset rung (optional explicit reset): `NOT StepCap` OR `NOT MachineEnabled` → call `CapTimer(IN:=FALSE, PT:=CapTimerPreset)`
- Transition rung when timer done:
  - `StepCap` (NO) AND `CapTimer.Q` (NO) → **S coil** `StepEject`
  - `StepCap` (NO) AND `CapTimer.Q` (NO) → **R coil** `StepCap`

---

## Network 9 — Eject step

- Output rung: `StepEject` (NO) AND `MachineEnabled` (NO) → (coil) `ConveyorMotor`
- Timer call rung: `StepEject` (NO) AND `MachineEnabled` (NO) → call `EjectTimer(IN:=TRUE, PT:=EjectTimerPreset)`
- Timer reset rung (optional explicit reset): `NOT StepEject` OR `NOT MachineEnabled` → call `EjectTimer(IN:=FALSE, PT:=EjectTimerPreset)`
- Transition rung when timer done:
  - `StepEject` (NO) AND `EjectTimer.Q` (NO) → **S coil** `StepWaitBottle`
  - `StepEject` (NO) AND `EjectTimer.Q` (NO) → **R coil** `StepEject`

---

## Network 10 — Fault override (safe state)

- `FaultActive` (NO) OR `NOT MachineEnabled` → **R coil** `StepFill`
- `FaultActive` (NO) OR `NOT MachineEnabled` → **R coil** `StepCap`
- `FaultActive` (NO) OR `NOT MachineEnabled` → **R coil** `StepEject`
- `FaultActive` (NO) OR `NOT MachineEnabled` → **R coil** `StepWaitBottle`

This ensures all sequence steps drop out in fault/stop conditions.

---

## Network 11 — Lamps and buzzer

- `MachineEnabled` (NO) AND `NOT FaultActive` (NC) → (coil) `RunLight`
- `FaultActive` (NO) OR `EmergencyStop` (NO) → (coil) `FaultLight`
- `FaultActive` (NO) → (coil) `AlarmBuzzer`

---

## Micro-test (code-only)

1. Build: **Ctrl+F7**.
2. Start Control Win runtime.
3. Login (**Ctrl+L**) and Start (**F5**).
4. Force/toggle inputs in watch:
   - StartButton ON then OFF → machine enters wait bottle.
   - BottlePresentSensor ON then OFF → fill for 5s.
   - Auto cap 2s, eject 3s, back to wait bottle.
   - LowLiquidLevelSensor ON (or EmergencyStop ON) → fault + alarm.
   - EmergencyStop OFF, ResetFaultButton pulse → fault clears.

