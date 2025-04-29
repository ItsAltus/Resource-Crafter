local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RCS = ReplicatedStorage:WaitForChild("ResourceCrafterShared")
local Remotes = RCS:WaitForChild("RemoteEvents")
local RequestCraft = Remotes:WaitForChild("RequestCraft")

local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local Recipes = require(RCS:WaitForChild("Recipes"))

RequestCraft.OnServerEvent:Connect(function(player, outputId)
    local recipe
    for _, r in ipairs(Recipes) do
        if r.outputId == outputId then recipe = r; break end
    end
    if not recipe then return end

    local inv = InventoryService.GetInventory(player)
    for itemId, needed in pairs(recipe.ingredients) do
        if (inv[itemId] or 0) < needed then
            return
        end
    end

    for itemId, needed in pairs(recipe.ingredients) do
        InventoryService.AddItem(player, itemId, -needed)
    end

    InventoryService.AddItem(player, recipe.outputId, 1)
end)
