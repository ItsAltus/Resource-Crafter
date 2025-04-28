--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RCS = ReplicatedStorage:WaitForChild("ResourceCrafterShared")
local RemoteEvents = RCS:WaitForChild("RemoteEvents")
local RequestEquip = RemoteEvents:WaitForChild("RequestEquip")
local ToolModels = RCS:WaitForChild("ToolModels")

local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local Items = require(RCS:WaitForChild("Items"))

local function onEquip(player: Player, itemId: string)
    local inv = InventoryService.GetInventory(player)
    if not inv[itemId] or inv[itemId] <= 0 then return end

    -- clear any old tools
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolPower") then
            tool:Destroy()
        end
    end
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolPower") then
            tool:Destroy()
        end
    end

    -- clone from ResourceCrafterShared.ToolModels
    local tmpl = ToolModels:FindFirstChild(itemId)
    if not tmpl then
        warn("EquipService: missing ToolModels/"..itemId)
        return
    end

    local tool = tmpl:Clone()
    tool:SetAttribute("ToolPower", Items[itemId].toolPower or 0)
    tool.Parent = player.Backpack
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(tool)
    end
end

RequestEquip.OnServerEvent:Connect(onEquip)
