-- yes its fe but people can't see the red box

local FLY_SPEED = 50 -- you should know what this is or else you might have problems
local FLY_POWER = 9e4 -- I don't even know what this is I just stole it off c00lk1ngs script
local FLY_ANIMATION_ID = "rbxassetid://104373527884152" -- flying animation, must be an emote to be FE



local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("StarterGui")
CoreGui:SetCore("SendNotification", {
	Title = "Im a bird by miles5746";
	Text = "thx 4 using, get people in in red box 2 'eat' them";
	Duration = 10;
	Button1 = "Ok bro what ever";
})
local flyConn = nil
local flyBG = nil
local flyBV = nil
local HRP = nil
local animationTrack = nil
local walkflinging = true
local Noclipping = nil
local Clip = false
local speaker = Players.LocalPlayer
local touchConnection = nil

local function anim2track(asset_id)
    local success, objs = pcall(game.GetObjects, game, asset_id)
    if not success or not objs or #objs == 0 then return asset_id end
    for _, obj in ipairs(objs) do
        if obj:IsA("Animation") then
            return obj.AnimationId
        end
    end
    return asset_id
end

local function getRoot(character)
    if not character then return nil end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function setupFlySystem(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    HRP = character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    local Highlight = Instance.new("Highlight")
    Highlight.Parent = HRP
    HRP.Transparency = 0

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local resolvedAnimId = anim2track(FLY_ANIMATION_ID)
        local animation = Instance.new("Animation")
        animation.AnimationId = resolvedAnimId
        animationTrack = animator:LoadAnimation(animation)
        if animationTrack then
            animationTrack.Priority = Enum.AnimationPriority.Action4
            animationTrack.Looped = true
            animationTrack:Play()
        end
    end

    flyBG = Instance.new("BodyGyro")
    flyBG.P = FLY_POWER
    flyBG.MaxTorque = Vector3.new(FLY_POWER, FLY_POWER, FLY_POWER)
    flyBG.CFrame = HRP.CFrame
    flyBG.Parent = HRP

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(FLY_POWER, FLY_POWER, FLY_POWER)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = HRP

    flyConn = RunService.Heartbeat:Connect(function()
        if not HRP or not flyBG or not flyBV then return end
        local camCFrame = workspace.CurrentCamera.CFrame
        local dir = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir = dir - Vector3.new(0, 1, 0)
        end

        if dir.Magnitude > 0 then
            dir = dir.Unit * FLY_SPEED
        end
        flyBV.Velocity = dir
        flyBG.CFrame = CFrame.new(HRP.Position, HRP.Position + camCFrame.LookVector)
    end)

    return true
end

local function cleanupFlySystem()
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    if flyBG then
        flyBG:Destroy()
        flyBG = nil
    end
    if flyBV then
        flyBV:Destroy()
        flyBV = nil
    end
    if animationTrack then
        animationTrack:Stop()
        animationTrack = nil
    end
    if touchConnection then
        touchConnection:Disconnect()
        touchConnection = nil
    end
    if Noclipping then
        Noclipping:Disconnect()
        Noclipping = nil
    end
end

local function NoclipLoop()
    if Clip == false and speaker and speaker.Character then
        for _, child in pairs(speaker.Character:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide then
                child.CanCollide = false
            end
        end
    end
end

local function onTouched(otherPart)
    local character = otherPart.Parent
    if not character then return end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end

    local root = getRoot(character)
    if not root then return end

    local vel = root.Velocity
    root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
    task.wait()
    if root and root.Parent then
        root.Velocity = vel
    end
end

local function setupTouchFling(character)
    if touchConnection then
        touchConnection:Disconnect()
    end

    local root = getRoot(character)
    if root then
        touchConnection = root.Touched:Connect(onTouched)
    end
end

local function setupWalkFling(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            walkflinging = false
        end)
    end

    spawn(function()
        repeat RunService.Heartbeat:Wait()
            local root = getRoot(character)
            if not root then continue end

            local vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

            RunService.RenderStepped:Wait()
            if root and root.Parent then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()
            if root and root.Parent then
                root.Velocity = vel + Vector3.new(0, 0.1, 0)
            end
        until walkflinging == false
    end)
end

local function setupCharacter(character)
    setupFlySystem(character)
    setupTouchFling(character)

    Clip = false
    task.wait(0.1)
    Noclipping = RunService.Stepped:Connect(NoclipLoop)
    setupWalkFling(character)
end

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
setupCharacter(character)

player.CharacterAdded:Connect(function(newCharacter)
    cleanupFlySystem()
    setupCharacter(newCharacter)
end)
