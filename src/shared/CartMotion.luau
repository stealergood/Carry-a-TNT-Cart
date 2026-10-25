local Players = game:GetService("Players")

local Config = require(script.Parent.CartConfig)
local Constants = require(script.Parent.CartConstants)

local CartMotion = {}

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function smoothstep(value: number): number
	local t = math.clamp(value, 0, 1)
	return t * t * (3 - 2 * t)
end

local function mudAdjustedSpeed(root: BasePart, maxSpeed: number): number
	local cartModel = root.Parent
	local multiplier = cartModel and cartModel:GetAttribute(Constants.MudSlowMultiplierAttribute)
	if typeof(multiplier) == "number" then
		return maxSpeed * math.clamp(multiplier, 0.1, 1)
	end
	return maxSpeed
end

function CartMotion.GroundSupport(root: BasePart)
	local model = root.Parent
	if not model then
		return nil
	end
	local query = RaycastParams.new()
	query.FilterType = Enum.RaycastFilterType.Exclude
	query.FilterDescendantsInstances = { model }
	query.CollisionGroup = Constants.CollisionGroup
	query.RespectCanCollide = true
	local minimumNormalY = math.cos(math.rad(Config.GroundMaxSlopeAngle))
	local normal = Vector3.zero
	local wheels = {}
	local contactCount = 0
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local wheel = model:FindFirstChild(string.format("WheelProxy_%d_%d", x, z))
			if wheel and wheel:IsA("BasePart") then
				local radius = wheel.Size.Y * 0.5
				local origin = wheel.Position + Vector3.yAxis * Config.GroundRayLift
				local distance = Config.GroundRayLift + radius + Config.StepMaxHeight + Config.StepClearance
				local hit = workspace:Raycast(origin, -Vector3.yAxis * distance, query)
				if hit and hit.Normal.Y >= minimumNormalY then
					local gap = wheel.Position.Y - radius - hit.Position.Y
					if gap <= Config.GroundContactGrace then
						normal += hit.Normal
						contactCount += 1
					end
					table.insert(wheels, { part = wheel, radius = radius, groundY = hit.Position.Y })
				end
			end
		end
	end
	if contactCount == 0 then
		return nil
	end
	return { normal = normal.Unit, wheels = wheels, query = query }
end

local function stepLiftAcceleration(root: BasePart, direction: Vector3, support): number
	if horizontal(root.AssemblyLinearVelocity):Dot(direction) > Config.StepMaxClimbSpeed then
		return 0
	end
	local stepHeight = 0
	for _, sample in ipairs(support.wheels) do
		local bottom = sample.part.Position - Vector3.yAxis * sample.radius
		local wall = workspace:Raycast(
			Vector3.new(bottom.X, sample.groundY + 0.06, bottom.Z),
			direction * (sample.radius + Config.StepProbeDistance),
			support.query
		)
		if wall and wall.Normal.Y < 0.5 then
			local above = wall.Position + direction * 0.12
			above = Vector3.new(above.X, sample.groundY + Config.StepMaxHeight + 0.1, above.Z)
			local top = workspace:Raycast(
				above,
				-Vector3.yAxis * (Config.StepMaxHeight + Config.StepClearance + 0.1),
				support.query
			)
			if top and top.Normal.Y >= math.cos(math.rad(Config.GroundMaxSlopeAngle)) then
				local height = top.Position.Y - bottom.Y
				local obstacleHeight = top.Position.Y - sample.groundY
				if
					obstacleHeight > 0.05
					and obstacleHeight <= Config.StepMaxHeight
					and height > -Config.StepClearance
				then
					stepHeight = math.max(stepHeight, height + Config.StepClearance)
				end
			end
		end
	end
	if stepHeight == 0 then
		return 0
	end
	local desiredUpSpeed = math.min(stepHeight * Config.StepLiftResponse, Config.StepMaxUpSpeed)
	return math.clamp(
		workspace.Gravity + (desiredUpSpeed - root.AssemblyLinearVelocity.Y) * Config.StepLiftResponse,
		0,
		workspace.Gravity * Config.StepMaxSupportRatio
	)
end

