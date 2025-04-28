--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryUpdated = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("InventoryUpdated")

type Inventory = {}
local playerInventory = {}

local InventoryService = {}

-- Adds amount of itemId to player's bag, then notifies client
function InventoryService.AddItem(player: Player, itemId: string, amount: number)
    local inv = playerInventory[player]
    if not inv then
        inv = {}
        playerInventory[player] = inv
        -- when player leaves, clear their data
        player.AncestryChanged:Connect(function(_, parent)
            if not parent then playerInventory[player] = nil end
        end)
    end

    inv[itemId] = (inv[itemId] or 0) + amount
    -- send full inventory to client
    InventoryUpdated:FireClient(player, inv)
end

-- Optional helper for other server code
function InventoryService.GetInventory(player: Player): Inventory
    return playerInventory[player] or {}
end

return InventoryService
