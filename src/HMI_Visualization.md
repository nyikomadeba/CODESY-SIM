# HMI Visualization Page — CODESY-SIM

Step-by-step instructions for creating the HMI (Visualization) page in CODESYS.

> Variable paths below assume MainTask runs the program instance named `PLC_PRG`.
> If you rename the task POU instance, update bindings to `<YourInstance>.VariableName`.

**How to create in CODESYS:**
> *Project → Add Object → Visualization → name it `HMI_Main`*  
> Add the elements below using the Visualization Toolbox.

---

## Page title

**CODESY-SIM — Bottle Filling Station**

---

## Section 1: Control Buttons (top-left area)

Each button is a Rectangle or Button shape with a Toggle/Tap action.

### 1. START Button
- Shape: Rectangle (green fill)
- Label: **START**
- OnMouseClick → Toggle variable: `PLC_PRG.StartPB`
  *(Tap action recommended: TRUE on press, FALSE on release — simulates momentary pushbutton)*
- Color animation → `PLC_PRG.RunLatch`
  - TRUE  → bright green `#00FF00`
  - FALSE → dark green   `#006600`

### 2. STOP Button
- Shape: Rectangle (red fill)
- Label: **STOP**
- OnMouseClick → Toggle variable: `PLC_PRG.StopPB`

### 3. E-STOP Button
- Shape: Rectangle (orange/red fill)
- Label: **E-STOP**
- OnMouseClick → Toggle variable: `PLC_PRG.EStop`
- Color animation → `PLC_PRG.EStop`
  - TRUE  → bright red `#FF0000`
  - FALSE → grey       `#888888`

### 4. FAULT RESET Button
- Shape: Rectangle (yellow fill)
- Label: **FAULT RESET**
- Use momentary action on `PLC_PRG.FaultReset`:
  - MouseDown: Write `TRUE`
  - MouseUp: Write `FALSE`

---

## Section 2: Sensor Input Simulation (top-right area)

### 5. BOTTLE SENSOR Button
- Shape: Rectangle (blue fill)
- Label: **BOTTLE PRESENT**
- OnMouseClick → Toggle variable: `PLC_PRG.BottleSensor`
- Color animation → `PLC_PRG.BottleSensor`
  - TRUE  → bright blue `#0000FF`
  - FALSE → grey        `#888888`

### 6. LOW LEVEL Button
- Shape: Rectangle
- Label: **LOW LEVEL**
- OnMouseClick → Toggle variable: `PLC_PRG.LowLevel`
- Color animation → `PLC_PRG.LowLevel`
  - TRUE  → orange `#FF8800`
  - FALSE → grey   `#888888`

---

## Section 3: Output Status Indicators (middle area)

Read-only indicator rectangles or circles:

| # | Label | Variable | ON colour | OFF colour |
|---|-------|----------|-----------|------------|
| 7 | CONVEYOR | `PLC_PRG.ConveyorMotor` | `#00CC00` green | `#AAAAAA` grey |
| 8 | FILL VALVE | `PLC_PRG.FillValve` | `#0099FF` blue | `#AAAAAA` grey |
| 9 | CAPPER | `PLC_PRG.Capper` | `#FFFF00` yellow | `#AAAAAA` grey |
| 10 | ALARM | `PLC_PRG.AlarmBuzzer` | `#FF0000` red | `#AAAAAA` grey |
| 11 | RUN LAMP | `PLC_PRG.GreenLamp` | `#00FF00` green | `#AAAAAA` grey |
| 12 | FAULT LAMP | `PLC_PRG.RedLamp` | `#FF0000` red | `#AAAAAA` grey |

---

## Section 4: State Machine Status (bottom area)

### 13. STATE display
- Shape: Rectangle (text box)
- Text variable output: `PLC_PRG.State`
  *(State is an INT; use a text list/expression if you want names.)*
- Color animation by integer value:

| Value | State name | Colour |
|-------|-----------|--------|
| 0 | S_Idle | `#AAAAAA` grey |
| 1 | S_WaitBottle | `#0088FF` blue |
| 2 | S_Fill | `#00FFFF` cyan |
| 3 | S_Cap | `#FFFF00` yellow |
| 4 | S_Eject | `#00FF00` green |
| 5 | S_Fault | `#FF0000` red |

### 14. SYSTEM ENABLE indicator
- Label: **SYSTEM ENABLE**
- Color animation → `PLC_PRG.SystemEnable`
  - TRUE  → green `#00CC00`
  - FALSE → grey  `#AAAAAA`

---

## Section 5: Animated Bottle (optional, centre area)

A simple rectangle representing the bottle:

| State | Fill colour |
|-------|-------------|
| S_Idle / S_WaitBottle | `#FFFFFF` white |
| S_Fill | `#AADDFF` light blue (filling) |
| S_Cap | `#FFFF88` light yellow (capping) |
| S_Eject | `#AAFFAA` light green (ejecting) |
| S_Fault | `#FFAAAA` light red (fault) |

---

## How to set a color animation in CODESYS Visualization

1. Select the shape on the HMI canvas.
2. Properties panel → expand **Color** → **Fill Color**.
3. Click **`...`** next to "Color" to open the Color animation dialog.
4. Enable **"Use expression"**.
5. Enter the variable path, e.g. `PLC_PRG.ConveyorMotor`.
6. Add colour entries:
   - Value `TRUE` → choose green
   - Value `FALSE` → choose grey
7. For enum/integer variables (like `State`), add one entry per integer
   value (0 = S_Idle, 1 = S_WaitBottle, …) with different colours.

## How to set a button tap action in CODESYS Visualization

1. Select the button shape.
2. Properties → **Input Configuration** → **OnMouseClick**.
3. Action: **"Toggle variable"** → enter path, e.g. `PLC_PRG.StartPB`.
4. For momentary simulation use **"Write value"** with value `TRUE` on
   MouseDown and `FALSE` on MouseUp (two separate actions).
