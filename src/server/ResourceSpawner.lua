local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Resources = require(ReplicatedStorage.ResourceCrafterShared.Resources)
local SPAWN_FOLDER = workspace:FindFirstChild("ResourceNodes") or Instance.new("Folder", workspace)
SPAWN_FOLDER.Name = "ResourceNodes"

local R_MIN, R_MAX = 15, 1000
local MIN_SEP = 10

local random = Random.new()

local function weightedChoose()
	local roll, cumulative = random:NextNumber(), 0
	for _, data in pairs(Resources) do
		cumulative += data.weight or 1
		if roll <= cumulative then
			return data
		end
	end
	return Resources.tree
end

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

	    local ray = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -200, 0))
        if ray then
            pos = Vector3.new(x, ray.Position.Y + size.Y/2, z)
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

local ResourceSpawner = {}

function ResourceSpawner.RespawnAll()
	SPAWN_FOLDER:ClearAllChildren()
	for _ = 1, 350 do
		spawnResource(weightedChoose())
	end
end

ResourceSpawner.SpawnResource = spawnResource

return ResourceSpawner
