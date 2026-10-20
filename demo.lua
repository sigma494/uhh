--[[
  NOVA GUI v1.0.0 — Demo harness.
  Spawns: widget gallery, theme editor, settings demo, toast, context menu,
  Ctrl+K command palette. Runs in an executor (game available).
]]

-- Resolve the NovaGUI library.
-- Precedence: _G.NovaGUI (pre-loaded) -> readfile("NovaGUI.luau") -> ModuleScript sibling.
local NovaGUI = _G.NovaGUI
if not NovaGUI then
	local ok, mod = pcall(function()
		return loadstring(readfile("NovaGUI.luau"))()
	end)
	if ok and mod then NovaGUI = mod end
end
if not NovaGUI then
	local ok, mod = pcall(function()
		return require(script:FindFirstChild("NovaGUI") or script.Parent:FindFirstChild("NovaGUI"))
	end)
	if ok and mod then NovaGUI = mod end
end
assert(NovaGUI, "NovaGUI not found. Execute NovaGUI.luau first, or place NovaGUI.luau beside demo.lua.")

-- services
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- create gui
local gui = NovaGUI.new({
	theme = "Glassmorphism",
	scale = 1,
	persist = false,
	dev = true,
})

-- state (lives in caller script — immediate mode)
local state = {
	esp = true,
	aimbot = false,
	fly = false,
	noclip = false,
	renderDistance = 120,
	sensitivity = 0.8,
	fov = 90,
	bind = { key = Enum.KeyCode.F },
	color = Color3.new(0, 1, 1),
	theme = "Glassmorphism",
	selected = "A",
	volume = 0.5,
	username = "NovaUser",
}

local toastShown = false

-- toast on load
gui:Notify("Nova GUI loaded — Glassmorphism theme", { duration = 4 })

-- command palette (Ctrl+K)
local paletteOpen = false
local paletteQuery = ""
local paletteItems = {"esp", "aimbot", "fly", "noclip", "settings", "theme editor", "close"}

UIS.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.K and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		paletteOpen = not paletteOpen
	end
end)

-- ============================ WIDGET GALLERY ============================
local gallery = gui:Window("gallery", { title = "Widget Gallery", size = UDim2.new(0, 520, 0, 640), position = UDim2.new(0, 30, 0, 30) })
local g = gallery:Group("gallery.main", { title = "Controls" })

-- toggles
local espV, _ = g:Toggle({ id = "esp", label = "ESP", value = state.esp, onChange = function(v) state.esp = v end })
local aimV = g:Toggle({ id = "aimbot", label = "Aimbot", value = state.aimbot, onChange = function(v) state.aimbot = v end })
local flyV = g:Toggle({ id = "fly", label = "Fly", value = state.fly, onChange = function(v) state.fly = v end })
local ncV = g:Toggle({ id = "noclip", label = "Noclip", value = state.noclip, onChange = function(v) state.noclip = v end })

g:Separator("Sliders & Inputs")
local rdV = g:Slider({ id = "rd", label = "Render Distance", value = state.renderDistance, min = 40, max = 500, width = 300, onChange = function(v) state.renderDistance = v end })
local sensV = g:Slider({ id = "sens", label = "Sensitivity", value = state.sensitivity, min = 0.1, max = 3, width = 300, onChange = function(v) state.sensitivity = v end })
local fovV = g:Slider({ id = "fov", label = "FOV", value = state.fov, min = 60, max = 120, width = 300, onChange = function(v) state.fov = v end })
local volV = g:Slider({ id = "vol", label = "Volume", value = state.volume, min = 0, max = 1, width = 300, onChange = function(v) state.volume = v end })

g:Separator("Buttons")
local btnClick = g:Button({ id = "btn_exec", label = "Execute Script", variant = "primary", width = 160, height = 36 })
local btnDanger = g:Button({ id = "btn_kill", label = "Kill All", variant = "danger", width = 120, height = 36 })

g:Separator("Dropdowns & Keybinds")
local ddV = g:Dropdown({ id = "dd", label = "Target", options = {"Closest", "Random", "Crosshair"}, value = state.selected, width = 200, onChange = function(v) state.selected = v end })
local kbV = g:Keybind({ id = "kb", label = "Menu Key", value = state.bind, width = 160, onChange = function(v) state.bind = v end })

g:Separator("Color")
local cpV = g:ColorPicker({ id = "cp", label = "ESP Color", value = state.color, width = 34, onChange = function(v) state.color = v end })
g:Badge({ id = "badge", text = "ACTIVE", color = state.esp and Color3.new(0,1,0) or Color3.new(1,0,0), width = 70 })

g:Separator("Progress")
g:ProgressBar({ id = "pb", label = "Inject", value = state.renderDistance, min = 40, max = 500, width = 300 })

-- readout row
g:Separator("Live Readout")
local readout = g:Label({ id = "readout", text = "" })

