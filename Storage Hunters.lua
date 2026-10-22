-- =======================================================================
--   LOAD RAYFIELD GEN2
-- =======================================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- =======================================================================
--   SERVICES
-- =======================================================================
local TweenService         = game:GetService("TweenService")
local Players              = game:GetService("Players")
local Workspace            = game:GetService("Workspace")
local RunService           = game:GetService("RunService")
local Lighting             = game:GetService("Lighting")
local UserInputService     = game:GetService("UserInputService")
local VirtualUser          = game:GetService("VirtualUser")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera      = Workspace.CurrentCamera

-- =======================================================================
--   STATE CONFIGURATION
-- =======================================================================
-- Combat / Target State
local tweenSpeed        = 100
local OFFSET            = Vector3.new(0, 3, 4)
local activeTween       = nil
local tracerEnabled     = false
local espEnabled        = false
local antiAfkEnabled    = false
local antiAfkConn       = nil
local playerAttachment  = nil
local tracerBeam        = nil

-- Player & Movement State
local currentWalkSpeed    = 16
local currentJumpPower    = 50
local currentGravity      = Workspace.Gravity
local infJumpEnabled      = false
local fullbrightEnabled   = false

-- Noclip State
local noclipEnabled       = false
local noclipConn          = nil

-- Fly State
local flyEnabled          = false
local flySpeed            = 60
local flyConn             = nil
local flyKeys             = { W = false, A = false, S = false, D = false, Up = false, Down = false }

-- Walk on Water State
local walkOnWaterEnabled  = false
local waterWalkConn       = nil
local waterRayParams      = RaycastParams.new()
waterRayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Fun / FX State
local ragdollEnabled      = false
local fxEnabled           = false
local fxConnections       = {}
local fxEmitters          = {}
local trackedFxChars      = {}

-- Whitelist for Jump & Fall FX targets
local fxWhitelist = {
	["potatosquatshorts"] = true,
	["bv013346"]           = true
}

-- Matrix Rain State
local matrixEnabled       = false
local matrixGui           = nil
local matrixConns         = {}

-- Halloween / Trick or Treat State
local autoTotEnabled      = false
local totLoopRunning      = false
local totDelay            = 1.5

-- Halloween / Auto Dig Grave State
local autoDigEnabled      = false
local digLoopRunning      = false
local digDelay            = 1.5

-- Garages Auto-Start State
local autoStartGarages = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false
}

-- =======================================================================
--   HELPER & RECOVERY FUNCTIONS
-- =======================================================================
local function getHumanoid(char)
	char = char or localPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP(char)
	char = char or localPlayer.Character
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function applyCharacterSettings(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.UseJumpPower = true
		hum.WalkSpeed    = currentWalkSpeed
		hum.JumpPower    = currentJumpPower
	end
end

local function interactWithPrompt(prompt)
	if not prompt or not prompt.Parent then return end

	if typeof(fireproximityprompt) == "function" then
		pcall(function()
			fireproximityprompt(prompt, 1, true)
		end)
		pcall(function()
			fireproximityprompt(prompt)
		end)
	else
		pcall(function()
			prompt:InputHoldBegin()
			task.wait((prompt.HoldDuration or 0.5) + 0.1)
			prompt:InputHoldEnd()
		end)
	end
end

-- =======================================================================
--   INSTANT PROMPT / INSTA-REPAIR LOGIC (HOOKS HOLD-BEGAN & OVERWRITES)
-- =======================================================================
local ProximityPromptService = game:GetService("ProximityPromptService")

local instaRepairEnabled     = false
local originalHoldDurations  = {}
local promptConns            = {}

local function setInstantPrompts(state)
	instaRepairEnabled = state

	for _, c in ipairs(promptConns) do
		c:Disconnect()
	end
	table.clear(promptConns)

	if state then
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				if originalHoldDurations[desc] == nil then
					originalHoldDurations[desc] = desc.HoldDuration
				end
				desc.HoldDuration = 0
			end
		end

		local shownConn = ProximityPromptService.PromptShown:Connect(function(prompt)
			if not instaRepairEnabled or not prompt then return end
			if originalHoldDurations[prompt] == nil then
				originalHoldDurations[prompt] = prompt.HoldDuration
			end
			prompt.HoldDuration = 0
		end)
		table.insert(promptConns, shownConn)

		local holdBeganConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			if not instaRepairEnabled or not prompt then return end

			if typeof(fireproximityprompt) == "function" then
				pcall(function() fireproximityprompt(prompt, 1, true) end)
				pcall(function() fireproximityprompt(prompt, 0, true) end)
				pcall(function() fireproximityprompt(prompt) end)
			else
				pcall(function()
					prompt:InputHoldBegin()
					task.wait(0.02)
					prompt:InputHoldEnd()
				end)
			end
		end)
		table.insert(promptConns, holdBeganConn)

		local descConn = Workspace.DescendantAdded:Connect(function(desc)
			if desc:IsA("ProximityPrompt") then
				if originalHoldDurations[desc] == nil then
					originalHoldDurations[desc] = desc.HoldDuration
				end
				desc.HoldDuration = 0
			end
		end)
		table.insert(promptConns, descConn)

		print("[InstaRepair] Enabled! All prompts will now complete instantly on tap.")
	else
		for prompt, origDuration in pairs(originalHoldDurations) do
			if prompt and prompt.Parent then
				pcall(function()
					prompt.HoldDuration = origDuration
				end)
			end
		end
		table.clear(originalHoldDurations)
		print("[InstaRepair] Disabled. Restored default hold durations.")
	end
end

