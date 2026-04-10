-- Vexon StealHub v1.0 - Rayfield UI Edition
-- All features migrated to Rayfield interface

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
   Name = "VEXON STEAL HUB",
   Icon = 0,
   LoadingTitle = "VEXON",
   LoadingSubtitle = "Initializing...",
   ShowText = "Vexon",
   Theme = "Dark",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- Number formatter for ESP
local function formatNumber(num)
	if not num or typeof(num) ~= "number" then return "?" end
	
	if num >= 1000000000000 then
		return string.format("%.1fT", num / 1000000000000)
	elseif num >= 1000000000 then
		return string.format("%.1fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(num)
	end
end

-- Server hop with cooldown and error handling
local lastServerHopTime = 0
local serverHopCooldown = 2  -- 2 second cooldown between hops

local function doServerHop()
	local currentTime = tick()
	if currentTime - lastServerHopTime < serverHopCooldown then
		print("⏳ Server hop cooldown active. Wait " .. math.ceil(serverHopCooldown - (currentTime - lastServerHopTime)) .. "s")
		Rayfield:Notify({
			Title = "Cooldown Active",
			Content = "Please wait " .. math.ceil(serverHopCooldown - (currentTime - lastServerHopTime)) .. "s",
			Duration = 2,
			Image = 4483362417,
		})
		return
	end
	
	lastServerHopTime = currentTime
	print("🚀 Vexon: Searching for available servers...")
	Rayfield:Notify({
		Title = "Server Hop",
		Content = "Searching for available servers...",
		Duration = 3,
		Image = 4483362417,
	})
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(
			game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", true)
		)
	end)

	if not success then
		print("❌ Failed to fetch servers: " .. tostring(result))
		Rayfield:Notify({
			Title = "Error",
			Content = "Failed to fetch servers",
			Duration = 3,
			Image = 4483362417,
		})
		lastServerHopTime = 0
		return
	end
	
	if not result or not result.data then
		print("❌ Invalid server data received")
		lastServerHopTime = 0
		return
	end

	local validServers = {}
	for _, server in ipairs(result.data) do
		if type(server) == "table" and 
		   server.id and 
		   type(tonumber(server.playing)) == "number" and 
		   type(tonumber(server.maxPlayers)) == "number" and 
		   server.id ~= game.JobId and 
		   tonumber(server.playing) < tonumber(server.maxPlayers) then
			table.insert(validServers, server.id)
		end
	end

	if #validServers > 0 then
		local pickedServer = validServers[math.random(1, #validServers)]
		print("🔄 Found server! Hopping...")
		Rayfield:Notify({
			Title = "Server Found",
			Content = "Hopping to new server...",
			Duration = 2,
			Image = 4483362417,
		})
		task.wait(0.5)
		local teleportSuccess, teleportErr = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, pickedServer, player)
		end)
		if not teleportSuccess then
			print("❌ Teleport failed: " .. tostring(teleportErr))
			Rayfield:Notify({
				Title = "Error",
				Content = "Teleport failed: " .. tostring(teleportErr),
				Duration = 3,
				Image = 4483362417,
			})
			lastServerHopTime = 0  -- Reset cooldown if teleport fails
		end
	else
		print("❌ Serverhop: Couldn't find a server.")
		Rayfield:Notify({
			Title = "No Servers",
			Content = "Couldn't find an available server",
			Duration = 3,
			Image = 4483362417,
		})
		lastServerHopTime = 0  -- Reset cooldown if no servers found
	end
end

