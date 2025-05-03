-- ============================================================
-- Script Name: InventoryUI.client.lua
-- Project: Resource Crafter
-- Author: ItsAltus (GitHub) / DrChicken2424 (Roblox)
-- Description: Manages the client‐side inventory and crafting UI:
--              * Inventory window toggling and rendering
--              * Hotbar rendering and equip indicators
--              * Drag‐and‐drop between inventory, hotbar, and crafting grid
--              * Crafting grid population, recipe matching, and output
--              * Communication with server via RemoteEvents
-- ============================================================

--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- disable default Roblox backpack UI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

--// SHARED REFERENCES
local RCS = ReplicatedStorage:WaitForChild("ResourceCrafterShared")
local InventoryUpdated = RCS.RemoteEvents:WaitForChild("InventoryUpdated")
local RequestEquip = RCS.RemoteEvents:WaitForChild("RequestEquip")
local RequestCraft = RCS.RemoteEvents:WaitForChild("RequestCraft")

local Items = require(RCS:WaitForChild("Items"))
local Recipes = require(RCS:WaitForChild("Recipes"))

--// LOCAL PLAYER & GUI REFERENCES
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
local invFrame = gui:WaitForChild("InventoryFrame")
local slotsFolder = invFrame:WaitForChild("Slots")
local hotbarFrame = gui:WaitForChild("HotbarFrame")
local openCraftBtn = invFrame:WaitForChild("OpenCraftButton")

local craftingGUI = player:WaitForChild("PlayerGui"):WaitForChild("CraftingUI")
local craftingFrame = craftingGUI:WaitForChild("CraftingFrame")
local craftGrid = craftingFrame:WaitForChild("CraftingGrid")
local outputSlot = craftingFrame:WaitForChild("OutputSlot")
local craftButton = craftingFrame:WaitForChild("CraftButton")

--// UI SLOTS ARRAYS
local invSlots = {}
for i = 1, 30 do
    invSlots[i] = slotsFolder:WaitForChild("Slot"..i)
end

local hotbarSlots = {}
for i = 1, 3 do
    hotbarSlots[i] = hotbarFrame:WaitForChild("HotbarSlot"..i)
end

local craftSlots = {}
for i = 1, 9 do
    craftSlots[i] = craftGrid:WaitForChild("CraftSlot"..i)
end

--// CONSTANTS
local HOTBAR_SLOT_NORMAL_SIZE = hotbarSlots[1].Size
local HOTBAR_SLOT_EQUIPPED_SIZE = UDim2.new(
    HOTBAR_SLOT_NORMAL_SIZE.X.Scale,
    math.floor(HOTBAR_SLOT_NORMAL_SIZE.X.Offset * 1.2),
    HOTBAR_SLOT_NORMAL_SIZE.Y.Scale,
    math.floor(HOTBAR_SLOT_NORMAL_SIZE.Y.Offset * 1.2)
)

local DEFAULT_SLOT_COLOR = Color3.fromRGB(40,40,40)
local HOVER_SLOT_COLOR = Color3.fromRGB(8,165,8)
local HOTBAR_HOVER_COLOR = Color3.fromRGB(100,100,255)
local CRAFT_HOVER_COLOR = Color3.fromRGB(165,  8,  8)

--// INTERNAL STATE
local slotOrder = {}
local workingInv = {}
local hotbarOrder = {nil, nil, nil}
local craftGridState = {}

local currentHoverInv, currentHoverHotbar, currentHoverCraft
local dragging = false
local dragSourceType = nil
local dragSourceIndex = 0
local dragOffset = Vector2.zero
local ghost, dragConn

-- initialize arrays
for i = 1, 30 do
    slotOrder[i] = nil
end
for i = 1, 9 do
    craftGridState[i] = nil
end

-- hide crafting UI initially
craftingFrame.Visible = false
invFrame.Visible = false
hotbarFrame.Visible = true

