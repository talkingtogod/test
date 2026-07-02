-- ModernUI.lua — Roblox UI Library
-- Minimal, responsive, resizable, PC + mobile
-- Usage: local UI = loadstring(game:HttpGet("url"))()
--        local window = UI:CreateWindow({Title = "My GUI"})

local ModernUI = {}
ModernUI.__index = ModernUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Color utilities
local function hex2rgb(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255)
end

local function rgb2hex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- Default theme
local Themes = {
    Dark = {
        BG = Color3.fromRGB(10, 10, 18),
        Surface = Color3.fromRGB(16, 16, 28),
        Panel = Color3.fromRGB(22, 22, 36),
        Card = Color3.fromRGB(28, 28, 46),
        CardHover = Color3.fromRGB(36, 36, 58),
        Accent = Color3.fromRGB(120, 80, 250),
        AccentLight = Color3.fromRGB(155, 125, 255),
        AccentDim = Color3.fromRGB(40, 25, 90),
        TextPri = Color3.fromRGB(240, 240, 252),
        TextSec = Color3.fromRGB(160, 160, 190),
        TextMuted = Color3.fromRGB(95, 95, 125),
        Border = Color3.fromRGB(32, 32, 55),
        Success = Color3.fromRGB(20, 200, 130),
        Warning = Color3.fromRGB(255, 175, 55),
        Danger = Color3.fromRGB(255, 70, 70),
        InputBG = Color3.fromRGB(16, 16, 28),
    },
    Light = {
        BG = Color3.fromRGB(245, 245, 250),
        Surface = Color3.fromRGB(235, 235, 242),
        Panel = Color3.fromRGB(225, 225, 235),
        Card = Color3.fromRGB(215, 215, 228),
        CardHover = Color3.fromRGB(200, 200, 218),
        Accent = Color3.fromRGB(100, 60, 230),
        AccentLight = Color3.fromRGB(130, 100, 240),
        AccentDim = Color3.fromRGB(200, 180, 255),
        TextPri = Color3.fromRGB(15, 15, 25),
        TextSec = Color3.fromRGB(80, 80, 110),
        TextMuted = Color3.fromRGB(140, 140, 170),
        Border = Color3.fromRGB(200, 200, 215),
        Success = Color3.fromRGB(20, 170, 110),
        Warning = Color3.fromRGB(220, 150, 40),
        Danger = Color3.fromRGB(220, 50, 50),
        InputBG = Color3.fromRGB(235, 235, 242),
    }
}

local function applyTheme(theme)
    return {
        BG = theme.BG,
        Surface = theme.Surface,
        Panel = theme.Panel,
        Card = theme.Card,
        CardHover = theme.CardHover,
        Accent = theme.Accent,
        AccentLight = theme.AccentLight,
        AccentDim = theme.AccentDim,
        TextPri = theme.TextPri,
        TextSec = theme.TextSec,
        TextMuted = theme.TextMuted,
        Border = theme.Border,
        Success = theme.Success,
        Warning = theme.Warning,
        Danger = theme.Danger,
        InputBG = theme.InputBG,
    }
end

local function tween(obj, props, dur, style, dir)
    local ti = TweenInfo.new(dur or 0.2, Enum.EasingStyle[style or "Quad"], Enum.EasingDirection[dir or "Out"])
    local t = TweenService:Create(obj, ti, props)
    t:Play()
    return t
end

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = obj
    return c
end

local function addStroke(obj, color, thickness, transp)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(32, 32, 55)
    s.Thickness = thickness or 0.5
    s.Transparency = transp or 0.6
    s.Parent = obj
    return s
end

-- Create a ScrollingFrame with proper configuration
local function createScrollingFrame(parent, size, pos)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = size or UDim2.new(1, 0, 1, 0)
    sf.Position = pos or UDim2.new(0, 0, 0, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = Color3.fromRGB(95, 95, 125)
    sf.ClipsDescendants = true
    sf.Parent = parent
    return sf
end

--------------------------------------------------------------------
-- Window
--------------------------------------------------------------------
function ModernUI:CreateWindow(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, ModernUI)

    self.Theme = applyTheme(Themes[cfg.Theme] or Themes.Dark)
    self.Title = cfg.Title or "UI"
    self.MinSize = cfg.MinSize or Vector2.new(320, 240)
    self.Size = cfg.Size or UDim2.new(0, 500, 0, 400)
    self.Keybind = cfg.Keybind or Enum.KeyCode.LeftControl
    self.ToggleKey = cfg.ToggleKey or "RightShift"

    self.Tabs = {}
    self.ActiveTab = nil
    self.Components = {}

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ModernUI_" .. self.Title:gsub("%s+", "")
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main frame
    local main = Instance.new("Frame")
    main.Size = self.Size
    main.Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2)
    main.BackgroundColor3 = self.Theme.BG
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.Parent = gui
    addCorner(main, 12)
    addStroke(main, self.Theme.AccentDim, 1.5, 0.4)
    self.Main = main
    self.GUI = gui

    -- Mobile close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 6)
    closeBtn.BackgroundColor3 = self.Theme.Card
    closeBtn.Text = "X"
    closeBtn.TextColor3 = self.Theme.TextSec
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.AutoButtonColor = false
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = main
    addCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = not gui.Enabled end)

    -- Toggle binding
    local function onToggle()
        gui.Enabled = not gui.Enabled
    end

    local inputCon
    inputCon = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode[self.ToggleKey] then
            onToggle()
        end
    end)

    -- Dragging
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Resizing
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    resizeHandle.BackgroundColor3 = self.Theme.Accent
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Text = ""
    resizeHandle.AutoButtonColor = false
    resizeHandle.Parent = main
    addCorner(resizeHandle, 4)

    local resizing, resizeStart, resizeStartSize
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = Vector2.new(input.Position.X, input.Position.Y)
            resizeStartSize = main.Size
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - resizeStart
            local newW = math.max(self.MinSize.X, resizeStartSize.X.Offset + delta.X)
            local newH = math.max(self.MinSize.Y, resizeStartSize.Y.Offset + delta.Y)
            main.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    addCorner(titleBar, 12)

    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 22)
    titleCover.Position = UDim2.new(0, 0, 0, 18)
    titleCover.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = self.Theme.AccentLight
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -12, 0, 32)
    tabBar.Position = UDim2.new(0, 6, 0, 44)
    tabBar.BackgroundColor3 = self.Theme.Surface
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    addCorner(tabBar, 8)

    local tabList = Instance.new("Frame")
    tabList.Size = UDim2.new(1, -4, 1, -4)
    tabList.Position = UDim2.new(0, 2, 0, 2)
    tabList.BackgroundTransparency = 1
    tabList.Parent = tabBar

    self.TabBar = tabBar
    self.TabList = tabList
    self.TabContainer = main

    self.TabButtons = {}

    -- Content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -12, 1, -82)
    content.Position = UDim2.new(0, 6, 0, 78)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = main
    self.Content = content

    self.Destroy = function()
        inputCon:Disconnect()
        gui:Destroy()
    end

    return self
