local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.CartConfig)
local Constants = require(game.ReplicatedStorage.Shared.CartConstants)
local CartPhysicsService = require(script.Parent.CartPhysicsService)
local CartValidationService = require(script.Parent.CartValidationService)

local CartClaimService = {}
local activeByPlayer = {}
local deathCartByPlayer = {}
local deathOwnerByRecord = {}
local characterConnections = {}
local deathConnections = {}
local setState
local onPlayerDied

local function disconnectAll(connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function clearDeathBinding(record)
	local player = deathOwnerByRecord[record]
	if player and deathCartByPlayer[player] == record then
		deathCartByPlayer[player] = nil
	end
	deathOwnerByRecord[record] = nil
end

local function bindDeathCart(record, player)
	local previousRecord = deathCartByPlayer[player]
	if previousRecord and previousRecord ~= record then
		clearDeathBinding(previousRecord)
	end
	local previousPlayer = deathOwnerByRecord[record]
	if previousPlayer and previousPlayer ~= player then
		deathCartByPlayer[previousPlayer] = nil
	end
	deathCartByPlayer[player] = record
	deathOwnerByRecord[record] = player
end

local function bindCharacter(player, character)
	local oldConnection = deathConnections[player]
	if oldConnection then
		oldConnection:Disconnect()
		deathConnections[player] = nil
	end
	task.spawn(function()
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
		if
			player.Parent ~= Players
			or player.Character ~= character
			or not humanoid
			or not humanoid:IsA("Humanoid")
		then
			return
		end
		deathConnections[player] = humanoid.Died:Connect(function()
			local record = deathCartByPlayer[player]
			if not record then
				return
			end
			clearDeathBinding(record)
			if onPlayerDied then
				onPlayerDied(record, player)
			end
		end)
	end)
end

local function bindPlayer(player)
	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)
	if player.Character then
		bindCharacter(player, player.Character)
	end
end

