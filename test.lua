--[[
	Qevrion UI Library 2.0.0

	The window is not drawn by hand: it is built from a dump of StarterGui.Qevrion (every non-default
	property of all 72 instances, read from Studio on 2026-11-13) and the rows are clones of the
	design's own templates (toggletemplate, scrollbartemplate, chooseboxtemplate, tabtoggletemplate).
	The API matches the ARNZ library: CreateWindow, CreateTab, CreateSection and the Create* elements.

	Additions on top of the design: smooth tab switching, a window open/close tween and a click effect
	(white dots with a white UIShadow that fade out after 1.5 s).
	Choices that are mine and not in the design: the "on" green of the toggle, the selected tab colour,
	and the colour picker, keybind, textbox, button and label rows (the design has no template for them;
	they reuse the pill and card styles of the design). Descriptions appear as small gray text under a row name.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local env = (getgenv and getgenv()) or _G

local VERSION = "2.0.0"

-- decoders for the design dump below
local U, D, V2, C = UDim2.new, UDim.new, Vector2.new, Color3.new
local function E(path)
	local enumName, item = path:match("^(%w+)%.(%w+)$")
	return Enum[enumName][item]
end
local function NS(t)
	local keys = {}
	for i = 1, #t, 2 do keys[#keys + 1] = NumberSequenceKeypoint.new(t[i], t[i + 1]) end
	return NumberSequence.new(keys)
end
local function CS(t)
	local keys = {}
	for i = 1, #t, 4 do keys[#keys + 1] = ColorSequenceKeypoint.new(t[i], Color3.new(t[i + 1], t[i + 2], t[i + 3])) end
	return ColorSequence.new(keys)
end
local function F(family, weight, style)
	return Font.new(family, Enum.FontWeight[weight], Enum.FontStyle[style])
end
local function CT(uri)
	return { __content = uri }
end

-- StarterGui.Qevrion, dumped from Studio (place 113753057554487). Node = { class, name, properties, children }.
-- Not in the dump on purpose: BorderSizePixel (0 on every GuiObject, applied by build) and Name.
local SPEC = {"ScreenGui","Qevrion",{},{{"Frame","Main",{BackgroundColor3=C(1,1,1),Position=U(0.266264,0,0.21522,0),Size=U(0.466212,0,0.568371,0)},{{"UICorner","UICorner",{BottomLeftRadius=D(0,16),BottomRightRadius=D(0,16),TopLeftRadius=D(0,16),TopRightRadius=D(0,16)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Color=C(1,1,1),Spread=U(0.01,0,0.01,0),Transparency=0.75},{}},{"ImageLabel","icon",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,ImageContent=CT("rbxassetid://109220448678592"),Position=U(0.007,0,0.0167364,0),Size=U(0.135499,0,0.209205,0)},{{"UIAspectRatioConstraint","UIAspectRatioConstraint",{AspectRatio=1,AspectType=E("AspectType.ScaleWithParentSize")},{}}}},{"ScrollingFrame","tabsToggles",{Active=true,BackgroundColor3=C(1,1,1),BackgroundTransparency=1,Position=U(0.00677495,0,0.251046,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=1,Size=U(0,100,0,338),VerticalScrollBarPosition=E("VerticalScrollBarPosition.Left")},{{"Frame","Frame",{AutomaticSize=E("AutomaticSize.Y"),BackgroundColor3=C(1,1,1),Position=U(0,0,0.0146444,0),Size=U(0,100,1,0)},{{"ImageButton","tabtoggletemplate",{BackgroundColor3=C(1,1,1),Position=U(0.32,0,0,0),Size=U(0,65,0,65)},{{"UICorner","UICorner",{BottomLeftRadius=D(0,16),BottomRightRadius=D(0,16),TopLeftRadius=D(0,16),TopRightRadius=D(0,16)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"ImageLabel","ImageLabel",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,ImageContent=CT("rbxassetid://124046017123499"),Position=U(0.111538,0,0.111538,0),Size=U(0.75,0,0.75,0)},{}}}},{"UIListLayout","UIListLayout",{HorizontalAlignment=E("HorizontalAlignment.Center"),Padding=D(0.02,0),SortOrder=E("SortOrder.LayoutOrder")},{}}}}}},{"Frame","header",{BackgroundColor3=C(1,1,1),Position=U(0.15771,0,0,0),Size=U(0.842272,0,0.133891,0)},{{"UICorner","UICorner",{BottomLeftRadius=D(0,0),BottomRightRadius=D(0,0),TopLeftRadius=D(0,0),TopRightRadius=D(0,16)},{}},{"ImageButton","unloadbutton",{BackgroundColor3=C(1,1,1),ImageContent=CT("rbxassetid://1302869033"),Position=U(0.907324,0,0.134615,0),Size=U(0.0723929,0,0.703125,0)},{{"UICorner","UICorner",{BottomLeftRadius=D(0,16),BottomRightRadius=D(0,16),TopLeftRadius=D(0,16),TopRightRadius=D(0,16)},{}},{"TextLabel","label",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U(1,0,1,0),Text="×",TextColor3=C(0,0,0),TextScaled=true,TextSize=14,TextWrapped=true},{{"UICorner","UICorner",{BottomLeftRadius=D(0,16),BottomRightRadius=D(0,16),TopLeftRadius=D(0,16),TopRightRadius=D(0,16)},{}}}}}},{"TextLabel","tabname",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxassetid://12187362578","Medium","Normal"),Position=U(0.0289572,0,0.153846,0),Size=U(0.503533,0,0.78125,0),Text="tab_name",TextColor3=C(0,0,0),TextSize=28,TextXAlignment=E("TextXAlignment.Left")},{}}}},{"Folder","breakers",{},{{"Frame","breaker",{BackgroundColor3=C(0.243137,0.243137,0.243137),Position=U(0.155,0,0,0),Size=U(0.00270998,0,1,0)},{}},{"Frame","breaker",{BackgroundColor3=C(0.243137,0.243137,0.243137),Position=U(0.150404,0,0,0),Size=U(0.00270998,0,1,0)},{}}}},{"Frame","tab",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,Position=U(0.168019,0,0.148536,0),Size=U(0,601,0,394)},{{"Frame","Container",{BackgroundColor3=C(1,1,1),Position=U(0.0299501,0,0.0482234,0),Size=U(0,570,0,346)},{{"UIGridLayout","UIGridLayout",{CellPadding=U(0,0,0.05,0),CellSize=U(1,0,0.15,0),SortOrder=E("SortOrder.LayoutOrder")},{}},{"Frame","toggletemplate",{BackgroundColor3=C(1,1,1),Size=U(0,131,0,142)},{{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"UICorner","UICorner",{},{}},{"TextLabel","text",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxassetid://12187362578","Regular","Normal"),Position=U(0.0315789,0,0,0),Size=U(0,391,0,50),Text="Example Text",TextColor3=C(0,0,0),TextSize=15,TextXAlignment=E("TextXAlignment.Left")},{}},{"Frame","toggle",{BackgroundColor3=C(0.705882,0,0.0117647),Position=U(0.789474,0,0.26975,0),Size=U(0,100,0,22)},{{"UICorner","UICorner",{BottomLeftRadius=D(1,0),BottomRightRadius=D(1,0),TopLeftRadius=D(1,0),TopRightRadius=D(1,0)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"ImageButton","toggle",{BackgroundColor3=C(1,1,1),ImageContent=CT("rbxassetid://1302869033"),Position=U(0,0,-0.318182,0),Size=U(0,35,0,35)},{{"UICorner","UICorner",{BottomLeftRadius=D(1,0),BottomRightRadius=D(1,0),TopLeftRadius=D(1,0),TopRightRadius=D(1,0)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}}}}}}}},{"Frame","scrollbartemplate",{BackgroundColor3=C(1,1,1),Size=U(0,131,0,142)},{{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"UICorner","UICorner",{},{}},{"TextLabel","text",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxassetid://12187362578","Regular","Normal"),Position=U(0.0315789,0,0,0),Size=U(0,287,0,50),Text="Example Text",TextColor3=C(0,0,0),TextSize=15,TextXAlignment=E("TextXAlignment.Left")},{}},{"Frame","scrollbar",{BackgroundColor3=C(0.705882,0,0.0117647),Position=U(0.635088,0,0.26975,0),Size=U(0,188,0,22)},{{"UICorner","UICorner",{BottomLeftRadius=D(1,0),BottomRightRadius=D(1,0),TopLeftRadius=D(1,0),TopRightRadius=D(1,0)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"ImageButton","hand",{BackgroundColor3=C(1,1,1),ImageContent=CT("rbxassetid://1302869033"),Position=U(0,0,-0.318182,0),Size=U(0,18,0,35)},{{"UICorner","UICorner",{BottomLeftRadius=D(1,0),BottomRightRadius=D(1,0),TopLeftRadius=D(1,0),TopRightRadius=D(1,0)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"TextLabel","amount",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxassetid://12187371840","Regular","Normal"),Position=U(-2,0,0.0571429,0),Size=U(0,30,0,30),Text="0",TextColor3=C(0,0,0),TextSize=28},{}}}}}}}},{"Frame","chooseboxtemplate",{BackgroundColor3=C(1,1,1),Size=U(0,131,0,142)},{{"UIShadow","UIShadow",{BlurRadius=D(0,20),Transparency=0.5},{}},{"UICorner","UICorner",{},{}},{"TextLabel","text",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxassetid://12187362578","Regular","Normal"),Position=U(0.0315789,0,0,0),Size=U(0,287,0,50),Text="Example Text",TextColor3=C(0,0,0),TextSize=15,TextXAlignment=E("TextXAlignment.Left")},{}},{"Frame","selectBox",{BackgroundColor3=C(1,1,1),Position=U(0.742007,0,0.193737,0),Size=U(0.221965,0,0.566025,0)},{{"UICorner","UICorner",{BottomLeftRadius=D(1,0),BottomRightRadius=D(1,0),TopLeftRadius=D(1,0),TopRightRadius=D(1,0)},{}},{"UIStroke","UIStroke",{Thickness=2},{{"UIGradient","UIGradient",{Transparency=NS({0,0,0.00819672,0.5,0.0983607,0.75625,0.502732,0.975,0.903005,0.74375,0.990437,0.4875,1,0})},{}}}},{"TextLabel","selectedType",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxasset://fonts/families/Inconsolata.json","Bold","Normal"),Position=U(0.0462887,0,0.0433246,0),Size=U(0.474646,0,1.02476,0),Text="Example",TextColor3=C(0,0,0),TextScaled=true,TextSize=14,TextWrapped=true,TextXAlignment=E("TextXAlignment.Left")},{{"UIAspectRatioConstraint","UIAspectRatioConstraint",{AspectRatio=2.38462,AspectType=E("AspectType.ScaleWithParentSize")},{}},{"UITextSizeConstraint","UITextSizeConstraint",{MaxTextSize=27},{}}}},{"TextLabel","iconignorethistext",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Position=U(0.65,0,0,0),Rotation=90,Size=U(0.35,0,1,0),Text="»",TextColor3=C(0,0,0),TextScaled=true,TextSize=14,TextWrapped=true},{{"UITextSizeConstraint","UITextSizeConstraint",{MaxTextSize=39},{}}}}}},{"ScrollingFrame","selectBoxDrop",{Active=true,BackgroundColor3=C(1,1,1),CanvasSize=U(0,0,1.5,0),Position=U(0.742007,0,0.952441,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=4,Size=U(0.221965,0,1.38579,0),Visible=false},{{"UICorner","UICorner",{BottomLeftRadius=D(0,4),BottomRightRadius=D(0,4),TopLeftRadius=D(0,4),TopRightRadius=D(0,4)},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Color=C(1,1,1),Transparency=0.5},{}},{"UIListLayout","UIListLayout",{HorizontalAlignment=E("HorizontalAlignment.Center"),Padding=D(0.023,0),SortOrder=E("SortOrder.LayoutOrder")},{}},{"TextButton","selectButton",{BackgroundColor3=C(1,1,1),FontFace=F("rbxasset://fonts/families/Inconsolata.json","Regular","Normal"),Position=U(0.111888,0,0,0),Size=U(0.776224,0,0.410664,0),Text="Example",TextColor3=C(0,0,0),TextScaled=true,TextSize=14,TextWrapped=true},{{"UICorner","UICorner",{},{}},{"Frame","Outline",{BackgroundColor3=C(1,1,1),BackgroundTransparency=1,Size=U(1,0,1,0)},{{"UICorner","UICorner",{},{}},{"UIStroke","UIStroke",{},{{"UIGradient","UIGradient",{Transparency=NS({0,0,0.00136612,0.89375,0.501366,1,0.998634,0.88125,1,0})},{}}}}}},{"UIGradient","UIGradient",{Color=CS({0,0.705882,0.705882,0.705882,0.0934256,1,1,1,1,1,1,1}),Rotation=-90},{}},{"UIShadow","UIShadow",{BlurRadius=D(0,20),Color=C(1,1,1),Transparency=0.5},{}},{"UITextSizeConstraint","UITextSizeConstraint",{MaxTextSize=14},{}}}}}}}}}}}}}}}}

local DESIGN_SIZE = Vector2.new(723, 463) -- Main at the viewport the design was made in (723 x 463 px)
local TAB_HOST_PAD_X, TAB_HOST_PAD_Y = 10, 8

local THEME = {
	White = Color3.new(1, 1, 1),
	Text = Color3.new(0, 0, 0),
	Dim = Color3.fromRGB(110, 110, 110),
	Off = Color3.new(0.705882, 0, 0.0117647), -- toggle and slider track colour from the design
	On = Color3.fromRGB(0, 170, 70), -- not in the design: my choice for the "on" state
	TabIdle = Color3.new(1, 1, 1),
	TabSelected = Color3.fromRGB(226, 226, 226), -- not in the design
	Hover = Color3.fromRGB(240, 240, 240),
}

local FONT_ID = "rbxassetid://12187362578"
local function labelFont(weight)
	return Font.new(FONT_ID, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end
local function monoFont(weight)
	return Font.new("rbxasset://fonts/families/Inconsolata.json", weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

-- ------------------------------------------------------------------ small helpers

local function create(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

local function tween(instance, seconds, props, style, direction)
	local t = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function applyImage(instance, uri)
	local ok = pcall(function() instance.ImageContent = Content.fromUri(uri) end)
	if not ok then pcall(function() instance.Image = uri end) end
end

-- builds an Instance tree from a dump node
local function build(node, parent)
	local class, name, props, children = node[1], node[2], node[3], node[4]
	local ok, instance = pcall(Instance.new, class)
	if not ok or not instance then return nil end
	instance.Name = name
	for key, value in pairs(props) do
		if type(value) == "table" and value.__content then
			applyImage(instance, value.__content)
		else
			pcall(function() instance[key] = value end)
		end
	end
	if instance:IsA("GuiObject") then instance.BorderSizePixel = 0 end
	for _, child in ipairs(children) do build(child, instance) end
	instance.Parent = parent
	return instance
end

local function shadowOf(template)
	return template and template:FindFirstChildOfClass("UIShadow")
end

local function addShadow(parent, color, transparency)
	local ok, shadow = pcall(Instance.new, "UIShadow")
	if not ok or not shadow then return nil end
	pcall(function()
		shadow.BlurRadius = UDim.new(0, 20)
		shadow.Color = color or Color3.new(0, 0, 0)
		shadow.Transparency = transparency or 0.5
		shadow.ZIndex = -1
	end)
	shadow.Parent = parent
	return shadow
end

local function addCorner(parent, radius)
	return create("UICorner", { CornerRadius = radius or UDim.new(0, 8) }, parent)
end

local function textLabel(parent, props)
	local base = {
		BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = labelFont(), TextSize = 15,
		TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left,
	}
	for key, value in pairs(props) do base[key] = value end
	return create("TextLabel", base, parent)
end

local GuiService = game:GetService("GuiService")

-- AbsolutePosition is measured from below the top bar, GetMouseLocation from the top of the screen
local function mouseLocation()
	return UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
end

-- a point in AbsolutePosition space as a Position inside the window's ScreenGui
local function guiLocal(window, x, y)
	local origin = window.Gui.AbsolutePosition
	return UDim2.fromOffset(x - origin.X, y - origin.Y)
end

local function insideGui(gui, point)
	local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
	return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function formatNumber(value)
	return tostring(math.floor(value * 1000 + 0.5) / 1000)
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
	if type(name) ~= "string" then return nil end
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
		if type(value) == "function" and name:match("^%u") then extra[lowerFirst(name)] = value end
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
			if not pcall(makefolder, built) then return false end
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

function Element:Get() return self.Value end

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

function Element:Reset() return self:Set(self.Default) end
function Element:OnChanged(fn) self.Listeners[#self.Listeners + 1] = fn end
function Element:SetVisible(visible) self.Row.Visible = visible and true or false end

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
		Window = group.Window, Kind = kind, Listeners = {}, Persist = opts.Persist ~= false,
		Flag = opts.Flag, Name = opts.Name or kind,
	}, Element)
	if opts.Callback then element.Listeners[1] = opts.Callback end
	return element
end

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

-- ------------------------------------------------------------------ rows (clones of the design templates)

local function makeRow(group, templateName, name, description)
	local window = group.Window
	local row = window.Templates[templateName]:Clone()
	row.Name = name or templateName
	row.LayoutOrder = group.Tab:_nextOrder()
	local label = row:FindFirstChild("text")
	if label then
		label.Text = name or ""
		label.TextTruncate = Enum.TextTruncate.AtEnd
		if description and description ~= "" then
			local x = label.Position.X
			label.Position = UDim2.new(x.Scale, x.Offset, 0, -9)
			local small = label:Clone()
			small.Name = "description"
			small.Text = description
			small.TextSize = 11
			small.TextColor3 = THEME.Dim
			small.Position = UDim2.new(x.Scale, x.Offset, 0, 27)
			small.Size = UDim2.new(0, label.Size.X.Offset, 0, 16)
			small.Parent = row
		end
	end
	row.Parent = group.Container
	return row, label
end

-- a plain row without the template's own control (labels, buttons, pills)
local function makePlainRow(group, name, description)
	local row, label = makeRow(group, "toggle", name, description)
	local control = row:FindFirstChild("toggle")
	if control then control:Destroy() end
	return row, label
end

-- a pill in the style of the design's dropdown box
local function makePill(window, row, width, height)
	local pill = window.Templates.choose.selectBox:Clone()
	for _, childName in ipairs({ "selectedType", "iconignorethistext" }) do
		local child = pill:FindFirstChild(childName)
		if child then child:Destroy() end
	end
	pill.Name = "pill"
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -20, 0.5, 0)
	pill.Size = UDim2.fromOffset(width, height or 29)
	pill.Parent = row
	return pill
end

local function pillButton(pill)
	return create("TextButton", {
		Name = "hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5,
	}, pill)
end

local function newPopup(window, size)
	local scale = window.UIScale.Scale
	local frame = create("Frame", { Name = "popup", Size = size, BackgroundColor3 = THEME.White, BorderSizePixel = 0, ZIndex = 100 }, window.Gui)
	addCorner(frame, UDim.new(0, 8))
	local shadow = shadowOf(window.Templates.toggle)
	if shadow then shadow:Clone().Parent = frame else addShadow(frame, Color3.new(0, 0, 0), 0.5) end
	local uiScale = create("UIScale", { Scale = scale * 0.9 }, frame)
	tween(uiScale, 0.16, { Scale = scale }, Enum.EasingStyle.Quad)
	return frame
end

-- ------------------------------------------------------------------ groups (tabs and sections create elements)

local Group = {}
Group.__index = Group

function Group:CreateToggle(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Toggle")
	local row = makeRow(self, "toggle", opts.Name, opts.Description)
	element.Row = row
	local track = row:FindFirstChild("toggle")
	local knob = track:FindFirstChild("toggle")
	local knobOff = knob.Position
	local knobOn = UDim2.new(1, -knob.Size.X.Offset, knobOff.Y.Scale, knobOff.Y.Offset)

	knob.Activated:Connect(function() element:Set(not element.Value) end)
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			element:Set(not element.Value)
		end
	end)

	function element:Validate(value)
		if type(value) ~= "boolean" then return false end
		return true, value
	end
	function element:Render()
		local on = self.Value == true
		tween(track, 0.22, { BackgroundColor3 = on and THEME.On or THEME.Off })
		tween(knob, 0.28, { Position = on and knobOn or knobOff }, Enum.EasingStyle.Back)
	end
	-- the first render should not animate from the template's colour
	local default = opts.Default == true
	track.BackgroundColor3 = default and THEME.On or THEME.Off
	knob.Position = default and knobOn or knobOff
	return finishElement(element, opts, default)
end

function Group:CreateSlider(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Slider")
	local suffix = opts.Suffix or ""
	local displayName = opts.Name
	if suffix ~= "" and displayName then displayName = displayName .. " (" .. suffix .. ")" end
	local row = makeRow(self, "slider", displayName, opts.Description)
	element.Row = row
	element.Min = opts.Min or 0
	element.Max = opts.Max or 100
	element.Step = (opts.Step and opts.Step > 0) and opts.Step or 1

	local track = row:FindFirstChild("scrollbar")
	local hand = track:FindFirstChild("hand")
	local amount = hand:FindFirstChild("amount")
	local handWidth = hand.Size.X.Offset

	local function snap(value)
		local snapped = element.Min + math.floor((value - element.Min) / element.Step + 0.5) * element.Step
		snapped = math.clamp(snapped, element.Min, element.Max)
		return tonumber(string.format("%.6f", snapped))
	end
	local function fromMouse(point)
		local width = track.AbsoluteSize.X - hand.AbsoluteSize.X
		if width <= 0 then return end
		local fraction = math.clamp((point.X - track.AbsolutePosition.X - hand.AbsoluteSize.X / 2) / width, 0, 1)
		element:Set(snap(element.Min + (element.Max - element.Min) * fraction))
	end
	local function begin(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			element.Window._dragFn = fromMouse
			fromMouse(mouseLocation())
		end
	end
	track.InputBegan:Connect(begin)
	hand.InputBegan:Connect(begin)

	function element:Validate(value)
		if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return false end
		return true, snap(value)
	end
	function element:Render()
		local range = self.Max - self.Min
		local fraction = range > 0 and (self.Value - self.Min) / range or 0
		local y = hand.Position.Y
		local target = UDim2.new(fraction, -handWidth * fraction, y.Scale, y.Offset)
		if self.Window._dragFn then hand.Position = target else tween(hand, 0.12, { Position = target }, Enum.EasingStyle.Quad) end
		local text = formatNumber(self.Value)
		amount.Text = text
		-- the design shows one big digit inside the hand; longer numbers get a smaller font so they stay readable
		amount.TextSize = #text <= 1 and 28 or math.max(11, math.floor(44 / #text))
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
	local row = makeRow(self, "choose", opts.Name, opts.Description)
	element.Row = row
	element.Options = {}
	for _, option in ipairs(opts.Options or {}) do element.Options[#element.Options + 1] = tostring(option) end
	local allowCustom = opts.AllowCustom == true

	local pill = row:FindFirstChild("selectBox")
	local selected = pill:FindFirstChild("selectedType")
	local leftover = row:FindFirstChild("selectBoxDrop")
	if leftover then leftover:Destroy() end
	local hit = pillButton(pill)

	local function openList()
		local window = element.Window
		local count = #element.Options
		if count == 0 then return end
		local scale = window.UIScale.Scale
		local template = window.Templates.drop
		local list = template:Clone()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		local visibleItems = math.min(count, 4)
		list.Name = "dropdown"
		list.Visible = true
		list.ZIndex = 100
		list.AnchorPoint = Vector2.new(1, 0)
		local fullSize = UDim2.fromOffset(math.max(pill.AbsoluteSize.X / scale, 120), visibleItems * 32 + 8)
		list.Size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 0)
		list.Position = guiLocal(window, pill.AbsolutePosition.X + pill.AbsoluteSize.X, pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 6)
		list.CanvasSize = UDim2.fromOffset(0, count * 32 + 8)
		list.ScrollingDirection = Enum.ScrollingDirection.Y
		local layout = list:FindFirstChildOfClass("UIListLayout")
		if layout then layout.Padding = UDim.new(0, 3) end
		create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, list)
		create("UIScale", { Scale = scale }, list)
		for index, option in ipairs(element.Options) do
			local item = window.Templates.option:Clone()
			item.Name = option
			item.Text = option
			item.LayoutOrder = index
			item.Position = UDim2.new()
			item.Size = UDim2.new(0.776224, 0, 0, 29)
			item.AutoButtonColor = false
			if option == element.Value then item.TextColor3 = THEME.On end
			item.Parent = list
			item.MouseEnter:Connect(function() tween(item, 0.1, { BackgroundTransparency = 0.25 }, Enum.EasingStyle.Quad) end)
			item.MouseLeave:Connect(function() tween(item, 0.1, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad) end)
			item.Activated:Connect(function()
				element:Set(option)
				window:_closePopup()
			end)
		end
		list.Parent = window.Gui
		-- opens from the top down
		tween(list, 0.24, { Size = fullSize }, Enum.EasingStyle.Quint)
		window:_setPopup(list, pill)
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
			if self.Options[1] then
				self:Set(self.Options[1], true)
			else
				self.Value = ""
				if self.Flag then self.Window.Flags[self.Flag] = "" end
				self:Render()
			end
		end
	end
	local default = opts.Default
	if default == nil or (not allowCustom and not table.find(element.Options, default)) then default = element.Options[1] or "" end
	return finishElement(element, opts, default)
end

function Group:CreateTextbox(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Textbox")
	local row = makePlainRow(self, opts.Name, opts.Description)
	element.Row = row
	local maxLength = opts.MaxLength
	local pill = makePill(element.Window, row, 190)
	local box = create("TextBox", {
		Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		FontFace = monoFont(Enum.FontWeight.Bold), TextSize = 14, TextColor3 = THEME.Text, PlaceholderText = opts.Placeholder or "",
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
	function element:Render() box.Text = self.Value end
	return finishElement(element, opts, tostring(opts.Default or ""))
end

function Group:CreateButton(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Button")
	local row = makePlainRow(self, opts.Name, opts.Description)
	element.Row = row
	local pill = makePill(element.Window, row, 120)
	local caption = textLabel(pill, {
		Size = UDim2.fromScale(1, 1), Text = opts.ButtonText or "Run", FontFace = monoFont(Enum.FontWeight.Bold),
		TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local hit = pillButton(pill)
	hit.MouseEnter:Connect(function() tween(pill, 0.12, { BackgroundColor3 = THEME.Hover }, Enum.EasingStyle.Quad) end)
	hit.MouseLeave:Connect(function() tween(pill, 0.12, { BackgroundColor3 = THEME.White }, Enum.EasingStyle.Quad) end)
	hit.Activated:Connect(function()
		for _, listener in ipairs(element.Listeners) do
			local ok, err = pcall(listener)
			if not ok then warn("[Qevrion] button error: " .. tostring(err)) end
		end
	end)

	function element:Validate() return false end
	function element:Render() end
	function element:SetText(text) caption.Text = tostring(text) end
	return finishElement(element, opts, nil)
end

function Group:CreateLabel(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Label")
	local row = makePlainRow(self, opts.Name, nil)
	element.Row = row
	local value = textLabel(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.new(0, 260, 1, 0),
		Text = tostring(opts.Description or ""), TextSize = 13, TextColor3 = THEME.Dim, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	function element:Validate() return false end
	function element:Render() end
	function element:SetText(text) value.Text = tostring(text) end
	return finishElement(element, opts, nil)
end

function Group:CreateKeybind(opts)
	opts = opts or {}
	local element = newElement(self, opts, "Keybind")
	local row = makePlainRow(self, opts.Name, opts.Description)
	element.Row = row
	element.Pressed = opts.Pressed
	local window = element.Window
	local pill = makePill(window, row, 130)
	local caption = textLabel(pill, {
		Size = UDim2.fromScale(1, 1), FontFace = monoFont(Enum.FontWeight.Bold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local hit = pillButton(pill)
	local listening = false
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
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then self:Set("None") else self:Set(input.KeyCode.Name) end
		else
			self:Render()
		end
	end
	hit.Activated:Connect(function()
		if listening then return end
		listening = true
		window._capture = element
		caption.Text = "press a key..."
	end)

	function element:Validate(value)
		local key = resolveKey(value)
		if not key then return false end
		return true, key
	end
	function element:Render() caption.Text = tostring(self.Value) end
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
	local row = makePlainRow(self, opts.Name, opts.Description)
	element.Row = row
	local pill = makePill(element.Window, row, 64, 26)
	local hit = pillButton(pill)

	local hue, sat, val = 0, 1, 1
	local function openPicker()
		local window = element.Window
		local frame = newPopup(window, UDim2.fromOffset(196, 176))
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = guiLocal(window, pill.AbsolutePosition.X + pill.AbsoluteSize.X, pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 6)

		local square = create("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(176, 104), BorderSizePixel = 0 }, frame)
		addCorner(square, UDim.new(0, 6))
		local whiteLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.White, BorderSizePixel = 0 }, square)
		addCorner(whiteLayer, UDim.new(0, 6))
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, whiteLayer)
		local blackLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, square)
		addCorner(blackLayer, UDim.new(0, 6))
		create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, blackLayer)
		local squareCursor = create("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0 }, square)
		addCorner(squareCursor, UDim.new(1, 0))
		create("UIStroke", { Thickness = 2, Color = THEME.White }, squareCursor)

		local bar = create("Frame", { Position = UDim2.fromOffset(10, 124), Size = UDim2.fromOffset(176, 12), BackgroundColor3 = THEME.White, BorderSizePixel = 0 }, frame)
		addCorner(bar, UDim.new(1, 0))
		local rainbow = {}
		for i = 0, 6 do rainbow[#rainbow + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i == 6 and 0.999 or i / 6, 1, 1)) end
		create("UIGradient", { Color = ColorSequence.new(rainbow) }, bar)
		local barCursor = create("Frame", { Size = UDim2.fromOffset(6, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.White, BorderSizePixel = 0 }, bar)
		addCorner(barCursor, UDim.new(1, 0))
		create("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = 0.3 }, barCursor)

		local hexBox = create("TextBox", {
			Position = UDim2.fromOffset(10, 144), Size = UDim2.fromOffset(176, 24), BackgroundColor3 = THEME.Hover, BorderSizePixel = 0,
			FontFace = monoFont(Enum.FontWeight.Bold), TextSize = 14, TextColor3 = THEME.Text, ClearTextOnFocus = false, Text = "",
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
		window:_setPopup(frame, pill)
	end
	hit.Activated:Connect(function()
		local window = element.Window
		if window._popup and window._popup.anchor == pill then window:_closePopup() else window:_closePopup() openPicker() end
	end)

	function element:Validate(value)
		if typeof(value) == "Color3" then return true, value end
		local color = hexToColor(value)
		if color then return true, color end
		return false
	end
	function element:Render()
		tween(pill, 0.15, { BackgroundColor3 = self.Value }, Enum.EasingStyle.Quad)
		hue, sat, val = self.Value:ToHSV()
	end
	local default = opts.Default
	if typeof(default) ~= "Color3" then default = hexToColor(default) or THEME.White end
	return finishElement(element, opts, default)
end

-- ------------------------------------------------------------------ tabs and sections

local Section = setmetatable({}, { __index = Group })
Section.__index = Section

local Tab = setmetatable({}, { __index = Group })
Tab.__index = Tab

function Tab:_nextOrder()
	self._order += 1
	return self._order
end

-- a section is a heading row in the tab's list, followed by its elements
function Tab:CreateSection(title, description)
	local window = self.Window
	local hasDescription = description ~= nil and description ~= ""
	local row = window.Templates.toggle:Clone()
	row.Name = "section"
	row.LayoutOrder = self:_nextOrder()
	row.BackgroundTransparency = 1
	for _, childName in ipairs({ "toggle", "UIShadow", "UICorner" }) do
		local child = row:FindFirstChild(childName)
		if child then child:Destroy() end
	end
	local label = row:FindFirstChild("text")
	label.Text = tostring(title or "")
	label.FontFace = labelFont(Enum.FontWeight.Bold)
	label.TextSize = 18
	label.Position = UDim2.new(0.0315789, 0, 0, hasDescription and -9 or 0)
	if hasDescription then
		local small = label:Clone()
		small.Name = "description"
		small.Text = description
		small.FontFace = labelFont()
		small.TextSize = 12
		small.TextColor3 = THEME.Dim
		small.Position = UDim2.new(0.0315789, 0, 0, 26)
		small.Size = UDim2.new(0, 391, 0, 16)
		small.Parent = row
	end
	row.Parent = self.Container
	return setmetatable({ Window = window, Tab = self, Container = self.Container, Header = row }, Section)
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
	if pcall(function() return CoreGui.Name end) then return CoreGui end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Window:_connect(signal, fn)
	local connection = signal:Connect(fn)
	self._connections[#self._connections + 1] = connection
	return connection
end

-- buttons keep the design's 65 px; the sidebar scrolls and follows the selected tab
local TAB_SIZE, TAB_GAP, TAB_TOP = 65, 6, 5

function Window:_layoutTabButtons()
	local layout = self.TabList:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Padding = UDim.new(0, TAB_GAP) end
	for _, button in ipairs(self.TabList:GetChildren()) do
		if button:IsA("GuiButton") then button.Size = UDim2.fromOffset(TAB_SIZE, TAB_SIZE) end
	end
end

function Window:_scrollTabIntoView(tab)
	local list = self.Main:FindFirstChild("tabsToggles")
	local index = table.find(self.Tabs, tab)
	if not list or not index or self.Destroyed then return end
	local scale = self.UIScale.Scale
	local viewHeight = list.AbsoluteWindowSize.Y / scale
	local canvasHeight = list.AbsoluteCanvasSize.Y / scale
	local centre = TAB_TOP + (index - 1) * (TAB_SIZE + TAB_GAP) + TAB_SIZE / 2
	local target = math.clamp(centre - viewHeight / 2, 0, math.max(0, canvasHeight - viewHeight))
	tween(list, 0.3, { CanvasPosition = Vector2.new(0, target) }, Enum.EasingStyle.Quad)
end

function Window:CreateTab(name, icon)
	name = tostring(name or "Tab")
	local tab = setmetatable({ Window = self, Name = name, _order = 0 }, Tab)
	tab.Tab = tab

	-- sidebar button: a clone of tabtoggletemplate, with the tab name as a small caption
	local button = self.Templates.tab:Clone()
	button.Name = name
	button.LayoutOrder = #self.Tabs + 1
	local hasIcon = false
	-- the design's button is a plain white square with an ImageLabel (75%) inside it: the icon goes there
	local iconLabel = button:FindFirstChild("ImageLabel") or button
	if type(icon) == "number" then
		applyImage(iconLabel, "rbxassetid://" .. icon)
		hasIcon = true
	elseif type(icon) == "string" and icon:match("^rbxassetid://") then
		applyImage(iconLabel, icon)
		hasIcon = true
	end
	local buttonScale = create("UIScale", { Scale = 1 }, button)
	textLabel(button, {
		Name = "caption", Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -17), Text = name,
		FontFace = labelFont(Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
	})
	button:FindFirstChild("caption").Visible = not hasIcon
	button.Parent = self.TabList
	self:_layoutTabButtons()

	-- content: a CanvasGroup (so the whole page can fade) holding a scrolling list laid out by the design's grid
	local host = create("CanvasGroup", {
		Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Position = self._hostPosition, Size = self._hostSize,
		GroupTransparency = 1, Visible = false,
	}, self.TabFrame)
	local scroll = create("ScrollingFrame", {
		Name = "Container", Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.White, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Text, ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, host)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, TAB_HOST_PAD_X), PaddingRight = UDim.new(0, TAB_HOST_PAD_X),
		PaddingTop = UDim.new(0, TAB_HOST_PAD_Y), PaddingBottom = UDim.new(0, TAB_HOST_PAD_Y),
	}, scroll)
	local grid = self.Templates.grid:Clone()
	-- the design's cell height is a scale of the 346 px Container; pin it in pixels because this page is a little taller
	grid.CellSize = UDim2.new(grid.CellSize.X.Scale, grid.CellSize.X.Offset, 0, self._cellHeight)
	grid.CellPadding = UDim2.new(grid.CellPadding.X.Scale, grid.CellPadding.X.Offset, 0, self._cellGap)
	grid.Parent = scroll

	tab.Button, tab.ButtonScale, tab.Host, tab.Container = button, buttonScale, host, scroll
	button.Activated:Connect(function() self:SelectTab(name) end)
	button.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then tween(buttonScale, 0.18, { Scale = 1.06 }, Enum.EasingStyle.Quad) end
	end)
	button.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then tween(buttonScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Quad) end
	end)

	self.Tabs[#self.Tabs + 1] = tab
	self.TabsByName[name] = tab
	if not self.CurrentTab then self:SelectTab(name) end
	return tab
end

function Window:SelectTab(name)
	local target = self.TabsByName[name]
	if not target or target == self.CurrentTab then return end
	self:_closePopup()
	local previous = self.CurrentTab
	self.CurrentTab = target

	-- header title: slides out to the left, then the new name slides in from the right
	local label = self.TabNameLabel
	local base = self._tabNamePosition
	self._nameToken += 1
	local token = self._nameToken
	if previous then
		tween(label, 0.1, { TextTransparency = 1, Position = base + UDim2.fromOffset(-14, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.1, function()
			if token ~= self._nameToken or self.Destroyed then return end
			label.Text = target.Name
			label.Position = base + UDim2.fromOffset(16, 0)
			tween(label, 0.3, { TextTransparency = 0, Position = base })
		end)
	else
		label.Text = target.Name
	end

	-- sidebar buttons
	for _, tab in ipairs(self.Tabs) do
		local active = tab == target
		tween(tab.Button, 0.25, { BackgroundColor3 = active and THEME.TabSelected or THEME.TabIdle }, Enum.EasingStyle.Quad)
		tween(tab.ButtonScale, 0.3, { Scale = active and 1.1 or 1 }, Enum.EasingStyle.Back)
	end

	-- page: the old one fades and drifts left, the new one fades in from the right
	local hostBase = self._hostPosition
	if previous then
		local leaving = previous.Host
		tween(leaving, 0.18, { GroupTransparency = 1, Position = hostBase + UDim2.fromOffset(-22, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.18, function()
			if self.CurrentTab ~= previous and not self.Destroyed then leaving.Visible = false end
		end)
	end
	local entering = target.Host
	entering.Position = hostBase + UDim2.fromOffset(26, 0)
	entering.GroupTransparency = 1
	entering.Visible = true
	tween(entering, 0.38, { GroupTransparency = 0, Position = hostBase })
	task.defer(function() self:_scrollTabIntoView(target) end)
end

function Window:Notify(text, seconds)
	if type(text) == "table" then
		seconds = text.Duration or seconds
		text = text.Text or text.Title or ""
	end
	text = tostring(text or "")
	seconds = tonumber(seconds) or 3
	local toast = create("TextLabel", {
		Size = UDim2.new(0, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = THEME.White, BorderSizePixel = 0,
		Text = text, FontFace = labelFont(Enum.FontWeight.Medium), TextSize = 15, TextColor3 = THEME.Text,
		BackgroundTransparency = 1, TextTransparency = 1, LayoutOrder = math.floor(os.clock() * 1000),
	}, self.ToastLayer)
	addCorner(toast, UDim.new(0, 12))
	local shadow = addShadow(toast, Color3.new(0, 0, 0), 1)
	create("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) }, toast)
	tween(toast, 0.3, { BackgroundTransparency = 0, TextTransparency = 0 })
	if shadow then tween(shadow, 0.3, { Transparency = 0.5 }) end
	task.delay(seconds, function()
		if not toast.Parent then return end
		local fade = tween(toast, 0.3, { BackgroundTransparency = 1, TextTransparency = 1 }, Enum.EasingStyle.Quad)
		if shadow then tween(shadow, 0.3, { Transparency = 1 }, Enum.EasingStyle.Quad) end
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

-- white dots with a white UIShadow, thrown out from the click point, gone after 1.5 seconds
function Window:_clickEffect(point)
	point = point - self.FxLayer.AbsolutePosition
	local count = 9
	local offsetAngle = math.random() * math.pi * 2
	for i = 1, count do
		local angle = offsetAngle + (i / count) * math.pi * 2 + (math.random() - 0.5) * 0.5
		local distance = math.random(30, 78)
		local size = math.random(5, 9)
		local dot = create("Frame", {
			Name = "dot", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(point.X, point.Y),
			BackgroundColor3 = THEME.White, BorderSizePixel = 0,
		}, self.FxLayer)
		addCorner(dot, UDim.new(1, 0))
		local shadow = addShadow(dot, THEME.White, 0.2)
		local target = UDim2.fromOffset(point.X + math.cos(angle) * distance, point.Y + math.sin(angle) * distance)
		tween(dot, 1.5, { Position = target, BackgroundTransparency = 1 }, Enum.EasingStyle.Quart)
		if shadow then tween(shadow, 1.5, { Transparency = 1 }, Enum.EasingStyle.Quad) end
		task.delay(1.55, function() dot:Destroy() end)
	end
end

function Window:SetVisible(visible)
	visible = visible and true or false
	if visible == self._shown then return end
	self._shown = visible
	self._visibleToken += 1
	local token = self._visibleToken
	local scale = self._scale
	if visible then
		self.UIScale.Scale = scale * 0.92
		self.Main.Visible = true
		tween(self.UIScale, 0.34, { Scale = scale }, Enum.EasingStyle.Back)
	else
		self:_closePopup()
		tween(self.UIScale, 0.18, { Scale = scale * 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.18, function()
			if token == self._visibleToken and not self.Destroyed then
				self.Main.Visible = false
				self.UIScale.Scale = scale
			end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self._shown)
end

function Window:SetMenuKey(key)
	local resolved = resolveKey(key)
	if resolved and resolved ~= "None" and resolved:sub(1, 5) ~= "Mouse" then self.MenuKey = resolved end
end

function Window:SetScale(scale)
	if type(scale) ~= "number" then return end
	self._scale = math.clamp(scale, 0.5, 1.8)
	self.UIScale.Scale = self._scale
	self:_closePopup()
end

function Window:GetFlag(flagName) return self.Flags[flagName] end

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
		self.Config:Save(meta.last ~= "" and meta.last or self.DefaultConfig)
	end)
end

function Window:_setPopup(frame, anchor)
	self._popup = { frame = frame, anchor = anchor }
end

function Window:_closePopup()
	local popup = self._popup
	self._popup = nil
	if not (popup and popup.frame) then return end
	local frame = popup.frame
	if frame.Name == "dropdown" and not self.Destroyed then
		-- closes bottom up, and stops taking clicks while it does
		tween(frame, 0.14, { Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.16, function() frame:Destroy() end)
		for _, item in ipairs(frame:GetChildren()) do
			if item:IsA("GuiButton") then item.Active = false end
		end
	else
		frame:Destroy()
	end
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	-- the Activated handler can run on a thread without Instance capability; restore a normal identity first
	if setthreadidentity then pcall(setthreadidentity, 8) end
	for _, fn in ipairs(self._destroyCallbacks) do
		-- own thread per callback: game code called from a cleanup can leave its thread without Instance capability
		task.spawn(function()
			local ok, err = pcall(fn)
			if not ok then warn("[Qevrion] OnDestroy error: " .. tostring(err)) end
		end)
	end
	for _, connection in ipairs(self._connections) do connection:Disconnect() end
	self._connections = {}
	self._dragFn, self._capture, self._popup = nil, nil, nil
	if self.Gui then
		local gui = self.Gui
		if not pcall(gui.Destroy, gui) then
			-- a cleanup callback may have lowered the thread identity; retry with a normal one, then on a fresh thread
			pcall(function() if setthreadidentity then setthreadidentity(8) end gui:Destroy() end)
			if gui.Parent then task.defer(function() pcall(gui.Destroy, gui) end) end
		end
	end
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
		Name = "Menu scale", Description = "Size of the window.", Flag = "ui.scale", Min = 0.6, Max = 1.8, Step = 0.05, Default = self._scale,
		Callback = function(value) self:SetScale(value) end,
	})
	section:CreateToggle({
		Name = "Click effect", Description = "White dots when you click.", Flag = "ui.clickeffect", Default = self._clickEffectEnabled,
		Callback = function(value) self._clickEffectEnabled = value end,
	})
	section:CreateButton({ Name = "Unload", Description = "Removes the window and stops the script.", ButtonText = "Unload", Callback = function() self:Destroy() end })
	return tab
end

function Window:CreateConfigTab(name, icon)
	local tab = self:CreateTab(name or "Config", icon)
	local config = self.Config
	local section = tab:CreateSection("Profiles", fileApi.ok and "Saved in the workspace folder." or "This executor has no file functions, configs cannot be saved.")
	local profile = section:CreateDropdown({ Name = "Profile", Description = "Pick a saved config.", Options = config:List(), Persist = false })
	local nameBox = section:CreateTextbox({
		Name = "Name", Description = "Used by Save.", Placeholder = "config name",
		Default = config.Meta.last ~= "" and config.Meta.last or self.DefaultConfig, Persist = false, MaxLength = 40,
	})
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
		_keybinds = {}, _saveToken = 0, _nameToken = 0, _visibleToken = 0, DefaultConfig = options.DefaultConfig or "default",
		MenuKey = resolveKey(options.MenuKey or "RightShift") or "RightShift",
		_clickEffectEnabled = options.ClickEffect ~= false, _scale = options.Scale or 1,
	}, Window)
	if window.MenuKey == "None" then window.MenuKey = "RightShift" end
	window.Config = newConfig(window, options.ConfigFolder or name)
	env.__QEVRION_WINDOWS[name] = window

	-- the design, built from the dump
	local gui = build(SPEC, nil)
	gui.Name = "Qevrion_" .. name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 100
	local main = gui:FindFirstChild("Main")
	local container = main.tab.Container

	-- templates are lifted out of the tree and cloned per element
	local templates = {
		grid = container:FindFirstChildOfClass("UIGridLayout"):Clone(),
		toggle = container.toggletemplate, slider = container.scrollbartemplate, choose = container.chooseboxtemplate,
		tab = main.tabsToggles.Frame.tabtoggletemplate,
	}
	templates.drop = templates.choose.selectBoxDrop
	templates.option = templates.drop.selectButton
	templates.toggle.Parent, templates.slider.Parent, templates.choose.Parent, templates.tab.Parent = nil, nil, nil, nil
	templates.option.Parent = nil
	window.Templates = templates

	-- where a tab page goes: exactly where the design's Container sits, with room around it for the row shadows
	local tabFrame = main.tab
	window.TabFrame = tabFrame
	window._hostSize = UDim2.fromOffset(container.Size.X.Offset + TAB_HOST_PAD_X * 2, container.Size.Y.Offset + TAB_HOST_PAD_Y * 2)
	window._cellHeight = templates.grid.CellSize.Y.Scale * container.Size.Y.Offset
	window._cellGap = templates.grid.CellPadding.Y.Scale * container.Size.Y.Offset
	window._hostPosition = UDim2.fromOffset(
		container.Position.X.Scale * tabFrame.Size.X.Offset + container.Position.X.Offset - TAB_HOST_PAD_X,
		container.Position.Y.Scale * tabFrame.Size.Y.Offset + container.Position.Y.Offset - TAB_HOST_PAD_Y)
	container:Destroy()

	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.Size = UDim2.fromOffset(DESIGN_SIZE.X, DESIGN_SIZE.Y)
	main.Visible = options.Visible ~= false
	window._shown = main.Visible
	window.Main, window.Gui = main, gui
	window.UIScale = create("UIScale", { Scale = window._scale }, main)

	local tabsToggles = main.tabsToggles
	tabsToggles.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabsToggles.CanvasSize = UDim2.new()
	tabsToggles.ScrollBarThickness = 3
	tabsToggles.ScrollingDirection = Enum.ScrollingDirection.Y
	window.TabList = tabsToggles.Frame

	local header = main.header
	window.TabNameLabel = header.tabname
	window.TabNameLabel.Text = ""
	window._tabNamePosition = window.TabNameLabel.Position
	local unload = header.unloadbutton
	unload.Activated:Connect(function() window:Destroy() end)
	unload.MouseEnter:Connect(function() tween(unload, 0.15, { BackgroundColor3 = THEME.Hover }, Enum.EasingStyle.Quad) end)
	unload.MouseLeave:Connect(function() tween(unload, 0.15, { BackgroundColor3 = THEME.White }, Enum.EasingStyle.Quad) end)

	window.ToastLayer = create("Frame", {
		Name = "toasts", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(420, 220),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, gui)
	create("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, window.ToastLayer)
	window.FxLayer = create("Frame", {
		Name = "fx", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 500, Active = false,
	}, gui)

	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	gui.Parent = parentForGui()

	-- dragging by the header
	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local start = mouseLocation()
		local grabX, grabY = start.X - main.AbsolutePosition.X, start.Y - main.AbsolutePosition.Y
		window._dragFn = function(point)
			local size, origin = main.AbsoluteSize, gui.AbsolutePosition
			main.Position = UDim2.fromOffset(point.X - grabX - origin.X + size.X / 2, point.Y - grabY - origin.Y + size.Y / 2)
		end
	end)

	-- one input listener per window: menu key, keybinds, key capture, popups, drags and the click effect
	window:_connect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if window._clickEffectEnabled and window._shown then window:_clickEffect(mouseLocation()) end
		end
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
