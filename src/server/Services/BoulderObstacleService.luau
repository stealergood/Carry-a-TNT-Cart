local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.CartConfig)

local BoulderObstacleService = {}

type WedgePair = {
	wedge: Model,
	trafficLight: Model?,
	chutePart: BasePart?,
	topDeck: BasePart?,
	rampWedge: BasePart?,
	phase: number,
	minStones: number,
	maxStones: number,
	minSize: number,
	maxSize: number,
	stoneDamage: number,
}

local ROCK_COLORS = {
	Color3.fromRGB(113, 113, 127), -- Flint
	Color3.fromRGB(130, 130, 134), -- Medium Stone Grey
	Color3.fromRGB(95, 95, 100), -- Dark Stone Grey
	Color3.fromRGB(142, 139, 135), -- Warm Grey
	Color3.fromRGB(105, 108, 112), -- Slate Grey
}

local started = false
local groupA: { WedgePair } = {}
local groupB: { WedgePair } = {}
local activeBouldersFolder: Folder? = nil

local function getOrCreateBoulderFolder(): Folder
	local folder = workspace:FindFirstChild("ActiveBoulders")
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "ActiveBoulders"
		newFolder.Parent = workspace
		folder = newFolder
	end
	return folder :: Folder
end

local function applyStonePhysics(stone: Part)
	stone.CustomPhysicalProperties = PhysicalProperties.new(
		2.4, -- Density
		0.42, -- Friction
		0.18, -- Elasticity
		1.0, -- FrictionWeight
		1.0 -- ElasticityWeight
	)
end

