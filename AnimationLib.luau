local AnimationOverride = {}
local localPlayer = game:GetService("Players").LocalPlayer
local currentAnimations = {}
local currentTracks = {}
local currentState = "Idle"
local defaultWalkSpeed = 16
local fadeTime = 0.2

local function clearAnimations()
    for _, track in pairs(currentTracks) do
        if track then
            track:Stop(fadeTime)
        end
    end
    currentTracks = {}
    currentState = "Idle"
end

local function getAnimationId(asset)
    if typeof(asset) == "Instance" and asset:IsA("Animation") then
        return asset.AnimationId
    elseif type(asset) == "string" and asset:match("rbxassetid://") then
        return asset
    else
        return "rbxassetid://"..tostring(asset)
    end
end

local function loadAnimation(animator, id)
    if not id then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = getAnimationId(id)
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Core
    track.Looped = true
    return track
end

local function playAnimation(track, speed)
    if not track then return end
    if not track.IsPlaying then
        track:Play(fadeTime)
    end
    track:AdjustSpeed(speed)
end

local function stopAnimation(track)
    if track and track.IsPlaying then
        track:Stop(fadeTime)
    end
end

local function getCharacter()
    return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

function AnimationOverride.Apply(animations, customWalkSpeed)
    clearAnimations()
    defaultWalkSpeed = customWalkSpeed or 16

    local character = getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    -- Load animations with fallbacks
    currentAnimations = {
        Idle = loadAnimation(animator, animations.Idle or "rbxassetid://507776043"),
        Walk = loadAnimation(animator, animations.Walk or animations.Idle or "rbxassetid://507776043"),
        Run = loadAnimation(animator, animations.Run or animations.Walk or animations.Idle or "rbxassetid://507776043"),
        Jump = loadAnimation(animator, animations.Jump or animations.Idle or "rbxassetid://507776043"),
        Fall = loadAnimation(animator, animations.Fall or animations.Idle or "rbxassetid://507776043")
    }

    -- Set up state connections
    local runningConn = humanoid.Running:Connect(function(speed)
        if speed > 0 then
            local shouldRun = humanoid.WalkSpeed > defaultWalkSpeed
            local newState = shouldRun and "Run" or "Walk"

            if newState ~= currentState then
                -- Stop previous movement animations
                stopAnimation(currentTracks[currentState])

                -- Play new animation
                currentState = newState
                playAnimation(currentAnimations[newState], speed/16)
                currentTracks[currentState] = currentAnimations[newState]
            else
                -- Just adjust speed if same animation
                if currentTracks[currentState] then
                    currentTracks[currentState]:AdjustSpeed(speed/16)
                end
            end
        else
            if currentState ~= "Idle" then
                stopAnimation(currentTracks[currentState])
                currentState = "Idle"
                playAnimation(currentAnimations.Idle, 1)
                currentTracks.Idle = currentAnimations.Idle
            end
        end
    end)

    local jumpingConn = humanoid.Jumping:Connect(function()
        if currentState ~= "Jump" then
            stopAnimation(currentTracks[currentState])
            currentState = "Jump"
            playAnimation(currentAnimations.Jump, 1)
            currentTracks.Jump = currentAnimations.Jump
        end
    end)

    local fallingConn = humanoid.FreeFalling:Connect(function()
        if currentState ~= "Fall" then
            stopAnimation(currentTracks[currentState])
            currentState = "Fall"
            playAnimation(currentAnimations.Fall, 1)
            currentTracks.Fall = currentAnimations.Fall
        end
    end)

    -- Store connections for cleanup
    table.insert(currentTracks, {runningConn, jumpingConn, fallingConn})

    -- Play idle immediately
    playAnimation(currentAnimations.Idle, 1)
    currentTracks.Idle = currentAnimations.Idle
end

function AnimationOverride.Clear()
    clearAnimations()
end

-- Handle character respawns
localPlayer.CharacterAdded:Connect(function()
    clearAnimations()
end)

return AnimationOverride
