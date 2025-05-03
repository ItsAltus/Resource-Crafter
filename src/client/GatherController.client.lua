-- ============================================================
-- Script Name: GatherController.client.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Client‐side logic for gathering resources:
--              * Plays swing animation on tool activation
--              * Detects left‐click on resource nodes via raycast and fires server event
--              * Changes mouse cursor when hovering over gatherable nodes within range
-- ============================================================

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONSTANTS
local HOVER_RANGE = 6 -- studs within for hover icon activated

--// REMOTES
local RequestGather = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("RequestGather")

--// LOCAL REFERENCES
local player = Players.LocalPlayer
local mouse = player:GetMouse()

--// ANIMATION ASSET
local swingAnim = Instance.new("Animation")
swingAnim.Name = "GatherSwing"
swingAnim.AnimationId = "rbxassetid://132929764470013"

-- ============================================================
--// PRIVATE FUNCTIONS
-- ============================================================

--[[
Function: getAnimator
Description: Ensures a Humanoid has an Animator child, returning it.
Parameters:
    - <humanoid> (Humanoid) - The humanoid to retrieve or create an Animator for.
Returns:
    - (Animator) - The existing or newly created Animator instance.
]]
local function getAnimator(humanoid)
    local a = humanoid:FindFirstChildOfClass("Animator")
    if not a then
        a = Instance.new("Animator")
        a.Parent = humanoid
    end
    return a
end

-- ============================================================
--// CHARACTER AND TOOL SETUP
-- ============================================================

player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    local animator = getAnimator(humanoid)

    -- play swing animation whenever the equipped tool is activated
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

-- ============================================================
--// MOUSE CLICK HANDLER
-- ============================================================

--[[
Function: onClick
Description: Raycasts from the camera through the mouse position to detect a resource node.
             If a valid node is clicked, fires the RequestGather event to the server.
Parameters:
    - None (uses `mouse` and `workspace.CurrentCamera`)
Returns:
    - None
]]
mouse.Button1Down:Connect(function()
    -- construct a ray from the camera through the mouse
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

-- ============================================================
--// HOVER CURSOR UPDATER
-- ============================================================

--[[
Function: updateCursor
Description: Changes the mouse icon based on whether the player is pointing at a
             pebble node within HOVER_RANGE.
Parameters:
    - None (called every RenderStepped)
Returns:
    - None
]]
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

    -- default cursor if not hovering a pebble
    mouse.Icon = "rbxassetid://93413280623076"
end)
