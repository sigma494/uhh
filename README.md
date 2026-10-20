# NOVA GUI

Immediate-mode Luau GUI library for Roblox executors. Glassmorphism, chromatic
aberration, per-element transparency, animated, zero-dependency. Mounts to
CoreGui / PlayerGui. Spawn a fully themed control panel in one line.

## Features

- **Immediate-mode API** — call widgets each frame, they return their value.
- **Glassmorphism / frosted glass** — translucent panels, hairline borders, glow.
- **Chromatic aberration** — RGB-split text effect (toggleable per theme).
- **Per-element transparency** — backgrounds, buttons, inputs, cards, all independently
  adjustable with live preview.
- **35+ built-in themes** (Glassmorphism, Frosted, Dark, Light, Cyberpunk, Neon, Nord,
  Dracula, Tokyo Night, Catppuccin, Rose Pine, Solarized, etc.).
- **Built-in theme editor** with searchable tokens, theme chips, randomize, export/import,
  8 save slots.
- **Full widget catalog**: Toggle, Checkbox, Slider, Dropdown, ColorPicker, Textbox,
  Keybind, Badge, ProgressBar, Segmented, RadioGroup, SearchBox, NumberBox, Button,
  Table, Tree, Modal, Notify, ContextMenu, TabBar, and more.
- **Animation engine** (hover, toggle, dropdown, modal, tab) with `reducedMotion` support.
- **Persistence**: named slots, export/import (JSON/Luau), validation & migration.
- **Keyboard navigation**, focus rings, auto-clamp/auto-flip popovers.

## 60-second quickstart

```lua
local NovaGUI = loadstring(game:HttpGet("https://your.host/NovaGUI.luau"))()

local gui = NovaGUI.new({
	theme = "Glassmorphism",   -- frosted translucent panels
	persist = false,
})

local gui = NovaGUI.new({ theme = "Glassmorphism" })
local esp = false

-- immediate mode: call each frame (e.g. inside RenderStepped)
gui:Window("main", { title = "Nova" }):Group("main", {
	-- widgets return their current value every frame
}):Toggle({ id = "esp", label = "ESP", value = esp, onChange = function(v) esp = v end })

-- one-line start (complete program):
-- local NovaGUI = loadstring(game:HttpGet("..."))()
-- local gui = NovaGUI.new({ theme = 'Glassmorphism' })
-- gui:Toggle({ id = 'esp', label = 'ESP' })
```

Mount point defaults to `CoreGui` (falls back to `PlayerGui`). Every option is
optional — pass only `id` and `label` and you get a fully styled widget.

## Widget gallery

| Widget | Call | Returns |
|--------|------|---------|
| Toggle | `group:Toggle({id,label,value})` | `boolean, hovered` |
| Checkbox | `group:Checkbox({id,label,value})` | `boolean, hovered` |
| Slider | `group:Slider({id,label,value,min,max})` | `number, hovered` |
| SliderInt | `group:SliderInt(...)` | `integer` |
| RangeSlider | `group:RangeSlider(...)` | `{min,max}` |
| DragNumber | `group:DragNumber(...)` | `number` |
| NumberBox | `group:NumberBox(...)` | `number` |
| Textbox | `group:Textbox({id,text,placeholder})` | `string, changed` |
| Dropdown | `group:Dropdown({id,options,value})` | `value, open` |
| MultiSelect | `group:MultiSelect(...)` | `{string}` |
| RadioGroup | `group:RadioGroup({id,options,value})` | `value` |
| Segmented | `group:Segmented({id,options,value})` | `value` |
| Keybind | `group:Keybind({id,value})` | `{key, modifiers}` |
| Mousebind | `group:Mousebind(...)` | `{button, modifiers}` |
| ColorPicker | `group:ColorPicker({id,value})` | `Color3` |
| ColorSwatch | `group:ColorSwatch({id,value})` | `Color3` |
| Button | `group:Button({id,text,variant})` | `clicked, hovered` |
| IconButton | `group:IconButton(...)` | `clicked` |
| Selectable | `group:Selectable(...)` | `boolean` |
| ListBox | `group:ListBox(...)` | `index` |
| Badge | `group:Badge({id,text,color})` | frame |
| ProgressBar | `group:ProgressBar({id,value,min,max})` | frame |
| Separator | `group:Separator({id,text?})` | frame |
| Spacer | `group:Spacer({id,height})` | frame |
| SearchBox | `group:SearchBox({id,text})` | `string, changed` |
| TagInput | `group:TagInput(...)` | `{string}` |
| Tree | `group:Tree({id,value})` | `expanded` |
| Collapsing | `group:Collapsing(...)` | `expanded` |

