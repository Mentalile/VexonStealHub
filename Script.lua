-- Vexon StealHub v1.0 - Clean Grey Bubbly UI
-- ESP now shows simplified numbers (1.2K, 1.3M, 1.1B, 2.4T)
-- Auto-executes on server hops like Infinite Yield

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Setup auto-execute listener once (like Infinite Yield)
if not _G.VexonListenerSetup then
	_G.VexonListenerSetup = true
	
	-- Listen for any teleport and auto-reload
	TeleportService.Teleported:Connect(function()
		task.wait(2)  -- Wait for new server to fully load
		print("🔄 Detected teleport! Auto-reloading Vexon StealHub on new server...")
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Mentalile/VexonStealHub/refs/heads/main/Script.lua",true))()
	end)
	
	-- Stop on Roblox close
	game:BindToClose(function()
		_G.VexonListenerSetup = false
		print("🛑 Vexon StealHub stopped (Roblox closing)")
	end)
end

-- Clean up old GUI instances
pcall(function()
	if CoreGui:FindFirstChild("VexonStealHub") then
		CoreGui:FindFirstChild("VexonStealHub"):Destroy()
	end
end)

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

-- Server hop - picks a random different server
local function doServerHop()
	print("🚀 Vexon: Finding random server...")
	local success, servers = pcall(function()
		return HttpService:JSONDecode(
			game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		)
	end)

	if success and servers and servers.data then
		local validServers = {}
		for _, server in ipairs(servers.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				table.insert(validServers, server)
			end
		end

		if #validServers > 0 then
			local picked = validServers[math.random(1, #validServers)]
			print("🔄 Hopping to new server...")
			task.wait(0.5)
			TeleportService:TeleportToPlaceInstance(game.PlaceId, picked.id, player)
		else
			print("❌ No other servers found")
		end
	else
		print("❌ Failed to fetch servers")
	end
end

-- Rejoin - rejoins the exact current server using JobId
local function doRejoin()
	print("🔄 Vexon: Rejoining current server...")
	task.wait(0.5)
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VexonStealHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 480)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 55, 55)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title bar (draggable)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 18)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VEXON"
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 80, 1, 0)
versionLabel.Position = UDim2.new(1, -100, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "STEAL HUB"
versionLabel.TextColor3 = Color3.fromRGB(140, 180, 255)
versionLabel.TextScaled = true
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Dragging
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Scrolling content
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 140, 255)
scroll.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = scroll

-- Toggle creator (clean bubbly style)
local function createToggle(name, defaultState, callback)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(1, 0, 0, 55)
	toggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	toggleFrame.BorderSizePixel = 0
	toggleFrame.Parent = scroll

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 14)
	tCorner.Parent = toggleFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.TextScaled = true
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame

	local switch = Instance.new("TextButton")
	switch.Size = UDim2.new(0, 70, 0, 35)
	switch.Position = UDim2.new(1, -85, 0.5, -17.5)
	switch.BackgroundColor3 = defaultState and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(120, 120, 120)
	switch.Text = defaultState and "ON" or "OFF"
	switch.TextColor3 = Color3.fromRGB(255, 255, 255)
	switch.TextScaled = true
	switch.Font = Enum.Font.GothamBold
	switch.Parent = toggleFrame

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(1, 0)
	sCorner.Parent = switch

	local state = defaultState

	switch.MouseButton1Click:Connect(function()
		state = not state
		switch.BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(120, 120, 120)
		switch.Text = state and "ON" or "OFF"
		callback(state)
	end)

	return toggleFrame
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

