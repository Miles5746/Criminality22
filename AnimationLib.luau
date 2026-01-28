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
    FadeTime = 0.15
}


local function anim2track(asset_id)
	local objs = game:GetObjects(asset_id)
	for i = 1, #objs do
		if objs[i]:IsA("Animation") then
			return objs[i].AnimationId
		end
	end
	return asset_id
end
function AnimationLib.PlayAnim(animid, speed, startTime, endTime, priority)
    speed = speed or 1
    startTime = startTime or 0
    priority = priority or Enum.AnimationPriority.Core
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    if not animid:find("rbxassetid://") then
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

function AnimationLib.PlaySeq(sequence)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    for _, data in ipairs(sequence) do
        local animId   = data[1]
        local speed    = data[2] ~= nil and data[2] or AnimationLib.Defaults.Speed
        local start    = data[3] ~= nil and data[3] or AnimationLib.Defaults.StartTime
        local finish   = data[4] ~= nil and data[4] or AnimationLib.Defaults.EndTime
        local priority = data[5] ~= nil and data[5] or AnimationLib.Defaults.Priority
        if not tostring(animId):find("rbxassetid://") then
            animId = "rbxassetid://" .. animId
        end
        animId = anim2track(animId)
        local animation = Instance.new("Animation")
        animation.AnimationId = animId
        local track = humanoid:LoadAnimation(animation)
        track.Priority = priority
        track:Play(0)
        track.TimePosition = start
        track:AdjustSpeed(speed)
        if finish then
            while track.IsPlaying and track.TimePosition < finish do
                task.wait()
            end
            track:Stop()
        else
            track.Stopped:Wait()
        end
    end
end

function AnimationLib.PlayPack(idle, walkRun, jump, fall, climb)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    jump  = jump  or idle
    fall  = fall  or idle
    climb = climb or idle
    local function load(animId)
        if not tostring(animId):find("rbxassetid://") then
            animId = "rbxassetid://" .. animId
        end
        animId = anim2track(animId)
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local track = humanoid:LoadAnimation(anim)
		track.Looped = true
        track.Priority = AnimationLib.PackDefaults.Priority
        return track
    end
    local tracks = {
        Idle = load(idle),
        WalkRun = load(walkRun),
        Jump = load(jump),
        Fall = load(fall),
        Climb = load(climb)
    }
    local function stopAll(except)
        for name, track in pairs(tracks) do
            if track ~= except then
                track:Stop(AnimationLib.PackDefaults.FadeTime)
            end
        end
    end
    tracks.Idle:Play(AnimationLib.PackDefaults.FadeTime)
    humanoid.Running:Connect(function(speed)
        if speed > 0.1 then
            if not tracks.WalkRun.IsPlaying then
                stopAll(tracks.WalkRun)
                tracks.WalkRun:Play(AnimationLib.PackDefaults.FadeTime)
                tracks.WalkRun:AdjustSpeed(AnimationLib.PackDefaults.Speed)
            end
        else
            if not tracks.Idle.IsPlaying then
                stopAll(tracks.Idle)
                tracks.Idle:Play(AnimationLib.PackDefaults.FadeTime)
            end
        end
    end)
    humanoid.Jumping:Connect(function()
        stopAll(tracks.Jump)
        tracks.Jump:Play(AnimationLib.PackDefaults.FadeTime)
    end)
    humanoid.FreeFalling:Connect(function(active)
        if active then
            stopAll(tracks.Fall)
            tracks.Fall:Play(AnimationLib.PackDefaults.FadeTime)
        end
    end)
    humanoid.Climbing:Connect(function(speed)
        if speed ~= 0 then
            stopAll(tracks.Climb)
            tracks.Climb:Play(AnimationLib.PackDefaults.FadeTime)
        end
    end)
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
