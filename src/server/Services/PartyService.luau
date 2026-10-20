local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.PartyConfig)
local CartConfig = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)
local CartService = require(script.Parent.CartService)
local CartClaimService = require(script.Parent.CartClaimService)
local Validation = require(script.Parent.CartValidationService)

local PartyService = {}
local sessions = {}
local membership = {}
local areas = {}
local checkpoints = {}
local playerConnections = {}
local admissionPending = {}
local nextAdmission = {}
local lastRequest = {}
local pendingLobby = {}
local notifications = {}
local snapshotRemote
local requestRemote
local lobbySpawn
local spawnFolder
local started = false
local revision = 0
local random = Random.new()

local function contains(part, position, inset)
	local p = part.CFrame:PointToObjectSpace(position)
	local h = part.Size * 0.5
	local margin = inset or 0
	return math.abs(p.X) <= h.X - margin and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z - margin
end

local function movePlayer(player, target)
	local root = Validation.GetCharacterRoot(player)
	if not root then
		return false
	end
	root.CFrame = target
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function publishPlayer(player)
	if player.Parent ~= Players then
		return
	end
	local session = membership[player]
	revision += 1
	local payload = { revision = revision, state = "None", notice = notifications[player] }
	if session then
		payload.partyId = session.id
		payload.state = session.state
		payload.hostUserId = session.host.UserId
		payload.capacity = session.capacity
		payload.count = #session.members
		payload.friendsOnly = session.friendsOnly
		payload.deadline = session.deadline
		payload.checkpoint = session.checkpoint
		payload.waitingForSpawn = session.waitingForSpawn
	end
	snapshotRemote:FireClient(player, payload)
end

local function notify(player, message)
	if player.Parent ~= Players then
		return
	end
	notifications[player] = { id = HttpService:GenerateGUID(false), text = message }
	publishPlayer(player)
end