function CartClaimService.Start(stateSetter, playerDiedCallback)
	setState = stateSetter
	onPlayerDied = playerDiedCallback
	Players.PlayerAdded:Connect(bindPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end
end

function CartClaimService.GetActive(player)
	return activeByPlayer[player]
end

function CartClaimService.Claim(record, player)
	local now = os.clock()
	if now - record.lastClaim < Config.ClaimCooldown then
		return false
	end
	if not CartValidationService.CanClaim(record, player, activeByPlayer) then
		return false
	end
	record.lastClaim = now
	setState(record, Constants.States.Claiming)
	activeByPlayer[player] = record
	record.puller = player

	local characterRoot = CartValidationService.GetCharacterRoot(player)
	if not characterRoot then
		CartClaimService.Release(record)
		return false
	end

	local hand = Instance.new("Attachment")
	hand.Name = Constants.HandAttachment
	hand.Position = Vector3.new(0, 0, -1)
	hand.Parent = characterRoot

	local rope = Instance.new("RopeConstraint")
	rope.Name = Constants.Rope
	rope.Attachment0 = record.root:FindFirstChild(Constants.PullAttachment)
	rope.Attachment1 = hand
	rope.Length = Config.RopeMaxLength
	rope.Thickness = Config.RopeThickness
	rope.Visible = false
	rope.Restitution = 0
	rope.Parent = record.root

	local beam = Instance.new("Beam")
	beam.Name = Constants.Beam
	beam.Attachment0 = record.root:FindFirstChild(Constants.PullAttachment)
	beam.Attachment1 = hand
	beam.FaceCamera = true
	beam.Width0 = Config.RopeThickness
	beam.Width1 = Config.RopeThickness
	beam.Segments = 10
	beam.LightEmission = 0
	beam.Color = ColorSequence.new(Color3.fromRGB(143, 111, 74))
	beam.Parent = record.root

	record.handAttachment = hand
	record.rope = rope
	record.beam = beam
	record.lastPosition = record.root.Position
	record.lastCheck = now
	record.windowStartPosition = record.root.Position
	record.windowStartTime = now

	local activeValue = player:FindFirstChild(Constants.ActiveCartValue)
	if not activeValue then
		activeValue = Instance.new("ObjectValue")
		activeValue.Name = Constants.ActiveCartValue
		activeValue.Parent = player
	end
	activeValue.Value = record.model

	table.insert(
		record.claimConnections,
		player.CharacterRemoving:Connect(function()
			CartClaimService.Release(record)
		end)
	)

	if not CartPhysicsService.SetOwner(record.root, player) then
		CartClaimService.Release(record)
		return false
	end
	setState(record, Constants.States.Pulling)
	bindDeathCart(record, player)
	return true
end

function CartClaimService.ClearDeathBinding(record)
	clearDeathBinding(record)
end

-- All-or-nothing, server-only attach after PartyService has positioned the crew.
function CartClaimService.AttachParty(record, members)
	local PartyConfig = require(game.ReplicatedStorage.Shared.PartyConfig)
	if
		not record.partyId
		or record.state ~= Constants.States.Idle
		or #members < 1
		or #members > PartyConfig.MaxPlayers
	then
		return false
	end
	for _, player in ipairs(members) do
		if
			activeByPlayer[player]
			or player:GetAttribute("PartyId") ~= record.partyId
			or not CartValidationService.GetCharacterRoot(player)
		then
			return false
		end
	end
	setState(record, Constants.States.Claiming)
	record.participants = {}
	for slot, player in ipairs(members) do
		local previousDeathCart = deathCartByPlayer[player]
		if previousDeathCart then
			clearDeathBinding(previousDeathCart)
		end
		local characterRoot = CartValidationService.GetCharacterRoot(player)
		local attachment = record.root:FindFirstChild(PartyConfig.AttachmentNames[slot])
		if not characterRoot or not attachment then
			CartClaimService.Release(record)
			return false
		end
		local hand = Instance.new("Attachment")
		hand.Name = Constants.HandAttachment
		hand.Position = Vector3.new(0, 0, -1)
		hand.Parent = characterRoot
		local rope = Instance.new("RopeConstraint")
		rope.Name = Constants.Rope
		rope.Attachment0 = attachment
		rope.Attachment1 = hand
		rope.Length = Config.RopeMaxLength
		rope.Thickness = Config.RopeThickness
		rope.Visible = false
		rope.Restitution = 0
		rope.Parent = record.root
		local beam = Instance.new("Beam")
		beam.Name = Constants.Beam
		beam.Attachment0 = attachment
		beam.Attachment1 = hand
		beam.FaceCamera = true
		beam.Width0 = Config.RopeThickness
		beam.Width1 = Config.RopeThickness
		beam.Segments = 10
		beam.Color = ColorSequence.new(Color3.fromRGB(143, 111, 74))
		beam.Parent = record.root
		table.insert(record.participants, {
			player = player,
			slot = slot,
			handAttachment = hand,
			attachment = attachment,
			rope = rope,
			beam = beam,
		})
		activeByPlayer[player] = record
		player:SetAttribute("PartySlot", slot)
		local active = Instance.new("ObjectValue")
		active.Name = Constants.ActiveCartValue
		active.Value = record.model
		active.Parent = player
	end
	if not CartPhysicsService.SetOwner(record.root, nil) then
		CartClaimService.Release(record)
		return false
	end
	setState(record, Constants.States.Pulling)
	return true
end

function CartClaimService.Release(record)
	if record.partyId then
		for _, member in ipairs(record.participants or {}) do
			if activeByPlayer[member.player] == record then
				activeByPlayer[member.player] = nil
				local active = member.player:FindFirstChild(Constants.ActiveCartValue)
				if active then
					active:Destroy()
				end
				member.player:SetAttribute("PartySlot", nil)
			end
			member.rope:Destroy()
			member.beam:Destroy()
			member.handAttachment:Destroy()
		end
		record.participants = {}
		CartPhysicsService.StopPullDrive(record)
		if record.state ~= Constants.States.Disabled then
			setState(record, Constants.States.Idle)
		end
		return
	end
	if
		record.state == Constants.States.Idle
		or record.state == Constants.States.Releasing
		or record.state == Constants.States.Disabled
	then
		return
	end
	setState(record, Constants.States.Releasing)
	local player = record.puller
	if player and activeByPlayer[player] == record then
		activeByPlayer[player] = nil
		local activeValue = player:FindFirstChild(Constants.ActiveCartValue)
		if activeValue then
			activeValue:Destroy()
		end
	end
	record.puller = nil
	CartPhysicsService.StopPullDrive(record)
	disconnectAll(record.claimConnections)
	if record.beam then
		record.beam:Destroy()
	end
	if record.rope then
		record.rope:Destroy()
	end
	if record.handAttachment then
		record.handAttachment:Destroy()
	end
	record.beam = nil
	record.rope = nil
	record.handAttachment = nil
	if record.root.Parent and not record.root.Anchored then
		CartPhysicsService.SetIdleOwnership(record.root)
		CartPhysicsService.ClampMotion(record.root, Config.MaxPushSpeed)
	end
	record.lastPosition = record.root.Position
	record.lastCheck = os.clock()
	record.windowStartPosition = record.root.Position
	record.windowStartTime = record.lastCheck
	setState(record, Constants.States.Idle)
end

function CartClaimService.ReleasePlayer(player)
	local record = activeByPlayer[player]
	if record then
		CartClaimService.Release(record)
	end
	local deathRecord = deathCartByPlayer[player]
	if deathRecord then
		clearDeathBinding(deathRecord)
	end
	local characterConnection = characterConnections[player]
	if characterConnection then
		characterConnection:Disconnect()
		characterConnections[player] = nil
	end
	local deathConnection = deathConnections[player]
	if deathConnection then
		deathConnection:Disconnect()
		deathConnections[player] = nil
	end
end

return CartClaimService