-- ============================================================
--// PRIVATE FUNCTIONS
-- ============================================================

--[[
Function: findMatchingRecipe
Description: Scans Recipes list for one whose shape exactly matches the provided
             craftGridState (array of up to 9 itemIds).
Parameters:
    - <state> ({ [number]: string? }) - craftGridState mapping slot -> itemId
Returns:
    - (table?) - the matching recipe or nil if none found
]]
local function findMatchingRecipe(state)
    for _, r in ipairs(Recipes) do
        local ok = true
        for i = 1, 9 do
            if state[i] ~= r.shape[i] then ok = false; break end
        end
        if ok then return r end
    end
    return nil
end

--[[
Function: updateSlotOrder
Description: Maintains slotOrder array so that each occupied inventory‐slot index
             points to an itemId. Removes IDs with zero count, and appends new IDs
             into first available slots.
Parameters:
    - <inv> ({ [string]: number }) - mapping itemId -> count
Returns:
    - None
]]
local function updateSlotOrder(inv)
    -- remove emptied slots
    for idx = 1, 30 do
        local id = slotOrder[idx]
        if id and (not inv[id] or inv[id] <= 0) then
            slotOrder[idx] = nil
        end
    end

    -- add new items to free slots
    for id, count in pairs(inv) do
        if count > 0 then
            local exists = false
            for idx = 1, 30 do
                if slotOrder[idx] == id then
                    exists = true
                    break
                end
            end

            if not exists then
                for idx = 1, 30 do
                    if slotOrder[idx] == nil then
                        slotOrder[idx] = id
                        break
                    end
                end
            end
        end
    end
end -- evil nesting

--[[
Function: renderInventory
Description: Updates all inventory UI slots to reflect slotOrder and workingInv.
Parameters:
    - <inv> ({ [string]: number }) - mapping itemId -> count
Returns:
    - None
]]
local function renderInventory(inv)
    for idx, slot in ipairs(invSlots) do
        local id = slotOrder[idx]
        local icon = slot:FindFirstChild("Icon")
        local countLabel = slot:FindFirstChild("Count")
        local count = (id and inv[id]) or 0

        if id and count > 0 then
            icon.Visible = true; icon.Image = Items[id].icon
            countLabel.Visible = true; countLabel.Text  = tostring(count)
        else
            icon.Visible = false; countLabel.Visible = false
        end

        slot.BackgroundColor3 = DEFAULT_SLOT_COLOR
        slot.Visible = true
    end
end

--[[
Function: renderHotbar
Description: Updates hotbar UI slots to reflect hotbarOrder.
Parameters:
    - None
Returns:
    - None
]]
local function renderHotbar()
    for idx, slot in ipairs(hotbarSlots) do
        local id = hotbarOrder[idx]
        local icon = slot:FindFirstChild("Icon")

        if id then
            icon.Visible = true
            icon.Image = Items[id].icon
        else
            icon.Visible = false
        end

        slot.BackgroundColor3 = DEFAULT_SLOT_COLOR
        slot.Visible = true
    end
end

--[[
Function: clearCraftGrid
Description: Resets visual state of all craftSlots and outputSlot.
Parameters:
    - None
Returns:
    - None
]]
local function clearCraftGrid()
    for _, slot in ipairs(craftSlots) do
        slot.Icon.Visible = false
        slot.Count.Visible = false
        slot.BackgroundColor3 = DEFAULT_SLOT_COLOR
    end
    outputSlot.Icon.Visible = false
end

