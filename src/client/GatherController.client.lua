local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HOVER_RANGE = 6

local RequestGather = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("RequestGather")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local swingAnim = Instance.new("Animation")
swingAnim.Name = "GatherSwing"
swingAnim.AnimationId = "rbxassetid://132929764470013"

local function getAnimator(humanoid)
    local a = humanoid:FindFirstChildOfClass("Animator")
    if not a then
        a = Instance.new("Animator")
        a.Parent = humanoid
    end
    return a
end

player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    local animator = getAnimator(humanoid)

    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                local track = animator:LoadAnimation(swingAnim)
                track.Priority = Enum.AnimationPriority.Action
                track:Play()
            end)
        end
    end)
end)

mouse.Button1Down:Connect(function()
    local unitRay = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {player.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local ray = workspace:Raycast(unitRay.Origin, unitRay.Direction * 256, params)
    if ray and ray.Instance and ray.Instance:FindFirstAncestorOfClass("Model") then
        local node = ray.Instance:FindFirstAncestorOfClass("Model")
        if node:GetAttribute("ResourceId") then
            RequestGather:FireServer(node)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local target = mouse.Target
    local model = target and target:FindFirstAncestorOfClass("Model")
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if model and hrp then
        local resourceId = model:GetAttribute("ResourceId")
        local nodePosition = model:GetPivot().Position
        local distance = (hrp.Position - nodePosition).Magnitude

        if resourceId == "pebble" and distance <= HOVER_RANGE then
            mouse.Icon = "rbxassetid://109156007581346"
            return
        end
    end

    mouse.Icon = "rbxassetid://93413280623076"
end)