function CartMotion.GroundAssistForce(root: BasePart, driveForce: Vector3, support): Vector3
	local drive = horizontal(driveForce)
	if not support or drive.Magnitude < Config.SteeringMinForce then
		return Vector3.zero
	end
	local mass = root.AssemblyMass
	local effort = math.clamp(drive.Magnitude / (mass * Config.GroundAssistFullAcceleration), 0, 1)
	local normal = support.normal
	local tangent = (drive.Unit - normal * drive.Unit:Dot(normal)).Unit
	-- Cancel only the gravity along a supported slope; retain the normal weight on the wheels.
	local slopeGravity = (Vector3.yAxis - normal * normal.Y) * workspace.Gravity
	local slopeDrive = tangent * drive.Magnitude - drive
	local stepAcceleration = stepLiftAcceleration(root, drive.Unit, support)
	-- A lifted wheel no longer supplies the slope's normal reaction.
	local slopeWeight = math.max(0, 1 - stepAcceleration / workspace.Gravity)
	local stepLift = Vector3.yAxis * stepAcceleration
	return slopeDrive + (slopeGravity * slopeWeight + stepLift) * mass * effort
end

function CartMotion.PullForce(
	root: BasePart,
	hand: Attachment,
	playerRoot: BasePart,
	pullAttachment: Attachment?,
	slackLength: number?
): (Vector3, number)
	local pull = pullAttachment or root:FindFirstChild("PullAttachment")
	if not pull or not pull:IsA("Attachment") then
		return Vector3.zero, 0
	end
	local offset = horizontal(hand.WorldPosition - pull.WorldPosition)
	if offset.Magnitude <= 0.05 then
		return Vector3.zero, 0
	end

	local direction = offset.Unit
	local stretch = math.max(0, offset.Magnitude - (slackLength or Config.RopeSlackLength))
	local relativeVelocity = horizontal(playerRoot.AssemblyLinearVelocity - root.AssemblyLinearVelocity)
	local separationSpeed = relativeVelocity:Dot(direction)
	local acceleration = math.clamp(
		Config.PullSpringAccelerationPerStud * stretch + Config.PullDampingAcceleration * separationSpeed,
		0,
		Config.MaxPullAcceleration
	)
	-- Scale down only while the cart is already moving toward the pull target.
	-- Using total speed here made a backward pull ineffective while the cart
	-- was still rolling forward near its speed limit.
	local speedTowardTarget = math.max(0, horizontal(root.AssemblyLinearVelocity):Dot(direction))
	local maxSpeed = mudAdjustedSpeed(root, Config.MaxCartSpeed)
	local softSpeedStart = mudAdjustedSpeed(root, Config.SoftSpeedStart)
	local range = math.max(maxSpeed - softSpeedStart, 0.01)
	local speedFactor = 1 - smoothstep((speedTowardTarget - softSpeedStart) / range)
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
	local maxSpeed = mudAdjustedSpeed(root, Config.MaxPushSpeed)
	local softSpeedStart = mudAdjustedSpeed(root, Config.SoftSpeedStart)
	local range = math.max(maxSpeed - softSpeedStart, 0.01)
	local speedFactor = 1 - smoothstep((speed - softSpeedStart) / range)
	return totalAcceleration * root.AssemblyMass * speedFactor
end

function CartMotion.ResistanceForce(
	root: BasePart,
	maxSpeed: number,
	rollingResistance: number?,
	velocityResistance: number?
): Vector3
	maxSpeed = mudAdjustedSpeed(root, maxSpeed)
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
	if forward.Magnitude < 0.05 then
		return Vector3.zero
	end
	forward = forward.Unit
	local direction = desired.Unit
	-- Preserve straight backing; oblique rear pulls must still turn toward the rope.
	if forward:Dot(direction) < -math.cos(math.rad(Config.SteeringReverseConeAngle)) then
		direction = -direction
	end
	local yawError = forward:Cross(direction).Y
	local yawVelocity = root.AssemblyAngularVelocity.Y
	local torque = yawError * Config.SteeringTorquePerError * speedFactor - yawVelocity * Config.SteeringDampingTorque
	torque = math.clamp(torque, -Config.MaxSteeringTorque, Config.MaxSteeringTorque)
	return Vector3.yAxis * torque
end

function CartMotion.UprightTorque(root: BasePart, groundNormal: Vector3?): Vector3
	local up = root.CFrame.UpVector
	local targetUp = groundNormal or Vector3.yAxis
	local tiltAxis = up:Cross(targetUp)
	if up:Dot(targetUp) < -0.9 and tiltAxis.Magnitude < 0.05 then
		tiltAxis = root.CFrame.RightVector
	end
	local angularVelocity = root.AssemblyAngularVelocity
	local tiltAngularVelocity = angularVelocity - targetUp * angularVelocity:Dot(targetUp)
	local torque = tiltAxis * Config.UprightSpringTorque - tiltAngularVelocity * Config.UprightDampingTorque
	if torque.Magnitude > Config.UprightMaxTorque then
		return torque.Unit * Config.UprightMaxTorque
	end
	return torque
end

return CartMotion
