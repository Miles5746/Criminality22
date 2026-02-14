local AnimationOverride = {}
local currentTracks = {}
local currentConnections = {}
local defaultWalkSpeed = 16
local localPlayer = game:GetService("Players").LocalPlayer

local function clearCurrentAnimations()
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in pairs(currentTracks) do
                    if track and track.IsPlaying then
                        track:Stop()
                    end
                end
                for _, connection in pairs(currentConnections) do
                    if connection then
                        connection:Disconnect()
                    end
                end
            end
        end
    end
    currentTracks = {}
    currentConnections = {}
end

local function anim2track(asset_id)
    if typeof(asset_id) == "Instance" and asset_id:IsA("Animation") then
        return asset_id.AnimationId
    end
    if type(asset_id) == "string" and asset_id:match("rbxassetid://") then
        return asset_id
    end
    local success, objs = pcall(game.GetObjects, game, "rbxassetid://"..tostring(asset_id):match("%d+"))
    if not success or not objs or #objs == 0 then return "rbxassetid://"..tostring(asset_id) end
    for i = 1, #objs do
        if objs[i]:IsA("Animation") then
            return objs[i].AnimationId
        end
    end
    return "rbxassetid://"..tostring(asset_id)
end

local function loadAnimation(animator, id)
    if not id then return nil end
    local resolvedId = anim2track(id)
    local anim = Instance.new("Animation")
    anim.AnimationId = resolvedId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Core
    return track
end

local function getFallbackTrack(tracks, preferredOrder)
    for _, animType in ipairs(preferredOrder) do
        if tracks[animType] then
            return tracks[animType]
        end
    end
    return nil
end

local function getCharacter()
    return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

function AnimationOverride.Apply(animations, customWalkSpeed)
    clearCurrentAnimations()
    defaultWalkSpeed = customWalkSpeed or 16
    local character = getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    if not animations.Idle then
        animations.Idle = "rbxassetid://507776043"
    end
    for animType, id in pairs(animations) do
        currentTracks[animType] = loadAnimation(animator, id)
    end
    table.insert(currentConnections, humanoid.Running:Connect(function(speed)
        if speed > 0 then
            local shouldRun = humanoid.WalkSpeed > defaultWalkSpeed
            if shouldRun then
                local runTrack = currentTracks.Run or getFallbackTrack(currentTracks, {"Walk", "Idle"})
                if runTrack then
                    runTrack:Play()
                    runTrack:AdjustSpeed(speed/16)
                end
                if currentTracks.Walk and currentTracks.Walk.IsPlaying then
                    currentTracks.Walk:Stop()
                end
            else
                local walkTrack = currentTracks.Walk or getFallbackTrack(currentTracks, {"Run", "Idle"})
                if walkTrack then
                    walkTrack:Play()
                    walkTrack:AdjustSpeed(speed/16)
                end
                if currentTracks.Run and currentTracks.Run.IsPlaying then
                    currentTracks.Run:Stop()
                end
            end
        else
            if currentTracks.Idle then
                currentTracks.Idle:Play()
            end
            if currentTracks.Walk and currentTracks.Walk.IsPlaying then
                currentTracks.Walk:Stop()
            end
            if currentTracks.Run and currentTracks.Run.IsPlaying then
                currentTracks.Run:Stop()
            end
        end
    end))
    table.insert(currentConnections, humanoid.Jumping:Connect(function()
        local jumpTrack = currentTracks.Jump or currentTracks.Idle
        if jumpTrack then
            jumpTrack:Play()
            if currentTracks.Run and currentTracks.Run.IsPlaying then
                currentTracks.Run:Stop()
            end
            if currentTracks.Walk and currentTracks.Walk.IsPlaying then
                currentTracks.Walk:Stop()
            end
        end
    end))
    table.insert(currentConnections, humanoid.FreeFalling:Connect(function()
        local fallTrack = currentTracks.Fall or currentTracks.Idle
        if fallTrack then
            fallTrack:Play()
            if currentTracks.Jump and currentTracks.Jump.IsPlaying then
                currentTracks.Jump:Stop()
            end
        end
    end))
    table.insert(currentConnections, humanoid.Swimming:Connect(function(speed)
        if speed > 0 then
            local swimTrack = currentTracks.Swim or currentTracks.Idle
            if swimTrack then
                swimTrack:Play()
                swimTrack:AdjustSpeed(speed/16)
                if currentTracks.SwimIdle and currentTracks.SwimIdle.IsPlaying then
                    currentTracks.SwimIdle:Stop()
                end
            end
        else
            local swimIdleTrack = currentTracks.SwimIdle or currentTracks.Idle
            if swimIdleTrack then
                swimIdleTrack:Play()
                if currentTracks.Swim and currentTracks.Swim.IsPlaying then
                    currentTracks.Swim:Stop()
                end
            end
        end
    end))
    table.insert(currentConnections, humanoid.Climbing:Connect(function(speed)
        if speed > 0 then
            local climbTrack = currentTracks.Climb or currentTracks.Idle
            if climbTrack then
                climbTrack:Play()
                climbTrack:AdjustSpeed(speed/16)
                if currentTracks.ClimbIdle and currentTracks.ClimbIdle.IsPlaying then
                    currentTracks.ClimbIdle:Stop()
                end
            end
        else
            local climbIdleTrack = currentTracks.ClimbIdle or currentTracks.Idle
            if climbIdleTrack then
                climbIdleTrack:Play()
                if currentTracks.Climb and currentTracks.Climb.IsPlaying then
                    currentTracks.Climb:Stop()
                end
            end
        end
    end))
    table.insert(currentConnections, humanoid.Died:Connect(function()
        local deathTrack = currentTracks.Death or currentTracks.Idle
        if deathTrack then
            deathTrack:Play()
            for animType, track in pairs(currentTracks) do
                if animType ~= "Death" and track and track.IsPlaying then
                    track:Stop()
                end
            end
        end
    end))
    if currentTracks.Idle then
        currentTracks.Idle:Play()
    end
end

function AnimationOverride.Clear()
    clearCurrentAnimations()
end

localPlayer.CharacterAdded:Connect(function()
    clearCurrentAnimations()
end)

return AnimationOverride
