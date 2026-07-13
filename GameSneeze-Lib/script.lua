-- GameSneeze Lib | mobile-fixed build + working ESP
-- Вставь в executor и запусти

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/wavetop865-gif/claude-script-for-roblox/cursor/fix-gamesneeze-mobile-383a/GameSneeze-Lib/Library.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Window = Library:New({
    Name = "Title here",
    Accent = Color3.fromRGB(55, 175, 225),
    PageAmmount = 2,
})

local Page1 = Window:Page({
    Name = "Visuals",
})

local Page2 = Window:Page({
    Name = "Settings",
})

local Section = Page1:Section({
    Name = "Section Name Here",
    Side = "Left",
    Fill = true,
})

local SideSection = Page1:Section({
    Name = "New Section",
    Side = "Right",
    Fill = true,
})

local ESP = {
    Enabled = false,
    Box = true,
    Name = true,
    Distance = true,
    Health = true,
    MaxDistance = 1000,
}

local espObjects = {}

local function makeDrawing(className, props)
    local drawing = Drawing.new(className)
    for key, value in pairs(props) do
        drawing[key] = value
    end
    drawing.Visible = false
    return drawing
end

local function hideEspObject(obj)
    for _, drawing in pairs(obj) do
        if typeof(drawing) == "userdata" then
            drawing.Visible = false
        end
    end
end

local function clearEsp(player)
    local obj = espObjects[player]
    if not obj then
        return
    end
    for _, drawing in pairs(obj) do
        if typeof(drawing) == "userdata" then
            pcall(function()
                drawing:Remove()
            end)
        end
    end
    espObjects[player] = nil
end

local function getEsp(player)
    if espObjects[player] then
        return espObjects[player]
    end
    local obj = {
        boxOutline = makeDrawing("Square", {
            Thickness = 2,
            Filled = false,
            Color = Color3.fromRGB(0, 0, 0),
            ZIndex = 1,
        }),
        box = makeDrawing("Square", {
            Thickness = 1,
            Filled = false,
            Color = Color3.fromRGB(255, 255, 255),
            ZIndex = 2,
        }),
        healthOutline = makeDrawing("Square", {
            Thickness = 1,
            Filled = true,
            Color = Color3.fromRGB(0, 0, 0),
            ZIndex = 1,
        }),
        health = makeDrawing("Square", {
            Thickness = 1,
            Filled = true,
            Color = Color3.fromRGB(0, 255, 0),
            ZIndex = 2,
        }),
        name = makeDrawing("Text", {
            Size = 14,
            Center = true,
            Outline = true,
            Color = Color3.fromRGB(255, 255, 255),
            ZIndex = 3,
        }),
        distance = makeDrawing("Text", {
            Size = 13,
            Center = true,
            Outline = true,
            Color = Color3.fromRGB(200, 200, 200),
            ZIndex = 3,
        }),
    }
    espObjects[player] = obj
    return obj
end

local function getCharacterBox(character)
    local head = character:FindFirstChild("Head")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not (head and root) then
        return nil
    end
    local top, topOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
    local bottom, bottomOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    if not (topOnScreen or bottomOnScreen) or top.Z < 0 or bottom.Z < 0 then
        return nil
    end
    local height = math.abs(bottom.Y - top.Y)
    local width = math.clamp(height * 0.55, 14, 180)
    local x = (top.X + bottom.X) / 2 - width / 2
    local y = math.min(top.Y, bottom.Y)
    return {
        X = x,
        Y = y,
        Width = width,
        Height = math.clamp(height, 28, 260),
    }
end

local function updateEsp()
    if not ESP.Enabled then
        for _, obj in pairs(espObjects) do
            hideEspObject(obj)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local obj = getEsp(player)

        if not (character and humanoid and root and humanoid.Health > 0) then
            hideEspObject(obj)
            continue
        end

        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        if distance > ESP.MaxDistance then
            hideEspObject(obj)
            continue
        end

        local box = getCharacterBox(character)
        if not box then
            hideEspObject(obj)
            continue
        end

        local healthFraction = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        local healthColor = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)

        if ESP.Box then
            obj.boxOutline.Visible = true
            obj.boxOutline.Position = Vector2.new(box.X - 1, box.Y - 1)
            obj.boxOutline.Size = Vector2.new(box.Width + 2, box.Height + 2)

            obj.box.Visible = true
            obj.box.Position = Vector2.new(box.X, box.Y)
            obj.box.Size = Vector2.new(box.Width, box.Height)
            obj.box.Color = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 255, 255)
        else
            obj.boxOutline.Visible = false
            obj.box.Visible = false
        end

        if ESP.Health then
            local barHeight = box.Height
            local fillHeight = math.max(2, barHeight * healthFraction)
            obj.healthOutline.Visible = true
            obj.healthOutline.Position = Vector2.new(box.X - 6, box.Y - 1)
            obj.healthOutline.Size = Vector2.new(4, barHeight + 2)

            obj.health.Visible = true
            obj.health.Color = healthColor
            obj.health.Position = Vector2.new(box.X - 5, box.Y + barHeight - fillHeight)
            obj.health.Size = Vector2.new(2, fillHeight)
        else
            obj.healthOutline.Visible = false
            obj.health.Visible = false
        end

        if ESP.Name then
            obj.name.Visible = true
            obj.name.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
            obj.name.Position = Vector2.new(box.X + box.Width / 2, box.Y - 18)
        else
            obj.name.Visible = false
        end

        if ESP.Distance then
            obj.distance.Visible = true
            obj.distance.Text = math.floor(distance) .. "m"
            obj.distance.Position = Vector2.new(box.X + box.Width / 2, box.Y + box.Height + 4)
        else
            obj.distance.Visible = false
        end
    end
end

RunService.RenderStepped:Connect(updateEsp)

Players.PlayerRemoving:Connect(clearEsp)

Section:Label({
    Name = "Label Name Here",
})

Section:Toggle({
    Name = "Toggle Here",
    Default = false,
    callback = function(state)
        ESP.Enabled = state
        if not state then
            for _, obj in pairs(espObjects) do
                hideEspObject(obj)
            end
        end
        print("ESP:", state)
    end,
})

Section:Toggle({
    Name = "Box ESP",
    Default = true,
    callback = function(state)
        ESP.Box = state
    end,
})

Section:Toggle({
    Name = "Name ESP",
    Default = true,
    callback = function(state)
        ESP.Name = state
    end,
})

Section:Toggle({
    Name = "Distance ESP",
    Default = true,
    callback = function(state)
        ESP.Distance = state
    end,
})

Section:Toggle({
    Name = "Health Bar",
    Default = true,
    callback = function(state)
        ESP.Health = state
    end,
})

Section:Button({
    Name = "Button Name Here",
    callback = function()
        print("Button clicked")
    end,
})

Section:Slider({
    Name = "Slider",
    Min = 1,
    Max = 100,
    Default = 50,
    callback = function(value)
        ESP.MaxDistance = value * 10
        print("Max distance:", ESP.MaxDistance)
    end,
})

SideSection:Label({
    Name = "Side panel",
    Center = true,
})

SideSection:Toggle({
    Name = "Extra Toggle",
    callback = function(state)
        print("Extra:", state)
    end,
})

Page2:Section({
    Name = "Page 2",
    Side = "Left",
    Fill = true,
}):Button({
    Name = "Test Button",
    callback = function()
        print("Page 2 button")
    end,
})

Window:Initialize()
