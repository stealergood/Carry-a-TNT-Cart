--!strict
-- Generates the complete Desert Biome Kit for Carry a TNT Cart on the Baseplate.
-- Adheres to the roblox-3d-stud-style visual language: chunky blocky silhouettes,
-- stepped layering, cohesive desert palette, clean collision, and anchored static parts.

local Workspace = game:GetService("Workspace")

local kitFolder = Workspace:FindFirstChild("DesertBiomeKit")
if kitFolder then
	kitFolder:Destroy()
end

kitFolder = Instance.new("Folder")
kitFolder.Name = "DesertBiomeKit"
kitFolder.Parent = Workspace

-- Color Palette Tokens
local SandColor = Color3.fromRGB(224, 192, 135)
local SandDark = Color3.fromRGB(196, 160, 105)
local SandLight = Color3.fromRGB(240, 212, 160)
local AdobeLight = Color3.fromRGB(209, 151, 112)
local AdobeMedium = Color3.fromRGB(182, 119, 78)
local AdobeDark = Color3.fromRGB(142, 85, 52)
local WoodDry = Color3.fromRGB(110, 85, 63)
local WoodDark = Color3.fromRGB(78, 58, 42)
local WoodLight = Color3.fromRGB(145, 115, 88)
local CactusGreen = Color3.fromRGB(79, 121, 66)
local CactusDark = Color3.fromRGB(56, 92, 45)
local FlowerRed = Color3.fromRGB(226, 88, 62)
local FlowerYellow = Color3.fromRGB(241, 181, 56)
local CamelTan = Color3.fromRGB(198, 154, 104)
local CamelLight = Color3.fromRGB(222, 193, 156)
local CamelDark = Color3.fromRGB(146, 107, 68)
local FabricRed = Color3.fromRGB(175, 52, 40)
local FabricTeal = Color3.fromRGB(44, 125, 138)
local FabricCream = Color3.fromRGB(245, 238, 222)
local ClayPot = Color3.fromRGB(188, 90, 54)
local ClayDark = Color3.fromRGB(148, 65, 34)
local BoneIvory = Color3.fromRGB(235, 227, 213)
local BoneHorn = Color3.fromRGB(85, 72, 60)
local DesertStone = Color3.fromRGB(142, 126, 109)
local DesertStoneDark = Color3.fromRGB(110, 96, 82)
local WaterBlue = Color3.fromRGB(48, 132, 168)
local MetalIron = Color3.fromRGB(60, 60, 60)

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

-- ==========================================
-- 0. SHOWCASE PRESENTATION PLATFORM
-- ==========================================
local platform = makePart(
	kitFolder,
	"ShowcasePlatform",
	Vector3.new(130, 1, 150),
	CFrame.new(-160, 0.5, 0),
	SandColor,
	Enum.Material.Sand,
	true
)
platform.TopSurface = Enum.SurfaceType.Studs

-- Perimeter Sandstone Trim
makePart(
	kitFolder,
	"PlatformBorderNorth",
	Vector3.new(132, 1.4, 2),
	CFrame.new(-160, 0.7, -75),
	AdobeDark,
	Enum.Material.Sandstone,
	true
)
makePart(
	kitFolder,
	"PlatformBorderSouth",
	Vector3.new(132, 1.4, 2),
	CFrame.new(-160, 0.7, 75),
	AdobeDark,
	Enum.Material.Sandstone,
	true
)
makePart(
	kitFolder,
	"PlatformBorderWest",
	Vector3.new(2, 1.4, 150),
	CFrame.new(-225, 0.7, 0),
	AdobeDark,
	Enum.Material.Sandstone,
	true
)
makePart(
	kitFolder,
	"PlatformBorderEast",
	Vector3.new(2, 1.4, 150),
	CFrame.new(-95, 0.7, 0),
	AdobeDark,
	Enum.Material.Sandstone,
	true
)

-- Category subfolders
local catBuildings = Instance.new("Folder")
catBuildings.Name = "01_DesertBuildings"
catBuildings.Parent = kitFolder

local catDunes = Instance.new("Folder")
catDunes.Name = "02_SandDunes"
catDunes.Parent = kitFolder

local catTrees = Instance.new("Folder")
catTrees.Name = "03_DeadTrees"
catTrees.Parent = kitFolder

local catCacti = Instance.new("Folder")
catCacti.Name = "04_Cacti"
catCacti.Parent = kitFolder

local catCamel = Instance.new("Folder")
catCamel.Name = "05_Camel"
catCamel.Parent = kitFolder

local catDecor = Instance.new("Folder")
catDecor.Name = "06_DesertDecorations"
catDecor.Parent = kitFolder

-- ==========================================
-- 1. BUILDINGS
-- ==========================================