end

--------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------
function ModernUI:CreateTab(name)
    local tabObj = {}
    tabObj.Name = name
    tabObj.Elements = {}
    tabObj.ScrollingFrames = {}

    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, -4)
    btn.Position = UDim2.new(0, 2 + (#self.TabButtons) * 102, 0, 2)
    btn.BackgroundColor3 = self.Theme.Surface
    btn.Text = name
    btn.TextColor3 = self.Theme.TextMuted
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = self.TabList
    addCorner(btn, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0.6, 0, 0, 3)
    indicator.Position = UDim2.new(0.2, 0, 1, -1)
    indicator.BackgroundColor3 = self.Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn
    addCorner(indicator, 2)

    tabObj.Button = btn
    tabObj.Indicator = indicator

    -- Tab content frame
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    tabContent.Parent = self.Content
    tabObj.Content = tabContent

    -- ScrollingFrame for this tab
    local sf = createScrollingFrame(tabContent, UDim2.new(1, 0, 1, 0))
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = sf

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = sf

    tabObj.Scroll = sf

    -- Button hover
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObj then
            tween(btn, {BackgroundColor3 = self.Theme.Card})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObj then
            tween(btn, {BackgroundColor3 = self.Theme.Surface})
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tabObj)
    end)

    table.insert(self.Tabs, tabObj)
    self.TabButtons[name] = btn

    -- Select first tab by default
    if #self.Tabs == 1 then
        self:SelectTab(tabObj)
    end

    return tabObj
end

function ModernUI:SelectTab(tab)
    if self.ActiveTab then
        self.ActiveTab.Content.Visible = false
        tween(self.ActiveTab.Button, {BackgroundColor3 = self.Theme.Surface, TextColor3 = self.Theme.TextMuted})
        self.ActiveTab.Indicator.Visible = false
    end
    self.ActiveTab = tab
    tab.Content.Visible = true
    tween(tab.Button, {BackgroundColor3 = self.Theme.AccentDim, TextColor3 = Color3.fromRGB(255, 255, 255)})
    tab.Indicator.Visible = true
end

--------------------------------------------------------------------
-- Elements
--------------------------------------------------------------------
local function createSection(tab, title)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 24)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = tab.Parent.Parent.Parent.Parent.Parent.Theme.AccentLight
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    table.insert(tab.Elements, frame)
    return frame
end

--------------------------------------------------------------------
-- Section
--------------------------------------------------------------------
function ModernUI:CreateSection(tab, name)
    return createSection(tab, name)
end

--------------------------------------------------------------------
-- Button
--------------------------------------------------------------------
function ModernUI:CreateButton(tab, text, callback)
    callback = callback or function() end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 34)
    frame.BackgroundColor3 = self.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = self.Theme.TextPri
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = frame

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 0, 20)
    accent.Position = UDim2.new(0, 8, 0.5, -10)
    accent.BackgroundColor3 = self.Theme.Accent
    accent.BorderSizePixel = 0
    accent.Parent = frame
    addCorner(accent, 2)

    btn.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.CardHover})
    end)
    btn.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    btn.MouseButton1Click:Connect(callback)

    return btn
end

--------------------------------------------------------------------
-- Toggle
--------------------------------------------------------------------
function ModernUI:CreateToggle(tab, text, default, callback)
    callback = callback or function() end
    local state = default or false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -58, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local toggleBG = Instance.new("Frame")
    toggleBG.Size = UDim2.new(0, 44, 0, 24)
    toggleBG.Position = UDim2.new(1, -52, 0.5, -12)
    toggleBG.BackgroundColor3 = state and self.Theme.Accent or Color3.fromRGB(60, 60, 80)
    toggleBG.BorderSizePixel = 0
    toggleBG.Parent = frame
    addCorner(toggleBG, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBG
    addCorner(knob, 9)

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Parent = frame

    local function setState(newState)
        state = newState
        tween(toggleBG, {BackgroundColor3 = state and self.Theme.Accent or Color3.fromRGB(60, 60, 80)})
        tween(knob, {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)})
        callback(state)
    end

    clickArea.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Surface})
    end)

    local obj = {}
    obj.Set = setState
    obj.Get = function() return state end
    obj.Frame = frame
    return obj
end

--------------------------------------------------------------------
-- TextInput
--------------------------------------------------------------------
function ModernUI:CreateTextInput(tab, placeholder, default, callback)
    callback = callback or function() end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)
    addStroke(frame, self.Theme.Border, 0.5, 0.6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.TextColor3 = self.Theme.TextPri
    box.PlaceholderText = placeholder or "Enter text..."
    box.PlaceholderColor3 = self.Theme.TextMuted
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = frame

    if default then
        box.Text = default
    end

    box.FocusLost:Connect(function(enter)
        if enter then
            callback(box.Text)
        end
    end)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        callback(box.Text)
    end)

    return box
