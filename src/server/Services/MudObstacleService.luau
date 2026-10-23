local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)
local CartTypes = require(ReplicatedStorage.Shared.CartTypes)
local CartHealthService = require(script.Parent.CartHealthService)
type CartRecord = CartTypes.CartRecord

local MudObstacleService = {}
local started = false
local playerBaseSpeeds: { [Humanoid]: number } = {}
local cartTimeInMud: { [CartRecord]: number } = {}

local function getQueryBox(part: BasePart): (CFrame, Vector3)
	local halfSize = part.Size * 0.5
	local frame = part.CFrame
	local right = frame.RightVector
	local up = frame.UpVector
	local look = frame.LookVector
	local halfX = math.abs(right.X) * halfSize.X + math.abs(up.X) * halfSize.Y + math.abs(look.X) * halfSize.Z
	local halfY = math.abs(right.Y) * halfSize.X + math.abs(up.Y) * halfSize.Y + math.abs(look.Y) * halfSize.Z
	local halfZ = math.abs(right.Z) * halfSize.X + math.abs(up.Z) * halfSize.Y + math.abs(look.Z) * halfSize.Z
	local bottom = part.Position.Y - halfY
	return CFrame.new(part.Position.X, bottom + Config.MudTriggerHeight * 0.5, part.Position.Z),
		Vector3.new(halfX * 2, Config.MudTriggerHeight, halfZ * 2)
end

local function findCartRecord(hit: BasePart, resolveCartRecord: (Model) -> CartRecord?): CartRecord?
	if hit.Name ~= Constants.DamageProxy then
		return nil
	end
	local model = hit.Parent
	if model and model:IsA("Model") then
		local record = resolveCartRecord(model)
		if record and not record.exploded and record.root.Parent then
			return record
		end
	end
	return nil
end

local function findPlayerHumanoid(hit: BasePart): Humanoid?
	if hit.Name ~= "HumanoidRootPart" then
		return nil
	end
	local character = hit.Parent
	if not character or not character:IsA("Model") or not Players:GetPlayerFromCharacter(character) then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function scan(resolveCartRecord: (Model) -> CartRecord?, elapsed: number)
	local presentPlayers: { [Humanoid]: boolean } = {}
	local presentCarts: { [CartRecord]: boolean } = {}
	local query = OverlapParams.new()
	query.RespectCanCollide = false

	local function checkPart(part: BasePart)
		if not part:IsDescendantOf(workspace) then
			return
		end
		local boxFrame, boxSize = getQueryBox(part)
		for _, hit in ipairs(workspace:GetPartBoundsInBox(boxFrame, boxSize, query)) do
			local humanoid = findPlayerHumanoid(hit)
			if humanoid then
				presentPlayers[humanoid] = true
			end
			local record = findCartRecord(hit, resolveCartRecord)
			if record then
				presentCarts[record] = true
			end
		end
	end

	for _, obstacle in ipairs(CollectionService:GetTagged(Config.MudTag)) do
		if obstacle:IsA("BasePart") then
			checkPart(obstacle)
		elseif obstacle:IsA("Model") then
			for _, descendant in ipairs(obstacle:GetDescendants()) do
				if descendant:IsA("BasePart") then
					checkPart(descendant)
				end
			end
		end
	end

	for humanoid, baseSpeed in pairs(playerBaseSpeeds) do
		if not presentPlayers[humanoid] then
			local character = humanoid.Parent
			if character then
				humanoid.WalkSpeed = baseSpeed
				character:SetAttribute(Constants.MudBaseWalkSpeedAttribute, nil)
				character:SetAttribute(Constants.MudSlowMultiplierAttribute, nil)
			end
			playerBaseSpeeds[humanoid] = nil
		end
	end
	for humanoid in pairs(presentPlayers) do
		if not playerBaseSpeeds[humanoid] then
			local baseSpeed = humanoid.WalkSpeed
			playerBaseSpeeds[humanoid] = baseSpeed
			local character = humanoid.Parent
			character:SetAttribute(Constants.MudBaseWalkSpeedAttribute, baseSpeed)
			character:SetAttribute(Constants.MudSlowMultiplierAttribute, Config.MudSlowMultiplier)
			humanoid.WalkSpeed = baseSpeed * Config.MudSlowMultiplier
		end
	end

	for record in pairs(cartTimeInMud) do
		if not presentCarts[record] then
			if record.model.Parent then
				record.model:SetAttribute(Constants.MudSlowMultiplierAttribute, nil)
			end
			cartTimeInMud[record] = nil
		end
	end
	for record in pairs(presentCarts) do
		local timeInMud = cartTimeInMud[record]
		if timeInMud == nil then
			record.model:SetAttribute(Constants.MudSlowMultiplierAttribute, Config.MudSlowMultiplier)
			cartTimeInMud[record] = 0
		else
			timeInMud += elapsed
			local seconds = math.floor(timeInMud)
			if seconds > 0 then
				CartHealthService.Damage(record, seconds * Config.MudDamagePerSecond)
				timeInMud -= seconds
			end
			cartTimeInMud[record] = timeInMud
		end
	end
end

function MudObstacleService.Start(resolveCartRecord: (Model) -> CartRecord?)
	if started then
		return
	end
	started = true
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < Config.MudScanInterval then
			return
		end
		local elapsed = accumulator
		accumulator = 0
		scan(resolveCartRecord, elapsed)
	end)
end

return MudObstacleService
