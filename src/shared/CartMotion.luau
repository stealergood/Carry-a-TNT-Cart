local Players = game:GetService("Players")

local Config = require(script.Parent.CartConfig)

local CartMotion = {}

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function smoothstep(value: number): number
	local t = math.clamp(value, 0, 1)
	return t * t * (3 - 2 * t)
end

function CartMotion.PullForce(root: BasePart, hand: Attachment, playerRoot: BasePart): (Vector3, number)
	local offset = horizontal(hand.WorldPosition - root.PullAttachment.WorldPosition)
	if offset.Magnitude <= 0.05 then
		return Vector3.zero, 0
	end

	local direction = offset.Unit
	local stretch = math.max(0, offset.Magnitude - Config.RopeSlackLength)
	local relativeVelocity = horizontal(playerRoot.AssemblyLinearVelocity - root.AssemblyLinearVelocity)
	local separationSpeed = relativeVelocity:Dot(direction)
	local acceleration = math.clamp(
		Config.PullSpringAccelerationPerStud * stretch + Config.PullDampingAcceleration * separationSpeed,
		0,
		Config.MaxPullAcceleration
	)
	local speed = horizontal(root.AssemblyLinearVelocity).Magnitude
	local range = math.max(Config.MaxCartSpeed - Config.SoftSpeedStart, 0.01)
	local speedFactor = 1 - smoothstep((speed - Config.SoftSpeedStart) / range)
	return direction * root.AssemblyMass * acceleration * speedFactor, acceleration / Config.MaxPullAcceleration
end

function CartMotion.PushForce(root: BasePart, pushProxy: BasePart): Vector3
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { root.Parent }

	local totalAcceleration = Vector3.zero
	local seenCharacters = {}
	for _, part in ipairs(workspace:GetPartsInPart(pushProxy, overlapParams)) do
		local character = part:FindFirstAncestorOfClass("Model")
		if character and not seenCharacters[character] then
			seenCharacters[character] = true
			local player = Players:GetPlayerFromCharacter(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local playerRoot = character:FindFirstChild("HumanoidRootPart")
			if player and humanoid and humanoid.Health > 0 and playerRoot and playerRoot:IsA("BasePart") then
				local offset = horizontal(root.Position - playerRoot.Position)
				if offset.Magnitude > 0.05 then
					local direction = offset.Unit
					local playerVelocity = horizontal(playerRoot.AssemblyLinearVelocity)
					local playerSpeedTowardCart = playerVelocity:Dot(direction)
					local relativeVelocity = playerVelocity - horizontal(root.AssemblyLinearVelocity)
					local speedTowardCart = horizontal(relativeVelocity):Dot(direction)
					if
						playerSpeedTowardCart >= Config.PushAssistMinSpeed
						and speedTowardCart >= Config.PushAssistMinSpeed
					then
						local acceleration = math.clamp(
							Config.PushSpringAccelerationPerSpeed * (speedTowardCart - Config.PushAssistMinSpeed)
								+ Config.PushDampingAcceleration * speedTowardCart,
							0,
							Config.MaxPushAcceleration
						)
						totalAcceleration += direction * acceleration
					end
				end
			end
		end
	end

	if totalAcceleration.Magnitude > Config.MaxCombinedPushAcceleration then
		totalAcceleration = totalAcceleration.Unit * Config.MaxCombinedPushAcceleration
	end
	local speed = horizontal(root.AssemblyLinearVelocity).Magnitude
	local range = math.max(Config.MaxPushSpeed - Config.SoftSpeedStart, 0.01)
	local speedFactor = 1 - smoothstep((speed - Config.SoftSpeedStart) / range)
	return totalAcceleration * root.AssemblyMass * speedFactor
end

function CartMotion.ResistanceForce(
	root: BasePart,
	maxSpeed: number,
	rollingResistance: number?,
	velocityResistance: number?
): Vector3
	local velocity = horizontal(root.AssemblyLinearVelocity)
	local speed = velocity.Magnitude
	if speed <= 0.05 then
		return Vector3.zero
	end
	local deceleration = (rollingResistance or Config.RollingResistance)
		+ (velocityResistance or Config.VelocityResistance) * speed * speed
	if speed > maxSpeed then
		deceleration += math.min((speed - maxSpeed) * Config.SpeedBrakeAcceleration, Config.SpeedBrakeAcceleration)
	end
	return -velocity.Unit * root.AssemblyMass * deceleration
end

function CartMotion.LateralGripForce(root: BasePart, driveForce: Vector3?): Vector3
	local lateralSpeed = root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
	if math.abs(lateralSpeed) <= 0.05 then
		return Vector3.zero
	end

	local gripFactor = 1
	local desired = driveForce and horizontal(driveForce) or Vector3.zero
	if desired.Magnitude >= Config.SteeringMinForce then
		local forward = horizontal(root.CFrame.RightVector)
		local sidewaysPull = math.abs(forward:Cross(desired.Unit).Y)
		gripFactor = 1 - sidewaysPull * Config.SteeringGripRelease
	end
	return -root.CFrame.LookVector * lateralSpeed * root.AssemblyMass * Config.LateralGripAcceleration * gripFactor
end

function CartMotion.SteeringTorque(root: BasePart, driveForce: Vector3, allowStart: boolean?): Vector3
	local desired = horizontal(driveForce)
	if desired.Magnitude < Config.SteeringMinForce then
		return Vector3.zero
	end
	local speed = horizontal(root.AssemblyLinearVelocity).Magnitude
	local steeringRange = math.max(Config.SteeringFullSpeed - Config.SteeringMinSpeed, 0.01)
	local speedFactor = smoothstep((speed - Config.SteeringMinSpeed) / steeringRange)
	if allowStart then
		speedFactor = math.max(speedFactor, Config.PullSteeringStartFactor)
	end
	local forward = horizontal(root.CFrame.RightVector)
	local direction = desired.Unit
	local yawError = forward:Cross(direction).Y
	local yawVelocity = root.AssemblyAngularVelocity.Y
	local torque = yawError * Config.SteeringTorquePerError * speedFactor - yawVelocity * Config.SteeringDampingTorque
	torque = math.clamp(torque, -Config.MaxSteeringTorque, Config.MaxSteeringTorque)
	return Vector3.yAxis * torque
end

function CartMotion.UprightTorque(root: BasePart): Vector3
	local up = root.CFrame.UpVector
	local tiltAxis = up:Cross(Vector3.yAxis)
	if up:Dot(Vector3.yAxis) < -0.9 and tiltAxis.Magnitude < 0.05 then
		tiltAxis = root.CFrame.RightVector
	end
	local angularVelocity = root.AssemblyAngularVelocity
	local tiltAngularVelocity = angularVelocity - Vector3.yAxis * angularVelocity:Dot(Vector3.yAxis)
	local torque = tiltAxis * Config.UprightSpringTorque - tiltAngularVelocity * Config.UprightDampingTorque
	if torque.Magnitude > Config.UprightMaxTorque then
		return torque.Unit * Config.UprightMaxTorque
	end
	return torque
end

return CartMotion
