# CODESY-SIM — Bottle-Filling PLC (Ladder / ST) + HMI Simulation

A beginner-friendly CODESYS project that implements a bottle-filling
station using Structured Text (equivalent to Ladder Diagram logic),
with a simple HMI Visualization page for simulation.

---

## Repository layout

```
src/
  PLC_PRG.st           ← Main program (Declaration + Implementation)
  GVL_vars.st          ← Optional empty GVL (not required for runtime flow)
  HMI_Visualization.md ← HMI page layout instructions
README.md
```

---

## Known issues fixed from prior attempts

| Previous error | Root cause | Fix |
|---|---|---|
| `Capper : FALSE;` compiler error | Assignment written in Declaration section | Use `:=` in Implementation; use `: BOOL := FALSE;` in Declaration |
| `tFill_PT : R_TRIG` type mismatch | Wrong type pasted (R_TRIG instead of TIME) | Declare `tFill_PT : TIME := T#5s;` in PLC_PRG declaration |
| `T_State` / `DED.DEVICE_STATE` confusion | Library enum type mismatch | Use integer state constants (`S_Idle..S_Fault`) in PLC_PRG declaration |
| FB calls in Declaration section | ST code pasted into wrong editor tab | All FB calls and assignments are in PLC_PRG Implementation only |
| `No CASE label found` | STATE labels/type mismatch | Use `State : INT` + matching `VAR CONSTANT` state labels in PLC_PRG declaration |

---

## Prerequisites

1. **CODESYS V3.5** or later (tested on Control Win V3 x64).
2. **Standard library** — must be added to the project:
   - *Project → Library Manager → Add library… → search "Standard" → add*
   - This provides `TON`, `R_TRIG`, `F_TRIG` function blocks.
3. **CODESYS Control Win V3 x64** runtime (for local PC simulation).

---

## How to open / build

### 1 — Create a new CODESYS project

1. Open CODESYS → *File → New Project → Standard Project*.
2. Select device: **CODESYS Control Win V3 x64**.
3. Language: choose **Structured Text (ST)** for `PLC_PRG`.

### 2 — Add Standard library

- *Project → Library Manager → Add library… → "Standard"*

### 3 — Edit PLC_PRG (core variables now live here)

1. Open `PLC_PRG` (created automatically with the Standard Project).
2. Click the **Declaration** tab → paste the Declaration section from
   `src/PLC_PRG.st` (`VAR CONSTANT ... END_VAR` and `VAR ... END_VAR`).
3. Click the **Implementation** tab → paste the Implementation section
   from `src/PLC_PRG.st`.
4. Save (Ctrl+S).

### 4 — Assign PLC_PRG to MainTask

- *Application → Task Configuration → MainTask → Add POU Instance →
  select `PLC_PRG`* (if not already listed).
- Ensure the program instance name is `PLC_PRG` so visualization paths
  like `PLC_PRG.StartPB` resolve directly.

### 5 — Build

- *Build → Build* (Ctrl+F7).
- Expected: **0 errors, 0 warnings** (or only info-level warnings).

---

## How to run in CODESYS Control Win V3 x64

1. Start the CODESYS Control Win V3 runtime (system tray icon or
   *Tools → CODESYS Control Win V3 x64 → Start*).
2. In CODESYS IDE: *Online → Login* (Ctrl+L) → choose the running
   target → *Yes* to download.
3. *Debug → Start* (F5) to run.

---

## How to create the HMI Visualization

Follow the step-by-step instructions in `src/HMI_Visualization.md`.
In summary:

1. *Project → Add Object → Visualization → name it `HMI_Main`*.
2. Add button and indicator shapes as described in that file.
3. Link variables using the Properties panel → Input/Color animation.

---

## How to test the sequence via HMI

Run this sequence in order on the HMI page:

> Note: E-STOP latches `Fault`; after releasing E-STOP you must pulse
> **FAULT RESET** to return to `S_Idle`.

| Step | Action | Expected result |
|------|--------|-----------------|
| 1 | Click **START** | `RunLatch = TRUE`, `State → S_WaitBottle`, Conveyor ON, Green lamp ON |
| 2 | Click **BOTTLE PRESENT** | `State → S_Fill`, Fill Valve ON |
| 3 | Wait 5 s (tFill_PT) | `State → S_Cap`, Capper ON |
| 4 | Wait 2 s (tCap_PT) | `State → S_Eject`, Conveyor ON |
| 5 | Wait 3 s (tEject_PT) | `State → S_WaitBottle` (ready for next bottle) |
| 6 | Click **STOP** | `RunLatch = FALSE`, `State → S_Idle`, all outputs OFF |
| 7 | Click **E-STOP** | `Fault = TRUE`, `State → S_Fault`, Red lamp + Alarm ON |
| 8 | Release E-STOP (set `EStop=FALSE`), then click **FAULT RESET** | `Fault = FALSE`, `State → S_Idle` |
| 9 | Toggle **LOW LEVEL** | `Fault = TRUE`, `State → S_Fault` |

---

## Variable quick reference (PLC_PRG declaration)

| Variable | Type | Purpose |
|---|---|---|
| `StartPB` | BOOL | Momentary Start pushbutton |
| `StopPB` | BOOL | Stop pushbutton |
| `EStop` | BOOL | Emergency Stop (active TRUE) |
| `BottleSensor` | BOOL | Bottle present sensor |
| `LowLevel` | BOOL | Low fluid level |
| `FaultReset` | BOOL | Fault reset (momentary) |
| `ConveyorMotor` | BOOL | Conveyor output |
| `FillValve` | BOOL | Fill valve output |
| `Capper` | BOOL | Capper output |
| `AlarmBuzzer` | BOOL | Alarm output |
| `GreenLamp` | BOOL | Running indicator |
| `RedLamp` | BOOL | Fault/Stop indicator |
| `RunLatch` | BOOL | Start/Stop latch |
| `SystemEnable` | BOOL | Master enable (derived) |
| `Fault` | BOOL | Fault latch |
| `State` | INT | State machine state (`S_Idle..S_Fault`) |
| `tFill_PT` | TIME | Fill timer preset (default 5 s) |
| `tCap_PT` | TIME | Cap timer preset (default 2 s) |
| `tEject_PT` | TIME | Eject timer preset (default 3 s) |

---

## State machine overview

```
S_Idle ──[SystemEnable]──► S_WaitBottle
S_WaitBottle ──[Bottle detected]──► S_Fill
S_Fill ──[tFill done]──► S_Cap
S_Cap  ──[tCap done]──►  S_Eject
S_Eject ──[tEject done]──► S_WaitBottle  (loop)
Any state ──[Fault]──► S_Fault
S_Fault ──[Fault cleared]──► S_Idle
```

---

## Notes on declaration scope

- Runtime inputs/outputs, latches, timers, triggers, and state flags are
  declared in `PLC_PRG` Declaration (POU scope), not required from GVL.
- `src/GVL_vars.st` is intentionally optional/empty for this simple demo.
- If you rename the `PLC_PRG` task instance, update HMI bindings from
  `PLC_PRG.<Variable>` to `<NewInstance>.<Variable>`.