-- 1A: Desert Watchtower
local function buildDesertWatchtower(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "01_DesertWatchtower"
	m.Parent = catBuildings

	-- Base Plinth
	makePart(
		m,
		"BaseStep",
		Vector3.new(14, 1.2, 14),
		origin * CFrame.new(0, 0.6, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"BaseMain",
		Vector3.new(12, 5, 12),
		origin * CFrame.new(0, 3.7, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)

	-- Arch Entrance Portal
	makePart(
		m,
		"DoorLeft",
		Vector3.new(3.5, 4.2, 1.5),
		origin * CFrame.new(-3.5, 3.3, 5.8),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"DoorRight",
		Vector3.new(3.5, 4.2, 1.5),
		origin * CFrame.new(3.5, 3.3, 5.8),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"DoorLintel",
		Vector3.new(10.5, 1.5, 1.8),
		origin * CFrame.new(0, 5.8, 5.8),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"DoorRecess",
		Vector3.new(3.5, 4.2, 1),
		origin * CFrame.new(0, 3.3, 5.4),
		Color3.fromRGB(30, 20, 15),
		Enum.Material.SmoothPlastic,
		false
	)

	-- Mid Tower Shaft
	makePart(
		m,
		"TowerShaft",
		Vector3.new(9.5, 13, 9.5),
		origin * CFrame.new(0, 12.7, 0),
		AdobeLight,
		Enum.Material.Sandstone
	)
	-- Decorative Sandstone Belt
	makePart(
		m,
		"ShaftBelt",
		Vector3.new(10.2, 1, 10.2),
		origin * CFrame.new(0, 11, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)

	-- Protruding Viga Wooden Poles
	for _, x in ipairs({ -3.5, 0, 3.5 }) do
		makePart(
			m,
			"VigaNorth",
			Vector3.new(0.8, 0.8, 11),
			origin * CFrame.new(x, 17, 0),
			WoodDark,
			Enum.Material.Wood,
			false
		)
	end

	-- Arrow Slits (Slotted Windows)
	for _, z in ipairs({ -5, 5 }) do
		makePart(
			m,
			"WindowSlot",
			Vector3.new(1, 2.5, 0.4),
			origin * CFrame.new(0, 14.5, z),
			Color3.fromRGB(20, 15, 12),
			Enum.Material.SmoothPlastic,
			false
		)
	end

	-- Top Observation Deck
	makePart(m, "DeckFloor", Vector3.new(12, 1, 12), origin * CFrame.new(0, 19.7, 0), WoodDry, Enum.Material.WoodPlanks)
	makePart(m, "DeckBeam1", Vector3.new(12.4, 0.8, 1), origin * CFrame.new(0, 18.8, 5), WoodDark, Enum.Material.Wood)
	makePart(m, "DeckBeam2", Vector3.new(12.4, 0.8, 1), origin * CFrame.new(0, 18.8, -5), WoodDark, Enum.Material.Wood)

	-- Deck Railing
	for _, x in ipairs({ -5.5, 5.5 }) do
		makePart(
			m,
			"RailPost",
			Vector3.new(0.8, 3, 0.8),
			origin * CFrame.new(x, 21.2, 5.5),
			WoodDark,
			Enum.Material.Wood
		)
		makePart(
			m,
			"RailPost",
			Vector3.new(0.8, 3, 0.8),
			origin * CFrame.new(x, 21.2, -5.5),
			WoodDark,
			Enum.Material.Wood
		)
		makePart(
			m,
			"RailBarZ",
			Vector3.new(0.5, 0.6, 11.8),
			origin * CFrame.new(x, 22, 0),
			WoodDry,
			Enum.Material.Wood,
			false
		)
	end
	makePart(
		m,
		"RailBarX1",
		Vector3.new(11.8, 0.6, 0.5),
		origin * CFrame.new(0, 22, 5.5),
		WoodDry,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"RailBarX2",
		Vector3.new(11.8, 0.6, 0.5),
		origin * CFrame.new(0, 22, -5.5),
		WoodDry,
		Enum.Material.Wood,
		false
	)

	-- 4 Canopy Corner Posts
	for _, x in ipairs({ -5, 5 }) do
		for _, z in ipairs({ -5, 5 }) do
			makePart(
				m,
				"CanopyPost",
				Vector3.new(0.8, 6, 0.8),
				origin * CFrame.new(x, 23.2, z),
				WoodDark,
				Enum.Material.Wood
			)
		end
	end

	-- Desert Nomad Striped Fabric Canopy
	local canopyY = 26.2
	for i = -5, 5, 2 do
		local col = if math.abs(i) % 4 == 1 then FabricRed else FabricCream
		makePart(
			m,
			"CanopyStripe",
			Vector3.new(1.9, 0.5, 12),
			origin * CFrame.new(i, canopyY, 0),
			col,
			Enum.Material.Fabric,
			false
		)
	end
	-- Stepped Peak Roof Tier
	makePart(
		m,
		"CanopyPeak",
		Vector3.new(8, 0.6, 8),
		origin * CFrame.new(0, canopyY + 0.5, 0),
		FabricRed,
		Enum.Material.Fabric,
		false
	)

	-- Hanging Brass Lantern
	local lantern = makePart(
		m,
		"LanternGlow",
		Vector3.new(1, 1.4, 1),
		origin * CFrame.new(0, 24.5, 0),
		FlowerYellow,
		Enum.Material.Neon,
		false
	)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 130)
	light.Brightness = 1.5
	light.Range = 16
	light.Parent = lantern

	m.PrimaryPart = m:FindFirstChild("BaseMain") :: BasePart
	return m
end

-- 1B: Desert Adobe Dwelling
local function buildDesertAdobeHouse(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "02_DesertAdobeHouse"
	m.Parent = catBuildings

	-- Main Foundation & Walls
	makePart(
		m,
		"FloorPlinth",
		Vector3.new(16, 1, 14),
		origin * CFrame.new(0, 0.5, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)
	local mainBody = makePart(
		m,
		"MainBody",
		Vector3.new(14, 9, 12),
		origin * CFrame.new(0, 5.5, 0),
		AdobeLight,
		Enum.Material.Sandstone
	)

	-- Stepped Parapet Roof
	makePart(
		m,
		"RoofRim",
		Vector3.new(14.6, 1.2, 12.6),
		origin * CFrame.new(0, 10.3, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"RoofDeck",
		Vector3.new(13.2, 0.5, 11.2),
		origin * CFrame.new(0, 10.1, 0),
		SandColor,
		Enum.Material.Sand
	)
	-- Corner Parapet Merlons
	for _, x in ipairs({ -6.8, 6.8 }) do
		for _, z in ipairs({ -5.8, 5.8 }) do
			makePart(
				m,
				"RoofMerlon",
				Vector3.new(1.4, 1.4, 1.4),
				origin * CFrame.new(x, 11.2, z),
				AdobeDark,
				Enum.Material.Sandstone
			)
		end
	end

	-- Protruding Viga Logs along roofline
	for x = -5, 5, 2.5 do
		makePart(
			m,
			"VigaFront",
			Vector3.new(0.7, 0.7, 13.6),
			origin * CFrame.new(x, 9.2, 0),
			WoodDark,
			Enum.Material.Wood,
			false
		)
	end

	-- Wooden Plank Front Door
	makePart(
		m,
		"DoorFrame",
		Vector3.new(4, 6.2, 1),
		origin * CFrame.new(-3, 4.1, 6.1),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"DoorWood",
		Vector3.new(3, 5.4, 0.5),
		origin * CFrame.new(-3, 3.8, 6.3),
		WoodDry,
		Enum.Material.WoodPlanks
	)
	makePart(
		m,
		"DoorHandle",
		Vector3.new(0.3, 0.8, 0.3),
		origin * CFrame.new(-2, 3.8, 6.6),
		MetalIron,
		Enum.Material.Metal,
		false
	)
	makePart(
		m,
		"DoorStep",
		Vector3.new(4.6, 0.5, 1.6),
		origin * CFrame.new(-3, 0.5, 6.8),
		AdobeDark,
		Enum.Material.Sandstone
	)

	-- Recessed Windows with Wooden Sills
	makePart(
		m,
		"WindowFrame1",
		Vector3.new(2.4, 2.4, 0.6),
		origin * CFrame.new(3.5, 5.5, 6.1),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"WindowGlass1",
		Vector3.new(1.8, 1.8, 0.2),
		origin * CFrame.new(3.5, 5.5, 6.2),
		Color3.fromRGB(25, 20, 18),
		Enum.Material.SmoothPlastic,
		false
	)
	makePart(
		m,
		"WindowSill1",
		Vector3.new(2.8, 0.4, 1),
		origin * CFrame.new(3.5, 4.2, 6.3),
		WoodDark,
		Enum.Material.Wood
	)

	-- Side Bazaar Awning / Fruit & Pottery Stall
	makePart(m, "AwningPost1", Vector3.new(0.6, 6, 0.6), origin * CFrame.new(6.8, 3, 3), WoodDark, Enum.Material.Wood)
	makePart(m, "AwningPost2", Vector3.new(0.6, 6, 0.6), origin * CFrame.new(6.8, 3, -3), WoodDark, Enum.Material.Wood)
	-- Striped Awning Roof
	for i = -3, 3, 1.5 do
		local col = if math.abs(i) % 3 == 0 then FabricTeal else FabricCream
		makePart(
			m,
			"AwningStrip",
			Vector3.new(2.8, 0.3, 1.4),
			origin * CFrame.new(8.2, 5.8, i) * CFrame.Angles(0, 0, math.rad(-15)),
			col,
			Enum.Material.Fabric,
			false
		)
	end
	-- Market Display Bench
	makePart(
		m,
		"MarketTable",
		Vector3.new(2.2, 1.8, 5.5),
		origin * CFrame.new(7.8, 1.4, 0),
		WoodDry,
		Enum.Material.WoodPlanks
	)

	m.PrimaryPart = mainBody
	return m
end

-- 1C: Ancient Sandstone Archway
local function buildAncientSandstoneArch(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "03_AncientSandstoneArch"
	m.Parent = catBuildings

	-- Left Pillar Base & Shaft
	makePart(
		m,
		"LeftPlinth",
		Vector3.new(4.5, 1.5, 4.5),
		origin * CFrame.new(-7, 0.75, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)
	local leftPillar = makePart(
		m,
		"LeftShaft",
		Vector3.new(3.5, 10, 3.5),
		origin * CFrame.new(-7, 6.5, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"LeftCapital",
		Vector3.new(4.5, 1.2, 4.5),
		origin * CFrame.new(-7, 12.1, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)

	-- Right Pillar Base & Shaft
	makePart(
		m,
		"RightPlinth",
		Vector3.new(4.5, 1.5, 4.5),
		origin * CFrame.new(7, 0.75, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"RightShaft",
		Vector3.new(3.5, 10, 3.5),
		origin * CFrame.new(7, 6.5, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"RightCapital",
		Vector3.new(4.5, 1.2, 4.5),
		origin * CFrame.new(7, 12.1, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)

	-- Stepped Arch Haunches
	makePart(
		m,
		"ArchHaunchL1",
		Vector3.new(2.5, 2, 3.2),
		origin * CFrame.new(-4.8, 13, 0),
		AdobeLight,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"ArchHaunchR1",
		Vector3.new(2.5, 2, 3.2),
		origin * CFrame.new(4.8, 13, 0),
		AdobeLight,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"ArchHaunchL2",
		Vector3.new(2.2, 1.8, 3),
		origin * CFrame.new(-2.8, 14, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"ArchHaunchR2",
		Vector3.new(2.2, 1.8, 3),
		origin * CFrame.new(2.8, 14, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)

	-- Central Keystone
	makePart(
		m,
		"Keystone",
		Vector3.new(3.8, 2.4, 3.8),
		origin * CFrame.new(0, 14.8, 0),
		AdobeDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"ArchTopLintel",
		Vector3.new(18.5, 1.4, 4),
		origin * CFrame.new(0, 16.2, 0),
		AdobeMedium,
		Enum.Material.Sandstone
	)

	-- Ancient Weathered Relic Block on Top
	makePart(
		m,
		"RelicPeak",
		Vector3.new(6, 1.2, 3.2),
		origin * CFrame.new(0, 17.5, 0),
		AdobeLight,
		Enum.Material.Sandstone
	)

	m.PrimaryPart = leftPillar
	return m
end

-- 1D: Desert Oasis Water Well
local function buildDesertOasisWell(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "04_DesertOasisWell"
	m.Parent = catBuildings

	-- Octagonal Stepped Stone Well Basin
	local basin = makePart(
		m,
		"WellBasinBase",
		Vector3.new(7, 1, 7),
		origin * CFrame.new(0, 0.5, 0),
		DesertStoneDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"WellWallNorth",
		Vector3.new(5.6, 2.4, 1.2),
		origin * CFrame.new(0, 2, -2.4),
		DesertStone,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"WellWallSouth",
		Vector3.new(5.6, 2.4, 1.2),
		origin * CFrame.new(0, 2, 2.4),
		DesertStone,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"WellWallWest",
		Vector3.new(1.2, 2.4, 3.8),
		origin * CFrame.new(-2.4, 2, 0),
		DesertStone,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"WellWallEast",
		Vector3.new(1.2, 2.4, 3.8),
		origin * CFrame.new(2.4, 2, 0),
		DesertStone,
		Enum.Material.Sandstone
	)

	-- Water surface inside
	makePart(
		m,
		"WaterDisc",
		Vector3.new(3.6, 0.4, 3.6),
		origin * CFrame.new(0, 1.6, 0),
		WaterBlue,
		Enum.Material.Glass,
		false
	)

	-- Wooden Uprights & Windlass
	makePart(
		m,
		"UprightLeft",
		Vector3.new(0.8, 6.5, 0.8),
		origin * CFrame.new(-2.4, 4.5, 0),
		WoodDark,
		Enum.Material.Wood
	)
	makePart(
		m,
		"UprightRight",
		Vector3.new(0.8, 6.5, 0.8),
		origin * CFrame.new(2.4, 4.5, 0),
		WoodDark,
		Enum.Material.Wood
	)
	makePart(m, "CrossBeam", Vector3.new(5.8, 0.8, 0.8), origin * CFrame.new(0, 7.5, 0), WoodDark, Enum.Material.Wood)

	-- Winch Cylinder & Rope
	makePart(
		m,
		"WinchCylinder",
		Vector3.new(3.8, 0.7, 0.7),
		origin * CFrame.new(0, 5.2, 0),
		WoodDry,
		Enum.Material.Wood
	)
	makePart(
		m,
		"WoundRope",
		Vector3.new(1.4, 0.9, 0.9),
		origin * CFrame.new(0, 5.2, 0),
		Color3.fromRGB(160, 130, 90),
		Enum.Material.Fabric,
		false
	)
	makePart(
		m,
		"HangingRope",
		Vector3.new(0.2, 2.4, 0.2),
		origin * CFrame.new(0, 3.8, 0),
		Color3.fromRGB(160, 130, 90),
		Enum.Material.Fabric,
		false
	)

	-- Wooden Bucket
	makePart(m, "Bucket", Vector3.new(1.2, 1.4, 1.2), origin * CFrame.new(0, 2.4, 0), WoodLight, Enum.Material.Wood)

	-- Well Roof Canopy (Pitched Timber Cap)
	makePart(
		m,
		"RoofLeft",
		Vector3.new(3.4, 0.5, 6.2),
		origin * CFrame.new(-1.3, 8.4, 0) * CFrame.Angles(0, 0, math.rad(-25)),
		AdobeMedium,
		Enum.Material.WoodPlanks
	)
	makePart(
		m,
		"RoofRight",
		Vector3.new(3.4, 0.5, 6.2),
		origin * CFrame.new(1.3, 8.4, 0) * CFrame.Angles(0, 0, math.rad(25)),
		AdobeMedium,
		Enum.Material.WoodPlanks
	)
	makePart(m, "RoofRidge", Vector3.new(0.6, 0.6, 6.4), origin * CFrame.new(0, 9.2, 0), AdobeDark, Enum.Material.Wood)

	m.PrimaryPart = basin
	return m
end

-- ==========================================
-- 2. SAND DUNES
-- ==========================================

-- 2A: Large Wind-Swept Sand Dune
local function buildWindSweptDune(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "01_WindSweptDune_Large"
	m.Parent = catDunes

	-- Stepped organic terrain layering (3D stud style)
	local b1 = makePart(
		m,
		"DuneTier1",
		Vector3.new(32, 1.5, 24),
		origin * CFrame.new(0, 0.75, 0),
		SandDark,
		Enum.Material.Sand
	)
	b1.TopSurface = Enum.SurfaceType.Studs

	local b2 = makePart(
		m,
		"DuneTier2",
		Vector3.new(26, 1.5, 18),
		origin * CFrame.new(-1.5, 2.25, -1),
		SandColor,
		Enum.Material.Sand
	)
	b2.TopSurface = Enum.SurfaceType.Studs

	local b3 = makePart(
		m,
		"DuneTier3",
		Vector3.new(18, 1.4, 12),
		origin * CFrame.new(-3, 3.7, -2),
		SandLight,
		Enum.Material.Sand
	)
	b3.TopSurface = Enum.SurfaceType.Studs

	local b4 = makePart(
		m,
		"DuneRidgeTop",
		Vector3.new(10, 1.2, 6),
		origin * CFrame.new(-4.5, 5, -3),
		SandLight,
		Enum.Material.Sand
	)
	b4.TopSurface = Enum.SurfaceType.Studs

	-- Slip face gentle slope wedges
	makeWedge(
		m,
		"SlipSlope1",
		Vector3.new(22, 1.5, 5),
		origin * CFrame.new(-1.5, 2.25, 10.5),
		SandColor,
		Enum.Material.Sand
	)
	makeWedge(m, "SlipSlope2", Vector3.new(14, 1.4, 4), origin * CFrame.new(-3, 3.7, 5), SandLight, Enum.Material.Sand)

	-- Embedded desert stone accents
	makePart(
		m,
		"Pebble1",
		Vector3.new(2, 1.2, 2.4),
		origin * CFrame.new(8, 0.8, -4) * CFrame.Angles(0, math.rad(25), 0),
		DesertStone,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"Pebble2",
		Vector3.new(1.6, 0.9, 1.6),
		origin * CFrame.new(10, 0.7, -2),
		DesertStoneDark,
		Enum.Material.Sandstone
	)

	m.PrimaryPart = b1
	return m
end

-- 2B: Small Sand Drift / Dune Mound
local function buildSandDrift(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "02_SandDrift_Small"
	m.Parent = catDunes

	local d1 =
		makePart(m, "DriftBase", Vector3.new(14, 1, 10), origin * CFrame.new(0, 0.5, 0), SandDark, Enum.Material.Sand)
	d1.TopSurface = Enum.SurfaceType.Studs

	local d2 = makePart(
		m,
		"DriftMid",
		Vector3.new(10, 1, 6),
		origin * CFrame.new(-1, 1.5, -0.5),
		SandColor,
		Enum.Material.Sand
	)
	d2.TopSurface = Enum.SurfaceType.Studs

	local d3 = makePart(
		m,
		"DriftPeak",
		Vector3.new(5, 0.8, 3),
		origin * CFrame.new(-2, 2.4, -1),
		SandLight,
		Enum.Material.Sand
	)
	d3.TopSurface = Enum.SurfaceType.Studs

	makeWedge(m, "DriftSlope", Vector3.new(8, 1, 3), origin * CFrame.new(-1, 1.5, 3.5), SandColor, Enum.Material.Sand)

	m.PrimaryPart = d1
	return m
end

-- ==========================================
-- 3. DEAD TREES (POHON KERING TANPA DAUN)
-- ==========================================

-- 3A: Standing Dead Tree
local function buildStandingDeadTree(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "01_StandingDeadTree"
	m.Parent = catTrees

	-- Spread Gnarled Roots
	local rootBase =
		makePart(m, "RootHub", Vector3.new(3, 1, 3), origin * CFrame.new(0, 0.5, 0), WoodDark, Enum.Material.Wood)
	makePart(
		m,
		"Root1",
		Vector3.new(1.4, 0.6, 3),
		origin * CFrame.new(1.8, 0.3, 0) * CFrame.Angles(0, math.rad(25), math.rad(-10)),
		WoodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"Root2",
		Vector3.new(1.4, 0.6, 3),
		origin * CFrame.new(-1.8, 0.3, 0.5) * CFrame.Angles(0, math.rad(-30), math.rad(10)),
		WoodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"Root3",
		Vector3.new(3, 0.6, 1.4),
		origin * CFrame.new(0.5, 0.3, -1.8) * CFrame.Angles(math.rad(10), math.rad(15), 0),
		WoodDark,
		Enum.Material.Wood,
		false
	)

	-- Lower Trunk
	makePart(m, "TrunkLow", Vector3.new(2.2, 5, 2.2), origin * CFrame.new(0, 3, 0), WoodDry, Enum.Material.Wood)
	-- Mid Trunk (Slight tilt)
	makePart(
		m,
		"TrunkMid",
		Vector3.new(1.8, 4.5, 1.8),
		origin * CFrame.new(0.3, 7.2, -0.2) * CFrame.Angles(math.rad(-4), 0, math.rad(5)),
		WoodDry,
		Enum.Material.Wood
	)
	-- Upper Spire
	makePart(
		m,
		"TrunkTop",
		Vector3.new(1.4, 4, 1.4),
		origin * CFrame.new(0.5, 11, -0.4) * CFrame.Angles(math.rad(3), 0, math.rad(-4)),
		WoodDry,
		Enum.Material.Wood
	)
	-- Crown dead point
	makePart(
		m,
		"CrownTip",
		Vector3.new(0.8, 2, 0.8),
		origin * CFrame.new(0.6, 13.5, -0.5),
		WoodDark,
		Enum.Material.Wood,
		false
	)

	-- Branch Group 1 (Left Lower Branch)
	makePart(
		m,
		"Branch1_Base",
		Vector3.new(3.5, 1.2, 1.2),
		origin * CFrame.new(-2.2, 6.5, 0.2) * CFrame.Angles(0, 0, math.rad(25)),
		WoodDry,
		Enum.Material.Wood
	)
	makePart(
		m,
		"Branch1_ForkA",
		Vector3.new(1, 2.8, 1),
		origin * CFrame.new(-4, 8, 0.4) * CFrame.Angles(0, 0, math.rad(-15)),
		WoodDry,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"Branch1_ForkB",
		Vector3.new(2.5, 0.8, 0.8),
		origin * CFrame.new(-4.5, 6.8, -0.6) * CFrame.Angles(0, math.rad(-30), math.rad(10)),
		WoodDark,
		Enum.Material.Wood,
		false
	)

	-- Branch Group 2 (Right Mid Branch)
	makePart(
		m,
		"Branch2_Base",
		Vector3.new(3.5, 1.2, 1.2),
		origin * CFrame.new(2.5, 9.2, -0.3) * CFrame.Angles(0, 0, math.rad(-25)),
		WoodDry,
		Enum.Material.Wood
	)
	makePart(
		m,
		"Branch2_ForkA",
		Vector3.new(1, 3.2, 1),
		origin * CFrame.new(4.4, 10.8, -0.5) * CFrame.Angles(0, 0, math.rad(20)),
		WoodDry,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"Branch2_ForkB",
		Vector3.new(2, 0.8, 0.8),
		origin * CFrame.new(4, 9, 0.8) * CFrame.Angles(0, math.rad(40), math.rad(-10)),
		WoodDark,
		Enum.Material.Wood,
		false
	)

	-- Branch Group 3 (Back Upper Twig)
	makePart(
		m,
		"Branch3_High",
		Vector3.new(1, 2.5, 2.2),
		origin * CFrame.new(0.4, 12.2, 1.4) * CFrame.Angles(math.rad(30), 0, 0),
		WoodDark,
		Enum.Material.Wood,
		false
	)

	m.PrimaryPart = rootBase
	return m
end

-- 3B: Fallen Desert Timber / Rotten Log
local function buildFallenDesertTimber(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "02_FallenDesertTimber"
	m.Parent = catTrees

	-- Main Log resting in sand
	local log = makePart(
		m,
		"LogMain",
		Vector3.new(2.4, 2.4, 11),
		origin * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(20), math.rad(3)),
		WoodDry,
		Enum.Material.Wood
	)

	-- Splintered / Hollowed End
	makePart(
		m,
		"HollowEnd",
		Vector3.new(1.6, 1.6, 0.8),
		log.CFrame * CFrame.new(0, 0, -5.4),
		Color3.fromRGB(35, 25, 20),
		Enum.Material.SmoothPlastic,
		false
	)

	-- Snapped branch stubs
	makePart(
		m,
		"BranchStub1",
		Vector3.new(1, 2, 1),
		log.CFrame * CFrame.new(0.8, 1.4, -1) * CFrame.Angles(0, 0, math.rad(-35)),
		WoodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"BranchStub2",
		Vector3.new(0.8, 1.6, 0.8),
		log.CFrame * CFrame.new(-0.8, 1.2, 2.5) * CFrame.Angles(0, 0, math.rad(40)),
		WoodDark,
		Enum.Material.Wood,
		false
	)

	-- Sand drift burying part of the log
	makePart(
		m,
		"LogSandCover",
		Vector3.new(3.5, 0.8, 4),
		log.CFrame * CFrame.new(0, -0.6, 1.5),
		SandColor,
		Enum.Material.Sand,
		false
	)

	m.PrimaryPart = log
	return m
end

-- ==========================================
-- 4. CACTI
-- ==========================================

-- 4A: Classic Tall Saguaro Cactus
local function buildSaguaroCactus(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "01_SaguaroCactus_Tall"
	m.Parent = catCacti

	-- Pebble Mound Base
	makePart(
		m,
		"CactusPebbles",
		Vector3.new(3.5, 0.6, 3.5),
		origin * CFrame.new(0, 0.3, 0),
		SandDark,
		Enum.Material.Sandstone,
		false
	)

	-- Main Column
	local trunk = makePart(
		m,
		"MainStem",
		Vector3.new(2.4, 13, 2.4),
		origin * CFrame.new(0, 6.8, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	trunk.TopSurface = Enum.SurfaceType.Studs

	-- Fluting Ribs (Darker Green 3D Reliefs)
	makePart(
		m,
		"RibX",
		Vector3.new(2.6, 12.6, 0.5),
		origin * CFrame.new(0, 6.8, 0),
		CactusDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		m,
		"RibZ",
		Vector3.new(0.5, 12.6, 2.6),
		origin * CFrame.new(0, 6.8, 0),
		CactusDark,
		Enum.Material.Plastic,
		false
	)

	-- Top Crown Flower
	makePart(
		m,
		"TopFlowerBase",
		Vector3.new(1, 0.4, 1),
		origin * CFrame.new(0, 13.5, 0),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)
	makePart(
		m,
		"TopFlowerStamen",
		Vector3.new(0.5, 0.5, 0.5),
		origin * CFrame.new(0, 13.8, 0),
		FlowerYellow,
		Enum.Material.Neon,
		false
	)

	-- Right Arm (Higher Arm)
	makePart(
		m,
		"ArmRight_H",
		Vector3.new(2.8, 1.8, 1.8),
		origin * CFrame.new(2.2, 8.5, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"ArmRight_V",
		Vector3.new(1.8, 5, 1.8),
		origin * CFrame.new(3.6, 11, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"ArmRight_Rib",
		Vector3.new(0.4, 4.8, 2),
		origin * CFrame.new(3.6, 11, 0),
		CactusDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		m,
		"ArmRight_Flower",
		Vector3.new(0.8, 0.3, 0.8),
		origin * CFrame.new(3.6, 13.6, 0),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	-- Left Arm (Lower Arm)
	makePart(
		m,
		"ArmLeft_H",
		Vector3.new(2.8, 1.8, 1.8),
		origin * CFrame.new(-2.2, 6, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"ArmLeft_V",
		Vector3.new(1.8, 4.5, 1.8),
		origin * CFrame.new(-3.6, 8.2, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"ArmLeft_Rib",
		Vector3.new(0.4, 4.3, 2),
		origin * CFrame.new(-3.6, 8.2, 0),
		CactusDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		m,
		"ArmLeft_Flower",
		Vector3.new(0.8, 0.3, 0.8),
		origin * CFrame.new(-3.6, 10.6, 0),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	m.PrimaryPart = trunk
	return m
end

-- 4B: Barrel Cactus Cluster
local function buildBarrelCactusCluster(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "02_BarrelCactusCluster"
	m.Parent = catCacti

	-- Main Big Barrel Cactus
	local b1 = makePart(
		m,
		"Barrel1_Base",
		Vector3.new(3.6, 1.4, 3.6),
		origin * CFrame.new(0, 0.7, 0),
		CactusDark,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"Barrel1_Mid",
		Vector3.new(4.2, 2.2, 4.2),
		origin * CFrame.new(0, 2.2, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"Barrel1_Top",
		Vector3.new(3.4, 1.2, 3.4),
		origin * CFrame.new(0, 3.8, 0),
		CactusGreen,
		Enum.Material.Plastic
	)
	-- Flowers on top
	makePart(
		m,
		"Flower1",
		Vector3.new(1.2, 0.4, 1.2),
		origin * CFrame.new(0, 4.5, 0),
		FlowerYellow,
		Enum.Material.Neon,
		false
	)
	makePart(
		m,
		"Flower2",
		Vector3.new(0.8, 0.3, 0.8),
		origin * CFrame.new(0.7, 4.5, 0.6),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	-- Secondary Small Barrel Cactus
	makePart(
		m,
		"Barrel2_Base",
		Vector3.new(2.4, 0.8, 2.4),
		origin * CFrame.new(3, 0.4, -1),
		CactusDark,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"Barrel2_Mid",
		Vector3.new(2.8, 1.6, 2.8),
		origin * CFrame.new(3, 1.4, -1),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"Barrel2_Top",
		Vector3.new(2.2, 0.8, 2.2),
		origin * CFrame.new(3, 2.5, -1),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"FlowerSmall",
		Vector3.new(0.8, 0.3, 0.8),
		origin * CFrame.new(3, 3, -1),
		FlowerYellow,
		Enum.Material.Neon,
		false
	)

	m.PrimaryPart = b1
	return m
end

-- 4C: Prickly Pear Cactus
local function buildPricklyPearCactus(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "03_PricklyPearCactus"
	m.Parent = catCacti

	-- Root Mound
	local pBase = makePart(
		m,
		"PadBase",
		Vector3.new(2.4, 0.6, 2.4),
		origin * CFrame.new(0, 0.3, 0),
		SandDark,
		Enum.Material.Sandstone,
		false
	)

	-- Pad 1 (Base upright pad)
	makePart(
		m,
		"Pad1",
		Vector3.new(3, 2.8, 0.6),
		origin * CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(10), 0),
		CactusGreen,
		Enum.Material.Plastic
	)

	-- Pad 2 (Left tilted pad)
	makePart(
		m,
		"Pad2",
		Vector3.new(2.6, 2.4, 0.5),
		origin * CFrame.new(-1.8, 3.8, 0) * CFrame.Angles(0, math.rad(-20), math.rad(30)),
		CactusGreen,
		Enum.Material.Plastic
	)
	-- Fruit on Pad 2 rim
	makePart(
		m,
		"Fruit1",
		Vector3.new(0.6, 0.7, 0.6),
		origin * CFrame.new(-3, 4.8, 0),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	-- Pad 3 (Right tilted pad)
	makePart(
		m,
		"Pad3",
		Vector3.new(2.6, 2.4, 0.5),
		origin * CFrame.new(1.8, 4, 0.2) * CFrame.Angles(0, math.rad(25), math.rad(-25)),
		CactusGreen,
		Enum.Material.Plastic
	)
	-- Fruit on Pad 3 rim
	makePart(
		m,
		"Fruit2",
		Vector3.new(0.6, 0.7, 0.6),
		origin * CFrame.new(3.1, 5, 0.3),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	-- Pad 4 (Top center pad)
	makePart(
		m,
		"Pad4",
		Vector3.new(2.2, 2.2, 0.5),
		origin * CFrame.new(0.2, 5.2, -0.1) * CFrame.Angles(0, math.rad(-5), math.rad(8)),
		CactusGreen,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"FruitTop",
		Vector3.new(0.6, 0.7, 0.6),
		origin * CFrame.new(0.3, 6.4, -0.1),
		FlowerRed,
		Enum.Material.Plastic,
		false
	)

	m.PrimaryPart = pBase
	return m
end

-- ==========================================
-- 5. CAMEL (UNTA GURUN 3D STUD STYLE)
-- ==========================================
local function buildCamel(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "01_DesertCamel"
	m.Parent = catCamel

	-- Torso (Main Body)
	local torso =
		makePart(m, "Torso", Vector3.new(4, 3.6, 7.5), origin * CFrame.new(0, 5.2, 0), CamelTan, Enum.Material.Plastic)
	torso.TopSurface = Enum.SurfaceType.Studs

	-- Belly lower shade
	makePart(
		m,
		"Belly",
		Vector3.new(3.6, 0.8, 6.8),
		origin * CFrame.new(0, 3.2, 0),
		CamelLight,
		Enum.Material.Plastic,
		false
	)

	-- Dromedary Hump (Punuk Unta)
	makePart(
		m,
		"HumpBase",
		Vector3.new(3.2, 2.2, 3.4),
		origin * CFrame.new(0, 7.8, -0.2),
		CamelTan,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"HumpPeak",
		Vector3.new(2.4, 1.2, 2.4),
		origin * CFrame.new(0, 9.2, -0.2),
		CamelDark,
		Enum.Material.Plastic
	)

	-- 4 Chunky Blocky Legs
	local legPositions = {
		{ name = "LegFrontLeft", x = -1.5, z = -2.6 },
		{ name = "LegFrontRight", x = 1.5, z = -2.6 },
		{ name = "LegBackLeft", x = -1.5, z = 2.6 },
		{ name = "LegBackRight", x = 1.5, z = 2.6 },
	}
	for _, l in ipairs(legPositions) do
		-- Thigh
		makePart(
			m,
			l.name .. "_Thigh",
			Vector3.new(1.4, 2.4, 1.4),
			origin * CFrame.new(l.x, 3.8, l.z),
			CamelTan,
			Enum.Material.Plastic
		)
		-- Shin
		makePart(
			m,
			l.name .. "_Shin",
			Vector3.new(1.1, 2.4, 1.1),
			origin * CFrame.new(l.x, 1.6, l.z),
			CamelTan,
			Enum.Material.Plastic
		)
		-- Hoof
		makePart(
			m,
			l.name .. "_Hoof",
			Vector3.new(1.4, 0.7, 1.6),
			origin * CFrame.new(l.x, 0.35, l.z - 0.1),
			CamelDark,
			Enum.Material.Plastic
		)
	end

	-- Neck (Curved Forward and Upward)
	makePart(
		m,
		"NeckBase",
		Vector3.new(2.2, 2.4, 2.4),
		origin * CFrame.new(0, 5.8, -3.8),
		CamelTan,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"NeckMid",
		Vector3.new(2, 3.2, 2),
		origin * CFrame.new(0, 7.6, -4.6) * CFrame.Angles(math.rad(25), 0, 0),
		CamelTan,
		Enum.Material.Plastic
	)
	makePart(m, "NeckTop", Vector3.new(1.8, 2, 1.8), origin * CFrame.new(0, 9.4, -5.3), CamelTan, Enum.Material.Plastic)

	-- Head & Snout
	makePart(m, "Head", Vector3.new(2.2, 1.8, 2.4), origin * CFrame.new(0, 10.4, -6.1), CamelTan, Enum.Material.Plastic)
	makePart(m, "Snout", Vector3.new(1.8, 1.3, 2), origin * CFrame.new(0, 9.8, -7.5), CamelLight, Enum.Material.Plastic)
	-- Nostrils
	makePart(
		m,
		"NostrilLeft",
		Vector3.new(0.3, 0.3, 0.2),
		origin * CFrame.new(-0.4, 9.9, -8.5),
		Color3.fromRGB(60, 45, 30),
		Enum.Material.SmoothPlastic,
		false
	)
	makePart(
		m,
		"NostrilRight",
		Vector3.new(0.3, 0.3, 0.2),
		origin * CFrame.new(0.4, 9.9, -8.5),
		Color3.fromRGB(60, 45, 30),
		Enum.Material.SmoothPlastic,
		false
	)

	-- Eyes
	makePart(
		m,
		"EyeLeft",
		Vector3.new(0.2, 0.4, 0.4),
		origin * CFrame.new(-1.15, 10.6, -6.2),
		Color3.fromRGB(20, 15, 10),
		Enum.Material.SmoothPlastic,
		false
	)
	makePart(
		m,
		"EyeRight",
		Vector3.new(0.2, 0.4, 0.4),
		origin * CFrame.new(1.15, 10.6, -6.2),
		Color3.fromRGB(20, 15, 10),
		Enum.Material.SmoothPlastic,
		false
	)

	-- Ears
	makePart(
		m,
		"EarLeft",
		Vector3.new(0.4, 0.8, 0.6),
		origin * CFrame.new(-1, 11.4, -5.4) * CFrame.Angles(math.rad(-25), 0, math.rad(-15)),
		CamelDark,
		Enum.Material.Plastic,
		false
	)
	makePart(
		m,
		"EarRight",
		Vector3.new(0.4, 0.8, 0.6),
		origin * CFrame.new(1, 11.4, -5.4) * CFrame.Angles(math.rad(-25), 0, math.rad(15)),
		CamelDark,
		Enum.Material.Plastic,
		false
	)

	-- Tail
	makePart(
		m,
		"Tail",
		Vector3.new(0.4, 2.6, 0.4),
		origin * CFrame.new(0, 4.4, 3.8) * CFrame.Angles(math.rad(15), 0, 0),
		CamelTan,
		Enum.Material.Plastic,
		false
	)
	makePart(
		m,
		"TailTuft",
		Vector3.new(0.6, 0.8, 0.6),
		origin * CFrame.new(0, 3.2, 4.2),
		CamelDark,
		Enum.Material.Plastic,
		false
	)

	-- Nomad Saddle Carpet (Striped Blanket across the back)
	makePart(
		m,
		"SaddleCarpet1",
		Vector3.new(4.3, 2.8, 1.6),
		origin * CFrame.new(0, 6.4, 1.4),
		FabricRed,
		Enum.Material.Fabric,
		false
	)
	makePart(
		m,
		"SaddleCarpet2",
		Vector3.new(4.3, 2.8, 1.4),
		origin * CFrame.new(0, 6.4, -1.8),
		FabricTeal,
		Enum.Material.Fabric,
		false
	)
	makePart(
		m,
		"SaddleTrimL",
		Vector3.new(0.3, 0.6, 4.6),
		origin * CFrame.new(-2.2, 4.8, -0.2),
		FabricCream,
		Enum.Material.Fabric,
		false
	)
	makePart(
		m,
		"SaddleTrimR",
		Vector3.new(0.3, 0.6, 4.6),
		origin * CFrame.new(2.2, 4.8, -0.2),
		FabricCream,
		Enum.Material.Fabric,
		false
	)

	-- Wooden Pack Frame
	makePart(
		m,
		"PackFrameCross",
		Vector3.new(4.5, 0.6, 0.6),
		origin * CFrame.new(0, 8.8, 1.5),
		WoodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"PackFramePouch",
		Vector3.new(1.4, 1.4, 1.8),
		origin * CFrame.new(2.3, 6.2, 0),
		WoodDry,
		Enum.Material.Wood,
		false
	)

	m.PrimaryPart = torso
	return m
end

-- ==========================================
-- 6. DECORATIONS
-- ==========================================

-- 6A: Desert Clay Urns / Terracotta Pots Cluster
local function buildDesertClayUrns(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "01_DesertClayUrns"
	m.Parent = catDecor

	-- Big Urn
	local urn1 = makePart(
		m,
		"BigUrn_Foot",
		Vector3.new(1.6, 0.4, 1.6),
		origin * CFrame.new(0, 0.2, 0),
		ClayDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"BigUrn_Belly",
		Vector3.new(2.4, 2.2, 2.4),
		origin * CFrame.new(0, 1.4, 0),
		ClayPot,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"BigUrn_Neck",
		Vector3.new(1.4, 0.8, 1.4),
		origin * CFrame.new(0, 2.7, 0),
		ClayPot,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"BigUrn_Rim",
		Vector3.new(1.8, 0.4, 1.8),
		origin * CFrame.new(0, 3.2, 0),
		ClayDark,
		Enum.Material.Sandstone
	)
	-- Handles
	makePart(
		m,
		"BigUrn_HandleL",
		Vector3.new(0.3, 1.2, 0.4),
		origin * CFrame.new(-1.3, 2, 0),
		ClayDark,
		Enum.Material.Sandstone,
		false
	)
	makePart(
		m,
		"BigUrn_HandleR",
		Vector3.new(0.3, 1.2, 0.4),
		origin * CFrame.new(1.3, 2, 0),
		ClayDark,
		Enum.Material.Sandstone,
		false
	)

	-- Medium Slender Amphora
	makePart(
		m,
		"MedUrn_Foot",
		Vector3.new(1.2, 0.3, 1.2),
		origin * CFrame.new(2, 0.15, -0.6),
		ClayDark,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"MedUrn_Belly",
		Vector3.new(1.8, 1.8, 1.8),
		origin * CFrame.new(2, 1.1, -0.6),
		ClayPot,
		Enum.Material.Sandstone
	)
	makePart(
		m,
		"MedUrn_Rim",
		Vector3.new(1.3, 0.4, 1.3),
		origin * CFrame.new(2, 2.1, -0.6),
		ClayDark,
		Enum.Material.Sandstone
	)

	-- Small Tipped Jar in Sand
	makePart(
		m,
		"SmallJar",
		Vector3.new(1.4, 1.4, 1.4),
		origin * CFrame.new(-1.5, 0.5, 0.8) * CFrame.Angles(0, math.rad(30), math.rad(25)),
		ClayPot,
		Enum.Material.Sandstone
	)

	m.PrimaryPart = urn1
	return m
end

-- 6B: Weathered Animal Skull Prop
local function buildWeatheredAnimalSkull(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "02_WeatheredAnimalSkull"
	m.Parent = catDecor

	-- Cranium
	local cranium = makePart(
		m,
		"Cranium",
		Vector3.new(2.4, 1.8, 2.4),
		origin * CFrame.new(0, 1.3, 0),
		BoneIvory,
		Enum.Material.Plastic
	)
	-- Snout pointing toward viewer (+Z)
	makePart(m, "Snout", Vector3.new(1.6, 1.2, 2.4), origin * CFrame.new(0, 0.8, 1.8), BoneIvory, Enum.Material.Plastic)
	makePart(
		m,
		"NoseTip",
		Vector3.new(1.2, 0.8, 0.6),
		origin * CFrame.new(0, 0.6, 3.1),
		BoneIvory,
		Enum.Material.Plastic
	)

	-- Eye Sockets (Dark recessed squares on front-top corners of cranium)
	makePart(
		m,
		"EyeSocketL",
		Vector3.new(0.5, 0.7, 0.6),
		origin * CFrame.new(-1, 1.4, 0.8),
		Color3.fromRGB(35, 30, 25),
		Enum.Material.SmoothPlastic,
		false
	)
	makePart(
		m,
		"EyeSocketR",
		Vector3.new(0.5, 0.7, 0.6),
		origin * CFrame.new(1, 1.4, 0.8),
		Color3.fromRGB(35, 30, 25),
		Enum.Material.SmoothPlastic,
		false
	)

	-- Left Horn sweeping out, up and curling forward
	makePart(
		m,
		"HornL_Base",
		Vector3.new(1.6, 0.9, 0.9),
		origin * CFrame.new(-1.8, 1.8, -0.4) * CFrame.Angles(0, math.rad(-20), math.rad(25)),
		BoneHorn,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"HornL_Tip",
		Vector3.new(1.4, 0.6, 0.6),
		origin * CFrame.new(-3, 2.6, 0.4) * CFrame.Angles(0, math.rad(30), math.rad(45)),
		BoneHorn,
		Enum.Material.Plastic,
		false
	)

	-- Right Horn sweeping out, up and curling forward
	makePart(
		m,
		"HornR_Base",
		Vector3.new(1.6, 0.9, 0.9),
		origin * CFrame.new(1.8, 1.8, -0.4) * CFrame.Angles(0, math.rad(20), math.rad(-25)),
		BoneHorn,
		Enum.Material.Plastic
	)
	makePart(
		m,
		"HornR_Tip",
		Vector3.new(1.4, 0.6, 0.6),
		origin * CFrame.new(3, 2.6, 0.4) * CFrame.Angles(0, math.rad(-30), math.rad(-45)),
		BoneHorn,
		Enum.Material.Plastic,
		false
	)

	m.PrimaryPart = cranium
	return m
end

-- 6C: Expedition Crates & Water Barrel
local function buildExpeditionCratesAndBarrel(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "03_ExpeditionCratesAndBarrel"
	m.Parent = catDecor

	-- Main Cargo Crate
	local crate1 = makePart(
		m,
		"CrateBody1",
		Vector3.new(3.6, 3.6, 3.6),
		origin * CFrame.new(0, 1.8, 0),
		WoodLight,
		Enum.Material.WoodPlanks
	)
	crate1.TopSurface = Enum.SurfaceType.Studs
	-- Metal Corner Braces
	makePart(
		m,
		"CrateStrap1",
		Vector3.new(3.7, 0.5, 3.7),
		origin * CFrame.new(0, 3.2, 0),
		MetalIron,
		Enum.Material.Metal,
		false
	)
	makePart(
		m,
		"CrateStrap2",
		Vector3.new(3.7, 0.5, 3.7),
		origin * CFrame.new(0, 0.8, 0),
		MetalIron,
		Enum.Material.Metal,
		false
	)

	-- Secondary Stacked Crate
	local crate2 = makePart(
		m,
		"CrateBody2",
		Vector3.new(2.8, 2.8, 2.8),
		origin * CFrame.new(0.3, 4.8, 0.2) * CFrame.Angles(0, math.rad(15), 0),
		WoodDry,
		Enum.Material.WoodPlanks
	)
	crate2.TopSurface = Enum.SurfaceType.Studs

	-- Water Barrel
	local barrel = makePart(
		m,
		"BarrelBody",
		Vector3.new(2.6, 3.2, 2.6),
		origin * CFrame.new(3.6, 1.6, 0),
		WoodDark,
		Enum.Material.Wood,
		true,
		Enum.PartType.Cylinder
	)
	barrel.CFrame = origin * CFrame.new(3.6, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	makePart(
		m,
		"BarrelSpigot",
		Vector3.new(0.4, 0.4, 0.6),
		origin * CFrame.new(3.6, 1.2, 1.5),
		MetalIron,
		Enum.Material.Metal,
		false
	)

	m.PrimaryPart = crate1
	return m
end

-- 6D: Nomad Campfire
local function buildNomadCampfire(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "04_NomadCampfire"
	m.Parent = catDecor

	-- Ashen Pit Base
	local pit = makePart(
		m,
		"AshPit",
		Vector3.new(4, 0.4, 4),
		origin * CFrame.new(0, 0.2, 0),
		Color3.fromRGB(45, 40, 38),
		Enum.Material.Sand,
		false
	)

	-- Ring of 6 Desert Stones
	local numStones = 6
	for i = 1, numStones do
		local angle = (i / numStones) * math.pi * 2
		local x = math.cos(angle) * 2.2
		local z = math.sin(angle) * 2.2
		makePart(
			m,
			"CampStone_" .. i,
			Vector3.new(1.3, 0.9, 1.3),
			origin * CFrame.new(x, 0.45, z) * CFrame.Angles(0, angle, 0),
			DesertStone,
			Enum.Material.Sandstone
		)
	end

	-- Charred Firewood Sticks
	makePart(
		m,
		"CharredWood1",
		Vector3.new(0.6, 0.6, 3),
		origin * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(10), math.rad(30), 0),
		Color3.fromRGB(30, 25, 22),
		Enum.Material.Wood
	)
	makePart(
		m,
		"CharredWood2",
		Vector3.new(0.6, 0.6, 3),
		origin * CFrame.new(0, 0.7, 0) * CFrame.Angles(math.rad(10), math.rad(-40), 0),
		Color3.fromRGB(30, 25, 22),
		Enum.Material.Wood
	)

	-- Glowing Embers (Neon)
	local ember = makePart(
		m,
		"GlowingEmbers",
		Vector3.new(1.6, 0.5, 1.6),
		origin * CFrame.new(0, 0.4, 0),
		Color3.fromRGB(255, 90, 25),
		Enum.Material.Neon,
		false
	)
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 140, 45)
	fireLight.Brightness = 2
	fireLight.Range = 14
	fireLight.Parent = ember

	m.PrimaryPart = pit
	return m
end

-- 6E: Wind-Eroded Sandstone Rocks
local function buildWindErodedRocks(origin: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "05_WindErodedSandstoneRocks"
	m.Parent = catDecor

	-- Main Boulder
	local r1 = makePart(
		m,
		"RockBase",
		Vector3.new(6.5, 3.2, 5.5),
		origin * CFrame.new(0, 1.6, 0),
		DesertStone,
		Enum.Material.Sandstone
	)
	r1.TopSurface = Enum.SurfaceType.Studs

	-- Upper Balanced Slab
	makePart(
		m,
		"RockMid",
		Vector3.new(5, 2.2, 4.2),
		origin * CFrame.new(0.5, 4, -0.2) * CFrame.Angles(0, math.rad(15), math.rad(4)),
		DesertStone,
		Enum.Material.Sandstone
	)

	-- Top Weathered Cap
	makePart(
		m,
		"RockCap",
		Vector3.new(3.6, 1.4, 3),
		origin * CFrame.new(-0.2, 5.6, -0.4) * CFrame.Angles(0, math.rad(-10), math.rad(-3)),
		DesertStoneDark,
		Enum.Material.Sandstone
	)

	-- Small Side Pebble
	makePart(
		m,
		"SidePebble",
		Vector3.new(2.4, 1.4, 2),
		origin * CFrame.new(-3.4, 0.7, 1.5) * CFrame.Angles(0, math.rad(35), 0),
		DesertStoneDark,
		Enum.Material.Sandstone
	)

	m.PrimaryPart = r1
	return m
end

-- ==========================================
-- INSTANTIATE ALL KIT MODELS
-- ==========================================
-- ROW 1 (Z = -50): Mainland Buildings
buildDesertWatchtower(CFrame.new(-195, 1, -50))
buildDesertAdobeHouse(CFrame.new(-160, 1, -50))
buildAncientSandstoneArch(CFrame.new(-125, 1, -50))

-- ROW 2 (Z = -15): Water Well & Sand Dunes
buildDesertOasisWell(CFrame.new(-200, 1, -15))
buildWindSweptDune(CFrame.new(-160, 1, -15))
buildSandDrift(CFrame.new(-120, 1, -15))

-- ROW 3 (Z = 20): Flora & Dead Trees
buildSaguaroCactus(CFrame.new(-205, 1, 20))
buildBarrelCactusCluster(CFrame.new(-190, 1, 20))
buildPricklyPearCactus(CFrame.new(-175, 1, 20))
buildStandingDeadTree(CFrame.new(-150, 1, 20))
buildFallenDesertTimber(CFrame.new(-125, 1, 20))

-- ROW 4 (Z = 55): Camel & Desert Decorations
buildCamel(CFrame.new(-200, 1, 55))
buildDesertClayUrns(CFrame.new(-175, 1, 55))
buildWeatheredAnimalSkull(CFrame.new(-160, 1, 55))
buildExpeditionCratesAndBarrel(CFrame.new(-145, 1, 55))
buildNomadCampfire(CFrame.new(-130, 1, 55))
buildWindErodedRocks(CFrame.new(-115, 1, 55))

print("DesertBiomeKit successfully generated!")
