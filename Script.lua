-- Vexon StealHub v1.0 - Clean Grey Bubbly UI
-- ESP now shows simplified numbers (1.2K, 1.3M, 1.1B, 2.4T)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

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

-- Server hop with cooldown and error handling
local lastServerHopTime = 0
local serverHopCooldown = 2  -- 2 second cooldown between hops

local function doServerHop()
	local currentTime = tick()
	if currentTime - lastServerHopTime < serverHopCooldown then
		print("⏳ Server hop cooldown active. Wait " .. math.ceil(serverHopCooldown - (currentTime - lastServerHopTime)) .. "s")
		return
	end
	
	lastServerHopTime = currentTime
	print("🚀 Vexon: Searching for available servers...")
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(
			game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", true)
		)
	end)

	if not success then
		print("❌ Failed to fetch servers: " .. tostring(result))
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
		task.wait(0.5)
		local teleportSuccess, teleportErr = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, pickedServer, player)
		end)
		if not teleportSuccess then
			print("❌ Teleport failed: " .. tostring(teleportErr))
			lastServerHopTime = 0  -- Reset cooldown if teleport fails
		end
	else
		print("❌ Serverhop: Couldn't find a server.")
		lastServerHopTime = 0  -- Reset cooldown if no servers found
	end
end

-- Rejoin - rejoins the exact current server using JobId
local function doRejoin()
	local currentTime = tick()
	if currentTime - lastServerHopTime < serverHopCooldown then
		print("⏳ Teleport cooldown active. Wait " .. math.ceil(serverHopCooldown - (currentTime - lastServerHopTime)) .. "s")
		return
	end
	
	lastServerHopTime = currentTime
	print("🔄 Vexon: Rejoining current server...")
	task.wait(0.5)
	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
	if not success then
		print("❌ Rejoin failed: " .. tostring(err))
		lastServerHopTime = 0  -- Reset cooldown on failure
	end
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VexonStealHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- Track minimized state
local isMinimized = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 500)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 50, 70)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Title bar (draggable)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

-- Gradient effect on title bar
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 120, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 22))
})
gradient.Rotation = 90
gradient.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VEXON"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Move "STEAL HUB" and version to a subtitle area
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -30, 0, 20)
subtitleLabel.Position = UDim2.new(0, 15, 0, 32)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "STEAL HUB v1.0"
subtitleLabel.TextColor3 = Color3.fromRGB(150, 180, 255)
subtitleLabel.TextSize = 12
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = titleBar

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -80, 0, 10)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 8)
minimizeCorner.Parent = minimizeBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Minimize frame (when minimized)
local minimizedFrame = Instance.new("Frame")
minimizedFrame.Size = UDim2.new(0, 90, 0, 45)
minimizedFrame.Position = UDim2.new(0.5, -45, 0.5, -22)
minimizedFrame.BackgroundColor3 = Color3.fromRGB(20, 120, 255)
minimizedFrame.BorderSizePixel = 0
minimizedFrame.Visible = false
minimizedFrame.Parent = screenGui

local minimizedCorner = Instance.new("UICorner")
minimizedCorner.CornerRadius = UDim.new(0, 12)
minimizedCorner.Parent = minimizedFrame

local minimizedLabel = Instance.new("TextLabel")
minimizedLabel.Size = UDim2.new(1, 0, 1, 0)
minimizedLabel.BackgroundTransparency = 1
minimizedLabel.Text = "VEXON"
minimizedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizedLabel.TextScaled = true
minimizedLabel.Font = Enum.Font.GothamBold
minimizedLabel.Parent = minimizedFrame

-- Minimize/Restore functionality
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	mainFrame.Visible = not isMinimized
	minimizedFrame.Visible = isMinimized
	minimizeBtn.Text = isMinimized and "+" or "−"
end)

minimizedFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isMinimized = false
		mainFrame.Visible = true
		minimizedFrame.Visible = false
		minimizeBtn.Text = "−"
	end