-- Rejoin - rejoins the exact current server using JobId
local function doRejoin()
	local currentTime = tick()
	if currentTime - lastServerHopTime < serverHopCooldown then
		print("⏳ Teleport cooldown active. Wait " .. math.ceil(serverHopCooldown - (currentTime - lastServerHopTime)) .. "s")
		Rayfield:Notify({
			Title = "Cooldown Active",
			Content = "Please wait " .. math.ceil(serverHopCooldown - (currentTime - lastServerHopTime)) .. "s",
			Duration = 2,
			Image = 4483362417,
		})
		return
	end
	
	lastServerHopTime = currentTime
	print("🔄 Vexon: Rejoining current server...")
	Rayfield:Notify({
		Title = "Rejoin",
		Content = "Rejoining server...",
		Duration = 2,
		Image = 4483362417,
	})
	task.wait(0.5)
	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
	if not success then
		print("❌ Rejoin failed: " .. tostring(err))
		Rayfield:Notify({
			Title = "Error",
			Content = "Rejoin failed: " .. tostring(err),
			Duration = 3,
			Image = 4483362417,
		})
		lastServerHopTime = 0  -- Reset cooldown on failure
	end
end

-- Features storage
local connections = {}
local featureStates = {}  -- Track which features are enabled for respawn

-- Helper to get valid character
local function getValidCharacter()
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		return char
	end
	return nil
end

-- Helper to safely disconnect and cleanup
local function safeDisconnect(key)
	if connections[key] then
		if typeof(connections[key]) == "RBXScriptConnection" then
			connections[key]:Disconnect()
		elseif typeof(connections[key]) == "table" then
			for _, conn in ipairs(connections[key]) do
				if conn then conn:Disconnect() end
			end
		end
		connections[key] = nil
	end
end

-- Global cleanup function to prevent memory leaks
local function cleanup()
	for key, conn in pairs(connections) do
		safeDisconnect(key)
	end
	for plr, gui in pairs(espObjects) do
		if gui and gui.Parent then
			pcall(function() gui:Destroy() end)
		end
	end
	espObjects = {}
end

-- Cleanup on script reload
game:GetService("RunService").Heartbeat:Connect(function()
	-- Periodically check for orphaned connections (every 30 seconds)
	if math.random(1, 1800) == 1 then
		-- Clean up any nil connections
		for key in pairs(connections) do
			if not connections[key] or (typeof(connections[key]) == "RBXScriptConnection" and not connections[key].Connected) then
				connections[key] = nil
			end
		end
	end
end)

-- Create tabs
local MainTab = Window:CreateTab("Main", 4483362417)
local ESPTab = Window:CreateTab("ESP", 4483362417)
local SettingsTab = Window:CreateTab("Settings", 4483362417)

-- MAIN TAB
MainTab:CreateButton({
	Name = "Server Hop",
	Callback = function()
		doServerHop()
	end,
})

MainTab:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		doRejoin()
	end,
})

-- ESP TAB
local espObjects = {}

function createPlayerESP(plr)
	if not plr or not plr.Character then return end
	if espObjects[plr] then return end

	local char = plr.Character
	local head = char:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = CoreGui

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 100)
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = plr.Name
	text.Parent = billboard

	espObjects[plr] = billboard

	local charRemoveConn
	charRemoveConn = plr.CharacterRemoving:Connect(function()
		if espObjects[plr] then
			pcall(function() espObjects[plr]:Destroy() end)
			espObjects[plr] = nil
		end
		if charRemoveConn then charRemoveConn:Disconnect() end
	end)
end

ESPTab:CreateToggle({
	Name = "ESP (Names + Cash + Steals)",
	CurrentValue = false,
	Flag = "Toggle_ESP",
	Callback = function(Value)
		featureStates.esp = Value
		if Value then
			-- Create ESP for existing players
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					pcall(function() createPlayerESP(plr) end)
				end
			end

			-- Listen for new players
			safeDisconnect("espAdded")
			connections.espAdded = Players.PlayerAdded:Connect(function(plr)
				task.wait(0.2)
				pcall(function() createPlayerESP(plr) end)
			end)

			-- Update ESP data
			safeDisconnect("espUpdate")
			connections.espUpdate = RunService.Heartbeat:Connect(function()
				for plr, gui in pairs(espObjects) do
					if plr and plr.Character and gui then
						local char = plr.Character
						local humanoid = char:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							-- Update text with name, cash, steals (if available)
							gui.TextLabel.Text = plr.Name .. " | [Active]"
						else
							if espObjects[plr] then
								pcall(function() espObjects[plr]:Destroy() end)
								espObjects[plr] = nil
							end
						end
					end
				end
			end)
		else
			safeDisconnect("espAdded")
			safeDisconnect("espUpdate")
			for _, gui in pairs(espObjects) do
				if gui and gui.Parent then
					pcall(function() gui:Destroy() end)
				end
			end
			espObjects = {}
		end
	end,
})