local function updateArea(area)
	local session = area.session
	local locked = session ~= nil
	for _, part in ipairs(area.barriers:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = locked
			part.Transparency = if locked then 0.88 else 1
		end
	end
	area.model:SetAttribute("PartyState", session and session.state or "Idle")
	local billboard = area.model:FindFirstChild("PartyBillboard", true)
	if billboard then
		billboard.Enabled = session ~= nil and (session.state == "Countdown" or session.state == "Launching")
		if billboard.Enabled then
			billboard.Count.Text = string.format("%d/%d", #session.members, session.capacity)
			billboard.Timer.Text =
				string.format("%ds", math.max(0, math.ceil(session.deadline - workspace:GetServerTimeNow())))
		else
			billboard.Count.Text = ""
			billboard.Timer.Text = ""
		end
	end
end

local function publish(session)
	if session.area then
		updateArea(session.area)
	end
	for _, player in ipairs(session.members) do
		publishPlayer(player)
	end
end

local function returnToLobby(player, index)
	pendingLobby[player] = lobbySpawn.CFrame * CFrame.new(((index - 1) % 4 - 1.5) * 3, 4, 0)
	if movePlayer(player, pendingLobby[player]) then
		pendingLobby[player] = nil
	end
end

local function releaseArea(session)
	local area = session.area
	if area then
		area.session = nil
		session.area = nil
		updateArea(area)
	end
end

local function disband(session, message, departed, backToLobby)
	if sessions[session.id] ~= session then
		return
	end
	-- Invalidate the session BEFORE detaching/destroying. No outstanding admission,
	-- respawn or death callback can recreate a cart after this point.
	sessions[session.id] = nil
	session.state = "Disbanded"
	local area = session.area
	releaseArea(session)
	if session.cart then
		CartService.DestroyPartyCart(session.cart)
		session.cart = nil
	end
	for index, player in ipairs(session.members) do
		if membership[player] == session then
			membership[player] = nil
			player:SetAttribute("PartyId", nil)
			player:SetAttribute("PartySlot", nil)
			player:SetAttribute("PartyCheckpoint", nil)
		end
		nextAdmission[player] = os.clock() + Config.ReentryCooldown
		if player ~= departed and player.Parent == Players then
			if backToLobby or not area then
				returnToLobby(player, index)
			else
				movePlayer(player, area.exit.CFrame * CFrame.new(0, 0, (index - 1) * 2))
			end
			notify(player, message)
		end
	end
	table.clear(session.members)
end

local function leaveWaiting(player)
	local session = membership[player]
	if
		not session
		or (session.state ~= "Configuring" and session.state ~= "Countdown" and session.state ~= "Launching")
	then
		return
	end
	if session.host == player then
		disband(session, "Party dibubarkan karena host keluar dari area.")
		return
	end
	local index = table.find(session.members, player)
	if index then
		table.remove(session.members, index)
	end
	membership[player] = nil
	player:SetAttribute("PartyId", nil)
	nextAdmission[player] = os.clock() + Config.ReentryCooldown
	if session.area then
		movePlayer(player, session.area.exit.CFrame)
	end
	publishPlayer(player)
	publish(session)
end

local function placeInArea(session, player)
	local index = table.find(session.members, player) or 1
	local offset = ({ Vector3.zero, Vector3.new(0, 0, 3), Vector3.new(0, 0, -3), Vector3.new(-3, 0, 0) })[index]
	movePlayer(player, session.area.center.CFrame + offset)
end

local function eligible(player)
	return player.Parent == Players
		and not membership[player]
		and not pendingLobby[player]
		and not CartClaimService.GetActive(player)
		and Validation.GetCharacterRoot(player) ~= nil
end

local function enterArea(area, player)
	if not eligible(player) then
		return
	end
	local root = Validation.GetCharacterRoot(player)
	if not root or (not contains(area.bounds, root.Position) and not contains(area.entry, root.Position)) then
		return
	end
	local session = area.session
	if not session then
		session = {
			id = HttpService:GenerateGUID(false),
			host = player,
			members = { player },
			capacity = Config.DefaultCapacity,
			friendsOnly = false,
			state = "Configuring",
			checkpoint = 0,
			deadline = 0,
			configuredAt = os.clock(),
			area = area,
			cart = nil,
			waitingForSpawn = false,
			nextSpawnAttempt = 0,
		}
		sessions[session.id] = session
		membership[player] = session
		player:SetAttribute("PartyId", session.id)
		area.session = session
		placeInArea(session, player)
		publish(session)
		return
	end
	if session.state ~= "Countdown" or workspace:GetServerTimeNow() >= session.deadline then
		return
	end
	if #session.members >= session.capacity then
		notify(player, "Party sudah penuh.")
		nextAdmission[player] = os.clock() + Config.FriendRetryInterval
		return
	end
	if session.friendsOnly then
		if admissionPending[player] then
			return
		end
		admissionPending[player] = session.id
		task.spawn(function()
			local ok, isFriend = pcall(player.IsFriendsWithAsync, player, session.host.UserId)
			if admissionPending[player] ~= session.id then
				return
			end
			admissionPending[player] = nil
			nextAdmission[player] = os.clock() + Config.FriendRetryInterval
			-- Friend lookups yield. Revalidate every admission condition afterwards.
			local currentRoot = Validation.GetCharacterRoot(player)
			if
				sessions[session.id] ~= session
				or area.session ~= session
				or not eligible(player)
				or session.state ~= "Countdown"
				or workspace:GetServerTimeNow() >= session.deadline
				or #session.members >= session.capacity
				or not currentRoot
				or (not contains(area.entry, currentRoot.Position) and not contains(area.bounds, currentRoot.Position))
			then
				return
			end
			if not ok or not isFriend then
				notify(
					player,
					if ok then "Party ini hanya untuk teman host." else "Pertemanan belum dapat diperiksa. Coba lagi."
				)
				return
			end
			table.insert(session.members, player)
			membership[player] = session
			player:SetAttribute("PartyId", session.id)
			placeInArea(session, player)
			publish(session)
		end)
	else
		table.insert(session.members, player)
		membership[player] = session
		player:SetAttribute("PartyId", session.id)
		placeInArea(session, player)
		publish(session)
	end
end

local function restart(session)
	if sessions[session.id] ~= session or session.state ~= "Running" then
		return
	end
	session.state = "Restarting"
	session.restartAt = os.clock() + CartConfig.CartRespawnDelay
	session.readyUntil = session.restartAt + Config.CharacterReadyTimeout
	session.nextSpawnAttempt = session.restartAt
	session.waitingForSpawn = false
	-- Set Restarting first: explosion/character events may re-enter this handler.
	CartService.ExplodePartyCart(session.cart)
	for _, player in ipairs(session.members) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
		notify(
			player,
			"Party mengulang di "
				.. (session.checkpoint > 0 and ("Checkpoint " .. session.checkpoint) or "Party Spawn")
				.. "."
		)
	end
	publish(session)
end

local function spawnClear(position, session)
	for _, model in ipairs(CollectionService:GetTagged(Constants.Tag)) do
		local root = model:IsA("Model") and model:FindFirstChild(Constants.PhysicsRoot)
		if
			root
			and model:IsDescendantOf(workspace)
			and not model:GetAttribute("Exploded")
			and (not session.cart or model ~= session.cart.model)
		then
			local delta = root.Position - position
			if Vector3.new(delta.X, 0, delta.Z).Magnitude < Config.SpawnClearRadius and math.abs(delta.Y) < 12 then
				return false
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local root = Validation.GetCharacterRoot(player)
		if root and membership[player] ~= session and (root.Position - position).Magnitude < 9 then
			return false
		end
	end
	return true
end

local function chooseSpawn(session)
	if session.checkpoint > 0 then
		local cp = checkpoints[session.checkpoint]
		if not cp or not cp.Parent then
			return nil
		end
		-- Centre and four corners stay on the existing 34x33 checkpoint rock.
		for _, offset in ipairs({
			Vector3.zero,
			Vector3.new(-8, 0, -8),
			Vector3.new(8, 0, 8),
			Vector3.new(-8, 0, 8),
			Vector3.new(8, 0, -8),
		}) do
			local cf = cp.CFrame * CFrame.new(offset + Vector3.new(0, cp.Size.Y / 2 + 1.2, 0))
			if spawnClear(cf.Position, session) then
				return cf
			end
		end
		return nil
	end
	local candidates = {}
	for _, part in ipairs(spawnFolder:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(candidates, part)
		end
	end
	while #candidates > 0 do
		local part = table.remove(candidates, random:NextInteger(1, #candidates))
		local cf = part.CFrame * CFrame.new(0, part.Size.Y / 2 + 1.2, 0)
		if spawnClear(cf.Position, session) then
			return cf
		end
	end
	return nil
end

local function launch(session)
	if os.clock() < session.nextSpawnAttempt then
		return
	end
	session.nextSpawnAttempt = os.clock() + Config.SpawnRetryInterval
	for _, player in ipairs(session.members) do
		if player.Parent ~= Players then
			disband(session, "Party dibubarkan karena " .. player.DisplayName .. " keluar dari game.", player, true)
			return
		end
		if not Validation.GetCharacterRoot(player) then
			return
		end
	end
	local spawnCFrame = chooseSpawn(session)
	if not spawnCFrame then
		if not session.waitingForSpawn then
			session.waitingForSpawn = true
			publish(session)
		end
		return
	end
	local oldCart = session.cart
	session.cart = nil
	if oldCart then
		CartService.DestroyPartyCart(oldCart)
	end
	-- No yields from placement through attach: other parties see the created cart
	-- before they choose their destination.
	for slot, player in ipairs(session.members) do
		movePlayer(player, spawnCFrame * CFrame.new(Config.MemberOffsets[slot]))
	end
	local record, reason = CartService.CreatePartyCart(session.id, session.members, spawnCFrame)
	if not record then
		disband(session, reason or "Party tidak dapat dimulai. Silakan coba lagi.", nil, true)
		return
	end
	session.cart = record
	session.state = "Running"
	session.waitingForSpawn = false
	session.previousPositions = {}
	for _, player in ipairs(session.members) do
		player:SetAttribute("PartyCheckpoint", session.checkpoint)
		local root = Validation.GetCharacterRoot(player)
		session.previousPositions[player] = root and root.Position
	end
	releaseArea(session)
	publish(session)
end

local function checkpointContains(part, position)
	local p = part.CFrame:PointToObjectSpace(position)
	return math.abs(p.X) <= part.Size.X / 2
		and math.abs(p.Z) <= part.Size.Z / 2
		and p.Y >= -2
		and p.Y <= Config.CheckpointHeight
end

local function updateCheckpoint(session)
	local target = checkpoints[session.checkpoint + 1]
	if not target then
		return
	end
	local cartRoot = session.cart and session.cart.root
	local reached = cartRoot and checkpointContains(target, cartRoot.Position)
	for _, player in ipairs(session.members) do
		local root = Validation.GetCharacterRoot(player)
		if root then
			local previous = session.previousPositions[player]
			-- Do not award a checkpoint from an implausible character jump.
			local plausible = not previous or (root.Position - previous).Magnitude <= CartConfig.MaxReleaseDistance
			if
				plausible
				and checkpointContains(target, root.Position)
				and cartRoot
				and (root.Position - cartRoot.Position).Magnitude <= CartConfig.MaxReleaseDistance + 4
			then
				reached = true
			end
			session.previousPositions[player] = root.Position
		end
	end
	if reached then
		session.checkpoint += 1
		for _, player in ipairs(session.members) do
			player:SetAttribute("PartyCheckpoint", session.checkpoint)
			notify(player, "Checkpoint " .. session.checkpoint .. " tersimpan untuk seluruh party!")
		end
		publish(session)
	end
end

local function characterLost(player)
	local session = membership[player]
	if not session then
		return
	end
	if session.state == "Running" then
		restart(session)
	elseif session.state ~= "Restarting" then
		leaveWaiting(player)
	end
end

local function bindPlayer(player)
	local connections = {}
	playerConnections[player] = connections
	local deathConnection
	local function characterAdded(character)
		if deathConnection then
			deathConnection:Disconnect()
			deathConnection = nil
		end
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if player.Parent ~= Players or player.Character ~= character or not humanoid then
				return
			end
			deathConnection = humanoid.Died:Connect(function()
				characterLost(player)
			end)
		end)
	end
	table.insert(connections, player.CharacterAdded:Connect(characterAdded))
	table.insert(
		connections,
		player.CharacterRemoving:Connect(function()
			if deathConnection then
				deathConnection:Disconnect()
				deathConnection = nil
			end
			local session = membership[player]
			task.delay(0.1, function()
				if player.Parent == Players and session and membership[player] == session then
					characterLost(player)
				end
			end)
		end)
	)
	table.insert(connections, function()
		if deathConnection then
			deathConnection:Disconnect()
		end
	end)
	if player.Character then
		characterAdded(player.Character)
	end
end

local function onRequest(player, action, capacity, friendsOnly)
	local now = os.clock()
	if typeof(action) ~= "string" or now - (lastRequest[player] or -math.huge) < Config.RequestInterval then
		return
	end
	lastRequest[player] = now
	if action == "Sync" then
		publishPlayer(player)
		return
	end
	local session = membership[player]
	if not session then
		return
	end
	if action == "Leave" or action == "Cancel" then
		leaveWaiting(player)
	elseif action == "Create" then
		if session.state ~= "Configuring" or session.host ~= player then
			return
		end
		if
			typeof(capacity) ~= "number"
			or capacity ~= capacity
			or capacity % 1 ~= 0
			or capacity < 1
			or capacity > Config.MaxPlayers
			or typeof(friendsOnly) ~= "boolean"
		then
			notify(player, "Pengaturan party tidak valid.")
			return
		end
		local root = Validation.GetCharacterRoot(player)
		if not root or not contains(session.area.bounds, root.Position) then
			return
		end
		session.capacity = capacity
		session.friendsOnly = friendsOnly
		session.state = "Countdown"
		session.deadline = workspace:GetServerTimeNow() + Config.CountdownSeconds
		publish(session)
	end
end

function PartyService.Start()
	if started then
		return
	end
	local design = workspace:FindFirstChild("PartyDesign")
	local lobby = workspace:FindFirstChild("LobbyEnvirontment")
	spawnFolder = lobby and lobby:FindFirstChild("PartySpawn")
	lobbySpawn = lobby and lobby:FindFirstChild("LobbySpawn", true)
	if not design or not spawnFolder or not lobbySpawn then
		warn("PartyService: PartyDesign, PartySpawn atau LobbySpawn belum tersedia.")
		return
	end
	for _, model in ipairs(design:GetChildren()) do
		local bounds = model:FindFirstChild("PartyBounds01")
		local entry = model:FindFirstChild("PartyEntry")
		local center = model:FindFirstChild("PartyCenter")
		local exit = model:FindFirstChild("PartyExit")
		local barriers = model:FindFirstChild("PartyBarriers")
		if bounds and entry and center and exit and barriers then
			table.insert(
				areas,
				{ model = model, bounds = bounds, entry = entry, center = center, exit = exit, barriers = barriers }
			)
		else
			warn("PartyService: area belum disiapkan:", model:GetFullName())
		end
	end
	table.sort(areas, function(a, b)
		return a.model.Name < b.model.Name
	end)
	local checkpointFolder = workspace:FindFirstChild("CheckPoint")
	if checkpointFolder then
		for _, model in ipairs(checkpointFolder:GetChildren()) do
			local index = tonumber(model.Name:match("^Checkpoint(%d+)$"))
			local spawn = model:FindFirstChild("CheckpointSpawn")
			if index and spawn and spawn:IsA("BasePart") then
				checkpoints[index] = spawn
			end
		end
	end
	started = true
	local remotes = Instance.new("Folder")
	remotes.Name = Config.RemoteFolder
	requestRemote = Instance.new("RemoteEvent")
	requestRemote.Name = "Request"
	requestRemote.Parent = remotes
	snapshotRemote = Instance.new("RemoteEvent")
	snapshotRemote.Name = "Snapshot"
	snapshotRemote.Parent = remotes
	remotes.Parent = ReplicatedStorage
	requestRemote.OnServerEvent:Connect(onRequest)
	CartService.SetPartyFailureHandler(function(id)
		local session = sessions[id]
		if session then
			restart(session)
		end
	end)
	for _, area in ipairs(areas) do
		updateArea(area)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local session = membership[player]
		if session then
			if session.state == "Running" or session.state == "Restarting" or session.state == "Launching" then
				disband(
					session,
					"Party dibubarkan karena " .. player.DisplayName .. " keluar dari game. Kamu dikembalikan ke lobby.",
					player,
					true
				)
			elseif session.host == player then
				disband(session, "Party dibubarkan karena host keluar dari game.", player)
			else
				leaveWaiting(player)
			end
		end
		for _, connection in ipairs(playerConnections[player] or {}) do
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			else
				connection()
			end
		end
		playerConnections[player] = nil
		admissionPending[player] = nil
		nextAdmission[player] = nil
		lastRequest[player] = nil
		pendingLobby[player] = nil
		notifications[player] = nil
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < Config.TickInterval then
			return
		end
		elapsed = 0
		local now = os.clock()
		for player, target in pairs(pendingLobby) do
			if player.Parent ~= Players or movePlayer(player, target) then
				pendingLobby[player] = nil
			end
		end
		for _, session in pairs(sessions) do
			if session.state == "Configuring" and now - session.configuredAt >= Config.ConfigureTimeout then
				disband(session, "Pengaturan party dibatalkan karena terlalu lama.")
			elseif session.state == "Countdown" and workspace:GetServerTimeNow() >= session.deadline then
				session.state = "Launching"
				launch(session)
			elseif session.state == "Launching" then
				launch(session)
			elseif session.state == "Restarting" and now >= session.restartAt then
				if now > session.readyUntil and not session.waitingForSpawn then
					disband(session, "Party dibubarkan karena anggota belum siap respawn.", nil, true)
				else
					launch(session)
				end
			elseif session.state == "Running" then
				if not session.cart or not session.cart.model:IsDescendantOf(workspace) then
					restart(session)
				else
					updateCheckpoint(session)
				end
			end
			if session.area then
				updateArea(session.area)
				for _, player in ipairs(session.members) do
					local root = Validation.GetCharacterRoot(player)
					if root and not contains(session.area.bounds, root.Position, 0.5) then
						placeInArea(session, player)
					end
				end
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if eligible(player) and now >= (nextAdmission[player] or 0) and not admissionPending[player] then
				local root = Validation.GetCharacterRoot(player)
				for _, area in ipairs(areas) do
					if contains(area.bounds, root.Position) or contains(area.entry, root.Position) then
						enterArea(area, player)
						if not membership[player] and contains(area.bounds, root.Position) then
							movePlayer(player, area.exit.CFrame)
						end
						break
					end
				end
			end
		end
	end)
end

return PartyService
