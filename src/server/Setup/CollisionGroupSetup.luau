local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Constants = require(game.ReplicatedStorage.Shared.CartConstants)

local CollisionGroupSetup = {}

local function assignCharacterCollisionGroup(character)
	local function assign(instance)
		if instance:IsA("BasePart") then
			instance.CollisionGroup = Constants.PlayerCollisionGroup
		end
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		assign(descendant)
	end
	character.DescendantAdded:Connect(assign)
end

local function ensureGroup(name)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

local function configureTriggerPart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.AudioCanCollide = false
	part.Massless = true
	part.CastShadow = false
	part.Transparency = 1
	part.CollisionGroup = Constants.TriggerCollisionGroup
end

local function configureMazeTriggers()
	local triggerFolder = workspace:FindFirstChild("MazeTriggers", true)
	if triggerFolder then
		for _, desc in ipairs(triggerFolder:GetDescendants()) do
			if desc:IsA("BasePart") then
				configureTriggerPart(desc)
			end
		end
	end
	for _, name in ipairs({ "TriggerMasuk", "TriggerKeluar" }) do
		local part = workspace:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			configureTriggerPart(part)
		end
	end
end

function CollisionGroupSetup.Start()
	ensureGroup(Constants.CollisionGroup)
	ensureGroup(Constants.PlayerCollisionGroup)
	ensureGroup(Constants.TriggerCollisionGroup)
	PhysicsService:CollisionGroupSetCollidable(Constants.CollisionGroup, "Default", true)
	PhysicsService:CollisionGroupSetCollidable(Constants.CollisionGroup, Constants.CollisionGroup, true)
	PhysicsService:CollisionGroupSetCollidable(Constants.CollisionGroup, Constants.PlayerCollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable(Constants.PlayerCollisionGroup, "Default", true)
	PhysicsService:CollisionGroupSetCollidable(Constants.PlayerCollisionGroup, Constants.PlayerCollisionGroup, true)
	PhysicsService:CollisionGroupSetCollidable(Constants.TriggerCollisionGroup, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(Constants.TriggerCollisionGroup, Constants.CollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable(Constants.TriggerCollisionGroup, Constants.PlayerCollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable(Constants.TriggerCollisionGroup, Constants.TriggerCollisionGroup, false)
	configureMazeTriggers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			assignCharacterCollisionGroup(player.Character)
		end
		player.CharacterAdded:Connect(assignCharacterCollisionGroup)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(assignCharacterCollisionGroup)
	end)
end

return CollisionGroupSetup
