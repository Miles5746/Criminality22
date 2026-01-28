local AnimationLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Miles5746/Criminality22/refs/heads/main/AnimationLib.luau"))()
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

AnimationLib.PlayPack("131482927380724", "139440238690196")

local walkflinging = false
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function startFling()
    if walkflinging then return end
    walkflinging = true

    local humanoid = Player.Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            walkflinging = false
        end)
    end

    coroutine.wrap(function()
        while walkflinging do
            local character = Player.Character
            local root = getRoot(character)

            while not (character and character.Parent and root and root.Parent) do
                RunService.Heartbeat:Wait()
                character = Player.Character
                root = getRoot(character)
            end

            local vel = root.Velocity
            local movel = 0.1

            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()

            if character and character.Parent and root and root.Parent then
                root.Velocity = vel
                RunService.Stepped:Wait()
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end

            RunService.Heartbeat:Wait()
        end
    end)()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.E then
        AnimationLib.StopAll()
        AnimationLib.PlayAnim("126475463257664")
        startFling()
        task.wait(1)
        walkflinging = false
    end
end)

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HRP = newChar:WaitForChild("HumanoidRootPart")
    walkflinging = false
end)
