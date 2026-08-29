# CODESY-SIM — Bottle-Filling PLC (Code-First LD + ST) + HMI Simulation

A beginner-friendly CODESYS project for a bottle-filling station.
It now includes a **code-first Ladder Diagram (LD) workflow** with
plain-English variable names, plus the earlier ST version.

---

## Repository layout

```
src/
  MachineIO.st              ← Plain-English GVL for LD workflow
  PLC_PRG_LD_Microsteps.md  ← Rung-by-rung LD build instructions
  GVL_vars.st          ← Global Variable List (TYPE + VAR_GLOBAL)
  PLC_PRG.st           ← Main program (implementation only)
  HMI_Visualization.md ← HMI page layout instructions
README.md
```

---

## Known issues fixed from prior attempts

| Previous error | Root cause | Fix |
|---|---|---|
| `Capper : FALSE;` compiler error | Assignment written in Declaration section | Use `:=` in Implementation; use `: BOOL := FALSE;` in Declaration |
| `tFill_PT : R_TRIG` type mismatch | Wrong type pasted (R_TRIG instead of TIME) | Changed to `tFill_PT : TIME := T#5s;` in GVL_vars.st |
| `T_State` / `DED.DEVICE_STATE` confusion | Library enum type used instead of custom | Defined own `T_State` enum in GVL_vars.st |
| FB calls in Declaration section | ST code pasted into wrong editor tab | All FB calls and assignments are in PLC_PRG Implementation only |
| `No CASE label found` | STATE enum declared after or separately from CASE | TYPE declared at top of same GVL, before VAR_GLOBAL |

---

## Prerequisites

1. **CODESYS V3.5** or later (tested on Control Win V3 x64).
2. **Standard library** — must be added to the project:
   - *Project → Library Manager → Add library… → search "Standard" → add*
   - This provides `TON`, `R_TRIG`, `F_TRIG` function blocks.
3. **CODESYS Control Win V3 x64** runtime (for local PC simulation).

---

## Recommended: code-first LD workflow (no visualization yet)

### 1 — Create a new CODESYS project

1. Open CODESYS → *File → New Project → Standard Project*.
2. Select device: **CODESYS Control Win V3 x64**.
3. Language: choose **Ladder Diagram (LD)** for `PLC_PRG`.

### 2 — Add Standard library

- *Project → Library Manager → Add library… → "Standard"*

### 3 — Create the Global Variable List

1. *Project → Add Object → Global Variable List → name it `MachineIO`*.
2. Open `MachineIO` in the editor (Declaration area).
3. **Replace** the entire content with `src/MachineIO.st`.
4. Save (Ctrl+S).

### 4 — Build ladder networks in PLC_PRG

1. Open `PLC_PRG` (created automatically with the Standard Project).
2. Follow `src/PLC_PRG_LD_Microsteps.md`.
3. Build networks 1→11 exactly in order.
4. Save (Ctrl+S).

### 5 — Assign PLC_PRG to MainTask

- *Application → Task Configuration → MainTask → Add POU Instance →
  select `PLC_PRG`* (if not already listed).

### 6 — Build

- *Build → Build* (Ctrl+F7).
- Expected: **0 errors, 0 warnings** (or only info-level warnings).

---

## How to run in CODESYS Control Win V3 x64 (code-only)

1. Start the CODESYS Control Win V3 runtime (system tray icon or
   *Tools → CODESYS Control Win V3 x64 → Start*).
2. In CODESYS IDE: *Online → Login* (Ctrl+L) → choose the running
   target → *Yes* to download.
3. *Debug → Start* (F5) to run.

## Micro-test sequence (code-only)

Use a watch window and force/toggle these inputs:

| Step | Action | Expected result |
|------|--------|-----------------|
| 1 | Pulse `StartButton` | `MachineRunning = TRUE`, `StepWaitBottle = TRUE`, `ConveyorMotor = TRUE` |
| 2 | Pulse `BottlePresentSensor` | `StepFill = TRUE`, `FillValve = TRUE` |
| 3 | Wait 5 s | `StepCap = TRUE`, `CapperMotor = TRUE` |
| 4 | Wait 2 s | `StepEject = TRUE`, `ConveyorMotor = TRUE` |
| 5 | Wait 3 s | `StepWaitBottle = TRUE` (loop complete) |
| 6 | Set `LowLiquidLevelSensor` TRUE (or `EmergencyStop` TRUE) | `FaultActive = TRUE`, `AlarmBuzzer = TRUE`, sequence stops |
| 7 | Clear E-stop, pulse `ResetFaultButton` | `FaultActive = FALSE`, `MachineRunning = FALSE` |

---

## Variable quick reference (plain-English LD set)

| Variable | Type | Purpose |
|---|---|---|
| `StartButton` | BOOL | Momentary Start pushbutton |
| `StopButton` | BOOL | Stop pushbutton |
| `EmergencyStop` | BOOL | Emergency stop (active TRUE) |
| `BottlePresentSensor` | BOOL | Simulated digital bottle sensor (real world: photoelectric) |
| `LowLiquidLevelSensor` | BOOL | Simulated digital low-level sensor (real world: float/level switch) |
| `ResetFaultButton` | BOOL | Fault reset (momentary) |
| `ConveyorMotor` | BOOL | Conveyor output |
| `FillValve` | BOOL | Fill valve output |
| `CapperMotor` | BOOL | Capper output |
| `AlarmBuzzer` | BOOL | Alarm output |
| `RunLight` | BOOL | Running indicator |
| `FaultLight` | BOOL | Fault/Stop indicator |
| `MachineRunning` | BOOL | Start/Stop latch |
| `MachineEnabled` | BOOL | Master enable (derived) |
| `FaultActive` | BOOL | Fault latch |
| `StepWaitBottle` | BOOL | Sequence step bit |
| `StepFill` | BOOL | Sequence step bit |
| `StepCap` | BOOL | Sequence step bit |
| `StepEject` | BOOL | Sequence step bit |
| `FillTimerPreset` | TIME | Fill timer preset (default 5 s) |
| `CapTimerPreset` | TIME | Cap timer preset (default 2 s) |
| `EjectTimerPreset` | TIME | Eject timer preset (default 3 s) |

---

## Legacy ST workflow (optional)

If you want the older Structured Text version, use:
- `src/GVL_vars.st`
- `src/PLC_PRG.st`
