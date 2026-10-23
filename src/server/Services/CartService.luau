local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)
local CartTypes = require(ReplicatedStorage.Shared.CartTypes)
type CartRecord = CartTypes.CartRecord
type CartState = CartTypes.CartState
local CollisionGroupSetup = require(script.Parent.Parent.Setup.CollisionGroupSetup)
local CartClaimService = require(script.Parent.CartClaimService)
local CartHealthService = require(script.Parent.CartHealthService)
local MudObstacleService = require(script.Parent.MudObstacleService)
local CartPhysicsService = require(script.Parent.CartPhysicsService)
local CartRespawnService = require(script.Parent.CartRespawnService)
local CartValidationService = require(script.Parent.CartValidationService)

local CartService = {}
local records: { [Model]: CartRecord } = {}
local started = false
local partyFailureHandler

local function getLiveCharacterRoot(player: Player, timeout: number): (BasePart?, Humanoid?)
	local deadline = os.clock() + timeout
	repeat
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and characterRoot and characterRoot:IsA("BasePart") then
			return characterRoot, humanoid
		end
		task.wait(0.1)
	until player.Parent ~= Players or os.clock() >= deadline
	return nil, nil
end

local function setState(record: CartRecord, state: CartState)
	record.state = state
	record.model:SetAttribute("CartState", state)
	record.model:SetAttribute("IsOccupied", state == Constants.States.Pulling or state == Constants.States.Claiming)
	record.model:SetAttribute("PullerUserId", record.puller and record.puller.UserId or 0)
	record.prompt.Enabled = not record.partyId and state == Constants.States.Idle
end

local function unregister(model)
	local record = records[model]
	if not record then
		return
	end
	CartClaimService.Release(record)
	setState(record, Constants.States.Disabled)
	for _, connection in ipairs(record.connections) do
		connection:Disconnect()
	end
	table.clear(record.connections)
	records[model] = nil
end

local function register(model)
	if records[model] or not model:IsA("Model") or not model:IsDescendantOf(workspace) then
		return
	end
	local root, reason = CartPhysicsService.Prepare(model)
	if not root then
		warn("Cart gagal disiapkan:", model:GetFullName(), reason)
		return
	end
	local currentId = model:GetAttribute("CartId")
	local duplicateId = false
	for otherModel in pairs(records) do
		if otherModel:GetAttribute("CartId") == currentId then
			duplicateId = true
			break
		end
	end
	if not currentId or duplicateId then
		model:SetAttribute("CartId", HttpService:GenerateGUID(false))
	end
	local staleRope = root:FindFirstChild(Constants.Rope)
	if staleRope then
		staleRope:Destroy()
	end
	local staleBeam = root:FindFirstChild(Constants.Beam)
	if staleBeam then
		staleBeam:Destroy()
	end

	local pullAttachment = root:FindFirstChild(Constants.PullAttachment)
	local prompt = pullAttachment:FindFirstChild(Constants.Prompt) or root:FindFirstChild(Constants.Prompt)
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = Constants.Prompt
	end
	prompt.Parent = pullAttachment
	prompt.ActionText = "Tarik Gerobak"
	prompt.ObjectText = "Gerobak TNT"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.MaxClaimDistance
	prompt.RequiresLineOfSight = false

	local now = os.clock()
	local partyId = model:GetAttribute("PartyId")
	local record = {
		partyId = partyId,
		participants = if partyId then {} else nil,
		model = model,
		root = root,
		prompt = prompt,
		state = Constants.States.Idle,
		puller = nil,
		beam = nil,
		handAttachment = nil,
		connections = {},
		claimConnections = {},
		lastPosition = root.Position,
		lastCFrame = root.CFrame,
		lastCheck = now,
		lastClaim = -math.huge,
		exploded = false,
		respawnScheduled = false,
		respawnTemplate = if partyId then nil else CartRespawnService.CreateTemplate(model),
		respawnOwnerUserId = nil,
		spawnCFrame = model:GetPivot(),
		activeDamageParts = {},
		windowStartPosition = root.Position,
		windowStartTime = now,
	}
	records[model] = record
	setState(record, Constants.States.Idle)
	CartPhysicsService.SetIdleOwnership(root)
	CartHealthService.Setup(record)

	local ownerUserId = model:GetAttribute("RespawnOwnerUserId")
	if typeof(ownerUserId) == "number" then
		model:SetAttribute("RespawnOwnerUserId", nil)
		task.spawn(function()
			local player = Players:GetPlayerByUserId(ownerUserId)
			if not player or not record.model.Parent then
				return
			end
			local characterRoot = getLiveCharacterRoot(player, 10)
			if not characterRoot or not record.model.Parent then
				return
			end

			local targetPosition = characterRoot.CFrame:PointToWorldSpace(Config.RespawnCartOffset)
			record.root.CFrame = CFrame.new(targetPosition) * characterRoot.CFrame.Rotation
			record.root.AssemblyLinearVelocity = Vector3.zero
			record.root.AssemblyAngularVelocity = Vector3.zero
			record.lastPosition = record.root.Position
			record.lastCFrame = record.root.CFrame
			record.lastCheck = os.clock()
			record.windowStartPosition = record.root.Position
			record.windowStartTime = record.lastCheck
			CartClaimService.Claim(record, player)
		end)
	end

	table.insert(
		record.connections,
		prompt.Triggered:Connect(function(player)
			CartClaimService.Claim(record, player)
		end)
	)
	table.insert(
		record.connections,
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(workspace) then
				unregister(model)
			end
		end)
	)
