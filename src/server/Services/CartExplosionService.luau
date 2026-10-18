local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.CartConfig)

local CartExplosionService = {}

local function emitParticles(parent: Instance, texture: string, color: ColorSequence, count: number, speed: NumberRange)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Color = color
	emitter.Lifetime = NumberRange.new(0.45, 1.1)
	emitter.Speed = speed
	emitter.Drag = 3
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.LightEmission = 0.65
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.35, 2.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Rate = 0
	emitter.Parent = parent
	emitter:Emit(count)
end

local function createVfx(position: Vector3)
	local core = Instance.new("Part")
	core.Name = "CartExplosionVFX"
	core.Shape = Enum.PartType.Ball
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(255, 121, 24)
	core.Transparency = 0.08
	core.Size = Vector3.one * 2
	core.CFrame = CFrame.new(position)
	core.Anchored = true
	core.CanCollide = false
	core.CanTouch = false
	core.CanQuery = false
	core.Parent = workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = core
	emitParticles(
		attachment,
		"rbxasset://textures/particles/fire_main.dds",
		ColorSequence.new(Color3.fromRGB(255, 238, 90), Color3.fromRGB(255, 73, 8)),
		55,
		NumberRange.new(15, 34)
	)
	emitParticles(
		attachment,
		"rbxasset://textures/particles/smoke_main.dds",
		ColorSequence.new(Color3.fromRGB(90, 84, 78), Color3.fromRGB(28, 25, 24)),
		38,
		NumberRange.new(8, 19)
	)
	emitParticles(
		attachment,
		"rbxasset://textures/particles/sparkles_main.dds",
		ColorSequence.new(Color3.fromRGB(255, 232, 112), Color3.fromRGB(255, 91, 14)),
		70,
		NumberRange.new(22, 45)
	)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 149, 44)
	light.Brightness = 10
	light.Range = 28
	light.Shadows = true
	light.Parent = core

	TweenService:Create(
		core,
		TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * 15, Transparency = 1 }
	):Play()
	TweenService:Create(light, TweenInfo.new(0.28), { Brightness = 0, Range = 0 }):Play()
	Debris:AddItem(core, 3)
end

local function killNearbyPlayers(position: Vector3)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if
			humanoid
			and humanoid.Health > 0
			and root
			and root:IsA("BasePart")
			and (root.Position - position).Magnitude <= Config.ExplosionRadius
		then
			humanoid.Health = 0
		end
	end
end

local function collectFragments(model: Model, root: BasePart): { BasePart }
	local candidates = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if
			descendant:IsA("BasePart")
			and descendant ~= root
			and descendant:GetAttribute("CarryProxy") ~= true
			and descendant.Transparency < 1
		then
			table.insert(candidates, descendant)
		end
	end
	table.sort(candidates, function(a, b)
		local aWheel = a.Name:match("^Wheel_") and 1 or 0
		local bWheel = b.Name:match("^Wheel_") and 1 or 0
		if aWheel ~= bWheel then
			return aWheel > bWheel
		end
		return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
	end)
	local fragments = {}
	for index = 1, math.min(#candidates, Config.ExplosionMaxFragments) do
		table.insert(fragments, candidates[index])
	end
	return fragments
end

local function scatterCart(record, position: Vector3)
	local random = Random.new()
	local fragments = collectFragments(record.model, record.root)
	local selected = {}
	for _, fragment in ipairs(fragments) do
		selected[fragment] = true
		fragment:BreakJoints()
		for _, joint in ipairs(fragment:GetDescendants()) do
			if joint:IsA("WeldConstraint") or joint:IsA("Motor6D") then
				joint:Destroy()
			end
		end
		fragment.Parent = workspace
		fragment.Anchored = false
		fragment.Massless = false
		fragment.CanCollide = true
		fragment.CanTouch = false
		fragment:SetAttribute("CartExplosionFragment", true)
		local away = fragment.Position - position
		local horizontal = Vector3.new(away.X, 0, away.Z)
		if horizontal.Magnitude < 0.1 then
			horizontal = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
		end
		local impulseDirection = horizontal.Unit * Config.ExplosionFragmentSpeed
			+ Vector3.yAxis
				* random:NextNumber(Config.ExplosionFragmentUpSpeed * 0.65, Config.ExplosionFragmentUpSpeed)
		fragment:ApplyImpulse(impulseDirection * fragment.AssemblyMass)
		fragment:ApplyAngularImpulse(
			Vector3.new(random:NextNumber(-10, 10), random:NextNumber(-10, 10), random:NextNumber(-10, 10))
				* fragment.AssemblyMass
		)
		Debris:AddItem(fragment, Config.ExplosionFragmentLifetime)
	end
	for _, descendant in ipairs(record.model:GetDescendants()) do
		if descendant:IsA("BasePart") and not selected[descendant] then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.Transparency = 1
		end
	end
end

function CartExplosionService.Explode(record)
	local position = record.root.Position
	createVfx(position)
	killNearbyPlayers(position)
	scatterCart(record, position)
	task.delay(Config.ExplosionCartRemovalDelay, function()
		if record.model.Parent then
			record.model:Destroy()
		end
	end)
end

return CartExplosionService
