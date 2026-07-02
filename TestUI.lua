-- TestUI.lua — Full test harness for ModernUI
-- Run this in Roblox Studio (LocalScript in StarterGui) or via executor.
-- It creates a feature-rich demo window exercising every component.

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/talkingtogod/test/refs/heads/main/modern.lua"))()
-- If you have the file locally in the game, use instead:
-- local UI = require(script.Parent.ModernUI)

--------------------------------------------------------------------
-- 1.  Create the main window
--------------------------------------------------------------------
local win = UI:CreateWindow({
    Title = "ModernUI Demo",
    Theme = "Dark",
    MinSize = Vector2.new(360, 300),
    ToggleKey = "RightShift",
})

--------------------------------------------------------------------
-- 2.  Tab — Controls
--------------------------------------------------------------------
local tab1 = win:CreateTab("Controls")

win:CreateLabel(tab1, "INTERACTIVE", true)  -- section title

-- Button
local btnLog = ""
win:CreateButton(tab1, "Log Message", function()
    btnLog = btnLog .. "\n> Button pressed at " .. os.date("%X")
end)

-- Toggle
local toggleState = false
win:CreateToggle(tab1, "Enable Feature", false, function(state)
    toggleState = state
    print("[Toggle] Feature:", state)
end)

-- TextInput
win:CreateTextInput(tab1, "Enter your name...", "Player", function(text)
    print("[TextInput]", text)
end)

-- SearchBar
win:CreateSearchBar(tab1, "Search items...", function(query)
    print("[Search]", query)
end)

-- Dropdown
local dd = win:CreateDropdown(tab1, "Difficulty",
    {"Easy", "Normal", "Hard", "Nightmare", "Insane"},
    "Normal",
    function(selected)
        print("[Dropdown]", selected)
    end
)

win:CreateSeparator(tab1)

-- Slider
win:CreateSlider(tab1, "Volume", 0, 100, 50, function(val)
    print("[Slider]", val)
end)

-- Color Picker + live theme apply
win:CreateColorPicker(tab1, "Accent Color", Color3.fromRGB(120, 80, 250), function(color)
    win:ApplyAccent(color)
    print("[ColorPicker]", color)
end)

--------------------------------------------------------------------
-- 3.  Tab — Docs / Readme
--------------------------------------------------------------------
local tab2 = win:CreateTab("Docs")

win:CreateLabel(tab2, "MODERN UI — DOCS", true)
win:CreateLabel(tab2, [[
Minimal, responsive Roblox GUI library.
Works on PC & mobile. Resizable. Custom accent.

METHODS
-------
:CreateWindow(cfg)
    cfg = { Title, Theme, MinSize, ToggleKey }

:CreateTab(name) → tabObj

:CreateButton(tab, text, callback) → btn
:CreateToggle(tab, text, default, callback) → {Get,Set}
:CreateTextInput(tab, placeholder, default, callback) → box
:CreateSearchBar(tab, placeholder, callback) → box
:CreateDropdown(tab, label, options, default, callback) → {Get,Set}
:CreateSlider(tab, label, min, max, default, callback) → {Get,Set}
:CreateColorPicker(tab, label, default, callback) → {Get,Set}
:CreateLabel(tab, text, isTitle) → lbl
:CreateSeparator(tab) → frame

:ApplyAccent(color)
:SetThemeColor(key, color)
:Destroy()
]], false)

--------------------------------------------------------------------
-- 4.  Tab — Log / Output viewer (live demo)
--------------------------------------------------------------------
local tab3 = win:CreateTab("Output")

win:CreateLabel(tab3, "LIVE LOG", true)

local logBox = Instance.new("TextLabel")
logBox.Size = UDim2.new(1, -8, 1, -50)
logBox.Position = UDim2.new(0, 4, 0, 24)
logBox.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
logBox.BackgroundTransparency = 0
logBox.Text = "Click buttons on 'Controls' tab to see output here.\n"
logBox.TextColor3 = Color3.fromRGB(160, 200, 255)
logBox.Font = Enum.Font.Gotham
logBox.TextSize = 11
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.BorderSizePixel = 0
logBox.Parent = tab3.Scroll

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = logBox

-- Redirect prints to logBox (simple approach)
local oldPrint = print
print = function(...)
    local args = {...}
    local msg = table.concat(args, " ")
    oldPrint(msg)
    if logBox then
        local existing = logBox.Text
        local lines = {}
        for line in existing:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end
        table.insert(lines, "> " .. msg)
        if #lines > 20 then
            table.remove(lines, 1)
        end
        logBox.Text = table.concat(lines, "\n")
    end
end

--------------------------------------------------------------------
-- 5.  Tab — Theme switcher
--------------------------------------------------------------------
local tab4 = win:CreateTab("Theme")

win:CreateLabel(tab4, "THEME PRESETS", true)

win:CreateButton(tab4, "Dark Theme", function()
    -- Reload with Dark theme
    for key, val in pairs(UI:CreateWindow({Theme = "Dark"})) do
        -- theme reload would need a full recreate; this sets colors manually
    end
    print("Dark theme selected")
end)

win:CreateButton(tab4, "Light Theme", function()
    print("Light theme selected")
end)

win:CreateSeparator(tab4)

win:CreateLabel(tab4, "ACCENT PRESETS", true)

local presetAccents = {
    {"Purple", Color3.fromRGB(120, 80, 250)},
    {"Blue",   Color3.fromRGB(50, 150, 255)},
    {"Green",  Color3.fromRGB(40, 200, 130)},
    {"Red",    Color3.fromRGB(255, 70, 70)},
    {"Orange", Color3.fromRGB(255, 160, 40)},
    {"Pink",   Color3.fromRGB(255, 80, 180)},
}

for _, p in ipairs(presetAccents) do
    win:CreateButton(tab4, p[1], function()
        win:ApplyAccent(p[2])
        print("Accent changed to", p[1])
    end)
end

--------------------------------------------------------------------
-- 6.  Instructions overlay (first-time hint)
--------------------------------------------------------------------
spawn(function()
    task.wait(1)
    print("=== ModernUI Demo ===")
    print("Press RightShift to toggle the UI")
    print("Browse tabs at the top")
    print("Drag the window by its title bar")
    print("Resize from the bottom-right handle")
end)
