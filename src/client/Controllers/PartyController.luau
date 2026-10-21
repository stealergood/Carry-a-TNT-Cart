local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.PartyConfig)

local PartyController = {}
local player = Players.LocalPlayer
-- Keeps the party dialog compact so gameplay stays visible behind it.
local DIALOG_MAX_SCALE = 0.8
local DIALOG_SCREEN_FILL = 0.88
local started = false

function PartyController.Start()
	if started then
		return
	end
	started = true
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("PartyGui", 15)
	local remotes = ReplicatedStorage:WaitForChild(Config.RemoteFolder, 15)
	if not gui or not remotes then
		warn("PartyController: GUI Studio atau remote party belum tersedia.")
		return
	end
	local request = remotes:WaitForChild("Request", 10)
	local snapshot = remotes:WaitForChild("Snapshot", 10)
	if not request or not snapshot then
		return
	end
	local dialog = gui.Dialog
	local waiting = gui.Waiting
	local capacity = Config.DefaultCapacity
	local friendsOnly = false
	local current = { state = "None", revision = -1 }
	local lastPartyId
	local pendingUntil = 0
	local noticeUntil = 0
	local lastNoticeId
	local previousSelection
	local screenSize = Vector2.zero

	local function updateSelection()
		for index = 1, Config.MaxPlayers do
			local button = dialog.Options["Size" .. index]
			local selected = index == capacity
			local face = button:FindFirstChild("Face")
			local lip = button:FindFirstChild("Lip")
			if face and lip then
				local num = face:FindFirstChild("Number")
				local unit = face:FindFirstChild("Unit")
				local grad = face:FindFirstChildOfClass("UIGradient")

				if selected then
					face.BackgroundColor3 = Color3.fromRGB(0, 195, 255)
					lip.BackgroundColor3 = Color3.fromRGB(0, 75, 175)
					if grad then
						grad.Enabled = true
					end
					if num then
						num.TextColor3 = Color3.fromRGB(255, 255, 255)
						local stroke = num:FindFirstChildOfClass("UIStroke")
						if stroke then
							stroke.Color = Color3.fromRGB(23, 33, 38)
							stroke.Thickness = 2.5
						end
					end
					if unit then
						unit.TextColor3 = Color3.fromRGB(255, 255, 255)
						local stroke = unit:FindFirstChildOfClass("UIStroke")
						if stroke then
							stroke.Color = Color3.fromRGB(23, 33, 38)
							stroke.Thickness = 2
						end
					end
				else
					face.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					lip.BackgroundColor3 = Color3.fromRGB(195, 212, 230)
					if grad then
						grad.Enabled = false
					end
					if num then
						num.TextColor3 = Color3.fromRGB(22, 35, 52)
						local stroke = num:FindFirstChildOfClass("UIStroke")
						if stroke then
							stroke.Color = Color3.fromRGB(255, 255, 255)
							stroke.Thickness = 1.2
						end
					end
					if unit then
						unit.TextColor3 = Color3.fromRGB(105, 128, 152)
						local stroke = unit:FindFirstChildOfClass("UIStroke")
						if stroke then
							stroke.Color = Color3.fromRGB(255, 255, 255)
							stroke.Thickness = 1.2
						end
					end
				end
				local selBadge = face:FindFirstChild("Selected")
				if selBadge then
					selBadge.Visible = selected
				end
			end
		end
		dialog.SelectedLabel.Text = string.format("%d PLAYER%s SELECTED", capacity, capacity == 1 and "" or "S")
		local toggle = dialog.Friends.Toggle
		toggle.BackgroundColor3 = if friendsOnly then Color3.fromRGB(46, 213, 115) else Color3.fromRGB(200, 214, 229)
		toggle.Knob.Position = UDim2.fromOffset(if friendsOnly then 38 else 4, 4)
		toggle:SetAttribute("Enabled", friendsOnly)
	end

	local function send(action)
		if os.clock() < pendingUntil then
			return
		end
		pendingUntil = os.clock() + 2
		request:FireServer(action, capacity, friendsOnly)
	end

	local function decorate(button)
		local face = button:FindFirstChild("Face")
		if not face then
			return
		end
		local home = face.Position
		local function animate(down)
			TweenService:Create(face, TweenInfo.new(0.09), {
				Position = home + UDim2.fromOffset(0, down and 4 or 0),
			}):Play()
		end
		button.MouseButton1Down:Connect(function()
			animate(true)
		end)
		button.MouseButton1Up:Connect(function()
			animate(false)
		end)
		button.MouseLeave:Connect(function()
			animate(false)
		end)
		button.SelectionGained:Connect(function()
			local stroke = face:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Color3.fromRGB(255, 227, 90)
			end
		end)
		button.SelectionLost:Connect(function()
			local stroke = face:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Color3.fromRGB(23, 33, 38)
			end
		end)
	end
	for _, descendant in ipairs(gui:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			decorate(descendant)
		end
	end
	for index = 1, Config.MaxPlayers do
		dialog.Options["Size" .. index].Activated:Connect(function()
			if os.clock() < pendingUntil then
				return
			end
			capacity = index
			updateSelection()
		end)
	end
	dialog.Friends.Toggle.Activated:Connect(function()
		if os.clock() < pendingUntil then
			return
		end
		friendsOnly = not friendsOnly
		updateSelection()
	end)
	dialog.Create.Activated:Connect(function()
		send("Create")
	end)
	dialog.Close.Activated:Connect(function()
		send("Cancel")
	end)
	waiting.Leave.Activated:Connect(function()
		send("Leave")
	end)

	local function apply(payload)
		if
			typeof(payload) ~= "table"
			or typeof(payload.revision) ~= "number"
			or payload.revision <= current.revision
		then
			return
		end
		local wasDialog = dialog.Visible
		current = payload
		pendingUntil = 0
		local configuring = payload.state == "Configuring" and payload.hostUserId == player.UserId
		if configuring and payload.partyId ~= lastPartyId then
			capacity = payload.capacity or Config.DefaultCapacity
			friendsOnly = payload.friendsOnly == true
			updateSelection()
		end
		lastPartyId = payload.partyId
		local overlay = gui:FindFirstChild("Overlay")
		if overlay then
			overlay.Visible = false
		end
		dialog.Visible = configuring
		waiting.Visible = payload.state == "Countdown" or payload.state == "Launching"
		waiting.Leave.Visible = true
		if configuring and not wasDialog then
			previousSelection = GuiService.SelectedObject
			if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
				GuiService.SelectedObject = dialog.Options["Size" .. capacity]
			end
		elseif wasDialog and not configuring then
			GuiService.SelectedObject = nil
		end
		if not configuring then
			local selected = GuiService.SelectedObject
			if selected and selected:IsDescendantOf(gui) then
				GuiService.SelectedObject = nil
			end
		end
		if payload.notice and payload.notice.id ~= lastNoticeId then
			lastNoticeId = payload.notice.id
			gui.Notice.Message.Text = payload.notice.text
			gui.Notice.Visible = true
			noticeUntil = os.clock() + 7
		end
	end
	snapshot.OnClientEvent:Connect(apply)
	updateSelection()
	request:FireServer("Sync")
	player.CharacterAdded:Connect(function()
		task.delay(1, function()
			request:FireServer("Sync")
		end)
	end)

	local function layout(size)
		local compact = size.Y < 620
		local height = if compact then 394 else 560
		local scale =
			math.min(DIALOG_MAX_SCALE, size.X * DIALOG_SCREEN_FILL / 650, size.Y * DIALOG_SCREEN_FILL / (height + 40))
		dialog.UIScale.Scale = math.max(0.35, scale)
		dialog.Size = UDim2.fromOffset(620, height)
		dialog.LowerLip.Size = UDim2.fromOffset(632, height + 8)
		dialog.Header.Size = UDim2.new(1, 0, 0, if compact then 80 else 108)
		dialog.Header.Title.TextSize = if compact then 34 else 40
		dialog.Header.Title.Position = UDim2.fromOffset(150, if compact then 9 else 18)
		dialog.Header.Subtitle.Position = UDim2.fromOffset(152, if compact then 53 else 69)
		dialog.SizeTitle.Position = UDim2.fromOffset(36, if compact then 91 else 132)
		dialog.SelectedLabel.Position = UDim2.fromOffset(386, if compact then 93 else 134)
		dialog.Options.Position = UDim2.fromOffset(36, if compact then 120 else 162)
		dialog.Options.Size = UDim2.fromOffset(540, if compact then 80 else 116)
		for index = 1, Config.MaxPlayers do
			local option = dialog.Options["Size" .. index]
			option.Face.Number.Position = UDim2.fromOffset(0, if compact then 5 else 20)
			option.Face.Unit.Position = UDim2.new(0, 0, 1, -30)
		end
		dialog.Friends.Position = UDim2.fromOffset(36, if compact then 214 else 302)
		dialog.Friends.Size = UDim2.fromOffset(540, if compact then 64 else 78)
		dialog.Friends.Toggle.Position = UDim2.new(1, -92, 0.5, -20)
		dialog.Friends.Description.Position = UDim2.fromOffset(74, if compact then 32 else 38)
		dialog.Create.Position = UDim2.fromOffset(36, if compact then 292 else 406)
		dialog.Create.Size = UDim2.fromOffset(540, if compact then 62 else 86)
		dialog.Footer.Position = UDim2.new(0, 36, 1, -35)
		waiting.UIScale.Scale = math.min(1, (size.X - 28) / 400)
		gui.Notice.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Notice.Position = UDim2.new(0.5, 0, if compact then 0.76 else 0.80, 0)
		gui.Notice.Size = UDim2.fromOffset(math.min(580, size.X - 32), if compact then 60 else 76)
	end
	RunService.RenderStepped:Connect(function()
		local size = gui.AbsoluteSize
		if size ~= screenSize then
			screenSize = size
			layout(size)
		end
		local pending = os.clock() < pendingUntil
		dialog.Create.Face.Label.Text = if pending then "PLEASE WAIT..." else "CREATE PARTY"
		if waiting.Visible then
			waiting.Title.Text = string.format("PARTY %d/%d", current.count or 1, current.capacity or 4)
			if current.waitingForSpawn then
				waiting.Details.Text = "Waiting for a clear spawn..."
			else
				waiting.Details.Text = string.format(
					"Starting in %ds  •  %s",
					math.max(0, math.ceil((current.deadline or 0) - workspace:GetServerTimeNow())),
					current.friendsOnly and "Friends only" or "Public"
				)
			end
		end
		if gui.Notice.Visible and os.clock() >= noticeUntil then
			gui.Notice.Visible = false
		end
	end)
end

return PartyController
