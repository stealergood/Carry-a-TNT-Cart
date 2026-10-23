local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)
local CartMotion = require(ReplicatedStorage.Shared.CartMotion)
local PartyConfig = require(ReplicatedStorage.Shared.PartyConfig)

local CartPullController = {}
local player = Players.LocalPlayer
local activeModel: Model? = nil
local activeHumanoid: Humanoid? = nil
local originalWalkSpeed: number? = nil

local function clearDrive(model)
	if model and model:GetAttribute("PartyId") then
		return
	end
	local root = model and model:FindFirstChild(Constants.PhysicsRoot)
	local drive = root and root:FindFirstChild(Constants.PullDrive)
	if drive and drive:IsA("VectorForce") then
		drive.Force = Vector3.zero
	end
	local groundAssist = root and root:FindFirstChild(Constants.GroundAssist)
	if groundAssist and groundAssist:IsA("VectorForce") then
		groundAssist.Force = Vector3.zero
	end
end

local function restorePlayerMovement()
	if activeHumanoid and activeHumanoid.Parent and originalWalkSpeed then
		local character = activeHumanoid.Parent
		local mudBaseSpeed = character:GetAttribute(Constants.MudBaseWalkSpeedAttribute)
		local mudMultiplier = character:GetAttribute(Constants.MudSlowMultiplierAttribute)
		local baseSpeed = if typeof(mudBaseSpeed) == "number" then mudBaseSpeed else originalWalkSpeed
		activeHumanoid.WalkSpeed = baseSpeed * (if typeof(mudMultiplier) == "number" then mudMultiplier else 1)
	end
	activeHumanoid = nil
	originalWalkSpeed = nil
end

local function stopActive()
	if activeModel then
		clearDrive(activeModel)
	end
	restorePlayerMovement()
	activeModel = nil
end

local function getActiveModel()
	local activeValue = player:FindFirstChild(Constants.ActiveCartValue)
	if not activeValue or not activeValue:IsA("ObjectValue") then
		return nil
	end
	local model = activeValue.Value
	if model and model:IsA("Model") and model:IsDescendantOf(workspace) then
		return model
	end
	return nil
end

local function getCharacterParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return humanoid, root
end

local function updateMovementLoad(humanoid, loadRatio, dt)
	if humanoid ~= activeHumanoid then
		restorePlayerMovement()
		activeHumanoid = humanoid
		originalWalkSpeed = humanoid.WalkSpeed
	end
	local character = humanoid.Parent
	local mudBaseSpeed = character and character:GetAttribute(Constants.MudBaseWalkSpeedAttribute)
	local mudMultiplier = character and character:GetAttribute(Constants.MudSlowMultiplierAttribute)
	if typeof(mudBaseSpeed) == "number" then
		originalWalkSpeed = mudBaseSpeed
	end
	local baseSpeed = originalWalkSpeed or humanoid.WalkSpeed
	local desiredSpeed = math.max(Config.MinPullerWalkSpeed, baseSpeed * (1 - Config.PullerMaxSpeedPenalty * loadRatio))
		* (if typeof(mudMultiplier) == "number" then mudMultiplier else 1)
	local response = 1 - math.exp(-Config.PullerSpeedResponse * dt)
	humanoid.WalkSpeed += (desiredSpeed - humanoid.WalkSpeed) * response
end

local function enforcePartyLeash(model)
	if model:GetAttribute("CartState") ~= Constants.States.Pulling then
		return
	end
	local slot = player:GetAttribute("PartySlot")
	local attachmentName = slot and PartyConfig.AttachmentNames[slot]
	local humanoid, characterRoot = getCharacterParts()
	local cartRoot = model:FindFirstChild(Constants.PhysicsRoot)
	local pull = cartRoot and attachmentName and cartRoot:FindFirstChild(attachmentName)
	local hand = characterRoot and characterRoot:FindFirstChild(Constants.HandAttachment)
	if
		not humanoid
		or not characterRoot
		or not cartRoot
		or not cartRoot:IsA("BasePart")
		or not pull
		or not pull:IsA("Attachment")
		or not hand
		or not hand:IsA("Attachment")
	then
		return
	end

	local offset = hand.WorldPosition - pull.WorldPosition
	local distance = offset.Magnitude
	if distance < Config.PartyRopeMaxLength then
		return
	end
	local direction = offset.Unit
	if distance > Config.PartyRopeMaxLength then
		characterRoot.CFrame -= direction * (distance - Config.PartyRopeMaxLength)
	end
	local relativeVelocity = characterRoot.AssemblyLinearVelocity - cartRoot.AssemblyLinearVelocity
	local outwardSpeed = relativeVelocity:Dot(direction)
	if outwardSpeed > 0 then
		characterRoot.AssemblyLinearVelocity -= direction * outwardSpeed
	end
