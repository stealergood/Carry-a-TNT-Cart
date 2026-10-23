local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)
local CartMotion = require(ReplicatedStorage.Shared.CartMotion)

local CartPhysicsService = {}

local function getVectorForce(root, name)
	local force = root:FindFirstChild(name)
	if force and not force:IsA("VectorForce") then
		force:Destroy()
		force = nil
	end
	if not force then
		force = Instance.new("VectorForce")
		force.Name = name
		force.Parent = root
	end
	force.Attachment0 = root:FindFirstChild(Constants.CenterAttachment)
	force.ApplyAtCenterOfMass = true
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	return force
end

local function configureCollider(part, density)
	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.CollisionGroup = Constants.CollisionGroup
	part.CustomPhysicalProperties = PhysicalProperties.new(
		density or Config.BaseColliderDensity,
		Config.CartFriction,
		Config.CartElasticity,
		100,
		100
	)
end

local function configureBallast(ballast, density)
	ballast.Anchored = false
	ballast.CanCollide = false
	ballast.CanTouch = false
	ballast.CanQuery = false
	ballast.Massless = false
	ballast.CustomPhysicalProperties = PhysicalProperties.new(density, 0, 0, 0, 0)
end

local function weld(root, part)
	if part == root or part:FindFirstChild("CarryWeld") then
		return
	end
	local joint = Instance.new("WeldConstraint")
	joint.Name = "CarryWeld"
	joint.Part0 = root
	joint.Part1 = part
	joint.Parent = part
end

local function isVisualWheel(part)
	return part:IsA("BasePart") and part.Name:match("^Wheel_") ~= nil
end

local function motorizeWheel(root, wheel)
	local oldWeld = wheel:FindFirstChild("CarryWeld")
	if oldWeld then
		oldWeld:Destroy()
	end
	local motor = wheel:FindFirstChild(Constants.WheelMotor)
	if motor and not motor:IsA("Motor6D") then
		motor:Destroy()
		motor = nil
	end
	if not motor then
		motor = Instance.new("Motor6D")
		motor.Name = Constants.WheelMotor
		motor.Part0 = root
		motor.Part1 = wheel
		motor.C0 = root.CFrame:ToObjectSpace(wheel.CFrame)
		motor.Parent = wheel
	else
		motor.Part0 = root
		motor.Part1 = wheel
	end
	return motor
end

local function applyTargetMass(root, ballast)
	local baseDensity = math.max(Config.BaseColliderDensity, 0.01)
	configureBallast(ballast, baseDensity)
	local ballastMass = ballast:GetMass()
	local effectiveVolume = ballastMass / baseDensity
	local otherMass = math.max(0, root.AssemblyMass - ballastMass)
	local desiredBallastMass = math.max(Config.TargetCartMass - otherMass, effectiveVolume * 0.01)
	local requiredDensity = math.clamp(desiredBallastMass / effectiveVolume, 0.01, 100)
	configureBallast(ballast, requiredDensity)
end

