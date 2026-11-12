--[[
	Qevrion UI Library 1.0.0
	Rebuilds the StarterGui.Qevrion design (white window, tab sidebar, header with tab name,
	rows with a red/green toggle, slider and dropdown pill) at runtime, and keeps the same API
	as the ARNZ library: CreateWindow, CreateTab, CreateSection and the Create* elements.

	Design values taken from StarterGui.Qevrion (inspected in Studio, 2026-11-12):
	  window 900x614 white, corner 16, white UIShadow (0.75); sidebar logo rbxassetid://109220448678592;
	  rows white, corner 8, black UIShadow (0.5); toggle track 100x22 (180,0,3), knob 35x35;
	  slider track 22 high, hand 18x35; dropdown pill with black 2px gradient stroke, Inconsolata text;
	  fonts: rbxassetid://12187362578 (labels), rbxassetid://12187371840 (values).
	Choices that are mine and not from the design: the "on" green, the selected tab colour,
	the colour picker, keybind, textbox and button rows (the design has no template for them).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local env = (getgenv and getgenv()) or _G

local VERSION = "1.0.0"
local DESIGN_WIDTH, DESIGN_HEIGHT = 900, 614
local ROW_HEIGHT = 52
local LOGO_IMAGE = "rbxassetid://109220448678592"

local THEME = {
	Window = Color3.new(1, 1, 1),
	Text = Color3.new(0, 0, 0),
	Dim = Color3.fromRGB(110, 110, 110),
	Off = Color3.fromRGB(180, 0, 3),
	On = Color3.fromRGB(0, 170, 70),
	Line = Color3.fromRGB(62, 62, 62),
	Knob = Color3.new(1, 1, 1),
	Pill = Color3.fromRGB(243, 243, 243),
	TabIdle = Color3.fromRGB(243, 243, 243),
	TabSelected = Color3.fromRGB(28, 28, 28),
}

local function bodyFont(weight)
	return Font.fromId(12187362578, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end
local function valueFont(weight)
	return Font.fromId(12187371840, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end
local function monoFont(weight)
	return Font.fromName("Inconsolata", weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local STROKE_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.01, 0.5), NumberSequenceKeypoint.new(0.1, 0.76),
	NumberSequenceKeypoint.new(0.5, 0.98), NumberSequenceKeypoint.new(0.9, 0.74), NumberSequenceKeypoint.new(0.99, 0.49),
	NumberSequenceKeypoint.new(1, 0),
})

-- ------------------------------------------------------------------ small helpers

local function create(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

local function addCorner(parent, radius)
	return create("UICorner", { CornerRadius = radius or UDim.new(0, 8) }, parent)
end

-- UIShadow is new; if the client does not have it the layout just goes without shadows
local function addShadow(parent, color, transparency, spread)
	local ok, shadow = pcall(Instance.new, "UIShadow")
	if not ok or not shadow then return nil end
	pcall(function()
		shadow.Color = color or Color3.new(0, 0, 0)
		shadow.Transparency = transparency or 0.5
		if spread then shadow.Spread = spread end
		shadow.ZIndex = -1
	end)
	shadow.Parent = parent
	return shadow
end

local function tween(instance, seconds, props)
	local t = TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function textLabel(parent, props)
	local base = {
		BackgroundTransparency = 1,
		FontFace = bodyFont(),
		TextSize = 15,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
	}
	for key, value in pairs(props) do base[key] = value end
	return create("TextLabel", base, parent)
end

local function mouseLocation()
	return UserInputService:GetMouseLocation()
end

local function insideGui(gui, point)
	local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
	return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function formatNumber(value)
	local rounded = math.floor(value * 1000 + 0.5) / 1000
	return tostring(rounded)
end

local function colorToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function hexToColor(text)
	if type(text) ~= "string" then return nil end
	local hex = text:match("^#?(%x%x%x%x%x%x)$")
	if not hex then return nil end
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end

local function resolveKey(name)
	if name == "None" then return "None" end
	if name == "MouseButton1" or name == "MouseButton2" or name == "MouseButton3" then return name end
	if type(name) == "string" and Enum.KeyCode[name] then return name end
	local ok, key = pcall(function() return Enum.KeyCode[name] end)
	if ok and key then return key.Name end
	return nil
end

local function lowerFirst(name)
	return name:sub(1, 1):lower() .. name:sub(2)
end

local function addCamelCaseAliases(class)
	local extra = {}
	for name, value in pairs(class) do
		if type(value) == "function" and name:match("^%u") then
			extra[lowerFirst(name)] = value
		end
	end
	for name, value in pairs(extra) do
		if class[name] == nil then class[name] = value end
	end
end

-- ------------------------------------------------------------------ file access (configs)

local fileApi = {
	ok = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		and type(isfolder) == "function" and type(makefolder) == "function" and type(listfiles) == "function",
}

local function ensureFolder(path)
	if not fileApi.ok then return false end
	local built = ""
	for part in path:gmatch("[^/]+") do
		built = built == "" and part or (built .. "/" .. part)
		if not isfolder(built) then
			local ok = pcall(makefolder, built)
			if not ok then return false end
		end
	end
	return true
end

local function cleanName(name)
	name = tostring(name or ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then return nil end
	return name:sub(1, 40)
end

-- ------------------------------------------------------------------ element base

local Element = {}
Element.__index = Element

function Element:Get()
	return self.Value
end

function Element:Fire()
	for _, listener in ipairs(self.Listeners) do
		local ok, err = pcall(listener, self.Value)
		if not ok then warn("[Qevrion] callback error: " .. tostring(err)) end
	end
end

function Element:Set(value, silent)
	if self.Destroyed then return false end
	local ok, coerced = self:Validate(value)
	if not ok then return false end
	self.Value = coerced
	if self.Flag then self.Window.Flags[self.Flag] = coerced end
	self:Render()
	if not silent then
		self:Fire()
		self.Window:_changed(self)
	end
	return true
end

function Element:Reset()
	return self:Set(self.Default)
end

function Element:OnChanged(fn)
	self.Listeners[#self.Listeners + 1] = fn
end

function Element:SetVisible(visible)
	self.Row.Visible = visible and true or false
end

function Element:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	if self.Flag and self.Window.Elements[self.Flag] == self then
		self.Window.Elements[self.Flag] = nil
		self.Window.Flags[self.Flag] = nil
	end
	if self.OnDestroyed then pcall(self.OnDestroyed, self) end
	self.Row:Destroy()
end

function Element:Refresh() end
function Element:SetRange() end
function Element:SetText() end
function Element:IsDown() return false end

local function newElement(group, opts, kind)
	local element = setmetatable({
		Window = group.Window,
		Kind = kind,
		Listeners = {},
		Persist = opts.Persist ~= false,
		Flag = opts.Flag,
		Name = opts.Name or kind,
	}, Element)
	if opts.Callback then element.Listeners[1] = opts.Callback end
	return element
end

-- registers the flag and applies the default without firing callbacks (unless RunOnCreate)
local function finishElement(element, opts, default)
	local window = element.Window
	if element.Flag then
		if window.Elements[element.Flag] then
			warn("[Qevrion] duplicate flag '" .. tostring(element.Flag) .. "': this element will not be saved")
			element.Flag = nil
		else
			window.Elements[element.Flag] = element
		end
	end
	element.Default = default
	element.Value = default
	if element.Flag then window.Flags[element.Flag] = default end
	element:Render()
	if opts.RunOnCreate then element:Fire() end
	return element
end

-- a row card in the tab list, with the name on the left and an optional small description
local function newRow(group, name, description, height)
	local row = create("Frame", {
		Name = name or "Row",
		Size = UDim2.new(1, 0, 0, height or ROW_HEIGHT),
		BackgroundColor3 = THEME.Window,
		BorderSizePixel = 0,
		LayoutOrder = group.Tab:_nextOrder(),
	}, group.Container)
	addCorner(row, UDim.new(0, 8))
	addShadow(row, Color3.new(0, 0, 0), 0.5)
	local hasDescription = description ~= nil and description ~= ""
	local title = textLabel(row, {
		Name = "text",
		Position = UDim2.fromOffset(16, hasDescription and 8 or 0),
		Size = hasDescription and UDim2.new(0.5, 0, 0, 20) or UDim2.new(0.5, 0, 1, 0),
		Text = name or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	local small
	if hasDescription then
		small = textLabel(row, {
			Name = "description",
			Position = UDim2.fromOffset(16, 28),
			Size = UDim2.new(0.5, 0, 0, 16),
			Text = description,
			TextSize = 11,
			TextColor3 = THEME.Dim,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
	end
	return row, title, small
end

local function rightAnchored(width, height, offsetX)
	return {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, offsetX or -16, 0.5, 0),
		Size = UDim2.fromOffset(width, height),
	}
end

local function invisibleButton(parent, props)
	local base = { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }
	for key, value in pairs(props) do base[key] = value end
	return create("TextButton", base, parent)
end

-- ------------------------------------------------------------------ groups (tabs and sections create elements)

local Group = {}
Group.__index = Group

function Group:CreateToggle(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Toggle")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row

	local track = create("Frame", rightAnchored(100, 22), row)
	track.BackgroundColor3 = THEME.Off
	track.BorderSizePixel = 0
	addCorner(track, UDim.new(1, 0))
	addShadow(track, Color3.new(0, 0, 0), 0.5)
	local knob = create("Frame", {
		Size = UDim2.fromOffset(35, 35),
		Position = UDim2.new(0, 0, 0.5, -17),
		BackgroundColor3 = THEME.Knob,
		BorderSizePixel = 0,
	}, track)
	addCorner(knob, UDim.new(1, 0))
	addShadow(knob, Color3.new(0, 0, 0), 0.5)
	local hit = invisibleButton(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 44), ZIndex = 3,
	})
	hit.Activated:Connect(function() element:Set(not element.Value) end)

	function element:Validate(value)
		if type(value) ~= "boolean" then return false end
		return true, value
	end
	function element:Render()
		local on = self.Value == true
		tween(track, 0.15, { BackgroundColor3 = on and THEME.On or THEME.Off })
		tween(knob, 0.15, { Position = on and UDim2.new(1, -35, 0.5, -17) or UDim2.new(0, 0, 0.5, -17) })
	end
	return finishElement(element, opts, opts.Default == true)
end

function Group:CreateSlider(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Slider")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row
	element.Min = opts.Min or 0
	element.Max = opts.Max or 100
	element.Step = (opts.Step and opts.Step > 0) and opts.Step or 1
	local suffix = opts.Suffix or ""

	local TRACK_WIDTH, HAND_WIDTH = 160, 18
	local track = create("Frame", rightAnchored(TRACK_WIDTH, 22), row)
	track.BackgroundColor3 = THEME.Off
	track.BorderSizePixel = 0
	addCorner(track, UDim.new(1, 0))
	addShadow(track, Color3.new(0, 0, 0), 0.5)
	local hand = create("Frame", {
		Size = UDim2.fromOffset(HAND_WIDTH, 35), Position = UDim2.new(0, 0, 0.5, -17),
		BackgroundColor3 = THEME.Knob, BorderSizePixel = 0,
	}, track)
	addCorner(hand, UDim.new(1, 0))
	addShadow(hand, Color3.new(0, 0, 0), 0.5)
	local valueLabel = textLabel(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16 - TRACK_WIDTH - 10, 0.5, 0),
		Size = UDim2.fromOffset(70, 20), TextXAlignment = Enum.TextXAlignment.Right, FontFace = valueFont(), TextSize = 14,
	}, row)
	local hit = invisibleButton(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(TRACK_WIDTH + 16, 44), ZIndex = 3,
	})

	local function snap(value)
		local min, max, step = element.Min, element.Max, element.Step
		local snapped = min + math.floor((value - min) / step + 0.5) * step
		snapped = math.clamp(snapped, min, max)
		return tonumber(string.format("%.6f", snapped))
	end
	local function fromMouse(point)
		local width = track.AbsoluteSize.X - hand.AbsoluteSize.X
		if width <= 0 then return end
		local fraction = math.clamp((point.X - track.AbsolutePosition.X - hand.AbsoluteSize.X / 2) / width, 0, 1)
		element:Set(snap(element.Min + (element.Max - element.Min) * fraction))
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			element.Window._dragFn = fromMouse
			fromMouse(mouseLocation())
		end
	end)

	function element:Validate(value)
		if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return false end
		return true, snap(value)
	end
	function element:Render()
		local range = self.Max - self.Min
		local fraction = range > 0 and (self.Value - self.Min) / range or 0
		hand.Position = UDim2.new(fraction, -HAND_WIDTH * fraction, 0.5, -17)
		valueLabel.Text = formatNumber(self.Value) .. suffix
	end
	function element:SetRange(min, max)
		if type(min) ~= "number" or type(max) ~= "number" or max <= min then return end
		self.Min, self.Max = min, max
		self.Value = snap(self.Value)
		if self.Flag then self.Window.Flags[self.Flag] = self.Value end
		self:Render()
	end
	return finishElement(element, opts, snap(opts.Default or element.Min))
end

function Group:CreateDropdown(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Dropdown")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row
	element.Options = {}
	for _, option in ipairs(opts.Options or {}) do element.Options[#element.Options + 1] = tostring(option) end
	local allowCustom = opts.AllowCustom == true

	local pill = create("Frame", rightAnchored(150, 28), row)
	pill.BackgroundColor3 = THEME.Window
	pill.BorderSizePixel = 0
	addCorner(pill, UDim.new(1, 0))
	local stroke = create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pill)
	create("UIGradient", { Transparency = STROKE_FADE }, stroke)
	local selected = textLabel(pill, {
		Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -40, 1, 0), FontFace = monoFont(Enum.FontWeight.Bold),
		TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd,
	}, pill)
	textLabel(pill, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(20, 28),
		Text = "»", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center,
	}, pill)
	local hit = invisibleButton(pill, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })

	local function openList()
		local window = element.Window
		local itemHeight, maxVisible = 26, 6
		local count = #element.Options
		if count == 0 then return end
		local listHeight = math.min(count, maxVisible) * (itemHeight + 3) + 8
		local scale = window.UIScale.Scale
		local frame = create("ScrollingFrame", {
			Name = "dropdown", Size = UDim2.fromOffset(pill.AbsoluteSize.X / scale, listHeight),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromOffset(pill.AbsolutePosition.X + pill.AbsoluteSize.X, pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 6),
			BackgroundColor3 = THEME.Window, BorderSizePixel = 0, ScrollBarThickness = 3,
			CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 100, ClipsDescendants = true,
		}, window.Gui)
		create("UIScale", { Scale = scale }, frame)
		addCorner(frame, UDim.new(0, 6))
		addShadow(frame, Color3.new(0, 0, 0), 0.5)
		create("UIListLayout", { Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, frame)
		create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, frame)
		for index, option in ipairs(element.Options) do
			local isSelected = option == element.Value
			local item = create("TextButton", {
				Size = UDim2.new(1, -12, 0, itemHeight), LayoutOrder = index, AutoButtonColor = false,
				BackgroundColor3 = isSelected and THEME.TabSelected or THEME.Pill, BorderSizePixel = 0,
				Text = option, FontFace = monoFont(), TextSize = 14, TextColor3 = isSelected and THEME.Window or THEME.Text,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, frame)
			addCorner(item, UDim.new(0, 8))
			item.Activated:Connect(function()
				element:Set(option)
				window:_closePopup()
			end)
		end
		window:_setPopup(frame, pill)
	end
	hit.Activated:Connect(function()
		local window = element.Window
		if window._popup and window._popup.anchor == pill then window:_closePopup() else window:_closePopup() openList() end
	end)

	function element:Validate(value)
		if type(value) ~= "string" then return false end
		if table.find(self.Options, value) or allowCustom then return true, value end
		return false
	end
	function element:Render()
		selected.Text = tostring(self.Value or "")
	end
	function element:Refresh(list)
		if type(list) == "function" then
			local ok, result = pcall(list)
			list = ok and result or nil
		end
		if type(list) ~= "table" then return end
		self.Options = {}
		for _, option in ipairs(list) do self.Options[#self.Options + 1] = tostring(option) end
		if not allowCustom and not table.find(self.Options, self.Value) then
			self:Set(self.Options[1] or "", true)
		end
	end
	local default = opts.Default
	if default == nil or (not allowCustom and not table.find(element.Options, default)) then default = element.Options[1] or "" end
	return finishElement(element, opts, default)
end

function Group:CreateTextbox(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Textbox")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row
	local maxLength = opts.MaxLength

	local pill = create("Frame", rightAnchored(190, 28), row)
	pill.BackgroundColor3 = THEME.Pill
	pill.BorderSizePixel = 0
	addCorner(pill, UDim.new(1, 0))
	local box = create("TextBox", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		FontFace = monoFont(), TextSize = 14, TextColor3 = THEME.Text, PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = THEME.Dim, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Text = "",
	}, pill)
	box.FocusLost:Connect(function()
		if not element:Set(box.Text) then box.Text = element.Value end
	end)

	function element:Validate(value)
		if type(value) ~= "string" then return false end
		if maxLength then value = value:sub(1, maxLength) end
		return true, value
	end
	function element:Render()
		box.Text = self.Value
	end
	return finishElement(element, opts, tostring(opts.Default or ""))
end

function Group:CreateButton(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Button")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(110, 28),
		BackgroundColor3 = THEME.TabSelected, BorderSizePixel = 0, AutoButtonColor = false, Text = opts.ButtonText or "Run",
		FontFace = bodyFont(Enum.FontWeight.Medium), TextSize = 14, TextColor3 = THEME.Window,
	}, row)
	addCorner(button, UDim.new(1, 0))
	button.MouseEnter:Connect(function() tween(button, 0.1, { BackgroundColor3 = Color3.fromRGB(70, 70, 70) }) end)
	button.MouseLeave:Connect(function() tween(button, 0.1, { BackgroundColor3 = THEME.TabSelected }) end)
	button.Activated:Connect(function()
		for _, listener in ipairs(element.Listeners) do
			local ok, err = pcall(listener)
			if not ok then warn("[Qevrion] button error: " .. tostring(err)) end
		end
	end)

	function element:Validate() return false end
	function element:Render() end
	function element:SetText(text) button.Text = tostring(text) end
	return finishElement(element, opts, nil)
end

function Group:CreateLabel(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Label")
	local row = newRow(self, opts.Name, nil)
	element.Row = row
	local value = textLabel(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0.5, -16, 1, 0),
		Text = tostring(opts.Description or ""), TextSize = 13, TextColor3 = THEME.Dim, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	function element:Validate() return false end
	function element:Render() end
	function element:SetText(text) value.Text = tostring(text) end
	return finishElement(element, opts, nil)
end

function Group:CreateKeybind(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Keybind")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row
	element.Pressed = opts.Pressed

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(130, 28),
		BackgroundColor3 = THEME.Pill, BorderSizePixel = 0, AutoButtonColor = false, FontFace = monoFont(Enum.FontWeight.Bold),
		TextSize = 13, TextColor3 = THEME.Text, Text = "",
	}, row)
	addCorner(button, UDim.new(1, 0))
	local listening = false
	local window = element.Window
	window._keybinds[#window._keybinds + 1] = element
	element.OnDestroyed = function(self)
		local index = table.find(window._keybinds, self)
		if index then table.remove(window._keybinds, index) end
		if window._capture == self then window._capture = nil end
	end

	function element:Capture(input)
		listening = false
		window._capture = nil
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 then
			self:Render()
		elseif kind == Enum.UserInputType.MouseButton2 or kind == Enum.UserInputType.MouseButton3 then
			self:Set(kind.Name)
		elseif kind == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				self:Set("None")
			else
				self:Set(input.KeyCode.Name)
			end
		else
			self:Render()
		end
	end
	button.Activated:Connect(function()
		if listening then return end
		listening = true
		window._capture = element
		button.Text = "press a key..."
	end)

	function element:Validate(value)
		local key = resolveKey(value)
		if not key then return false end
		return true, key
	end
	function element:Render()
		button.Text = tostring(self.Value)
	end
	function element:Matches(input)
		local value = self.Value
		if value == "None" then return false end
		if value:sub(1, 5) == "Mouse" then return input.UserInputType.Name == value end
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == value
	end
	function element:IsDown()
		local value = self.Value
		if value == "None" then return false end
		if value:sub(1, 5) == "Mouse" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType[value]) end
		return UserInputService:IsKeyDown(Enum.KeyCode[value])
	end
	return finishElement(element, opts, resolveKey(opts.Default or "None") or "None")
end

function Group:CreateColorPicker(opts)
	opts = opts or {}
	local element = newElement(self, opts, "ColorPicker")
	local row = newRow(self, opts.Name, opts.Description)
	element.Row = row

	local swatch = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(56, 24),
		BackgroundColor3 = Color3.new(1, 0, 0), BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, row)
	addCorner(swatch, UDim.new(1, 0))
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.6 }, swatch)
	addShadow(swatch, Color3.new(0, 0, 0), 0.5)

	local hue, sat, val = 0, 1, 1
	local function openPicker()
		local window = element.Window
		local scale = window.UIScale.Scale
		local frame = create("Frame", {
			Name = "colorpicker", Size = UDim2.fromOffset(196, 176), AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromOffset(swatch.AbsolutePosition.X + swatch.AbsoluteSize.X, swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y + 6),
			BackgroundColor3 = THEME.Window, BorderSizePixel = 0, ZIndex = 100,
		}, window.Gui)
		create("UIScale", { Scale = scale }, frame)
		addCorner(frame, UDim.new(0, 10))
		addShadow(frame, Color3.new(0, 0, 0), 0.5)

		local square = create("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(176, 104), BorderSizePixel = 0 }, frame)
		addCorner(square, UDim.new(0, 6))
		square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		local whiteLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, square)
		addCorner(whiteLayer, UDim.new(0, 6))
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, whiteLayer)
		local blackLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, square)
		addCorner(blackLayer, UDim.new(0, 6))
		create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, blackLayer)
		local squareCursor = create("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0 }, square)
		addCorner(squareCursor, UDim.new(1, 0))
		create("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1) }, squareCursor)

		local bar = create("Frame", { Position = UDim2.fromOffset(10, 124), Size = UDim2.fromOffset(176, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, frame)
		addCorner(bar, UDim.new(1, 0))
		local rainbow = {}
		for i = 0, 6 do rainbow[#rainbow + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 == 1 and 0.999 or i / 6, 1, 1)) end
		create("UIGradient", { Color = ColorSequence.new(rainbow) }, bar)
		local barCursor = create("Frame", { Size = UDim2.fromOffset(6, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
		addCorner(barCursor, UDim.new(1, 0))
		create("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = 0.3 }, barCursor)

		local hexBox = create("TextBox", {
			Position = UDim2.fromOffset(10, 144), Size = UDim2.fromOffset(176, 24), BackgroundColor3 = THEME.Pill, BorderSizePixel = 0,
			FontFace = monoFont(), TextSize = 14, TextColor3 = THEME.Text, ClearTextOnFocus = false, Text = "",
		}, frame)
		addCorner(hexBox, UDim.new(1, 0))

		local function refreshVisuals()
			square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			squareCursor.Position = UDim2.fromScale(sat, 1 - val)
			barCursor.Position = UDim2.new(hue, 0, 0.5, 0)
			hexBox.Text = colorToHex(Color3.fromHSV(hue, sat, val))
		end
		local function apply()
			element:Set(Color3.fromHSV(hue, sat, val))
			refreshVisuals()
		end
		local function squareDrag(point)
			sat = math.clamp((point.X - square.AbsolutePosition.X) / square.AbsoluteSize.X, 0, 1)
			val = 1 - math.clamp((point.Y - square.AbsolutePosition.Y) / square.AbsoluteSize.Y, 0, 1)
			apply()
		end
		local function barDrag(point)
			hue = math.clamp((point.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 0.999)
			apply()
		end
		local function beginDrag(handler)
			return function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					window._dragFn = handler
					handler(mouseLocation())
				end
			end
		end
		square.InputBegan:Connect(beginDrag(squareDrag))
		bar.InputBegan:Connect(beginDrag(barDrag))
		hexBox.FocusLost:Connect(function()
			local color = hexToColor(hexBox.Text)
			if color then
				hue, sat, val = color:ToHSV()
				apply()
			else
				refreshVisuals()
			end
		end)
		refreshVisuals()
		window._setPopup(window, frame, swatch)
	end
	swatch.Activated:Connect(function()
		local window = element.Window
		if window._popup and window._popup.anchor == swatch then window:_closePopup() else window:_closePopup() openPicker() end
	end)

	function element:Validate(value)
		if typeof(value) == "Color3" then return true, value end
		local color = hexToColor(value)
		if color then return true, color end
		return false
	end
	function element:Render()
		swatch.BackgroundColor3 = self.Value
		hue, sat, val = self.Value:ToHSV()
	end
	local default = opts.Default
	if typeof(default) ~= "Color3" then default = hexToColor(default) or Color3.new(1, 1, 1) end
	return finishElement(element, opts, default)
end

-- ------------------------------------------------------------------ tabs and sections

local Section = setmetatable({}, { __index = Group })
Section.__index = Section

local Tab = setmetatable({}, { __index = Group })
Tab.__index = Tab

function Tab:_nextOrder()
	self._order = self._order + 1
	return self._order
end

function Tab:CreateSection(title, description)
	local window = self.Window
	local hasDescription = description ~= nil and description ~= ""
	local header = create("Frame", {
		Name = "section", Size = UDim2.new(1, 0, 0, hasDescription and 44 or 30), BackgroundTransparency = 1,
		BorderSizePixel = 0, LayoutOrder = self:_nextOrder(),
	}, self.Container)
	textLabel(header, {
		Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 0, 24), Text = tostring(title or ""),
		FontFace = bodyFont(Enum.FontWeight.Bold), TextSize = 18,
	}, header)
	if hasDescription then
		textLabel(header, {
			Position = UDim2.fromOffset(4, 24), Size = UDim2.new(1, -8, 0, 16), Text = description, TextSize = 12, TextColor3 = THEME.Dim,
		}, header)
	end
	return setmetatable({ Window = window, Tab = self, Container = self.Container, Header = header }, Section)
end

function Tab:Select()
	self.Window:SelectTab(self.Name)
end

-- ------------------------------------------------------------------ config manager

local Config = {}
Config.__index = Config

local function newConfig(window, folder)
	local self = setmetatable({ Window = window, Folder = folder, Meta = { autosave = false, autoload = false, last = "" } }, Config)
	self:_readMeta()
	return self
end

function Config:_dir() return self.Folder .. "/configs" end
function Config:_path(name) return self:_dir() .. "/" .. name .. ".json" end

function Config:_readMeta()
	if not fileApi.ok then return end
	local path = self.Folder .. "/meta.json"
	local ok, exists = pcall(isfile, path)
	if not (ok and exists) then return end
	local readOk, raw = pcall(readfile, path)
	if not readOk then return end
	local decodeOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if decodeOk and type(data) == "table" then
		self.Meta.autosave = data.autosave == true
		self.Meta.autoload = data.autoload == true
		self.Meta.last = type(data.last) == "string" and data.last or ""
	end
end

function Config:_writeMeta()
	if not (fileApi.ok and ensureFolder(self.Folder)) then return end
	pcall(writefile, self.Folder .. "/meta.json", HttpService:JSONEncode(self.Meta))
end

function Config:_collect()
	local flags = {}
	for flagName, element in pairs(self.Window.Elements) do
		if element.Persist and element.Value ~= nil and element.Kind ~= "Button" and element.Kind ~= "Label" then
			local value = element.Value
			if typeof(value) == "Color3" then value = colorToHex(value) end
			flags[flagName] = value
		end
	end
	return flags
end

function Config:Export()
	return HttpService:JSONEncode({ schema = 1, flags = self:_collect() })
end

function Config:_apply(data)
	if type(data) ~= "table" or type(data.flags) ~= "table" then return false, "not a Qevrion config" end
	local applied = 0
	for flagName, value in pairs(data.flags) do
		local element = self.Window.Elements[flagName]
		if element and element.Persist and element:Set(value) then applied += 1 end
	end
	return true, applied
end

function Config:Import(json)
	local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok then return false, "invalid JSON" end
	return self:_apply(data)
end

function Config:List()
	local names = {}
	if not (fileApi.ok and ensureFolder(self:_dir())) then return names end
	local ok, files = pcall(listfiles, self:_dir())
	if not ok then return names end
	for _, path in ipairs(files) do
		local name = tostring(path):match("([^/\\]+)%.json$")
		if name then names[#names + 1] = name end
	end
	table.sort(names)
	return names
end

function Config:Save(name)
	name = cleanName(name)
	if not name then return false, "invalid name" end
	if not (fileApi.ok and ensureFolder(self:_dir())) then return false, "no file access" end
	local ok, err = pcall(writefile, self:_path(name), self:Export())
	if not ok then return false, tostring(err) end
	self.Meta.last = name
	self:_writeMeta()
	return true, name
end

function Config:Load(name)
	name = cleanName(name)
	if not name then return false, "invalid name" end
	if not fileApi.ok then return false, "no file access" end
	local path = self:_path(name)
	local okExists, exists = pcall(isfile, path)
	if not (okExists and exists) then return false, "no such config" end
	local okRead, raw = pcall(readfile, path)
	if not okRead then return false, tostring(raw) end
	local ok, result = self:Import(raw)
	if ok then
		self.Meta.last = name
		self:_writeMeta()
	end
	return ok, result
end

function Config:Delete(name)
	name = cleanName(name)
	if not name then return false, "invalid name" end
	if not (fileApi.ok and type(delfile) == "function") then return false, "no file access" end
	local ok, err = pcall(delfile, self:_path(name))
	if not ok then return false, tostring(err) end
	if self.Meta.last == name then
		self.Meta.last = ""
		self:_writeMeta()
	end
	return true
end

function Config:SetAutoSave(value)
	self.Meta.autosave = value == true
	self:_writeMeta()
end

function Config:SetAutoLoad(value)
	self.Meta.autoload = value == true
	self:_writeMeta()
end

-- ------------------------------------------------------------------ window

local Window = {}
Window.__index = Window

local Qevrion = { Version = VERSION }
Qevrion.__index = Qevrion

env.__QEVRION_WINDOWS = env.__QEVRION_WINDOWS or {}

local function parentForGui()
	local ok, hidden = pcall(function() return gethui and gethui() end)
	if ok and hidden then return hidden end
	local okCore = pcall(function() return CoreGui.Name end)
	if okCore then return CoreGui end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Window:_connect(signal, fn)
	local connection = signal:Connect(fn)
	self._connections[#self._connections + 1] = connection
	return connection
end

function Window:_nextTabId()
	self._tabCount += 1
	return self._tabCount
end

function Window:_layoutTabButtons()
	local count = #self.Tabs
	if count == 0 then return end
	local available = self.SidebarList.AbsoluteSize.Y / math.max(self.UIScale.Scale, 0.01)
	if available <= 0 then available = 448 end
	local size = math.clamp(math.floor((available - (count - 1) * 8) / count), 40, 65)
	for _, tab in ipairs(self.Tabs) do
		tab.Button.Size = UDim2.fromOffset(size, size)
	end
end

function Window:CreateTab(name, icon)
	name = tostring(name or "Tab")
	local tab = setmetatable({ Window = self, Name = name, _order = 0 }, Tab)
	tab.Tab = tab

	local button = create("TextButton", {
		Name = name, Size = UDim2.fromOffset(65, 65), BackgroundColor3 = THEME.TabIdle, BorderSizePixel = 0, AutoButtonColor = false,
		LayoutOrder = #self.Tabs + 1, Text = "", FontFace = bodyFont(Enum.FontWeight.Bold), TextSize = 20, TextColor3 = THEME.Text,
	}, self.SidebarList)
	addCorner(button, UDim.new(0, 16))
	addShadow(button, Color3.new(0, 0, 0), 0.5)
	local glyph
	if type(icon) == "number" or (type(icon) == "string" and icon:match("^rbxassetid://")) then
		glyph = create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6),
			BackgroundTransparency = 1, Image = type(icon) == "number" and ("rbxassetid://" .. icon) or icon, ImageColor3 = THEME.Text,
		}, button)
	else
		button.Text = name:sub(1, 2):upper()
	end
	tab.Button, tab.Glyph = button, glyph

	tab.Container = create("ScrollingFrame", {
		Name = name, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
	}, self.Content)
	create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, tab.Container)
	create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10) }, tab.Container)

	button.Activated:Connect(function() self:SelectTab(name) end)
	self.Tabs[#self.Tabs + 1] = tab
	self.TabsByName[name] = tab
	self:_layoutTabButtons()
	if not self.CurrentTab then self:SelectTab(name) end
	return tab
end

function Window:SelectTab(name)
	local target = self.TabsByName[name]
	if not target then return end
	self:_closePopup()
	self.CurrentTab = target
	self.TabNameLabel.Text = target.Name
	for _, tab in ipairs(self.Tabs) do
		local active = tab == target
		tab.Container.Visible = active
		tween(tab.Button, 0.15, { BackgroundColor3 = active and THEME.TabSelected or THEME.TabIdle })
		tab.Button.TextColor3 = active and THEME.Window or THEME.Text
		if tab.Glyph then tab.Glyph.ImageColor3 = active and THEME.Window or THEME.Text end
	end
end

function Window:Notify(text, seconds)
	if type(text) == "table" then
		seconds = text.Duration or seconds
		text = text.Text or text.Title or ""
	end
	text = tostring(text or "")
	seconds = tonumber(seconds) or 3
	local toast = create("TextLabel", {
		Size = UDim2.new(0, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = THEME.Window, BorderSizePixel = 0,
		Text = text, FontFace = bodyFont(Enum.FontWeight.Medium), TextSize = 15, TextColor3 = THEME.Text, BackgroundTransparency = 1, TextTransparency = 1,
		LayoutOrder = math.floor(os.clock() * 1000),
	}, self.ToastLayer)
	addCorner(toast, UDim.new(0, 18))
	addShadow(toast, Color3.new(0, 0, 0), 0.5)
	create("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) }, toast)
	tween(toast, 0.2, { BackgroundTransparency = 0, TextTransparency = 0 })
	task.delay(seconds, function()
		if not toast.Parent then return end
		local fade = tween(toast, 0.25, { BackgroundTransparency = 1, TextTransparency = 1 })
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

function Window:SetVisible(visible)
	self.Main.Visible = visible and true or false
	if not visible then self:_closePopup() end
end

function Window:Toggle()
	self:SetVisible(not self.Main.Visible)
end

function Window:SetMenuKey(key)
	local resolved = resolveKey(key)
	if resolved and resolved ~= "None" and resolved:sub(1, 5) ~= "Mouse" then self.MenuKey = resolved end
end

function Window:SetScale(scale)
	if type(scale) ~= "number" then return end
	self.UIScale.Scale = math.clamp(scale, 0.5, 1.6)
	self:_closePopup()
	self:_layoutTabButtons()
end

function Window:GetFlag(flagName)
	return self.Flags[flagName]
end

function Window:SetFlag(flagName, value, silent)
	local element = self.Elements[flagName]
	if not element then return false end
	return element:Set(value, silent)
end

function Window:OnDestroy(fn)
	self._destroyCallbacks[#self._destroyCallbacks + 1] = fn
end

function Window:LoadAutoConfig()
	local meta = self.Config.Meta
	if meta.autoload and meta.last ~= "" then
		local ok, result = self.Config:Load(meta.last)
		if not ok then warn("[Qevrion] auto load failed: " .. tostring(result)) end
	end
end

function Window:_changed(element)
	local meta = self.Config.Meta
	if not (meta.autosave and element.Flag and element.Persist) then return end
	self._saveToken += 1
	local token = self._saveToken
	task.delay(0.8, function()
		if token ~= self._saveToken or self.Destroyed then return end
		local name = meta.last ~= "" and meta.last or self.DefaultConfig
		self.Config:Save(name)
	end)
end

function Window:_setPopup(frame, anchor)
	self._popup = { frame = frame, anchor = anchor }
end

function Window:_closePopup()
	local popup = self._popup
	self._popup = nil
	if popup and popup.frame then popup.frame:Destroy() end
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, fn in ipairs(self._destroyCallbacks) do
		local ok, err = pcall(fn)
		if not ok then warn("[Qevrion] OnDestroy error: " .. tostring(err)) end
	end
	for _, connection in ipairs(self._connections) do connection:Disconnect() end
	self._connections = {}
	self._dragFn, self._capture, self._popup = nil, nil, nil
	if self.Gui then self.Gui:Destroy() end
	if env.__QEVRION_WINDOWS[self.Name] == self then env.__QEVRION_WINDOWS[self.Name] = nil end
end

function Window:CreateSettingsTab(name, icon)
	local tab = self:CreateTab(name or "Settings", icon)
	local section = tab:CreateSection("Menu", "Look and behaviour of this window.")
	section:CreateKeybind({
		Name = "Menu key", Description = "Shows or hides the window.", Flag = "ui.menukey", Default = self.MenuKey,
		Callback = function(key) self:SetMenuKey(key) end,
	})
	section:CreateSlider({
		Name = "Menu scale", Description = "Size of the window.", Flag = "ui.scale", Min = 0.6, Max = 1.4, Step = 0.05, Default = self.UIScale.Scale,
		Callback = function(value) self:SetScale(value) end,
	})
	section:CreateButton({ Name = "Unload", Description = "Removes the window and stops the script.", ButtonText = "Unload", Callback = function() self:Destroy() end })
	return tab
end

function Window:CreateConfigTab(name, icon)
	local tab = self:CreateTab(name or "Config", icon)
	local config = self.Config
	local section = tab:CreateSection("Profiles", fileApi.ok and "Saved in the workspace folder." or "This executor has no file functions, configs cannot be saved.")
	local profile = section:CreateDropdown({
		Name = "Profile", Description = "Pick a saved config.", Options = config:List(), Persist = false,
	})
	local nameBox = section:CreateTextbox({ Name = "Name", Description = "Used by Save.", Placeholder = "config name", Default = config.Meta.last ~= "" and config.Meta.last or self.DefaultConfig, Persist = false, MaxLength = 40 })
	local function refreshList(select)
		profile:Refresh(config:List())
		if select then profile:Set(select, true) end
	end
	local function report(ok, result, doneText)
		self:Notify(ok and doneText or ("Failed: " .. tostring(result)), 3)
	end
	section:CreateButton({ Name = "Save", Description = "Writes the current values.", ButtonText = "Save", Callback = function()
		local ok, result = config:Save(nameBox:Get())
		report(ok, result, "Saved " .. tostring(result))
		if ok then refreshList(result) end
	end })
	section:CreateButton({ Name = "Load", Description = "Applies the selected profile.", ButtonText = "Load", Callback = function()
		local ok, result = config:Load(profile:Get())
		report(ok, result, "Loaded " .. tostring(profile:Get()))
	end })
	section:CreateButton({ Name = "Delete", Description = "Removes the selected profile.", ButtonText = "Delete", Callback = function()
		local ok, result = config:Delete(profile:Get())
		report(ok, result, "Deleted " .. tostring(profile:Get()))
		if ok then refreshList() end
	end })
	section:CreateButton({ Name = "Refresh", Description = "Reads the folder again.", ButtonText = "Refresh", Callback = function() refreshList() end })

	local options = tab:CreateSection("Automatic", "Save and load without clicking.")
	options:CreateToggle({ Name = "Auto save", Description = "Saves 0.8 s after a change.", Default = config.Meta.autosave, Persist = false, Callback = function(v) config:SetAutoSave(v) end })
	options:CreateToggle({ Name = "Auto load", Description = "Loads the last profile on start.", Default = config.Meta.autoload, Persist = false, Callback = function(v) config:SetAutoLoad(v) end })

	local share = tab:CreateSection("Share", "Move a config between machines.")
	local importBox = share:CreateTextbox({ Name = "Import JSON", Description = "Paste, then press Import.", Placeholder = "{...}", Persist = false })
	share:CreateButton({ Name = "Import", Description = "Applies the pasted JSON.", ButtonText = "Import", Callback = function()
		local ok, result = config:Import(importBox:Get())
		report(ok, result, "Imported " .. tostring(result) .. " values")
	end })
	share:CreateButton({ Name = "Copy JSON", Description = "Copies the current values.", ButtonText = "Copy", Callback = function()
		if type(setclipboard) == "function" and pcall(setclipboard, config:Export()) then
			self:Notify("Copied to the clipboard", 2)
		else
			self:Notify("This executor has no clipboard function", 3)
		end
	end })
	return tab
end

-- ------------------------------------------------------------------ CreateWindow

function Qevrion:CreateWindow(options)
	options = options or {}
	local name = tostring(options.Name or "Qevrion")

	local previous = env.__QEVRION_WINDOWS[name]
	if previous and previous.Destroy then pcall(previous.Destroy, previous) end

	local window = setmetatable({
		Name = name, Flags = {}, Elements = {}, Tabs = {}, TabsByName = {}, _connections = {}, _destroyCallbacks = {},
		_keybinds = {}, _tabCount = 0, _saveToken = 0, DefaultConfig = options.DefaultConfig or "default",
		MenuKey = resolveKey(options.MenuKey or "RightShift") or "RightShift",
	}, Window)
	if window.MenuKey == "None" then window.MenuKey = "RightShift" end
	window.Config = newConfig(window, options.ConfigFolder or name)
	env.__QEVRION_WINDOWS[name] = window

	local gui = create("ScreenGui", {
		Name = "Qevrion_" .. name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	gui.Parent = parentForGui()
	window.Gui = gui

	local main = create("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN_WIDTH, DESIGN_HEIGHT), BackgroundColor3 = THEME.Window, BorderSizePixel = 0,
		Visible = options.Visible ~= false,
	}, gui)
	addCorner(main, UDim.new(0, 16))
	addShadow(main, Color3.new(1, 1, 1), 0.75, UDim2.fromScale(0.01, 0.01))
	window.Main = main

	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local fit = math.min(1, viewport.X * 0.92 / DESIGN_WIDTH, viewport.Y * 0.92 / DESIGN_HEIGHT)
	window.UIScale = create("UIScale", { Scale = math.clamp(fit * (options.Scale or 1), 0.5, 1.6) }, main)

	-- sidebar: logo and tab buttons
	create("ImageLabel", {
		Name = "icon", Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(120, 120), BackgroundTransparency = 1, Image = LOGO_IMAGE,
	}, main)
	local sidebar = create("ScrollingFrame", {
		Name = "tabsToggles", Position = UDim2.fromOffset(0, 154), Size = UDim2.fromOffset(136, DESIGN_HEIGHT - 154 - 12),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 1, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	}, main)
	create("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, sidebar)
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) }, sidebar)
	window.SidebarList = sidebar

	-- two thin breaker lines between sidebar and content, as in the design
	local breakers = create("Folder", { Name = "breakers" }, main)
	for _, x in ipairs({ 135, 139.5 }) do
		create("Frame", { Name = "breaker", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0, 2.4, 1, 0), BackgroundColor3 = THEME.Line, BorderSizePixel = 0 }, breakers)
	end

	-- header: tab name, drag area, unload button
	local header = create("Frame", {
		Name = "header", Position = UDim2.fromOffset(142, 0), Size = UDim2.fromOffset(DESIGN_WIDTH - 142, 82),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, main)
	window.TabNameLabel = textLabel(header, {
		Name = "tabname", Position = UDim2.fromOffset(22, 12), Size = UDim2.fromOffset(420, 58), Text = "", FontFace = bodyFont(Enum.FontWeight.Medium), TextSize = 28,
	}, header)
	local unload = create("TextButton", {
		Name = "unloadbutton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = THEME.Pill, BorderSizePixel = 0, AutoButtonColor = false, Text = "×", FontFace = bodyFont(Enum.FontWeight.Medium),
		TextSize = 26, TextColor3 = THEME.Text,
	}, header)
	addCorner(unload, UDim.new(1, 0))
	unload.Activated:Connect(function() window:Destroy() end)

	window.Content = create("Frame", {
		Name = "tab", Position = UDim2.fromOffset(151, 91), Size = UDim2.fromOffset(DESIGN_WIDTH - 151 - 12, DESIGN_HEIGHT - 91 - 12),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, main)

	window.ToastLayer = create("Frame", {
		Name = "toasts", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(400, 220),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, gui)
	create("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, window.ToastLayer)

	-- dragging by the header
	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local start = mouseLocation()
		local grabX, grabY = start.X - main.AbsolutePosition.X, start.Y - main.AbsolutePosition.Y
		window._dragFn = function(point)
			local size = main.AbsoluteSize
			main.Position = UDim2.fromOffset(point.X - grabX + size.X / 2, point.Y - grabY + size.Y / 2)
		end
	end)

	-- one input listener per window: menu key, keybinds, key capture, popups and drags
	window:_connect(UserInputService.InputBegan, function(input, processed)
		if window._capture then
			window._capture:Capture(input)
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and window._popup then
			local point = mouseLocation()
			local popup = window._popup
			if not insideGui(popup.frame, point) and not insideGui(popup.anchor, point) then window:_closePopup() end
		end
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == window.MenuKey then
			window:Toggle()
			return
		end
		for _, keybind in ipairs(window._keybinds) do
			if keybind.Pressed and keybind:Matches(input) then
				local ok, err = pcall(keybind.Pressed, keybind.Value)
				if not ok then warn("[Qevrion] keybind error: " .. tostring(err)) end
			end
		end
	end)
	window:_connect(UserInputService.InputChanged, function(input)
		if window._dragFn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			window._dragFn(mouseLocation())
		end
	end)
	window:_connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			window._dragFn = nil
		end
	end)

	return window
end

function Qevrion:RegisterIcon() end

addCamelCaseAliases(Qevrion)
addCamelCaseAliases(Window)
addCamelCaseAliases(Group)
addCamelCaseAliases(Tab)
addCamelCaseAliases(Section)
addCamelCaseAliases(Element)
addCamelCaseAliases(Config)

env.QEVRION_LIBRARY = Qevrion
return Qevrion
