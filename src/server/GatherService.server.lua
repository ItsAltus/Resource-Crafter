-- ============================================================
-- Script Name: GatherService.server.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Handles gather requests from clients, checks range and tool power,
--              applies durability damage to resource nodes, and distributes item drops.
--              Respawns resources after depletion using ResourceSpawner.
-- ============================================================

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ResourceSpawner = require(script.Parent:WaitForChild("ResourceSpawner"))
local Resources = require(ReplicatedStorage.ResourceCrafterShared.Resources)

--// REMOTES
local RequestGather = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("RequestGather")

--// CONSTANTS
local GATHER_RANGE = 6 -- max distance for gathering interaction

-- ============================================================
--// GATHERING HANDLER
-- ============================================================

--[[
Function: onGather
Description: Server-side handler for gather requests. Verifies the request,
             checks tool requirements and distance, applies damage, rewards items,
             and schedules respawn if the resource is depleted.
Parameters:
    - <player> (Player) - The player who initiated the request.
    - <node> (Model) - The resource node being gathered from.
Returns:
    - None
Notes:
    - Prevents gathering outside of range or without correct tool power.
    - Only applies damage if tool meets requiredToolPower (if specified).
    - Drops are defined per resource in Resources[id].drops.
]]
local function onGather(player, node)
    -- validate that the node is a valid spawn
    if not node:IsDescendantOf(workspace.ResourceNodes) then return end

    -- check if player is close enough (XZ only)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local nodePosition = node:GetPivot().Position
    local dx = hrp.Position.X - nodePosition.X
    local dz = hrp.Position.Z - nodePosition.Z
    if math.sqrt(dx*dx + dz*dz) > GATHER_RANGE then
        return
    end

    -- get resource data by ID
    local id = node:GetAttribute("ResourceId")
    local data = Resources[id]
    if not data then return end

    -- check for tool and its power
    local tool = player.Character:FindFirstChildOfClass("Tool")
    local toolPower = tool and tool:GetAttribute("ToolPower") or 0
    if data.requiredToolPower > 0 then -- (if not a pebble)
        if toolPower < data.requiredToolPower then return end -- if tool isn't powerful enough, animation plays but no damage done to node
    end

    -- apply damage to node durability
    local durability = node:GetAttribute("Durability") or 0
    durability -= toolPower
    node:SetAttribute("Durability", durability)

     -- handle destruction and drops
    if durability <= 0 then
        local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
        for _, drop in ipairs(data.drops) do
            InventoryService.AddItem(player, drop.itemId, drop.amount)
        end

        node:Destroy()

        -- respawn new resource node after its defined delay
        task.delay(data.respawnTime, function()
            ResourceSpawner.SpawnResource(data)
        end)
    end
end

--// CONNECTION
RequestGather.OnServerEvent:Connect(onGather)
