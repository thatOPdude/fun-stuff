-- // ===== Discord UI (remote) + Furnace Runner + Player Fun Tab =====

-- pull the UI lib from your GitHub raw URL (executor-friendly)
local LIB_URL = "https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/refs/heads/main/Discord%20UI%20Lib/Discord%20Lib%20Source.lua"
local DiscordLib = loadstring(game:HttpGet(LIB_URL))()

-- services / player
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- keep occluders transparent
player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam

-- ===== CONFIG =====
local FURNACES_FOLDER = workspace:WaitForChild("Map")
    :WaitForChild("Tycoons")
    :WaitForChild("Tycoon1")
    :WaitForChild("Furnaces")

local PROMPT_TAKEOUT = "TakeOutMetal"
local PROMPT_OVERDRIVE = "Overdrive"

local TAKE_OUT_COUNT = 6
local BETWEEN_TAKEOUT = 0.10
local APPROACH_BUFFER = 3.8      -- stand slightly in front
local MOVE_SPEED = 80            -- studs/sec (snappy)
local MOVETO_TOLERANCE = 3
local MAX_STAND_DIST = 10
local MAX_NUDGE_TRIES = 2

-- ===== helpers =====
local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid  = character:WaitForChild("Humanoid")
    hrp       = character:WaitForChild("HumanoidRootPart")
end

local function getFurnaces()
    local t = {}
    for _, c in ipairs(FURNACES_FOLDER:GetChildren()) do
        if c:IsA("Model") or c:IsA("Folder") then
            table.insert(t, c)
        end
    end
    table.sort(t, function(a,b) return a.Name < b.Name end)
    return t
end

local function findPrompt(root, name)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name == name then
            return d
        end
    end
end

local function promptPart(prompt)
    local p = prompt and prompt.Parent
    if p and p:IsA("BasePart") then return p end
    if p and p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then
        return p.Parent
    end
end

-- face target without pitch/roll
local function yawLookAt(fromPos, toPos)
    local dir = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z)
    if dir.Magnitude < 1e-3 then return CFrame.new(fromPos) end
    return CFrame.new(fromPos, fromPos + dir.Unit)
end

-- pick a stable spot around the part (front/back/right/left)
local function bestStandCF(part, prompt)
    local cf = part.CFrame
    local maxAct = (prompt and prompt.MaxActivationDistance or 12)
    local distClamp = math.max(2, math.min(MAX_STAND_DIST, maxAct - 0.5))
    local outward = math.max(math.max(part.Size.X, part.Size.Z) * 0.5 + APPROACH_BUFFER, 2)

    local dirs = { cf.LookVector, -cf.LookVector, cf.RightVector, -cf.RightVector }
    local best, scoreBest = cf, -1
    for _, dir in ipairs(dirs) do
        local pos = part.Position + dir * outward + Vector3.new(0, 2.25, 0)
        local horiz = Vector3.new(pos.X - part.Position.X, 0, pos.Z - part.Position.Z)
        if horiz.Magnitude > distClamp then
            pos = part.Position + horiz.Unit * distClamp + Vector3.new(0, pos.Y - part.Position.Y, 0)
        end
        local cand = CFrame.new(pos, part.Position)
        local score = 1/(1+(cand.Position-hrp.Position).Magnitude) + (cand.Position-part.Position).Magnitude
        if score > scoreBest then scoreBest, best = score, cand end
    end
    return best
end

