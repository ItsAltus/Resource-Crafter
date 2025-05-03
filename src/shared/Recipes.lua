-- ============================================================
-- Script Name: Recipes.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Table containing all craftable recipes that
--				players can make in the game.
-- ============================================================

local Recipes = {
    {
        outputId = "wooden_axe",
        shape = {
            nil,   "wood",  "wood",
            nil,   "wood",  "wood",
            nil,   "stone", nil,
        },
        ingredients = { wood = 4, stone = 1 },
    },
    {
        outputId = "wooden_axe",  -- alternative axe shape, crafts same tool
        shape = {
            "wood","wood",  nil,
            "wood","wood",  nil,
            nil,   "stone", nil,
        },
        ingredients = { wood = 4, stone = 1 },
    },
    {
        outputId = "stone_pickaxe",
        shape = {
            "stone",   "stone",  "stone",
              nil,      "wood",    nil,
              nil,      "wood",    nil,
        },
        ingredients = { wood = 2, stone = 3 },
    },
}

return Recipes