function CartPhysicsService.Prepare(model)
	local root = model:FindFirstChild(Constants.PhysicsRoot)
	if root and not root:IsA("BasePart") then
		return nil, "PhysicsRoot bukan BasePart"
	end
	if not root then
		root = Instance.new("Part")
		root.Name = Constants.PhysicsRoot
		root.Size = Config.ChassisSize
		root.CFrame = model:GetPivot() * Config.ChassisOffset
		root.Parent = model
	end
	root.Transparency = 1
	root.CastShadow = false
	root.Massless = false
	root.Size = Config.ChassisSize
	configureCollider(root)

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root and part:GetAttribute("CarryProxy") ~= true then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = true
			if isVisualWheel(part) then
				motorizeWheel(root, part)
			else
				weld(root, part)
			end
		end
	end

	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local name = string.format("WheelProxy_%d_%d", x, z)
			local proxy = model:FindFirstChild(name)
			local targetOffset =
				CFrame.new(x * Config.WheelX, Config.WheelY - Config.ChassisOffset.Position.Y, z * Config.WheelZ)
			if not proxy then
				proxy = Instance.new("Part")
				proxy.Name = name
				proxy.Shape = Enum.PartType.Ball
				proxy.CFrame = root.CFrame * targetOffset
				proxy:SetAttribute("CarryProxy", true)
				proxy.Parent = model
			end
			if (root.CFrame:ToObjectSpace(proxy.CFrame).Position - targetOffset.Position).Magnitude > 0.01 then
				local oldWeld = proxy:FindFirstChild("CarryWeld")
				if oldWeld then
					oldWeld:Destroy()
				end
				proxy.CFrame = root.CFrame * targetOffset
			end
			proxy.Transparency = 1
			proxy.Shape = Enum.PartType.Ball
			proxy.CastShadow = false
			proxy.Massless = false
			proxy.Size = Config.WheelProxySize
			configureCollider(proxy)
			weld(root, proxy)
		end
	end

	local bodyProxy = model:FindFirstChild("BodyProxy")
	if not bodyProxy then
		bodyProxy = Instance.new("Part")
		bodyProxy.Name = "BodyProxy"
		bodyProxy.CFrame = root.CFrame * Config.BodyProxyOffset
		bodyProxy:SetAttribute("CarryProxy", true)
		bodyProxy.Parent = model
	end
	local bodyOffset = root.CFrame:ToObjectSpace(bodyProxy.CFrame).Position
	if (bodyOffset - Config.BodyProxyOffset.Position).Magnitude > 0.01 then
		local oldWeld = bodyProxy:FindFirstChild("CarryWeld")
		if oldWeld then
			oldWeld:Destroy()
		end
		bodyProxy.CFrame = root.CFrame * Config.BodyProxyOffset
	end
	bodyProxy.Size = Config.BodyProxySize
	bodyProxy.Transparency = 1
	bodyProxy.CastShadow = false
	bodyProxy.Massless = true
	configureCollider(bodyProxy)
	weld(root, bodyProxy)

	local damageProxy = model:FindFirstChild(Constants.DamageProxy)
	if not damageProxy then
		damageProxy = Instance.new("Part")
		damageProxy.Name = Constants.DamageProxy
		damageProxy.CFrame = root.CFrame * Config.DamageProxyOffset
		damageProxy:SetAttribute("CarryProxy", true)
		damageProxy.Parent = model
	end
	local damageOffset = root.CFrame:ToObjectSpace(damageProxy.CFrame).Position
	if (damageOffset - Config.DamageProxyOffset.Position).Magnitude > 0.01 then
		local oldWeld = damageProxy:FindFirstChild("CarryWeld")
		if oldWeld then
			oldWeld:Destroy()
		end
		damageProxy.CFrame = root.CFrame * Config.DamageProxyOffset
	end
	damageProxy.Size = Config.DamageProxySize
	damageProxy.Transparency = 1
	damageProxy.CastShadow = false
	damageProxy.Massless = true
	damageProxy.Anchored = false
	damageProxy.CanCollide = false
	damageProxy.CanTouch = true
	damageProxy.CanQuery = true
	damageProxy.CollisionGroup = Constants.CollisionGroup
	weld(root, damageProxy)

	local pushProxy = model:FindFirstChild("PushProxy")
	if not pushProxy then
		pushProxy = Instance.new("Part")
		pushProxy.Name = "PushProxy"
		pushProxy.CFrame = root.CFrame * Config.PushProxyOffset
		pushProxy:SetAttribute("CarryProxy", true)
		pushProxy.Parent = model
	end
	pushProxy.Size = Config.PushProxySize
	local pushOffset = root.CFrame:ToObjectSpace(pushProxy.CFrame).Position
	if (pushOffset - Config.PushProxyOffset.Position).Magnitude > 0.01 then
		local oldWeld = pushProxy:FindFirstChild("CarryWeld")
		if oldWeld then
			oldWeld:Destroy()
		end
		pushProxy.CFrame = root.CFrame * Config.PushProxyOffset
	end
	pushProxy.Transparency = 1
	pushProxy.CastShadow = false
	pushProxy.Massless = true
	configureCollider(pushProxy)
	pushProxy.CanCollide = false
	weld(root, pushProxy)

	local ballast = model:FindFirstChild(Constants.Ballast)
	if not ballast then
		ballast = Instance.new("Part")
		ballast.Name = Constants.Ballast
		ballast.CFrame = root.CFrame * Config.BallastOffset
		ballast:SetAttribute("CarryProxy", true)
		ballast.Parent = model
	end
	ballast.Size = Config.BallastSize
	local ballastOffset = root.CFrame:ToObjectSpace(ballast.CFrame).Position
	if (ballastOffset - Config.BallastOffset.Position).Magnitude > 0.01 then
		local oldWeld = ballast:FindFirstChild("CarryWeld")
		if oldWeld then
			oldWeld:Destroy()
		end
		ballast.CFrame = root.CFrame * Config.BallastOffset
	end
	ballast.Transparency = 1
	ballast.CastShadow = false
	weld(root, ballast)
	applyTargetMass(root, ballast)

	local pull = root:FindFirstChild(Constants.PullAttachment)
	if not pull then
		pull = Instance.new("Attachment")
		pull.Name = Constants.PullAttachment
		pull.Parent = root
	end
	pull.Position = Config.PullOffset
	if model:GetAttribute("PartyId") then
		local PartyConfig = require(game.ReplicatedStorage.Shared.PartyConfig)
		for slot, name in ipairs(PartyConfig.AttachmentNames) do
			local attachment = root:FindFirstChild(name)
			if not attachment then
				attachment = Instance.new("Attachment")
				attachment.Name = name
				attachment.Parent = root
			end
			attachment.Position = PartyConfig.AttachmentOffsets[slot]
		end
	end

	local center = root:FindFirstChild(Constants.CenterAttachment)
	if not center then
		center = Instance.new("Attachment")
		center.Name = Constants.CenterAttachment
		center.Parent = root
	end
	center.Position = Vector3.zero

	getVectorForce(root, Constants.PullDrive).Force = Vector3.zero
	getVectorForce(root, Constants.PushDrive).Force = Vector3.zero
	getVectorForce(root, Constants.MotionResistance).Force = Vector3.zero
	getVectorForce(root, Constants.GroundAssist).Force = Vector3.zero
	getVectorForce(root, Constants.LateralGrip).Force = Vector3.zero

	local legacyStabilizer = root:FindFirstChild("UprightStabilizer")
	if legacyStabilizer then
		legacyStabilizer:Destroy()
	end
	local stabilizer = root:FindFirstChild(Constants.UprightStabilizer)
	if stabilizer and not stabilizer:IsA("Torque") then
		stabilizer:Destroy()
		stabilizer = nil
	end
	if not stabilizer then
		stabilizer = Instance.new("Torque")
		stabilizer.Name = Constants.UprightStabilizer
		stabilizer.Parent = root
	end
	stabilizer.Attachment0 = center
	stabilizer.RelativeTo = Enum.ActuatorRelativeTo.World
	stabilizer.Torque = Vector3.zero

	local steering = root:FindFirstChild(Constants.SteeringTorque)
	if steering and not steering:IsA("Torque") then
		steering:Destroy()
		steering = nil
	end
	if not steering then
		steering = Instance.new("Torque")
		steering.Name = Constants.SteeringTorque
		steering.Parent = root
	end
	steering.Attachment0 = center
	steering.RelativeTo = Enum.ActuatorRelativeTo.World
	steering.Torque = Vector3.zero

	model.PrimaryPart = root
	model:SetAttribute("CarryPrepared", true)
	return root
