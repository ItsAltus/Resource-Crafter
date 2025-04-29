local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RCS = ReplicatedStorage:WaitForChild("ResourceCrafterShared")
local RemoteEvents = RCS:WaitForChild("RemoteEvents")
local RequestEquip = RemoteEvents:WaitForChild("RequestEquip")
local ToolModels = RCS:WaitForChild("ToolModels")

local Items = require(RCS:WaitForChild("Items"))

local function onEquip(player, itemId)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local equipped = character:FindFirstChild(itemId)
    if equipped and equipped:IsA("Tool") then
        equipped:Destroy()
        return
    end

    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolPower") then
            tool:Destroy()
        end
    end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolPower") then
            tool:Destroy()
        end
    end

    local toolModel = ToolModels:FindFirstChild(itemId)
    if not toolModel then
        warn("EquipService: missing ToolModels/"..itemId)
        return
    end

    local tool = toolModel:Clone()
    tool.Name = itemId
    tool:SetAttribute("ToolPower", Items[itemId].toolPower or 0)
    tool.Parent = player.Backpack

    humanoid:EquipTool(tool)
end

RequestEquip.OnServerEvent:Connect(onEquip)
