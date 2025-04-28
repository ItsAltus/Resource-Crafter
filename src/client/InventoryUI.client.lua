--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InventoryUpdated = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("InventoryUpdated")

local RequestEquip = ReplicatedStorage
    :WaitForChild("ResourceCrafterShared")
    :WaitForChild("RemoteEvents")
    :WaitForChild("RequestEquip")

local Items = require(ReplicatedStorage.ResourceCrafterShared.Items)

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "InventoryUI"
gui.ResetOnSpawn = false

-- background frame
local frame = Instance.new("Frame")
frame.Name  = "InventoryFrame"
frame.Size  = UDim2.new(0,  (64+4)*5 + 4, 0, (64+4)*6 + 4)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Parent = gui

-- grid layout
local grid = Instance.new("UIGridLayout")
grid.CellSize    = UDim2.new(0,64,0,64)
grid.CellPadding = UDim2.new(0,4,0,4)
grid.SortOrder   = Enum.SortOrder.LayoutOrder
grid.Parent      = frame

-- render function
local function render(inv: {[string]: number})
    -- clear old slots
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local order = 1
    for itemId, count in pairs(inv) do
        -- skip zero counts
        if count > 0 then
            local slot = Instance.new("Frame")
            slot.Name        = "Slot"..order
            slot.Size        = UDim2.new(0,64,0,64)
            slot.LayoutOrder = order
            slot.BackgroundColor3 = Color3.fromRGB(40,40,40)
            slot.BorderSizePixel   = 1
            slot.Parent      = frame

            -- icon
            local img = Instance.new("ImageLabel")
            img.Size   = UDim2.new(1,0,1,-20)
            img.Position = UDim2.new(0,0,0,0)
            img.Image  = Items[itemId].icon
            img.BackgroundTransparency = 1
            img.Parent = slot

            -- count
            local lbl = Instance.new("TextLabel")
            lbl.Size      = UDim2.new(1,0,0,20)
            lbl.Position  = UDim2.new(0,0,1,-20)
            lbl.BackgroundTransparency = 1
            lbl.Text      = tostring(count)
            lbl.TextScaled = true
            lbl.TextColor3 = Color3.fromRGB(255,255,255)
            lbl.Parent    = slot

            -- equip on click if toolPower > 0
            if Items[itemId].toolPower then
                slot.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        RequestEquip:FireServer(itemId)
                    end
                end)
            end

            order += 1
            if order > 30 then break end
        end
    end
end

-- initial sync (in case inventory was filled before UI loaded)
InventoryUpdated.OnClientEvent:Connect(render)
