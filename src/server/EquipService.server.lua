-- ============================================================
-- Script Name: EquipService.server.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Handles equipping and unequipping of tools based on inventory requests.
--              Ensures only one tool is active, cleans up existing tools, and validates
--              item requests via ToolModels and Items definitions.
-- ============================================================

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// SHARED MODULES & FOLDERS
local RCS = ReplicatedStorage:WaitForChild("ResourceCrafterShared")
local RemoteEvents = RCS:WaitForChild("RemoteEvents")
local RequestEquip = RemoteEvents:WaitForChild("RequestEquip")
local ToolModels = RCS:WaitForChild("ToolModels")
local Items = require(RCS:WaitForChild("Items"))

-- ============================================================
--// EQUIP HANDLER
-- ============================================================

--[[
Function: onEquip
Description: Responds to equip requests from the client. If the requested tool is already
             equipped, it is unequipped (toggled off). Otherwise, it removes any existing
             equipped or carried tool and equips the requested one if valid.
Parameters:
    - <player> (Player) - The player requesting the equip.
    - <itemId> (string) - The ID of the item to equip (must match a ToolModel name).
Returns:
    - None
Notes:
    - The tool's power is looked up from the Items module and assigned as an attribute.
    - Both character and backpack are cleared of previous tools with ToolPower attributes.
]]
local function onEquip(player, itemId)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- if the tool is already equipped, toggle it off
    local equipped = character:FindFirstChild(itemId)
    if equipped and equipped:IsA("Tool") then
        equipped:Destroy()
        return
    end

    -- clean up any previously equipped tools in backpack or character
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

    -- validate and clone the new tool
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

--// CONNECTION
RequestEquip.OnServerEvent:Connect(onEquip)