end

--------------------------------------------------------------------
-- SearchBar
--------------------------------------------------------------------
function ModernUI:CreateSearchBar(tab, placeholder, callback)
    callback = callback or function() end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)
    addStroke(frame, self.Theme.AccentDim, 1, 0.5)

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 28, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = self.Theme.TextMuted
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.TextSize = 13
    searchIcon.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -32, 1, 0)
    box.Position = UDim2.new(0, 28, 0, 0)
    box.BackgroundTransparency = 1
    box.TextColor3 = self.Theme.TextPri
    box.PlaceholderText = placeholder or "Search..."
    box.PlaceholderColor3 = self.Theme.TextMuted
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = frame

    box:GetPropertyChangedSignal("Text"):Connect(function()
        callback(box.Text)
    end)

    return box
end

--------------------------------------------------------------------
-- Dropdown
--------------------------------------------------------------------
function ModernUI:CreateDropdown(tab, text, options, default, callback)
    callback = callback or function() end
    local selected = default or (options[1] or "")
    local open = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    frame.ClipsDescendants = false
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. selected
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = self.Theme.TextSec
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 12
    arrow.Parent = frame

    local dropdownList = Instance.new("Frame")
    dropdownList.Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 28 + 4)
    dropdownList.Position = UDim2.new(0, 0, 1, 4)
    dropdownList.BackgroundColor3 = self.Theme.Panel
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    dropdownList.Parent = frame
    addCorner(dropdownList, 8)
    addStroke(dropdownList, self.Theme.Border, 0.5, 0.5)

    local dropdownScroll = createScrollingFrame(dropdownList, UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2))
    dropdownScroll.ZIndex = 10
    dropdownScroll.ScrollBarThickness = 3

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = dropdownScroll

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = self.Theme.Panel
        optBtn.Text = opt
        optBtn.TextColor3 = self.Theme.TextSec
        optBtn.Font = Enum.Font.GothamSemibold
        optBtn.TextSize = 11
        optBtn.AutoButtonColor = false
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 11
        optBtn.Parent = dropdownScroll
        addCorner(optBtn, 4)

        optBtn.MouseEnter:Connect(function()
            tween(optBtn, {BackgroundColor3 = self.Theme.Card})
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, {BackgroundColor3 = self.Theme.Panel})
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            lbl.Text = text .. ": " .. selected
            dropdownList.Visible = false
            open = false
            callback(selected)
        end)
    end

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Parent = frame

    clickArea.MouseButton1Click:Connect(function()
        open = not open
        dropdownList.Visible = open
        dropdownList.ZIndex = 10
        for _, v in ipairs(dropdownScroll:GetChildren()) do
            if v:IsA("TextButton") then v.ZIndex = 11 end
        end
        tween(arrow, {Rotation = open and 180 or 0})
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        if not open then
            tween(frame, {BackgroundColor3 = self.Theme.Surface})
        end
    end)

    -- Close dropdown when clicking outside
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and open then
            local pos = UserInputService:GetMouseLocation()
            local absPos = frame.AbsolutePosition
            local absSize = frame.AbsoluteSize
            local ddPos = dropdownList.AbsolutePosition
            local ddSize = dropdownList.AbsoluteSize
            local inFrame = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
            local inDropdown = pos.X >= ddPos.X and pos.X <= ddPos.X + ddSize.X and pos.Y >= ddPos.Y and pos.Y <= ddPos.Y + ddSize.Y
            if not inFrame and not inDropdown then
                open = false
                dropdownList.Visible = false
                tween(arrow, {Rotation = 0})
            end
        end
    end)

    local obj = {}
    obj.Set = function(val)
        selected = val
        lbl.Text = text .. ": " .. selected
        callback(selected)
    end
    obj.Get = function() return selected end
    return obj
end

--------------------------------------------------------------------
-- Slider
--------------------------------------------------------------------
function ModernUI:CreateSlider(tab, text, min, max, default, callback)
    callback = callback or function() end
    local value = default or min
    local dragging = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 40)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 36, 0, 18)
    valLabel.Position = UDim2.new(1, -44, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(value)
    valLabel.TextColor3 = self.Theme.AccentLight
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, -24, 0, 6)
    barBG.Position = UDim2.new(0, 12, 0, 28)
    barBG.BackgroundColor3 = self.Theme.Card
    barBG.BorderSizePixel = 0
    barBG.Parent = frame
    addCorner(barBG, 3)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    barFill.BackgroundColor3 = self.Theme.Accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBG
    addCorner(barFill, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = self.Theme.AccentLight
    knob.BorderSizePixel = 0
    knob.Parent = barBG
    addCorner(knob, 7)

    local function update(val)
        val = math.clamp(val, min, max)
        value = math.floor(val)
        local ratio = (value - min) / (max - min)
        barFill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -7, 0.5, -7)
        valLabel.Text = tostring(value)
        callback(value)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    local inputCon
    inputCon = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X
            local barAbs = barBG.AbsolutePosition.X
            local barSize = barBG.AbsoluteSize.X
            local ratio = (pos - barAbs) / barSize
            update(min + ratio * (max - min))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Surface})
    end)

    local obj = {}
    obj.Set = update
    obj.Get = function() return value end
    return obj
end

