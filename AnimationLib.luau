local AnimationLib = {}

AnimationLib.Defaults = {
    Speed = 1,
    StartTime = 0,
    EndTime = nil,
    Priority = Enum.AnimationPriority.Action
}

AnimationLib.PackDefaults = {
    Speed = 1,
    Priority = Enum.AnimationPriority.Movement,
    FadeTime = 0.15,
    WalkSpeedThreshold = 16  -- Default threshold for walk/run transition
}

local function anim2track(asset_id)
    if typeof(asset_id) == "Instance" and asset_id:IsA("Animation") then
        return asset_id.AnimationId
    end

    local objs
    if tostring(asset_id):find("rbxassetid://") then
        objs = game:GetObjects(asset_id)
    else
        objs = game:GetObjects("rbxassetid://" .. asset_id)
    end

    for i = 1, #objs do
        if objs[i]:IsA("Animation") then
            return objs[i].AnimationId
        end
    end
    return "rbxassetid://" .. tostring(asset_id):match("%d+")
end

function AnimationLib.PlayAnim(animid, speed, startTime, endTime, priority)
    speed = speed or 1
    startTime = startTime or 0
    priority = priority or Enum.AnimationPriority.Core

    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    if not tostring(animid):find("rbxassetid://") then
        animid = "rbxassetid://" .. animid
    end

    animid = anim2track(animid)
    local animation = Instance.new("Animation")
    animation.AnimationId = animid

    local track = humanoid:LoadAnimation(animation)
    track.Priority = priority
    track:Play(0)
    track.TimePosition = startTime
    track:AdjustSpeed(speed)

    if endTime then
        task.spawn(function()
            while track.IsPlaying do
                if track.TimePosition >= endTime then
                    track:Stop()
                    break
                end
                task.wait()
            end
        end)
    end

    return track
end

function AnimationLib.PlayPack(walkSpeedThreshold, idle, walk, run, jump, fall, climb)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Set default threshold if not provided
    walkSpeedThreshold = walkSpeedThreshold or AnimationLib.PackDefaults.WalkSpeedThreshold

    -- Set default animations if not provided
    jump = jump or idle
    fall = fall or idle
    climb = climb or idle
    run = run or walk or idle
    walk = walk or idle

    local function load(animId)
        if not animId then return nil end

        if not tostring(animId):find("rbxassetid://") then
            animId = "rbxassetid://" .. animId
        end

        animId = anim2track(animId)
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        anim.Looped = true

        local track = humanoid:LoadAnimation(anim)
        track.Looped = true
        track.Priority = AnimationLib.PackDefaults.Priority
        return track
    end

    local tracks = {
        Idle = load(idle),
        Walk = load(walk),
        Run = load(run),
        Jump = load(jump),
        Fall = load(fall),
        Climb = load(climb)
    }

    local currentTrack = nil
    local currentState = "Idle"

    local function stopAll()
        for name, track in pairs(tracks) do
            if track and track.IsPlaying then
                track:Stop(AnimationLib.PackDefaults.FadeTime)
            end
        end
        currentTrack = nil
    end

    local function playTrack(track, speed)
        if not track then return end

        if currentTrack ~= track then
            stopAll()
            currentTrack = track
            track:Play(AnimationLib.PackDefaults.FadeTime)
        end

        track:AdjustSpeed(speed or 1)
    end

    -- Play idle immediately
    if tracks.Idle then
        playTrack(tracks.Idle, 1)
    end

    -- Movement handling
    local runningConn
    runningConn = humanoid.Running:Connect(function(speed)
        if speed > 0.1 then
            local shouldRun = humanoid.WalkSpeed > walkSpeedThreshold
            local newState = shouldRun and "Run" or "Walk"

            if newState ~= currentState then
                currentState = newState
                local track = tracks[newState]
                if track then
                    playTrack(track, speed / 16)
                end
            else
                -- Just adjust speed if same state
                if currentTrack then
                    currentTrack:AdjustSpeed(speed / 16)
                end
            end
        else
            if currentState ~= "Idle" then
                currentState = "Idle"
                if tracks.Idle then
                    playTrack(tracks.Idle, 1)
                end
            end
        end
    end)

    -- Jump handling
    local jumpingConn
    jumpingConn = humanoid.Jumping:Connect(function()
        if currentState ~= "Jump" then
            currentState = "Jump"
            if tracks.Jump then
                playTrack(tracks.Jump, 1)
            end
        end
    end)

    -- Fall handling
    local freeFallingConn
    freeFallingConn = humanoid.FreeFalling:Connect(function(active)
        if active and currentState ~= "Fall" then
            currentState = "Fall"
            if tracks.Fall then
                playTrack(tracks.Fall, 1)
            end
        end
    end)

    -- Climb handling
    local climbingConn
    climbingConn = humanoid.Climbing:Connect(function(speed)
        if speed ~= 0 and currentState ~= "Climb" then
            currentState = "Climb"
            if tracks.Climb then
                playTrack(tracks.Climb, speed / 16)
            end
        elseif speed == 0 and currentState == "Climb" then
            currentState = "Idle"
            if tracks.Idle then
                playTrack(tracks.Idle, 1)
            end
        end
    end)

    -- Character respawn handling
    local characterAddedConn
    characterAddedConn = player.CharacterAdded:Connect(function(newCharacter)
        if runningConn then runningConn:Disconnect() end
        if jumpingConn then jumpingConn:Disconnect() end
        if freeFallingConn then freeFallingConn:Disconnect() end
        if climbingConn then climbingConn:Disconnect() end
        if characterAddedConn then characterAddedConn:Disconnect() end

        -- Reapply animations to new character
        task.wait(1) -- Wait for character to fully load
        AnimationLib.PlayPack(walkSpeedThreshold, idle, walk, run, jump, fall, climb)
    end)

    -- Store connections for potential cleanup
    local connections = {
        runningConn,
        jumpingConn,
        freeFallingConn,
        climbingConn,
        characterAddedConn
    }

    return {
        Stop = function()
            stopAll()
            for _, conn in ipairs(connections) do
                if conn and conn.Connected then
                    conn:Disconnect()
                end
            end
        end,
        SetWalkSpeedThreshold = function(newThreshold)
            walkSpeedThreshold = newThreshold
        end,
        GetCurrentState = function()
            return currentState
        end
    }
end

function AnimationLib.StopAll()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

return AnimationLib
