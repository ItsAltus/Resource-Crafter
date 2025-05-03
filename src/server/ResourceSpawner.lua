-- ============================================================
-- Script Name: ResourceSpawner.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Handles weighted random generation and safe spatial spawning of
--              resource nodes in the world, enforcing minimum separation between
--              nodes, ensuring they spawn on land no matter the height, and
--              tagging them for later.
-- ============================================================

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// MODULES
local Resources = require(ReplicatedStorage.ResourceCrafterShared.Resources)

--// CONSTANTS
local SPAWN_FOLDER = workspace:FindFirstChild("ResourceNodes") or Instance.new("Folder", workspace)
SPAWN_FOLDER.Name = "ResourceNodes"

local R_MIN, R_MAX = 15, 1000 -- radial spawn range
local MIN_SEP = 10 -- minimum distance between nodes

--// RANDOM GENERATOR
local random = Random.new()

-- ============================================================
--// PRIVATE FUNCTIONS
-- ============================================================

--[[
Function: weightedChoose
Description: Selects a resource from the Resources module based on weighted
             probability.
Returns:
    - (table) - A resource entry from the Resources module.
]]
local function weightedChoose()
	local roll, cumulative = random:NextNumber(), 0
	for _, data in pairs(Resources) do
		cumulative += data.weight or 1
		if roll <= cumulative then
			return data
		end
	end
	return Resources.tree -- fallback if something goes wrong
end

--[[
Function: spawnResource
Description: Spawns a resource node model into the world using a radial distance and
             collision-avoiding placement algorithm. Sets attributes required for
             gameplay interaction and tags the object for CollectionService usage.
Parameters:
    - <data> (table) - A resource definition from Resources, must include:
        - id (string)
        - model (string)
        - durability (number)
        - requiredToolPower (number)
Returns:
    - None
Notes:
    - If a valid model is not found for the resource, it logs a warning and skips spawn.
]]
local function spawnResource(data)
	local modelTemplate = ReplicatedStorage.ResourceCrafterShared.ResourceModels:FindFirstChild(data.model)
	if not modelTemplate then warn("Missing model for "..data.id); return end

	local model = modelTemplate:Clone()
	model:SetAttribute("ResourceId", data.id)
	model:SetAttribute("Durability", data.durability)
    model:SetAttribute("RequiredToolPower", data.requiredToolPower)

    local size = model:GetExtentsSize()
    local selfRad = math.max(size.X, size.Z) / 2

    local pos
    repeat
        local angle = random:NextNumber() * math.pi * 2
	    local dist = random:NextNumber(R_MIN, R_MAX)
	    local x, z = math.cos(angle) * dist, math.sin(angle) * dist

	    local ray = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -200, 0)) -- for checking if model spawned on the ground
        if ray then
            pos = Vector3.new(x, ray.Position.Y + size.Y/2, z) -- y calculation ensures model is centered on the detected surface, not sunk into it
        else
            pos = Vector3.new(x, 5, z)
        end

        local tooClose = false
        for _, child in ipairs(SPAWN_FOLDER:GetChildren()) do
            local childPosition = child:GetPivot().Position
            local childSize = child:GetExtentsSize()
            local childRad = math.max(childSize.X, childSize.Z) / 2

            if (childPosition - pos).Magnitude < (selfRad + childRad + MIN_SEP) then
                tooClose = true
                break
            end
        end

    until not tooClose

    model.Parent = SPAWN_FOLDER
    model:PivotTo(CFrame.new(pos))
	CollectionService:AddTag(model, "ResourceNode")
end

-- ============================================================
--// MODULE DEFINITION
-- ============================================================

local ResourceSpawner = {}

-- Clears all current nodes and generates 350 new nodes using weighted random selection.
function ResourceSpawner.RespawnAll()
	SPAWN_FOLDER:ClearAllChildren()
	for _ = 1, 350 do
		spawnResource(weightedChoose())
	end
end

-- manual spawning method
ResourceSpawner.SpawnResource = spawnResource

--// RETURN MODULE
return ResourceSpawner
