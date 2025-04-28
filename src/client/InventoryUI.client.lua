--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local InventoryUpdated = ReplicatedStorage.ResourceCrafterShared.RemoteEvents.InventoryUpdated
local RequestEquip = ReplicatedStorage.ResourceCrafterShared.RemoteEvents.RequestEquip

local Items = require(ReplicatedStorage.ResourceCrafterShared.Items)

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
local invFrame = gui:WaitForChild("InventoryFrame")
local hotbarFrame = gui:WaitForChild("HotbarFrame")

local invSlots = {}
for i = 1, 30 do
    invSlots[i] = invFrame:WaitForChild("Slot"..i)
end

local hotbarSlots = {}
for i = 1, 3 do
    hotbarSlots[i] = hotbarFrame:WaitForChild("HotbarSlot"..i)
end

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

local slotOrder = {}
local lastInv = {}
local hotbarOrder = {nil, nil, nil}
local currentHoverInv
local currentHoverHotbar

invFrame.Visible = false
hotbarFrame.Visible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M then
        invFrame.Visible = not invFrame.Visible
    end
end)

local function updateSlotOrder(inv)
    for i = #slotOrder, 1, -1 do
        if not inv[slotOrder[i]] or inv[slotOrder[i]] <= 0 then
            table.remove(slotOrder, i)
        end
    end
    for id, count in pairs(inv) do
        if count > 0 then
            local found = false
            for _, v in ipairs(slotOrder) do
                if v == id then found = true; break end
            end
            if not found and #slotOrder < 30 then
                table.insert(slotOrder, id)
            end
        end
    end
end

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

local function renderAll(inv)
    renderInventory(inv)
    renderHotbar()
end

local dragging = false
local dragSourceType = nil
local dragSourceIndex = 0
local dragOffset = Vector2.zero
local ghost
local dragConn

local function startDrag(slot, input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local inventoryIdx = table.find(invSlots, slot)
    local hotbarIdx = table.find(hotbarSlots, slot)
    if inventoryIdx then
        if not slotOrder[inventoryIdx] then return end
        dragSourceType, dragSourceIndex = "inv", inventoryIdx
    elseif hotbarIdx then
        if not hotbarOrder[hotbarIdx] then return end
        dragSourceType, dragSourceIndex = "hotbar", hotbarIdx
    else
        return
    end

    dragging = true
    slot.BackgroundTransparency = 0.5
    slot:FindFirstChild("Icon").ImageTransparency = 0.5
    if dragSourceType == "inv" then
        slot:FindFirstChild("Count").TextTransparency = 0.5
    end

    local absPos = slot.AbsolutePosition
    dragOffset = Vector2.new(
        input.Position.X - absPos.X,
        input.Position.Y - absPos.Y
    )

    ghost = slot:Clone()
    ghost.Name = "DragGhost"
    ghost.Parent = gui
    ghost.ZIndex = 100
    ghost.Visible = true
    ghost.Position = UDim2.fromOffset(absPos.X, absPos.Y)

    dragConn = RunService.RenderStepped:Connect(function()
        local mx,my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
        ghost.Position = UDim2.fromOffset(mx - dragOffset.X, my - dragOffset.Y)
    end)
end

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
        else
            slot:TweenSize(HOTBAR_SLOT_NORMAL_SIZE,
                Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
                0.1, true)
        end
    end
end

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

player.CharacterAdded:Connect(onCharacter)
if player.Character then
    onCharacter(player.Character)
end

UserInputService.InputEnded:Connect(function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 or not dragging then
        return
    end
    dragging = false
    if dragConn then dragConn:Disconnect(); dragConn = nil end
    if ghost then ghost:Destroy(); ghost = nil end

    local original = (dragSourceType == "inv" and invSlots or hotbarSlots)[dragSourceIndex]
    original.BackgroundTransparency = 0
    original:FindFirstChild("Icon").ImageTransparency = 0
    if dragSourceType == "inv" then
        original:FindFirstChild("Count").TextTransparency = 0
    end

    if dragSourceType == "inv" then
        local id = slotOrder[dragSourceIndex]
        if currentHoverHotbar then
            if not hotbarOrder[currentHoverHotbar]
               and not table.find(hotbarOrder, id) then
                hotbarOrder[currentHoverHotbar] = id
                renderHotbar()
                updateEquippedIndicator()
            end
        elseif currentHoverInv and currentHoverInv ~= dragSourceIndex then
            slotOrder[dragSourceIndex], slotOrder[currentHoverInv] =
                slotOrder[currentHoverInv], slotOrder[dragSourceIndex]
            renderInventory(lastInv)
        end

    elseif dragSourceType == "hotbar" then
        if currentHoverHotbar and currentHoverHotbar ~= dragSourceIndex then
            hotbarOrder[dragSourceIndex], hotbarOrder[currentHoverHotbar] =
                hotbarOrder[currentHoverHotbar], hotbarOrder[dragSourceIndex]
        else
            hotbarOrder[dragSourceIndex] = nil
        end
        renderHotbar()
        updateEquippedIndicator()
    end

    dragSourceType = nil
end)

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

InventoryUpdated.OnClientEvent:Connect(function(inv)
    lastInv = inv
    updateSlotOrder(inv)
    renderAll(inv)
    updateEquippedIndicator()
end)