end)

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
scroll.Size = UDim2.new(1, -20, 1, -80)
scroll.Position = UDim2.new(0, 10, 0, 70)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
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
	toggleFrame.Size = UDim2.new(1, 0, 0, 50)
	toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	toggleFrame.BorderSizePixel = 0
	toggleFrame.Parent = scroll

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 10)
	tCorner.Parent = toggleFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.65, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(240, 240, 245)
	label.TextScaled = true
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = toggleFrame

	local label2 = Instance.new("UIPadding")
	label2.PaddingLeft = UDim.new(0, 12)
	label2.Parent = label

	local switch = Instance.new("TextButton")
	switch.Size = UDim2.new(0, 65, 0, 32)
	switch.Position = UDim2.new(1, -82, 0.5, -16)
	switch.BackgroundColor3 = defaultState and Color3.fromRGB(100, 220, 140) or Color3.fromRGB(100, 100, 130)
	switch.Text = defaultState and "ON" or "OFF"
	switch.TextColor3 = Color3.fromRGB(255, 255, 255)
	switch.TextSize = 12
	switch.Font = Enum.Font.GothamBold
	switch.Parent = toggleFrame

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0, 8)
	sCorner.Parent = switch

	local state = defaultState

	switch.MouseButton1Click:Connect(function()
		state = not state
		switch.BackgroundColor3 = state and Color3.fromRGB(100, 220, 140) or Color3.fromRGB(100, 100, 130)
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
hopFrame.Size = UDim2.new(1, 0, 0, 50)
hopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
hopFrame.BorderSizePixel = 0
hopFrame.Parent = scroll

local hopCorner = Instance.new("UICorner")
hopCorner.CornerRadius = UDim.new(0, 10)
hopCorner.Parent = hopFrame

local hopLabel = Instance.new("TextLabel")
hopLabel.Size = UDim2.new(0.65, 0, 1, 0)
hopLabel.BackgroundTransparency = 1
hopLabel.Text = "Server Hop"
hopLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
hopLabel.TextScaled = true
hopLabel.Font = Enum.Font.GothamSemibold
hopLabel.TextXAlignment = Enum.TextXAlignment.Left
hopLabel.Parent = hopFrame

local hopPad = Instance.new("UIPadding")
hopPad.PaddingLeft = UDim.new(0, 12)
hopPad.Parent = hopLabel

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(0, 65, 0, 32)
hopBtn.Position = UDim2.new(1, -82, 0.5, -16)
hopBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
hopBtn.Text = "HOP"
hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hopBtn.TextSize = 12
hopBtn.Font = Enum.Font.GothamBold
hopBtn.Parent = hopFrame

local hopBCorner = Instance.new("UICorner")
hopBCorner.CornerRadius = UDim.new(0, 8)
hopBCorner.Parent = hopBtn

hopBtn.MouseButton1Click:Connect(doServerHop)

-- 3. Rejoin
local rejoinFrame = Instance.new("Frame")
rejoinFrame.Size = UDim2.new(1, 0, 0, 50)
rejoinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
rejoinFrame.BorderSizePixel = 0
rejoinFrame.Parent = scroll

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 10)
rejoinCorner.Parent = rejoinFrame

local rejoinLabel = Instance.new("TextLabel")
rejoinLabel.Size = UDim2.new(0.65, 0, 1, 0)
rejoinLabel.BackgroundTransparency = 1
rejoinLabel.Text = "Rejoin Server"
rejoinLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
rejoinLabel.TextScaled = true
rejoinLabel.Font = Enum.Font.GothamSemibold
rejoinLabel.TextXAlignment = Enum.TextXAlignment.Left
rejoinLabel.Parent = rejoinFrame

local rejoinPad = Instance.new("UIPadding")
rejoinPad.PaddingLeft = UDim.new(0, 12)
rejoinPad.Parent = rejoinLabel


local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(0, 65, 0, 32)
rejoinBtn.Position = UDim2.new(1, -82, 0.5, -16)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 80)
rejoinBtn.Text = "REJOIN"
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextSize = 12
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.Parent = rejoinFrame

local rejoinBCorner = Instance.new("UICorner")
rejoinBCorner.CornerRadius = UDim.new(0, 8)
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