-- =======================================================================
--   GARAGE AUTO-START LOGIC
-- =======================================================================
local function getGarageEnterPrompt(garageNum)
	local debris = Workspace:FindFirstChild("_Debris")
	local garages = debris and debris:FindFirstChild("Garages")
	if not garages then
		garages = Workspace:FindFirstChild("Garages", true)
	end
	if not garages then return nil, nil end

	local garage = garages:FindFirstChild("Halloween Garage " .. tostring(garageNum))
	if not garage then return nil, nil end

	local entry = garage:FindFirstChild("EntrySquare")
	local pPart = entry and entry:FindFirstChild("PromptPart")
	local prompt = pPart and (pPart:FindFirstChild("EnterAuction") or pPart:FindFirstChildOfClass("ProximityPrompt"))

	return prompt, pPart
end

task.spawn(function()
	while true do
		for garageNum = 1, 4 do
			if autoStartGarages[garageNum] then
				local prompt, pPart = getGarageEnterPrompt(garageNum)

				if prompt and prompt.Enabled and pPart then
					local hrp = getHRP()
					if hrp and (hrp.Position - pPart.Position).Magnitude > (prompt.MaxActivationDistance or 10) then
						hrp.CFrame = pPart.CFrame + Vector3.new(0, 3, 0)
						task.wait(0.2)
					end

					interactWithPrompt(prompt)
					task.wait(0.5)
				end
			end
		end
		task.wait(1)
	end
end)

-- =======================================================================
--   MOVEMENT / PHYSICS LOGIC
-- =======================================================================
local function setNoclip(state)
	noclipEnabled = state
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end

	if state then
		noclipConn = RunService.Stepped:Connect(function()
			local char = localPlayer.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	end
end

local function getFlyDirection()
	local cf = camera.CFrame
	local dir = Vector3.zero
	if flyKeys.W    then dir += cf.LookVector end
	if flyKeys.S    then dir -= cf.LookVector end
	if flyKeys.A    then dir -= cf.RightVector end
	if flyKeys.D    then dir += cf.RightVector end
	if flyKeys.Up   then dir += Vector3.new(0, 1, 0) end
	if flyKeys.Down then dir -= Vector3.new(0, 1, 0) end

	if dir.Magnitude > 0 then
		dir = dir.Unit
	end
	return dir
end

local function setFly(state)
	flyEnabled = state
	if flyConn then flyConn:Disconnect(); flyConn = nil end

	local hum = getHumanoid()
	local hrp = getHRP()

	if state then
		if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end

		flyConn = RunService.RenderStepped:Connect(function(dt)
			local root = getHRP()
			if not root then return end

			local moveDir = getFlyDirection() * flySpeed
			if moveDir.Magnitude > 0 then
				root.CFrame = root.CFrame + (moveDir * dt)
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	else
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W           then flyKeys.W = true end
	if k == Enum.KeyCode.A           then flyKeys.A = true end
	if k == Enum.KeyCode.S           then flyKeys.S = true end
	if k == Enum.KeyCode.D           then flyKeys.D = true end
	if k == Enum.KeyCode.Space       then flyKeys.Up = true end
	if k == Enum.KeyCode.LeftControl then flyKeys.Down = true end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W           then flyKeys.W = false end
	if k == Enum.KeyCode.A           then flyKeys.A = false end
	if k == Enum.KeyCode.S           then flyKeys.S = false end
	if k == Enum.KeyCode.D           then flyKeys.D = false end
	if k == Enum.KeyCode.Space       then flyKeys.Up = false end
	if k == Enum.KeyCode.LeftControl then flyKeys.Down = false end
end)

local function setWalkOnWater(state)
	walkOnWaterEnabled = state
	if waterWalkConn then waterWalkConn:Disconnect(); waterWalkConn = nil end

	local hum = getHumanoid()
	if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, not state) end

	if state then
		waterWalkConn = RunService.Heartbeat:Connect(function()
			local char = localPlayer.Character
			local hrp = getHRP(char)
			if not hrp then return end

			waterRayParams.FilterDescendantsInstances = { char }
			local ray = Workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), waterRayParams)
			if ray and ray.Material == Enum.Material.Water then
				local targetY = ray.Position.Y + 2.8
				if hrp.Position.Y < targetY then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
					hrp.CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)
				end
			end
		end)
	end
end

-- =======================================================================
--   FUN & VISUALS LOGIC
-- =======================================================================
local function setRagdoll(state)
	ragdollEnabled = state
	local hum = getHumanoid()
	if not hum then return end

	if state then
		hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
		hum.PlatformStand = true
	else
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function explodeMe()
	local hrp = getHRP()
	local hum = getHumanoid()
	if not hrp then return end

	local exp = Instance.new("Explosion")
	exp.Position = hrp.Position
	exp.BlastPressure = 0
	exp.BlastRadius = 6
	exp.Parent = Workspace

	task.delay(0.05, function()
		if hum then hum.Health = 0 end
	end)
end

local function isFxTarget(plr)
	if not plr then return false end
	if plr == localPlayer then return true end
	return fxWhitelist[string.lower(plr.Name)] == true
end

local function cleanFX()
	for _, conn in ipairs(fxConnections) do
		conn:Disconnect()
	end
	table.clear(fxConnections)

	for _, pe in ipairs(fxEmitters) do
		if pe and pe.Parent then
			pe:Destroy()
		end
	end
	table.clear(fxEmitters)
	table.clear(trackedFxChars)
end

