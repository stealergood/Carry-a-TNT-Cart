--!strict
-- Generates the complete DesertBiomeObstacleKit for Carry a TNT Cart on the Baseplate.
-- Follows roblox-3d-stud-style: modular 30x30 tiles, pure stud aesthetic (MaterialVariant = "Studs"),
-- DisplayBase with Indonesian NameBoard, and Prop with swept cart clearance (8-12 studs).

local Workspace = game:GetService("Workspace")

local kitFolder = Workspace:FindFirstChild("DesertBiomeObstacleKit")
if kitFolder then
	kitFolder:Destroy()
end

kitFolder = Instance.new("Folder")
kitFolder.Name = "DesertBiomeObstacleKit"
kitFolder.Parent = Workspace

-- ==========================================
-- COLOR PALETTE TOKENS
-- ==========================================
local SandColor = Color3.fromRGB(224, 192, 135)
local SandDark = Color3.fromRGB(196, 160, 105)
local SandLight = Color3.fromRGB(240, 212, 160)
local SandstoneBase = Color3.fromRGB(150, 105, 70)
local SandstoneLight = Color3.fromRGB(210, 145, 95)
local SandstoneMedium = Color3.fromRGB(185, 115, 72)
local SandstoneDark = Color3.fromRGB(155, 90, 52)
local SandstoneDeep = Color3.fromRGB(128, 70, 38)
local WoodDry = Color3.fromRGB(110, 85, 63)
local WoodDark = Color3.fromRGB(78, 58, 42)
local WoodLight = Color3.fromRGB(145, 115, 88)
local WoodWeathered = Color3.fromRGB(120, 95, 75)
local CactusGreen = Color3.fromRGB(79, 121, 66)
local CactusLight = Color3.fromRGB(102, 145, 85)
local CactusDark = Color3.fromRGB(56, 92, 45)
local FlowerRed = Color3.fromRGB(226, 88, 62)
local FlowerYellow = Color3.fromRGB(241, 181, 56)
local WaterBlue = Color3.fromRGB(48, 145, 185)
local BoneIvory = Color3.fromRGB(235, 227, 213)
local ClothRed = Color3.fromRGB(175, 52, 40)
local ClothCream = Color3.fromRGB(245, 238, 222)
local DangerRed = Color3.fromRGB(200, 45, 45)

-- ==========================================
-- BUILDER HELPERS
-- ==========================================
local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	local isSpecial = material == Enum.Material.Neon or material == Enum.Material.Glass
	part.Material = if isSpecial then material else Enum.Material.Plastic
	if not isSpecial then
		part.MaterialVariant = "Studs"
	end
	part.Anchored = true
	part.CanCollide = if canCollide ~= nil then canCollide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function makeWedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?
): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cf
	wedge.Color = color
	local isSpecial = material == Enum.Material.Neon or material == Enum.Material.Glass
	wedge.Material = if isSpecial then material else Enum.Material.Plastic
	if not isSpecial then
		wedge.MaterialVariant = "Studs"
	end
	wedge.Anchored = true
	wedge.CanCollide = if canCollide ~= nil then canCollide else true
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Parent = parent
	return wedge
end

