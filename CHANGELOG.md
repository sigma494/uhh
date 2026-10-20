# NOVA GUI — Changelog

## 1.0.0 — 2026-10-20

Initial release.

- Immediate-mode Luau GUI library, single file, zero dependencies.
- Glassmorphism / frosted glass themes with per-element transparency
  (`bgTransparency`, `cardTransparency`, `buttonTransparency`,
  `inputTransparency`, …).
- Chromatic aberration (RGB-split) and text glow effect tokens.
- 35+ built-in themes: Glassmorphism, Frosted, Dark, Light, Amoled, Midnight,
  Slate, Mono, Graphite, Aqua, Aqua Light, Serika, Rust, Iris, Neon, Cyberpunk,
  Vaporwave, Synthwave, Terminal, Matrix, Nord, Dracula, Gruvbox, Tokyo Night,
  Catppuccin, Rose Pine, Solarized, Forest, Ocean, Sunset, Coffee, Candy, Brutal,
  Paper, Pastel, Retro95.
- Full widget catalog: Toggle, Checkbox, Slider, SliderInt, RangeSlider,
  DragNumber, NumberBox, Textbox, Dropdown, MultiSelect, RadioGroup, Segmented,
  Keybind, Mousebind, ColorPicker, ColorSwatch, Button, IconButton, Selectable,
  ListBox, Badge, ProgressBar, Separator, Spacer, SearchBox, TagInput, Tree,
  Collapsing, Table, Canvas, Plot, Custom.
- Chrome: Window, TabBar, Modal, ContextMenu, Tooltip, Notify (toast),
  CommandPalette.
- Animation engine (hover, toggle, dropdown, modal, tab) with named easings and
  `reducedMotion` support.
- Persistence: named slots, Save/Load/ClearSlots, Export/Import (JSON/Luau),
  validation & migration.
- Event bus (`On`/`Off`).
- `types.d.luau` type definitions.
- Demo harness (`demo.lua`): widget gallery, theme editor, settings panel, toast,
  context menu, Ctrl+K command palette.
- README + API reference.

## 1.0.1 — planned

- Dockable workspace with drop zones.
- Fuzzy-search command palette.
- Token inspector dev overlay.
- Audio click/hover cues.
- Virtualized ListBox/Table for 1000+ items.
