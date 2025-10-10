-- // ===== Hacker Style Dev Utility: Acorn Auto-Tween + AFK + Sliders =====
-- // Hotkeys: [R]=Run  [F]=AFK  [M]=Minimize    Buttons: [–]=Minimize

-- ========== Services ==========
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- ========== Safe Defaults ==========
local DEFAULT_WS, DEFAULT_JP, USE_JP = 16, 50, true
pcall(function()
	if typeof(humanoid.WalkSpeed) == "number" then DEFAULT_WS = humanoid.WalkSpeed end
	if humanoid.UseJumpPower ~= nil then USE_JP = humanoid.UseJumpPower end
	if typeof(humanoid.JumpPower) == "number" then DEFAULT_JP = humanoid.JumpPower end
end)

-- ========== State / Settings ==========
local STATE = {
	running      = false,
	afkOn        = false,
	minimized    = false,
	guiPos       = Vector2.new(20, 20),
	opacity      = 1.0,       -- 0.3–1.0
	tweenSpeed   = 140,       -- studs/sec
	walkSpeed    = DEFAULT_WS,
	jumpPower    = DEFAULT_JP,
	useJumpPower = USE_JP,
}
pcall(function()
	local attrs = player:GetAttributes()
	if attrs._DevTool_Settings then
		for k,v in pairs(HttpService:JSONDecode(attrs._DevTool_Settings)) do STATE[k] = v end
	end
end)
local function saveSettings()
	pcall(function()
		player:SetAttribute("_DevTool_Settings", HttpService:JSONEncode({
			minimized   = STATE.minimized,
			guiPos      = {x = STATE.guiPos.X, y = STATE.guiPos.Y},
			opacity     = STATE.opacity,
			tweenSpeed  = STATE.tweenSpeed,
			walkSpeed   = STATE.walkSpeed,
			jumpPower   = STATE.jumpPower,
		}))
	end)
end

-- ====== NEW: home + busy ======
local homeCFrame : CFrame? = nil
local busy = false

-- ========== Gui Helpers ==========
local function mk(tag, props, parent)
	local inst = Instance.new(tag)
	for k,v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local gui = mk("ScreenGui", {
	Name = "DevAcornUtility",
	ResetOnSpawn = false,
	IgnoreGuiInset = true
}, player:WaitForChild("PlayerGui"))

local frame = mk("Frame", {
	Size = UDim2.fromOffset(360, 340),
	Position = UDim2.fromOffset(STATE.guiPos.X, STATE.guiPos.Y),
	BackgroundColor3 = Color3.fromRGB(10,10,10),
	BorderColor3 = Color3.fromRGB(0,255,0),
	BorderSizePixel = 2,
	Active = true,
	Draggable = false, -- ✅ drag handled by title bar only
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0,12)}, frame)
local stroke = mk("UIStroke", {
	Thickness = 1.6, Color = Color3.fromRGB(0,255,0),
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.2
}, frame)