end

local function validateRecord(record, now)
	if record.exploded then
		return
	end
	local root = record.root
	if record.partyId then
		local valid, reason = CartValidationService.CheckActive(record)
		if not valid or CartValidationService.IsTeleport(record, now, Config.HardMaxCartSpeed) then
			if partyFailureHandler then
				partyFailureHandler(record.partyId, reason or "cart moved too far")
			end
			return
		end
		CartPhysicsService.ClampMotion(root, Config.HardMaxCartSpeed)
		record.lastPosition = root.Position
		record.lastCFrame = root.CFrame
		record.lastCheck = now
		if now - record.windowStartTime >= Config.ValidationWindow then
			record.windowStartPosition = root.Position
			record.windowStartTime = now
		end
		return
	end
	if not root.Parent or root.Anchored then
		CartClaimService.Release(record)
		setState(record, Constants.States.Disabled)
		return
	end
	if record.state == Constants.States.Disabled then
		setState(record, Constants.States.Idle)
		CartPhysicsService.SetIdleOwnership(root)
	end
	if record.state == Constants.States.Pulling then
		local valid = CartValidationService.CheckActive(record)
		if not valid then
			CartClaimService.Release(record)
		end
	end
	local maxSpeed = record.state == Constants.States.Pulling and Config.HardMaxCartSpeed or Config.HardMaxPushSpeed
	if CartValidationService.IsTeleport(record, now, maxSpeed) then
		CartClaimService.Release(record)
		CartPhysicsService.SetOwner(root, nil)
		root.CFrame = record.lastCFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	else
		local velocity = root.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		if horizontalSpeed > maxSpeed + Config.MaxSpeedSlack then
			CartClaimService.Release(record)
		end
		CartPhysicsService.ClampMotion(root, maxSpeed)
	end
	record.lastPosition = root.Position
	record.lastCFrame = root.CFrame
	record.lastCheck = now
	if now - record.windowStartTime >= Config.ValidationWindow then
		record.windowStartPosition = root.Position
		record.windowStartTime = now
	end
end

function CartService.SetPartyFailureHandler(callback)
	partyFailureHandler = callback
end

