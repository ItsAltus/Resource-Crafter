-- ============================================================
-- Script Name: InitResources.server.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Initializes the resource spawning once upon server start.
-- ============================================================

local ResourceSpawner = require(script.Parent:WaitForChild("ResourceSpawner"))

-- call once on server boot to populate the map with resources
ResourceSpawner.RespawnAll()
