local Resources = {
	tree = {
		id = "tree",
		model = "TreeModel",
		requiredToolPower = 1,
		drops = { {itemId = "wood", amount = 3} },
		durability = 16,
		weight = 0.5,
		respawnTime = 30,
	},
	rock = {
		id = "rock",
		model = "RockModel",
		requiredToolPower = 15,
		drops = { {itemId = "stone", amount = 3} },
		durability = 20,
		weight = 0.16,
		respawnTime = 60,
	},
    pebble = {
		id = "pebble",
		model = "PebbleModel",
		requiredToolPower = 0,
		drops = { {itemId = "stone", amount = 1} },
		durability = 0,
		weight = 0.34,
		respawnTime = 45,
	},
}

return Resources
