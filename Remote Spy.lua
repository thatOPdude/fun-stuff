-- =======================================================================
--   🎃 REMOTE & INTERACTION SPY (POWERED BY HALLOW-LIB)
-- =======================================================================
local Hallow = loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/HallowLib.lua"))()

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local CoreGui    = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

local parentGui = (typeof(gethui) == "function" and gethui()) 
	or CoreGui:FindFirstChild("RobloxGui") 
	or localPlayer:WaitForChild("PlayerGui")

-- State Configuration
local isPaused          = false
local ignoreFinds       = true
local captureRemotes    = true
local capturePrompts    = true
local captureClicks     = true
local maxLogs           = 100
local activeLogs        = {}

local ignoredEvents = {
	["Announce"]              = true,
	["OnboardingTasksStatus"] = true,
	["LostItemsStatus"]       = true,
}

local function copyText(text)
	if typeof(setclipboard) == "function" then
		setclipboard(tostring(text))
	elseif typeof(toclipboard) == "function" then
		toclipboard(tostring(text))
	end
end

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
			if count > 8 then
				table.insert(parts, "...")
				break
			end
			table.insert(parts, tostring(k) .. ": " .. serializeArgs(v, depth + 1))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	else
		return tostring(val)
	end
end

-- =======================================================================
--   BUILD SPY WINDOW
-- =======================================================================
local Window = Hallow:CreateWindow({
	Title = "REMOTE SPY"
})

local LogsTab = Window:CreateTab("Logs", "👻")
local ControlsTab = Window:CreateTab("Controls", "⚙️")

LogsTab:CreateSection("Live Event Feed (Click Card To Copy)")

