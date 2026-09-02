# CODESY-SIM — Bottle-Filling PLC (Ladder / ST) + HMI Simulation

A beginner-friendly CODESYS project that implements a bottle-filling
station using Structured Text (equivalent to Ladder Diagram logic),
with a simple HMI Visualization page for simulation.

---

## Repository layout

```
src/
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

## How to open / build

### 1 — Create a new CODESYS project

1. Open CODESYS → *File → New Project → Standard Project*.
2. Select device: **CODESYS Control Win V3 x64**.
3. Language: choose **Structured Text (ST)** for `PLC_PRG`.

### 2 — Add Standard library

- *Project → Library Manager → Add library… → "Standard"*

### 3 — Create the Global Variable List

1. *Project → Add Object → Global Variable List → name it `GVL_vars`*.
2. Open `GVL_vars` in the editor (Declaration area).
3. **Replace** the entire content with the text from `src/GVL_vars.st`.
4. Save (Ctrl+S).

### 4 — Edit PLC_PRG

1. Open `PLC_PRG` (created automatically with the Standard Project).
2. Click the **Declaration** tab → ensure it contains only:
   ```pascal
   VAR
   END_VAR
   ```
3. Click the **Implementation** tab → **replace** all content with
   the text from `src/PLC_PRG.st` (paste everything after the header
   comment — i.e. from `(* Step 1 *)` onwards).
4. Save (Ctrl+S).

### 5 — Assign PLC_PRG to MainTask

- *Application → Task Configuration → MainTask → Add POU Instance →
  select `PLC_PRG`* (if not already listed).

### 6 — Build

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

## Variable quick reference

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
| `State` | T_State | State machine state |
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
