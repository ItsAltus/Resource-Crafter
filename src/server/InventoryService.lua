local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryUpdated = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("InventoryUpdated")

type Inventory = {}
local playerInventory = {}

local InventoryService = {}

function InventoryService.AddItem(player: Player, itemId: string, amount: number)
    local inv = playerInventory[player]
    if not inv then
        inv = {}
        playerInventory[player] = inv
        player.AncestryChanged:Connect(function(_, parent)
            if not parent then playerInventory[player] = nil end
        end)
    end

    inv[itemId] = (inv[itemId] or 0) + amount
    InventoryUpdated:FireClient(player, inv)
end

function InventoryService.GetInventory(player: Player): Inventory
    return playerInventory[player] or {}
end

return InventoryService