All widgets support `onChange` (fires only on actual change), `width`/`height`,
`label`, and theme overrides.

## Theming guide

A theme is a flat table of ~85 tokens. Pass a name string or an inline table:

```lua
local gui = NovaGUI.new({
	theme = {
		primary = Color3.fromRGB(0, 255, 120),
		bgTransparency = 0.50,
		cardTransparency = 0.55,
		buttonTransparency = 0.30,
		inputTransparency = 0.50,
		textGlowEnabled = true,
		chromaticAberrationEnabled = true,
		chromaticAberrationOffset = 1.5,
		radius = 12,
	},
})
```

### Token reference (transparency & effects)

| Token | Purpose |
|-------|---------|
| `bg` / `bgTransparency` | Root backdrop |
| `surface` / `surfaceTransparency` | Panel surfaces |
| `card` / `cardTransparency` | Cards / containers |
| `buttonTransparency` | Buttons (independent) |
| `inputTransparency` | Inputs (independent) |
| `border` / `borderTransparency` | Hairline borders |
| `primary` / `primaryTransparency` | Accent colour |
| `glowColor` / `glowTransparency` | Neon glow |
| `textGlowEnabled` / `textGlowColor` / `textGlowIntensity` | Text glow |
| `chromaticAberrationEnabled` / `chromaticAberrationOffset` | RGB split |
| `shadowBlur` / `shadowSpread` / `shadowTransparency` | Drop shadows |
| `radius` / `radiusSm` / `radiusLg` | Corner rounding |
| `motionFast` / `motionStandard` / `motionSlow` | Animation durations |

Live-edit any token with `gui:PatchTheme({ ... })` — changes apply instantly.

### Theme editor

`gui:Window(...)` + built-in editor window (see `demo.lua`) provides:
- Theme chips (one-click switch)
- Live transparency sliders for bg / card / button / input
- Effect toggles: text glow, chromatic aberration + offset slider
- Randomize, export/import (JSON / Luau / base64), 8 save slots

## Cookbook

### Settings panel
```lua
local win = gui:Window("settings", { title = "Settings" })
local g = win:Group("settings")
g:Toggle({ id = "esp", label = "ESP", value = true })
g:Slider({ id = "fov", label = "FOV", value = 90, min = 60, max = 120 })
g:Keybind({ id = "bind", label = "Menu Key", value = { key = Enum.KeyCode.Insert } })
g:ColorPicker({ id = "color", label = "Chams", value = Color3.new(1,0,0) })
```

### Keybind menu
```lua
local bind = { key = Enum.KeyCode.F }
g:Keybind({ id = "panic", label = "Panic", value = bind,
	onChange = function(v) bind = v end })
```

### Live stats overlay
```lua
local gui = NovaGUI.new({ theme = "Mono", parent = PlayerGui })
local overlay = gui:Window("stats", { title = "Stats", size = UDim2.new(0, 220, 0, 120) })
-- inside RenderStepped:
overlay:Group("s"):Label({ id = "fps", text = "FPS: 60" })
```

## FAQ / troubleshooting

**Q: Nothing appears.**
A: Ensure `game` is available (executor context). Mount falls back CoreGui →
PlayerGui. Check developer console (F9) for errors.

**Q: Theme change has no effect.**
A: Call `gui:setTheme(name)` or `gui:patchTheme({...})`; widgets read the
active theme on each render pass.

**Q: Can I save/load configs?**
A: `gui:Save("slot1")`, `gui:Load("slot1")`, `gui:ClearSlots()`.
`gui:ExportTheme("json")` / `gui:ImportTheme(table)`.

**Q: 300+ widgets — will it lag?**
A: Dirty-flag skipping + batched updates target stable 60fps. Call `gui:Destroy()`
when done to remove all connections/instances.