-- Secret Parts Highlighter
local secretParts = {
	"SECRET_ASCENDINGEGG",
	"SECRET_LOOTPLACEHOLDER",
	"SECRET_SEVEN",
	"SECRET_SIX",
	"SECRET_SUPERBLOCKSCAPE",
	"SECRET_SUPERBLOCKSFEDORA",
	"SECRET_SUPERBLOCKSHAD",
	"SECRET_SUPERBLOCKSHADES",
	"SECRET_SUPERBLOCKSOILET",
	"SECRET_SUPERBLOCKSTOILET"
}

local highlightedSecrets = {}

local function createSecretESP(mainPart, modelName)
	if highlightedSecrets[mainPart] then return end
	
	local success, err = pcall(function()
		-- Use BoxHandleAdornment for visible wireframe ESP
		local boxAdorn = Instance.new("BoxHandleAdornment")
		boxAdorn.Name = modelName:lower().."_SESP"
		boxAdorn.Parent = mainPart
		boxAdorn.Adornee = mainPart
		boxAdorn.AlwaysOnTop = true
		boxAdorn.ZIndex = 0
		boxAdorn.Size = mainPart.Size
		boxAdorn.Transparency = 0.3
		boxAdorn.Color = BrickColor.new("Lime green")
		
		highlightedSecrets[mainPart] = boxAdorn
	end)
end

local function checkAndHighlightPart(model)
	-- The secret parts are in PlacedItems > SECRET_[name]_placed_[id] > Main
	for _, secretName in ipairs(secretParts) do
		local isMatch = string.sub(model.Name, 1, #secretName) == secretName
		if isMatch then
			local mainPart = model:FindFirstChild("Main")
			if mainPart and mainPart:IsA("BasePart") then
				createSecretESP(mainPart, model.Name)
			end
			break
		end
	end
end

ESPTab:CreateToggle({
	Name = "Highlight Secret Parts",
	CurrentValue = false,
	Flag = "Toggle_SecretHighlight",
	Callback = function(Value)
		featureStates.secretHighlight = Value
		if Value then
			safeDisconnect("secretScan")
			safeDisconnect("secretDescendantAdded")
			
			-- Initial scan of PlacedItems for existing secret parts
			task.spawn(function()
				local placedItems = workspace:FindFirstChild("PlacedItems")
				if placedItems then
					for _, model in ipairs(placedItems:GetChildren()) do
						checkAndHighlightPart(model)
					end
				end
			end)
			
			-- Listen for new secret parts being added to PlacedItems
			local placedItems = workspace:FindFirstChild("PlacedItems")
			if placedItems then
				connections.secretDescendantAdded = placedItems.ChildAdded:Connect(function(model)
					task.wait(0.1)  -- Wait for model to fully load
					checkAndHighlightPart(model)
				end)
			end
		else
			safeDisconnect("secretScan")
			safeDisconnect("secretDescendantAdded")
			-- Destroy adornments
			for part, adorn in pairs(highlightedSecrets) do
				if adorn and adorn.Parent then
					pcall(function() adorn:Destroy() end)
				end
			end
			highlightedSecrets = {}
		end
	end,
})

-- SETTINGS TAB
SettingsTab:CreateLabel("Version: 1.0 - Rayfield Edition")
SettingsTab:CreateLabel("Features: Server Hop, Rejoin, ESP, Secret Highlighter")
SettingsTab:CreateButton({
	Name = "Close UI",
	Callback = function()
		Window:Close()
	end,
})

-- Handle character respawn
player.CharacterAdded:Connect(function(newChar)
	wait(0.1)  -- Wait for character to load fully
end)

print("✅ Vexon StealHub loaded! Press K to toggle UI.")