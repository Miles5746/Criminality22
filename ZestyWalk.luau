local ANIMATION_ID = "rbxassetid://134974879985373" -- set to whatever you want this is just a zesty walk
local CONFIGSPEED = 10 --higher = slower


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local function anim2track(asset_id)
    local success, objs = pcall(function()
        return game:GetObjects(asset_id)
    end)
    if not success or #objs == 0 then
        return asset_id
    end

    for _, obj in ipairs(objs) do
        if obj:IsA("Animation") then
            return obj.AnimationId
        end
    end
    return asset_id
end
local function applyAnimation(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    local resolvedId = anim2track(ANIMATION_ID)
    if not resolvedId then
        return
    end
    local animation = Instance.new("Animation")
    animation.AnimationId = resolvedId
    local animationTrack = animator:LoadAnimation(animation)
    if not animationTrack then
        return
    end
    humanoid.Running:Connect(function(speed)
        if speed > 0.1 then
            animationTrack:Play()
            animationTrack:AdjustSpeed(speed / 10)
        else
            animationTrack:Stop()
        end
    end)
end
Players.LocalPlayer.CharacterAdded:Connect(applyAnimation)
if Players.LocalPlayer.Character then
    applyAnimation(Players.LocalPlayer.Character)
end
