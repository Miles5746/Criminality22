local AnimationOverride = {}
local currentCharacter = nil
local currentTracks = {}
local currentConnections = {}

local function clearCurrentAnimations()
    if currentCharacter then
        local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
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
    local resolvedId = anim2track(id)
    local anim = Instance.new("Animation")
    anim.AnimationId = resolvedId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Core
    return track
end

function AnimationOverride.Apply(character, animations)
    clearCurrentAnimations()
    currentCharacter = character

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    -- Load all animations
    for animType, id in pairs(animations) do
        currentTracks[animType] = loadAnimation(animator, id)
    end

    -- Set up connections
    table.insert(currentConnections, humanoid.Running:Connect(function(speed)
        if currentTracks.Run and speed > 12 then
            currentTracks.Run:Play()
            currentTracks.Run:AdjustSpeed(speed/16)
            if currentTracks.Walk and currentTracks.Walk.IsPlaying then
                currentTracks.Walk:Stop()
            end
        elseif currentTracks.Walk and speed > 0 then
            currentTracks.Walk:Play()
            currentTracks.Walk:AdjustSpeed(speed/16)
            if currentTracks.Run and currentTracks.Run.IsPlaying then
                currentTracks.Run:Stop()
            end
        elseif currentTracks.Idle and speed <= 0 then
            currentTracks.Idle:Play()
            if currentTracks.Walk and currentTracks.Walk.IsPlaying then
                currentTracks.Walk:Stop()
            end
            if currentTracks.Run and currentTracks.Run.IsPlaying then
                currentTracks.Run:Stop()
            end
        end
    end))

    table.insert(currentConnections, humanoid.Jumping:Connect(function()
        if currentTracks.Jump then
            currentTracks.Jump:Play()
            if currentTracks.Run and currentTracks.Run.IsPlaying then
                currentTracks.Run:Stop()
            end
            if currentTracks.Walk and currentTracks.Walk.IsPlaying then
                currentTracks.Walk:Stop()
            end
        end
    end))

    table.insert(currentConnections, humanoid.FreeFalling:Connect(function()
        if currentTracks.Fall then
            currentTracks.Fall:Play()
            if currentTracks.Jump and currentTracks.Jump.IsPlaying then
                currentTracks.Jump:Stop()
            end
        end
    end))

    table.insert(currentConnections, humanoid.Swimming:Connect(function(speed)
        if speed > 0 then
            if currentTracks.Swim then
                currentTracks.Swim:Play()
                currentTracks.Swim:AdjustSpeed(speed/16)
                if currentTracks.SwimIdle and currentTracks.SwimIdle.IsPlaying then
                    currentTracks.SwimIdle:Stop()
                end
            end
        else
            if currentTracks.SwimIdle then
                currentTracks.SwimIdle:Play()
                if currentTracks.Swim and currentTracks.Swim.IsPlaying then
                    currentTracks.Swim:Stop()
                end
            end
        end
    end))

    table.insert(currentConnections, humanoid.Climbing:Connect(function(speed)
        if speed > 0 then
            if currentTracks.Climb then
                currentTracks.Climb:Play()
                currentTracks.Climb:AdjustSpeed(speed/16)
                if currentTracks.ClimbIdle and currentTracks.ClimbIdle.IsPlaying then
                    currentTracks.ClimbIdle:Stop()
                end
            end
        else
            if currentTracks.ClimbIdle then
                currentTracks.ClimbIdle:Play()
                if currentTracks.Climb and currentTracks.Climb.IsPlaying then
                    currentTracks.Climb:Stop()
                end
            end
        end
    end))

    table.insert(currentConnections, humanoid.Died:Connect(function()
        if currentTracks.Death then
            currentTracks.Death:Play()
            for animType, track in pairs(currentTracks) do
                if animType ~= "Death" and track.IsPlaying then
                    track:Stop()
                end
            end
        end
    end))

    -- Play idle animation immediately
    if currentTracks.Idle then
        currentTracks.Idle:Play()
    end
end

function AnimationOverride.Clear()
    clearCurrentAnimations()
    currentCharacter = nil
end

return AnimationOverride