end

function CartPhysicsService.SetOwner(root, player)
	local canSet, reason = root:CanSetNetworkOwnership()
	if not canSet then
		warn("Tidak bisa mengatur network ownership cart:", reason)
		return false
	end
	root:SetNetworkOwner(player)
	return true
end

function CartPhysicsService.SetIdleOwnership(root)
	local canSet, reason = root:CanSetNetworkOwnership()
	if not canSet then
		warn("Tidak bisa mengatur auto ownership cart:", reason)
		return false
	end
	root:SetNetworkOwner(nil)
	return true
end

function CartPhysicsService.ClampMotion(root, maxSpeed)
	local velocity = root.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	if horizontal.Magnitude > maxSpeed then
		local capped = horizontal.Unit * maxSpeed
		root.AssemblyLinearVelocity = Vector3.new(capped.X, velocity.Y, capped.Z)
	end
	local angular = root.AssemblyAngularVelocity
	if angular.Magnitude > Config.MaxAngularSpeed then
		root.AssemblyAngularVelocity = angular.Unit * Config.MaxAngularSpeed
	end
end

function CartPhysicsService.UpdatePushDrive(root)
	local drive = root:FindFirstChild(Constants.PushDrive)
	local pushProxy = root.Parent and root.Parent:FindFirstChild("PushProxy")
	if not drive or not drive:IsA("VectorForce") or not pushProxy or not pushProxy:IsA("BasePart") then
		return
	end
	drive.Force = CartMotion.PushForce(root, pushProxy)
end

