-- GameSneeze Lib example (mobile-friendly build)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wavetop865-gif/claude-script-for-roblox/cursor/fix-gamesneeze-mobile-383a/GameSneeze-Lib/Library.lua"))()

local Window = Library:New({
    Name = "Title",
})

local Page = Window:Page({
    Name = "Page"
})

local Section = Page:Section({
    Name = "Section",
    Fill = true,
    Side = "Left"
})

Section:Label({
    Name = "Label",
    Center = true
})

Section:Toggle({
    Name = "Toggle",
    callback = function(value)
        print(value)
    end
})

Section:Button({
    Name = "Button",
    callback = function()
        print("clicked")
    end
})

Section:Slider({
    Name = "Slider",
    Min = 1,
    Max = 100,
    Default = 1,
    callback = function(value)
        print(value)
    end
})

Window:Initialize()