local function createModule(name: string, originCf: CFrame, titleText: string): (Model, Model)
	local module = Instance.new("Model")
	module.Name = name
	module.Parent = kitFolder

	-- DisplayBase
	local displayBase = Instance.new("Model")
	displayBase.Name = "DisplayBase"
	displayBase.Parent = module

	local soilPad = makePart(
		displayBase,
		"SoilPad",
		Vector3.new(30, 0.8, 30),
		originCf * CFrame.new(0, -0.4, 0),
		SandstoneBase,
		Enum.Material.Plastic,
		true
	)
	module.PrimaryPart = soilPad

	makePart(
		displayBase,
		"SandTop",
		Vector3.new(30, 0.12, 30),
		originCf * CFrame.new(0, 0.06, 0),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	makePart(
		displayBase,
		"LabelPost",
		Vector3.new(0.55, 3.0, 0.55),
		originCf * CFrame.new(-6, 1.55, 13),
		WoodWeathered,
		Enum.Material.Plastic,
		false
	)
	makePart(
		displayBase,
		"LabelPost",
		Vector3.new(0.55, 3.0, 0.55),
		originCf * CFrame.new(6, 1.55, 13),
		WoodWeathered,
		Enum.Material.Plastic,
		false
	)

	local nameBoard = makePart(
		displayBase,
		"NameBoard",
		Vector3.new(18, 2.5, 0.45),
		originCf * CFrame.new(0, 3.45, 13) * CFrame.Angles(0, math.pi, 0),
		WoodDark,
		Enum.Material.Plastic,
		false
	)

	local sg = Instance.new("SurfaceGui")
	sg.Name = "SampleLabel"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(800, 110)
	sg.LightInfluence = 0
	sg.Parent = nameBoard

	local tl = Instance.new("TextLabel")
	tl.Name = "Title"
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.Position = UDim2.new(0, 0, 0, 0)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextColor3 = Color3.fromRGB(255, 235, 190)
	tl.TextScaled = true
	tl.Text = titleText
	tl.Parent = sg

	-- Prop container
	local prop = Instance.new("Model")
	prop.Name = "Prop"
	prop.Parent = module

	return module, prop
end

-- ============================================================================
-- 01. CACTUS CHICANE ("CELAH KAKTUS")
-- Slalom winding between two major saguaro and prickly pear cactus stands.
-- Swept clearance ~9-10 studs in an S-curve.
-- ============================================================================
local function build01_CactusChicane(originCf: CFrame)
	local _, prop = createModule("01_CactusChicane", originCf, "CELAH KAKTUS")

	-- West Cactus Stand
	local westStand = Instance.new("Model")
	westStand.Name = "WestCactusCluster"
	westStand.Parent = prop

	makePart(
		westStand,
		"SandMound1",
		Vector3.new(9, 0.6, 9),
		originCf * CFrame.new(-7.5, 0.35, 3),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"SandMound2",
		Vector3.new(6, 0.5, 6),
		originCf * CFrame.new(-8, 0.85, 3),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- Tall Saguaro (Trunk + 2 Arms)
	makePart(
		westStand,
		"SaguaroTrunk",
		Vector3.new(2.4, 9.5, 2.4),
		originCf * CFrame.new(-7.5, 5.5, 3),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"SaguaroCrown",
		Vector3.new(2.2, 0.8, 2.2),
		originCf * CFrame.new(-7.5, 10.5, 3),
		CactusLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"CrownFlower",
		Vector3.new(1.2, 0.5, 1.2),
		originCf * CFrame.new(-7.5, 11.0, 3),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	-- Left arm
	makePart(
		westStand,
		"ArmLeftHoriz",
		Vector3.new(2.2, 1.8, 1.8),
		originCf * CFrame.new(-9.5, 5.8, 3),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"ArmLeftVert",
		Vector3.new(1.8, 4.0, 1.8),
		originCf * CFrame.new(-10.4, 7.8, 3),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)

	-- Right arm
	makePart(
		westStand,
		"ArmRightHoriz",
		Vector3.new(2.0, 1.8, 1.8),
		originCf * CFrame.new(-5.5, 4.5, 3),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"ArmRightVert",
		Vector3.new(1.8, 3.2, 1.8),
		originCf * CFrame.new(-4.6, 6.1, 3),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)

	-- Prickly pear pads
	makePart(
		westStand,
		"PearPad1",
		Vector3.new(2.4, 2.8, 0.6),
		originCf * CFrame.new(-5.5, 1.8, 5.5) * CFrame.Angles(0, 0.4, 0.2),
		CactusLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"PearPad2",
		Vector3.new(1.8, 2.0, 0.5),
		originCf * CFrame.new(-5.0, 3.5, 5.8) * CFrame.Angles(0, -0.3, 0.4),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westStand,
		"PearFlower",
		Vector3.new(0.6, 0.6, 0.6),
		originCf * CFrame.new(-4.8, 4.6, 6.0),
		FlowerYellow,
		Enum.Material.Plastic,
		false
	)

	-- East Cactus Stand
	local eastStand = Instance.new("Model")
	eastStand.Name = "EastCactusCluster"
	eastStand.Parent = prop

	makePart(
		eastStand,
		"SandMound1",
		Vector3.new(8, 0.6, 8),
		originCf * CFrame.new(7.5, 0.35, -5),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastStand,
		"SandMound2",
		Vector3.new(5.5, 0.5, 5.5),
		originCf * CFrame.new(7.5, 0.85, -5),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- Medium Saguaro
	makePart(
		eastStand,
		"SaguaroTrunk",
		Vector3.new(2.2, 7.5, 2.2),
		originCf * CFrame.new(7.5, 4.5, -5),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastStand,
		"SaguaroCrown",
		Vector3.new(2.0, 0.6, 2.0),
		originCf * CFrame.new(7.5, 8.4, -5),
		CactusLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastStand,
		"ArmEastHoriz",
		Vector3.new(2.0, 1.6, 1.6),
		originCf * CFrame.new(9.4, 5.0, -5),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastStand,
		"ArmEastVert",
		Vector3.new(1.6, 3.0, 1.6),
		originCf * CFrame.new(10.2, 6.6, -5),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)

	-- Barrel Cactus
	makePart(
		eastStand,
		"BarrelTrunk",
		Vector3.new(2.4, 2.4, 2.4),
		originCf * CFrame.new(5.2, 1.6, -3.2),
		CactusDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastStand,
		"BarrelBud",
		Vector3.new(0.8, 0.6, 0.8),
		originCf * CFrame.new(5.2, 2.9, -3.2),
		FlowerYellow,
		Enum.Material.Plastic,
		false
	)

	-- Decorative desert pebbles
	makePart(
		prop,
		"Pebble1",
		Vector3.new(1.5, 0.8, 1.2),
		originCf * CFrame.new(-3.2, 0.45, 6),
		SandstoneDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		prop,
		"Pebble2",
		Vector3.new(1.2, 0.6, 1.5),
		originCf * CFrame.new(4.0, 0.35, -8),
		SandstoneMedium,
		Enum.Material.Plastic,
		false
	)
	makePart(
		prop,
		"DeadBush",
		Vector3.new(1.8, 1.5, 1.8),
		originCf * CFrame.new(11.0, 0.8, 2),
		WoodWeathered,
		Enum.Material.Plastic,
		false
	)
end

-- ============================================================================
-- 02. DUNE HUMP RAMP ("RAMP BUKIT PASIR")
-- Stepped wedge dune ramp (+3.5 studs crest), 12-stud wide lane, flanked by rock walls.
-- ============================================================================
local function build02_DuneHumpRamp(originCf: CFrame)
	local _, prop = createModule("02_DuneHumpRamp", originCf, "RAMP BUKIT PASIR")

	local rampModel = Instance.new("Model")
	rampModel.Name = "SandDuneRamp"
	rampModel.Parent = prop

	-- Approach Wedge 1 (Z: 14 to 5, Y: 0 to 1.8)
	makeWedge(
		rampModel,
		"SouthRampLow",
		Vector3.new(12, 1.8, 9),
		originCf * CFrame.new(0, 0.95, 9.5) * CFrame.Angles(0, math.pi, 0),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- Approach Wedge 2 (Z: 5 to 0, Y: 1.8 to 3.5)
	makePart(
		rampModel,
		"SouthRampSubBase",
		Vector3.new(12, 1.8, 5),
		originCf * CFrame.new(0, 0.95, 2.5),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		rampModel,
		"SouthRampHigh",
		Vector3.new(12, 1.7, 5),
		originCf * CFrame.new(0, 2.65, 2.5) * CFrame.Angles(0, math.pi, 0),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- Crest Flat Top (Z: 0 to -4, Y: 3.5)
	makePart(
		rampModel,
		"CrestBase",
		Vector3.new(12, 3.5, 4),
		originCf * CFrame.new(0, 1.8, -2),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- Descent Wedge 1 (Z: -4 to -9, Y: 3.5 down to 1.5)
	makePart(
		rampModel,
		"NorthDescentSubBase",
		Vector3.new(12, 1.5, 5),
		originCf * CFrame.new(0, 0.8, -6.5),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		rampModel,
		"NorthDescentHigh",
		Vector3.new(12, 2.0, 5),
		originCf * CFrame.new(0, 2.5, -6.5),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- Descent Wedge 2 (Z: -9 to -14, Y: 1.5 down to 0)
	makeWedge(
		rampModel,
		"NorthDescentLow",
		Vector3.new(12, 1.5, 5),
		originCf * CFrame.new(0, 0.8, -11.5),
		SandColor,
		Enum.Material.Plastic,
		true
	)

	-- West Flank (Sandstone Tiered Buttress)
	local westFlank = Instance.new("Model")
	westFlank.Name = "WestFlank"
	westFlank.Parent = prop

	makePart(
		westFlank,
		"StoneTier1",
		Vector3.new(6, 2.0, 24),
		originCf * CFrame.new(-9.5, 1.0, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westFlank,
		"StoneTier2",
		Vector3.new(5, 2.5, 18),
		originCf * CFrame.new(-10.0, 3.0, -1),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westFlank,
		"StoneTier3",
		Vector3.new(4, 1.5, 12),
		originCf * CFrame.new(-10.5, 4.8, -2),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	-- Small saguaro on flank
	makePart(
		westFlank,
		"FlankCactus",
		Vector3.new(1.8, 5.0, 1.8),
		originCf * CFrame.new(-10.5, 7.8, -2),
		CactusGreen,
		Enum.Material.Plastic,
		true
	)

	-- East Flank (Sandstone Tiered Buttress)
	local eastFlank = Instance.new("Model")
	eastFlank.Name = "EastFlank"
	eastFlank.Parent = prop

	makePart(
		eastFlank,
		"StoneTier1",
		Vector3.new(6, 2.0, 24),
		originCf * CFrame.new(9.5, 1.0, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastFlank,
		"StoneTier2",
		Vector3.new(5, 2.5, 18),
		originCf * CFrame.new(10.0, 3.0, 1),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastFlank,
		"StoneTier3",
		Vector3.new(4, 1.5, 12),
		originCf * CFrame.new(10.5, 4.8, 2),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastFlank,
		"DesertShrub",
		Vector3.new(2, 2, 2),
		originCf * CFrame.new(10.5, 6.2, 2),
		WoodDry,
		Enum.Material.Plastic,
		false
	)
end

-- ============================================================================
-- 03. QUICKSAND MUD PIT ("PASIR HISAP")
-- Treacherous sunken pit in center; twin safe tracks (wooden plank bridge vs packed sandstone).
-- ============================================================================
local function build03_QuicksandMudPit(originCf: CFrame)
	local _, prop = createModule("03_QuicksandMudPit", originCf, "PASIR HISAP")

	local pitModel = Instance.new("Model")
	pitModel.Name = "HazardPit"
	pitModel.Parent = prop

	-- Sunken center basin (soft mud/sand)
	makePart(
		pitModel,
		"MudSurface",
		Vector3.new(10, 0.25, 18),
		originCf * CFrame.new(0, 0.14, 0),
		SandDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		pitModel,
		"MudSlime1",
		Vector3.new(4, 0.1, 5),
		originCf * CFrame.new(-1.5, 0.28, 2),
		Color3.fromRGB(160, 115, 70),
		Enum.Material.Plastic,
		false
	)
	makePart(
		pitModel,
		"MudSlime2",
		Vector3.new(5, 0.1, 4),
		originCf * CFrame.new(1.8, 0.28, -3),
		Color3.fromRGB(150, 100, 60),
		Enum.Material.Plastic,
		false
	)

	-- Half-sunken wagon wheel
	local wheel = makePart(
		pitModel,
		"SubmergedWheel",
		Vector3.new(0.6, 3.2, 3.2),
		originCf * CFrame.new(1.5, 0.8, 1.0) * CFrame.Angles(0.3, 0.2, 0.4),
		WoodDark,
		Enum.Material.Plastic,
		false
	)
	wheel.Shape = Enum.PartType.Cylinder

	-- Creature rib bones protruding
	makePart(
		pitModel,
		"RibBone1",
		Vector3.new(0.4, 2.5, 0.4),
		originCf * CFrame.new(-2.2, 0.9, -2) * CFrame.Angles(0, 0, 0.4),
		BoneIvory,
		Enum.Material.Plastic,
		false
	)
	makePart(
		pitModel,
		"RibBone2",
		Vector3.new(0.4, 2.8, 0.4),
		originCf * CFrame.new(-2.0, 1.0, 0) * CFrame.Angles(0, 0, 0.5),
		BoneIvory,
		Enum.Material.Plastic,
		false
	)
	makePart(
		pitModel,
		"RibBone3",
		Vector3.new(0.4, 2.2, 0.4),
		originCf * CFrame.new(-2.4, 0.8, 2) * CFrame.Angles(0, 0, 0.35),
		BoneIvory,
		Enum.Material.Plastic,
		false
	)

	-- 4 Warning stakes at pit corners
	local function makeWarningStake(x: number, z: number)
		local post = makePart(
			pitModel,
			"WarnStake",
			Vector3.new(0.6, 4.0, 0.6),
			originCf * CFrame.new(x, 2.0, z),
			WoodDark,
			Enum.Material.Plastic,
			true
		)
		makePart(
			pitModel,
			"WarnFlag",
			Vector3.new(0.1, 1.2, 1.6),
			originCf * CFrame.new(x, 3.4, z + (z > 0 and 0.8 or -0.8)),
			DangerRed,
			Enum.Material.Plastic,
			false
		)
	end
	makeWarningStake(-4.8, 9)
	makeWarningStake(4.8, 9)
	makeWarningStake(-4.8, -9)
	makeWarningStake(4.8, -9)

	-- SAFE ROUTE A: West Wooden Corduroy Boardwalk (width 7 studs: X = -5 to -12)
	local westRoute = Instance.new("Model")
	westRoute.Name = "WestBoardwalkTrack"
	westRoute.Parent = prop

	makePart(
		westRoute,
		"SubBase",
		Vector3.new(7.5, 0.4, 28),
		originCf * CFrame.new(-8.8, 0.22, 0),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	-- Wooden planks along Z
	for z = -12, 12, 2.2 do
		makePart(
			westRoute,
			"Plank",
			Vector3.new(6.8, 0.35, 1.8),
			originCf * CFrame.new(-8.8, 0.55, z),
			(math.abs(z) % 4 == 0) and WoodWeathered or WoodDry,
			Enum.Material.Plastic,
			true
		)
	end

	-- SAFE ROUTE B: East Packed Sandstone Ridge (width 7 studs: X = +5 to +12)
	local eastRoute = Instance.new("Model")
	eastRoute.Name = "EastSandstoneTrack"
	eastRoute.Parent = prop

	makePart(
		eastRoute,
		"StoneRidgeBase",
		Vector3.new(7.5, 0.6, 28),
		originCf * CFrame.new(8.8, 0.32, 0),
		SandstoneBase,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastRoute,
		"StoneRidgeTop",
		Vector3.new(6.5, 0.2, 26),
		originCf * CFrame.new(8.8, 0.65, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	-- Curb stones along inner edge
	for z = -10, 10, 4 do
		makePart(
			eastRoute,
			"CurbStone",
			Vector3.new(1.0, 0.8, 3.2),
			originCf * CFrame.new(5.5, 0.75, z),
			SandstoneDark,
			Enum.Material.Plastic,
			true
		)
	end
end

-- ============================================================================
-- 04. RUINED PILLAR GATE ("PILAR RERUNTUHAN")
-- Ancient collapsed sandstone columns and rubble framing a 9.5-stud center gate.
-- ============================================================================
local function build04_RuinedPillarGate(originCf: CFrame)
	local _, prop = createModule("04_RuinedPillarGate", originCf, "PILAR RERUNTUHAN")

	-- West Standing Column (Tall & Imposing)
	local westCol = Instance.new("Model")
	westCol.Name = "WestStandingPillar"
	westCol.Parent = prop

	makePart(
		westCol,
		"PlinthBase",
		Vector3.new(4.5, 1.4, 4.5),
		originCf * CFrame.new(-7.5, 0.75, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westCol,
		"ShaftLower",
		Vector3.new(3.4, 4.0, 3.4),
		originCf * CFrame.new(-7.5, 3.4, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westCol,
		"ShaftMidRing",
		Vector3.new(3.8, 0.8, 3.8),
		originCf * CFrame.new(-7.5, 5.8, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westCol,
		"ShaftUpper",
		Vector3.new(3.2, 4.0, 3.2),
		originCf * CFrame.new(-7.5, 8.2, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westCol,
		"CapitalBase",
		Vector3.new(4.2, 1.2, 4.2),
		originCf * CFrame.new(-7.5, 10.8, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westCol,
		"CapitalTop",
		Vector3.new(4.8, 0.8, 4.8),
		originCf * CFrame.new(-7.5, 11.8, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)

	-- Architrave beam broken on west side
	makePart(
		westCol,
		"BrokenBeam",
		Vector3.new(3.5, 2.0, 5.0),
		originCf * CFrame.new(-10.5, 1.1, 0) * CFrame.Angles(0, 0.2, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)

	-- East Collapsed Column (Broken base + Toppled upper drums)
	local eastCol = Instance.new("Model")
	eastCol.Name = "EastRuinedPillar"
	eastCol.Parent = prop

	makePart(
		eastCol,
		"PlinthBase",
		Vector3.new(4.5, 1.4, 4.5),
		originCf * CFrame.new(7.5, 0.75, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastCol,
		"FracturedStub",
		Vector3.new(3.4, 2.5, 3.4),
		originCf * CFrame.new(7.5, 2.65, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastCol,
		"FractureJagged",
		Vector3.new(2.4, 1.2, 2.0),
		originCf * CFrame.new(7.8, 4.3, 0.4),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)

	-- Toppled drum sections fallen to the side
	makePart(
		eastCol,
		"FallenDrum1",
		Vector3.new(3.2, 4.5, 3.2),
		originCf * CFrame.new(10.5, 1.8, 1.5) * CFrame.Angles(0.3, 0.2, 1.57),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastCol,
		"FallenCapital",
		Vector3.new(4.5, 2.0, 4.5),
		originCf * CFrame.new(12.5, 1.5, -2.5) * CFrame.Angles(-0.2, 0.5, 0.3),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)

	-- Rubble Piles
	makePart(
		prop,
		"Rubble1",
		Vector3.new(2.2, 1.2, 2.5),
		originCf * CFrame.new(-6.0, 0.65, 3.5),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		prop,
		"Rubble2",
		Vector3.new(2.5, 1.0, 2.2),
		originCf * CFrame.new(6.2, 0.55, -3.2),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)

	-- Ancient stone threshold paving embedded in center lane (CanCollide = true, flush with sand)
	makePart(
		prop,
		"ThresholdPaving1",
		Vector3.new(8.0, 0.15, 3.0),
		originCf * CFrame.new(0, 0.1, 0),
		SandstoneBase,
		Enum.Material.Plastic,
		true
	)
	makePart(
		prop,
		"ThresholdPaving2",
		Vector3.new(7.0, 0.15, 2.0),
		originCf * CFrame.new(0, 0.1, 3.5),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
end

-- ============================================================================
-- 05. WIND-BLOWN SAND DRIFT ("GELOMBANG PASIR")
-- Alternating sweeping barchan dune ridges across the lane forming a chicane.
-- Swept clearance ~9.5 studs.
-- ============================================================================
local function build05_WindBlownSandDrift(originCf: CFrame)
	local _, prop = createModule("05_WindBlownSandDrift", originCf, "GELOMBANG PASIR")

	-- Dune Ridge 1 (South-West: blocks X = -15 to -2, Z = 3 to 7)
	local dune1 = Instance.new("Model")
	dune1.Name = "WestDuneCrest"
	dune1.Parent = prop

	makePart(
		dune1,
		"Base1",
		Vector3.new(13, 0.8, 7),
		originCf * CFrame.new(-8.5, 0.45, 5),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		dune1,
		"Mid1",
		Vector3.new(11, 1.0, 5),
		originCf * CFrame.new(-9.0, 1.25, 5),
		SandColor,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		dune1,
		"WedgeFront1",
		Vector3.new(11, 1.2, 3),
		originCf * CFrame.new(-9.0, 2.25, 6) * CFrame.Angles(0, math.pi, 0),
		SandColor,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		dune1,
		"WedgeBack1",
		Vector3.new(11, 1.2, 3),
		originCf * CFrame.new(-9.0, 2.25, 4),
		SandLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		dune1,
		"CrestCap1",
		Vector3.new(9, 0.4, 1.2),
		originCf * CFrame.new(-9.5, 2.95, 5),
		SandLight,
		Enum.Material.Plastic,
		true
	)

	-- Dune Ridge 2 (North-East: blocks X = +2 to +15, Z = -7 to -3)
	local dune2 = Instance.new("Model")
	dune2.Name = "EastDuneCrest"
	dune2.Parent = prop

	makePart(
		dune2,
		"Base2",
		Vector3.new(13, 0.8, 7),
		originCf * CFrame.new(8.5, 0.45, -5),
		SandDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		dune2,
		"Mid2",
		Vector3.new(11, 1.0, 5),
		originCf * CFrame.new(9.0, 1.25, -5),
		SandColor,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		dune2,
		"WedgeFront2",
		Vector3.new(11, 1.2, 3),
		originCf * CFrame.new(9.0, 2.25, -4) * CFrame.Angles(0, math.pi, 0),
		SandColor,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		dune2,
		"WedgeBack2",
		Vector3.new(11, 1.2, 3),
		originCf * CFrame.new(9.0, 2.25, -6),
		SandLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		dune2,
		"CrestCap2",
		Vector3.new(9, 0.4, 1.2),
		originCf * CFrame.new(9.5, 2.95, -5),
		SandLight,
		Enum.Material.Plastic,
		true
	)

	-- Wind Indicator Weather Vane on a post at side
	local vaneModel = Instance.new("Model")
	vaneModel.Name = "WindIndicator"
	vaneModel.Parent = prop

	makePart(
		vaneModel,
		"Pole",
		Vector3.new(0.6, 7.5, 0.6),
		originCf * CFrame.new(-12, 3.8, 11),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		vaneModel,
		"Arm",
		Vector3.new(2.4, 0.3, 0.3),
		originCf * CFrame.new(-11.2, 7.2, 11),
		WoodLight,
		Enum.Material.Plastic,
		false
	)
	makePart(
		vaneModel,
		"Pennant",
		Vector3.new(1.8, 1.0, 0.1),
		originCf * CFrame.new(-10.6, 6.7, 11),
		ClothRed,
		Enum.Material.Plastic,
		false
	)

	-- Sand ripple details on floor (CanCollide = false)
	for i = 1, 3 do
		makePart(
			prop,
			"SandRipple" .. i,
			Vector3.new(7, 0.1, 0.6),
			originCf * CFrame.new(2.5, 0.12, 8 - (i * 2)),
			SandLight,
			Enum.Material.Plastic,
			false
		)
	end
end

-- ============================================================================
-- 06. FALLEN DESERT TIMBER ("KAYU GURUN TUMBANG")
-- Gnarled petrified acacia tree with uprooted stump ball, sawed center clearance (10 studs).
-- ============================================================================
local function build06_FallenDesertTimber(originCf: CFrame)
	local _, prop = createModule("06_FallenDesertTimber", originCf, "KAYU GURUN TUMBANG")

	-- West Uprooted Root Ball & Trunk Segment
	local westTree = Instance.new("Model")
	westTree.Name = "WestRootBall"
	westTree.Parent = prop

	-- Massive uprooted root ball
	makePart(
		westTree,
		"RootCore",
		Vector3.new(5.0, 4.5, 5.0),
		originCf * CFrame.new(-11.5, 2.4, 1.5),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	-- Gnarled root prongs
	makePart(
		westTree,
		"Prong1",
		Vector3.new(1.4, 3.8, 1.4),
		originCf * CFrame.new(-13.5, 3.0, 3.0) * CFrame.Angles(0.3, 0, 0.5),
		WoodDry,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westTree,
		"Prong2",
		Vector3.new(1.2, 3.4, 1.2),
		originCf * CFrame.new(-13.0, 2.5, -0.5) * CFrame.Angles(-0.4, 0.2, 0.4),
		WoodDry,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westTree,
		"Prong3",
		Vector3.new(1.4, 2.8, 1.4),
		originCf * CFrame.new(-10.0, 4.2, 2.5) * CFrame.Angles(0.5, -0.3, -0.3),
		WoodDark,
		Enum.Material.Plastic,
		true
	)

	-- West Log extending towards center, sawed cleanly at X = -5.0
	makePart(
		westTree,
		"LogWestMain",
		Vector3.new(6.0, 3.0, 3.0),
		originCf * CFrame.new(-7.8, 1.6, 0.8) * CFrame.Angles(0, -0.15, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	-- Sawed wood face
	makePart(
		westTree,
		"CutFaceWest",
		Vector3.new(0.2, 2.8, 2.8),
		originCf * CFrame.new(-4.8, 1.6, 0.4) * CFrame.Angles(0, -0.15, 0),
		WoodLight,
		Enum.Material.Plastic,
		true
	)

	-- East Fallen Trunk Segment (Extending from X = +5.0 to X = +13.5)
	local eastTree = Instance.new("Model")
	eastTree.Name = "EastLogSegment"
	eastTree.Parent = prop

	-- Sawed wood face
	makePart(
		eastTree,
		"CutFaceEast",
		Vector3.new(0.2, 2.8, 2.8),
		originCf * CFrame.new(4.8, 1.6, -0.4) * CFrame.Angles(0, -0.15, 0),
		WoodLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastTree,
		"LogEastMain",
		Vector3.new(8.0, 3.0, 3.0),
		originCf * CFrame.new(8.8, 1.6, -1.0) * CFrame.Angles(0, -0.15, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)

	-- Branch fork jutting upwards
	makePart(
		eastTree,
		"BranchFork",
		Vector3.new(1.8, 4.5, 1.8),
		originCf * CFrame.new(11.0, 3.8, -1.5) * CFrame.Angles(0.3, 0, -0.4),
		WoodDry,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastTree,
		"BranchTip",
		Vector3.new(1.2, 2.8, 1.2),
		originCf * CFrame.new(12.2, 6.0, -1.8) * CFrame.Angles(0.2, 0.4, -0.6),
		WoodWeathered,
		Enum.Material.Plastic,
		true
	)

	-- Small desert brush around logs (CanCollide = false)
	makePart(
		prop,
		"DeadTwig1",
		Vector3.new(2.2, 1.4, 2.2),
		originCf * CFrame.new(-8.5, 0.8, -2.5),
		WoodDry,
		Enum.Material.Plastic,
		false
	)
	makePart(
		prop,
		"DeadTwig2",
		Vector3.new(1.8, 1.2, 1.8),
		originCf * CFrame.new(7.5, 0.7, 2.0),
		WoodWeathered,
		Enum.Material.Plastic,
		false
	)
end

-- ============================================================================
-- 07. SANDSTONE BOULDERS ("BATU KARANG GURUN")
-- Wind-sculpted desert hoodoo & tiered sandstone rock tower creating 9-stud defile.
-- ============================================================================
local function build07_SandstoneBoulders(originCf: CFrame)
	local _, prop = createModule("07_SandstoneBoulders", originCf, "BATU KARANG GURUN")

	-- West Hoodoo (Balanced Mushroom Rock)
	local hoodoo = Instance.new("Model")
	hoodoo.Name = "WestHoodoo"
	hoodoo.Parent = prop

	-- Tiered pedestal
	makePart(
		hoodoo,
		"BasePlinth",
		Vector3.new(7.0, 1.8, 7.0),
		originCf * CFrame.new(-8.5, 0.9, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		hoodoo,
		"BaseTier2",
		Vector3.new(5.5, 1.5, 5.5),
		originCf * CFrame.new(-8.5, 2.5, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	-- Slender eroded neck
	makePart(
		hoodoo,
		"ErodedNeck",
		Vector3.new(3.2, 3.6, 3.2),
		originCf * CFrame.new(-8.5, 5.0, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	-- Massive mushroom cap rock
	makePart(
		hoodoo,
		"CapStone1",
		Vector3.new(7.5, 1.8, 7.5),
		originCf * CFrame.new(-8.5, 7.6, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		hoodoo,
		"CapStone2",
		Vector3.new(6.0, 1.2, 6.0),
		originCf * CFrame.new(-8.5, 9.0, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)

	-- Secondary side boulder
	makePart(
		hoodoo,
		"SideBoulder",
		Vector3.new(3.5, 2.4, 3.2),
		originCf * CFrame.new(-6.2, 1.2, 4.2),
		SandstoneDeep,
		Enum.Material.Plastic,
		true
	)

	-- East Stratified Sandstone Tower
	local tower = Instance.new("Model")
	tower.Name = "EastRockTower"
	tower.Parent = prop

	makePart(
		tower,
		"Layer1",
		Vector3.new(6.5, 2.2, 6.5),
		originCf * CFrame.new(8.5, 1.1, 0),
		SandstoneDeep,
		Enum.Material.Plastic,
		true
	)
	makePart(
		tower,
		"Layer2",
		Vector3.new(5.8, 2.0, 5.8),
		originCf * CFrame.new(8.5, 3.1, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		tower,
		"Layer3",
		Vector3.new(5.0, 2.0, 5.0),
		originCf * CFrame.new(8.5, 5.0, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		tower,
		"Layer4",
		Vector3.new(4.2, 1.8, 4.2),
		originCf * CFrame.new(8.5, 6.8, 0),
		SandstoneBase,
		Enum.Material.Plastic,
		true
	)
	makePart(
		tower,
		"TowerTop",
		Vector3.new(2.8, 1.5, 2.8),
		originCf * CFrame.new(8.5, 8.4, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)

	-- Flanking boulders
	makePart(
		tower,
		"FlankRock1",
		Vector3.new(3.2, 2.2, 3.5),
		originCf * CFrame.new(6.2, 1.1, -3.8),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		tower,
		"FlankRock2",
		Vector3.new(3.0, 1.6, 2.8),
		originCf * CFrame.new(11.2, 0.8, 3.5),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)

	-- Desert floor pebbles & dry vegetation (CanCollide = false)
	makePart(
		prop,
		"FloorPebble",
		Vector3.new(1.2, 0.5, 1.5),
		originCf * CFrame.new(-3.5, 0.3, -2.5),
		SandstoneDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		prop,
		"DrySprout",
		Vector3.new(1.0, 1.5, 1.0),
		originCf * CFrame.new(4.2, 0.8, 3.0),
		CactusGreen,
		Enum.Material.Plastic,
		false
	)
end

-- ============================================================================
-- 08. OASIS CHASM BRIDGE ("JEMBATAN OASIS")
-- Sunken canyon wash with oasis water pool; crossed by a 10-stud wide wooden bridge.
-- ============================================================================
local function build08_OasisChasmBridge(originCf: CFrame)
	local _, prop = createModule("08_OasisChasmBridge", originCf, "JEMBATAN OASIS")

	-- Chasm Trench (Z: -6 to +6, sunken by 2.2 studs)
	local chasmModel = Instance.new("Model")
	chasmModel.Name = "ChasmBasin"
	chasmModel.Parent = prop

	-- Oasis Pool on East side of trench
	makePart(
		chasmModel,
		"OasisWater",
		Vector3.new(11, 0.2, 11),
		originCf * CFrame.new(9.0, -0.6, 0),
		WaterBlue,
		Enum.Material.Plastic,
		false
	)
	makePart(
		chasmModel,
		"OasisSandBank",
		Vector3.new(11, 0.3, 11),
		originCf * CFrame.new(9.0, -0.85, 0),
		SandDark,
		Enum.Material.Plastic,
		true
	)

	-- Oasis Vegetation (Mini palm trees on oasis shore)
	local oasisFlora = Instance.new("Model")
	oasisFlora.Name = "OasisFlora"
	oasisFlora.Parent = prop

	makePart(
		oasisFlora,
		"PalmTrunk1",
		Vector3.new(0.8, 5.0, 0.8),
		originCf * CFrame.new(12.5, 2.0, -3.5) * CFrame.Angles(0, 0, -0.2),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		oasisFlora,
		"PalmLeaves1",
		Vector3.new(4.0, 0.6, 4.0),
		originCf * CFrame.new(13.0, 4.6, -3.5),
		CactusGreen,
		Enum.Material.Plastic,
		false
	)

	makePart(
		oasisFlora,
		"PalmTrunk2",
		Vector3.new(0.7, 3.8, 0.7),
		originCf * CFrame.new(12.0, 1.4, 3.2) * CFrame.Angles(0.2, 0, -0.15),
		WoodDry,
		Enum.Material.Plastic,
		true
	)
	makePart(
		oasisFlora,
		"PalmLeaves2",
		Vector3.new(3.4, 0.5, 3.4),
		originCf * CFrame.new(12.4, 3.4, 3.2),
		CactusLight,
		Enum.Material.Plastic,
		false
	)

	-- Dry rock banks on West side of trench
	makePart(
		chasmModel,
		"WestChasmBank",
		Vector3.new(8, 1.2, 12),
		originCf * CFrame.new(-10.5, -0.5, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)

	-- Wooden Bridge across chasm (X: -5.5 to +4.5, Z: -6.5 to +6.5, width 10 studs)
	local bridgeModel = Instance.new("Model")
	bridgeModel.Name = "TimberBridge"
	bridgeModel.Parent = prop

	-- Support Stringer Beams
	makePart(
		bridgeModel,
		"BeamWest",
		Vector3.new(1.2, 1.4, 13.5),
		originCf * CFrame.new(-5.0, 0.2, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		bridgeModel,
		"BeamEast",
		Vector3.new(1.2, 1.4, 13.5),
		originCf * CFrame.new(4.2, 0.2, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)

	-- Bridge deck planks
	for z = -6.0, 6.0, 1.2 do
		makePart(
			bridgeModel,
			"DeckPlank",
			Vector3.new(9.8, 0.35, 1.0),
			originCf * CFrame.new(-0.4, 0.85, z),
			(math.abs(math.floor(z)) % 2 == 0) and WoodDry or WoodWeathered,
			Enum.Material.Plastic,
			true
		)
	end

	-- Bridge Guide Rails & Posts
	makePart(
		bridgeModel,
		"RailWest",
		Vector3.new(0.6, 0.8, 13.5),
		originCf * CFrame.new(-5.0, 1.2, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		bridgeModel,
		"RailEast",
		Vector3.new(0.6, 0.8, 13.5),
		originCf * CFrame.new(4.2, 1.2, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)

	-- 4 Corner Posts with guide rope
	local function makeBridgePost(x: number, z: number)
		makePart(
			bridgeModel,
			"Post",
			Vector3.new(0.8, 3.2, 0.8),
			originCf * CFrame.new(x, 2.0, z),
			WoodDark,
			Enum.Material.Plastic,
			true
		)
	end
	makeBridgePost(-5.0, 6.5)
	makeBridgePost(4.2, 6.5)
	makeBridgePost(-5.0, -6.5)
	makeBridgePost(4.2, -6.5)

	-- Guide ropes along rails
	makePart(
		bridgeModel,
		"RopeWest",
		Vector3.new(0.3, 0.3, 13.0),
		originCf * CFrame.new(-5.0, 2.8, 0),
		ClothCream,
		Enum.Material.Plastic,
		false
	)
	makePart(
		bridgeModel,
		"RopeEast",
		Vector3.new(0.3, 0.3, 13.0),
		originCf * CFrame.new(4.2, 2.8, 0),
		ClothCream,
		Enum.Material.Plastic,
		false
	)

	-- Approach Ramps (North and South)
	makeWedge(
		bridgeModel,
		"SouthRamp",
		Vector3.new(10, 0.75, 3.5),
		originCf * CFrame.new(-0.4, 0.45, 8.2) * CFrame.Angles(0, math.pi, 0),
		SandColor,
		Enum.Material.Plastic,
		true
	)
	makeWedge(
		bridgeModel,
		"NorthRamp",
		Vector3.new(10, 0.75, 3.5),
		originCf * CFrame.new(-0.4, 0.45, -8.2),
		SandColor,
		Enum.Material.Plastic,
		true
	)
end

-- ============================================================================
-- 09. DESERT SPIKE BARRIER ("BARIKADE DURI GURUN")
-- Fortified nomadic spike barricade with sandbag base, skull marker, 9.5-stud gate.
-- ============================================================================
local function build09_DesertSpikeBarrier(originCf: CFrame)
	local _, prop = createModule("09_DesertSpikeBarrier", originCf, "BARIKADE DURI GURUN")

	-- West Palisade (X = -13.5 to -4.8, Z = 0)
	local westPalisade = Instance.new("Model")
	westPalisade.Name = "WestSpikePalisade"
	westPalisade.Parent = prop

	-- Sandbag Base
	for x = -13, -5, 2.5 do
		makePart(
			westPalisade,
			"SandbagLow",
			Vector3.new(2.4, 1.0, 2.0),
			originCf * CFrame.new(x, 0.55, 0),
			SandDark,
			Enum.Material.Plastic,
			true
		)
		makePart(
			westPalisade,
			"SandbagHigh",
			Vector3.new(2.2, 0.9, 1.8),
			originCf * CFrame.new(x + 0.8, 1.45, 0),
			SandColor,
			Enum.Material.Plastic,
			true
		)
	end

	-- Sharpened Wooden Stakes angled forward
	for i, x in ipairs({ -12.5, -10.5, -8.5, -6.5 }) do
		local stakeAngle = 0.25 * (i % 2 == 0 and 1 or -1)
		makePart(
			westPalisade,
			"SpikeShaft",
			Vector3.new(0.8, 5.0, 0.8),
			originCf * CFrame.new(x, 2.8, 0.3) * CFrame.Angles(0.35, stakeAngle, 0),
			WoodDark,
			Enum.Material.Plastic,
			true
		)
		makeWedge(
			westPalisade,
			"SpikeTip",
			Vector3.new(0.8, 1.2, 0.8),
			originCf * CFrame.new(x, 5.4, 1.1) * CFrame.Angles(0.35, stakeAngle, 0),
			WoodLight,
			Enum.Material.Plastic,
			true
		)
	end
	-- Horizontal cross-brace timber
	makePart(
		westPalisade,
		"CrossBrace",
		Vector3.new(8.5, 0.7, 0.7),
		originCf * CFrame.new(-9.0, 2.5, -0.6),
		WoodDry,
		Enum.Material.Plastic,
		true
	)

	-- East Palisade (X = +4.8 to +13.5, Z = 0)
	local eastPalisade = Instance.new("Model")
	eastPalisade.Name = "EastSpikePalisade"
	eastPalisade.Parent = prop

	-- Sandbag Base
	for x = 5, 13, 2.5 do
		makePart(
			eastPalisade,
			"SandbagLow",
			Vector3.new(2.4, 1.0, 2.0),
			originCf * CFrame.new(x, 0.55, 0),
			SandDark,
			Enum.Material.Plastic,
			true
		)
		makePart(
			eastPalisade,
			"SandbagHigh",
			Vector3.new(2.2, 0.9, 1.8),
			originCf * CFrame.new(x - 0.8, 1.45, 0),
			SandColor,
			Enum.Material.Plastic,
			true
		)
	end

	-- Sharpened Wooden Stakes angled forward
	for i, x in ipairs({ 6.5, 8.5, 10.5, 12.5 }) do
		local stakeAngle = 0.25 * (i % 2 == 0 and 1 or -1)
		makePart(
			eastPalisade,
			"SpikeShaft",
			Vector3.new(0.8, 5.0, 0.8),
			originCf * CFrame.new(x, 2.8, 0.3) * CFrame.Angles(0.35, stakeAngle, 0),
			WoodDark,
			Enum.Material.Plastic,
			true
		)
		makeWedge(
			eastPalisade,
			"SpikeTip",
			Vector3.new(0.8, 1.2, 0.8),
			originCf * CFrame.new(x, 5.4, 1.1) * CFrame.Angles(0.35, stakeAngle, 0),
			WoodLight,
			Enum.Material.Plastic,
			true
		)
	end
	makePart(
		eastPalisade,
		"CrossBrace",
		Vector3.new(8.5, 0.7, 0.7),
		originCf * CFrame.new(9.0, 2.5, -0.6),
		WoodDry,
		Enum.Material.Plastic,
		true
	)

	-- Overhead Checkpoint Gateway Frame (Full 8.5 studs vertical clearance)
	local gateFrame = Instance.new("Model")
	gateFrame.Name = "GatewayOverhead"
	gateFrame.Parent = prop

	makePart(
		gateFrame,
		"GatePostWest",
		Vector3.new(1.0, 9.5, 1.0),
		originCf * CFrame.new(-4.8, 4.8, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		gateFrame,
		"GatePostEast",
		Vector3.new(1.0, 9.5, 1.0),
		originCf * CFrame.new(4.8, 4.8, 0),
		WoodDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		gateFrame,
		"OverheadBeam",
		Vector3.new(11.5, 1.0, 1.0),
		originCf * CFrame.new(0, 9.2, 0),
		WoodDry,
		Enum.Material.Plastic,
		true
	)

	-- Hanging Cloth Pennants (CanCollide = false)
	makePart(
		gateFrame,
		"Pennant1",
		Vector3.new(1.2, 2.2, 0.1),
		originCf * CFrame.new(-2.2, 7.6, 0),
		ClothRed,
		Enum.Material.Plastic,
		false
	)
	makePart(
		gateFrame,
		"Pennant2",
		Vector3.new(1.2, 2.6, 0.1),
		originCf * CFrame.new(0, 7.4, 0),
		ClothCream,
		Enum.Material.Plastic,
		false
	)
	makePart(
		gateFrame,
		"Pennant3",
		Vector3.new(1.2, 2.2, 0.1),
		originCf * CFrame.new(2.2, 7.6, 0),
		ClothRed,
		Enum.Material.Plastic,
		false
	)

	-- Warning Skull mounted on east post
	makePart(
		eastPalisade,
		"SkullMarker",
		Vector3.new(1.2, 1.2, 1.2),
		originCf * CFrame.new(5.6, 4.8, 0.6),
		BoneIvory,
		Enum.Material.Plastic,
		false
	)
end

-- ============================================================================
-- 10. SUNKEN CANYON ARCH ("NGARAI GURUN")
-- Towering natural red sandstone bluffs spanning a grand arch (8.5 clearance, 11 wide).
-- ============================================================================
local function build10_SunkenCanyonArch(originCf: CFrame)
	local _, prop = createModule("10_SunkenCanyonArch", originCf, "NGARAI GURUN")

	-- West Canyon Bluff (X = -15 to -5.5, Y = 0 to 12)
	local westBluff = Instance.new("Model")
	westBluff.Name = "WestCanyonBluff"
	westBluff.Parent = prop

	makePart(
		westBluff,
		"Base1",
		Vector3.new(9.5, 3.5, 18),
		originCf * CFrame.new(-10.2, 1.75, 0),
		SandstoneDeep,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westBluff,
		"Base2",
		Vector3.new(8.5, 3.5, 16),
		originCf * CFrame.new(-10.7, 5.25, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westBluff,
		"Base3",
		Vector3.new(8.0, 3.0, 14),
		originCf * CFrame.new(-11.0, 8.5, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		westBluff,
		"CliffRim",
		Vector3.new(7.0, 2.5, 12),
		originCf * CFrame.new(-11.5, 11.25, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)

	-- East Canyon Bluff (X = +5.5 to +15, Y = 0 to 12)
	local eastBluff = Instance.new("Model")
	eastBluff.Name = "EastCanyonBluff"
	eastBluff.Parent = prop

	makePart(
		eastBluff,
		"Base1",
		Vector3.new(9.5, 3.5, 18),
		originCf * CFrame.new(10.2, 1.75, 0),
		SandstoneDeep,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastBluff,
		"Base2",
		Vector3.new(8.5, 3.5, 16),
		originCf * CFrame.new(10.7, 5.25, 0),
		SandstoneDark,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastBluff,
		"Base3",
		Vector3.new(8.0, 3.0, 14),
		originCf * CFrame.new(11.0, 8.5, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		eastBluff,
		"CliffRim",
		Vector3.new(7.0, 2.5, 12),
		originCf * CFrame.new(11.5, 11.25, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)

	-- Raptor Nest perched on East Rim
	local nest = Instance.new("Model")
	nest.Name = "RaptorNest"
	nest.Parent = prop

	makePart(
		nest,
		"NestRim",
		Vector3.new(3.5, 0.8, 3.5),
		originCf * CFrame.new(11.5, 12.8, -2.5),
		WoodDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		nest,
		"NestStick1",
		Vector3.new(4.2, 0.4, 0.6),
		originCf * CFrame.new(11.5, 13.0, -2.5) * CFrame.Angles(0, 0.6, 0),
		WoodDry,
		Enum.Material.Plastic,
		false
	)
	makePart(
		nest,
		"NestStick2",
		Vector3.new(4.0, 0.4, 0.6),
		originCf * CFrame.new(11.5, 13.0, -2.5) * CFrame.Angles(0, -0.7, 0),
		WoodDry,
		Enum.Material.Plastic,
		false
	)

	-- Monumental Natural Sandstone Arch spanning across the canyon
	local archModel = Instance.new("Model")
	archModel.Name = "NaturalSandstoneArch"
	archModel.Parent = prop

	-- Arch Shoulders (Springers)
	makePart(
		archModel,
		"SpringerWest",
		Vector3.new(3.0, 3.0, 6.0),
		originCf * CFrame.new(-6.2, 8.8, 0) * CFrame.Angles(0, 0, -0.35),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		archModel,
		"SpringerEast",
		Vector3.new(3.0, 3.0, 6.0),
		originCf * CFrame.new(6.2, 8.8, 0) * CFrame.Angles(0, 0, 0.35),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)

	-- Arch Crown Span (Spans from X = -5 to +5, Under-clearance Y = 8.5 studs, Top Y = 13.5 studs)
	makePart(
		archModel,
		"ArchUnderbelly",
		Vector3.new(9.5, 1.8, 5.0),
		originCf * CFrame.new(0, 9.6, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)
	makePart(
		archModel,
		"ArchCrownMain",
		Vector3.new(11.0, 2.2, 5.5),
		originCf * CFrame.new(0, 11.4, 0),
		SandstoneMedium,
		Enum.Material.Plastic,
		true
	)
	makePart(
		archModel,
		"ArchCrownTop",
		Vector3.new(7.0, 1.4, 4.0),
		originCf * CFrame.new(0, 13.0, 0),
		SandstoneLight,
		Enum.Material.Plastic,
		true
	)

	-- Wind-eroded skylight hole in arch top
	makePart(
		archModel,
		"ErosionAccent",
		Vector3.new(2.0, 0.8, 1.8),
		originCf * CFrame.new(-1.8, 13.8, 0.4),
		SandstoneDark,
		Enum.Material.Plastic,
		false
	)

	-- Canyon roadbed paving stones
	makePart(
		prop,
		"RoadBedSlab1",
		Vector3.new(8.0, 0.15, 6.0),
		originCf * CFrame.new(0, 0.1, -4.0),
		SandstoneBase,
		Enum.Material.Plastic,
		true
	)
	makePart(
		prop,
		"RoadBedSlab2",
		Vector3.new(8.0, 0.15, 6.0),
		originCf * CFrame.new(0, 0.1, 4.0),
		SandstoneBase,
		Enum.Material.Plastic,
		true
	)
end

-- ============================================================================
-- MAIN SPAWNER DISPATCHER
-- Spawns all 10 modules in 2 rows of 5 modules on the clear Baseplate staging area.
-- ============================================================================
local function generateKit()
	print("[DesertBiomeObstacleKit] Starting generation...")

	-- Row 1: Z = -35 (Modules 01 - 05)
	build01_CactusChicane(CFrame.new(70, -0.4, -35))
	build02_DuneHumpRamp(CFrame.new(110, -0.4, -35))
	build03_QuicksandMudPit(CFrame.new(150, -0.4, -35))
	build04_RuinedPillarGate(CFrame.new(190, -0.4, -35))
	build05_WindBlownSandDrift(CFrame.new(230, -0.4, -35))

	-- Row 2: Z = -85 (Modules 06 - 10)
	build06_FallenDesertTimber(CFrame.new(70, -0.4, -85))
	build07_SandstoneBoulders(CFrame.new(110, -0.4, -85))
	build08_OasisChasmBridge(CFrame.new(150, -0.4, -85))
	build09_DesertSpikeBarrier(CFrame.new(190, -0.4, -85))
	build10_SunkenCanyonArch(CFrame.new(230, -0.4, -85))

	local totalCount = #kitFolder:GetDescendants()
	print(
		string.format(
			"[DesertBiomeObstacleKit] Generation complete! Spawned 10 modules with %d total instances.",
			totalCount
		)
	)
	return totalCount
end

return generateKit()
