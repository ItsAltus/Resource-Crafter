--!strict
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