-- 4b. Secret Parts Highlighter
local secretParts = {
	"SECRET_ASCENDINGEGG",
	"SECRET_LOOTPLACEHOLDER",
	"SECRET_SEVEN",
	"SECRET_SIX",
	"SECRET_SUPERBLOCKSCAPE",
	"SECRET_SUPERBLOCKSFEDORA",
	"SECRET_SUPERBLOCKSHAD",
	"SECRET_SUPERBLOCKSHADES",
	"SECRET_SUPERBLOCKSOILET"
}

local highlightedSecrets = {}

createToggle("Highlight Secret Parts", false, function(state)
	featureStates.secretHighlight = state
	if state then
		-- Start scanning for secret parts
		safeDisconnect("secretScan")
		connections.secretScan = RunService.Heartbeat:Connect(function()
			for _, secretName in ipairs(secretParts) do
				local secretPart = workspace:FindFirstChild(secretName)
				if secretPart and secretPart:IsA("BasePart") then
					if not highlightedSecrets[secretName] then
						-- Create highlight
						local highlight = Instance.new("Highlight")
						highlight.Color = Color3.fromRGB(255, 200, 50)  -- Golden yellow
						highlight.OutlineColor = Color3.fromRGB(255, 140, 0)  -- Orange outline
						highlight.OutlineTransparency = 0.2
						highlight.Transparency = 0.3
						highlight.Parent = secretPart
						
						-- Add outline for better visibility
						pcall(function()
							secretPart.CanCollide = secretPart.CanCollide  -- Keep original collision
						end)
						
						highlightedSecrets[secretName] = highlight
						print("✨ Found secret part: " .. secretName)
					end
				end
			end
		end)
	else
		safeDisconnect("secretScan")
		for secretName, highlight in pairs(highlightedSecrets) do
			if highlight and highlight.Parent then
				pcall(function() highlight:Destroy() end)
			end
		end
		highlightedSecrets = {}
	end
end)

-- 5. Super Steal (vfly + noclip)
local FLY_SPEED = 30
local flySpeeds = {
	keyboard = 30,
	mobile = 60
}

-- Detect if user is on mobile
local function isMobileUser()
	return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)[1] == nil and 
		   (not game:FindService("GuiService")) or 
		   UserInputService:GetMouseDelta() == Vector2.new(0, 0)
end

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

		-- Enable fly - works for both PC and Mobile
		connections.superStealFly = RunService.RenderStepped:Connect(function()
			if connections.superStealBV and connections.superStealBV.Parent then
				local cam = workspace.CurrentCamera
				local moveDir = Vector3.new(0, 0, 0)
				local isMobile = UserInputService:FindFirstChild("Gamepad1") == nil and 
					game:GetService("UserInputService"):GetGamepadState(Enum.UserInputType.Gamepad1) == nil

				-- Keyboard controls (PC)
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

				-- Mobile controls - follow camera direction
				if moveDir.Magnitude == 0 then
					-- No keyboard input, use camera direction (mobile users)
					moveDir = cam.CFrame.LookVector
					local currentSpeed = flySpeeds.mobile
					connections.superStealBV.Velocity = moveDir * currentSpeed
				else
					-- Keyboard input detected
					if moveDir.Magnitude > 0 then
						connections.superStealBV.Velocity = moveDir.Unit * flySpeeds.keyboard
					else
						connections.superStealBV.Velocity = Vector3.new(0, 0, 0)
					end
				end
			end
		end)

		print("🌀 Vexon Super Steal ENABLED (works on PC & Mobile)")
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

			-- Re-enable fly (mobile compatible)
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

					-- Mobile controls - follow camera direction if no keyboard input
					if moveDir.Magnitude == 0 then
						moveDir = cam.CFrame.LookVector
						connections.superStealBV.Velocity = moveDir * flySpeeds.mobile
					else
						connections.superStealBV.Velocity = moveDir.Unit * flySpeeds.keyboard
					end
				end
			end)
		end
	end
end)

print("✅ Vexon StealHub loaded! Enjoy the features.")