-- Helper: Adds log directly into the Logs tab page
local function addLog(tag, titleText, descText, copyPayload)
	if isPaused then return end

	local timeStr = os.date("%H:%M:%S")
	local payload = copyPayload or descText

	table.insert(activeLogs, {
		time    = timeStr,
		tag     = tag,
		main    = titleText,
		payload = payload
	})

	-- Trim buffer
	if #activeLogs > maxLogs then
		table.remove(activeLogs, 1)
	end

	-- Trim older card elements in UI
	local mainGui = parentGui:FindFirstChild("HallowLib_Main")
	local logsPage = mainGui and mainGui:FindFirstChild("Logs_Page", true)
	if logsPage then
		local cards = {}
		for _, child in ipairs(logsPage:GetChildren()) do
			if child:IsA("Frame") and child.BackgroundTransparency < 1 then
				table.insert(cards, child)
			end
		end
		if #cards >= maxLogs then
			for i = 1, (#cards - maxLogs + 1) do
				if cards[i] then cards[i]:Destroy() end
			end
		end
	end

	-- Create clickable card in the Logs Tab
	LogsTab:CreateButton({
		Name = string.format("[%s] [%s] %s", timeStr, tag, titleText),
		Description = descText,
		Callback = function()
			copyText(payload)
			Hallow:Notify({
				Title = "Copied!",
				Content = "Payload copied to clipboard.",
				Duration = 2
			})
		end
	})
end

-- =======================================================================
--   CONTROLS TAB
-- =======================================================================
ControlsTab:CreateSection("Filters & Actions")

ControlsTab:CreateToggle({
	Name = "Filter Spam & Finds",
	Description = "Silences chat announcement feeds and polling events",
	Default = true,
	Callback = function(val)
		ignoreFinds = val
	end
})

ControlsTab:CreateToggle({
	Name = "Pause Event Stream",
	Description = "Temporarily freezes all new incoming logs",
	Default = false,
	Callback = function(val)
		isPaused = val
	end
})

ControlsTab:CreateButton({
	Name = "Copy All Logs (Bulk Dump)",
	Description = "Copies all active captured logs to your clipboard",
	Callback = function()
		if #activeLogs == 0 then
			Hallow:Notify({
				Title = "Empty Buffer",
				Content = "No logs captured yet to copy.",
				Duration = 2.5
			})
			return
		end

		local fullDump = {}
		for _, entry in ipairs(activeLogs) do
			table.insert(fullDump, string.format("[%s] [%s] %s\n%s", entry.time, entry.tag, entry.main, entry.payload))
		end

		local combinedText = table.concat(fullDump, "\n\n" .. string.rep("-", 45) .. "\n\n")
		copyText(combinedText)

		Hallow:Notify({
			Title = "Bulk Copied",
			Content = "All logs dumped to clipboard!",
			Duration = 3
		})
	end
})

ControlsTab:CreateButton({
	Name = "Clear All Logs",
	Description = "Wipes all current logs from memory and the feed",
	Callback = function()
		table.clear(activeLogs)
		local mainGui = parentGui:FindFirstChild("HallowLib_Main")
		local logsPage = mainGui and mainGui:FindFirstChild("Logs_Page", true)
		if logsPage then
			for _, child in ipairs(logsPage:GetChildren()) do
				if child:IsA("Frame") and child.BackgroundTransparency < 1 then
					child:Destroy()
				end
			end
		end
		Hallow:Notify({
			Title = "Cleared",
			Content = "Logs have been wiped.",
			Duration = 2
		})
	end
})

ControlsTab:CreateSection("Event Listeners")

ControlsTab:CreateToggle({
	Name = "Capture RemoteEvents",
	Description = "Listens to incoming client remote executions",
	Default = true,
	Callback = function(val)
		captureRemotes = val
	end
})

ControlsTab:CreateToggle({
	Name = "Capture ProximityPrompts",
	Description = "Listens to interaction hold begins in workspace",
	Default = true,
	Callback = function(val)
		capturePrompts = val
	end
})

ControlsTab:CreateToggle({
	Name = "Capture GUI Clicks",
	Description = "Listens to PlayerGui button interactions",
	Default = true,
	Callback = function(val)
		captureClicks = val
	end
})

ControlsTab:CreateSection("Window Management")

ControlsTab:CreateButton({
	Name = "Destroy UI",
	Description = "Completely unloads and closes the spy tool",
	Callback = function()
		Window:Destroy()
	end
})

-- =======================================================================
--   HOOKS: REMOTES, PROMPTS & GUI CLICKS
-- =======================================================================

-- 1. RemoteEvents Hook
local hookedRemotes = {}
local function hookRemote(remote)
	if not remote:IsA("RemoteEvent") or hookedRemotes[remote] then return end
	hookedRemotes[remote] = true

	remote.OnClientEvent:Connect(function(...)
		if not captureRemotes or isPaused then return end
		if ignoreFinds and ignoredEvents[remote.Name] then return end

		local args = {...}
		local formattedArgs = {}
		for _, a in ipairs(args) do
			table.insert(formattedArgs, serializeArgs(a))
		end

		local argString = table.concat(formattedArgs, ", ")
		local copyData = string.format("-- RemoteEvent: %s\nlocal args = {\n    %s\n}", remote:GetFullName(), table.concat(formattedArgs, ",\n    "))

		addLog("REMOTE", remote.Name, "Args: " .. argString, copyData)
	end)
end

for _, desc in ipairs(game:GetDescendants()) do
	if desc:IsA("RemoteEvent") then pcall(hookRemote, desc) end
end
game.DescendantAdded:Connect(function(desc)
	if desc:IsA("RemoteEvent") then pcall(hookRemote, desc) end
end)

-- 2. ProximityPrompt Hook
local hookedPrompts = {}
local function hookPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or hookedPrompts[prompt] then return end
	hookedPrompts[prompt] = true

	prompt.PromptButtonHoldBegan:Connect(function()
		if not capturePrompts or isPaused then return end
		local text = prompt.ActionText or prompt.ObjectText or prompt.Name
		local path = prompt:GetFullName()
		addLog("PROMPT", text, "Path: " .. path, path)
	end)
end

for _, desc in ipairs(Workspace:GetDescendants()) do
	if desc:IsA("ProximityPrompt") then pcall(hookPrompt, desc) end
end
Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then pcall(hookPrompt, desc) end
end)

-- 3. GUI Clicks Hook
local hookedButtons = {}
local function hookButton(btn)
	if not btn:IsA("GuiButton") or hookedButtons[btn] then return end
	hookedButtons[btn] = true

	btn.MouseButton1Click:Connect(function()
		if not captureClicks or isPaused then return end
		local mainGui = parentGui:FindFirstChild("HallowLib_Main")
		if mainGui and btn:IsDescendantOf(mainGui) then return end

		local path = btn:GetFullName()
		addLog("CLICK", btn.Name, "Path: " .. path, path)
	end)
end

for _, desc in ipairs(localPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
	hookButton(desc)
end
localPlayer.PlayerGui.DescendantAdded:Connect(hookButton)

addLog("SYSTEM", "Initialized", "Remote Spy is ready. Click any entry to copy.", "Spy Initialized")
