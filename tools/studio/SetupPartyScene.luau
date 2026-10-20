-- One-time EDIT MODE setup. Not mapped by Rojo; the resulting Instances are
-- the editable source of truth in Studio. Run after inspecting existing assets.
local StarterGui = game:GetService("StarterGui")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local outline = Color3.fromRGB(23, 33, 38)
local white = Color3.fromRGB(255, 248, 231)
local muted = Color3.fromRGB(174, 185, 196)
local friendsImage = "rbxassetid://17368071983"
local studsImage = StarterGui:GetAttribute("PartyStudsAsset") or "rbxassetid://104291473736518"

local function make(className, name, parent, properties)
	local obj = Instance.new(className)
	obj.Name = name
	for key, value in pairs(properties or {}) do
		obj[key] = value
	end
	obj.Parent = parent
	return obj
end
local function corner(parent, radius)
	make("UICorner", "Corner", parent, { CornerRadius = UDim.new(0, radius) })
end
local function stroke(parent, thickness)
	make(
		"UIStroke",
		"Outline",
		parent,
		{ Color = outline, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
	)
end
local function label(parent, name, text, position, size, textSize, color, strong)
	local obj = make("TextLabel", name, parent, {
		BackgroundTransparency = 1,
		Text = text,
		Position = position,
		Size = size,
		Font = if strong then Enum.Font.FredokaOne else Enum.Font.GothamMedium,
		TextSize = textSize,
		TextColor3 = color or white,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	})
	if strong then
		make("UIStroke", "TextOutline", obj, { Color = outline, Thickness = 1.8 })
	end
	return obj
end
local function frame(parent, name, position, size, color, radius)
	local obj = make("Frame", name, parent, {
		Position = position,
		Size = size,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	if radius then
		corner(obj, radius)
	end
	return obj
end
local function studs(parent, transparency, tileSize)
	make("ImageLabel", "Studs", parent, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = studsImage,
		ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tileSize, tileSize),
		ZIndex = 3,
	})
end
local function button(parent, name, text, pos, size, color, lipColor, radius)
	local obj = make("TextButton", name, parent, {
		Position = pos,
		Size = size,
		Text = "",
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Selectable = true,
		ZIndex = 4,
	})
	frame(obj, "Lip", UDim2.fromOffset(0, 8), UDim2.new(1, 0, 1, -8), lipColor, radius)
	local face = frame(obj, "Face", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 1, -8), color, radius)
	stroke(face, 4)
	face.ZIndex = 4
	local highlight = frame(face, "Highlight", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 3), Color3.new(1, 1, 1), 2)
	highlight.BackgroundTransparency = 0.7
	highlight.ZIndex = 5
	if text ~= "" then
		local textLabel = label(face, "Label", text, UDim2.fromOffset(8, 0), UDim2.new(1, -16, 1, 0), 28, white, true)
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
	end
	return obj
end

assert(not StarterGui:FindFirstChild("PartyGui"), "PartyGui already exists; edit it in place instead of replacing it.")
local gui = make("ScreenGui", "PartyGui", StarterGui, {
	ResetOnSpawn = false,
	DisplayOrder = 30,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
})
gui:SetAttribute("DesignSource", "https://www.figma.com/design/aP8YDulc0Do9EmyO66N8Yl?node-id=5-171")
local overlay = frame(gui, "Overlay", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.fromRGB(3, 5, 8))
overlay.BackgroundTransparency = 0.42
overlay.Visible = false
overlay.ZIndex = 1
local dialog =
	frame(gui, "Dialog", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(620, 560), Color3.fromRGB(32, 43, 57), 18)