-- Title bar (drag zone)
local titleBar = mk("Frame", {
	Size = UDim2.new(1, -12, 0, 28),
	Position = UDim2.new(0, 6, 0, 6),
	BackgroundTransparency = 1,
	Active = true
}, frame)
local title = mk("TextLabel", {
	Size = UDim2.new(1, -112, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Code,
	Text = "ACORN DEV TOOLKIT",
	TextColor3 = Color3.fromRGB(0,255,0),
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left
}, titleBar)

-- Drag logic (only titleBar drags)
do
	local dragging = false
	local dragOffset
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local mouse = UserInputService:GetMouseLocation()
			dragOffset = Vector2.new(mouse.X - frame.AbsolutePosition.X, mouse.Y - frame.AbsolutePosition.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
			local mouse = UserInputService:GetMouseLocation()
			local pos = Vector2.new(mouse.X, mouse.Y) - dragOffset
			pos = Vector2.new(math.clamp(pos.X, 0, vp.X - frame.AbsoluteSize.X),
			                  math.clamp(pos.Y, 0, vp.Y - frame.AbsoluteSize.Y))
			frame.Position = UDim2.fromOffset(pos.X, pos.Y)
			STATE.guiPos = pos
		end
	end)
end

-- Title buttons
local btnDestroy = mk("TextButton", {
	Size = UDim2.fromOffset(28, 22),
	Position = UDim2.new(1, -30, 0, 3),
	BackgroundColor3 = Color3.fromRGB(50,20,20),
	BorderSizePixel = 0,
	Text = "X",
	Font = Enum.Font.Code, TextSize = 16,
	TextColor3 = Color3.fromRGB(255,80,80),
	ZIndex = 2
}, titleBar)
mk("UICorner", {CornerRadius = UDim.new(0,6)}, btnDestroy)

local btnMin = mk("TextButton", {
	Size = UDim2.fromOffset(28, 22),
	Position = UDim2.new(1, -62, 0, 3),
	BackgroundColor3 = Color3.fromRGB(30,30,30),
	BorderSizePixel = 0,
	Text = "-",
	Font = Enum.Font.Code, TextSize = 18,
	TextColor3 = Color3.fromRGB(0,255,0)
}, titleBar)
mk("UICorner", {CornerRadius = UDim.new(0,6)}, btnMin)

-- Labels
local status = mk("TextLabel", {
	Size = UDim2.new(1,-12,0,18),
	Position = UDim2.new(0,6,0,34),
	BackgroundTransparency = 1,
	Font = Enum.Font.Code, Text = "STATUS: OFFLINE",
	TextColor3 = Color3.fromRGB(0,200,0), TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left
}, frame)
local afkStatus = mk("TextLabel", {
	Size = UDim2.new(1,-12,0,18),
	Position = UDim2.new(0,6,0,52),
	BackgroundTransparency = 1,
	Font = Enum.Font.Code, Text = "AFK: OFF",
	TextColor3 = Color3.fromRGB(120,255,120), TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left
}, frame)

-- Buttons row
local btnRun = mk("TextButton", {
	Size = UDim2.fromOffset(100, 32),
	Position = UDim2.new(0, 8, 0, 76),
	BackgroundColor3 = Color3.fromRGB(50,50,50),
	TextColor3 = Color3.fromRGB(0,0,0),
	Font = Enum.Font.Code, TextSize = 14,
	Text = "RUN: OFF", BorderSizePixel = 0
}, frame)
mk("UICorner", {CornerRadius = UDim.new(0,8)}, btnRun)

local btnAFK = mk("TextButton", {
	Size = UDim2.fromOffset(100, 32),
	Position = UDim2.new(0, 116, 0, 76),
	BackgroundColor3 = Color3.fromRGB(50,50,50),
	TextColor3 = Color3.fromRGB(0,0,0),
	Font = Enum.Font.Code, TextSize = 14,
	Text = "AFK: OFF", BorderSizePixel = 0
}, frame)
mk("UICorner", {CornerRadius = UDim.new(0,8)}, btnAFK)

local fpsLabel = mk("TextLabel", {
	Size = UDim2.fromOffset(110, 18),
	Position = UDim2.new(1, -118, 0, 80),
	BackgroundTransparency = 1,
	Font = Enum.Font.Code, Text = "FPS: --",
	TextColor3 = Color3.fromRGB(0,255,0), TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Right
}, frame)

-- Notifications / Visuals
local function notify(msg)
	pcall(function()
		StarterGui:SetCore("SendNotification", {Title="Dev Toolkit", Text=msg, Duration=2})
	end)
end
local function setBtnVisual(button, isOn, label)
	if isOn then
		button.BackgroundColor3 = Color3.fromRGB(0,255,0)
		button.Text = label .. ": ON"
	else
		button.BackgroundColor3 = Color3.fromRGB(50,50,50)
		button.Text = label .. ": OFF"
	end
end
local function refreshStatus()
	status.Text = STATE.running and "STATUS: ACTIVE" or "STATUS: OFFLINE"
	afkStatus.Text = "AFK: " .. (STATE.afkOn and "ON" or "OFF")
	frame.BackgroundTransparency = 1 - STATE.opacity
	stroke.Transparency = (STATE.running or STATE.afkOn) and 0.08 or 0.2
end

-- ========== Slider Factory (works + RESET right; no frame dragging) ==========
local function createSlider(labelText, minV, maxV, defaultV, posY, onChange, precision)
	local RIGHT_PAD, GAP, RESET_W, VALUE_W = 8, 6, 52, 60

	local container = mk("Frame", {
		Size = UDim2.new(1, -16, 0, 48),
		Position = UDim2.new(0, 8, 0, posY),
		BackgroundTransparency = 1,
		Active = true
	}, frame)

	local lbl = mk("TextLabel", {
		Size = UDim2.new(1, -56, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		Text = labelText .. ":",
		TextColor3 = Color3.fromRGB(0,255,0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	}, container)

	local valueText = mk("TextLabel", {
		Size = UDim2.fromOffset(VALUE_W, 16),
		Position = UDim2.new(1, -(RIGHT_PAD + RESET_W + GAP + VALUE_W), 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		Text = tostring(defaultV),
		TextColor3 = Color3.fromRGB(0,255,0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right
	}, container)

	local resetBtn = mk("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(RESET_W, 16),
		Position = UDim2.new(1, -RIGHT_PAD, 0, 0),
		BackgroundColor3 = Color3.fromRGB(30,30,30),
		BorderSizePixel = 0,
		Text = "RESET", Font = Enum.Font.Code, TextSize = 12,
		TextColor3 = Color3.fromRGB(0,255,0)
	}, container)
	mk("UICorner", {CornerRadius = UDim.new(0,4)}, resetBtn)

	local bar = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = Color3.fromRGB(30,30,30),
		BorderSizePixel = 0,
		Active = true
	}, container)
	mk("UICorner", {CornerRadius = UDim.new(0,7)}, bar)

	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0,255,0),
		BorderSizePixel = 0
	}, bar)
	mk("UICorner", {CornerRadius = UDim.new(0,7)}, fill)

	local knob = mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16,16),
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		BorderColor3 = Color3.fromRGB(0,255,0),
		BorderSizePixel = 2,
		Active = true
	}, bar)
	mk("UICorner", {CornerRadius = UDim.new(1,0)}, knob)

	-- Helpers
	local dragging = false
	local function clampVal(v)
		v = math.clamp(v, minV, maxV)
		if precision then local m=10^precision; v = math.floor(v*m+0.5)/m else v = math.floor(v+0.5) end
		return v
	end
	local function setVisualByValue(v)
		v = clampVal(v)
		local a = (v - minV) / (maxV - minV)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valueText.Text = tostring(v)
	end
	local function setFromMouseX(x)
		if bar.AbsoluteSize.X <= 0 then return end
		local absX = math.clamp(x - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
		local v = minV + (absX / bar.AbsoluteSize.X) * (maxV - minV)
		v = clampVal(v); setVisualByValue(v)
		if onChange then onChange(v) end
	end

	-- Events (prevent frame dragging conflicts)
	local function beginDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end
	bar.InputBegan:Connect(beginDrag)
	knob.InputBegan:Connect(beginDrag)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromMouseX(UserInputService:GetMouseLocation().X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	resetBtn.MouseButton1Click:Connect(function()
		setVisualByValue(defaultV)
		if onChange then onChange(defaultV) end
	end)

	-- Initialize after layout exists
	task.defer(function() setVisualByValue(defaultV) end)
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() setVisualByValue(defaultV) end)

	return {
		setValue = function(v) setVisualByValue(v); if onChange then onChange(clampVal(v)) end end
	}
end

-- ========== Sliders ==========
local y = 116
local tweenSlider = createSlider("TWEEN SPEED (stud/s)", 60, 260, STATE.tweenSpeed, y, function(v)
	STATE.tweenSpeed = v; saveSettings()
end);              y = y + 48

local wsSlider = createSlider("WALK SPEED", 8, 64, STATE.walkSpeed, y, function(v)
	STATE.walkSpeed = v
	if humanoid and humanoid.Parent then humanoid.WalkSpeed = v end
	saveSettings()
end);              y = y + 48

local jpSlider = createSlider("JUMP POWER", 20, 120, STATE.jumpPower, y, function(v)
	STATE.jumpPower = v
	if humanoid and humanoid.Parent and STATE.useJumpPower then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = v
	end
	saveSettings()
end);              y = y + 48

local opacitySlider = createSlider("OPACITY", 0.3, 1.0, STATE.opacity, y, function(v)
	STATE.opacity = v; refreshStatus(); saveSettings()
end, 2);           y = y + 48

-- Auto-fit frame height
frame.Size = UDim2.fromOffset(360, y + 30)
local CONTENT_HEIGHT = y + 30

-- ========== FPS Counter ==========
do
	local last = time(); local frames = 0
	RunService.RenderStepped:Connect(function()
		frames += 1; local now = time()
		if now - last >= 0.5 then
			local fps = math.floor(frames / (now - last) + 0.5)
			fpsLabel.Text = ("FPS: %d"):format(fps)
			last = now; frames = 0
		end
	end)
end

-- ========== Acorn Tween ==========
local acornFolderName = "Acorn"
local acornName       = "Acorn"
local function getAcorn()
	local folder = workspace:FindFirstChild(acornFolderName)
	return folder and folder:FindFirstChild(acornName) or nil
end
local function getAcornPosition(acorn)
	if not acorn then return nil end
	if acorn:IsA("Model") then
		if acorn.PrimaryPart then return acorn.PrimaryPart.Position end
		local pp = acorn:FindFirstChildWhichIsA("BasePart", true)
		return pp and pp.Position or nil
	elseif acorn:IsA("BasePart") then
		return acorn.Position
	end
	return nil
end

local function tweenToPos(targetPos : Vector3)
	if not hrp or not hrp.Parent then return false end
	local distance = (targetPos - hrp.Position).Magnitude
	local speed    = math.max(10, STATE.tweenSpeed)
	local duration = math.clamp(distance / speed, 0.05, 10)
	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))}
	)
	tween:Play()
	local ok = pcall(function() tween.Completed:Wait() end)
	return ok