--------------------------------------------------------------------
-- ColorPicker
--------------------------------------------------------------------
function ModernUI:CreateColorPicker(tab, text, default, callback)
    callback = callback or function() end
    local color = default or self.Theme.Accent
    local open = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    frame.ClipsDescendants = false
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 28, 0, 20)
    preview.Position = UDim2.new(1, -36, 0.5, -10)
    preview.BackgroundColor3 = color
    preview.BorderSizePixel = 0
    preview.Parent = frame
    addCorner(preview, 4)

    -- Color picker popup
    local pickerBG = Instance.new("Frame")
    pickerBG.Size = UDim2.new(0, 200, 0, 240)
    pickerBG.Position = UDim2.new(1, 4, 0, 0)
    pickerBG.BackgroundColor3 = self.Theme.Panel
    pickerBG.BorderSizePixel = 0
    pickerBG.Visible = false
    pickerBG.ZIndex = 20
    pickerBG.Parent = frame
    addCorner(pickerBG, 10)
    addStroke(pickerBG, self.Theme.Border, 1, 0.4)

    -- Hue/Saturation square
    local colorBox = Instance.new("Frame")
    colorBox.Size = UDim2.new(1, -16, 0, 140)
    colorBox.Position = UDim2.new(0, 8, 0, 8)
    colorBox.BorderSizePixel = 0
    colorBox.ZIndex = 21
    colorBox.Parent = pickerBG
    addCorner(colorBox, 6)

    local hue = 0
    local sat = 1
    local val = 1

    -- We'll use a simpler approach: preset color swatches
    local swatchesLabel = Instance.new("TextLabel")
    swatchesLabel.Size = UDim2.new(1, -16, 0, 16)
    swatchesLabel.Position = UDim2.new(0, 8, 0, 152)
    swatchesLabel.BackgroundTransparency = 1
    swatchesLabel.Text = "Quick Colors"
    swatchesLabel.TextColor3 = self.Theme.TextMuted
    swatchesLabel.Font = Enum.Font.GothamBold
    swatchesLabel.TextSize = 10
    swatchesLabel.ZIndex = 21
    swatchesLabel.Parent = pickerBG

    local swatchGrid = Instance.new("Frame")
    swatchGrid.Size = UDim2.new(1, -16, 0, 72)
    swatchGrid.Position = UDim2.new(0, 8, 0, 168)
    swatchGrid.BackgroundTransparency = 1
    swatchGrid.ZIndex = 21
    swatchGrid.Parent = pickerBG

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 24, 0, 24)
    gridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    gridLayout.Parent = swatchGrid

    local presetColors = {
        Color3.fromRGB(255, 70, 70),
        Color3.fromRGB(255, 160, 40),
        Color3.fromRGB(255, 220, 50),
        Color3.fromRGB(80, 220, 80),
        Color3.fromRGB(40, 200, 180),
        Color3.fromRGB(50, 150, 255),
        Color3.fromRGB(100, 80, 255),
        Color3.fromRGB(180, 70, 220),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(180, 180, 180),
        Color3.fromRGB(100, 100, 100),
        Color3.fromRGB(20, 20, 20),
        Color3.fromRGB(40, 200, 130),
        Color3.fromRGB(255, 100, 150),
        Color3.fromRGB(130, 200, 255),
        Color3.fromRGB(255, 200, 150),
    }

    for _, c in ipairs(presetColors) do
        local swatch = Instance.new("TextButton")
        swatch.Size = UDim2.new(1, 0, 1, 0)
        swatch.BackgroundColor3 = c
        swatch.BorderSizePixel = 0
        swatch.AutoButtonColor = false
        swatch.Text = ""
        swatch.ZIndex = 22
        swatch.Parent = swatchGrid
        addCorner(swatch, 4)
        swatch.MouseButton1Click:Connect(function()
            color = c
            preview.BackgroundColor3 = c
            callback(c)
            pickerBG.Visible = false
            open = false
        end)
    end

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Parent = frame

    clickArea.MouseButton1Click:Connect(function()
        open = not open
        pickerBG.Visible = open
    end)

    -- Close on outside click
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and open then
            local pos = UserInputService:GetMouseLocation()
            local fAbs = frame.AbsolutePosition
            local fSize = frame.AbsoluteSize
            local pAbs = pickerBG.AbsolutePosition
            local pSize = pickerBG.AbsoluteSize
            local inFrame = pos.X >= fAbs.X and pos.X <= fAbs.X + fSize.X and pos.Y >= fAbs.Y and pos.Y <= fAbs.Y + fSize.Y
            local inPicker = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
            if not inFrame and not inPicker then
                open = false
                pickerBG.Visible = false
            end
        end
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Surface})
    end)

    local obj = {}
    obj.Set = function(c)
        color = c
        preview.BackgroundColor3 = c
    end
    obj.Get = function() return color end
    return obj
end

--------------------------------------------------------------------
-- Label / Docs
--------------------------------------------------------------------
function ModernUI:CreateLabel(tab, text, isTitle)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, isTitle and 24 or 20)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = isTitle and self.Theme.AccentLight or self.Theme.TextSec
    lbl.Font = isTitle and Enum.Font.GothamBlack or Enum.Font.Gotham
    lbl.TextSize = isTitle and 13 or 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = frame

    return lbl
end

--------------------------------------------------------------------
-- Separator
--------------------------------------------------------------------
function ModernUI:CreateSeparator(tab)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 1)
    frame.Position = UDim2.new(0, 8, 0, 0)
    frame.BackgroundColor3 = self.Theme.Border
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    return frame
end

--------------------------------------------------------------------
-- Theme customization
--------------------------------------------------------------------
function ModernUI:SetThemeColor(key, color)
    if self.Theme[key] then
        self.Theme[key] = color
    end
end

function ModernUI:ApplyAccent(color)
    self.Theme.Accent = color
    self.Theme.AccentLight = Color3.fromRGB(math.min(color.R * 255 + 30, 255), math.min(color.G * 255 + 30, 255), math.min(color.B * 255 + 30, 255))
    self.Theme.AccentDim = Color3.fromRGB(math.max(color.R * 255 - 30, 0), math.max(color.G * 255 - 30, 0), math.max(color.B * 255 - 30, 0))
end

