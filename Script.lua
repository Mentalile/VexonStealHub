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

-- New Fly Feature Variables
local newFlyEnabled = false
local newFlyConnection = nil
local newFlyVelocity = nil
local newFlyGyro = nil

local function freezePlayer()
	local char = player.Character
	if not char then return end
	
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			pcall(function()
				part.Anchored = true
			end)
		end
	end
end

local function unfreezePlayer()
	local char = player.Character
	if not char then return end
	
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Anchored then
			pcall(function()
				part.Anchored = false
			end)
		end
	end
end

local function enableNewFly()
	newFlyEnabled = true
	local char = player.Character
	if not char then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	
	if not root or not humanoid then return end
	
	-- Create BodyVelocity for movement
	newFlyVelocity = Instance.new("BodyVelocity")
	newFlyVelocity.Velocity = Vector3.new(0, 0, 0)
	newFlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	newFlyVelocity.Parent = root
	
	-- Create BodyGyro for rotation
	newFlyGyro = Instance.new("BodyGyro")
	newFlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	newFlyGyro.P = 10000
	newFlyGyro.Parent = root
	
	humanoid.PlatformStand = true
	
	-- Rapid freeze/unfreeze cycle with VFly 0.3
	newFlyConnection = RunService.RenderStepped:Connect(function()
		if not newFlyEnabled or not player.Character then return end
		
		local char = player.Character
		local root = char:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		
		if not root or not newFlyVelocity or not newFlyGyro then return end
		
		-- Update rotation
		newFlyGyro.CFrame = camera.CFrame
		
		-- Handle movement input (WASD)
		local moveDir = Vector3.new(0, 0, 0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir = moveDir + camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir = moveDir - camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir = moveDir - camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir = moveDir + camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDir = moveDir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			moveDir = moveDir - Vector3.new(0, 1, 0)
		end
		
		-- Apply movement at 0.3 speed
		if moveDir.Magnitude > 0 then
			newFlyVelocity.Velocity = moveDir.Unit * 0.3
		else
			newFlyVelocity.Velocity = Vector3.new(0, 0, 0)
		end
	end)
	
	Rayfield:Notify({
		Title = "New Fly",
		Content = "New Fly enabled! Use WASD + Space/Ctrl to move.",
		Duration = 3,
		Image = 4483362417,
	})
end

local function disableNewFly()
	newFlyEnabled = false
	local char = player.Character
	
	if newFlyConnection then
		newFlyConnection:Disconnect()
		newFlyConnection = nil
	end
	
	if newFlyVelocity then
		pcall(function() newFlyVelocity:Destroy() end)
		newFlyVelocity = nil
	end
	
	if newFlyGyro then
		pcall(function() newFlyGyro:Destroy() end)
		newFlyGyro = nil
	end
	
	-- Restore humanoid state
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
	
	Rayfield:Notify({
		Title = "New Fly",
		Content = "New Fly disabled!",
		Duration = 2,
		Image = 4483362417,
	})
end

MainTab:CreateToggle({
	Name = "New Fly (Spam Freeze + VFly 0.3)",
	CurrentValue = false,
	Flag = "Toggle_NewFly",
	Callback = function(Value)
		if Value then
			enableNewFly()
		else
			disableNewFly()
		end
	end,
})

-- Fly Jump Feature Variables
local flyJumpEnabled = false
local flyJumpConnection = nil

local function enableFlyJump()
	flyJumpEnabled = true
	
	-- Disconnect previous connection if it exists
	if flyJumpConnection then
		flyJumpConnection:Disconnect()
		flyJumpConnection = nil
	end
	
	-- Connect to JumpRequest to keep player jumping
	flyJumpConnection = UserInputService.JumpRequest:Connect(function()
		if not flyJumpEnabled or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		end
	end)
	
	Rayfield:Notify({
		Title = "⚠️ Fly Jump",
		Content = "Fly Jump enabled! WARNING: Semi-detected, may be finicky!",
		Duration = 4,
		Image = 4483362417,
	})
end

local function disableFlyJump()
	flyJumpEnabled = false
	
	if flyJumpConnection then
		flyJumpConnection:Disconnect()
		flyJumpConnection = nil
	end
	
	Rayfield:Notify({
		Title = "Fly Jump",
		Content = "Fly Jump disabled",
		Duration = 2,
		Image = 4483362417,
	})
end

MainTab:CreateToggle({
	Name = "Fly Jump (Semi-Detected)",
	CurrentValue = false,
	Flag = "Toggle_FlyJump",
	Callback = function(Value)
		if Value then
			enableFlyJump()
		else
			disableFlyJump()
		end
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
							-- Get cash and steals from leaderstats
							local cash = "?"
							local steals = "?"
							pcall(function()
								if plr:FindFirstChild("leaderstats") then
									local stats = plr.leaderstats
									if stats:FindFirstChild("Cash") then
										cash = formatNumber(stats.Cash.Value)
									end
									if stats:FindFirstChild("Steals") then
										steals = tostring(stats.Steals.Value)
									end
								end
							end)
							-- Update text with name, steals, and formatted cash
							gui.TextLabel.Text = plr.Name .. " | " .. steals .. " | $" .. cash
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

-- LEADERBOARD TAB
local LeaderboardTab = Window:CreateTab("Leaderboard", 4483362417)

local function updateLeaderboard()
	-- Get all players and their stats
	local playerStats = {}
	
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local cash = 0
			local steals = 0
			
			pcall(function()
				if plr:FindFirstChild("leaderstats") then
					local stats = plr.leaderstats
					if stats:FindFirstChild("Cash") then
						cash = stats.Cash.Value
					end
					if stats:FindFirstChild("Steals") then
						steals = stats.Steals.Value
					end
				end
			end)
			
			table.insert(playerStats, {
				name = plr.Name,
				steals = steals,
				cash = cash,
				cashFormatted = formatNumber(cash)
			})
		end
	end
	
	-- Sort by steals (descending)
	table.sort(playerStats, function(a, b)
		return a.steals > b.steals
	end)
	
	-- Create leaderboard text
	local leaderboardText = "RANK | NAME | STEALS | CASH\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
	for i, stat in ipairs(playerStats) do
		leaderboardText = leaderboardText .. string.format("%d | %s | %d | $%s\n", i, stat.name, stat.steals, stat.cashFormatted)
	end
	
	-- Return formatted text (no need to update UI directly)
	return leaderboardText
end

-- Create a label to display the leaderboard
local leaderboardLabel = LeaderboardTab:CreateLabel("")

LeaderboardTab:CreateButton({
	Name = "Refresh Leaderboard",
	Callback = function()
		local text = updateLeaderboard()
		leaderboardLabel:Set(text)
		Rayfield:Notify({
			Title = "Leaderboard",
			Content = "Leaderboard updated!",
			Duration = 2,
			Image = 4483362417,
		})
	end,
})

-- Auto-update leaderboard every 2 seconds
connections.leaderboardUpdate = game:GetService("RunService").Heartbeat:Connect(function()
	if math.random(1, 120) == 1 then  -- Update every ~2 seconds
		local text = updateLeaderboard()
		pcall(function() leaderboardLabel:Set(text) end)
	end
end)

-- SETTINGS TAB
SettingsTab:CreateLabel("Version: 1.0 - Rayfield Edition")
SettingsTab:CreateLabel("Features: Server Hop, Rejoin, New Fly, Fly Jump, ESP, Secret Highlighter, Leaderboard")
SettingsTab:CreateButton({
	Name = "Close UI",
	Callback = function()
		Window:Close()
	end,
})

-- Handle character respawn
player.CharacterAdded:Connect(function(newChar)
	wait(0.1)  -- Wait for character to load fully
	-- Disable New Fly on respawn
	if newFlyEnabled then
		disableNewFly()
	end
	-- Disable Fly Jump on respawn
	if flyJumpEnabled then
		disableFlyJump()
	end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(plr)
	-- Clean up ESP
	if espObjects[plr] then
		pcall(function() espObjects[plr]:Destroy() end)
		espObjects[plr] = nil
	end
end)

print("✅ Vexon StealHub loaded! Press K to toggle UI.")