end

-- ===== NEW: tween back to saved CFrame (keeps orientation) =====
local function tweenToCFrame(targetCF : CFrame)
	if not hrp or not hrp.Parent or not targetCF then return false end
	local distance = (targetCF.Position - hrp.Position).Magnitude
	local speed    = math.max(10, STATE.tweenSpeed)
	local duration = math.clamp(distance / speed, 0.05, 10)
	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = targetCF}
	)
	tween:Play()
	local ok = pcall(function() tween.Completed:Wait() end)
	return ok
end

-- main loop + spawn listener
task.spawn(function()
	local spawnConn
	local function hookSpawn(folder)
		if spawnConn then spawnConn:Disconnect() end
		if folder then
			spawnConn = folder.ChildAdded:Connect(function(child)
				if child.Name == acornName and STATE.running and not busy then
					task.wait(0.1)
					local pos = getAcornPosition(child)
					if pos then
						busy = true
						status.Text = "STATUS: LOCKED ON (SPAWN)"
						local ok1 = tweenToPos(pos)
						if ok1 and homeCFrame then
							task.wait(0.05)
							tweenToCFrame(homeCFrame)
						end
						busy = false
					end
				end
			end)
		end
	end
	task.spawn(function()
		while gui.Parent do
			hookSpawn(workspace:FindFirstChild(acornFolderName))
			task.wait(2)
		end
	end)

	while gui.Parent do
		if STATE.running and not busy then
			local acorn = getAcorn()
			if acorn then
				local pos = getAcornPosition(acorn)
				if pos then
					busy = true
					status.Text = "STATUS: LOCKED ON"
					local ok1 = tweenToPos(pos)
					if ok1 and homeCFrame then
						task.wait(0.05)
						tweenToCFrame(homeCFrame)
					end
					busy = false
				else
					status.Text = "STATUS: SCANNING..."
				end
			else
				status.Text = "STATUS: SEARCHING..."
			end
		end
		task.wait(0.8)
	end
end)