dialog.AnchorPoint = Vector2.new(0.5, 0.5)
dialog.Visible = false
dialog.SelectionGroup = true
dialog.ZIndex = 10
stroke(dialog, 4)
make("UIScale", "UIScale", dialog, { Scale = 1 })
local lip = frame(dialog, "LowerLip", UDim2.fromOffset(-6, 11), UDim2.fromOffset(632, 568), outline, 18)
lip.ZIndex = 0
local surface = frame(dialog, "Surface", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.fromRGB(32, 43, 57), 18)
surface.ZIndex = 1
local header = frame(dialog, "Header", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 108), Color3.fromRGB(237, 40, 81), 14)
header.ClipsDescendants = true
studs(header, 0.9, 96)
local headerLip = frame(header, "LowerLip", UDim2.new(0, 0, 1, -6), UDim2.new(1, 0, 0, 6), Color3.fromRGB(167, 25, 54))
headerLip.ZIndex = 4
label(header, "Title", "CREATE PARTY", UDim2.fromOffset(150, 18), UDim2.fromOffset(350, 50), 40, white, true)
label(
	header,
	"Subtitle",
	"CHOOSE YOUR CREW SIZE",
	UDim2.fromOffset(152, 69),
	UDim2.fromOffset(340, 22),
	15,
	white,
	false
)
make("ImageLabel", "FriendsIcon", dialog, {
	Position = UDim2.fromOffset(20, -26),
	Size = UDim2.fromOffset(112, 112),
	BackgroundTransparency = 1,
	Image = friendsImage,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 6,
})
button(
	dialog,
	"Close",
	"×",
	UDim2.fromOffset(548, 20),
	UDim2.fromOffset(52, 58),
	Color3.fromRGB(255, 80, 100),
	Color3.new(0, 0, 0),
	12
)
label(dialog, "SizeTitle", "PARTY SIZE", UDim2.fromOffset(36, 132), UDim2.fromOffset(180, 24), 18, white, false)
local selected = label(
	dialog,
	"SelectedLabel",
	"2 PLAYERS SELECTED",
	UDim2.fromOffset(386, 134),
	UDim2.fromOffset(190, 22),
	13,
	Color3.fromRGB(46, 184, 242),
	false
)
selected.TextXAlignment = Enum.TextXAlignment.Right
local options = frame(dialog, "Options", UDim2.fromOffset(36, 162), UDim2.fromOffset(540, 116), outline)
options.BackgroundTransparency = 1
make(
	"UIListLayout",
	"Layout",
	options,
	{ FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }
)
for index = 1, 4 do
	local option = button(
		options,
		"Size" .. index,
		"",
		UDim2.fromOffset(0, 0),
		UDim2.new(0, 124, 1, 0),
		Color3.fromRGB(49, 65, 81),
		Color3.fromRGB(27, 38, 49),
		12
	)
	option.LayoutOrder = index
	local number =
		label(option.Face, "Number", tostring(index), UDim2.fromOffset(0, 20), UDim2.new(1, 0, 0, 42), 34, white, true)
	number.TextXAlignment = Enum.TextXAlignment.Center
	local unit = label(
		option.Face,
		"Unit",
		index == 1 and "PLAYER" or "PLAYERS",
		UDim2.new(0, 0, 1, -30),
		UDim2.new(1, 0, 0, 20),
		13,
		white,
		false
	)
	unit.TextXAlignment = Enum.TextXAlignment.Center
	local badge = frame(
		option.Face,
		"Selected",
		UDim2.new(1, -32, 0, 5),
		UDim2.fromOffset(26, 26),
		Color3.fromRGB(45, 203, 101),
		13
	)
	badge.ZIndex = 6
	stroke(badge, 2)
	local check = label(badge, "Check", "✓", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 18, white, false)
	check.ZIndex = 7
	check.TextXAlignment = Enum.TextXAlignment.Center
	badge.Visible = index == 2
end
local friends =
	frame(dialog, "Friends", UDim2.fromOffset(36, 302), UDim2.fromOffset(540, 78), Color3.fromRGB(17, 25, 32), 12)
stroke(friends, 4)
make("ImageLabel", "Icon", friends, {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.fromOffset(54, 54),
	BackgroundTransparency = 1,
	Image = friendsImage,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 5,
})
label(friends, "Title", "FRIENDS ONLY", UDim2.fromOffset(74, 10), UDim2.fromOffset(250, 24), 18, white, false)
label(
	friends,
	"Description",
	"Only the host's friends can join",
	UDim2.fromOffset(74, 38),
	UDim2.fromOffset(330, 20),
	16,
	muted,
	false
)
local toggle = make("TextButton", "Toggle", friends, {
	Position = UDim2.new(1, -92, 0.5, -20),
	Size = UDim2.fromOffset(72, 40),
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(49, 65, 81),
	BorderSizePixel = 0,
	ZIndex = 5,
})
corner(toggle, 20)
stroke(toggle, 3)
local knob = frame(toggle, "Knob", UDim2.fromOffset(4, 4), UDim2.fromOffset(32, 32), white, 16)
knob.ZIndex = 6
stroke(knob, 2)
local create = button(
	dialog,
	"Create",
	"CREATE PARTY",
	UDim2.fromOffset(36, 406),
	UDim2.fromOffset(540, 86),
	Color3.fromRGB(45, 203, 101),
	Color3.fromRGB(21, 124, 69),
	16
)
studs(create.Face, 0.92, 108)
local footer = label(
	dialog,
	"Footer",
	"Your crew leaves 15 seconds after you create the party.",
	UDim2.fromOffset(36, 512),
	UDim2.fromOffset(540, 22),
	13,
	muted,
	false
)
footer.TextXAlignment = Enum.TextXAlignment.Center

local waiting =
	frame(gui, "Waiting", UDim2.new(0.5, 0, 0, 12), UDim2.fromOffset(400, 126), Color3.fromRGB(32, 43, 57), 12)