function CartService.CreatePartyCart(partyId: string, members: { Player }, spawnCFrame: CFrame)
	local PartyConfig = require(ReplicatedStorage.Shared.PartyConfig)
	local template = game:GetService("ServerStorage"):FindFirstChild(PartyConfig.TemplateName)
	if not template or not template:IsA("Model") then
		return nil, "Template cart party tidak tersedia."
	end
	local model = template:Clone()
	model.Name = "PartyCart"
	model:SetAttribute("PartyId", partyId)
	model:SetAttribute("CartId", nil)
	model:SetAttribute("Exploded", nil)
	model:SetAttribute("RespawnOwnerUserId", nil)
	CollectionService:RemoveTag(model, Constants.Tag)
	model:PivotTo(spawnCFrame)
	model.Parent = workspace
	register(model)
	local record = records[model]
	if not record then
		model:Destroy()
		return nil, "Cart tidak dapat disiapkan."
	end
	CollectionService:AddTag(model, Constants.Tag)
	record.root.AssemblyLinearVelocity = Vector3.zero
	record.root.AssemblyAngularVelocity = Vector3.zero
	if not CartClaimService.AttachParty(record, members) then
		unregister(model)
		model:Destroy()
		return nil, "Anggota belum siap dihubungkan."
	end
	return record, nil
end

function CartService.DestroyPartyCart(record)
	if not record or not record.partyId then
		return
	end
	record.exploded = true
	record.respawnScheduled = true
	CartClaimService.ClearDeathBinding(record)
	unregister(record.model)
	record.model:Destroy()
	for _, child in ipairs(workspace:GetChildren()) do
		if child:GetAttribute("PartyEffectsId") == record.partyId then
			child:Destroy()
		end
	end
end

function CartService.ExplodePartyCart(record)
	if record and record.partyId and record.model.Parent and not record.exploded then
		CartHealthService.Explode(record)
	end
end

function CartService.Start()
	if started then
		return
	end
	started = true
	CollisionGroupSetup.Start()
	local function onPlayerDied(record: CartRecord, player: Player)
		if record.exploded then
			return
		end
		record.respawnOwnerUserId = player.UserId
		if record.model.Parent and record.root.Parent then
			CartHealthService.Explode(record)
		else
			record.exploded = true
			CartRespawnService.Schedule(record, player.UserId)
		end
	end

	CartClaimService.Start(setState, onPlayerDied)
	CartHealthService.Start(function(record)
		CartClaimService.ClearDeathBinding(record)
		CartClaimService.Release(record)
		setState(record, Constants.States.Disabled)
		CartPhysicsService.SetOwner(record.root, nil)
		if record.partyId then
			if partyFailureHandler then
				partyFailureHandler(record.partyId, "cart exploded")
			end
		else
			CartRespawnService.Schedule(record, record.respawnOwnerUserId)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		CartClaimService.ReleasePlayer(player)
	end)

	CollectionService:GetInstanceAddedSignal(Constants.Tag):Connect(register)
	CollectionService:GetInstanceRemovedSignal(Constants.Tag):Connect(unregister)
	for _, model in ipairs(CollectionService:GetTagged(Constants.Tag)) do
		register(model)
	end
	MudObstacleService.Start(function(model: Model): CartRecord?
		return records[model]
	end)
	local defaultCart = workspace:FindFirstChild("Minecart_Default_TNT")
	if defaultCart and defaultCart:IsA("Model") and not CollectionService:HasTag(defaultCart, Constants.Tag) then
		CollectionService:AddTag(defaultCart, Constants.Tag)
	end

	local validationElapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		for _, record in pairs(records) do
			CartHealthService.Update(record)
			if record.partyId and record.state == Constants.States.Pulling and not record.exploded then
				CartPhysicsService.UpdatePartyDrive(record)
			elseif record.state == Constants.States.Idle and not record.partyId then
				CartPhysicsService.UpdatePushDrive(record.root)
				CartPhysicsService.UpdateMotionResistance(record.root, Config.MaxPushSpeed, true)
				local pushDrive = record.root:FindFirstChild(Constants.PushDrive)
				CartPhysicsService.UpdateSteering(
					record.root,
					pushDrive and pushDrive:IsA("VectorForce") and pushDrive.Force or Vector3.zero
				)
				CartPhysicsService.UpdateGroundForces(record.root)
			end
		end
		validationElapsed += dt
		if validationElapsed >= Config.ValidationInterval then
			validationElapsed = 0
			local now = os.clock()
			for _, record in pairs(records) do
				validateRecord(record, now)
			end
		end
	end)
end

return CartService