-- ========== Anti-AFK ==========
local afkConn : RBXScriptConnection? = nil
local wiggleStop = false
local function startAFK()
	if afkConn then afkConn:Disconnect() end
	afkConn = player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	wiggleStop = false
	task.spawn(function()
		while STATE.afkOn and not wiggleStop and gui.Parent do
			task.wait(math.random(55, 75))
			pcall(function()
				if not hrp or not hrp.Parent then return end
				local orig = hrp.CFrame
				local offset = Vector3.new((math.random()-0.5)*0.6, 0, (math.random()-0.5)*0.6)
				local t1 = TweenService:Create(hrp, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = orig + offset})
				t1:Play(); t1.Completed:Wait()
				local t2 = TweenService:Create(hrp, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {CFrame = orig})
				t2:Play(); t2.Completed:Wait()
			end)
		end
	end)
end
local function stopAFK()
	if afkConn then afkConn:Disconnect(); afkConn = nil end
	wiggleStop = true
end

-- ========== UI Anim + Edge Snap ==========
task.spawn(function()
	while gui.Parent do
		if STATE.running or STATE.afkOn then
			stroke.Transparency = 0.05; task.wait(0.3)
			stroke.Transparency = 0.4;  task.wait(0.3)
		else
			stroke.Transparency = 0.2;  task.wait(0.5)
		end
	end
end)