return ModernUI
-- ModernUI.lua — Roblox UI Library
-- Minimal, responsive, resizable, PC + mobile
-- Usage: local UI = loadstring(game:HttpGet("url"))()
--        local window = UI:CreateWindow({Title = "My GUI"})

local ModernUI = {}
ModernUI.__index = ModernUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Color utilities
local function hex2rgb(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255)
end

local function rgb2hex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- Default theme
local Themes = {
    Dark = {
        BG = Color3.fromRGB(10, 10, 18),
        Surface = Color3.fromRGB(16, 16, 28),
        Panel = Color3.fromRGB(22, 22, 36),
        Card = Color3.fromRGB(28, 28, 46),
        CardHover = Color3.fromRGB(36, 36, 58),
        Accent = Color3.fromRGB(120, 80, 250),
        AccentLight = Color3.fromRGB(155, 125, 255),
        AccentDim = Color3.fromRGB(40, 25, 90),
        TextPri = Color3.fromRGB(240, 240, 252),
        TextSec = Color3.fromRGB(160, 160, 190),
        TextMuted = Color3.fromRGB(95, 95, 125),
        Border = Color3.fromRGB(32, 32, 55),
        Success = Color3.fromRGB(20, 200, 130),
        Warning = Color3.fromRGB(255, 175, 55),
        Danger = Color3.fromRGB(255, 70, 70),
        InputBG = Color3.fromRGB(16, 16, 28),
    },
    Light = {
        BG = Color3.fromRGB(245, 245, 250),
        Surface = Color3.fromRGB(235, 235, 242),
        Panel = Color3.fromRGB(225, 225, 235),
        Card = Color3.fromRGB(215, 215, 228),
        CardHover = Color3.fromRGB(200, 200, 218),
        Accent = Color3.fromRGB(100, 60, 230),
        AccentLight = Color3.fromRGB(130, 100, 240),
        AccentDim = Color3.fromRGB(200, 180, 255),
        TextPri = Color3.fromRGB(15, 15, 25),
        TextSec = Color3.fromRGB(80, 80, 110),
        TextMuted = Color3.fromRGB(140, 140, 170),
        Border = Color3.fromRGB(200, 200, 215),
        Success = Color3.fromRGB(20, 170, 110),
        Warning = Color3.fromRGB(220, 150, 40),
        Danger = Color3.fromRGB(220, 50, 50),
        InputBG = Color3.fromRGB(235, 235, 242),
    }
}

local function applyTheme(theme)
    return {
        BG = theme.BG,
        Surface = theme.Surface,
        Panel = theme.Panel,
        Card = theme.Card,
        CardHover = theme.CardHover,
        Accent = theme.Accent,
        AccentLight = theme.AccentLight,
        AccentDim = theme.AccentDim,
        TextPri = theme.TextPri,
        TextSec = theme.TextSec,
        TextMuted = theme.TextMuted,
        Border = theme.Border,
        Success = theme.Success,
        Warning = theme.Warning,
        Danger = theme.Danger,
        InputBG = theme.InputBG,
    }
end

local function tween(obj, props, dur, style, dir)
    local ti = TweenInfo.new(dur or 0.2, Enum.EasingStyle[style or "Quad"], Enum.EasingDirection[dir or "Out"])
    local t = TweenService:Create(obj, ti, props)
    t:Play()
    return t
end

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = obj
    return c
end

local function addStroke(obj, color, thickness, transp)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(32, 32, 55)
    s.Thickness = thickness or 0.5
    s.Transparency = transp or 0.6
    s.Parent = obj
    return s
end

-- Create a ScrollingFrame with proper configuration
local function createScrollingFrame(parent, size, pos)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = size or UDim2.new(1, 0, 1, 0)
    sf.Position = pos or UDim2.new(0, 0, 0, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = Color3.fromRGB(95, 95, 125)
    sf.ClipsDescendants = true
    sf.Parent = parent
    return sf
end

--------------------------------------------------------------------
-- Window
--------------------------------------------------------------------
function ModernUI:CreateWindow(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, ModernUI)

    self.Theme = applyTheme(Themes[cfg.Theme] or Themes.Dark)
    self.Title = cfg.Title or "UI"
    self.MinSize = cfg.MinSize or Vector2.new(320, 240)
    self.Size = cfg.Size or UDim2.new(0, 500, 0, 400)
    self.Keybind = cfg.Keybind or Enum.KeyCode.LeftControl
    self.ToggleKey = cfg.ToggleKey or "RightShift"

    self.Tabs = {}
    self.ActiveTab = nil
    self.Components = {}

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ModernUI_" .. self.Title:gsub("%s+", "")
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main frame
    local main = Instance.new("Frame")
    main.Size = self.Size
    main.Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2)
    main.BackgroundColor3 = self.Theme.BG
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.Parent = gui
    addCorner(main, 12)
    addStroke(main, self.Theme.AccentDim, 1.5, 0.4)
    self.Main = main
    self.GUI = gui

    -- Mobile close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 6)
    closeBtn.BackgroundColor3 = self.Theme.Card
    closeBtn.Text = "X"
    closeBtn.TextColor3 = self.Theme.TextSec
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.AutoButtonColor = false
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = main
    addCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = not gui.Enabled end)

    -- Toggle binding
    local function onToggle()
        gui.Enabled = not gui.Enabled
    end

    local inputCon
    inputCon = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode[self.ToggleKey] then
            onToggle()
        end
    end)

    -- Dragging
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Resizing
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    resizeHandle.BackgroundColor3 = self.Theme.Accent
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Text = ""
    resizeHandle.AutoButtonColor = false
    resizeHandle.Parent = main
    addCorner(resizeHandle, 4)

    local resizing, resizeStart, resizeStartSize
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = Vector2.new(input.Position.X, input.Position.Y)
            resizeStartSize = main.Size
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - resizeStart
            local newW = math.max(self.MinSize.X, resizeStartSize.X.Offset + delta.X)
            local newH = math.max(self.MinSize.Y, resizeStartSize.Y.Offset + delta.Y)
            main.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    addCorner(titleBar, 12)

    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 22)
    titleCover.Position = UDim2.new(0, 0, 0, 18)
    titleCover.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = self.Theme.AccentLight
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -12, 0, 32)
    tabBar.Position = UDim2.new(0, 6, 0, 44)
    tabBar.BackgroundColor3 = self.Theme.Surface
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    addCorner(tabBar, 8)

    local tabList = Instance.new("Frame")
    tabList.Size = UDim2.new(1, -4, 1, -4)
    tabList.Position = UDim2.new(0, 2, 0, 2)
    tabList.BackgroundTransparency = 1
    tabList.Parent = tabBar

    self.TabBar = tabBar
    self.TabList = tabList
    self.TabContainer = main

    self.TabButtons = {}

    -- Content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -12, 1, -82)
    content.Position = UDim2.new(0, 6, 0, 78)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = main
    self.Content = content

    self.Destroy = function()
        inputCon:Disconnect()
        gui:Destroy()
    end

    return self