local function spawnSingleBoulder(pair: WedgePair, container: Folder)
	local chute = pair.chutePart
	local topDeck = pair.topDeck

	local minSize = pair.wedge:GetAttribute("MinStoneSize") or pair.minSize
	local maxSize = pair.wedge:GetAttribute("MaxStoneSize") or pair.maxSize
	local stoneSize = minSize + math.random() * (maxSize - minSize)
	stoneSize = math.round(stoneSize * 10) / 10

	local stone = Instance.new("Part")
	stone.Name = "Boulder"
	stone.Shape = Enum.PartType.Ball
	stone.Size = Vector3.new(stoneSize, stoneSize, stoneSize)
	stone.Material = Enum.Material.Plastic
	stone.MaterialVariant = "Studs"
	stone.Color = ROCK_COLORS[math.random(1, #ROCK_COLORS)]
	stone.Anchored = false
	stone.CanCollide = true
	stone.CollisionGroup = "Default"
	applyStonePhysics(stone)

	-- Determine spawn position in front of chute recess on top deck
	local forward = (chute and chute.CFrame.LookVector) or Vector3.new(1, 0, 0)
	local right = (chute and chute.CFrame.RightVector) or Vector3.new(0, 0, 1)
	local chutePos = chute and chute.Position or pair.wedge:GetPivot().Position

	local deckTopY = (topDeck and (topDeck.Position.Y + topDeck.Size.Y * 0.5)) or (chutePos.Y - 2.1)
	local spawnY = deckTopY + (stoneSize * 0.5) + 0.25

	local maxSpread = (chute and math.max(2, chute.Size.X - 2.5)) or 8.0
	local jitter = (math.random() - 0.5) * maxSpread

	local spawnX = chutePos.X + (forward.X * 3.0)
	local spawnZ = chutePos.Z + (right.Z * jitter)

	stone.CFrame = CFrame.new(spawnX, spawnY, spawnZ)

	-- Forward roll impulse towards +X (down the ramp)
	local speed = math.random(12, 17)
	local zSpread = (math.random() - 0.5) * 3
	stone.AssemblyLinearVelocity = Vector3.new(forward.X * speed, -2, forward.Z * speed + zSpread)
	stone.AssemblyAngularVelocity = Vector3.new(0, 0, -math.random(5, 9))

	-- Tag for Cart Damage
	CollectionService:AddTag(stone, Config.DamageTag)
	if Config.BoulderDamageTag then
		CollectionService:AddTag(stone, Config.BoulderDamageTag)
	end
	stone:SetAttribute("Damage", pair.stoneDamage)

	-- Player Character Contact Damage
	local hitDebounce: { [Player]: number } = {}
	local touchedConn: RBXScriptConnection?
	touchedConn = stone.Touched:Connect(function(hit)
		if not hit or not hit.Parent then
			return
		end
		local character = hit.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			local now = os.clock()
			if hitDebounce[player] and now - hitDebounce[player] < 1.0 then
				return
			end
			hitDebounce[player] = now
			humanoid:TakeDamage(pair.stoneDamage)
		end
	end)

	stone.Destroying:Connect(function()
		if touchedConn then
			touchedConn:Disconnect()
			touchedConn = nil
		end
	end)

	stone.Parent = container

	-- Automatic cleanup: max lifetime of 10s
	Debris:AddItem(stone, 10)
end

local function setGroupState(group: { WedgePair }, stateName: string)
	for _, pair in ipairs(group) do
		if pair.trafficLight and pair.trafficLight.Parent then
			pair.trafficLight:SetAttribute("State", stateName)
		end
	end
end

local function spawnWaveForPair(pair: WedgePair, windowDuration: number, container: Folder)
	task.spawn(function()
		local minStones = pair.wedge:GetAttribute("MinStones") or pair.minStones
		local maxStones = pair.wedge:GetAttribute("MaxStones") or pair.maxStones
		local count = math.random(minStones, maxStones)
		local interval = windowDuration / math.max(1, count)

		for i = 1, count do
			if not started or not pair.wedge.Parent then
				break
			end
			spawnSingleBoulder(pair, container)
			if i < count then
				task.wait(interval + (math.random(-10, 10) * 0.01))
			end
		end
	end)
end

local function runAlternatingPhases()
	task.spawn(function()
		local container = getOrCreateBoulderFolder()

		while started do
			local redDuration = Config.BoulderRedDuration or 5.0
			local yellowDuration = Config.BoulderYellowDuration or 1.5
			local spawnWindow = math.max(1.0, redDuration - yellowDuration)

			-- ========================================================
			-- PHASE 1: Group A (1 & 3) is RED (Spawning Boulders!)
			--          Group B (2 & 4) is GREEN (Safe to Cross!)
			-- ========================================================
			setGroupState(groupA, "Red")
			setGroupState(groupB, "Green")

			for _, pair in ipairs(groupA) do
				spawnWaveForPair(pair, spawnWindow, container)
			end

			task.wait(spawnWindow)
			if not started then
				break
			end

			-- ========================================================
			-- TRANSITION 1: Group B (2 & 4) turns YELLOW (Warning!)
			--               Group A (1 & 3) remains RED (finishing rolls)
			-- ========================================================
			setGroupState(groupB, "Yellow")
			task.wait(yellowDuration)
			if not started then
				break
			end

			-- ========================================================
			-- PHASE 2: Group B (2 & 4) is RED (Spawning Boulders!)
			--          Group A (1 & 3) is GREEN (Safe to Cross!)
			-- ========================================================
			setGroupState(groupB, "Red")
			setGroupState(groupA, "Green")

			for _, pair in ipairs(groupB) do
				spawnWaveForPair(pair, spawnWindow, container)
			end

			task.wait(spawnWindow)
			if not started then
				break
			end

			-- ========================================================
			-- TRANSITION 2: Group A (1 & 3) turns YELLOW (Warning!)
			--               Group B (2 & 4) remains RED (finishing rolls)
			-- ========================================================
			setGroupState(groupA, "Yellow")
			task.wait(yellowDuration)
		end
	end)
end

local function discoverPairs(): ({ WedgePair }, { WedgePair })
	local group1: { WedgePair } = {}
	local group2: { WedgePair } = {}

	local toBiome2 = workspace:FindFirstChild("ObbyLand1") and workspace.ObbyLand1:FindFirstChild("ToBiome2")
	local searchContainers: { Instance } = { toBiome2, workspace }

	local foundWedges: { Model } = {}
	for _, container in ipairs(searchContainers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Model") and child.Name:match("^StoneWedge%d*$") then
					table.insert(foundWedges, child)
				end
			end
		end
	end

	-- Sort wedges by numeric suffix or Z coordinate (approach order)
	table.sort(foundWedges, function(a, b)
		local numA = tonumber(a.Name:match("%d+"))
		local numB = tonumber(b.Name:match("%d+"))
		if numA and numB then
			return numA < numB
		end
		return a:GetPivot().Position.Z > b:GetPivot().Position.Z
	end)

	for index, wedge in ipairs(foundWedges) do
		local light: Model? = nil
		for _, child in ipairs(wedge:GetChildren()) do
			if child:IsA("Model") and child.Name:match("TrafficLight") then
				light = child
				break
			end
		end
		if not light and wedge.Parent then
			light = wedge.Parent:FindFirstChild("TrafficLight" .. index) :: Model?
			if not light then
				for _, child in ipairs(wedge.Parent:GetChildren()) do
					if child:IsA("Model") and child.Name:match("TrafficLight" .. index) then
						light = child
						break
					end
				end
			end
		end

		local details = wedge:FindFirstChild("StoneWedgeDetails")
		local chutePart = (details and details:FindFirstChild("SpawnerChuteRecess") :: BasePart?)
			or wedge:FindFirstChild("SpawnerChuteRecess", true) :: BasePart?
		local topDeck = wedge:FindFirstChild("TopDeck") :: BasePart?
		local rampWedge = wedge:FindFirstChild("RampWedge") :: BasePart?

		-- Determine Phase: odd indices (1, 3) = Phase 1, even indices (2, 4) = Phase 2
		local explicitPhase = wedge:GetAttribute("Phase")
		local phase = (type(explicitPhase) == "number" and explicitPhase) or ((index % 2 == 1) and 1 or 2)

		local minStones = wedge:GetAttribute("MinStones") or Config.BoulderMinCount or 5
		local maxStones = wedge:GetAttribute("MaxStones") or Config.BoulderMaxCount or 10
		local minSize = wedge:GetAttribute("MinStoneSize") or Config.BoulderMinSize or 2.5
		local maxSize = wedge:GetAttribute("MaxStoneSize") or Config.BoulderMaxSize or 4.6
		local stoneDamage = wedge:GetAttribute("StoneDamage") or Config.BoulderPlayerDamage or 15

		-- Set attributes for easy Studio adjustment
		wedge:SetAttribute("Phase", phase)
		wedge:SetAttribute("MinStones", minStones)
		wedge:SetAttribute("MaxStones", maxStones)
		wedge:SetAttribute("MinStoneSize", minSize)
		wedge:SetAttribute("MaxStoneSize", maxSize)
		wedge:SetAttribute("StoneDamage", stoneDamage)

		if light then
			light:SetAttribute("AutoCycle", false)
			-- Default initial state based on phase
			light:SetAttribute("State", phase == 1 and "Red" or "Green")
		end

		local pairRecord: WedgePair = {
			wedge = wedge,
			trafficLight = light,
			chutePart = chutePart,
			topDeck = topDeck,
			rampWedge = rampWedge,
			phase = phase,
			minStones = minStones,
			maxStones = maxStones,
			minSize = minSize,
			maxSize = maxSize,
			stoneDamage = stoneDamage,
		}

		if phase == 1 then
			table.insert(group1, pairRecord)
		else
			table.insert(group2, pairRecord)
		end
	end

	return group1, group2
end

-- Fast cleanup watchdog for out-of-bounds boulders
local function startWatchdog()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.25 then
			return
		end
		accumulator = 0

		if not activeBouldersFolder or not activeBouldersFolder.Parent then
			return
		end

		for _, stone in ipairs(activeBouldersFolder:GetChildren()) do
			if stone:IsA("BasePart") then
				local pos = stone.Position
				if pos.Y < 0 or pos.X > 1175 then
					stone:Destroy()
				end
			end
		end
	end)
end

function BoulderObstacleService.Start()
	if started then
		return
	end
	started = true
	activeBouldersFolder = getOrCreateBoulderFolder()
	groupA, groupB = discoverPairs()

	runAlternatingPhases()
	startWatchdog()
end

return BoulderObstacleService