frame:GetPropertyChangedSignal("Position"):Connect(function()
	STATE.guiPos = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
end)

-- ========== Buttons / Hotkeys ==========
local function toggleRun()
	STATE.running = not STATE.running
	-- NEW: capture home when turning on
	if STATE.running and hrp and hrp.Parent then
		homeCFrame = hrp.CFrame
	end
	setBtnVisual(btnRun, STATE.running, "RUN")
	refreshStatus()
	notify(STATE.running and "Auto-Tween: ON" or "Auto-Tween: OFF")
end

local function toggleAFK()
	STATE.afkOn = not STATE.afkOn
	setBtnVisual(btnAFK, STATE.afkOn, "AFK")
	if STATE.afkOn then startAFK() else stopAFK() end
	refreshStatus()
	notify(STATE.afkOn and "AFK: ON" or "AFK: OFF")
end

btnRun.MouseButton1Click:Connect(toggleRun)
btnAFK.MouseButton1Click:Connect(toggleAFK)

btnMin.MouseButton1Click:Connect(function()
	STATE.minimized = not STATE.minimized
	if STATE.minimized then
		for _,child in ipairs(frame:GetChildren()) do
			if child ~= titleBar and child ~= stroke then child.Visible = false end
		end
		titleBar.Visible = true
		frame.Size = UDim2.fromOffset(230, 40)
	else
		for _,child in ipairs(frame:GetChildren()) do child.Visible = true end
		frame.Size = UDim2.fromOffset(360, math.max(200, CONTENT_HEIGHT))
	end
	saveSettings()
end)

btnDestroy.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.UserInputType == Enum.UserInputType.Keyboard then
		if inp.KeyCode == Enum.KeyCode.R then toggleRun() end
		if inp.KeyCode == Enum.KeyCode.F then toggleAFK() end
		if inp.KeyCode == Enum.KeyCode.M then btnMin:Activate() end
	end
end)

-- ========== Respawn Safety ==========
player.CharacterAdded:Connect(function(c)
	character = c
	humanoid  = c:WaitForChild("Humanoid")
	hrp       = c:WaitForChild("HumanoidRootPart")
	humanoid.WalkSpeed = STATE.walkSpeed
	if STATE.useJumpPower then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = STATE.jumpPower
	end
	-- NEW: refresh home if we're running (spawn at new body)
	if STATE.running and hrp and hrp.Parent then
		homeCFrame = hrp.CFrame
	end
	if STATE.afkOn then stopAFK(); startAFK() end
end)

-- ========== Init ==========
setBtnVisual(btnRun, STATE.running, "RUN")
setBtnVisual(btnAFK, STATE.afkOn, "AFK")
tweenSlider.setValue(STATE.tweenSpeed)
wsSlider.setValue(STATE.walkSpeed)
jpSlider.setValue(STATE.jumpPower)
opacitySlider.setValue(STATE.opacity)
refreshStatus()
if STATE.minimized then btnMin:Activate() end
StarterGui:SetCore("SendNotification", {Title="Dev Toolkit", Text="Loaded (R=Run, F=AFK, M=Min)", Duration=2})