local function setupCharacterFX(char)
	if not char then return end
	local hum = char:WaitForChild("Humanoid", 5)
	local hrp = char:WaitForChild("HumanoidRootPart", 5) or char:WaitForChild("Torso", 5)
	if not hum or not hrp then return end

	local jumpPE = Instance.new("ParticleEmitter")
	jumpPE.Rate = 0
	jumpPE.Speed = NumberRange.new(6, 12)
	jumpPE.SpreadAngle = Vector2.new(360, 360)
	jumpPE.Lifetime = NumberRange.new(0.4, 0.7)
	jumpPE.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0)
	})
	jumpPE.Parent = hrp
	table.insert(fxEmitters, jumpPE)

	local landPE = jumpPE:Clone()
	landPE.Parent = hrp
	table.insert(fxEmitters, landPE)

	local fallPE = Instance.new("ParticleEmitter")
	fallPE.Rate = 0
	fallPE.Speed = NumberRange.new(8, 14)
	fallPE.SpreadAngle = Vector2.new(180, 180)
	fallPE.Acceleration = Vector3.new(0, 15, 0)
	fallPE.Lifetime = NumberRange.new(0.3, 0.6)
	fallPE.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0)
	})
	fallPE.Parent = hrp
	table.insert(fxEmitters, fallPE)

	trackedFxChars[char] = {
		hum          = hum,
		hrp          = hrp,
		jumpPE       = jumpPE,
		landPE       = landPE,
		fallPE       = fallPE,
		wasGrounded  = true,
		isJumping    = false,
		isFalling    = false,
		prevVelY     = 0,
		lastJumpTick = 0,
		lastFallTick = 0,
		lastLandTick = 0
	}
end

local function hookPlayerFX(targetPlr)
	if not isFxTarget(targetPlr) then return end

	if targetPlr.Character then
		task.spawn(setupCharacterFX, targetPlr.Character)
	end

	local charAddedConn = targetPlr.CharacterAdded:Connect(function(char)
		if fxEnabled then
			task.spawn(setupCharacterFX, char)
		end
	end)
	table.insert(fxConnections, charAddedConn)
end

local function setLowGravFX(state)
	fxEnabled = state
	cleanFX()

	if state then
		for _, plr in ipairs(Players:GetPlayers()) do
			hookPlayerFX(plr)
		end

		local playerJoinedConn = Players.PlayerAdded:Connect(function(newPlr)
			if fxEnabled then
				hookPlayerFX(newPlr)
			end
		end)
		table.insert(fxConnections, playerJoinedConn)

		local monitorConn = RunService.Heartbeat:Connect(function()
			local now = tick()
			for char, data in pairs(trackedFxChars) do
				local hrp = data.hrp
				local hum = data.hum

				if not hrp or not hum or not hrp.Parent or not hum.Parent or hum.Health <= 0 then
					trackedFxChars[char] = nil
				else
					local velY = hrp.AssemblyLinearVelocity.Y
					local isGrounded = (hum.FloorMaterial ~= Enum.Material.Air)

					if isGrounded then
						if not data.wasGrounded then
							if (now - data.lastLandTick) > 0.2 then
								data.lastLandTick = now
								if data.landPE and data.landPE.Parent then
									data.landPE:Emit(35)
								end
							end
						end
						data.isJumping = false
						data.isFalling = false
					else
						if data.wasGrounded then
							if velY > 6 then
								if (now - data.lastJumpTick) > 0.2 then
									data.lastJumpTick = now
									if data.jumpPE and data.jumpPE.Parent then
										data.jumpPE:Emit(25)
									end
								end
								data.isJumping = true
								data.isFalling = false
							else
								if (now - data.lastFallTick) > 0.3 then
									data.lastFallTick = now
									if data.fallPE and data.fallPE.Parent then
										data.fallPE:Emit(20)
									end
								end
								data.isFalling = true
								data.isJumping = false
							end
						else
							if velY > 15 and (velY - data.prevVelY > 18) then
								if (now - data.lastJumpTick) > 0.2 then
									data.lastJumpTick = now
									if data.jumpPE and data.jumpPE.Parent then
										data.jumpPE:Emit(25)
									end
								end
								data.isJumping = true
								data.isFalling = false
							elseif velY < -8 and not data.isFalling then
								if (now - data.lastFallTick) > 0.35 then
									data.lastFallTick = now
									if data.fallPE and data.fallPE.Parent then
										data.fallPE:Emit(20)
									end
								end
								data.isFalling = true
							end
						end
					end

					data.wasGrounded = isGrounded
					data.prevVelY = velY
				end
			end
		end)
		table.insert(fxConnections, monitorConn)
	end
end