-- 1. Infinite Jump
createToggle("Infinite Jump", false, function(state)
	featureStates.infJump = state
	if state then
		safeDisconnect("infJump")
		connections.infJump = UserInputService.JumpRequest:Connect(function()
			local char = getValidCharacter()
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
	else
		safeDisconnect("infJump")
	end
end)

-- 2. Server Hop
local hopFrame = Instance.new("Frame")
hopFrame.Size = UDim2.new(1, 0, 0, 55)
hopFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
hopFrame.BorderSizePixel = 0
hopFrame.Parent = scroll

local hopCorner = Instance.new("UICorner")
hopCorner.CornerRadius = UDim.new(0, 14)
hopCorner.Parent = hopFrame

local hopLabel = Instance.new("TextLabel")
hopLabel.Size = UDim2.new(0.7, 0, 1, 0)
hopLabel.BackgroundTransparency = 1
hopLabel.Text = "Server Hop (click to hop)"
hopLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
hopLabel.TextScaled = true
hopLabel.Font = Enum.Font.GothamSemibold
hopLabel.TextXAlignment = Enum.TextXAlignment.Left
hopLabel.Parent = hopFrame

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(0, 100, 0, 35)
hopBtn.Position = UDim2.new(1, -115, 0.5, -17.5)
hopBtn.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
hopBtn.Text = "HOP"
hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hopBtn.TextScaled = true
hopBtn.Font = Enum.Font.GothamBold
hopBtn.Parent = hopFrame

local hopBCorner = Instance.new("UICorner")
hopBCorner.CornerRadius = UDim.new(0, 12)
hopBCorner.Parent = hopBtn

hopBtn.MouseButton1Click:Connect(doServerHop)

-- 3. Rejoin
local rejoinFrame = Instance.new("Frame")
rejoinFrame.Size = UDim2.new(1, 0, 0, 55)
rejoinFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
rejoinFrame.BorderSizePixel = 0
rejoinFrame.Parent = scroll

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 14)
rejoinCorner.Parent = rejoinFrame

local rejoinLabel = Instance.new("TextLabel")
rejoinLabel.Size = UDim2.new(0.7, 0, 1, 0)
rejoinLabel.BackgroundTransparency = 1
rejoinLabel.Text = "Rejoin Current Server"
rejoinLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
rejoinLabel.TextScaled = true
rejoinLabel.Font = Enum.Font.GothamSemibold
rejoinLabel.TextXAlignment = Enum.TextXAlignment.Left
rejoinLabel.Parent = rejoinFrame

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(0, 100, 0, 35)
rejoinBtn.Position = UDim2.new(1, -115, 0.5, -17.5)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 50)
rejoinBtn.Text = "REJOIN"
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextScaled = true
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.Parent = rejoinFrame

local rejoinBCorner = Instance.new("UICorner")
rejoinBCorner.CornerRadius = UDim.new(0, 12)
rejoinBCorner.Parent = rejoinBtn

rejoinBtn.MouseButton1Click:Connect(doRejoin)

-- 4. ESP (with simplified numbers)
local espObjects = {}
createToggle("ESP (Names + Cash + Steals)", false, function(state)
	featureStates.esp = state
	if state then
		-- Create ESP for existing players
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				pcall(function() createPlayerESP(plr) end)
			end
		end

		-- Listen for new players
		safeDisconnect("espAdded")
		connections.espAdded = Players.PlayerAdded:Connect(function(plr)
			if plr ~= player then
				pcall(function() createPlayerESP(plr) end)
			end
		end)

		-- Update ESP data
		safeDisconnect("espUpdate")
		connections.espUpdate = RunService.Heartbeat:Connect(function()
			for plr, gui in pairs(espObjects) do
				if plr and plr.Character and plr.Character:FindFirstChild("Head") then
					local ls = plr:FindFirstChild("leaderstats")
					local cashVal = (ls and ls:FindFirstChild("Cash")) and ls.Cash.Value or 0
					local stealsVal = (ls and ls:FindFirstChild("Steals")) and ls.Steals.Value or 0
					
					if gui and gui.Parent then
						gui.TextLabel.Text = plr.Name .. "\n💰 " .. formatNumber(cashVal) .. "\n🔥 " .. formatNumber(stealsVal)
					end
				end
			end
		end)
	else
		safeDisconnect("espAdded")
		safeDisconnect("espUpdate")
		for _, gui in pairs(espObjects) do
			pcall(function() gui:Destroy() end)
		end
		espObjects = {}
	end
end)

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