function CartPhysicsService.UpdatePartyDrive(record)
	local total = Vector3.zero
	for _, member in ipairs(record.participants or {}) do
		local character = member.player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		if playerRoot and member.handAttachment.Parent and member.attachment.Parent then
			local offset = member.handAttachment.WorldPosition - member.attachment.WorldPosition
			local distance = offset.Magnitude
			if distance > Config.PartyRopeMaxLength + Config.PartyRopeServerSlack then
				local direction = offset.Unit
				playerRoot.CFrame -= direction * (distance - Config.PartyRopeMaxLength)
				local relativeVelocity = playerRoot.AssemblyLinearVelocity - record.root.AssemblyLinearVelocity
				local outwardSpeed = relativeVelocity:Dot(direction)
				if outwardSpeed > 0 then
					playerRoot.AssemblyLinearVelocity -= direction * outwardSpeed
				end
			end
			total += CartMotion.PullForce(
				record.root,
				member.handAttachment,
				playerRoot,
				member.attachment,
				Config.PartyPullSlackLength
			)
		end
	end
	local maxForce = record.root.AssemblyMass * Config.PartyMaxPullAcceleration
	if total.Magnitude > maxForce then
		total = total.Unit * maxForce
	end
	local root = record.root
	root[Constants.PullDrive].Force = total
	-- Party propulsion comes only from the crew; outsiders cannot steer it by pushing.
	root[Constants.PushDrive].Force = Vector3.zero
	root[Constants.MotionResistance].Force = CartMotion.ResistanceForce(root, Config.MaxCartSpeed)
	root[Constants.LateralGrip].Force = CartMotion.LateralGripForce(root, total)
	root[Constants.SteeringTorque].Torque = CartMotion.SteeringTorque(root, total, true)
	CartPhysicsService.UpdateGroundForces(root, total)
end

function CartPhysicsService.UpdateMotionResistance(root, maxSpeed, useIdlePushResistance)
	local resistance = root:FindFirstChild(Constants.MotionResistance)
	if not resistance or not resistance:IsA("VectorForce") then
		return
	end
	if useIdlePushResistance then
		resistance.Force = CartMotion.ResistanceForce(
			root,
			maxSpeed,
			Config.IdlePushRollingResistance,
			Config.IdlePushVelocityResistance
		)
	else
		resistance.Force = CartMotion.ResistanceForce(root, maxSpeed)
	end
end

function CartPhysicsService.UpdateSteering(root, driveForce)
	local lateralGrip = root:FindFirstChild(Constants.LateralGrip)
	if lateralGrip and lateralGrip:IsA("VectorForce") then
		lateralGrip.Force = CartMotion.LateralGripForce(root, driveForce)
	end
	local steering = root:FindFirstChild(Constants.SteeringTorque)
	if steering and steering:IsA("Torque") then
		steering.Torque = CartMotion.SteeringTorque(root, driveForce)
	end
end

function CartPhysicsService.UpdateGroundForces(root, driveForce)
	local support = CartMotion.GroundSupport(root)
	local groundAssist = root:FindFirstChild(Constants.GroundAssist)
	if groundAssist and groundAssist:IsA("VectorForce") then
		local pushDrive = root:FindFirstChild(Constants.PushDrive)
		local drive = driveForce or (pushDrive and pushDrive:IsA("VectorForce") and pushDrive.Force) or Vector3.zero
		groundAssist.Force = CartMotion.GroundAssistForce(root, drive, support)
	end
	local stabilizer = root:FindFirstChild(Constants.UprightStabilizer)
	if not stabilizer or not stabilizer:IsA("Torque") then
		return
	end
	stabilizer.Torque = CartMotion.UprightTorque(root, support and support.normal)
end

function CartPhysicsService.StopPullDrive(record)
	local groundAssist = record.root:FindFirstChild(Constants.GroundAssist)
	if groundAssist and groundAssist:IsA("VectorForce") then
		groundAssist.Force = Vector3.zero
	end
	local drive = record.root:FindFirstChild(Constants.PullDrive)
	if drive and drive:IsA("VectorForce") then
		drive.Force = Vector3.zero
	end
	local steering = record.root:FindFirstChild(Constants.SteeringTorque)
	if steering and steering:IsA("Torque") then
		steering.Torque = Vector3.zero
	end
	local lateralGrip = record.root:FindFirstChild(Constants.LateralGrip)
	if lateralGrip and lateralGrip:IsA("VectorForce") then
		lateralGrip.Force = Vector3.zero
	end
end

return CartPhysicsService