-- Matrix Rain Overlay
local glyphs = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&*/+<>[]{}()\\|"
local function randGlyph()
	local idx = math.random(1, #glyphs)
	return string.sub(glyphs, idx, idx)
end

local function setMatrix(state)
	matrixEnabled = state
	for _, c in pairs(matrixConns) do c:Disconnect() end
	table.clear(matrixConns)

	if matrixGui then
		matrixGui:Destroy()
		matrixGui = nil
	end

	if not state then return end

	matrixGui = Instance.new("ScreenGui")
	matrixGui.Name = "MatrixRainOverlay"
	matrixGui.IgnoreGuiInset = true
	matrixGui.ResetOnSpawn = false
	matrixGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	matrixGui.Parent = localPlayer:WaitForChild("PlayerGui")

	local columns = 40
	for i = 1, columns do
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Code
		lbl.TextColor3 = Color3.fromRGB(120, 255, 120)
		lbl.TextSize = 14
		lbl.Text = randGlyph()
		lbl.Position = UDim2.new(i / columns, -8, math.random(), -200)
		lbl.Size = UDim2.fromOffset(16, 2000)
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.ZIndex = 0
		lbl.Parent = matrixGui

		local conn = RunService.Heartbeat:Connect(function(dt)
			if not lbl or not lbl.Parent then return end
			local p = lbl.Position
			local ny = p.Y.Scale + dt * (0.08 + (i % 7) * 0.01)
			if ny > 1 then ny = -0.1 end
			lbl.Position = UDim2.new(p.X.Scale, p.X.Offset, ny, p.Y.Offset)
			if math.random() < 0.15 then
				lbl.Text = randGlyph()
			end
		end)
		table.insert(matrixConns, conn)
	end
end

-- =======================================================================
--   CORE TARGETING & BOT FUNCTIONS
-- =======================================================================
local function getZombies()
	local folder = Workspace:FindFirstChild("_Zombies")
		or Workspace:FindFirstChild("Zombies")
		or Workspace:FindFirstChild("Enemies")
	if not folder then return {} end

	local list = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			local hrp = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
			local hum = child:FindFirstChildOfClass("Humanoid")
			if hrp and (not hum or hum.Health > 0) then
				table.insert(list, child)
			end
		end
	end
	return list
end

local function getNearestZombie()
	local zombies = getZombies()
	local hrp = getHRP()
	if not hrp or #zombies == 0 then return nil end

	local myPos = hrp.Position
	local nearest, nearestDist = nil, math.huge
	for _, z in ipairs(zombies) do
		local zHRP = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso")
		if zHRP then
			local d = (zHRP.Position - myPos).Magnitude
			if d < nearestDist then
				nearestDist = d
				nearest = z
			end
		end
	end
	return nearest
end

local function cancelCurrentTween()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	local hrp = getHRP()
	if hrp then
		hrp.Anchored = false
	end
end

local function tweenToZombie(targetZombie)
	local myHRP = getHRP()
	local targetHRP = targetZombie and (targetZombie:FindFirstChild("HumanoidRootPart") or targetZombie:FindFirstChild("Torso"))
	if not myHRP or not targetHRP then return end

	cancelCurrentTween()

	local targetPos = targetHRP.Position + OFFSET
	local targetCFrame = CFrame.lookAt(targetPos, targetHRP.Position)
	local distance = (myHRP.Position - targetPos).Magnitude
	local duration = math.max(0.15, distance / math.max(1, tweenSpeed))

	myHRP.Anchored = true
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	activeTween = TweenService:Create(myHRP, tweenInfo, { CFrame = targetCFrame })

	activeTween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed or state == Enum.PlaybackState.Cancelled then
			if myHRP and myHRP.Parent then
				myHRP.Anchored = false
			end
			activeTween = nil
		end
	end)
	activeTween:Play()
end

local function clearESP()
	for _, z in ipairs(getZombies()) do
		local hl = z:FindFirstChild("DevZombieHighlight")
		if hl then hl:Destroy() end
	end
end

-- =======================================================================
--   HALLOWEEN / TRICK OR TREAT LOGIC (240-SECOND / 4-MINUTE COOLDOWN)
-- =======================================================================
local unlitHouses          = {}
local currentKnockingHouse = nil
local minHouseY            = 5
local HOUSE_COOLDOWN       = 240

task.spawn(function()
	local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
	local uiFolder = eventsFolder and eventsFolder:WaitForChild("UI", 5)
	local notifyRemote = (uiFolder and uiFolder:FindFirstChild("Notify")) 
		or ReplicatedStorage:FindFirstChild("Notify", true)

	if notifyRemote and notifyRemote:IsA("RemoteEvent") then
		notifyRemote.OnClientEvent:Connect(function(msg, ...)
			if typeof(msg) == "string" and string.find(string.lower(msg), "lights are out") then
				if currentKnockingHouse then
					unlitHouses[currentKnockingHouse] = tick() + HOUSE_COOLDOWN
					print(string.format("[TrickOrTreat] '%s' lights are out! Cooldown set for 4 minutes (240s).", currentKnockingHouse.Name))
				end
			end
		end)
	end
end)

local function getHalloweenBuildingFolder()
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then return nil end
	local hw = areas:FindFirstChild("Halloween")
	if not hw then return nil end

	local tot = hw:FindFirstChild("Haloweem Trick or Treat ") or hw:FindFirstChild("Haloweem Trick or Treat")
	if not tot then return nil end

	return tot:FindFirstChild("Building")
end

local function isHousePhysicallyLit(house)
	if house:GetAttribute("Lit") == false or house:GetAttribute("Active") == false then
		return false
	end

	local litVal = house:FindFirstChild("IsLit") or house:FindFirstChild("Lit")
	if litVal and litVal:IsA("BoolValue") and not litVal.Value then
		return false
	end

	local hasAnyLightSource = false
	for _, desc in ipairs(house:GetDescendants()) do
		if desc:IsA("Light") then
			hasAnyLightSource = true
			if desc.Enabled then
				return true
			end
		end
	end

	if hasAnyLightSource then
		return false
	end

	return true
end

local function getAllHouses()
	local buildingFolder = getHalloweenBuildingFolder()
	if not buildingFolder then return {} end

	local houseList = {}

	for index, house in ipairs(buildingFolder:GetChildren()) do
		local prompt = house:FindFirstChild("TrickOrTreatPrompt", true) 
			or house:FindFirstChildOfClass("ProximityPrompt", true)

		if prompt then
			local promptPoint = house:FindFirstChild("TrickOrTreatPromptPoint", true) or prompt.Parent

			local worldPos = nil
			if promptPoint:IsA("Attachment") then
				worldPos = promptPoint.WorldPosition
			elseif promptPoint:IsA("BasePart") then
				worldPos = promptPoint.Position
			elseif promptPoint.Parent and promptPoint.Parent:IsA("BasePart") then
				worldPos = promptPoint.Parent.Position
			end

			if worldPos and worldPos.Y >= minHouseY then
				table.insert(houseList, {
					house  = house,
					point  = promptPoint,
					prompt = prompt,
					pos    = worldPos
				})
			end
		end
	end

	return houseList
