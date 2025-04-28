--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ResourceSpawner = require(script.Parent:WaitForChild("ResourceSpawner"))
local Resources = require(ReplicatedStorage.ResourceCrafterShared.Resources)

local RequestGather = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("RequestGather")

local GATHER_RANGE = 6

local function onGather(player, node)
    if not node:IsDescendantOf(workspace.ResourceNodes) then return end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local nodePosition = node:GetPivot().Position
    local dx = hrp.Position.X - nodePosition.X
    local dz = hrp.Position.Z - nodePosition.Z
    if math.sqrt(dx*dx + dz*dz) > GATHER_RANGE then
        return
    end

    local id = node:GetAttribute("ResourceId")
    local data = Resources[id]
    if not data then return end

    if data.requiredToolPower > 0 then
        local tool = player.Character:FindFirstChildOfClass("Tool")
        local toolPower = tool and tool:GetAttribute("ToolPower") or 0
        if toolPower < data.requiredToolPower then return end
    end

    -- decrement durability
    local durability = node:GetAttribute("Durability") or 0
    durability -= 1
    node:SetAttribute("Durability", durability)

    if durability <= 0 then
        -- award drops (stub: print; swap for InventoryService later)
        local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
        for _, drop in ipairs(data.drops) do
            InventoryService.AddItem(player, drop.itemId, drop.amount)
        end

        -- remove node and respawn just this one
        node:Destroy()
        task.delay(data.respawnTime, function()
            ResourceSpawner.SpawnResource(data)
        end)
    end
end

RequestGather.OnServerEvent:Connect(onGather)
