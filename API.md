# NOVA GUI — API Reference

All functions are methods on the `Gui` object returned by `NovaGUI.new(opts)`.
Every option is optional; unknown/invalid options fall back to theme defaults.

## GLOBAL ENTRY

### `NovaGUI.new(options?) -> Gui`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | `string \| table` | `"Glassmorphism"` | Built-in theme name or inline theme table |
| `parent` | `Instance` | `CoreGui` (fallback `PlayerGui`) | Mount point |
| `scale` | `number` | `1` | UI scale 0.5–2.0 |
| `accent` | `Color3` | theme primary | Shortcut primary colour |
| `persist` | `boolean` | `true` | Autosave theme/widget values |
| `persistKey` | `string` | `"nova"` | Save namespace |
| `reducedMotion` | `boolean \| string` | `false` | Disable non-essential animation |
| `dev` | `boolean` | `false` | Token inspector + debug outlines |

Example:
```lua
local gui = NovaGUI.new({ theme = "Cyberpunk", persist = true, dev = true })
```

## GUI OBJECT

### `gui:Window(id, options?) -> Window`
Create a draggable, closable window. Returns a `Window` (also usable as a `Group`).
Window options support `title`, `size` (`UDim2`), `position` (`UDim2`), `visible`,
`collapsible`, `closable`, `draggable`, `resizable`, `snapToEdges`, `minSize`,
`scrollable`, `onClose`.

### `gui:TabBar(id, options?) -> active`
Tab bar with animated indicator. Options: `tabs` (`{string}`), `active`, `onChange`.

### `gui:Notify(text, options?)`
Toast notification. Options: `duration` (default 4).

### `gui:Modal(id, options?) -> Group`
Backdrop-blur modal (scale-in). Returns a Group for content.

### `gui:ContextMenu(id, options?) -> Group`
Right-click context menu.

### `gui:Tooltip(text, anchor)`
Hover tooltip anchored to an instance.

### `gui:SetTheme(theme) -> Gui`
Set theme by name string or inline table.

### `gui:GetTheme() -> table`
Returns a deep copy of the active theme.

### `gui:PatchTheme(partialTheme) -> Gui`
Merge partial tokens into the active theme (live preview).

### `gui:ResetTheme() -> Gui`
Restore built-in defaults.

### `gui:ExportTheme(format?) -> string`
`"lua"` (default) or `"json"`.

### `gui:ImportTheme(spec) -> Gui`
Import a theme table or JSON string. Unknown keys ignored, bad types coerced.

### `gui:Save(slot?) / gui:Load(slot?) / gui:ClearSlots()`
Named save slots with metadata + timestamp.

### `gui:SetScale(n) -> Gui` / `gui:Destroy() -> Gui`
Scale 0.5–2.0 / remove all listeners, connections, instances.

### `gui:On(event, handler) -> Gui` / `gui:Off(event, handler) -> Gui`
Event bus (e.g. `"themeChanged"`).

## WINDOW / GROUP

Windows and Groups expose the same widget methods. Group options support
`title`, `width`, `height`, `position`, `parent`.

### Widget signature
Every widget: `group:Widget({ id, label, value, width, height, onChange, ... })`
→ returns current value (plus `hovered`/`changed`/`open` where applicable).
`onChange` fires only on actual change.

### Input widgets

| Method | Returns | Notes |
|--------|---------|-------|
| `Toggle({id,label,value,width,height})` | `boolean, hovered` | Pill switch, Space/Enter |
| `Checkbox({id,label,value,size})` | `boolean, hovered` | Indeterminate supported |
| `Slider({id,label,value,min,max,width})` | `number, hovered` | Wheel, click-jump |
| `SliderInt(...)` | `integer` | Integer formatting |
| `RangeSlider({id,value={min,max}})` | `{number}` | Two thumbs |
| `DragNumber({id,value,step})` | `number` | Click-drag scrub |
| `NumberBox({id,value,min,max,step})` | `number` | Spinner arrows |
| `Textbox({id,text,placeholder,width})` | `string, changed` | Caret, selection |
| `Dropdown({id,options,value,width})` | `value, open` | Type-to-filter |
| `MultiSelect(...)` | `{string}` | Summary text |
| `RadioGroup({id,options,value})` | `value` | Roving arrow nav |
| `Segmented({id,options,value})` | `value` | Sliding indicator |
| `Keybind({id,value,width})` | `{key, modifiers}` | Listening state |
| `Mousebind({id,value})` | `{button, modifiers}` | Mouse button bind |
| `ColorPicker({id,value})` | `Color3` | Full HSV picker popover |
| `ColorSwatch({id,value})` | `Color3` | Opens picker |
| `SearchBox({id,text,width})` | `string, changed` | Live filter |
| `TagInput({id,value})` | `{string}` | Chips with X |

### Buttons

| Method | Returns |
|--------|---------|
| `Button({id,text,variant,width,height})` | `clicked, hovered` |
| `IconButton({id,icon})` | `clicked` |
| `ButtonRow({id,options})` | `index, clicked` |
| `SplitButton(...)`, `HoldButton`, `RepeatButton`, `LinkButton` |

Variants: `primary`, `secondary`, `ghost`, `outline`, `danger`, `success`.

### Display

| Method | Returns |
|--------|---------|
| `Label({id,text,size,color,transparency})` | frame |
| `Badge({id,text,color,width,height})` | frame |
| `ProgressBar({id,value,min,max,width})` | frame |
| `Separator({id,text?})` | frame |
| `Spacer({id,height})` | frame |
| `Spinner({id,style})` | frame (3 styles) |

### Containers & chrome

`Window`, `TabBar`, `Group`, `Modal`, `Popover`, `ScrollArea`, `Columns`,
`Tooltip`, `Toast`, `CommandPalette`.

## TYPE DEFINITIONS

See `types.d.luau` for full `export type` definitions (`Gui`, `Window`, `Group`,
`WidgetOpts`, `Theme`, `Themes`).

## EVENTS

- `themeChanged(theme)` — fired after `SetTheme`/`PatchTheme`.
- `widgetChanged(id, value)` — fired when any widget's `onChange` triggers.

## ERROR HANDLING

Bad options never throw. Unknown theme → `DEFAULT_THEME`. Missing label → `id`.
Corrupt saved config → defaults. All `Instance` property sets are `pcall`-guarded.
