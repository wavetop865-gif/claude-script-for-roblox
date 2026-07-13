-- GameSneeze Lib | mobile-fixed build
-- Вставь в executor и запусти

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/wavetop865-gif/claude-script-for-roblox/cursor/fix-gamesneeze-mobile-383a/GameSneeze-Lib/Library.lua"
))()

local Window = Library:New({
    Name = "Title here",
    Accent = Color3.fromRGB(55, 175, 225),
})

local Page1 = Window:Page({
    Name = "Page Name Here",
})

local Page2 = Window:Page({
    Name = "Page Name Here",
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

Section:Label({
    Name = "Label Name Here",
})

Section:Toggle({
    Name = "Toggle Here",
    Default = false,
    callback = function(state)
        print("Toggle:", state)
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
        print("Slider:", value)
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