end

local function updatePull(model, dt)
	if model:GetAttribute("PartyId") then
		-- The shared cart is driven on the server; slowing each local Humanoid
		-- makes party movement respond late.
		restorePlayerMovement()
		return
	end
	if
		model:GetAttribute("CartState") ~= Constants.States.Pulling
		or model:GetAttribute("PullerUserId") ~= player.UserId
	then
		clearDrive(model)
		restorePlayerMovement()
		return
	end

	local humanoid, characterRoot = getCharacterParts()
	local root = model:FindFirstChild(Constants.PhysicsRoot)
	local pull = root and root:FindFirstChild(Constants.PullAttachment)
	local drive = root and root:FindFirstChild(Constants.PullDrive)
	local hand = characterRoot and characterRoot:FindFirstChild(Constants.HandAttachment)
	if
		not humanoid
		or not characterRoot
		or not root
		or not root:IsA("BasePart")
		or not pull
		or not pull:IsA("Attachment")
		or not drive
		or not drive:IsA("VectorForce")
		or not hand
		or not hand:IsA("Attachment")
	then
		clearDrive(model)
		restorePlayerMovement()
		return
	end

	local pullForce, loadRatio = CartMotion.PullForce(root, hand, characterRoot)
	drive.Force = pullForce
	local pushForce = Vector3.zero
	local pushDrive = root:FindFirstChild(Constants.PushDrive)
	local pushProxy = model:FindFirstChild("PushProxy")
	if pushDrive and pushDrive:IsA("VectorForce") then
		pushForce = if pushProxy and pushProxy:IsA("BasePart")
			then CartMotion.PushForce(root, pushProxy)
			else Vector3.zero
		pushDrive.Force = pushForce
	end
	local resistance = root:FindFirstChild(Constants.MotionResistance)
	if resistance and resistance:IsA("VectorForce") then
		resistance.Force = CartMotion.ResistanceForce(root, Config.MaxCartSpeed)
	end
	local lateralGrip = root:FindFirstChild(Constants.LateralGrip)
	if lateralGrip and lateralGrip:IsA("VectorForce") then
		lateralGrip.Force = CartMotion.LateralGripForce(root, pullForce + pushForce)
	end
	local steering = root:FindFirstChild(Constants.SteeringTorque)
	if steering and steering:IsA("Torque") then
		steering.Torque = CartMotion.SteeringTorque(root, pullForce + pushForce, true)
	end
	local support = CartMotion.GroundSupport(root)
	local groundAssist = root:FindFirstChild(Constants.GroundAssist)
	if groundAssist and groundAssist:IsA("VectorForce") then
		groundAssist.Force = CartMotion.GroundAssistForce(root, pullForce + pushForce, support)
	end
	local stabilizer = root:FindFirstChild(Constants.UprightStabilizer)
	if stabilizer and stabilizer:IsA("Torque") then
		stabilizer.Torque = CartMotion.UprightTorque(root, support and support.normal)
	end
	updateMovementLoad(humanoid, loadRatio, dt)
end

function CartPullController.Start()
	RunService.PreSimulation:Connect(function(dt)
		local model = getActiveModel()
		if model ~= activeModel then
			stopActive()
			activeModel = model
		end
		if activeModel then
			updatePull(activeModel, dt)
		end
	end)
	RunService.PostSimulation:Connect(function()
		if activeModel and activeModel:GetAttribute("PartyId") then
			enforcePartyLeash(activeModel)
		end
	end)
	player.CharacterRemoving:Connect(stopActive)
end

return CartPullController
