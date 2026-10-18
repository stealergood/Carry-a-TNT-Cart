local Config = require(game.ReplicatedStorage.Shared.CartConfig)
local Constants = require(game.ReplicatedStorage.Shared.CartConstants)
local CartPhysicsService = require(script.Parent.CartPhysicsService)
local CartValidationService = require(script.Parent.CartValidationService)

local CartClaimService = {}
local activeByPlayer = {}
local setState

local function disconnectAll(connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

function CartClaimService.Start(stateSetter)
	setState = stateSetter
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

	local characterRoot, humanoid = CartValidationService.GetCharacterRoot(player)
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
		humanoid.Died:Connect(function()
			CartClaimService.Release(record)
		end)
	)
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
	return true
end

function CartClaimService.Release(record)
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
end

return CartClaimService