end

--------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------
function ModernUI:CreateTab(name)
    local tabObj = {}
    tabObj.Name = name
    tabObj.Elements = {}
    tabObj.ScrollingFrames = {}

    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, -4)
    btn.Position = UDim2.new(0, 2 + (#self.TabButtons) * 102, 0, 2)
    btn.BackgroundColor3 = self.Theme.Surface
    btn.Text = name
    btn.TextColor3 = self.Theme.TextMuted
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = self.TabList
    addCorner(btn, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0.6, 0, 0, 3)
    indicator.Position = UDim2.new(0.2, 0, 1, -1)
    indicator.BackgroundColor3 = self.Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn
    addCorner(indicator, 2)

    tabObj.Button = btn
    tabObj.Indicator = indicator

    -- Tab content frame
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    tabContent.Parent = self.Content
    tabObj.Content = tabContent

    -- ScrollingFrame for this tab
    local sf = createScrollingFrame(tabContent, UDim2.new(1, 0, 1, 0))
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = sf

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = sf

    tabObj.Scroll = sf

    -- Button hover
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObj then
            tween(btn, {BackgroundColor3 = self.Theme.Card})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObj then
            tween(btn, {BackgroundColor3 = self.Theme.Surface})
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tabObj)
    end)

    table.insert(self.Tabs, tabObj)
    self.TabButtons[name] = btn

    -- Select first tab by default
    if #self.Tabs == 1 then
        self:SelectTab(tabObj)
    end

    return tabObj
end

function ModernUI:SelectTab(tab)
    if self.ActiveTab then
        self.ActiveTab.Content.Visible = false
        tween(self.ActiveTab.Button, {BackgroundColor3 = self.Theme.Surface, TextColor3 = self.Theme.TextMuted})
        self.ActiveTab.Indicator.Visible = false
    end
    self.ActiveTab = tab
    tab.Content.Visible = true
    tween(tab.Button, {BackgroundColor3 = self.Theme.AccentDim, TextColor3 = Color3.fromRGB(255, 255, 255)})
    tab.Indicator.Visible = true
end

--------------------------------------------------------------------
-- Elements
--------------------------------------------------------------------
local function createSection(tab, title)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 24)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = tab.Parent.Parent.Parent.Parent.Parent.Theme.AccentLight
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    table.insert(tab.Elements, frame)
    return frame
end

--------------------------------------------------------------------
-- Section
--------------------------------------------------------------------
function ModernUI:CreateSection(tab, name)
    return createSection(tab, name)
end

--------------------------------------------------------------------
-- Button
--------------------------------------------------------------------
function ModernUI:CreateButton(tab, text, callback)
    callback = callback or function() end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 34)
    frame.BackgroundColor3 = self.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = self.Theme.TextPri
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = frame

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 0, 20)
    accent.Position = UDim2.new(0, 8, 0.5, -10)
    accent.BackgroundColor3 = self.Theme.Accent
    accent.BorderSizePixel = 0
    accent.Parent = frame
    addCorner(accent, 2)

    btn.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.CardHover})
    end)
    btn.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    btn.MouseButton1Click:Connect(callback)

    return btn
end

--------------------------------------------------------------------
-- Toggle
--------------------------------------------------------------------
function ModernUI:CreateToggle(tab, text, default, callback)
    callback = callback or function() end
    local state = default or false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -58, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local toggleBG = Instance.new("Frame")
    toggleBG.Size = UDim2.new(0, 44, 0, 24)
    toggleBG.Position = UDim2.new(1, -52, 0.5, -12)
    toggleBG.BackgroundColor3 = state and self.Theme.Accent or Color3.fromRGB(60, 60, 80)
    toggleBG.BorderSizePixel = 0
    toggleBG.Parent = frame
    addCorner(toggleBG, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBG
    addCorner(knob, 9)

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Parent = frame

    local function setState(newState)
        state = newState
        tween(toggleBG, {BackgroundColor3 = state and self.Theme.Accent or Color3.fromRGB(60, 60, 80)})
        tween(knob, {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)})
        callback(state)
    end

    clickArea.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Surface})
    end)

    local obj = {}
    obj.Set = setState
    obj.Get = function() return state end
    obj.Frame = frame
    return obj
end

--------------------------------------------------------------------
-- TextInput
--------------------------------------------------------------------
function ModernUI:CreateTextInput(tab, placeholder, default, callback)
    callback = callback or function() end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)
    addStroke(frame, self.Theme.Border, 0.5, 0.6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.TextColor3 = self.Theme.TextPri
    box.PlaceholderText = placeholder or "Enter text..."
    box.PlaceholderColor3 = self.Theme.TextMuted
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = frame

    if default then
        box.Text = default
    end

    box.FocusLost:Connect(function(enter)
        if enter then
            callback(box.Text)
        end
    end)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        callback(box.Text)
    end)

    return box
