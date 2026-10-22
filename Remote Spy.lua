-- =======================================================================
--   CUSTOM INTERACTION & REMOTE SPY (WITH BULK COPY & FINDS FILTER)
-- =======================================================================
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local localPlayer        = Players.LocalPlayer

-- Global State
local isPaused           = false
local ignoreFinds        = true
local maxLogs            = 150
local activeLogs         = {} -- Stores live logs; wiped on Clear

-- Blacklisted spam events (silences "Finds" and background task syncs)
local ignoredEvents = {
	["Announce"]              = true, -- The "Finds" feed shown in chat
	["OnboardingTasksStatus"] = true, -- Continuous quest status polling
	["LostItemsStatus"]       = true, -- Item pool polling
}

-- Safe Clipboard copy for Solara
local function copyText(text)
	if typeof(setclipboard) == "function" then
		setclipboard(tostring(text))
	elseif typeof(toclipboard) == "function" then
		toclipboard(tostring(text))
	end
end

-- Argument Serializer
local function serializeArgs(val, depth)
	depth = depth or 0
	if depth > 3 then return "..." end
	local t = typeof(val)
	if t == "string" then
		return '"' .. val .. '"'
	elseif t == "number" or t == "boolean" then
		return tostring(val)
	elseif t == "Instance" then
		return val:GetFullName()
	elseif t == "table" then
		local parts = {}
		local count = 0
		for k, v in pairs(val) do
			count = count + 1
			if count > 12 then
				table.insert(parts, "...")
				break
			end
			local keyStr = tostring(k)
			table.insert(parts, keyStr .. ": " .. serializeArgs(v, depth + 1))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	else
		return tostring(val)
	end
end

-- =======================================================================
--   BUILD SPY GUI
-- =======================================================================
local parentGui = (typeof(gethui) == "function" and gethui()) or CoreGui:FindFirstChild("RobloxGui") or localPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InteractionRemoteSpy"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 330)
MainFrame.Position = UDim2.new(0.05, 0, 0.45, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 8)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(50, 50, 60)
UIStroke.Thickness = 1

-- Top Bar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "  REMOTE & INTERACTION SPY"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Size = UDim2.new(0, 180, 1, 0)
Title.BackgroundTransparency = 1
Title.Parent = TopBar

-- Header Buttons Container
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(1, -190, 1, 0)
BtnContainer.Position = UDim2.new(0, 185, 0, 0)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = TopBar

local UIListH = Instance.new("UIListLayout", BtnContainer)
UIListH.FillDirection = Enum.FillDirection.Horizontal
UIListH.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListH.VerticalAlignment = Enum.VerticalAlignment.Center
UIListH.Padding = UDim.new(0, 6)

local function makeHeaderButton(text, bgCol, width, onClick)
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 11
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = bgCol
	btn.Size = UDim2.new(0, width or 65, 0, 22)
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.Parent = BtnContainer

	local c = Instance.new("UICorner", btn)
	c.CornerRadius = UDim.new(0, 4)

	btn.MouseButton1Click:Connect(onClick)
	return btn
end

-- Log Container
local Scroll = Instance.new("ScrollingFrame")
Scroll.Name = "LogScroll"
Scroll.Size = UDim2.new(1, -12, 1, -44)
Scroll.Position = UDim2.new(0, 6, 0, 38)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 5
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame

local LogLayout = Instance.new("UIListLayout", Scroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 4)

-- Dragging functionality
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

TopBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- =======================================================================
--   LOG DISPLAY & BULK LOGIC
-- =======================================================================
local logOrder = 0

