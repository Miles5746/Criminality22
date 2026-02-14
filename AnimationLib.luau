local AnimationOverride = {}
local currentTracks = {}
local currentConnections = {}
local defaultWalkSpeed = 16
local localPlayer = game:GetService("Players").LocalPlayer
local currentAnimations = {}
local isRunning = false
local isWalking = false

local function clearCurrentAnimations()
    for _, track in pairs(currentTracks) do
        if track and track.IsPlaying then
            track:Stop(0.1)
        end
    end
    for _, connection in pairs(currentConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    currentTracks = {}
    currentConnections = {}
    isRunning = false
    isWalking = false
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
    track.Looped = true
    return track
end

local function getCharacter()
    return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local function playAnimation(track, speed, fadeTime)
    if not track then return end
    fadeTime = fadeTime or 0.2
    if track.IsPlaying then
        track:AdjustSpeed(speed)
    else
        track:Play(fadeTime)
        track:AdjustSpeed(speed)
    end
end

local function stopAnimation(track, fadeTime)
    if track and track.IsPlaying then
        track:Stop(fadeTime or 0.2)
    end
end

function AnimationOverride.Apply(animations, customWalkSpeed)
    clearCurrentAnimations()
    defaultWalkSpeed = customWalkSpeed or 16
    local character = getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    -- Load all animations with fallbacks
    currentAnimations = {
        Idle = loadAnimation(animator, animations.Idle or "rbxassetid://507776043"),
        Walk = loadAnimation(animator, animations.Walk or animations.Idle or "rbxassetid://507776043"),
        Run = loadAnimation(animator, animations.Run or animations.Walk or animations.Idle or "rbxassetid://507776043"),
        Jump = loadAnimation(animator, animations.Jump or animations.Idle or "rbxassetid://507776043"),
        Fall = loadAnimation(animator, animations.Fall or animations.Idle or "rbxassetid://507776043"),
        Swim = loadAnimation(animator, animations.Swim or animations.Idle or "rbxassetid://507776043"),
        SwimIdle = loadAnimation(animator, animations.SwimIdle or animations.Swim or animations.Idle or "rbxassetid://507776043"),
        Climb = loadAnimation(animator, animations.Climb or animations.Idle or "rbxassetid://507776043"),
        ClimbIdle = loadAnimation(animator, animations.ClimbIdle or animations.Climb or animations.Idle or "rbxassetid://507776043"),
        Death = loadAnimation(animator, animations.Death or animations.Idle or "rbxassetid://507776043")
    }

    -- Set up connections with debounce
    local lastState = ""
    local lastSpeed = 0

    table.insert(currentConnections, humanoid.Running:Connect(function(speed)
        if speed > 0 then
            local shouldRun = humanoid.WalkSpeed > defaultWalkSpeed
            local currentState = shouldRun and "Run" or "Walk"

            -- Only change if state actually changed
            if currentState ~= lastState or math.abs(speed - lastSpeed) > 1 then
                lastState = currentState
                lastSpeed = speed

                -- Stop previous movement animations
                stopAnimation(currentAnimations.Walk, 0.1)
                stopAnimation(currentAnimations.Run, 0.1)

                -- Play appropriate animation
                if shouldRun then
                    isRunning = true
                    isWalking = false
                    playAnimation(currentAnimations.Run, speed/16, 0.1)
                else
                    isRunning = false
                    isWalking = true
                    playAnimation(currentAnimations.Walk, speed/16, 0.1)
                end
            else
                -- Just adjust speed if same animation
                if isRunning and currentAnimations.Run then
                    currentAnimations.Run:AdjustSpeed(speed/16)
                elseif isWalking and currentAnimations.Walk then
                    currentAnimations.Walk:AdjustSpeed(speed/16)
                end
            end
        else
            -- Stopped moving
            if lastState ~= "Idle" then
                lastState = "Idle"
                stopAnimation(currentAnimations.Walk, 0.1)
                stopAnimation(currentAnimations.Run, 0.1)
                playAnimation(currentAnimations.Idle, 1, 0.1)
                isRunning = false
                isWalking = false
            end
        end
    end))

    table.insert(currentConnections, humanoid.Jumping:Connect(function()
        if lastState ~= "Jump" then
            lastState = "Jump"
            stopAnimation(currentAnimations.Walk, 0.1)
            stopAnimation(currentAnimations.Run, 0.1)
            playAnimation(currentAnimations.Jump, 1, 0.1)
            isRunning = false
            isWalking = false
        end
    end))

    table.insert(currentConnections, humanoid.FreeFalling:Connect(function()
        if lastState ~= "Fall" then
            lastState = "Fall"
            stopAnimation(currentAnimations.Jump, 0.1)
            playAnimation(currentAnimations.Fall, 1, 0.1)
        end
    end))

    table.insert(currentConnections, humanoid.Swimming:Connect(function(speed)
        if speed > 0 then
            if lastState ~= "Swim" then
                lastState = "Swim"
                stopAnimation(currentAnimations.SwimIdle, 0.1)
                playAnimation(currentAnimations.Swim, speed/16, 0.1)
            else
                currentAnimations.Swim:AdjustSpeed(speed/16)
            end
        else
            if lastState ~= "SwimIdle" then
                lastState = "SwimIdle"
                stopAnimation(currentAnimations.Swim, 0.1)
                playAnimation(currentAnimations.SwimIdle, 1, 0.1)
            end
        end
    end))

    table.insert(currentConnections, humanoid.Climbing:Connect(function(speed)
        if speed > 0 then
            if lastState ~= "Climb" then
                lastState = "Climb"
                stopAnimation(currentAnimations.ClimbIdle, 0.1)
                playAnimation(currentAnimations.Climb, speed/16, 0.1)
            else
                currentAnimations.Climb:AdjustSpeed(speed/16)
            end
        else
            if lastState ~= "ClimbIdle" then
                lastState = "ClimbIdle"
                stopAnimation(currentAnimations.Climb, 0.1)
                playAnimation(currentAnimations.ClimbIdle, 1, 0.1)
            end
        end
    end))

    table.insert(currentConnections, humanoid.Died:Connect(function()
        if lastState ~= "Death" then
            lastState = "Death"
            for animType, track in pairs(currentAnimations) do
                if animType ~= "Death" and track and track.IsPlaying then
                    stopAnimation(track, 0.1)
                end
            end
            playAnimation(currentAnimations.Death, 1, 0.1)
        end
    end))

    -- Play idle animation immediately
    playAnimation(currentAnimations.Idle, 1, 0.1)
end

function AnimationOverride.Clear()
    clearCurrentAnimations()
end

localPlayer.CharacterAdded:Connect(function()
    clearCurrentAnimations()
end)

return AnimationOverride
