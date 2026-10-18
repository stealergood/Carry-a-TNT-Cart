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
local CartPhysicsService = require(script.Parent.CartPhysicsService)
local CartRespawnService = require(script.Parent.CartRespawnService)
local CartValidationService = require(script.Parent.CartValidationService)

local CartService = {}
local records: { [Model]: CartRecord } = {}
local started = false

local function setState(record: CartRecord, state: CartState)
	record.state = state
	record.model:SetAttribute("CartState", state)
	record.model:SetAttribute("IsOccupied", state == Constants.States.Pulling or state == Constants.States.Claiming)
	record.model:SetAttribute("PullerUserId", record.puller and record.puller.UserId or 0)
	record.prompt.Enabled = state == Constants.States.Idle
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
	local record = {
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
		respawnTemplate = CartRespawnService.CreateTemplate(model),
		spawnCFrame = model:GetPivot(),
		activeDamageParts = {},
		windowStartPosition = root.Position,
		windowStartTime = now,
	}
	records[model] = record
	setState(record, Constants.States.Idle)
	CartPhysicsService.SetIdleOwnership(root)
	CartHealthService.Setup(record)

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

function CartService.Start()
	if started then
		return
	end
	started = true
	CollisionGroupSetup.Start()
	CartClaimService.Start(setState)
	CartHealthService.Start(function(record)
		CartClaimService.Release(record)
		setState(record, Constants.States.Disabled)
		CartPhysicsService.SetOwner(record.root, nil)
		CartRespawnService.Schedule(record)
	end)

	Players.PlayerRemoving:Connect(CartClaimService.ReleasePlayer)

	CollectionService:GetInstanceAddedSignal(Constants.Tag):Connect(register)
	CollectionService:GetInstanceRemovedSignal(Constants.Tag):Connect(unregister)
	for _, model in ipairs(CollectionService:GetTagged(Constants.Tag)) do
		register(model)
	end
	local defaultCart = workspace:FindFirstChild("Minecart_Default_TNT")
	if defaultCart and defaultCart:IsA("Model") and not CollectionService:HasTag(defaultCart, Constants.Tag) then
		CollectionService:AddTag(defaultCart, Constants.Tag)
	end

	local validationElapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		for _, record in pairs(records) do
			CartHealthService.Update(record)
			if record.state == Constants.States.Idle then
				CartPhysicsService.UpdatePushDrive(record.root)
				CartPhysicsService.UpdateMotionResistance(record.root, Config.MaxPushSpeed, true)
				local pushDrive = record.root:FindFirstChild(Constants.PushDrive)
				CartPhysicsService.UpdateSteering(
					record.root,
					pushDrive and pushDrive:IsA("VectorForce") and pushDrive.Force or Vector3.zero
				)
				CartPhysicsService.UpdateUprightTorque(record.root)
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