--[[
Function: updateCraftingUI
Description: Renders the crafting grid based on craftGridState, shows matched
             recipe output if applicable, and enables/disables craftButton.
Parameters:
    - None
Returns:
    - None
]]
local function updateCraftingUI()
    clearCraftGrid()
    for i, slot in ipairs(craftSlots) do
        local id = craftGridState[i]
        if id then
            slot.Icon.Visible = true
            slot.Icon.Image = Items[id].icon
            slot.Count.Visible = true
            slot.Count.Text = "1"
        end
    end
    local rec = findMatchingRecipe(craftGridState)
    if rec then
        outputSlot.Icon.Visible = true
        outputSlot.Icon.Image = Items[rec.outputId].icon
        craftButton.Text = "Craft "..(Items[rec.outputId].name or rec.outputId)
        craftButton.AutoButtonColor = true
    else
        craftButton.AutoButtonColor = false
    end
    craftButton.Visible = true
end

--[[
Function: closeCrafting
Description: Closes craftingFrame. If <refund> is true, returns items from craftGridState
             back into workingInv and re-renders inventory.
Parameters:
    - <refund> (boolean) - whether to refund placed items on close
Returns:
    - None
]]
local function closeCrafting(refund)
    if craftingFrame.Visible then
        craftingFrame.Visible = false
        craftButton.Text = "Craft"
        if refund then
            for i = 1, 9 do
                local id = craftGridState[i]
                if id then
                    workingInv[id] = (workingInv[id] or 0) + 1
                end
                craftGridState[i] = nil
            end
            updateCraftingUI()
            updateSlotOrder(workingInv)
            renderInventory(workingInv)
        end
    end
end

--[[
Function: startDrag
Description: Initiates a drag‐and‐drop operation from an inventory, hotbar, or craft slot.
             Creates a ghost UI element and connects RenderStepped to follow mouse.
Parameters:
    - <slot> (GuiObject) - the UI slot that was clicked
    - <input> (InputObject) - the input event
Returns:
    - None
Notes:
    - Sets global dragSourceType/index for drop logic in InputEnded handler.
]]
local function startDrag(slot, input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    -- determine source type & index
    local inventoryIdx = table.find(invSlots, slot)
    local hotbarIdx = table.find(hotbarSlots, slot)
    local craftingIdx = table.find(craftSlots, slot)

    if inventoryIdx then
        if not slotOrder[inventoryIdx] then return end
        dragSourceType, dragSourceIndex = "inv", inventoryIdx
    elseif hotbarIdx then
        if not hotbarOrder[hotbarIdx] then return end
        dragSourceType, dragSourceIndex = "hotbar", hotbarIdx
    elseif craftingIdx then
        if not craftGridState[craftingIdx] then return end
        dragSourceType, dragSourceIndex = "craft", craftingIdx
    else
        return
    end

    dragging = true

    -- dim original
    slot.BackgroundTransparency = 0.5
    slot:FindFirstChild("Icon").ImageTransparency = 0.5
    if dragSourceType == "inv" or dragSourceType == "craft" then
        slot:FindFirstChild("Count").TextTransparency = 0.5
    end

    -- compute offset for smooth ghost movement
    local absPos = slot.AbsolutePosition
    dragOffset = Vector2.new(
        input.Position.X - absPos.X,
        input.Position.Y - absPos.Y
    )

    -- create ghost clone
    ghost = slot:Clone()
    ghost.Name = "DragGhost"
    ghost.Parent = craftingGUI
    ghost.ZIndex = 100
    ghost.Visible = true
    ghost.Position = UDim2.fromOffset(absPos.X, absPos.Y)

    -- update ghost each frame
    dragConn = RunService.RenderStepped:Connect(function()
        local mx,my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
        ghost.Position = UDim2.fromOffset(mx - dragOffset.X, my - dragOffset.Y)
    end)
end

--[[
Function: updateEquippedIndicator
Description: Adjusts hotbar slot sizes and stroke thickness to highlight currently
             equipped tool in Character.
Parameters:
    - None
Returns:
    - None
]]
local function updateEquippedIndicator()
    local character = player.Character
    if not character then return end
    local tool = character:FindFirstChildOfClass("Tool")
    local equippedId = tool and tool.Name

    for idx, slot in ipairs(hotbarSlots) do
        local id = hotbarOrder[idx]
        if id and id == equippedId then
            slot:TweenSize(HOTBAR_SLOT_EQUIPPED_SIZE,
                Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
                0.1, true)
            slot:WaitForChild("UIStroke").Thickness = 3
        else
            slot:TweenSize(HOTBAR_SLOT_NORMAL_SIZE,
                Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
                0.1, true)
            slot:WaitForChild("UIStroke").Thickness = 0
        end
    end
end

--[[
Function: onCharacter
Description: Connects to Character ChildAdded/Removed to update equip indicator when tools
             change in the world.
Parameters:
    - <char> (Model) - the new Character model
Returns:
    - None
]]
local function onCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child:GetAttribute("ToolPower") then
            updateEquippedIndicator()
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and child:GetAttribute("ToolPower") then
            updateEquippedIndicator()
        end
    end)
    updateEquippedIndicator()