end

local function runTrickOrTreatSweep(singleRun)
	if totLoopRunning and not singleRun then return end
	totLoopRunning = true

	local houses = getAllHouses()
	if #houses == 0 then
		window:Notify({
			title = "Trick or Treat",
			content = "No valid surface houses found!",
			duration = 3
		})
		totLoopRunning = false
		return
	end

	for index, houseData in ipairs(houses) do
		if not autoTotEnabled and not singleRun then break end

		local house = houseData.house
		local prompt = houseData.prompt
		local targetPoint = houseData.point
		local hrp = getHRP()

		if unlitHouses[house] and tick() < unlitHouses[house] then
			continue
		end

		if not isHousePhysicallyLit(house) then
			continue
		end

		if hrp and prompt and prompt.Parent and targetPoint then
			cancelCurrentTween()

			local targetCFrame = nil
			if targetPoint:IsA("Attachment") then
				targetCFrame = targetPoint.WorldCFrame
			elseif targetPoint:IsA("BasePart") then
				targetCFrame = targetPoint.CFrame
			elseif targetPoint.Parent and targetPoint.Parent:IsA("BasePart") then
				targetCFrame = targetPoint.Parent.CFrame
			end

			if targetCFrame then
				if targetCFrame.Position.Y < minHouseY then
					continue
				end

				currentKnockingHouse = house

				hrp.CFrame = targetCFrame + Vector3.new(0, 1.5, 0)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero

				task.wait(0.25)
				interactWithPrompt(prompt)
				task.wait(0.35)

				if unlitHouses[house] and tick() < unlitHouses[house] then
					currentKnockingHouse = nil
					continue
				end

				unlitHouses[house] = tick() + HOUSE_COOLDOWN
				print(string.format("[TrickOrTreat] Successfully looted '%s'. Cooldown set for 4 minutes (240s).", house.Name))

				task.wait(math.max(0, totDelay - 0.6))
				currentKnockingHouse = nil
			end
		end
	end

	totLoopRunning = false
end

-- =======================================================================
--   ACCURATE MULTI-GRAVE SCANNER
-- =======================================================================
local function getAllGraveSpots()
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then return {} end
	local hw = areas:FindFirstChild("Halloween")
	if not hw then return {} end

	local list = {}
	local addedPrompts = {}

	for _, child in ipairs(hw:GetChildren()) do
		if string.lower(child.Name) == "grave" or string.find(string.lower(child.Name), "grave") then
			local partsFolder = child:FindFirstChild("Parts")
			if partsFolder then
				for _, subGrave in ipairs(partsFolder:GetChildren()) do
					local prompt = subGrave:FindFirstChild("GraveDigPrompt", true) 
						or subGrave:FindFirstChildOfClass("ProximityPrompt", true)
					
					if prompt and not addedPrompts[prompt] then
						addedPrompts[prompt] = true
						local tpPoint = subGrave:FindFirstChild("GraveDigPromptPoint", true) 
							or prompt.Parent
						table.insert(list, {
							part   = subGrave,
							point  = tpPoint,
							prompt = prompt
						})
					end
				end
			end

			for _, desc in ipairs(child:GetDescendants()) do
				if desc:IsA("ProximityPrompt") and (desc.Name == "GraveDigPrompt" or string.find(desc.Name, "Dig")) then
					if not addedPrompts[desc] then
						addedPrompts[desc] = true
						local tpPoint = desc.Parent
						local hostPart = (tpPoint:IsA("BasePart") and tpPoint) 
							or (tpPoint:IsA("Attachment") and tpPoint.Parent) 
							or child:FindFirstChildOfClass("BasePart", true)
						table.insert(list, {
							part   = hostPart,
							point  = tpPoint,
							prompt = desc
						})
					end
				end
			end
		end
	end

	if #list == 0 then
		for _, desc in ipairs(hw:GetDescendants()) do
			if desc:IsA("ProximityPrompt") and (desc.Name == "GraveDigPrompt" or string.find(desc.Name, "Dig")) then
				if not addedPrompts[desc] then
					addedPrompts[desc] = true
					local tpPoint = desc.Parent
					table.insert(list, {
						part   = (tpPoint:IsA("BasePart") and tpPoint) or (tpPoint:IsA("Attachment") and tpPoint.Parent) or desc.Parent,
						point  = tpPoint,
						prompt = desc
					})
				end
			end
		end
	end

	return list
end

local function runGraveDigSweep(singleRun)
	if digLoopRunning and not singleRun then return end
	digLoopRunning = true

	local graves = getAllGraveSpots()
	if #graves == 0 then
		window:Notify({
			title = "Auto Dig Grave",
			content = "No graves found in workspace!",
			duration = 3
		})
		digLoopRunning = false
		return
	end

	for index, graveData in ipairs(graves) do
		if not autoDigEnabled and not singleRun then break end

		local hrp = getHRP()
		local prompt = graveData.prompt
		local targetPoint = graveData.point or graveData.part

		if hrp and prompt and prompt.Parent and targetPoint then
			if prompt.Enabled then
				cancelCurrentTween()

				local targetCFrame = nil
				if targetPoint:IsA("BasePart") then
					targetCFrame = targetPoint.CFrame
				elseif targetPoint:IsA("Attachment") then
					targetCFrame = targetPoint.WorldCFrame
				elseif graveData.part and graveData.part:IsA("BasePart") then
					targetCFrame = graveData.part.CFrame
				elseif graveData.part and graveData.part:IsA("Model") then
					targetCFrame = graveData.part:GetPivot()
				end

				if targetCFrame then
					hrp.CFrame = targetCFrame + Vector3.new(0, 2.5, 0)
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero

					task.wait(0.3)
					interactWithPrompt(prompt)
					task.wait(digDelay)
				end
			end
		end
	end

	digLoopRunning = false