end

--------------------------------------------------------------------
-- SearchBar
--------------------------------------------------------------------
function ModernUI:CreateSearchBar(tab, placeholder, callback)
    callback = callback or function() end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)
    addStroke(frame, self.Theme.AccentDim, 1, 0.5)

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 28, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = self.Theme.TextMuted
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.TextSize = 13
    searchIcon.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -32, 1, 0)
    box.Position = UDim2.new(0, 28, 0, 0)
    box.BackgroundTransparency = 1
    box.TextColor3 = self.Theme.TextPri
    box.PlaceholderText = placeholder or "Search..."
    box.PlaceholderColor3 = self.Theme.TextMuted
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = frame

    box:GetPropertyChangedSignal("Text"):Connect(function()
        callback(box.Text)
    end)

    return box
end

--------------------------------------------------------------------
-- Dropdown
--------------------------------------------------------------------
function ModernUI:CreateDropdown(tab, text, options, default, callback)
    callback = callback or function() end
    local selected = default or (options[1] or "")
    local open = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    frame.ClipsDescendants = false
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. selected
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = self.Theme.TextSec
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 12
    arrow.Parent = frame

    local dropdownList = Instance.new("Frame")
    dropdownList.Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 28 + 4)
    dropdownList.Position = UDim2.new(0, 0, 1, 4)
    dropdownList.BackgroundColor3 = self.Theme.Panel
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    dropdownList.Parent = frame
    addCorner(dropdownList, 8)
    addStroke(dropdownList, self.Theme.Border, 0.5, 0.5)

    local dropdownScroll = createScrollingFrame(dropdownList, UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2))
    dropdownScroll.ZIndex = 10
    dropdownScroll.ScrollBarThickness = 3

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = dropdownScroll

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = self.Theme.Panel
        optBtn.Text = opt
        optBtn.TextColor3 = self.Theme.TextSec
        optBtn.Font = Enum.Font.GothamSemibold
        optBtn.TextSize = 11
        optBtn.AutoButtonColor = false
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 11
        optBtn.Parent = dropdownScroll
        addCorner(optBtn, 4)

        optBtn.MouseEnter:Connect(function()
            tween(optBtn, {BackgroundColor3 = self.Theme.Card})
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, {BackgroundColor3 = self.Theme.Panel})
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            lbl.Text = text .. ": " .. selected
            dropdownList.Visible = false
            open = false
            callback(selected)
        end)
    end

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Parent = frame

    clickArea.MouseButton1Click:Connect(function()
        open = not open
        dropdownList.Visible = open
        dropdownList.ZIndex = 10
        for _, v in ipairs(dropdownScroll:GetChildren()) do
            if v:IsA("TextButton") then v.ZIndex = 11 end
        end
        tween(arrow, {Rotation = open and 180 or 0})
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        if not open then
            tween(frame, {BackgroundColor3 = self.Theme.Surface})
        end
    end)

    -- Close dropdown when clicking outside
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and open then
            local pos = UserInputService:GetMouseLocation()
            local absPos = frame.AbsolutePosition
            local absSize = frame.AbsoluteSize
            local ddPos = dropdownList.AbsolutePosition
            local ddSize = dropdownList.AbsoluteSize
            local inFrame = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
            local inDropdown = pos.X >= ddPos.X and pos.X <= ddPos.X + ddSize.X and pos.Y >= ddPos.Y and pos.Y <= ddPos.Y + ddSize.Y
            if not inFrame and not inDropdown then
                open = false
                dropdownList.Visible = false
                tween(arrow, {Rotation = 0})
            end
        end
    end)

    local obj = {}
    obj.Set = function(val)
        selected = val
        lbl.Text = text .. ": " .. selected
        callback(selected)
    end
    obj.Get = function() return selected end
    return obj
end

--------------------------------------------------------------------
-- Slider
--------------------------------------------------------------------
function ModernUI:CreateSlider(tab, text, min, max, default, callback)
    callback = callback or function() end
    local value = default or min
    local dragging = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 40)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 36, 0, 18)
    valLabel.Position = UDim2.new(1, -44, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(value)
    valLabel.TextColor3 = self.Theme.AccentLight
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, -24, 0, 6)
    barBG.Position = UDim2.new(0, 12, 0, 28)
    barBG.BackgroundColor3 = self.Theme.Card
    barBG.BorderSizePixel = 0
    barBG.Parent = frame
    addCorner(barBG, 3)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    barFill.BackgroundColor3 = self.Theme.Accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBG
    addCorner(barFill, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = self.Theme.AccentLight
    knob.BorderSizePixel = 0
    knob.Parent = barBG
    addCorner(knob, 7)

    local function update(val)
        val = math.clamp(val, min, max)
        value = math.floor(val)
        local ratio = (value - min) / (max - min)
        barFill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -7, 0.5, -7)
        valLabel.Text = tostring(value)
        callback(value)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    local inputCon
    inputCon = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X
            local barAbs = barBG.AbsolutePosition.X
            local barSize = barBG.AbsoluteSize.X
            local ratio = (pos - barAbs) / barSize
            update(min + ratio * (max - min))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Surface})
    end)

    local obj = {}
    obj.Set = update
    obj.Get = function() return value end
    return obj
end