end


-- ============================================================
--// INPUT & EVENT HANDLERS
-- ============================================================

-- toggle inventory on M key
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M then
        invFrame.Visible = not invFrame.Visible
        if craftingFrame.Visible then
            closeCrafting(true)
        end
    end
end)

player.CharacterAdded:Connect(onCharacter)
if player.Character then
    onCharacter(player.Character)
end

-- handle end of drag
UserInputService.InputEnded:Connect(function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 or not dragging then
        return
    end
    dragging = false
    if dragConn then dragConn:Disconnect(); dragConn = nil end
    if ghost then ghost:Destroy(); ghost = nil end

    -- restore original slot visuals
    local original
    if dragSourceType == "inv" then
        original = invSlots[dragSourceIndex]
    elseif dragSourceType == "hotbar" then
        original = hotbarSlots[dragSourceIndex]
    elseif dragSourceType == "craft" then
        original = craftSlots[dragSourceIndex]
    end

    if original then
        original.BackgroundTransparency = 0
        original:FindFirstChild("Icon").ImageTransparency = 0
        if dragSourceType == "inv" or dragSourceType == "craft" then
            original:FindFirstChild("Count").TextTransparency = 0
        end
    end

    -- DROP LOGIC based on source & hover targets
    if dragSourceType == "inv" then
        local id = slotOrder[dragSourceIndex]
        if currentHoverCraft then
            -- move into craft grid
            local slotIdx  = currentHoverCraft
            local prevId   = craftGridState[slotIdx]

            if prevId then
                workingInv[prevId] = (workingInv[prevId] or 0) + 1
            end

            if (workingInv[id] or 0) > 0 then
                workingInv[id] = workingInv[id] - 1
                craftGridState[slotIdx] = id
            end
            updateCraftingUI()
            updateSlotOrder(workingInv)
            renderInventory(workingInv)

        elseif currentHoverHotbar then
            -- assign to hotbar if empty
            if not hotbarOrder[currentHoverHotbar]
               and not table.find(hotbarOrder, id) then
                hotbarOrder[currentHoverHotbar] = id
                renderHotbar()
                updateEquippedIndicator()
            end

        elseif currentHoverInv and currentHoverInv ~= dragSourceIndex then
            -- swap inventory slots
            slotOrder[dragSourceIndex], slotOrder[currentHoverInv] =
                slotOrder[currentHoverInv], slotOrder[dragSourceIndex]
            renderInventory(workingInv)
        end

    elseif dragSourceType == "hotbar" then
        -- swap or clear hotbar slot
        if currentHoverHotbar and currentHoverHotbar ~= dragSourceIndex then
            hotbarOrder[dragSourceIndex], hotbarOrder[currentHoverHotbar] =
                hotbarOrder[currentHoverHotbar], hotbarOrder[dragSourceIndex]
        else
            hotbarOrder[dragSourceIndex] = nil
        end
        renderHotbar()
        updateEquippedIndicator()

    elseif dragSourceType == "craft" then
        local id = craftGridState[dragSourceIndex]
        if currentHoverInv then
            -- return to inventory
            workingInv[id] = (workingInv[id] or 0) + 1
            craftGridState[dragSourceIndex] = nil
            updateSlotOrder(workingInv)
            renderInventory(workingInv)

        elseif currentHoverCraft and currentHoverCraft ~= dragSourceIndex then
            -- swap craft grid slots
            craftGridState[dragSourceIndex], craftGridState[currentHoverCraft] =
                craftGridState[currentHoverCraft], craftGridState[dragSourceIndex]

        else
            -- clear craft slot
            craftGridState[dragSourceIndex] = nil
        end
        updateCraftingUI()
    end

    dragSourceType = nil
end)

