-- ============================================================
-- Script Name: CraftingService.server.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Handles crafting requests from players. Verifies that the player
--              has enough ingredients in their inventory based on the Recipes module,
--              subtracts the required items, and adds the crafted item to their inventory.
-- ============================================================

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// SHARED MODULES
local RCS = ReplicatedStorage:WaitForChild("ResourceCrafterShared")
local Remotes = RCS:WaitForChild("RemoteEvents")
local RequestCraft = Remotes:WaitForChild("RequestCraft")

local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local Recipes = require(RCS:WaitForChild("Recipes"))

-- ============================================================
--// CRAFTING HANDLER
-- ============================================================

--[[
Function: RequestCraft.OnServerEvent
Description: Handles a player's request to craft an item after clicking the craft button.
             Looks up the recipe by outputId, checks that the player has all required
             ingredients, subtracts them, and adds the crafted item to their inventory.
Parameters:
    - <player> (Player) - The player attempting to craft.
    - <outputId> (string) - The ID of the item the player wants to craft.
Returns:
    - None
]]
RequestCraft.OnServerEvent:Connect(function(player, outputId)
    -- look up recipe for the requested outputId
    local recipe
    for _, r in ipairs(Recipes) do
        if r.outputId == outputId then recipe = r; break end
    end
    if not recipe then return end -- invalid recipe ID

    -- check that player has all required ingredients
    local inv = InventoryService.GetInventory(player)
    for itemId, needed in pairs(recipe.ingredients) do
        if (inv[itemId] or 0) < needed then
            return -- not enough of a required ingredient
        end
    end

    -- subtract ingredients from inventory (addItem with a negative amount)
    for itemId, needed in pairs(recipe.ingredients) do
        InventoryService.AddItem(player, itemId, -needed)
    end

    -- grant crafted item
    InventoryService.AddItem(player, recipe.outputId, 1)
end)