local function addLog(tag, tagColor, mainText, copyPayload)
	if isPaused then return end

	logOrder = logOrder + 1
	local timeStr = os.date("%H:%M:%S")
	local payload = copyPayload or mainText

	-- Store into active buffer for Bulk Copy
	table.insert(activeLogs, {
		time    = timeStr,
		tag     = tag,
		main    = mainText,
		payload = payload
	})

	local Row = Instance.new("Frame")
	Row.Name = "Row_" .. logOrder
	Row.Size = UDim2.new(1, -6, 0, 26)
	Row.BackgroundColor3 = (logOrder % 2 == 0) and Color3.fromRGB(24, 24, 30) or Color3.fromRGB(18, 18, 22)
	Row.BorderSizePixel = 0
	Row.LayoutOrder = logOrder
	Row.Parent = Scroll

	local rCorner = Instance.new("UICorner", Row)
	rCorner.CornerRadius = UDim.new(0, 4)

	-- Single Copy Button
	local CopyBtn = Instance.new("TextButton")
	CopyBtn.Size = UDim2.new(0, 46, 0, 20)
	CopyBtn.Position = UDim2.new(1, -50, 0, 3)
	CopyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	CopyBtn.Text = "Copy"
	CopyBtn.Font = Enum.Font.SourceSansBold
	CopyBtn.TextSize = 11
	CopyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	CopyBtn.BorderSizePixel = 0
	CopyBtn.Parent = Row

	local cCorner = Instance.new("UICorner", CopyBtn)
	cCorner.CornerRadius = UDim.new(0, 3)

	CopyBtn.MouseButton1Click:Connect(function()
		copyText(payload)
		CopyBtn.Text = "Copied!"
		CopyBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
		task.delay(1, function()
			if CopyBtn and CopyBtn.Parent then
				CopyBtn.Text = "Copy"
				CopyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end)
	end)

	-- Log Text Label
	local TextLbl = Instance.new("TextLabel")
	TextLbl.Size = UDim2.new(1, -56, 1, 0)
	TextLbl.Position = UDim2.new(0, 6, 0, 0)
	TextLbl.BackgroundTransparency = 1
	TextLbl.Font = Enum.Font.Code
	TextLbl.TextSize = 11
	TextLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	TextLbl.TextXAlignment = Enum.TextXAlignment.Left
	TextLbl.TextTruncate = Enum.TextTruncate.AtEnd
	TextLbl.RichText = true

	local hexColor = tagColor:ToHex()
	TextLbl.Text = string.format("<font color='#888888'>[%s]</font> <font color='#%s'><b>[%s]</b></font> %s", timeStr, hexColor, tag, mainText)
	TextLbl.Parent = Row

	-- Auto scroll to bottom
	task.defer(function()
		Scroll.CanvasPosition = Vector2.new(0, 999999)
	end)

	-- Trim old entries (keep visual UI and memory buffer synchronized)
	local children = Scroll:GetChildren()
	if #children > maxLogs then
		for i = 1, (#children - maxLogs) do
			if children[i]:IsA("Frame") then
				children[i]:Destroy()
			end
		end
	end

	while #activeLogs > maxLogs do
		table.remove(activeLogs, 1)
	end
end

-- =======================================================================
--   HEADER ACTION BUTTONS
-- =======================================================================

-- 1. Copy All (Bulk Copy)
local copyAllBtn
copyAllBtn = makeHeaderButton("Copy All", Color3.fromRGB(45, 95, 145), 70, function()
	if #activeLogs == 0 then
		copyAllBtn.Text = "Empty!"
		task.delay(1, function()
			if copyAllBtn then copyAllBtn.Text = "Copy All" end
		end)
		return
	end

	local fullDump = {}
	for _, entry in ipairs(activeLogs) do
		table.insert(fullDump, string.format("[%s] [%s] %s\n%s", entry.time, entry.tag, entry.main, entry.payload))
	end

	local combinedText = table.concat(fullDump, "\n\n" .. string.rep("-", 50) .. "\n\n")
	copyText(combinedText)

	copyAllBtn.Text = "Copied All!"
	copyAllBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
	task.delay(1.2, function()
		if copyAllBtn then
			copyAllBtn.Text = "Copy All"
			copyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
end)

-- 2. Filter Finds Toggle
local findsBtn
findsBtn = makeHeaderButton("Finds: OFF", Color3.fromRGB(150, 40, 40), 72, function()
	ignoreFinds = not ignoreFinds
	findsBtn.Text = ignoreFinds and "Finds: OFF" or "Finds: ON"
	findsBtn.BackgroundColor3 = ignoreFinds and Color3.fromRGB(150, 40, 40) or Color3.fromRGB(40, 140, 40)
end)

-- 3. Pause Button
local pauseBtn
pauseBtn = makeHeaderButton("Pause", Color3.fromRGB(70, 70, 85), 55, function()
	isPaused = not isPaused
	pauseBtn.Text = isPaused and "Resume" or "Pause"
	pauseBtn.BackgroundColor3 = isPaused and Color3.fromRGB(160, 100, 20) or Color3.fromRGB(70, 70, 85)
end)

-- 4. Clear Button (Wipes both Visuals and the Bulk Copy Memory)
makeHeaderButton("Clear", Color3.fromRGB(130, 40, 40), 55, function()
	table.clear(activeLogs) -- Ensures Bulk Copy cannot copy cleared data

	for _, child in ipairs(Scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	logOrder = 0
end)

-- =======================================================================
--   HOOKS: REMOTES, GUI CLICKS & PROXIMITY PROMPTS
-- =======================================================================

-- 1. Hook Incoming RemoteEvents
local hookedRemotes = {}

local function hookRemote(remote)
	if not remote:IsA("RemoteEvent") or hookedRemotes[remote] then return end
	hookedRemotes[remote] = true

	remote.OnClientEvent:Connect(function(...)
		if ignoreFinds and ignoredEvents[remote.Name] then
			return
		end

		local args = {...}
		local formattedArgs = {}
		for _, a in ipairs(args) do
			table.insert(formattedArgs, serializeArgs(a))
		end

		local argString = table.concat(formattedArgs, ", ")
		local display = string.format("Event: '%s' | Args: %s", remote.Name, argString)
		local copyData = string.format("-- RemoteEvent: %s\nlocal args = {\n    %s\n}", remote:GetFullName(), table.concat(formattedArgs, ",\n    "))

		addLog("REMOTE (IN)", Color3.fromRGB(255, 80, 80), display, copyData)
	end)
end

for _, desc in ipairs(game:GetDescendants()) do
	if desc:IsA("RemoteEvent") then
		pcall(hookRemote, desc)
	end
end

game.DescendantAdded:Connect(function(desc)
	if desc:IsA("RemoteEvent") then
		pcall(hookRemote, desc)
	end
end)

-- 2. Hook GUI Button Clicks
local hookedButtons = {}

local function hookButton(btn)
	if not btn:IsA("GuiButton") or hookedButtons[btn] then return end
	hookedButtons[btn] = true

	btn.MouseButton1Click:Connect(function()
		if isPaused then return end
		if btn:IsDescendantOf(ScreenGui) then return end

		local path = btn:GetFullName()
		local display = string.format("Clicked '%s' | Path: %s", btn.Name, path)
		addLog("GUI CLICK", Color3.fromRGB(80, 200, 255), display, path)
	end)
end

for _, desc in ipairs(localPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
	hookButton(desc)
end

localPlayer.PlayerGui.DescendantAdded:Connect(hookButton)

-- 3. Hook ProximityPrompts
local hookedPrompts = {}

local function hookPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or hookedPrompts[prompt] then return end
	hookedPrompts[prompt] = true

	prompt.PromptButtonHoldBegan:Connect(function()
		if isPaused then return end
		local text = prompt.ActionText or prompt.ObjectText or prompt.Name
		local path = prompt:GetFullName()
		local display = string.format("Holding '%s' at: %s", text, path)
		addLog("PROMPT HOLD", Color3.fromRGB(255, 215, 0), display, path)
	end)
end

for _, desc in ipairs(Workspace:GetDescendants()) do
	if desc:IsA("ProximityPrompt") then
		pcall(hookPrompt, desc)
	end
end

Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then
		pcall(hookPrompt, desc)
	end
end)

addLog("SYSTEM", Color3.fromRGB(120, 255, 120), "Remote Spy Initialized. 'Finds' filter is ACTIVE.", "Spy initialized")
