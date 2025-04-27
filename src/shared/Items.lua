--!strict
export type Item = {
	id: string,
	name: string,
	icon: string,
	maxStack: number,
	toolPower: number?,
}

local Items: {[string]: Item} = {
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
        icon = "rbxassetid://0",
        maxStack = 99
    },
	stone_pickaxe = {
        id="stone_pickaxe",
        name="Stone Pickaxe",
        icon="rbxassetid://0",
        maxStack=1,
        toolPower=2
    },
}

return Items