waiting.AnchorPoint = Vector2.new(0.5, 0)
waiting.Visible = false
waiting.ZIndex = 10
stroke(waiting, 3)
make("UIScale", "UIScale", waiting)
label(waiting, "Title", "PARTY 1/4", UDim2.fromOffset(18, 12), UDim2.fromOffset(230, 30), 25, white, true)
label(waiting, "Details", "Starting in 15s", UDim2.fromOffset(18, 47), UDim2.fromOffset(364, 25), 17, muted, false)
button(
	waiting,
	"Leave",
	"LEAVE",
	UDim2.fromOffset(264, 78),
	UDim2.fromOffset(118, 40),
	Color3.fromRGB(237, 40, 81),
	Color3.fromRGB(167, 25, 54),
	8
).Face.Label.TextSize =
	19
local notice =
	frame(gui, "Notice", UDim2.new(0.5, 0, 0, 148), UDim2.fromOffset(580, 76), Color3.fromRGB(17, 25, 32), 12)
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.Visible = false
notice.ZIndex = 20
stroke(notice, 3)
local message = label(notice, "Message", "", UDim2.fromOffset(16, 8), UDim2.new(1, -32, 1, -16), 18, white, false)
message.TextXAlignment = Enum.TextXAlignment.Center

local function part(parent, name, position, size)
	return make("Part", name, parent, {
		Position = position,
		Size = size,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Transparency = 1,
		CastShadow = false,
	})
end
for _, area in ipairs(workspace.PartyDesign:GetChildren()) do
	local bounds = area:FindFirstChild("PartyBounds01")
	local floor = area:FindFirstChild("Floor")
	assert(bounds and floor, "Missing bounds/floor: " .. area.Name)
	bounds.CanCollide = false
	bounds.CanTouch = false
	bounds.Transparency = 1
	local center = Vector3.new(bounds.Position.X, floor.Position.Y + floor.Size.Y / 2 + 3, bounds.Position.Z)
	local towardCorridor = if center.X < 1200 then 1 else -1
	part(area, "PartyCenter", center, Vector3.one)
	part(area, "PartyExit", center + Vector3.new(towardCorridor * 11, 0, 0), Vector3.one)
	part(area, "PartyEntry", center + Vector3.new(towardCorridor * 7, 1, 0), Vector3.new(3, 8, 9))
	local barriers = make("Folder", "PartyBarriers", area)
	local halfX, halfZ = bounds.Size.X / 2, bounds.Size.Z / 2
	for _, spec in ipairs({
		{ "Left", Vector3.new(-halfX, 0, 0), Vector3.new(0.4, bounds.Size.Y, bounds.Size.Z) },
		{ "Right", Vector3.new(halfX, 0, 0), Vector3.new(0.4, bounds.Size.Y, bounds.Size.Z) },
		{ "Front", Vector3.new(0, 0, -halfZ), Vector3.new(bounds.Size.X, bounds.Size.Y, 0.4) },
		{ "Back", Vector3.new(0, 0, halfZ), Vector3.new(bounds.Size.X, bounds.Size.Y, 0.4) },
	}) do
		local wall = part(barriers, spec[1], bounds.Position + spec[2], spec[3])
		wall.Color = Color3.fromRGB(45, 183, 243)
		wall.Material = Enum.Material.ForceField
	end
	local anchor = part(area, "BillboardAnchor", center + Vector3.new(0, 7, 0), Vector3.one)
	local billboard = make("BillboardGui", "PartyBillboard", anchor, {
		Size = UDim2.fromOffset(150, 84),
		Enabled = false,
		AlwaysOnTop = false,
		MaxDistance = 90,
		Adornee = anchor,
	})
	for index, name in ipairs({ "Timer", "Count" }) do
		make("TextLabel", name, billboard, {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			Position = UDim2.fromScale(0, (index - 1) * 0.5),
			Size = UDim2.fromScale(1, 0.5),
			Font = Enum.Font.FredokaOne,
			TextSize = 32,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeColor3 = outline,
			TextStrokeTransparency = 0,
		})
	end
	task.wait()
end
assert(not ServerStorage:FindFirstChild("PartyCartTemplate"), "Template already exists")
local source
local nearest = math.huge
local startPoint = workspace.LobbyEnvirontment.PartySpawn:GetChildren()[1].Position
for _, candidate in ipairs(workspace:GetChildren()) do
	if candidate.Name == "Minecart_Default_TNT" and candidate:IsA("Model") then
		local root = candidate:FindFirstChild("PhysicsRoot")
		if root and (root.Position - startPoint).Magnitude < nearest then
			source = candidate
			nearest = (root.Position - startPoint).Magnitude
		end
	end
end
assert(source, "Lobby cart missing")
local template = source:Clone()
template.Name = "PartyCartTemplate"
template.PrimaryPart = template.PhysicsRoot
CollectionService:RemoveTag(template, "CarryCart")
template:SetAttribute("CartId", nil)
template:SetAttribute("PartyId", nil)
template.Parent = ServerStorage
return { gui = gui:GetFullName(), areas = #workspace.PartyDesign:GetChildren(), template = template:GetFullName() }