--------------------------------------------------------------------
-- ColorPicker
--------------------------------------------------------------------
function ModernUI:CreateColorPicker(tab, text, default, callback)
    callback = callback or function() end
    local color = default or self.Theme.Accent
    local open = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    frame.ClipsDescendants = false
    addCorner(frame, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = self.Theme.TextPri
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 28, 0, 20)
    preview.Position = UDim2.new(1, -36, 0.5, -10)
    preview.BackgroundColor3 = color
    preview.BorderSizePixel = 0
    preview.Parent = frame
    addCorner(preview, 4)

    -- Color picker popup
    local pickerBG = Instance.new("Frame")
    pickerBG.Size = UDim2.new(0, 200, 0, 240)
    pickerBG.Position = UDim2.new(1, 4, 0, 0)
    pickerBG.BackgroundColor3 = self.Theme.Panel
    pickerBG.BorderSizePixel = 0
    pickerBG.Visible = false
    pickerBG.ZIndex = 20
    pickerBG.Parent = frame
    addCorner(pickerBG, 10)
    addStroke(pickerBG, self.Theme.Border, 1, 0.4)

    -- Hue/Saturation square
    local colorBox = Instance.new("Frame")
    colorBox.Size = UDim2.new(1, -16, 0, 140)
    colorBox.Position = UDim2.new(0, 8, 0, 8)
    colorBox.BorderSizePixel = 0
    colorBox.ZIndex = 21
    colorBox.Parent = pickerBG
    addCorner(colorBox, 6)

    local hue = 0
    local sat = 1
    local val = 1

    -- We'll use a simpler approach: preset color swatches
    local swatchesLabel = Instance.new("TextLabel")
    swatchesLabel.Size = UDim2.new(1, -16, 0, 16)
    swatchesLabel.Position = UDim2.new(0, 8, 0, 152)
    swatchesLabel.BackgroundTransparency = 1
    swatchesLabel.Text = "Quick Colors"
    swatchesLabel.TextColor3 = self.Theme.TextMuted
    swatchesLabel.Font = Enum.Font.GothamBold
    swatchesLabel.TextSize = 10
    swatchesLabel.ZIndex = 21
    swatchesLabel.Parent = pickerBG

    local swatchGrid = Instance.new("Frame")
    swatchGrid.Size = UDim2.new(1, -16, 0, 72)
    swatchGrid.Position = UDim2.new(0, 8, 0, 168)
    swatchGrid.BackgroundTransparency = 1
    swatchGrid.ZIndex = 21
    swatchGrid.Parent = pickerBG

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 24, 0, 24)
    gridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    gridLayout.Parent = swatchGrid

    local presetColors = {
        Color3.fromRGB(255, 70, 70),
        Color3.fromRGB(255, 160, 40),
        Color3.fromRGB(255, 220, 50),
        Color3.fromRGB(80, 220, 80),
        Color3.fromRGB(40, 200, 180),
        Color3.fromRGB(50, 150, 255),
        Color3.fromRGB(100, 80, 255),
        Color3.fromRGB(180, 70, 220),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(180, 180, 180),
        Color3.fromRGB(100, 100, 100),
        Color3.fromRGB(20, 20, 20),
        Color3.fromRGB(40, 200, 130),
        Color3.fromRGB(255, 100, 150),
        Color3.fromRGB(130, 200, 255),
        Color3.fromRGB(255, 200, 150),
    }

    for _, c in ipairs(presetColors) do
        local swatch = Instance.new("TextButton")
        swatch.Size = UDim2.new(1, 0, 1, 0)
        swatch.BackgroundColor3 = c
        swatch.BorderSizePixel = 0
        swatch.AutoButtonColor = false
        swatch.Text = ""
        swatch.ZIndex = 22
        swatch.Parent = swatchGrid
        addCorner(swatch, 4)
        swatch.MouseButton1Click:Connect(function()
            color = c
            preview.BackgroundColor3 = c
            callback(c)
            pickerBG.Visible = false
            open = false
        end)
    end

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Parent = frame

    clickArea.MouseButton1Click:Connect(function()
        open = not open
        pickerBG.Visible = open
    end)

    -- Close on outside click
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and open then
            local pos = UserInputService:GetMouseLocation()
            local fAbs = frame.AbsolutePosition
            local fSize = frame.AbsoluteSize
            local pAbs = pickerBG.AbsolutePosition
            local pSize = pickerBG.AbsoluteSize
            local inFrame = pos.X >= fAbs.X and pos.X <= fAbs.X + fSize.X and pos.Y >= fAbs.Y and pos.Y <= fAbs.Y + fSize.Y
            local inPicker = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
            if not inFrame and not inPicker then
                open = false
                pickerBG.Visible = false
            end
        end
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Card})
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = self.Theme.Surface})
    end)

    local obj = {}
    obj.Set = function(c)
        color = c
        preview.BackgroundColor3 = c
    end
    obj.Get = function() return color end
    return obj
end

--------------------------------------------------------------------
-- Label / Docs
--------------------------------------------------------------------
function ModernUI:CreateLabel(tab, text, isTitle)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, isTitle and 24 or 20)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = isTitle and self.Theme.AccentLight or self.Theme.TextSec
    lbl.Font = isTitle and Enum.Font.GothamBlack or Enum.Font.Gotham
    lbl.TextSize = isTitle and 13 or 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = frame

    return lbl
end

--------------------------------------------------------------------
-- Separator
--------------------------------------------------------------------
function ModernUI:CreateSeparator(tab)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 1)
    frame.Position = UDim2.new(0, 8, 0, 0)
    frame.BackgroundColor3 = self.Theme.Border
    frame.BorderSizePixel = 0
    frame.Parent = tab.Scroll
    return frame
end

--------------------------------------------------------------------
-- Theme customization
--------------------------------------------------------------------
function ModernUI:SetThemeColor(key, color)
    if self.Theme[key] then
        self.Theme[key] = color
    end
end

function ModernUI:ApplyAccent(color)
    self.Theme.Accent = color
    self.Theme.AccentLight = Color3.fromRGB(math.min(color.R * 255 + 30, 255), math.min(color.G * 255 + 30, 255), math.min(color.B * 255 + 30, 255))
    self.Theme.AccentDim = Color3.fromRGB(math.max(color.R * 255 - 30, 0), math.max(color.G * 255 - 30, 0), math.max(color.B * 255 - 30, 0))
end

return ModernUI