-- inventory slot hover & drag start
for idx, slot in ipairs(invSlots) do
    slot.MouseEnter:Connect(function()
        currentHoverInv = idx
        slot.BackgroundColor3 = HOVER_SLOT_COLOR
    end)
    slot.MouseLeave:Connect(function()
        if currentHoverInv == idx then currentHoverInv = nil end
        slot.BackgroundColor3 = DEFAULT_SLOT_COLOR
    end)
    slot.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(slot, inp)
        end
    end)
end

-- hotbar slot hover, right‐click equip, left‐click drag
for idx, slot in ipairs(hotbarSlots) do
    slot.MouseEnter:Connect(function()
        currentHoverHotbar = idx
        slot.BackgroundColor3 = HOTBAR_HOVER_COLOR
    end)
    slot.MouseLeave:Connect(function()
        if currentHoverHotbar == idx then currentHoverHotbar = nil end
        slot.BackgroundColor3 = DEFAULT_SLOT_COLOR
    end)
    slot.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            local id = hotbarOrder[idx]
            if id then
                RequestEquip:FireServer(id)
            end
        elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(slot, inp)
        end
    end)
end

-- craft grid slot hover & drag
for idx, slot in ipairs(craftSlots) do
    slot.MouseEnter:Connect(function()
        currentHoverCraft = idx
        slot.BackgroundColor3 = CRAFT_HOVER_COLOR
    end)
    slot.MouseLeave:Connect(function()
        if currentHoverCraft == idx then currentHoverCraft = nil end
        slot.BackgroundColor3 = DEFAULT_SLOT_COLOR
    end)
    slot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(slot, input)
        end
    end)
end

-- open/close crafting window
openCraftBtn.MouseButton1Click:Connect(function()
    if craftingFrame.Visible then
        closeCrafting(true)
    else
        craftingFrame.Visible = true
        updateCraftingUI()
    end
end)

-- perform craft on button click
craftButton.MouseButton1Click:Connect(function()
    local rec = findMatchingRecipe(craftGridState)
    if not rec then return end

    RequestCraft:FireServer(rec.outputId)

    -- clear craft grid state & UI
    for i = 1, 9 do
        craftGridState[i] = nil
    end
    updateCraftingUI()

    -- remove used tools from hotbar if part of recipe
    for idx, id in ipairs(hotbarOrder) do
        if id and rec.ingredients[id] then
            hotbarOrder[idx] = nil
            local character = player.Character
            local equipped = character:FindFirstChild(id)
            equipped:Destroy()
        end
    end
    renderHotbar()
    updateEquippedIndicator()
end)

-- hotkey 1/2/3 equip
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local map = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
    }
    local idx = map[input.KeyCode]
    if idx then
        local id = hotbarOrder[idx]
        if id then
            RequestEquip:FireServer(id)
        end
    end
end)

-- receive updated inventory from server
InventoryUpdated.OnClientEvent:Connect(function(inv)
    -- deep copy inventory
    workingInv = {}
    for id,ct in pairs(inv) do
        workingInv[id] = ct
    end

    updateSlotOrder(workingInv)
    renderInventory(workingInv)
    renderHotbar()
    if craftingFrame.Visible then
        updateCraftingUI()
    end
    updateEquippedIndicator()
end)
