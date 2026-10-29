local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.CartConstants)

local MazeCameraController = {}

local player = Players.LocalPlayer
local started = false
local isLocked = false

local defaultCameraMode = Enum.CameraMode.Classic
local defaultMinZoom = 0.5
local defaultMaxZoom = 128
local savedThirdPersonZoom = 12

local triggerMasuk: BasePart? = nil
local triggerKeluar: BasePart? = nil
local characterConnections: { RBXScriptConnection } = {}

local function pointInPart(part: BasePart, worldPoint: Vector3, pad: number?): boolean
	local extra = pad or 0
	local localPos = part.CFrame:PointToObjectSpace(worldPoint)
	local half = part.Size * 0.5
	return math.abs(localPos.X) <= half.X + extra
		and math.abs(localPos.Y) <= half.Y + extra
		and math.abs(localPos.Z) <= half.Z + extra
end

local function getAliveCharacterRoot(): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root, humanoid
	end
	return nil, nil
end

local function enableFirstPersonLock()
	local root, humanoid = getAliveCharacterRoot()
	if not root or not humanoid then
		return
	end
	if isLocked then
		if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
		return
	end

	local camera = workspace.CurrentCamera
	if camera then
		local currentDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
		if currentDist >= 4 then
			savedThirdPersonZoom = math.clamp(currentDist, 8, 28)
		end
	end

	isLocked = true
	player:SetAttribute("InMazeFirstPerson", true)
	player.CameraMinZoomDistance = defaultMinZoom
	player.CameraMaxZoomDistance = defaultMaxZoom
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

local function resetCameraLock()
	local wasLocked = isLocked or player.CameraMode == Enum.CameraMode.LockFirstPerson
	isLocked = false
	player:SetAttribute("InMazeFirstPerson", false)

	if not wasLocked then
		return
	end

	player.CameraMode = defaultCameraMode
	player.CameraMaxZoomDistance = defaultMaxZoom
	local restoreZoom = math.clamp(savedThirdPersonZoom, 8, math.max(12, defaultMaxZoom))
	player.CameraMinZoomDistance = restoreZoom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	task.delay(0.05, function()
		if not isLocked then
			player.CameraMinZoomDistance = defaultMinZoom
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
end

local function prepareTriggerPart(part: BasePart)
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

local function bindTriggers()
	local triggerFolder = workspace:FindFirstChild("MazeTriggers", true)
	local foundMasuk = (triggerFolder and triggerFolder:FindFirstChild("TriggerMasuk"))
		or workspace:FindFirstChild("TriggerMasuk", true)
	local foundKeluar = (triggerFolder and triggerFolder:FindFirstChild("TriggerKeluar"))
		or workspace:FindFirstChild("TriggerKeluar", true)

	triggerMasuk = if foundMasuk and foundMasuk:IsA("BasePart") then foundMasuk else nil
	triggerKeluar = if foundKeluar and foundKeluar:IsA("BasePart") then foundKeluar else nil

	if triggerMasuk then
		prepareTriggerPart(triggerMasuk)
	end

	if triggerKeluar then
		prepareTriggerPart(triggerKeluar)
	end
end

local function bindCharacter(character: Model)
	for _, conn in ipairs(characterConnections) do
		conn:Disconnect()
	end
	table.clear(characterConnections)

	-- Always reset camera lock on spawn/respawn.
	resetCameraLock()

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid or not humanoid:IsA("Humanoid") or player.Character ~= character then
			return
		end
		table.insert(
			characterConnections,
			humanoid.Died:Connect(function()
				resetCameraLock()
			end)
		)
	end)
end

function MazeCameraController.Start()
	if started then
		return
	end
	started = true

	defaultCameraMode = player.CameraMode
	defaultMinZoom = player.CameraMinZoomDistance
	defaultMaxZoom = player.CameraMaxZoomDistance

	bindTriggers()

	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and (descendant.Name == "TriggerMasuk" or descendant.Name == "TriggerKeluar") then
			bindTriggers()
		end
	end)

	player.CharacterAdded:Connect(bindCharacter)
	player.CharacterRemoving:Connect(function()
		resetCameraLock()
	end)

	if player.Character then
		bindCharacter(player.Character)
	end

	RunService.Heartbeat:Connect(function()
		local root, humanoid = getAliveCharacterRoot()
		if not root or not humanoid then
			if isLocked then
				resetCameraLock()
			end
			return
		end

		local pos = root.Position
		if triggerKeluar and triggerKeluar.Parent and pointInPart(triggerKeluar, pos, 1.5) then
			if isLocked then
				resetCameraLock()
			end
			return
		end

		if triggerMasuk and triggerMasuk.Parent and pointInPart(triggerMasuk, pos, 1.5) then
			if not isLocked then
				enableFirstPersonLock()
			end
			return
		end

		if isLocked then
			-- Reset if player backed out before the entrance, exited past TriggerKeluar, fell, or teleported out of the maze.
			local outOfZ = (triggerMasuk and pos.Z > triggerMasuk.Position.Z + 4)
				or (triggerKeluar and pos.Z < triggerKeluar.Position.Z - 4)
			local outOfMazePlatform = math.abs(pos.X - 1139) > 55 or pos.Y < 8 or pos.Y > 60
			if outOfZ or outOfMazePlatform then
				resetCameraLock()
			end
		end
	end)
end

return MazeCameraController
