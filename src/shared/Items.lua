-- ============================================================
-- Script Name: Items.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Table containing all acquirable items that
--				in the game.
-- ============================================================

local Items = {
	wooden_axe = {
        id = "wooden_axe",
        name = "Wooden Axe",
        icon = "rbxassetid://106664449675720",
        maxStack = 1,
        toolPower = 5
    },
	wood = {
        id = "wood",
        name = "Wood",
        icon = "rbxassetid://90866279893538",
        maxStack = 99,
        toolPower = 0
    },
    stone = {
        id = "stone",
        name = "Stone",
        icon = "rbxassetid://97210443305959",
        maxStack = 99,
        toolPower = 1
    },
	stone_pickaxe = {
        id = "stone_pickaxe",
        name = "Stone Pickaxe",
        icon = "rbxassetid://125416476621162",
        maxStack = 1,
        toolPower = 15
    },
}

return Items