end

-- Respawn hooks
localPlayer.CharacterAdded:Connect(function(char)
	applyCharacterSettings(char)

	task.wait(0.2)
	if noclipEnabled then setNoclip(true) end
	if flyEnabled then setFly(true) end
	if walkOnWaterEnabled then setWalkOnWater(true) end
	if ragdollEnabled then setRagdoll(true) end
end)

-- =======================================================================
--   RUNSERVICE RENDER LOOPS
-- =======================================================================
RunService.RenderStepped:Connect(function()
	if tracerEnabled then
		if not tracerBeam then
			tracerBeam = Instance.new("Beam")
			tracerBeam.Name = "TracerBeam"
			tracerBeam.Color = ColorSequence.new(Color3.fromRGB(255, 45, 45))
			tracerBeam.Width0 = 0.1
			tracerBeam.Width1 = 0.1
			tracerBeam.FaceCamera = true
			tracerBeam.LightEmission = 1
			tracerBeam.Parent = camera
		end

		local myHRP = getHRP()
		local nearest = getNearestZombie()

		if myHRP and nearest then
			local targetHRP = nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChild("Torso")
			if targetHRP then
				if not playerAttachment or playerAttachment.Parent ~= myHRP then
					playerAttachment = Instance.new("Attachment", myHRP)
				end
				local targetAtt = targetHRP:FindFirstChild("TargetAtt") or Instance.new("Attachment", targetHRP)
				targetAtt.Name = "TargetAtt"

				tracerBeam.Attachment0 = playerAttachment
				tracerBeam.Attachment1 = targetAtt
				tracerBeam.Enabled = true
			else
				if tracerBeam then tracerBeam.Enabled = false end
			end
		else
			if tracerBeam then tracerBeam.Enabled = false end
		end
	elseif tracerBeam then
		tracerBeam.Enabled = false
	end

	if espEnabled then
		for _, z in ipairs(getZombies()) do
			if not z:FindFirstChild("DevZombieHighlight") then
				local hl = Instance.new("Highlight")
				hl.Name = "DevZombieHighlight"
				hl.FillColor = Color3.fromRGB(255, 45, 45)
				hl.FillTransparency = 0.5
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.OutlineTransparency = 0.2
				hl.Adornee = z
				hl.Parent = z
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpEnabled then
		local hum = getHumanoid()
		if hum and hum.Parent then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			hum:ChangeState(Enum.HumanoidStateType.Seated)
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- =======================================================================
--   BUILD UI (RAYFIELD GEN2 API)
-- =======================================================================
local window = Rayfield:CreateWindow({
	name = "OP HUB",
	subtitle = "OP HUB",
	sidebarLayout = true,
	theme = "Rose",
	showText = "OP HUB",
	ShowText = "OP HUB"
})

window:Notify({
	title = "OP HUB",
	content = "OP HUB loaded successfully.",
	duration = 4
})

-- -----------------------------------------------------------------------
--   TAB: HALLOWEEN (TRICK OR TREAT & GRAVES)
-- -----------------------------------------------------------------------
local halloweenTab = window:CreateTab({
	name = "Halloween",
	icon = 0
})

-- --- Trick or Treat Section ---
halloweenTab:CreateToggle({
	name = "Auto Trick or Treat (Loop)",
	currentValue = false,
	callback = function(value)
		autoTotEnabled = value
		if autoTotEnabled then
			task.spawn(function()
				while autoTotEnabled do
					runTrickOrTreatSweep(false)
					task.wait(1)
				end
			end)
		end
	end
})

halloweenTab:CreateButton({
	name = "Trick or Treat All Houses (Once)",
	callback = function()
		task.spawn(function()
			runTrickOrTreatSweep(true)
		end)
	end
})

halloweenTab:CreateSlider({
	name = "House Delay",
	range = { 0.5, 5 },
	increment = 0.1,
	suffix = " s",
	currentValue = 1.5,
	callback = function(val)
		totDelay = val
	end
})

halloweenTab:CreateDivider()

-- --- Auto Dig Grave Section ---
halloweenTab:CreateToggle({
	name = "Auto Dig Graves (Loop)",
	currentValue = false,
	callback = function(value)
		autoDigEnabled = value
		if autoDigEnabled then
			task.spawn(function()
				while autoDigEnabled do
					runGraveDigSweep(false)
					task.wait(1)
				end
			end)
		end
	end
})

halloweenTab:CreateButton({
	name = "Dig All Graves (Once)",
	callback = function()
		task.spawn(function()
			runGraveDigSweep(true)
		end)
	end
})

halloweenTab:CreateSlider({
	name = "Grave Delay",
	range = { 0.5, 5 },
	increment = 0.1,
	suffix = " s",
	currentValue = 1.5,
	callback = function(val)
		digDelay = val
	end
})

-- -----------------------------------------------------------------------
--   TAB: GARAGES
-- -----------------------------------------------------------------------
local garagesTab = window:CreateTab({
	name = "Garages",
	icon = 0
})

garagesTab:CreateToggle({
	name = "Auto Start Garage 1 (10 Candy)",
	currentValue = false,
	callback = function(value)
		autoStartGarages[1] = value
	end
})

garagesTab:CreateToggle({
	name = "Auto Start Garage 2 (20 Candy)",
	currentValue = false,
	callback = function(value)
		autoStartGarages[2] = value
	end
})

garagesTab:CreateToggle({
	name = "Auto Start Garage 3 (30 Candy)",
	currentValue = false,
	callback = function(value)
		autoStartGarages[3] = value
	end
})

garagesTab:CreateToggle({
	name = "Auto Start Garage 4 (40 Candy)",
	currentValue = false,
	callback = function(value)
		autoStartGarages[4] = value
	end
})

-- -----------------------------------------------------------------------
--   TAB: ZOMBIES
-- -----------------------------------------------------------------------
local zombiesTab = window:CreateTab({
	name = "Zombies",
	icon = 0
})

local zombieStat = zombiesTab:CreateStat({
	name = "Zombies on Map",
	value = 0
})

zombiesTab:CreateDivider()

zombiesTab:CreateButton({
	name = "Tween to Nearest Zombie",
	callback = function()
		local n = getNearestZombie()
		if n then tweenToZombie(n) end
	end
})

zombiesTab:CreateButton({
	name = "Cancel Active Motion",
	callback = function()
		cancelCurrentTween()
	end
})

zombiesTab:CreateSlider({
	name = "Tween Speed",
	range = { 30, 250 },
	increment = 5,
	suffix = " studs/s",
	currentValue = 100,
	callback = function(val)
		tweenSpeed = val
	end
})

zombiesTab:CreateDivider()

zombiesTab:CreateToggle({
	name = "Entity Highlight (ESP)",
	currentValue = false,
	callback = function(value)
		espEnabled = value
		if not espEnabled then clearESP() end
	end
})

zombiesTab:CreateToggle({
	name = "Target Tracer Beam",
	currentValue = false,
	callback = function(value)
		tracerEnabled = value
	end
})

-- -----------------------------------------------------------------------
--   TAB: PLAYER
-- -----------------------------------------------------------------------
local playerTab = window:CreateTab({
	name = "Player",
	icon = 0
})

playerTab:CreateToggle({
	name = "Insta Repair / Instant Hold",
	currentValue = false,
	callback = function(value)
		setInstantPrompts(value)
	end
})

playerTab:CreateDivider()

playerTab:CreateSlider({
	name = "WalkSpeed",
	range = { 16, 200 },
	increment = 1,
	suffix = " speed",
	currentValue = 16,
	callback = function(val)
		currentWalkSpeed = val
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = val end
	end
})

playerTab:CreateSlider({
	name = "Jump Power",
	range = { 0, 300 },
	increment = 5,
	suffix = " power",
	currentValue = 50,
	callback = function(val)
		currentJumpPower = val
		local hum = getHumanoid()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = val
		end
	end
})

playerTab:CreateSlider({
	name = "World Gravity",
	range = { 0, 500 },
	increment = 10,
	suffix = " grav",
	currentValue = Workspace.Gravity,
	callback = function(val)
		currentGravity = val
		Workspace.Gravity = val
	end
})

playerTab:CreateSlider({
	name = "Camera FOV",
	range = { 40, 120 },
	increment = 1,
	suffix = " deg",
	currentValue = camera.FieldOfView,
	callback = function(val)
		camera.FieldOfView = val
	end
})

playerTab:CreateDivider()

playerTab:CreateToggle({
	name = "Infinite Jump",
	currentValue = false,
	callback = function(value)
		infJumpEnabled = value
	end
})

playerTab:CreateToggle({
	name = "Anti-AFK Protection",
	currentValue = false,
	callback = function(value)
		antiAfkEnabled = value
		if antiAfkEnabled then
			antiAfkConn = localPlayer.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end)
		else
			if antiAfkConn then
				antiAfkConn:Disconnect()
				antiAfkConn = nil
			end
		end
	end
})

