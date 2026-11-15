-- LUMEN CONFIG DEMO
-- Shows saving, loading, deleting and autoloading config files.
--
-- Load the library one of these ways (edit the line below):
--   1) from a file:  loadstring(readfile("Lumen/LumenV2Library.lua"))()
--   2) from a URL:   loadstring(game:HttpGet("https://your.host/LumenV2Library.lua"))()
local Lumen = loadstring(readfile("Lumen/LumenV2Library.lua"))()

local Window = Lumen:CreateWindow({
	Title = "Config Demo",
	Author = "Lumen V2",
	Icon = "wrench",
	Theme = "Dark",
	Glass = 0,
	ToggleKey = Enum.KeyCode.RightShift,
})

---------------------------------------------------------------------
-- Tab 1: some elements WITH a Flag. Only flagged elements are saved.
---------------------------------------------------------------------
Window:Section("Demo")
local Play = Window:Tab({ Title = "Settings to save", Icon = "settings" })

Play:Toggle({ Title = "Enabled", Flag = "Enabled", Value = true })
Play:Slider({
	Title = "Speed",
	Flag = "Speed",
	Value = { Min = 0, Max = 100, Default = 40 },
})
Play:Dropdown({
	Title = "Mode",
	Flag = "Mode",
	Values = { "Easy", "Normal", "Hard", "Insane" },
	Value = "Normal",
})
Play:Dropdown({
	Title = "Features",
	Flag = "Features",
	Multi = true,
	Values = { "Sound", "Particles", "Shadows", "Bloom" },
	Value = { "Sound" },
})
Play:Input({ Title = "Display name", Flag = "Name", Placeholder = "Type here..." })
Play:Keybind({ Title = "Action key", Flag = "ActionKey", Value = "E" })
Play:Colorpicker({ Title = "Accent", Flag = "Accent", Value = Color3.fromHex("#0091ff") })

Play:Paragraph({
	Title = "Try it",
	Desc = "Change a few values, save a config on the Configs tab, change them again, then load it back.",
})

---------------------------------------------------------------------
-- Tab 2: the config manager (one call builds the whole UI)
---------------------------------------------------------------------
Window:Divider()
Window:Section("Config")
local Cfg = Window:Tab({ Title = "Configs", Icon = "palette" })
Cfg:ConfigManager()

---------------------------------------------------------------------
-- Using the API from code instead of the UI
---------------------------------------------------------------------
Cfg:Divider()
Cfg:Paragraph({
	Title = "API examples",
	Desc = "These buttons call the same functions you can use in your own scripts.",
	Buttons = {
		{
			Title = "Quick save",
			Callback = function()
				local ok, err = Lumen:SaveConfigFile("quick")
				Window:Notify({ Title = ok and "Saved 'quick'" or "Failed", Content = err, Duration = 2 })
			end,
		},
		{
			Title = "Quick load",
			Callback = function()
				local ok, err = Lumen:LoadConfigFile("quick")
				Window:Notify({ Title = ok and "Loaded 'quick'" or "Failed", Content = err, Duration = 2 })
			end,
		},
		{
			Title = "Print list",
			Callback = function()
				print("Storage:", Lumen:ConfigStorage())
				print("Configs:", table.concat(Lumen:ListConfigs(), ", "))
				print("Autoload:", Lumen:GetAutoload())
			end,
		},
	},
})

Cfg:Button({
	Title = "Destroy UI",
	Callback = function()
		Window:Destroy()
	end,
})

Window:SelectTab(1)

-- Call this LAST, after every flagged element exists.
Lumen:LoadAutoload()
Window:Notify({ Title = "Ready", Content = "Storage: " .. Lumen:ConfigStorage(), Icon = "check", Duration = 4 })