-- anchored, yaw-only, zero-vel tween (no fling/spin)
local currentTween
local function tweenTo(targetCF)
    if not hrp or not hrp.Parent then return false end

    local startCF = hrp.CFrame
    local goalCF  = yawLookAt(targetCF.Position, targetCF.LookVector + targetCF.Position)
    local d       = (startCF.Position - goalCF.Position).Magnitude
    local duration = math.max(0.04, d / MOVE_SPEED)

    if currentTween then currentTween:Cancel() end
    local alpha = Instance.new("NumberValue"); alpha.Value = 0
    currentTween = TweenService:Create(alpha, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = 1})

    local wasAnchored = hrp.Anchored
    hrp.Anchored = true
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    local conn = RunService.Heartbeat:Connect(function()
        local a = alpha.Value
        local pos = startCF.Position:Lerp(goalCF.Position, a)
        hrp.CFrame = yawLookAt(pos, targetCF.Position)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    currentTween:Play()
    currentTween.Completed:Wait()
    if conn then conn:Disconnect() end
    alpha:Destroy()
    currentTween = nil

    hrp.CFrame = goalCF
    hrp.Anchored = wasAnchored
    return (hrp.Position - goalCF.Position).Magnitude <= MOVETO_TOLERANCE
end

local function inRange(prompt)
    local p = promptPart(prompt)
    return p and (hrp.Position - p.Position).Magnitude <= (prompt.MaxActivationDistance + 0.5)
end

local function firePrompt(prompt)
    local oldLOS, oldDist = prompt.RequiresLineOfSight, prompt.MaxActivationDistance
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = math.max(oldDist, 12)
    local hold = prompt.HoldDuration or 0
    prompt:InputHoldBegin()
    if hold > 0 then task.wait(hold + 0.02) else RunService.Heartbeat:Wait() end
    prompt:InputHoldEnd()
    prompt.RequiresLineOfSight, prompt.MaxActivationDistance = oldLOS, oldDist
end

-- ===== state / loop =====
local running = false
local overdriveOnly = false
local busy = false

local function runOneFurnace(furnace)
    local take = findPrompt(furnace, PROMPT_TAKEOUT)
    local part = (take and promptPart(take)) or (findPrompt(furnace, PROMPT_OVERDRIVE) and promptPart(findPrompt(furnace, PROMPT_OVERDRIVE)))
    if not part then return end

    -- go to a safe front spot
    local stand = bestStandCF(part, take)
    tweenTo(stand)

    -- nudge if somehow out of range
    local tries = 0
    while not overdriveOnly and take and (not inRange(take)) and tries < MAX_NUDGE_TRIES do
        tries = tries + 1
        tweenTo(stand * CFrame.new(0, 0, -1.25 * tries))
    end

    if overdriveOnly then
        local od = findPrompt(furnace, PROMPT_OVERDRIVE)
        if od and inRange(od) then
            firePrompt(od)
            task.wait(0.10) -- tiny pause so server registers it
        end
        return
    else
        if take then
            for i = 1, TAKE_OUT_COUNT do
                if not running then break end
                if inRange(take) then firePrompt(take) end
                task.wait(BETWEEN_TAKEOUT)
            end
        end
        return
    end
end

local function mainLoop()
    if busy then return end
    busy = true
    while running do
        for _, furnace in ipairs(getFurnaces()) do
            if not running then break end
            runOneFurnace(furnace)
        end
    end
    busy = false
end

-- ====== Discord UI wiring ======
local win = DiscordLib:Window("Utility Hub")
local srv = win:Server("Tycoon", "rbxassetid://7733765398") -- icon optional
local chFurn = srv:Channel("Furnaces")
local chPlayer = srv:Channel("Player")
local chSettings = srv:Channel("Settings")

-- Metal Pickup toggle
chFurn:Toggle("Metal Pickup", false, function(state)
    running = state
    if state then
        refreshCharacter()
        task.spawn(mainLoop)
        DiscordLib:Notification("Metal Pickup", "Started.", "Okay!")
    else
        if currentTween then currentTween:Cancel() end
        DiscordLib:Notification("Metal Pickup", "Stopped.", "Okay!")
    end
end)

-- Overdrive-only toggle
chFurn:Toggle("Overdrive Only", false, function(state)
    overdriveOnly = state
    if state then
        DiscordLib:Notification("Mode", "Overdrive-only enabled.", "Nice")
    else
        DiscordLib:Notification("Mode", "Back to TakeOut x6 @ 0.1s.", "Got it")
    end
end)

-- =========================
-- Player tab: FUN FEATURES
-- =========================
-- WalkSpeed
chPlayer:Slider("WalkSpeed", 4, 200, humanoid.WalkSpeed, function(v)
    humanoid.WalkSpeed = math.clamp(tonumber(v) or humanoid.WalkSpeed, 4, 200)
end)

-- Camera FOV
chPlayer:Slider("Camera FOV", 40, 120, camera.FieldOfView, function(v)
    camera.FieldOfView = math.clamp(tonumber(v) or camera.FieldOfView, 40, 120)
end)

-- ---------- Infinite Jump ----------
local infJumpOn = false
local jumpConn
local function setInfiniteJump(on)
    infJumpOn = on
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    if on then
        jumpConn = UserInputService.JumpRequest:Connect(function()
            if humanoid and humanoid.Parent then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                humanoid:ChangeState(Enum.HumanoidStateType.Seated) -- cancel fall stun (quick toggle)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end
chPlayer:Toggle("Infinite Jump", false, function(state)
    setInfiniteJump(state)
end)

-- ---------- Noclip ----------
local noclipOn = false
local noclipConn
local function setNoclip(on)
    noclipOn = on
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            if not character or not character.Parent then return end
            for _, v in ipairs(character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end)
    end
end
chPlayer:Toggle("Noclip", false, function(state)
    setNoclip(state)
end)

-- ---------- Fly ----------
local flyOn = false
local flySpeed = 60
local flyConn
local keys = {W=false, A=false, S=false, D=false, Up=false, Down=false}

local function dirVec()
    local cf = camera.CFrame
    local look = cf.LookVector
    local right = cf.RightVector
    local up = Vector3.new(0,1,0)
    local v = Vector3.zero
    if keys.W then v = v + look end
    if keys.S then v = v - look end
    if keys.A then v = v - right end
    if keys.D then v = v + right end
    if keys.Up then v = v + up end      -- Space
    if keys.Down then v = v - up end    -- LeftControl
    if v.Magnitude > 0 then v = v.Unit end
    return v
end

local function setFly(on)
    flyOn = on
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if on then
        -- make sure physics doesn’t fight us
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        flyConn = RunService.RenderStepped:Connect(function(dt)
            if not hrp or not hrp.Parent then return end
            local v = dirVec() * flySpeed
            -- move by CFrame offset so it feels crisp client-side
            if v.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + v * dt
            end
            -- keep velocities zero to prevent drift
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

-- input tracking for fly
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then keys.W = true end
    if key == Enum.KeyCode.A then keys.A = true end
    if key == Enum.KeyCode.S then keys.S = true end
    if key == Enum.KeyCode.D then keys.D = true end
    if key == Enum.KeyCode.Space then keys.Up = true end
    if key == Enum.KeyCode.LeftControl then keys.Down = true end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then keys.W = false end
    if key == Enum.KeyCode.A then keys.A = false end
    if key == Enum.KeyCode.S then keys.S = false end
    if key == Enum.KeyCode.D then keys.D = false end
    if key == Enum.KeyCode.Space then keys.Up = false end
    if key == Enum.KeyCode.LeftControl then keys.Down = false end
end)

chPlayer:Toggle("Fly", false, function(state)
    setFly(state)
end)
chPlayer:Slider("Fly Speed", 10, 200, flySpeed, function(v)
    flySpeed = math.clamp(tonumber(v) or flySpeed, 10, 200)
end)

-- ---------- Anti-AFK (NEW) ----------
local antiAfkOn = false
local antiConn
local VirtualUser = game:GetService("VirtualUser")

local function setAntiAfk(on)
    antiAfkOn = on
    if antiConn then antiConn:Disconnect(); antiConn = nil end
    if on then
        antiConn = player.Idled:Connect(function()
            if not antiAfkOn then return end
            -- slight randomization so it’s not perfectly periodic
            task.wait(0.5 + math.random() * 0.6)
            VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
            task.wait(0.2 + math.random() * 0.2)
            VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
        end)
    end
end

chPlayer:Toggle("Anti-AFK", false, function(state)
    setAntiAfk(state)
    if state then
        DiscordLib:Notification("Anti-AFK", "Anti-AFK enabled.", "Nice")
    else
        DiscordLib:Notification("Anti-AFK", "Anti-AFK disabled.", "Okay!")
    end
end)

-- =========================
-- Settings / Destroy
-- =========================
chSettings:Button("Destroy GUI", function()
    -- turn everything off cleanly
    setInfiniteJump(false)
    setNoclip(false)
    setFly(false)
    setAntiAfk(false) -- NEW: ensure Anti-AFK disconnects
    running = false
    if currentTween then currentTween:Cancel() end

    if win and type(win.Close) == "function" then
        win:Close()
    else
        for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if g:IsA("ScreenGui") and g.Name:lower():find("discord") then g:Destroy() end
        end
    end
end)

-- keep stuff sane after respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
    player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam

    -- reapply fun toggles if they’re on
    if infJumpOn then setInfiniteJump(true) end
    if noclipOn then setNoclip(true) end
    if flyOn then setFly(true) end
    if antiAfkOn then setAntiAfk(true) end -- NEW: reapply Anti-AFK after respawn
end)