playerTab:CreateToggle({
	name = "Fullbright / Clear Fog",
	currentValue = false,
	callback = function(value)
		fullbrightEnabled = value
		if fullbrightEnabled then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
		else
			Lighting.Brightness = 1
			Lighting.GlobalShadows = true
		end
	end
})

playerTab:CreateButton({
	name = "Respawn Character",
	callback = function()
		local hum = getHumanoid()
		if hum then hum.Health = 0 end
	end
})

-- -----------------------------------------------------------------------
--   TAB: MOVEMENT
-- -----------------------------------------------------------------------
local movementTab = window:CreateTab({
	name = "Movement",
	icon = 0
})

movementTab:CreateToggle({
	name = "Fly Mode",
	currentValue = false,
	callback = function(value)
		setFly(value)
	end
})

movementTab:CreateSlider({
	name = "Fly Speed",
	range = { 10, 200 },
	increment = 5,
	suffix = " speed",
	currentValue = 60,
	callback = function(val)
		flySpeed = val
	end
})

movementTab:CreateDivider()

movementTab:CreateToggle({
	name = "Noclip",
	currentValue = false,
	callback = function(value)
		setNoclip(value)
	end
})

movementTab:CreateToggle({
	name = "Walk On Water",
	currentValue = false,
	callback = function(value)
		setWalkOnWater(value)
	end
})

-- -----------------------------------------------------------------------
--   TAB: FUN & FX
-- -----------------------------------------------------------------------
local funTab = window:CreateTab({
	name = "Fun / FX",
	icon = 0
})

funTab:CreateToggle({
	name = "Ragdoll Mode",
	currentValue = false,
	callback = function(value)
		setRagdoll(value)
	end
})

funTab:CreateToggle({
	name = "Jump & Fall FX (Synced)",
	currentValue = false,
	callback = function(value)
		setLowGravFX(value)
	end
})

