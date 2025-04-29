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
        outputId = "wooden_axe",
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
