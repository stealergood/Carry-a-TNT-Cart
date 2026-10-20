local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.PartyConfig)

local PartyController = {}
local player = Players.LocalPlayer
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
			button.Face.BackgroundColor3 = if selected then Color3.fromRGB(45, 183, 243) else Color3.fromRGB(49, 65, 81)
			button.Lip.BackgroundColor3 = if selected then Color3.fromRGB(8, 124, 185) else Color3.fromRGB(27, 38, 49)
			button.Face.Selected.Visible = selected
		end
		dialog.SelectedLabel.Text = string.format("%d PLAYER%s SELECTED", capacity, capacity == 1 and "" or "S")
		local toggle = dialog.Friends.Toggle
		toggle.BackgroundColor3 = if friendsOnly then Color3.fromRGB(45, 203, 101) else Color3.fromRGB(49, 65, 81)
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
		gui.Overlay.Visible = configuring
		dialog.Visible = configuring
		waiting.Visible = payload.state == "Countdown" or payload.state == "Launching" or payload.state == "Restarting"
		waiting.Leave.Visible = payload.state ~= "Restarting"
		if configuring and not wasDialog then
			previousSelection = GuiService.SelectedObject
			if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
				GuiService.SelectedObject = dialog.Options["Size" .. capacity]
			end
		elseif wasDialog and not configuring then
			GuiService.SelectedObject = if waiting.Visible and waiting.Leave.Visible
				then waiting.Leave
				else previousSelection
		end
		if not configuring and (not waiting.Visible or not waiting.Leave.Visible) then
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
		local scale = math.min(1, (size.X - 28) / 650, (size.Y - 26) / (height + 40))
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
		gui.Notice.Size = UDim2.fromOffset(math.min(580, size.X - 32), 76)
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
			waiting.Title.Text = if current.state == "Restarting"
				then "RESTARTING PARTY"
				else string.format("PARTY %d/%d", current.count or 1, current.capacity or 4)
			if current.state == "Restarting" then
				waiting.Details.Text = if (current.checkpoint or 0) > 0
					then "Respawn at Checkpoint " .. current.checkpoint
					else "Respawn at Party Spawn"
			elseif current.waitingForSpawn then
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
