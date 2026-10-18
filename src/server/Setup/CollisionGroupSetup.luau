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

function CollisionGroupSetup.Start()
	ensureGroup(Constants.CollisionGroup)
	ensureGroup(Constants.PlayerCollisionGroup)
	PhysicsService:CollisionGroupSetCollidable(Constants.CollisionGroup, "Default", true)
	PhysicsService:CollisionGroupSetCollidable(Constants.CollisionGroup, Constants.CollisionGroup, true)
	PhysicsService:CollisionGroupSetCollidable(Constants.CollisionGroup, Constants.PlayerCollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable(Constants.PlayerCollisionGroup, "Default", true)
	PhysicsService:CollisionGroupSetCollidable(Constants.PlayerCollisionGroup, Constants.PlayerCollisionGroup, true)
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