-- 5. Super Steal (vfly + noclip)
local FLY_SPEED = 30

createToggle("Super Steal (Slow V-Fly + Noclip)", false, function(state)
	featureStates.superSteal = state
	local char = getValidCharacter()
	if not char then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if state then
		-- Cleanup any existing connections
		safeDisconnect("superStealNoclip")
		safeDisconnect("superStealFly")
		if connections.superStealBV then
			pcall(function() connections.superStealBV:Destroy() end)
			connections.superStealBV = nil
		end

		-- Enable noclip
		connections.superStealNoclip = RunService.Stepped:Connect(function()
			local currentChar = getValidCharacter()
			if currentChar then
				for _, part in ipairs(currentChar:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						pcall(function() part.CanCollide = false end)
					end
				end
			end
		end)

		-- Create BodyVelocity for flight
		connections.superStealBV = Instance.new("BodyVelocity")
		connections.superStealBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		connections.superStealBV.Velocity = Vector3.new(0, 0, 0)
		connections.superStealBV.Parent = root

		-- Enable fly
		connections.superStealFly = RunService.RenderStepped:Connect(function()
			if connections.superStealBV and connections.superStealBV.Parent then
				local cam = workspace.CurrentCamera
				local moveDir = Vector3.new(0, 0, 0)

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

				if moveDir.Magnitude > 0 then
					connections.superStealBV.Velocity = moveDir.Unit * FLY_SPEED
				else
					connections.superStealBV.Velocity = Vector3.new(0, 0, 0)
				end
			end
		end)

		print("🌀 Vexon Super Steal ENABLED (slow fly + noclip)")
	else
		-- Cleanup
		safeDisconnect("superStealNoclip")
		safeDisconnect("superStealFly")
		if connections.superStealBV then
			pcall(function() connections.superStealBV:Destroy() end)
			connections.superStealBV = nil
		end
		
		-- Restore collision
		local currentChar = getValidCharacter()
		if currentChar then
			for _, part in ipairs(currentChar:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function() part.CanCollide = true end)
				end
			end
		end
		print("🛑 Vexon Super Steal DISABLED")
	end
end)

-- Scroll canvas size
scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end)

-- Handle character respawn - reinitialize features if they were enabled
player.CharacterAdded:Connect(function(newChar)
	wait(0.1)  -- Wait for character to load fully
	
	-- Re-enable Super Steal if it was on
	if featureStates.superSteal then
		local root = newChar:FindFirstChild("HumanoidRootPart")
		if root then
			-- Cleanup old connections
			safeDisconnect("superStealNoclip")
			safeDisconnect("superStealFly")
			if connections.superStealBV then
				pcall(function() connections.superStealBV:Destroy() end)
				connections.superStealBV = nil
			end

			-- Re-enable noclip
			connections.superStealNoclip = RunService.Stepped:Connect(function()
				local currentChar = getValidCharacter()
				if currentChar then
					for _, part in ipairs(currentChar:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							pcall(function() part.CanCollide = false end)
						end
					end
				end
			end)

			-- Create BodyVelocity for flight
			connections.superStealBV = Instance.new("BodyVelocity")
			connections.superStealBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			connections.superStealBV.Velocity = Vector3.new(0, 0, 0)
			connections.superStealBV.Parent = root

			-- Re-enable fly
			connections.superStealFly = RunService.RenderStepped:Connect(function()
				if connections.superStealBV and connections.superStealBV.Parent then
					local cam = workspace.CurrentCamera
					local moveDir = Vector3.new(0, 0, 0)

					if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

					if moveDir.Magnitude > 0 then
						connections.superStealBV.Velocity = moveDir.Unit * FLY_SPEED
					else
						connections.superStealBV.Velocity = Vector3.new(0, 0, 0)
					end
				end
			end)
		end
	end
end)

print("✅ Vexon StealHub loaded! Auto-execute enabled - enjoy server hopping!")