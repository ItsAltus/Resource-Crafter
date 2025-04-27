--!strict
local Resources = {
	tree = {
		id = "tree",
		model = "TreeModel",          -- child of ReplicatedStorage.ResourceModels
		requiredToolPower = 1,
		drops = { {itemId = "wood", amount = 3} },
		durability = 3,
		weight = 0.6,
		respawnTime = 30,             -- seconds
	},
	stone = {
		id = "stone",
		model = "StoneModel",
		requiredToolPower = 2,
		drops = { {itemId = "stone", amount = 3} },
		durability = 4,
		weight = 0.25,
		respawnTime = 45,
	},
    pebble = {
		id = "pebble",
		model = "PebbleModel",
		requiredToolPower = 0,
		drops = { {itemId = "stone", amount = 1} },
		durability = 1,
		weight = 0.15,
		respawnTime = 45,
	},
}

return Resources
