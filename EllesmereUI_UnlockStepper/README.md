# EllesmereUI Unlock Stepper

A small companion addon for **[EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui)** that adds **`-` / `+` stepper buttons** to the number fields in the Unlock Mode cog menu. You can move and resize elements one pixel at a time without dragging them with the mouse or calculating coordinates.

```
Width        [-] [ 450 ] [+]
Height       [-] [  40 ] [+]
X Position   [-] [   0 ] [+]
Y Position   [-] [-480 ] [+]
Offset X     [-] [   0 ] [+]
Offset Y     [-] [   2 ] [+]
```

## Why

In Unlock Mode, dragging a bar along one axis usually moves it slightly on the other axis too. Typing exact X/Y values works, but anchored bars make you account for the height of the bar above them. With the stepper buttons you click until the element is where you want it, and only the axis you touch changes.

## Features

- `-` / `+` buttons on every number field in the cog menu:
  **Width, Height, X Position, Y Position, Offset X, Offset Y, Extra Width, Extra Height**
- **Click:** ±1 px
- **Shift + Click:** ±10 px
- **Hold:** repeats continuously
- **Mouse wheel** over a field: ±1 px (Shift: ±10)
- Hover color follows EllesmereUI's **UI Accent Color**
- Works on every Unlock Mode element, not only action bars

## How it works

A step writes the new value into the field and runs that field's own *Enter* handler. The change goes through EllesmereUI's own code path, the same as typing a number and pressing Enter. That includes the pixel-exact nudge, the anchor chains, width/height matching and pending saves. The addon does no position math of its own.

- Width/Height fields that are **matched** to another element stay locked, and their buttons are greyed out.
- The buttons do nothing **in combat**, the same as the fields themselves.

## Requirements

- **EllesmereUI** (tested with 9.5.x)
- Interface: `120000–120105`, `16001` (WoW Forever)

## Installation

1. Download or clone this repository.
2. Copy the `EllesmereUI_UnlockStepper` folder into
   `World of Warcraft\<game version>\Interface\AddOns\`
3. Make sure the folder contains `EllesmereUI_UnlockStepper.toc` and `UnlockStepper.lua` directly, not inside another subfolder.
4. Restart the game or type `/reload`.

## Usage

1. Open EllesmereUI **Unlock Mode**.
2. Select an element and open its **cog menu**.
3. Use the `-` / `+` buttons next to any value.

## Compatibility notes

The addon attaches to EllesmereUI's Unlock Mode menu without modifying any EllesmereUI files. It relies on a few internal names: the `EllesmereUnlockMode` overlay frame, plus the cog menu's `_hintFS`, `_pool.fields` and `_box`. If a future EllesmereUI update renames these, the buttons stop appearing, but nothing breaks. Please open an issue if that happens.

## Files

| File | Purpose |
|---|---|
| `EllesmereUI_UnlockStepper.toc` | Addon metadata |
| `UnlockStepper.lua` | All logic |

## Credits

- **EllesmereUI** by Ellesmere. This is an unofficial add-on and is not affiliated with the EllesmereUI project.
