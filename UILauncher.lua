-- =======================================================================
--   🎃 JACK-O'-LANTERN UI LAUNCHER (POWERED BY HALLOW-LIB)
-- =======================================================================
local Hallow = loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/HallowLib.lua"))()

local Window = Hallow:CreateWindow({
	Title = "UI LAUNCHER"
})

-- -----------------------------------------------------------------------
--   TAB 1: LAUNCH HUBS & TOOLS
-- -----------------------------------------------------------------------
local LaunchTab = Window:CreateTab("Hubs", "🎃")

LaunchTab:CreateSection("Available Scripts")

-- 1. Storage Hunters Hub
LaunchTab:CreateButton({
	Name = "Storage Hunters Hub",
	Description = "Auto-Tot (4m Cooldown), TPs, Insta-Repair & Garages",
	Callback = function()
		Hallow:Notify({
			Title = "Launching...",
			Content = "Loading Storage Hunters Hub",
			Duration = 2.5
		})
		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/Storage%20Hunters%20Script%20(OPHUB)"))()
		end)
	end
})

-- 2. Remote & Interaction Spy
LaunchTab:CreateButton({
	Name = "Remote & Interaction Spy",
	Description = "Captures Remotes, Prompt holds, & filters 'Finds' spam",
	Callback = function()
		Hallow:Notify({
			Title = "Launching...",
			Content = "Loading Remote & Interaction Spy",
			Duration = 2.5
		})
		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/Remote%20Spy.lua"))()
		end)
	end
})

-- 3. Dex Explorer
LaunchTab:CreateButton({
	Name = "Dex Explorer",
	Description = "Dark Dex Premium: Browse workspace hierarchy & data",
	Callback = function()
		Hallow:Notify({
			Title = "Launching...",
			Content = "Loading Dex Explorer",
			Duration = 2.5
		})
		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/XIMMYzwsss/Dex-Premium/refs/heads/main/DexPremium.lua"))()
		end)
	end
})

-- -----------------------------------------------------------------------
--   TAB 2: SETTINGS & MANAGEMENT
-- -----------------------------------------------------------------------
local SettingsTab = Window:CreateTab("Settings", "⚙️")

SettingsTab:CreateSection("Window Management")

SettingsTab:CreateButton({
	Name = "Destroy UI",
	Description = "Completely closes and unloads the launcher",
	Callback = function()
		Window:Destroy()
	end
})

SettingsTab:CreateParagraph({
	Title = "Launcher Information",
	Content = "Jack-O'-Lantern UI launcher rewritten for fast script execution using Hallow Library."
})
