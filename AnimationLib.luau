local AnimationLib = {}

local DEFAULT_PRIORITY = Enum.AnimationPriority.Core
local DEFAULT_FADE_TIME = 0.2
local DEFAULT_SPEED = 1
local currentPlayingPack = nil

local function getCharacter()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    return localPlayer and localPlayer.Character or workspace:FindFirstChildOfClass("Model")
end

local function stopCurrentPack()
    if currentPlayingPack then
        currentPlayingPack.Stop()
        currentPlayingPack = nil
    end
end

function AnimationLib.PlaySeq(animationSequence, settings)
    stopCurrentPack()

    local character = getCharacter()
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    settings = settings or {}
    local currentTrack = nil
    local sequenceComplete = false
    local currentIndex = 1
    local tracks = {}

    for i, animData in ipairs(animationSequence) do
        local animId = typeof(animData) == "string" and animData or animData[1]
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://"..tostring(animId):match("%d+")

        local track = animator:LoadAnimation(animation)
        if track then
            track.Priority = settings.priority or DEFAULT_PRIORITY
            track:AdjustSpeed(settings.speed or DEFAULT_SPEED)

            tracks[i] = {
                track = track,
                startTime = typeof(animData) == "table" and animData[2] or 0,
                endTime = typeof(animData) == "table" and animData[3] or track.Length,
                speed = typeof(animData) == "table" and animData[4] or (settings.speed or DEFAULT_SPEED),
                priority = typeof(animData) == "table" and animData[5] or (settings.priority or DEFAULT_PRIORITY),
                fadeTime = typeof(animData) == "table" and animData[6] or (settings.fadeTime or DEFAULT_FADE_TIME)
            }
        end
    end

    if #tracks == 0 then return end

    local function playNext(index)
        if sequenceComplete or not tracks[index] then
            sequenceComplete = true
            currentPlayingPack = nil
            return
        end

        currentIndex = index
        local data = tracks[index]

        if currentTrack then
            currentTrack:Stop(data.fadeTime or 0)
        end

        currentTrack = data.track
        currentTrack.Priority = data.priority
        currentTrack:AdjustSpeed(data.speed)

        if data.startTime > 0 then
            currentTrack:Play(data.fadeTime, data.startTime)
        else
            currentTrack:Play(data.fadeTime)
        end

        local duration = (data.endTime - data.startTime) / data.speed

        if index < #tracks then
            task.delay(duration, function()
                if not sequenceComplete then
                    playNext(index + 1)
                end
            end)
        end
    end

    playNext(1)

    currentPlayingPack = {
        Stop = function()
            sequenceComplete = true
            if currentTrack then
                currentTrack:Stop()
            end
            currentPlayingPack = nil
        end,

        Pause = function()
            if currentTrack then
                currentTrack:AdjustSpeed(0)
            end
        end,

        Resume = function()
            if currentTrack then
                local data = tracks[currentIndex]
                currentTrack:AdjustSpeed(data.speed)
            end
        end,

        GetCurrentTrack = function()
            return currentTrack
        end,

        GetCurrentIndex = function()
            return currentIndex
        end
    }

    return currentPlayingPack
end

function AnimationLib.StopAll()
    local character = getCharacter()
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

function AnimationLib.FadeOutAll(fadeTime)
    fadeTime = fadeTime or 0.3
    local character = getCharacter()
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop(fadeTime)
    end
end

return AnimationLib