funTab:CreateToggle({
	name = "Matrix Rain Overlay",
	currentValue = false,
	callback = function(value)
		setMatrix(value)
	end
})

funTab:CreateDivider()

funTab:CreateButton({
	name = "Explode Me",
	callback = function()
		explodeMe()
	end
})

-- -----------------------------------------------------------------------
--   TAB: TPS
-- -----------------------------------------------------------------------
local tpsTab = window:CreateTab({
	name = "TPs",
	icon = 0
})

local CustomTargets = {
	["Shopping Mall"] = function(area)
		local spawns = area:FindFirstChild("ShoppingMallCarSpawns", true)
		if spawns then
			return spawns:FindFirstChildOfClass("BasePart") or spawns:FindFirstChild("Part") or spawns:FindFirstChildWhichIsA("BasePart", true)
		end
	end,
	["Carnanval"] = function(area)
		local npcFolder = area:FindFirstChild("NPC")
		local monkey = (npcFolder and npcFolder:FindFirstChild("Circus Monkey")) or area:FindFirstChild("Circus Monkey", true)
		return monkey and (monkey:FindFirstChild("HumanoidRootPart") or monkey:FindFirstChild("UpperTorso") or monkey:FindFirstChild("Torso") or monkey.PrimaryPart or monkey:FindFirstChildWhichIsA("BasePart", true))
	end
}

local function resolveAreaTarget(areaFolder)
	if not areaFolder then return nil end
	local name = areaFolder.Name

	-- 1. Carnanval Exception: Target Circus Monkey
	if name == "Carnanval" then
		local customFinder = CustomTargets["Carnanval"]
		local monkey = customFinder and customFinder(areaFolder)
		if monkey then
			if monkey:IsA("Model") then return monkey:GetPivot() end
			if monkey:IsA("BasePart") then return monkey.CFrame end
		end
	end

	-- 2. Shopping Mall Exception: Target ShoppingMallCarSpawns
	if name == "Shopping Mall" then
		local customFinder = CustomTargets["Shopping Mall"]
		local spawnTarget = customFinder and customFinder(areaFolder)
		if spawnTarget then
			if spawnTarget:IsA("Model") then return spawnTarget:GetPivot() end
			if spawnTarget:IsA("BasePart") then return spawnTarget.CFrame end
		end
	end

	-- 3. Default: Find "Lost and Found Box" for all other areas
	local box = areaFolder:FindFirstChild("Lost and Found Box", true)
	if box then
		local cube = box:FindFirstChild("Meshes/LNF_Cube", true) or box:FindFirstChild("LNF_Cube", true)
		if cube and cube:IsA("BasePart") then
			return cube.CFrame
		end
		if box:IsA("Model") then
			return box:GetPivot()
		elseif box:IsA("BasePart") then
			return box.CFrame
		end
		local anyPart = box:FindFirstChildWhichIsA("BasePart", true)
		if anyPart then return anyPart.CFrame end
	end

	-- 4. Fallback if area has no box
	local anyPart = areaFolder:FindFirstChildWhichIsA("BasePart", true)
	if anyPart then return anyPart.CFrame end
	if areaFolder:IsA("Model") then return areaFolder:GetPivot() end

	return nil
end

local function teleportToTarget(targetCFrame, name, yOffset)
	local hrp = getHRP()
	if not hrp or not targetCFrame then return end

	cancelCurrentTween()

	local offset = yOffset or 4.5
	local destCFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, offset, 0))

	hrp.CFrame = destCFrame
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	if name then
		window:Notify({
			title = "Teleport",
			content = "Teleported to " .. name,
			duration = 2
		})
	end
end

local function buildTPs()
	local areasFolder = Workspace:FindFirstChild("Areas")
	if not areasFolder then
		window:Notify({
			title = "TPs Warning",
			content = "Workspace.Areas folder not found.",
			duration = 4
		})
		return
	end

	for _, areaFolder in ipairs(areasFolder:GetChildren()) do
		tpsTab:CreateButton({
			name = "TP " .. areaFolder.Name,
			callback = function()
				if areaFolder.Name == "Shopping Mall" then
					task.spawn(function()
						-- Step 1: Teleport to Junk Yard's Lost and Found Box first
						local junkYard = areasFolder:FindFirstChild("Junk Yard") or areasFolder:FindFirstChild("Junkyard")
						if junkYard then
							local jyTarget = resolveAreaTarget(junkYard)
							if jyTarget then
								teleportToTarget(jyTarget, "Junk Yard (Transit)", 4.5)
								task.wait(0.4)
							end
						end

						-- Step 2: Teleport into Shopping Mall
						local mallTarget = resolveAreaTarget(areaFolder)
						if mallTarget then
							teleportToTarget(mallTarget, "Shopping Mall", 4.5)
						else
							window:Notify({
								title = "Teleport Failed",
								content = "Could not find destination for Shopping Mall",
								duration = 3
							})
						end
					end)
				else
					local targetCFrame = resolveAreaTarget(areaFolder)
					if targetCFrame then
						teleportToTarget(targetCFrame, areaFolder.Name, 4.5)
					else
						window:Notify({
							title = "Teleport Failed",
							content = "Could not find destination for " .. areaFolder.Name,
							duration = 3
						})
					end
				end
			end
		})
	end
end

buildTPs()

-- =======================================================================
--   DYNAMIC ENTITY COUNTER
-- =======================================================================
task.spawn(function()
	while true do
		local count = #getZombies()
		pcall(function()
			zombieStat:Set(count)
		end)
		task.wait(0.5)
	end
end)

-- Toggle Menu Keybind (Right Control)
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
		window:ToggleHide()
	end
end)
