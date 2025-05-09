# Resource Crafter

**Project:** Resource Crafter
**Author:** ItsAltus (GitHub) / DrChicken2424 (ROBLOX)

**Demo Place:** [Resource Crafter](https://www.roblox.com/games/71722005474604/Resource-Crafter)  

---

## Overview

**Resource Crafter** is a modular Roblox demo for spawning, gathering, and crafting resources in an open world. It provides:

* **Weighted random resource generation** across the map
* **Resource durability‑based gathering** with tool power requirements
* **Client–server inventory system** with real‑time UI updates
* **Drag‑and‑drop inventory & crafting GUI**
* **Hotbar equip/unequip** and **swing animations**

---

## Features

* **Procedural Resource Spawning**

  * `ResourceSpawner` places nodes at random radial distances with collision avoidance and respawn timers.
* **Gathering Mechanics**

  * Durable nodes that require a minimum tool power, breakable into drops, then respawn.
* **Inventory Management**

  * `InventoryService` tracks per‑player item counts, auto‑cleans on disconnect, and fires `InventoryUpdated` to clients.
* **Drag‑and‑Drop UI**

  * 30‑slot inventory, 3‑slot hotbar, 3×3 Minecraft-style crafting grid, with hover highlights and swap logic.
* **Crafting System**

  * `Recipes` define ingredient shapes; players place items in the grid, match a recipe, then craft.
* **Hotbar & Tool Equipping**

  * Equip one tool at a time via hotbar or keybind (1–3), with client swing animation on use.

---

## Project Structure

```
ServerScriptService/
├─ InitResources.server.lua        -- One‑time startup: populates map
├─ ResourceSpawner.lua             -- Weighted spawn & respawn logic
├─ InventoryService.lua            -- Server‐side inventory backend
├─ RequestGather.server.lua        -- Handles gather requests & durability
├─ EquipTool.server.lua            -- Toggles tool equip/unequip
└─ RequestCraft.server.lua         -- Verifies recipes, subtracts ingredients, grants output

StarterPlayerScripts/
├─ GatherController.client.lua     -- Raycast click & hover cursor for gathering
└─ InventoryUI.client.lua          -- Opens inventory, drag‑and‑drop & crafting GUI

ReplicatedStorage/
└─ ResourceCrafterShared/
   ├─ Resources.lua                -- Resource node metadata
   ├─ Items.lua                    -- Item metadata
   ├─ Recipes.lua                  -- Crafting recipes metadata
   └─ RemoteEvents/                
      ├─ RequestGather (RemoteEvent)  
      ├─ InventoryUpdated (RemoteEvent)  
      ├─ RequestEquip (RemoteEvent)  
      └─ RequestCraft (RemoteEvent)
```

---

## Usage

1. **Place Modules & Scripts**

   * Import all scripts into their respective Roblox services (ServerScriptService, StarterPlayerScripts, and ReplicatedStorage).
2. **Start Server**

   * `InitResources.server.lua` will call `ResourceSpawner.RespawnAll()` on boot to populate nodes.
3. **Gathering**

   * On the client, left‑click a resource node within range to send `RequestGather` to the server.
   * Server checks range, tool power, deducts durability, drops items via `InventoryService`, and respawns the node.
4. **Inventory & Hotbar**

   * Press **M** to toggle the inventory UI. Drag items between inventory, hotbar, and crafting grid.
   * Right‑click or press **1**, **2**, **3** on a hotbar slot to equip/unequip that tool.
5. **Crafting**

   * Place ingredients in the 3×3 grid; when they match a recipe in `Recipes.lua`, click **Craft** to consume ingredients and receive the output item.
6. **Extending**

   * Add new entries to **Resources.lua**, **Items.lua**, or **Recipes.lua** to introduce new materials, tools, or recipes.

---