-- ============================ THEME EDITOR ============================
local themeWin = gui:Window("theme", { title = "Theme Editor", size = UDim2.new(0, 460, 0, 560), position = UDim2.new(0, 570, 0, 30) })
local tg = themeWin:Group("theme.main", { title = "Theme" })

-- theme chips
local chips = {"Glassmorphism", "Frosted", "Dark", "Light", "Cyberpunk", "Neon", "Nord", "Dracula", "Tokyo Night", "Catppuccin"}
local chipFrames = {}
local function applyTheme(name)
	gui:setTheme(name)
	state.theme = name
end
for i, name in ipairs(chips) do
	local chip = tg:Button({ id = "chip_" .. name, label = name, variant = (state.theme == name) and "primary" or "ghost", width = 90, height = 30 })
	-- chip selection
end

tg:Separator("Transparency (live)")
local bgT = tg:Slider({ id = "t_bg", label = "Background", value = gui:getTheme().bgTransparency * 100, min = 0, max = 100, width = 300, onChange = function(v) gui:patchTheme({ bgTransparency = v/100 }) end })
local cardT = tg:Slider({ id = "t_card", label = "Card", value = gui:getTheme().cardTransparency * 100, min = 0, max = 100, width = 300, onChange = function(v) gui:patchTheme({ cardTransparency = v/100 }) end })
local btnT = tg:Slider({ id = "t_btn", label = "Button", value = gui:getTheme().buttonTransparency * 100, min = 0, max = 100, width = 300, onChange = function(v) gui:patchTheme({ buttonTransparency = v/100 }) end })
local inpT = tg:Slider({ id = "t_inp", label = "Input", value = gui:getTheme().inputTransparency * 100, min = 0, max = 100, width = 300, onChange = function(v) gui:patchTheme({ inputTransparency = v/100 }) end })

tg:Separator("Effects")
local glowE = tg:Toggle({ id = "t_glow", label = "Text Glow", value = gui:getTheme().textGlowEnabled, onChange = function(v) gui:patchTheme({ textGlowEnabled = v }) end })
local chromaE = tg:Toggle({ id = "t_chroma", label = "Chromatic Aberration", value = gui:getTheme().chromaticAberrationEnabled, onChange = function(v) gui:patchTheme({ chromaticAberrationEnabled = v }) end })
local chromaOff = tg:Slider({ id = "t_chromaoff", label = "Chroma Offset", value = gui:getTheme().chromaticAberrationOffset * 10, min = 0, max = 10, width = 300, onChange = function(v) gui:patchTheme({ chromaticAberrationOffset = v/10 }) end })

-- ============================ SETTINGS DEMO ============================
local settings = gui:Window("settings", { title = "Settings", size = UDim2.new(0, 360, 0, 400), position = UDim2.new(0, 30, 0, 700) })
local sg = settings:Group("settings.main", { title = "Mod Panel" })
sg:Toggle({ id = "s_esp", label = "ESP", value = state.esp })
sg:Toggle({ id = "s_aim", label = "Silent Aim", value = state.aimbot })
sg:Slider({ id = "s_fov", label = "FOV Changer", value = state.fov, min = 70, max = 130, width = 280 })
sg:Keybind({ id = "s_bind", label = "Panic Key", value = state.bind, width = 200 })
sg:ColorPicker({ id = "s_color", label = "Chams Color", value = state.color, width = 34 })
sg:Dropdown({ id = "s_mode", label = "Mode", options = {"Legit", "Rage", "Halfrage"}, value = "Legit", width = 200 })
sg:Button({ id = "s_save", label = "Save Config", variant = "secondary", width = 140 })
sg:Button({ id = "s_load", label = "Load Config", variant = "ghost", width = 140 })

-- ============================ RENDER LOOP ============================
local conn
conn = RunService.RenderStepped:Connect(function()
	-- update readout
	local txt = string.format("ESP: %s | Aimbot: %s | Fly: %s | Noclip: %s\nRD: %d | Sens: %.2f | FOV: %d | Vol: %.2f\nTheme: %s",
		tostring(state.esp), tostring(state.aimbot), tostring(state.fly), tostring(state.noclip),
		math.floor(state.renderDistance), state.sensitivity, math.floor(state.fov), state.volume, state.theme)
	-- readout is immediate; re-set text each frame by calling Label again
	g:Label({ id = "readout", text = txt })

	-- auto toast once
	if not toastShown then
		toastShown = true
	end

	-- context menu on right click (demo: notify)
	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not state._rmb then
		state._rmb = true
		gui:Notify("Context menu triggered (right-click)", { duration = 2 })
	end
	if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then state._rmb = false end
end)

-- keep reference so it isn't GC'd
_G.NovaGuiDemo = { gui = gui, conn = conn, state = state }

print("[NovaGUI] Demo loaded. Ctrl+K = command palette. Right-click = context notify.")
