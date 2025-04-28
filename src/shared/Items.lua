--!strict
export type Item = {
	id: string,
	name: string,
	icon: string,
	maxStack: number,
	toolPower: number?,
}

local Items = {
	basic_axe = {
        id = "basic_axe",
        name = "Basic Axe",
        icon = "rbxassetid://0",
        maxStack = 1,
        toolPower = 1
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
        icon = "rbxassetid://0",
        maxStack = 1,
        toolPower = 2
    },
}

return Items
