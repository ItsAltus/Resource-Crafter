-- ============================================================
-- Script Name: InventoryService.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Handles per-player inventory management. Includes item tracking,
--              amount updates, player cleanup, and replication
--              to clients through a remote event.
-- ============================================================

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// REMOTES
local InventoryUpdated = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("InventoryUpdated")

--// INTERNAL STORAGE
local playerInventory = {}

-- ============================================================
--// PUBLIC METHODS
-- ============================================================

local InventoryService = {}

--[[
Function: AddItem
Description: Adds a specified number of an item to the player’s inventory. If the player
             doesn’t have an inventory table, one is created and cleaned up upon leave.
Parameters:
    - <player> (Player) - The player to receive the item.
    - <itemId> (string) - The string identifier of the item.
    - <amount> (number) - The quantity to add (can be negative to subtract).
Returns:
    - None
Notes:
    - Triggers the InventoryUpdated RemoteEvent to sync the updated inventory to the client.
    - Automatically tracks disconnects via AncestryChanged to avoid memory leaks.
]]
function InventoryService.AddItem(player, itemId, amount)
    local inv = playerInventory[player]
    if not inv then
        inv = {}
        playerInventory[player] = inv

        -- clean up when the player leaves
        player.AncestryChanged:Connect(function(_, parent)
            if not parent then playerInventory[player] = nil end
        end)
    end

    inv[itemId] = (inv[itemId] or 0) + amount
    InventoryUpdated:FireClient(player, inv)
end

--[[
Function: GetInventory
Description: Retrieves the current inventory table for a player. If the player has not yet
             been assigned an inventory, returns an empty table.
Parameters:
    - <player> (Player) - The player whose inventory is being retrieved.
Returns:
    - (Inventory) - A table mapping item IDs to their respective quantities.
]]
function InventoryService.GetInventory(player)
    return playerInventory[player] or {}
end

--// RETURN MODULE
return InventoryService
